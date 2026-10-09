# PitBull4 compatibility milestone 1

Date: 2026-10-08  
Package version: **compat-20261008.5** (milestone 1 with Era, Mists, Forever TOC, and options checkbox hotfixes)  
Status: **Implementation and isolated checks complete; in-game validation pending**

## Forever options checkbox hotfix 4

The immediate baseline is the latest compat-20261008.4 full milestone package, SHA-256 `20dcecd3d675a6b4b7b90a7a8284f7369aa9dbbe3bbdb598d1b84b1256387aee`. The user reported a nil-function error at AceGUIWidget-CheckBox.lua:130 when opening options on Forever 1.60.1 build 70291.

The failing function is the legacy global SetDesaturation(texture, boolean), not a texture method. The supplied Forever and Retail sources no longer define this global. Era and Mists still define it as a thin wrapper around Texture:SetDesaturated(boolean). SimpleTextureBaseAPIDocumentation.lua documents the native boolean method in all five supplied sources: Forever 1.60.1.70291, Era 1.15.9.69547, Mists 5.5.4.70032, Retail 12.1.0.69933, and Retail 12.1.5.70077. The widget now calls that shared native method directly at all six call sites, without a project branch or replacement global.

The CheckBox widget revision increases from 26 to 27. The real bundled AceGUI registration and pool logic then replace an older constructor, discard version-26 pooled controls, and prevent a later version-26 copy from overwriting the repair. An already registered newer widget remains authoritative. The core AceGUI library revision is unchanged.

A temporary offline harness loaded the actual bundled LibStub, AceGUI core, and widget with narrow frame/texture stubs and the legacy global absent. It reproduced the original error and passed 113 checks after the repair. Cases cover initial acquisition, checked/unchecked appearance, clicks/callbacks/sounds, disabled input, programmatic changes while disabled, three-state cycling, radio style, descriptions, release/reacquisition, old pooled widgets, and widget load order. The same shared texture contract was exercised under the five supplied client labels; these are isolated tests, not real client executions. The existing 257 compatibility and 99 HideBlizzard assertions also pass under Lua 5.3. Lua 5.1 compilation and in-game validation remain unavailable/pending.

All 24 package manifest versions and the runtime version identify compat-20261008.5. The six Forever Interface declarations remain 16001. The changed-files ZIP overlays compat-20261008.4; use the complete full ZIP when the installed base is older or uncertain. Earlier Era, Mists, scenario-target, and Forever TOC fixes are retained.

Close the game before replacing files. On Forever, open `/pb`, toggle a checkbox, visit options with disabled and three-state controls where present, then close and reopen options. Confirm no checkbox error and the expected checked/disabled appearance. Repeat normal options opening on the supported Era, Mists, and Retail clients. Record any remaining traceback and the selected package version.

## Forever TOC hotfix 3

The immediate baseline is the latest compat-20261008.3 milestone package, including both previous client hotfixes. The user reported Forever **1.60.1, build 70291, dated October 7, 2026, TOC 16001**. The updated supplied UI source agrees on version/build (`version.txt`: `1.60.1.70291`) and defines `WOW_PROJECT_CAMELOT = 18` in `Blizzard_ProjectConstants/Camelot/ProjectConstants.lua`.

The six core, standalone DogTag, and source DogTag Camelot/generic manifests still declared `Interface: 0`. They now declare `Interface: 16001`, and their pending Interface metadata has been replaced with the confirmed client values. All 24 package manifests and the runtime version string now identify compat-20261008.4. Other clients retain their previous Interface declarations. This corrects the known metadata mismatch; the selected manifest and gameplay behavior still require confirmation in-game.

No gameplay logic, XML load list, library, profile field, event registration, or protected-frame behavior changes in this hotfix. The existing Era and Mists fixes are retained. The changed-files ZIP is an overlay for **compat-20261008.3 only**; the full ZIP is a complete replacement package. The consolidated changelog records this update.

Verification confirms all six Forever Interface declarations, all 24 package version declarations, and all 16 runtime addon TOC/XML load graphs. The existing regression suites pass 257 and 99 assertions. Byte comparison confirms that XML and Lua implementations are unchanged apart from the runtime version string, whose syntax check passes. These offline checks do not establish in-game loading or gameplay compatibility.

Close the game before installing the updated files, then reopen it and check the AddOns list with out-of-date loading disabled. PitBull4 and optional PitBull4_DogTagTexts should no longer be rejected for the previous Interface mismatch. Confirm login, player/target frames, and `/pb` options, then continue the wider client checks below. Test DogTag separately when enabled.

