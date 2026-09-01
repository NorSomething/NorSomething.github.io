---
title: nock
tags: C, XCB, PAM
---

# Nock
> A tiny and super basic X11 screen locker that I wrote out of pure boredom and as a way to distract myself from college academics :p

## Prelude
One day, like any other, I was doom scrolling on my bed and came across this fantastic [video](https://www.youtube.com/watch?v=CagsZdJ3ZhA) by [theurbanpenguin](https://www.youtube.com/@theurbanpenguin). This piqued my interest about `Pluggable Auth Modules` (more on this later) and after a little more digging I found out that I can make **my own** pam files. 

To do this, I needed to implement one of the [core PAM functions](https://www.linuxjournal.com/article/5940). Here I found out about the `pam_sm_authenticate` function. Judging from the name itself you can tell it has *something* to do with auth and... maybe something to do with Linux lockscreens? *cue the title track*
~img=nock.png~
> my nock in action!

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
To be not so blunt - The sort of locking mechanism you can build with Xorg is **much** simpler than what you would need to do if you were working with Wayland. Now why is that? Well Xorg is much older than Wayland, and as a result - you don't need to fiddle with the display server all that much which simplifies what you will be needing to do for this particular usecase.

**What exactly should a lockscreen do visually?** Well... it should lock the screen (*duh!*) and in doing so prevent the user from accessing the computer until the correct password is entered. This can be done in a very simplified way on the Xorg display server. You just need a way to **re-direct all input** from the user into your lock screen app and **display a gui** of sorts over the already existing applications. More on how I implemented these later.

Now now now.. why not do the same on Wayland? Wellllll - I saw [the bindings](https://pkg.go.dev/github.com/tuxx/wayland-ext-session-lock-go#section-readme) to do any work with the Wayland protocol and got scared XD.

### XCB vs XLib
With our display server chosen, we now need a **UI library** to do our lockscreen bidding. With Xorg we have two C libraries to work with - **XLib and XCB**. What's the difference?

Xlib is an older standard library and XCB is the newer library.

Thats honestly the only reason I chose XCB over Xlib here for this project. XCB is also synchronous while XLib is asynchronous, might be useful when I eventually decide to make a more fleshed out version of this app.


### User Auth in Linux
Okay now we have our UI library, let's now find a way to actually authenticate the user password. Here, we don't really have the burden of choice as there is only one way to authenticate user passwords in Linux - PAM. So we go with that!

## Technical Background - PAM 
Majority of this section would be exploring what PAM is and how it user account authentication works in Linux.

**PAM or the Pluggable Authentication Modules** is basically a set of unix system libraries that handles authentication and access control. All apps that need to validate user account stuff need not write their own auth logic and can just have PAM do it for them.

There are mainly four different **PAM Management Groups**.
1. `auth` : deals with password verification and other ways to authtenticating with your system like fingerprint and face id.
2. `account` : deals with user permissions for files and things like if a certain account is allowed to login or not.
3. `password` : deals with changing passwords and all other things relating to it.
4. `session` : deals with session management.

Here, for a lockscreen application we will ofcourse be using the `auth` module. The app will offload the entire "checking password" part to PAM. But how does it actually do that offloading and asking PAM? Thats where **PAM Conversations** come in!

**A PAM Conversation is a routine or a bridge between your regular apps and PAM.** 
The default PAM conversation works over the shell. For example, whenever you run `su`, the application that throws you inside root : `su` calls PAM which runs the default conversation. One of the flags in this default conversation hide the password when typing, which is why you can't see your password when this particular app is run.

But we wont be working over the shell, we have our own GUI! I hear ye I hear ye. This is why for this project, we have a **custom** PAM conversation. Nothing complicated tho, just a way to get the entered password, store it in a `pam_response` struct instance so that my password checking function can use it. Here is my simple implementation : 

```
static int my_conv(int num_msg, const struct pam_message **msg, struct pam_response **resp, void *password) {

	struct pam_response *p = malloc(sizeof(struct pam_response));
	p->resp = (char *)malloc(strlen(password)+1);
	strcpy(p->resp, password);
	*resp = p;
		
	return PAM_SUCCESS;

}
```
Here, `struct pam_response` is as imported struct type from the `<security/_pam_types.h>` header. This function above just is used to fill the `conversation struct`. The PAM modules look for any conversation function with the correct function signature (as above), and calls it. 

Now we need to actually authenticate the entered password against the password stored in your computer. For that we need to **make our own pam files!**
We now have to create a separate `PAM file`, say something called `nock` in `/etc/pam.d` directory. Why? Because we need a separate set of "auth rules"  that our lock screen will touch. So now we have a nock file, alongside files like `/etc/pam.d/su` and `/etc/pam.d/sshd` and other such apps. This type of structure is a part of PAM's design : each app having its own set of auth rules, as said before.

Our `nock` pam file will contain the following rules : 
```
auth       include      system-local-login
account    include      system-local-login
```
~img=instalsh.png~
> The PAM configuration used by nock
From before, we know we need the `auth` rule for doing the actual authenticating for the user account, and we need the `account` rule for checking if t hat particular user account is even allowed to login

> One could also add the password rule if they wanted the application to also be able to change userpasswords 

You also might have noticed this `system-local-login` thingy in our pam file. What's that you ask? To answer that we must read each line of the pam file as in almost a semantic way : "Auth rule *including* **system-local-login**". There is already a pre-existing PAM file called the `system-local-login` which will be used along with the auth rule. Our systems can probably have multiple login/lockscreens and having a common set of configurations is quite useful. It is correct to think of this as a sort of **shared authentication policy**.

> There are also the `.so` files which are actual PAM modules, the code which contains the instructions/code that deals with stored passwords, hashing and un-hashing them to use as per need. We dont really need to worry about any of these, so we treat them as abstractions! :D

I have this tiny [**bash script**](https://github.com/NorSomething/nock/blob/main/install.sh) for my app that does the entire writing your PAM file for you!

# Basic Working
Now, lets see what my nock actually does when you run it! Here is where I tell you about my XCB stuff.

## Setup 
We first need to connect to the X sever and grab the current screen. This is probably the most standard first steps for any XCB related program.
```
connection = xcb_connect(NULL, NULL);
screen = xcb_setup_roots_iterator(xcb_get_setup(connection)).data;
xcb_key_symbols_t *syms = xcb_key_symbols_alloc(connection);
```
Here, the `xcb_key_symbols_t` type is super important as it allows us to convert raw keycode inputs from the keyboard into actual readble key strokes. For example, it can convert something like a keycode of `38` into `XK_a`.

## Making the lockscreen cover the entire screen
XCB gives us a `create_window()` function which.. creates a new window! (*no way!*). But to make it go fullscreen we do some neat trickery. Instead of making the window huge, this function tells the window manager to treat it as fullscreen via the [`EWMH protocol`](https://specifications.freedesktop.org/wm/1.5/). We use the `_NET_WM_STATE_FULLSCREEN` property here to achieve this.
```
xcb_change_property(connection, XCB_PROP_MODE_REPLACE, window, state_reply->atom, XCB_ATOM_ATOM, 32, 1, &fs_reply->atom);
```

## Redirection of input to the window
As mentioned before, we need to make it such that all the input entered by the user goes inside our lockscreen app. For this we have a really neat function called `xcb_grab_keyboard`, which does exactly what's written on its tin. 
```
xcb_grab_keyboard(connection, 0, screen->root, XCB_CURRENT_TIME, XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC);
```
> This is also what makes our XCB window an actual lockscreen, rather than just another GUI window.

## The general event loop
Like every UI app, everything boils down to one `while(true)` loop. This is what my lockscreen does as well. There is one while loop where I have a **blocking** `xcb_wait_forevent()` function, which in this lockscreen app, waits for a specific set of events:

1. `XCB_BUTTON_PRESS` : triggered when any mouse click occurs, which I use as a toggle to the usual 'hide' and 'unhide' password seen in other lockscreen applications.
2. `XCB_KEY_PRESS` : triggered for all the possible keyboard inputs. Here is where I handle the actual password entry, backspace for deleting and return key to send the password to the auth check parts.
3. `XCB_EXPOSE` : triggered when the window is just created. 

> There is also an `XCB_KEY_RELEASE` which is present to check keycode 9, which is Escape. It is just for testing purposes, which when triggered, just exits the app.

## The Password checking
As mentioned above, I have an `auth_user()` function which is where my custom PAM conversation from before hands back whatever the user typed into the GUI as the **"response"**. This is then checked by PAM against the real password hash for that user, and the my auth function returns 1 or 0 depending on the result. 
This true or false return is used by my UI parts of the code to decide whether to show "Access Granted" and exit, or to clear all buffers and let the user try again. 

# Limitations and Conclusion
`nock` works, but it is a very crude implementation of a lockscreen and has some glaring flaws lol.

1. There is no real error handling.
2. The fullscreen trick works fine on my setup but it will definitely NOT hold up on setups that have multiple monitors or different resolutions, or even on some window managers for some obscure reasons.
3. No pointer grabbing so theoretically the applications below could manipulate this flaw. 

None of these problems were really a part of my first draft of sorts for this project, although its been months since I last worked on this project XD. Just haven't paid much attention towards this project.

~img=run.png~

It is still a **really** cool project imho, especially the PAM part, hence the blog! I hope to get time to work on this more and make it *proper*, rather than it just being a "proof of concept""

#### Always feel free to contribute to the project on [Github!](https://github.com/NorSomething/nock).

*until next time, baii!*
