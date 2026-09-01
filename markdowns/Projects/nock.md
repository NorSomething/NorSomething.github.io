---
title: nock
tags: C, XCB, PAM
---

# Nock
A tiny and super basic X11 screen locker that I wrote out of pure boredom and as a way to distract myself from college academics :p

## Prelude
One day, as any other, I was doom scrolling on my bed and came across this fantastic [video](https://www.youtube.com/watch?v=CagsZdJ3ZhA) by [theurbanpenguin](https://www.youtube.com/@theurbanpenguin). This piqued my interest about `Pluggable Auth Modules` (more on this later) and after a little more digging I found out that I can make **own** pam modules. 

To do this, I needed to implement one of the [core PAM functions](https://www.linuxjournal.com/article/5940). Here I found out about the `pam_sm_authenticate` function. Judging from the name itself you can tell it has *something* to do with auth and... maybe something to do with Linux lockscreens? *cue the title track*

## Tech Stack
- C 
- XCB 
- PAM
- Other POSIX APIs

## Why this Tech Stack?
So **what** exactly do you need to have a functioning lock screen? Well mainly two things - a way for the user to see your lockscreen, and a way for your app to do the actual locking mechanism. 

Let's address them one by one. First the sort of UI part of the app - on Linux users broadly have two choices when making something that interacts closely with the display server. Those choices spring from the display servers itself. Firstly there is `Xorg` (using the X11 protocol) - the (mostly) old display server. Then there is `Wayland` - the modern and sort of the choice for all computers now. 

### Why I chose Xorg as my display server
To be blunt - I chose to make this over Xorg because I was lazy :p
To be not so blunt - The sort of locking mechanism you can build with Xorg is **much** simpler than what you would need to do if you were working with Wayland. Now why is that? Well Xorg is much older than Wayland, and as a result - you dont need to fiddle with the display server all that much which simplifies what you will be needing to do for this particular usecase.

Time to answer this one **question** as broadly as possible : What exactly should a lockscreen do visually? Well... it should lock the screen (*duh!*) and in doing so prevent the user from accessing the computer untill the correct password is entered. This can be done in a very simplified way on the Xorg display server. You just need a way to **re-direct all input** from the user into your lock screen app and **display a gui** of sorts over the already existing applications. More on how I implemented these later.

Now now now.. why not do the same on Wayland? Wellllll - I saw [the bindings](https://pkg.go.dev/github.com/tuxx/wayland-ext-session-lock-go#section-readme) to do any work with the Wayland protocol and got scared XD.

### XCB vs XLib
With our display server chosen, we now need a **UI library** to do our lockscreen bidding. With Xorg we have two C libraries to work with - **XLib and XCB**. What's the difference?

Xlib is an older standard library and XCB is the newer library.

Thats honestly the only reason I chose XCB over Xlib here for this project. XCB is also synchronous while XLib is asynchronous, might be useful when I eventually decide to make a more fleshed out version of this app.


### User Auth in Linux
Okay now we have our UI library, let's now find a way to actually authenticate the user password. Here, we don't really have the burden of choice as there is only one way to authenticate user passwords in Linux - PAM. So we go with that!

## Technical Background
Majority of this section would be exploring what PAM is and how it user account authentication works in Linux.

**PAM or the Pluggable Authentication Modules** is basically a set of unix system libraries that handles authentication and access control. All apps that need to validate user account stuff need not write their own auth logic and can just can PAM do it for them.

There are mainly four different **PAM Management Groups**.
1. `auth` : deals with password verification and other ways to authtenticating with your system like fingerprint and face id.
2. `account` : deals with user permissions for files and things like if a certain account is allowed to login or not.
3. `password` : deals with changing passwords and all other things relating to it.
4. `session` : deals with session managemet.

Here, for a lockscreen application we will ofcourse be using the `auth` module. The app will offload the entire "checking password" part to PAM. But how does it actually do that offloading and asking PAM? Thats where **PAM Conversations** come in!

**A PAM Conversation is a routine or a bridge between jfjfjfjfjfjfyour regular apps and PAM.** 
The default PAM conversation works over the shell. For example, whenever you run `su`, the application that throws you inside root : `su` calls PAM which runs the default conversation. One of the flags in this default converation hide the password when typing, which is why you can't see your password when this particular app is run.

But we wont be working over the shell, we have our own GUI! I hear ye I hear ye. This is why for this project, we have a **custom** PAM conversation. Nothing very complicated tho, just a way to