## Mists hotfix 2

The immediate baseline is the compat-20261008.2 full milestone ZIP, SHA-256 `4d88afd259e00f36362e048ff9a5053c024774b1ac9f0faae127c846a972ecb0`. The reported client is Mists 5.5.4 build 70032, TOC 50504.

- HideBlizzard accepts nil optional frame arguments in its class-resource and ordinary frame helpers. Unsupported frames are no longer reported through the global error handler.
- Classic selects MonkHarmonyBar and PaladinPowerBar when their modern frame names are absent. Retail/Camelot keep their modern names; their PaladinPowerBar mixin is not treated as a frame.
- The supplied traceback indicates that the ToDebugString locale warning occurs while BugGrabber records the original frame diagnostic. PitBull has no source lookup for that locale key. Removing the invalid optional-frame diagnostics removes this reported trigger; AceLocale and locale data are unchanged.
- Out-of-combat wrappers and the native castbar Show secure post-hook are preserved. The change adds no event, polling loop, SavedVariables field, or dependency.
- The new HideBlizzard suite fails on the old module and passes 99 assertions on the repaired module. The existing 257-assertion compatibility suite also passes.

See `MISTS_HOTFIX.md` for source evidence and focused in-game retest steps. The previous Era fixes are retained; the wider compatibility audit and runtime checks remain pending.

## Classic Era hotfix 1

The compat-20261008.1 milestone was reported to fail on Classic Era 1.15.9 at Texture:SetAtlas, and to print invalid spell IDs 28880 and 34976. This hotfix uses that exact milestone archive, SHA-256 `de33bac7861cc8ab2fddfa0db35d7629cd71beb314521b0a50b74d5fe19162ef`, as its immediate code baseline.

- BetterStatusBar and LiveStatusBar clear atlases by restoring their ordinary texture with SetTexture. Native Texture:SetAtlas is called only with an atlas name. BetterStatusBar retains the normal texture and bypasses its same-texture shortcut while an atlas is active.
- Shared aura-filter conversion and saved-name-list migration use the private DoesSpellExist adapter before name lookup. Spells absent from the active client are omitted. Supported expansion spells remain available. Debug diagnostics remain for an existing spell whose name lookup unexpectedly fails.
- Saved-filter conversion merges new name keys after numeric-key iteration, preventing table rehashing from invalidating next(). A single temporary conversion table is reused across filters in that profile callback.
- The strict offline texture stub reproduced the original atlas error before the bar fix. New cases cover Era/Mainline/Mists/Camelot bar resets, custom textures, reuse, same underlying assets, and public/native renderer transitions; aura cases cover native Era, legacy Era fallback, TBC, Mists, and Retail conversion.

The supplied Era source `1.15.9.69547(1).zip` documents a required atlas name for SetAtlas, a nil-accepting texture asset for SetTexture, and C_Spell.DoesSpellExist as a database-existence check independent of whether the player learned the spell. Relevant files: `Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua` and `SpellDocumentation.lua`. Matching capability contracts were checked against the supplied Retail, Mists, and Forever source snapshots.

All previous milestone changes are retained. The UnitFrame and CastBar source files remain byte-identical to the original scenario-target baseline. HideBlizzard was unchanged by the Era fix; the current Mists fix changes only its optional-frame handling and Classic class-bar aliases. No new library, event, polling loop, secure attribute, or SavedVariables schema is introduced. These hotfixes do not complete the wider compatibility audit; all client acceptance tests below remain required.

## Baseline

This milestone uses the supplied **PitBull4-Scenario-Target-NPC-Secret-Identity-Fix-2026-08-23(1).zip**, SHA-256 `19505255c2dd323e68a5df61fa7cea3e25df26eaf5bb4a8a74067039640f953b`. It follows the first implementation milestone in **PitBull4_Replacement_Cross_Client_Compatibility_Report_2026-10-08.md**: repair client entry points/initialization and the shared native health-bar contract.

The existing scenario NPC identity, hidden-target refresh, and secure castbar-hiding implementations are preserved. Their source files were compared byte for byte with the baseline.

## Implemented

