# Milestone 1 refactor — compat-20261010.1

The compatibility implementation now changes application files only. All 139 bundled library files are byte-identical to the supplied scenario-target baseline; no library files were added or removed.

## Changes from compat-20261008.5

- Restored the original AceGUI CheckBox, LibDualSpec, and standalone DogTag Compiler files.
- Added SpecProfiles.lua, a PitBull-owned event-driven profile controller. It replaces LibDualSpec calls and its load/dependency declarations while preserving existing character mappings and older alternate-profile data. It defers profile changes during combat and handles unavailable/delayed specialization data.
- Added Options/NativeControls.lua with native toggle, multiselect, three-state, and radio controls. PitBull's options provider routes these through PitBull-specific widget types; shared AceGUI controls are untouched. AceConfig/AceGUI still supplies the surrounding options window.
- Added the application load-list changes, localization keys, four-suite regression coverage, project instructions, a locked library hash inventory, and a verifier for future milestones.
- Preserved earlier application compatibility changes and Forever Interface 16001 metadata. The previous DogTag compiler whitespace edit is withdrawn.
- Updated all 24 application manifests and the runtime to compat-20261010.1.

## Cumulative milestone scope

The milestone retains private cross-client adapters and Era/Camelot entry points; shared native/readable health and power bars; fraction, deficit, reverse, fade, and animation behavior; VisualHeal overlays; Era atlas/spell-filter fixes; Mists Blizzard-frame handling; and the original scenario-target/secure castbar implementation. CHANGELOG.md contains the complete history. COMPATIBILITY_VALIDATION.md describes the current implementation and remaining work.

## Evidence and use

544 offline assertions pass, including actual untouched AceConfig and AceDB integration. All 122 application Lua files and 91 XML files parse, all 16 root load graphs resolve, and all 139 library hashes match. Five negative guard cases also pass. In-game and Lua 5.1 validation remain pending.

Use the full package to replace an earlier modified milestone and restore its original libraries. The application-only changed distribution excludes every lib/libs folder. It is a source overlay against the supplied master ZIP, with the original bundled libraries supplied separately; it cannot restore the three altered libraries from an older milestone.

Future milestones must replace library-dependent application code with PitBull-owned native implementations. Vendor files, inventory, shared functions, built-in widget factories, and library versions remain unchanged.
