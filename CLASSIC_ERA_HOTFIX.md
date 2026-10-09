# PitBull4 Classic Era compatibility hotfix

Date: 2026-10-08  
Version: **compat-20261008.2**  
Status: source fixes and offline checks complete; in-game retest pending.

## Purpose and changes

Fix the reported Classic Era 1.15.9 milestone failure at `Texture:SetAtlas()` and the invalid spell-ID messages for **28880** and **34976**.

- `Controls/BetterStatusBar.lua`: native atlas calls receive an atlas name. Clearing an atlas restores the ordinary texture through `SetTexture`, including public/native bars, custom media, and pooled controls. The texture-cache shortcut also checks for an active atlas, so matching texture assets cannot leave stale atlas state.
- `Modules/Aura/Filter.lua`: shared aura lists and saved name-list conversion check whether a spell exists in the active database before fetching its name. Era skips the unavailable Gift of the Naaru and Netherstorm Flag entries; clients with those spells retain them. This checks database availability, not whether the character learned the spell. Debug diagnostics remain for existing spells with unexpectedly missing names.
- Saved-filter conversion defers new name-key insertions until numeric-key iteration finishes, preventing the reproduced `invalid key to next` failure.
- Package and runtime version metadata are aligned. The consolidated `CHANGELOG.md` contains this release and all previous entries.

The immediate baseline is `PitBull4_Compatibility_Milestone_1_Full_2026-10-08.zip`, version compat-20261008.1, SHA-256 `de33bac7861cc8ab2fddfa0db35d7629cd71beb314521b0a50b74d5fe19162ef`.

## API compatibility

| API/path | Behavior |
| --- | --- |
| Native `Texture:SetAtlas` | Requires an atlas name; no native nil-atlas reset is used. This input contract is present in every supplied client snapshot. |
| Native `Texture:SetTexture` | Restores ordinary texture assets when leaving atlas display. |
| Private spell adapter | Uses native `C_Spell.DoesSpellExist`/`GetSpellName` where available; retains its existing legacy `GetSpellInfo` fallback. |
| Era 1.15.9 | Unsupported shared aura IDs are omitted before name lookup. Login, options, configuration mode, and reload require a focused retest. |
| Retail, Mists, Forever/Camelot | Previous module routing and display behavior remain. Matching APIs were checked in the supplied source; full in-game coverage remains pending. |

No new dependency, SavedVariables schema, event, polling loop, or secure-frame attribute is introduced. Existing milestone changes are retained. `UnitFrame.lua`, `Modules/CastBar/CastBar.lua`, and `Modules/HideBlizzard/HideBlizzard.lua` remain byte-identical to both the milestone and original scenario-target baseline.

## Verification and performance

- **257 isolated regression assertions pass.** They execute real bar and filter code under narrow API stubs, including Era native/legacy spell paths, supported expansion spells, atlas resets, control reuse, custom media, renderer transitions, and profile conversion.
- The strengthened texture stub reproduced the old nil-atlas failure before the fix. The migration case also reproduced the unsafe table-iteration failure before deferred insertion was added.
- **226 Lua files** parse with texluac/Lua 5.3.6; **91 XML files** parse; all **16 root TOC/XML load graphs** resolve. Offline tests are absent from every game load graph.
- Spell availability checks run during filter construction and profile conversion. One temporary conversion table is reused across filters per profile callback. The ordinary texture-cache check adds a native atlas query. No in-game performance improvement is claimed.

No Warcraft client or Lua 5.1 compiler is available here. Stubs do not emulate Blizzard's rendering, secrecy, taint, or secure-execution engines. Wider compatibility and in-game acceptance remain governed by `COMPATIBILITY_VALIDATION.md`.

## Install and retest

Use the full milestone ZIP to replace the `PitBull4` and optional `PitBull4_DogTagTexts` addon folders. Keep existing SavedVariables and profiles.

The changed-files hotfix ZIP applies **only to an installed compat-20261008.1 milestone**. Extract it over the existing addon folders. It includes changed files only and is not a standalone addon.

On Era, verify login with the existing profile, open `/pb`, toggle configuration mode, switch profiles, and reload the UI. Confirm health/power bars retain their configured textures and colors, supported aura filters still work, and neither the atlas error nor messages for 28880/34976 recur. Record any remaining error with the selected manifest and package version.

To run the offline suite from the directory containing PitBull4: `texlua PitBull4/Tests/compatibility_regressions.lua`.
