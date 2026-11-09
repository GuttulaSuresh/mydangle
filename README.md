# MyDangle 🧿

A small macOS menu-bar app that hangs a charm from the top of your screen, like a charm hanging from a car mirror. Grab it with the mouse, flick it, and it swings on a rope with real physics.

Written in Swift with AppKit. It runs fully offline: no packages, no server.

## Versions

Each version is a commit with a tag, so you can see how the app grew.

| Tag | What changed |
|---|---|
| `v1.0` | First version: menu-bar app with a hanging charm |
| `v1.4` | Double-click installer, control window, Bhairava and Lemon & Chilli charms |
| `v1.5` | Segmented rope (18 nodes), weighted charm, spring-damper mouse pull, flick momentum |
| `v1.6` | Launch at login, physics pauses on lock and sleep, experimental lock-screen visibility |
| `v2.0` | Fresh rebuild as MyDangle V2 (current) |

## Run it (V2)

1. Open `MyDangleV2.xcodeproj` in Xcode.
2. Select **My Mac** and pick your Apple Development Team if Xcode asks.
3. Press **⌘R**.
4. Look for `🧿 MyDangle` in the menu bar. The charm appears at the top center.

Needs macOS 13 or later.

Versions v1.4 to v1.6 also come with `Install MyDangle.command`, which builds the app and installs it to `~/Applications`. Check out the tag first, e.g. `git checkout v1.6`.
