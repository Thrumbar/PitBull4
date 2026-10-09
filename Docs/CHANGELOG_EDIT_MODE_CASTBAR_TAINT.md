# Edit Mode casting-bar taint fix

## Fixed

- Replaced the direct `frame.Show = noop` override used by the Hide Blizzard module with a `hooksecurefunc(frame, "Show", ...)` post-hook.
- Prevents PitBull4 from tainting Blizzard's `PlayerCastingBarFrame:Show()` method.
- Prevents the tainted Edit Mode refresh from reaching arena casting bars and failing while Blizzard iterates the secret-keyed `CastingBarTypeInfo` table in `CastingBarMixin:StopFinishAnims()`.

## Behavior retained

- Frames handled by the raw hide path are still hidden whenever Blizzard attempts to show them.
- No frame parent changes were added to the raw path.
- Classic and Mainline use the same secure hook API; no version-specific fallback is required.

## Reload requirement

A full UI reload is required after installing this patch because the old session may already have a tainted `Show` field on the Blizzard frame.
