# PitBull4 Mists Blizzard-frame hiding hotfix

Date: 2026-10-08  
Version: **compat-20261008.3**  
Reported client: **5.5.4 build 70032, TOC 50504**  
Status: source repair and offline checks complete; in-game retest pending.

## Cause and repair

HideBlizzard passed six class-resource globals to its helper. In the supplied MoP client, arguments 3 through 6 are nil. The helper intentionally reported each nil argument when PitBull4.DEBUG was enabled, producing the four errors during profile initialization.

| Original argument | Mists build 70032 | Repaired handling |
| --- | --- | --- |
| 3: MonkHarmonyBarFrame | Frame is named MonkHarmonyBar | Use the Classic name when the modern name is absent |
| 4: PaladinPowerBarFrame | Frame is named PaladinPowerBar | Use the Classic name when the modern name is absent |
| 5: MageArcaneChargesFrame | No such frame in the supplied Mists UnitFrame source | Skip the optional frame |
| 6: EssencePlayerFrame | No evoker resource frame in this client | Skip the optional frame |

Source evidence is in `5.5.4.70032.zip`: `Blizzard_UnitFrame/MonkHarmonyBar.xml:83`, `PaladinPowerBar.xml:30`, and the class-resource entries in `Blizzard_UnitFrame.toc:41-57`. RuneFrame and WarlockPowerFrame retain their existing names.

Classic fallback names are restricted to the existing Classic client flag, which the compatibility adapter derives from WOW_PROJECT_ID. This matters because Retail/Forever use PaladinPowerBar as a mixin table; their native frame is PaladinPowerBarFrame. The same modern names are present in both supplied Retail snapshots and the Forever Mainline UnitFrame source.

Both local frame helpers now accept absent optional arguments. They continue to unregister events, hide available frames, and install the existing visibility hooks. Native castbar Show is still post-hooked with hooksecurefunc, and all existing out-of-combat wrappers remain in place.

The supplied ToDebugString traceback runs through BugGrabber while recording the original hide-frame error, then AceLocale's missing-key handler. No PitBull source requests that locale key. This indicates a secondary error-reporting lookup. Removing the false frame diagnostics removes the reported trigger; no fake translation or library modification is added. If the locale warning occurs with an unrelated future error, that error-reporting path needs a separate investigation.

## Baseline and preserved work

Immediate baseline: `PitBull4_Compatibility_Milestone_1_Full_2026-10-08.zip`, compat-20261008.2, SHA-256 `4d88afd259e00f36362e048ff9a5053c024774b1ac9f0faae127c846a972ecb0`.

The existing Classic Era atlas/spell-filter fixes and milestone changes remain. UnitFrame, CastBar, BetterStatusBar, and Aura/Filter are byte-identical to this immediate baseline. Outside the HideBlizzard source repair, changes are release metadata, the consolidated CHANGELOG.md, validation documentation, and offline test evidence. No new framework dependency, SavedVariables migration, event, polling loop, or secure attribute is introduced.

## Verification

- Existing compatibility suite: **257 assertions pass**.
- New HideBlizzard suite: **99 assertions pass**. The Mists reproduction fails against the old module before the patch.
- **227 Lua files** parse with texluac/Lua 5.3.6; **91 XML files** parse; all **16 root TOC/XML load graphs** resolve. Both offline harnesses are absent from game load graphs.
- Focused checks cover Mists aliases, nil optional frames, modern frame names and mixin avoidance, profile refreshes, existing reload notices, retained castbar hooks, and combat callback scheduling under a stub.

These are source and offline checks. No Warcraft client or Lua 5.1 compiler is available here; the tests do not emulate Blizzard's taint or secure-execution engines. The wider feature and client validation matrix remains in `COMPATIBILITY_VALIDATION.md`.

## Install and retest

The full ZIP supplies complete PitBull4 and optional PitBull4_DogTagTexts folders. Replace the installed addon folders and retain SavedVariables. The changed-files ZIP is an overlay for **compat-20261008.2 only**; it is not a standalone addon.

On Mists 5.5.4 build 70032:

1. Login with the existing profile and open `/pb`; confirm the four invalid-frame reports and associated locale warning are absent.
2. With Class power bar hiding enabled, test a monk and paladin, plus a death knight/warlock where available. Blizzard resource bars should remain hidden while the corresponding configured PitBull resource displays work.
3. Switch profiles, toggle configuration mode, and reload. Toggling hiding off after frames were hidden should retain the existing reload notice; verify normal Blizzard bars return after the reload.
4. Enter combat and leave combat with a castbar enabled; check that no new blocked-action report occurs and the configured Blizzard-frame hiding persists.
5. Confirm the selected manifest remains PitBull4_Mists.toc and the runtime version is compat-20261008.3.

Retest Era login/options and Retail/Forever frame hiding separately before making a broader compatibility claim.