- Added core and optional DogTag Vanilla/Era, Classic alias, and Camelot manifests, plus generic Camelot fallback manifests. Era and Camelot have separate module lists. Camelot uses the existing access-aware cast implementation and a nine-class gameplay selection; expansion class-resource modules are excluded from these two new paths.
- Activated a rewritten, single-file private compatibility adapter before libraries and core startup. It does not write wrappers into Blizzard namespace tables. Unknown project IDs are explicitly unknown. Camelot is distinct from both Retail and generic Classic, and restriction-state handling is selected by API capability.
- Made the specialization database enhancement optional, allowing regular Era initialization when LibDualSpec deliberately declines to load. Corrected the bundled library to use the native specialization getter on specialization-based clients. Its patch revision is 28.1, so it can upgrade an older bundled revision 28. The release configuration retains this patched bundled copy.
- Normalized legacy spell-range answers to boolean/nil and legacy cooldowns to the native table contract. Addon-management calls preserve native and legacy argument order. Selected core/options, aura, range, Lua-text, latency, and DogTag consumers use these private adapters.
- Repaired LiveStatusBar's recursive color accessor and missing texture/fill contract. Its stable outer control retains the existing renderer and geometry for readable values, while opaque values go directly to native StatusBar methods. Mode changes keep the same health control instance.
- Restored public-value deficit, reverse, extra-segment, fade, and animation behavior. Protected values use native interpolation, with native health/power percentage APIs and a reverse curve for supported deficit display. The UI descriptions explain that fade and custom animation duration apply when values are readable. Animation/fade settings recover when values become readable again.
- Corrected health percentages to use the native zero-to-one fraction without multiplying by 0.01. Health values are checked for accessibility before numeric processing. Unknown live health is no longer reported as known full health; dead/disconnected readable placeholders retain their configured appearance.
- Repaired VisualHeal configuration examples and public healing/absorb overlays. They attach to the actual fill endpoint, tolerate missing incoming-heal APIs, clear when geometry is protected, and rebuild if the health control is replaced.
- Applied access checks to shared numeric normalization and primary/alternate-mana processing. Primary power's raw path respects readable hide settings, and alternate mana's raw path respects “Hide if full.”
- Removed the aura-consolidation dependency on the optional UnitAura global and its incorrect return-16 assumption. A native consolidation flag is preserved where provided; otherwise the flag is false.
- Capability-checked optional health, specialization, expansion, and restriction-state events. Corrected DogTag's whitespace pattern to Lua's `%s` form. Updated the consolidated changelog and aligned package-version strings.

## Client entry points

Interface declarations for the standard clients reflect the supplied version labels and still require comparison with the fourth GetBuildInfo() return value in-game.

| Client | Core entry point | Module path | Validation status |
| --- | --- | --- | --- |
| Retail 12.1.0 / 12.1.5 | PitBull4_Mainline.toc; declarations 120100, 120105 | modules.xml | Source/isolated checks; game tests pending |
| Mists 5.5.4 | PitBull4_Mists.toc; declaration 50504 | modules_Mists.xml | Source/isolated checks; game tests pending |
| Era 1.15.9 | PitBull4_Vanilla.toc; declaration 11509; Classic alias available | modules_Vanilla.xml | Initialization guard checked; game tests pending |
| Forever/Camelot 1.60.1 build 70291 | PitBull4_Camelot.toc or generic PitBull4.toc; declaration 16001 | modules_Camelot.xml | Interface confirmed by the user; actual TOC selection and gameplay tests pending |
| TBC / Cataclysm | Existing TBC/Cata manifests retained | Existing lists | Unverified targets; no new compatibility claim |

**Forever's Interface value is now confirmed as 16001 for the reported 1.60.1 build 70291 client.** All six core, standalone DogTag, and source DogTag Camelot/generic manifests use that value. The generic manifest remains a Camelot fallback. Each manifest includes `X-PitBull4-Manifest` so the selected file can be identified in-game. Client updates may require a new Interface declaration; a metadata correction does not establish runtime compatibility.

## API contracts

| Family | Current native behavior | Private fallback / decision |
| --- | --- | --- |
| Addon management | Captured C_AddOns functions | Legacy globals; corrected enable-state argument order |
| Spell metadata/range/cooldown | Captured individual C_Spell functions | Native-shaped information/cooldown tables; range boolean/nil |
| Specialization profiles | C_SpecializationInfo.GetSpecialization for spec-based clients | Talent-group getter only for that system; optional library at startup |
| Restriction state/events | Capability-based state handling, including Camelot | Absent optional capabilities do not register those events |
| Health/power display | Native StatusBar sinks and percentage/reverse-curve APIs for opaque values | Existing renderer and arithmetic only for readable values |
| Aura consolidation | Native aura-table field where supplied | False when absent; no deprecated tuple/global dependency |

