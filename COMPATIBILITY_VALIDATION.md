# PitBull4 compatibility milestone 1

Date: 2026-10-10  
Package version: **compat-20261010.3**  
Status: **Implementation and offline checks complete; in-game validation pending**

## Midnight class-resource parent correction

Reported client: Retail Midnight 12.1.0 build 69933, dated September 18, 2026, Interface 120100. Immediate input: PitBull4_Frame_Toggle_Hotfix_Full_2026-10-10.zip (compat-20261010.2).

The previous hotfix reparented WarlockPowerFrame to a private hidden frame. Blizzard's ClassPowerBar:GetUnit() reads self.unit or self:GetParent():GetParent().unit; the reported bar has no cached unit, and the hidden frame has no parent. WarlockPowerBar:OnEvent() calls UpdatePower() on both PLAYER_REGEN_DISABLED and PLAYER_REGEN_ENABLED, including when the bar belongs to an inactive class. The supplied old release reproduces the exact ClassPowerBar.lua:11 error offline using the original Blizzard source.

The runebar hider now passes `not PitBull4.wow_classic` to the existing suppression helper. Modern bars keep their native parents, shown state, events, and managed-layout membership while alpha and mouse suppression remain reversible. The change applies to RuneFrame, WarlockPowerFrame, MonkHarmonyBarFrame, PaladinPowerBarFrame, MageArcaneChargesFrame, and EssencePlayerFrame. Classic keeps the existing parent suppression and Mists aliases. No Blizzard function, unit field, namespace, or library is replaced.

| Supplied source / API | Checked behavior |
| --- | --- |
| Retail 12.1.0.69933: Blizzard_UnitFrame/ClassPowerBar.lua, GetUnit(), line 11 | Native grandparent lookup preserved, including missing cached unit and vehicle unit |
| Retail 12.1.0.69933: Blizzard_UnitFrame/ShardBar.lua, OnEvent(), lines 10–15 | Original Warlock combat-entry/exit callbacks succeed for active and inactive bars |
| Retail 12.1.0.69933: Blizzard_UnitFrame/ClassResourceBarTemplate.lua | Original Setup() and UpdateMaxPower() retain the parent-unit chain and existing resource pool |
| Retail 12.1.5.70077 / Forever 1.60.1.70338 | Matching original class-resource implementations execute under the same offline regression fixtures |
| Mists / Cata / Era / TBC fixtures | Existing Classic expansion gate, missing optional frames, resource aliases, and parent-suppression path retained |
| Shared frame methods: SetAlpha / EnableMouse | Existing reversible suppression reused; no new client-specific API or polling loop |

Install either the full replacement or the changed-only overlay on the supplied Frame Toggle Hotfix, then reload once to load the repaired module and rebuild native Blizzard parenting. On build 69933, enter a delve, start and end several fights, generate/spend Soul Shards if playing a Warlock, and toggle Class power bar with Player both checked and unchecked. Repeat a toggle in combat, change profiles, and disable the module. Confirm the bar restores outside combat or immediately after combat and capture any Lua or blocked-action errors. Validate an inactive Warlock bar on another class as well.

## Reversible Blizzard frame toggles

The Hide Blizzard frames module now releases suppression when a frame group is unchecked, a profile stops hiding it, or the module is disabled. Outside combat this is immediate; combat changes apply after PLAYER_REGEN_ENABLED and use the latest selected settings. A private native listener completes pending restoration even after module disable.

Unit/group frames and Classic resources retain their native events, unit watches, local shown state, and party frame pools. Their original or latest Blizzard-requested parent is restored. Modern class-resource bars, cast bars, and the alternate-power bar retain native parenting, methods, animation state, and contextual visibility, using reversible alpha and mouse suppression. The alternate-power bar's native OnHide reparents itself, so it must keep its parent rather than use ancestor suppression. No Blizzard method or global is replaced. Raid IsShown settings and CVars are not modified. No new polling loop is introduced.

| Supplied client source | Frame handling used |
| --- | --- |
| Retail 12.1.0.69933 / 12.1.5.70077 | Modern unit/party/arena roots; lazy compact-frame generation hooks; native class-resource/cast-bar parenting retained |
| Forever 1.60.1 build 70338 | Modern unit/party/compact-frame APIs with existing Camelot gameplay routing; native class-resource/cast-bar parenting retained when the existing class-resource gate is active |
| Mists 5.5.4.70032 | Shared frame APIs; Classic MonkHarmonyBar/PaladinPowerBar aliases when modern names are absent |
| Era 1.15.9.69547 / TBC 2.5.6 build 69795 | Shared frame APIs; optional frame/resource handling; legacy party globals when PartyFrame is absent |
| Cataclysm | Existing Classic expansion routing covered by offline fixtures; no new supplied source or in-game pass |

The correction is contained in Modules/HideBlizzard/HideBlizzard.lua. All lib/libs contents and the locked baseline inventory remain unchanged. The full release retains the original milestone 1 refactor, and the changed-only hotfix compares directly with the supplied PitBull4_Frame_Toggle_Hotfix_Full_2026-10-10.zip. Historical milestone comparison records retain their original baselines.

