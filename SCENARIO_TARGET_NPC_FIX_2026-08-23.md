# Scenario target NPC fix (2026-08-23)

## Fixed symptoms

- A target frame with no previous target did not appear for a scenario NPC.
- A target frame showing the player remained stale after selecting a scenario NPC.
- Restricted NPC casts repeatedly produced blocked comparisons and arithmetic in
  `Modules/CastBar/CastBar.lua`.

## Root cause

Retail 12.1 can return a secret `UnitGUID` for a non-player-controlled unit on a
restricted map. The earlier compatibility guard converted that secret GUID to
`nil`. `CheckGUIDForUnitID` then treated it as a missing unit and explicitly
suppressed the frame update. This made both observed states deterministic: an
empty frame stayed empty, while a populated frame retained its previous unit.

The CastBar helpers also attempted protected comparisons and arithmetic inside
`pcall`. A protected-value block still taints/aborts that execution path; `pcall`
does not make the value readable.

## Changes

- Added a private per-frame identity revision for units whose real GUID is
  protected. It is used only for PitBull4 lifecycle and cache invalidation and
  is never passed to a Blizzard API as a GUID.
- Kept "protected live unit" separate from "unit absent" throughout unit-frame,
  module, bar, fader, indicator, portrait, background, and group-header paths.
- Forced `PLAYER_TARGET_CHANGED` to refresh all matching frames when the target
  GUID is inaccessible, including a currently hidden target frame.
- Made portrait caches refresh when one protected NPC target replaces another.
- Made the Retail CastBar consult
  `C_Secrets.ShouldUnitSpellCastingBeSecret`. Restricted casts now hide only the
  cast display before any secret comparison or timing arithmetic; the owning
  target frame continues updating.
- Replaced the remaining CastBar `pcall`-based value operations with the shared
  access-aware helpers.
- Kept Classic Era, Burning Crusade Classic, Mists/Cataclysm Classic behavior
  unchanged by feature-detecting the Retail-only `C_Secrets` predicates.

## Verification

- Simulated transitions from no target to a protected NPC, player to a protected
  NPC, protected NPC to protected NPC, and protected NPC back to a public GUID.
- Simulated fully secret CastBar return values with metamethods that fail on any
  comparison, arithmetic, or string conversion.
- Compiled all 115 first-party Lua files with `texluac -p`.
- Preserved both complete addon folders: `PitBull4` and
  `PitBull4_DogTagTexts`.

The supplied log also contains failures attributed to GSE, Carbonite.Info, and
TinyTooltip-Remake. Those are separate addons and are not modified by this
package.
