# MyDangle

A tiny local-only macOS menu-bar toy inspired by dangling desktop charms.

## What this first version does

- Runs as a menu-bar-only Mac app.
- Displays a transparent floating dangle over other apps.
- Uses a physical pendulum simulation with gravity, damping and momentum.
- Drag/flick the charm with your mouse.
- Grab the tiny anchor dot at the top to move it horizontally.
- Choose several emoji charms.
- Change rope length, charm size and horizontal position.
- Remembers your choices in `UserDefaults`.
- Works across Spaces and alongside full-screen apps where macOS permits auxiliary panels.
- Global shortcuts:
  - Control + Option + D: Show / hide.
  - Control + Option + K: Give it a push.

## Requirements

- macOS 13+
- Xcode 15+ recommended
- No third-party packages
- No server
- No account
- No internet connection after download

## Run it

1. Unzip this folder.
2. Open `MyDangle.xcodeproj` in Xcode.
3. Select the **MyDangle** scheme.
4. In **Signing & Capabilities**, choose your Apple Development Team if Xcode asks.
5. Press **Run** (`Command + R`).
6. Look for the circular icon in the macOS menu bar.

Because this is a local development build, you do not need to publish it to the App Store.

## Notes

This MVP uses a single physical pendulum rather than a multi-segment rope. It already swings, accelerates under gravity, damps naturally, and keeps momentum after a flick. A later version can replace this with a Verlet multi-node rope for more bending and wobble.

The overlay panel is intentionally narrow rather than a full-screen transparent window. This avoids a giant invisible window interfering with normal mouse interaction in other apps.

## Good next upgrades

- True multi-segment rope / chain physics.
- Import custom PNG/WebP charms.
- Drag-and-drop charm library.
- Custom rope colors and styles.
- Notch-aware anchor positioning.
- Launch at Login via `SMAppService`.
- `mydangle://` URL commands.
- Sparkle / particles when the charm is clicked.
- Multiple simultaneous dangles.
- Per-display dangles.