## Application-only refactor

All 139 files beneath a lib/libs directory match the supplied scenario-target baseline byte for byte. This includes nested module libraries, assets, manifests, and the standalone PitBull4_DogTagTexts libraries. No library is added, removed, upgraded, patched, or monkey-patched by this milestone.

The three earlier milestone library edits have been reverted:

| Restored file | Current application behavior |
| --- | --- |
| PitBull4/Libs/AceGUI-3.0/widgets/AceGUIWidget-CheckBox.lua | Options/NativeControls.lua supplies PitBull's own native controls. The shared CheckBox remains version 26 with its original constructor. |
| PitBull4/Libs/LibDualSpec-1.0/LibDualSpec-1.0.lua | SpecProfiles.lua handles specialization profiles; the library is no longer included by libs.xml or core OptionalDeps. |
| PitBull4_DogTagTexts/Libs/LibDogTag-3.0/Compiler.lua | The original compiler is preserved. The previous whitespace-pattern change is withdrawn; further DogTag migration is deferred. |

SpecProfiles.lua uses native specialization/talent-group capabilities and native events. It preserves the existing character namespace named LibDualSpec-1.0 as a saved-data identifier, without loading that library or adding its methods to the database. Existing mappings and older alternate-profile data are retained. Invalid or unavailable specialization data does not cause a profile switch; changes during combat apply after combat. The existing AceDB database and profile-options table remain dependencies during this milestone.

NativeControls.lua creates native toggle controls without a library, including disabled and three-state appearance, descriptions, icons, and callbacks. Application-owned multiselect and radio controls reuse those native toggles and reflow on width changes. A small adapter registers only PitBull-specific AceGUI types. PitBull's option provider prepares these controls on every query, including later module/plugin options, while respecting explicitly selected foreign controls. The options window still uses AceConfig/AceGUI. No built-in widget, shared constructor, Blizzard global, library version, or library API is replaced.

The reported Forever checkbox failure is reproduced with the restored vendor widget when the removed SetDesaturation global is absent. The same unchanged AceConfig renderer opens and operates PitBull's replacements successfully under the offline fixtures. They use Texture:SetDesaturated, documented in all five supplied client source snapshots. Those source checks establish the API contract; client rendering and secure behavior still require in-game validation.

AGENTS.md records the boundary for later work. Tests/library_baseline_hashes.json records every library digest and the supplied archive digest. Tests/verify_library_boundary.py rejects changed bytes, changed inventory, and library entries in changed-only ZIPs. Do not refresh packaging externals or regenerate the hashes to accept a library update; build against the locked supplied files and run the verifier before distributing a milestone.

## Baseline and retained changes

The library and original application baseline is PitBull4-Scenario-Target-NPC-Secret-Identity-Fix-2026-08-23(1).zip, SHA-256 19505255c2dd323e68a5df61fa7cea3e25df26eaf5bb4a8a74067039640f953b. The immediate refactor input is the compat-20261008.5 full milestone, SHA-256 88d545d48d3d536ac5ef9c5dd8083e5f9f35f8d46ec12721eddf71b38f61db2c.

The cumulative application implementation retains:

- Explicit Era/Camelot core and optional DogTag entry points, separate module selections, manifest diagnostics, and Forever Interface 16001 declarations.
- A private compatibility adapter loaded before libraries and startup. It distinguishes Camelot, normalizes addon/spell/range/cooldown contracts, and checks optional native capabilities/events without writing into Blizzard API tables.
- Shared health/bar correctness: native sinks for inaccessible values, readable-value geometry, deficit/reverse/fade/animation behavior, fraction scaling, stable controls, and recovery from dead/disconnected and restricted states.
- VisualHeal configuration and readable incoming-heal/absorb overlays, including fill endpoints, missing optional APIs, and control replacement. Protected geometry clears overlays.
- Readability guards for numeric normalization and primary/alternate-mana hide behavior.
- Aura consolidation without the deprecated tuple/global assumption, and Era spell availability checks before shared-filter/name conversion. Saved-filter insertions are deferred until numeric-key iteration completes.
- Atlas reset through SetTexture, retaining custom textures and clearing stale atlas state on pooled controls and renderer changes.
- Mists optional Blizzard-frame handling and Classic MonkHarmonyBar/PaladinPowerBar aliases, now using reversible suppression and a native combat listener.

UnitFrame.lua and Modules/CastBar/CastBar.lua remain byte-identical to the original supplied scenario-target baseline. The full change history is in CHANGELOG.md; older library-based implementations are explicitly marked superseded there.

## Client entry points

| Client | Core manifest | Interface | Status |
| --- | --- | --- | --- |
| Retail 12.1.0 / 12.1.5 | PitBull4_Mainline.toc | 120100, 120105 | Supplied-source/offline checks; in-game tests pending |
| Mists 5.5.4 | PitBull4_Mists.toc | 50504 | Supplied-source/offline checks; in-game tests pending |
| Era 1.15.9 | PitBull4_Vanilla.toc; Classic alias retained | 11509 | Regular Era needs no specialization library; in-game tests pending |
| Forever/Camelot 1.60.1 build 70291 | PitBull4_Camelot.toc or PitBull4.toc | 16001 | Interface confirmed by the user; TOC selection/gameplay tests pending |
| TBC / Cataclysm | Existing TBC/Cata manifests | Existing values retained | Unverified targets; no new compatibility claim |