The adapter itself has no framework dependency. The complete addon remains modular and uses its bundled Ace3 and other libraries. Whole-addon dependency removal, one-file flattening, and explicit addon-frame Edit Mode integration remain separate work.

## Verification

- **227 Lua files parse with texluac/Lua 5.3.6:** 225 addon files plus two offline regression harnesses. All **91 XML files** parse.
- All **16 root TOC/XML graphs** resolve. The private adapter loads before LibDualSpec and Main.lua in every core graph. Era/Camelot graphs omit the expansion-resource modules, and the Camelot graph selects the intended cast implementation.
- **257 isolated regression assertions pass.** They cover client identity, partial native namespaces, adapter contracts, optional event/library behavior, native specialization selection, health fractions/colors, raw/native transitions, death and recovery, public deficit/reverse/animation/fade, restored settings after protection, shared update-handler integration, VisualHeal configuration/live/absorb geometry and replacement, power hide settings, alternate-mana hiding, and aura consolidation with deprecated fallbacks unavailable.
- **99 additional HideBlizzard assertions pass.** They cover Mists aliases, absent optional frames, Retail/Camelot names and mixin avoidance, profile refreshes, reload notices, preserved native castbar hooks, and callback deferral under a combat scheduling stub.
- The original UnitFrame.lua and Modules/CastBar/CastBar.lua remain byte-identical to the scenario-target baseline. BetterStatusBar and Aura/Filter remain byte-identical to compat-20261008.2.

The harnesses are **offline only** and are not referenced by any addon manifest. From a directory containing the extracted PitBull4 folder, run `texlua PitBull4/Tests/compatibility_regressions.lua` and `texlua PitBull4/Tests/hide_blizzard_regressions.lua`. They execute actual module/control functions with narrow API/widget stubs. Opaque stand-ins verify that guarded paths avoid ordinary arithmetic/formatting; they do not emulate Blizzard's secrecy, taint, layout, or secure-execution engine. No Warcraft client or Lua 5.1 compiler was available. No in-game compatibility pass or performance improvement is claimed.

## Install and validate

The full ZIP contains the complete PitBull4 and optional PitBull4_DogTagTexts folders. Close the game and replace the existing addon folders with these folders. The current Forever checkbox changed-files ZIP applies only to compat-20261008.4 and requires all existing files and bundled libraries. SavedVariables/profile schema is retained. DogTag is optional and remains disabled by default within PitBull.

Start with Era and Forever, then repeat the common checks on Retail 12.1.0, Retail 12.1.5, and Mists 5.5.4:

1. Record the client build/interface before loading the addon:
   ```lua
   /run local v,b,d,i=GetBuildInfo();print("Project",WOW_PROJECT_ID,"Version",v,"Build",b,"Interface",i)
   ```
   On the reported Forever build, the expected Interface is 16001. Once loaded, record the selected TOC and package version:
   ```lua
   /run print(PitBull4.Compat.AddOns.GetAddOnMetadata("PitBull4","X-PitBull4-Manifest"),PitBull4.version)
   ```
2. Use only this addon and its bundled contents first. Regular Era must reach options and populate player/target frames without another addon supplying LibDualSpec. Test an existing profile as well as a clean profile.
3. Check full, half, low, and zero health; death/ghost/disconnect and recovery; public health gradients; primary and alternate mana; readable hide settings; reverse/deficit; and animation/fade restoration after restricted data becomes readable.
4. Enable VisualHeal. Check configuration samples, public incoming/player healing and absorbs, vertical/horizontal bars, reversed/deficit bars, and recovery after restricted data or control replacement. Protected overlays currently clear by design.
5. Repeat no-target → scenario NPC → different NPC → player/public target transitions, including target-of-target and reused visible frames. Confirm existing secure targeting and castbar hiding remain functional.
6. Check aura handling with deprecation fallbacks enabled and disabled, reload/relog position retention, profile/spec changes where supported, combat, and Edit Mode entry/exit. Test optional DogTag separately.

Capture exact build/interface/manifest/version, enabled modules, reproduction steps, Lua/blocked-action logs, and screenshots. A pass requires supported features to display correctly and the relevant paths to produce no Lua or blocked-action errors.

## Remaining advised work

The wider restricted-value audit remains pending: class resources, range/aura unit comparisons and helpers, role/PvP/tooltip/identity color paths, threat, and native feature parity. Missing/delayed Blizzard-frame assumptions, explicit Edit Mode coordination, module-level gameplay routing, and optional cast/empower behavior still require review and runtime testing. Broader performance changes await idle and active measurements. Confirm all interface declarations and every claimed client in-game before preparing a public release.
