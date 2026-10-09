# PitBull Unit Frames 4.0

## compat-20261008.5 — Forever options checkbox hotfix (2026-10-08)

- Fixed the Forever 1.60.1 options error in AceGUIWidget-CheckBox.lua by replacing all six removed global SetDesaturation calls with the native Texture:SetDesaturated method.
- Bumped the CheckBox widget revision from 26 to 27 so AceGUI upgrades older registrations and discards older pooled widgets. Enabled, disabled, three-state, and radio behavior is preserved.
- Confirmed the native method in all five supplied client sources: Forever, Era, Mists, and both Retail builds. The original failure reproduces offline; 113 checkbox checks and the existing 356 regression assertions pass. In-game validation remains pending.
- Retained the earlier client hotfixes and aligned package/runtime versions. No new dependency, global wrapper, polling loop, or profile migration is introduced.

## compat-20261008.4 — Forever TOC hotfix (2026-10-08)

- Corrected Forever's Interface declaration from 0 to 16001 for client 1.60.1 build 70291 in the core, optional DogTag, and source DogTag Camelot/generic manifests.
- Replaced pending Interface metadata with the confirmed client values and aligned package/runtime version strings.
- Retained the Era and Mists hotfixes. Existing gameplay logic, module selections, profiles, and bundled libraries are unchanged; in-game validation remains pending.

## compat-20261008.3 — Mists Blizzard-frame hiding hotfix (2026-10-08)

- Fixed Mists 5.5.4 build 70032 login/profile errors by accepting absent optional Blizzard frames instead of reporting them as invalid.
- Added the Classic MonkHarmonyBar and PaladinPowerBar names while retaining modern frame names on Retail and Camelot.
- Removed the reported frame-error trigger for the secondary AceLocale ToDebugString warning during BugGrabber error recording.
- Preserved out-of-combat hiding, the secure castbar Show post-hook, existing profiles, and the previous Classic Era texture/spell fixes.
- Added 99 focused HideBlizzard assertions; the existing 257 compatibility assertions also pass. In-game validation remains pending.

## compat-20261008.2 — Classic Era atlas and aura-filter hotfix (2026-10-08)

- Fixed Classic Era login/configuration errors caused by passing nil to Texture:SetAtlas. Public and native bars restore their ordinary textures through SetTexture, including pooled controls and custom media.
- Prevented texture-cache shortcuts from retaining an atlas when the ordinary texture uses the same underlying asset.
- Checked spell database availability before converting shared aura-filter IDs and saved name lists. Era skips unavailable Gift of the Naaru (28880) and Netherstorm Flag (34976) entries without invalid-ID chat warnings; clients with those spells retain them.
- Deferred saved-filter name insertions until spell-ID iteration finishes, avoiding invalid-key errors during profile migration.
- Strengthened offline texture API stubs and added regression coverage for atlas resets, control reuse, renderer transitions, unavailable spells, supported expansion spells, and saved-profile conversion. All 257 isolated assertions pass; in-game validation remains pending.

## compat-20261008.1 — Client initialization and shared-bar correctness (2026-10-08)

- Added Era/Camelot core and optional DogTag entry points with explicit module selections and manifest diagnostics.
- Activated a private API adapter, separated Camelot identity from Classic, capability-checked restriction handling/events, and made specialization-profile startup optional.
- Fixed the bundled native specialization getter and normalized legacy spell range/cooldown contracts.
- Repaired shared bar getters and fill geometry; preserved public-value deficit, fade, animation, and extra segments while routing protected values through native display methods.
- Fixed health fraction scaling and VisualHeal configuration/live overlays; preserved scenario-target and secure castbar-hiding changes.
- Corrected primary/alternate-mana hide settings, removed deprecated aura-consolidation tuple dependence, and repaired the DogTag whitespace pattern.
- Added offline regression evidence and a client-validation checklist. All in-game checks and Forever's actual interface declaration remain pending.


