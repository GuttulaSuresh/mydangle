MYDANGLE v1.6 — LOCK, SLEEP & STARTUP
=====================================

This version is built on the working v1.5 realistic-rope release.

WHAT'S NEW
----------
1. Launch at Login
   - Open the MyDangle control window.
   - Check "Launch MyDangle at login".
   - Or use menu bar:
       MyDangle > Startup & Lock > Launch at Login
   - macOS may show the item in:
       System Settings > General > Login Items

2. Lock / user-session detection
   - MyDangle listens for the macOS user session becoming inactive/active.
   - Physics pauses while the session is inactive.
   - It resumes smoothly after the user session becomes active again.

3. Sleep / wake detection
   - Physics pauses when the displays or Mac sleep.
   - The simulation clock is reset during pause, so unlocking/waking does not
     cause a giant jump or violent physics catch-up frame.

4. Experimental Lock-Screen Visibility
   - OFF by default.
   - Enable in the control window or:
       MyDangle > Startup & Lock > Experimental Lock-Screen Visibility

   When enabled, MyDangle:
   - sets the dangle window's canBecomeVisibleWithoutLogin property to true
   - raises the dangle to NSWindow.Level.screenSaver while the user session
     is inactive
   - leaves the charm static while locked

IMPORTANT LIMITATION
--------------------
This is best-effort/experimental.

macOS owns the secure password Lock Screen and may place that secure UI above
all third-party app windows. Enabling this option does NOT guarantee that the
charm will be visible on every macOS version or every lock/login configuration.

The feature uses public AppKit APIs only and does not bypass macOS security.

INSTALL / UPDATE
----------------
1. Quit MyDangle v1.5.
2. Unzip this package.
3. Double-click "Install MyDangle.command".
4. Wait for BUILD SUCCEEDED.
5. The installer replaces:
       ~/Applications/MyDangle.app
6. MyDangle launches automatically.

AFTER INSTALLATION
------------------
Double-click:
    Home > Applications > MyDangle.app

No Xcode is needed to run it.

RECOMMENDED TEST
----------------
A. Confirm normal desktop behavior first.
B. Enable "Experimental lock-screen visibility".
C. Lock the Mac normally.
D. Check whether your macOS configuration allows the static charm to remain
   visible. If the secure password screen covers it, that is macOS security
   behavior rather than an app failure.
E. Unlock and confirm physics resumes smoothly.

LAUNCH AT LOGIN NOTE
--------------------
The app uses Apple's SMAppService.mainApp API on macOS 13+.
Depending on macOS settings, registration can require user approval. The
control window shows "Waiting for macOS approval" when that happens.
