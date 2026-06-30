# Known Limitations

## Resize Cursor on Non-Activating Subtitle Panel

The subtitle container is a borderless, mostly transparent, non-activating `NSPanel`
that is allowed to receive first-click resize gestures without taking focus from
the movie player. In this configuration, macOS does not consistently deliver
standard cursor-rect updates for the panel's resize edges while another app owns
focus.

The app therefore treats resize cursor changes as best-effort only. Product
behavior must not depend on the pointer changing to the horizontal resize cursor.

Current workaround:

- The subtitle container only supports width resize; height is content-driven.
- When hover/edit chrome is visible, the container shows subtle visual resize
  cues on its left and right edges.
- Users can drag those left or right edge regions to adjust subtitle width even
  when the pointer remains the regular arrow.

Do not spend more implementation time trying to make the cursor transition
perfect until there is a proven AppKit or SwiftUI API path that works reliably
for non-activating, transparent panels.
