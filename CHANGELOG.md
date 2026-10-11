# PitBull4 — Changelog

Changes are ordered newest first. Current application version: **compat-20261010.3**. Earlier cumulative changes without individual release dates are grouped at the end of the release history.

## 2026-10-11 — Changed-only distribution and documentation

- Compared the Class Resource Hotfix full release with the supplied PitBull4-midnight source archive, normalizing its root folder to `PitBull4`.
- Consolidated the release history into this single changelog, with the newest entries first. Superseded implementations are identified where relevant.
- Packaged changed and added application files only. No application code was altered for this distribution, and no library files are included.

## 2026-10-10 — Class Resource Hotfix (compat-20261010.3)

- Corrected the Retail Midnight `ClassPowerBar.lua:11` nil-parent error reported on 12.1.0 build 69933.
- Modern class-resource bars retain Blizzard's parent chain, events, shown state, and managed-layout membership. Reversible alpha and mouse suppression preserves native unit lookup, combat callbacks, setup, and maximum-power updates.
- Applied the correction to Death Knight, Warlock, Monk, Paladin, Mage, and Evoker resource frames. Classic retains its existing suppression path and Mists frame aliases.

## 2026-10-10 — Frame Toggle Hotfix (compat-20261010.2)

- Made Hide Blizzard frames settings reversible when an option is unchecked, profiles change, or the module is disabled.
- Restores frames immediately outside combat; combat changes apply afterward using the latest settings, including pending restoration after module disable.
- Preserved native events, unit watches, contextual visibility, requested parents, party-frame pools, and raid-display preferences.
- Preserved native cast-bar and alternate-power parenting and methods. Removed obsolete reload instructions and the module's Reload UI option.

## 2026-10-10 — Application-only Milestone 1 Refactor (compat-20261010.1)

- Replaced application use of LibDualSpec with native specialization-profile switching, preserving saved mappings and older alternate-profile data. Profile changes defer during combat.
- Added PitBull-owned toggle, multiselect, three-state, and radio controls while retaining the existing AceConfig/AceGUI options container.
- Restored the original AceGUI CheckBox, LibDualSpec, and DogTag compiler files, withdrawing the earlier vendor edits.
- Locked all 139 bundled library files to the supplied scenario-target baseline and added SHA-256 boundary verification. Dependency removal remains ongoing.

## 2026-10-08 — Client Hotfixes (compat-20261008.2–.5)

- Corrected Forever/Camelot Interface declarations to **16001**. Retail declarations remain **120100, 120105**.
- Fixed Mists optional class-resource handling, including legacy Monk and Paladin frame aliases, and skipped absent optional frames.
- Fixed Classic Era atlas resets through ordinary texture restoration and corrected stale atlas cache state.
- Checked spell availability before shared aura-filter conversion, avoiding unavailable Era spell IDs 28880 and 34976. Deferred insertion of converted filter names until iteration completes.
- Interim library changes were subsequently withdrawn in compat-20261010.1; the current implementation uses application-owned controls and profile switching.

## Earlier cumulative changes — Stages 01–01AM and Milestone 1

The source changelog groups these changes by feature and does not assign a reliable release date to each stage. They are retained here without invented dates.

### Core and client compatibility

- Added a private compatibility bootstrap and native/legacy API adapters for addon loading and metadata, spells, range and cooldown queries, auras, tooltips, and reputation.
- Added optional restriction-state monitoring and world-entry refreshes. Corrected the API lookup to `C_RestrictedActions.GetAddOnRestrictionState`, with a legacy fallback where available.
- Added explicit Era and Camelot entry points, optional DogTag manifests, client-specific module selections, and manifest diagnostics. Separated Forever/Camelot identity from Classic.
- Added default boss-group and focus units to existing TBC profiles inherited from earlier Classic releases in upstream v4.2.49.

### Blizzard frames, Edit Mode, and scenario targets

- Fixed scenario NPC targets remaining hidden or showing a stale previous unit when their GUID is restricted. Added private per-frame identity revisions, distinguished restricted live units from absent units, and refreshed matching frames and portraits when targets change.

### Health, power, and healing predictions

- Added example values and colors for configuration previews and guarded live reads during restricted startup. CombatFader remains visible when health or power data is inaccessible.
- Repaired shared bar getters, health-fraction scaling, and fill geometry. Preserved readable-value reverse, deficit, fade, animation, and extra-segment behavior while sending inaccessible values through native display methods.
- Preserved health-bar controls through death, ghost, disconnection, resurrection, and reconnection, with visible fallback values and appropriate state colors.
- Improved live unit-event updates and `best_unit` selection for swapped or target-chain frames. Corrected primary/alternate-mana hiding, the HealthBar queue-rename regression, and the duplicated color-options callback that prevented loading.
- Centralized VisualHeal control creation and corrected preview, incoming-heal, absorb, endpoint, and replacement-control handling. Inaccessible prediction data clears the affected overlay until readable data returns.