## [Unreleased](https://github.com/nebularg/PitBull4/compare/v4.2.49...HEAD) (2026-04-16)
[Full Changelog](https://github.com/nebularg/PitBull4/compare/v4.2.49...HEAD) [Previous Releases](https://github.com/nebularg/PitBull4/releases)

### Dead, ghost, and disconnected health-bar rendering

- Fixed health bars intermittently disappearing when a player, party member,
  raid member, target, focus, boss, or other displayed unit dies while Retail
  add-on restrictions are active.
- Preserved the existing native `LiveStatusBar` through alive, dead, ghost,
  disconnected, resurrected, and reconnected transitions. The health module no
  longer returns an empty raw value for a valid dead or ghost unit, so the
  shared bar handler does not delete and later reconstruct the control.
- Added safe plain `1/1` fallback values for dead, ghost, and disconnected
  units. This keeps the configured visual footprint visible without performing
  arithmetic on restricted or secret health values.
- Reordered health-state evaluation so non-secret dead and disconnected states
  are resolved before the restricted numeric-data guard. Dead units now use the
  configured **Dead** color and disconnected units use the configured
  **Disconnected** color even when the combat restriction is active.
- Kept live-unit behavior unchanged: unrestricted clients continue to use raw
  `UnitHealth()` and `UnitHealthMax()` values, while the existing normalized
  health fallback remains available to non-native bar paths.

### Retail restriction-state compatibility

- Corrected the restriction-state API lookup from the nonexistent
  `C_AddOns.GetAddOnRestrictionState` member to Blizzard's documented
  `C_RestrictedActions.GetAddOnRestrictionState` function.
- Preserved the legacy global fallback for older clients that do not expose the
  Retail namespace.
- Startup and reload detection can now recognize a restriction that is already
  active, instead of waiting for a later `ADDON_RESTRICTION_STATE_CHANGED`
  transition.

### Compatibility and validation

- Validated the restriction API and event payload against the supplied Retail
  12.0.7.68367 and 12.1.0.68824 FrameXML/API documentation.
- Compared Blizzard's unit and compact-unit-frame health update behavior across
  both supplied Retail versions. No death-specific health API migration is
  required between these releases.
- The fix is runtime-gated by PitBull4's existing Retail restriction support;
  Classic Era, Burning Crusade Classic, Cataclysm Classic, and Mists Classic
  retain their existing health API behavior.
- No saved-variable schema, layout profile, media, localization, module load
  order, or secure-click attribute changes were introduced.

- Midnight / Retail secret-value compatibility pass across PitBull text evaluation.
    Hardened LuaTexts, ComboPoints, and DogTag-driven text paths against secret boolean / number / string comparisons that could trigger taint-style runtime errors on modern clients.
    This includes avoiding unsafe direct boolean tests and numeric comparisons when the client marks values as secret.

- Modernized DogTag text loading and startup behavior.
    Updated the DogTag text provider to use `C_AddOns` loading paths and modern addon availability checks while keeping the module load-on-demand friendly.
    Preserves existing PitBull text-provider behavior while improving compatibility with current clients.

- Expanded LibDogTag-3.0 secret-value handling.
    Added defensive handling for secret values in compiler output and core categories so expressions no longer break on empty-string coercion, numeric conversion, or equality checks when protected values are returned.
    Secret results are now preserved safely instead of being forced through unsafe normalization paths.

- Updated LibDogTag-Unit aura scanning for current Blizzard APIs.
    Aura tags now use `C_UnitAuras.GetAuraDataByIndex` / `GetAuraDataBySpellName`, skip secret aura names, track aura counts and expiration data safely, and continue to fire DogTag aura events without depending on legacy name-based access patterns.

- Improved cast-tag compatibility from Classic through Midnight.
    Cast handling now branches between older rank-returning cast APIs and modern spellID-based APIs, respects Classic player-only fallback behavior, and avoids unsafe comparisons when GUID, cast times, or spell identifiers are secret.

- Modernized health-tag calculations for restricted clients.
    Health text now uses `UnitHealthPercent()` and Blizzard curve helpers where available, with safe fallback math for older clients.
    Ghost-health edge cases and color calculations were also tightened for better cross-version consistency.

- Cross-version DogTagTexts packaging pass.
    Kept versioned TOCs aligned for TBC, Cataclysm Classic, Mists Classic, and Mainline so the DogTag text module remains loadable across supported WoW branches during the compatibility refactor.

## [v4.2.49](https://github.com/nebularg/PitBull4/tree/v4.2.49) (2026-02-12)
[Full Changelog](https://github.com/nebularg/PitBull4/compare/v4.2.48...v4.2.49) [Previous Releases](https://github.com/nebularg/PitBull4/releases)

- Add default boss group and focus units to existing profiles in TBC  
    This is for people coming from classic releases.  
    Resolves #94  