The six core, standalone DogTag, and source DogTag Camelot/generic manifests retain Interface 16001. All 24 application manifest versions and the runtime version identify compat-20261010.3. Updated clients may need revised declarations; metadata does not establish runtime compatibility.

## Verification

All **1,453 offline assertions pass** with the supplied Retail 12.1.0 source passed to the HideBlizzard suite. Without external Blizzard source, the four default suites pass 1,425 assertions:

| Suite | Assertions | Coverage |
| --- | ---: | --- |
| compatibility_regressions.lua | 252 | Client/capability adapters, bar rendering transitions, health/power, VisualHeal, atlas resets, and aura/filter conversions |
| hide_blizzard_regressions.lua | 1,008 | Reversible toggles, native lifecycle/parent/alpha/mouse preservation, overlap, profiles, lazy frames, combat/disable restoration, and original Blizzard class-resource callbacks (980 checks without external source) |
| native_options_regressions.lua | 130 | Actual untouched AceConfig renderer; toggle/multiselect/three-state/radio interactions, disabled input, resizing, pooled reuse, late options, and unchanged shared checkbox |
| spec_profiles_regressions.lua | 63 | Native versus talent-group selection, existing/older mappings, combat deferral, delayed data, actual untouched AceDB/AceDBOptions, profile deletion/reset, initialization order, and no LibDualSpec registration |

All **122 application-owned Lua files** parse with texluac/Lua 5.3.6; all **91 XML files** parse; all **16 root TOC/XML load graphs** resolve. Every core graph loads Compat.lua before SpecProfiles.lua and Main.lua, loads NativeControls.lua before Options.lua, and excludes LibDualSpec. Tests are absent from addon load graphs. All 139 library digests and their inventory match the baseline. Five negative guard checks reject modified, missing, added, mixed-case, and backslash-separated library paths.

The harnesses run actual application code, selected unchanged library code, and supplied Blizzard class-resource source with narrow API/frame fixtures. They do not emulate Blizzard secrecy, taint, real layout, protected execution, or performance. A Lua 5.1 compiler and Warcraft client are unavailable; no in-game compatibility or performance pass is claimed. Commands are in Tests/README.md; current checks are in Tests/class_resource_hotfix_results.json. Earlier result files are historical records.

## Installation and in-game checks

**Use the full replacement to move from an earlier milestone with modified libraries.** Close the game and replace the PitBull4 and optional PitBull4_DogTagTexts addon folders with the full package folders. Keep existing SavedVariables/profile data. The changed-only ZIP contains no library files and cannot restore an earlier milestone's altered library files. This hotfix overlay compares against PitBull4_Frame_Toggle_Hotfix_Full_2026-10-10.zip and assumes that release is installed.

Record GetBuildInfo(), WOW_PROJECT_ID, X-PitBull4-Manifest, and PitBull4.version. Test Era and Forever first, then Mists and both supplied Retail targets:

1. Open /pb; change a toggle, disabled/three-state settings where present, multiselects, and radio settings. Resize, close, and reopen the window. Confirm the original checkbox error does not recur.
2. With existing profile bindings, switch specializations or talent groups and confirm the correct profile. Test enable/disable, creation, deletion, relog, and a specialization transition during combat. Regular Era must initialize without a specialization library or season API.
3. Test health/power at varied values; death/disconnect/recovery; readable/restricted display transitions; reverse/deficit/fade/animation settings; and VisualHeal geometry.
4. Repeat no target to scenario NPC to different NPC to player/public target transitions, including reused frames and target-of-target. Check secure targeting and castbar hiding.
5. Check each Hide Blizzard frames option on and off outside combat; a valid frame should return immediately. Targets, pets, party/raid/boss/arena frames, and cast/alternate-power bars should appear only in their normal context. Repeat during combat, switch profiles, and disable/re-enable the module. Check raid-style party overlap and raid display preferences. Enter/exit Edit Mode, check Mists aliases, and test optional DogTag separately.

For this hotfix, install the full package or overlay the changed-only ZIP onto the supplied Frame Toggle Hotfix, then log in (or reload once if replacing files while the client is open). The initial reload loads the correction and rebuilds native class-resource parenting. Subsequent toggles do not require reloading or relogging.

Capture the exact build/interface/manifest/version, enabled modules, reproduction steps, Lua/blocked-action logs, and screenshots for failures.

## Remaining migration

Whole-addon dependency removal, remaining Ace3/media/serialization consumers, DogTag replacement, one-file flattening, and explicit Edit Mode integration remain later work. The broader restricted-value audit and per-client gameplay routing also remain pending. Future milestones must move dependent application code into PitBull-owned native implementations while leaving all lib/libs contents intact.
