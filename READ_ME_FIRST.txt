MYDANGLE 1.5 — REALISTIC ROPE & PHYSICS
=======================================

This package is based on the stable double-clickable v1.4 app and keeps:
- normal double-click launch
- visible control window
- menu-bar controls
- Bhairava charm
- Lemon & Chilli charm
- local-only operation

WHAT'S NEW IN 1.5
-----------------
1. Segmented flexible rope
   - 18 simulated rope nodes
   - 10 constraint passes per physics step
   - rope bends and transmits tension instead of behaving as one rigid pendulum

2. Weighted charm endpoint
   - the charm has higher effective mass than the rope
   - bottom rope segments carry more load
   - swinging feels heavier and less "cartoon-like"

3. Spring-damper mouse interaction
   - the mouse pulls the charm instead of instantly teleporting it
   - the charm lags slightly behind fast pointer movement
   - the rope straightens naturally under tension

4. Real flick momentum
   - recent pointer velocity is measured and smoothed
   - releasing the mouse transfers part of that velocity into the charm
   - fast flick = stronger swing; slow release = gentle movement

5. Better gravity and stability
   - time-based physics
   - high-frequency update request
   - substeps on slower frames
   - constraint solver prevents stretchy/unstable rope behavior

6. More realistic rope appearance
   - smooth spline through the physical rope nodes
   - dark depth strand
   - warm-gold main fiber
   - fine highlight
   - subtle braided/fiber bands
   - small top knot
   - soft shadow

7. Small charm tilt
   - the artwork stays mostly upright
   - it tilts slightly from rope direction and horizontal inertia

INSTALL / UPDATE
----------------
1. Quit any currently running MyDangle.
2. Unzip this package.
3. Double-click "Install MyDangle.command".
4. Let Terminal reach BUILD SUCCEEDED.
5. The installer replaces:
      ~/Applications/MyDangle.app
6. It launches the updated app automatically.

AFTER INSTALLATION
------------------
No Xcode is needed to RUN MyDangle.
Double-click:
    Home > Applications > MyDangle.app

HOW TO TEST THE NEW PHYSICS
---------------------------
- Grab the charm.
- Move the mouse slowly left/right and notice the weighted follow.
- Move quickly and notice the rope tension.
- Flick sideways and release.
- Try short vs long rope from the MyDangle menu.
- Use "Reset Physics" to return to rest.

If you prefer more or less lag after testing, the next update can expose
"Light / Natural / Heavy" physics presets.