### Auras and tooltips

- Guarded aura fields, ownership, dispel types, sorting, filters, and highlights against restricted values. Replaced raw source-unit/name comparisons with derived ownership and stable numeric keys.
- Matched aura-tooltip refreshes by instance ID with spell-ID fallback, replacing name-based matching.
- Guarded stack counts, cooldown timing, and icon assignment, with spell-texture or sample-icon fallback when live icons are inaccessible.
- Added display/highlight filter fallback handling and removed reliance on the deprecated aura-consolidation tuple.
- Left unit-tooltip title coloring to Blizzard's native unit-tooltip path, avoiding restricted identity checks on compound units such as `targettarget`.

### Casting and text

- Guarded cast timing, interruptibility, identifiers, icon paths, and cached cast data. Restricted Retail casts suppress the cast display without preventing the owning unit frame from updating.
- Moved cast caches and ScriptEnv cast-data lookup to unit-token keys, including target-chain frames. Used token matching for cast-to-frame updates and latency player detection.
- Suppressed unsafe Mainline global-cooldown duration sizing while retaining cast-queue handling.
- Corrected LuaTexts pooled-table cleanup and guarded release of non-table input. Replaced CombatText's live FontString comparison with an internal preview-state flag.
- Kept DogTagTexts optional, corrected standalone library include paths, and modernized load-on-demand handling. Earlier supplied text-provider changes covered restricted compiler results, modern aura scanning, native/legacy cast APIs, and health/ghost-state calculations.

### Unit caches and indicators

- Added access-aware string, GUID, boolean, equality, and table helpers for core frame caches, LuaTexts status/event updates, Highlight, Border, and player/pet power matching.
- Replaced GUID-keyed throttled aura, health, power, and ready-check queues with unit-token keys; corrected queue iteration and avoided queued aura work while leaving the world.
- Used unit-token leader detection and handled ready-check frames represented by a target or `best_unit`.


#### Earlier implementation notes

- Earlier guarded normalization, secure-call, and string-conversion experiments were superseded by later access-aware boundaries and native rendering corrections.

## Validation

The full hotfix's recorded validation reports 1,453 offline assertions, 122 application Lua files, 91 XML files, and 16 root manifest load graphs. Those are historical release results. For this distribution, the four bundled default suites passed **1,425 assertions**, the 139-file library boundary was verified, and archive contents were compared byte for byte with the selected target.

Offline checks do not certify in-game taint, secrecy, secure execution, layout, or performance. Live-client validation remains pending.

## Installation and comparison record

This ZIP is a source overlay, not a standalone addon. Apply it to the supplied Midnight source with its existing packaged dependencies available. The baseline ZIP contains only five library files; 134 additional target library files are intentionally excluded. Obtain dependencies from the complete Class Resource Hotfix package if the installation does not already contain them. The optional `PitBull4_DogTagTexts` application files also require their existing libraries.

1. Back up the addon folders and retain SavedVariables.
2. Rename the baseline's `PitBull4-midnight` folder to `PitBull4` if necessary.
3. Extract the overlay into `Interface/AddOns`, allowing application files to be replaced.
4. Delete the obsolete files listed below. ZIP extraction cannot remove them.
5. Reload the UI and retest frame toggles and class-resource bars.

Obsolete baseline files:

- `PitBull4/Controls/StatusBar.lua`
- `PitBull4/ModuleHandling/SecretBarModule.lua`
- `PitBull4/Modules/Aura/UpdateCooldownTexts.lua`
- `PitBull4/Modules/Aura/UpdateWeaponEnchants.lua`

Release-specific historical change reports are omitted from this overlay because their change summaries are consolidated above. Technical validation and test documentation remain as supplied. This overlay cannot remove pre-existing historical changelog documents; retain `PitBull4/CHANGELOG.md` as the authoritative change history.

| Comparison | Result |
| --- | ---: |
| Modified application files | 75 |
| Added application/documentation files | 69 |
| Total overlay files | 144 |
| Obsolete files to delete | 4 |
| Library files in overlay | 0 |
| Consolidated changelog files | 1 |

Baseline SHA-256: `9f69052e0df465b5ead0dfd4cc5761c6fd34be4901071d77a29c744e01ebc976`  
Target SHA-256: `9cb2ee249cfae225d58c56c44a44d11b874124dc14f61dfa40a3d23e03348649`
