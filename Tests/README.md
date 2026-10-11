# Offline verification

These files are not loaded by Warcraft. Run from the directory containing the extracted PitBull4 and PitBull4_DogTagTexts folders:

    texlua PitBull4/Tests/compatibility_regressions.lua
    texlua PitBull4/Tests/hide_blizzard_regressions.lua
    texlua PitBull4/Tests/native_options_regressions.lua
    texlua PitBull4/Tests/spec_profiles_regressions.lua
    python3 PitBull4/Tests/verify_library_boundary.py

The four default Lua suites pass 252, 980, 130, and 63 assertions respectively: **1,425 total** for compat-20261010.3. Passing the supplied Blizzard_UnitFrame source directory as the frame suite's second argument adds checks against the original callbacks: **1,008 frame assertions / 1,453 total**. Runtime: Lua 5.3.6. A Lua 5.1 compiler and Warcraft client were unavailable. Narrow fixtures do not certify taint isolation, secrecy, real layout, secure execution, or performance.

    texlua PitBull4/Tests/hide_blizzard_regressions.lua PitBull4/ /path/to/12.1.0.69933/Blizzard_UnitFrame

The optional source route loads ClassPowerBar.lua, ClassResourceBarTemplate.lua, and ShardBar.lua unchanged in an isolated fixture. It checks uncached GetUnit(), active/inactive Warlock combat callbacks, native Setup()/UpdateMaxPower(), vehicle-unit resolution, resource-pool preservation, parent changes, fade/mouse restoration, overlapping player/class-bar settings, and combat/module-disable restoration. It passes against all three supplied modern implementations: Retail 12.1.0.69933, Retail 12.1.5.70077, and Forever 1.60.1.70338. Running this updated suite against the compat-20261010.2 module with Retail 12.1.0 source reproduces ClassPowerBar.lua:11 before any power arithmetic executes. Blizzard source files are inputs for verification and are not included in the addon packages.

The compatibility suite exercises actual bars, shared update handlers, health/power behavior, VisualHeal, capability adapters, and aura/profile conversion. Texture fixtures reject empty atlas names and clear atlas state through SetTexture. Removed checks for edited LibDualSpec/DogTag library implementations are superseded by the native profile tests and byte-level vendor verification.

HideBlizzard tests cover reversible frame-group toggles across Era/TBC/Cata/Mists/Forever/Retail fixtures, current unit visibility, latest native parent requests, overlapping party/raid suppression, retained native events/unit watches/party pools, Mists aliases, optional frames/mixin avoidance, active/idle cast bars, alternate-power parenting, opaque alpha pass-through, native mouse state, combat-login deferral, repeated combat toggles, disable/re-enable restoration, delayed addon loads, lazy compact frame generation, profile changes, and re-entrant native OnShow callbacks. They also reject the former permanent event/watch removal and reload controls.

Native options tests load the untouched LibStub, CallbackHandler, AceGUI core/CheckBox, AceConfigRegistry, and AceConfigDialog. The original old checkbox error reproduces with SetDesaturation absent; actual dialog opening and callbacks succeed with PitBull controls. Checks cover five supplied client labels, state changes, disabled input, radio/multiselect/three-state behavior, width reflow, release/reacquisition, late options, and unchanged shared CheckBox registration/version. Native toggles also work before any library loads.

Specialization-profile tests cover Retail/Mists native specialization indexes, Era seasonal/regular behavior, Forever/TBC/Cata talent groups, existing/older saved mappings, invalid or delayed data, combat deferral, options rebuilds, and creation/deletion/reset through the untouched AceDB/AceDBOptions libraries. The actual application initialization body is also checked with a saved binding: profile callbacks wait until module defaults and the minimap launcher are ready. LibDualSpec is never loaded or embedded.

The Python verifier checks the exact inventory and SHA-256 of all 139 lib/libs files, including nested and standalone-addon libraries. Optionally verify the original archive and an application-only distribution:

    python3 PitBull4/Tests/verify_library_boundary.py --baseline-archive /path/to/supplied-baseline.zip --patch /path/to/application-only-changes.zip

It rejects changed/missing/added libraries and library paths in an overlay, including case variations and backslash separators. Never change the hashes to accept a milestone library edit. A full package may include unchanged baseline libraries; a changed-only ZIP must include none. Existing packaging externals must not refresh the locked vendor contents.

The changed-files.json inventory compares the current application against the supplied scenario-target baseline. The separate master-comparison inventory accompanying the distribution compares against PitBull4-master.zip. These are different baselines. Use the full replacement when restoring the earlier milestone's library edits; the application-only ZIP intentionally cannot restore library files.

The earlier changed-files.json, master-comparison.json, and static-results.json are retained as milestone 1 records for compat-20261010.1. The hide_blizzard_hotfix_results.json file is the historical compat-20261010.2 record. Current class-resource checks and the exact immediate baseline, PitBull4_Frame_Toggle_Hotfix_Full_2026-10-10.zip, are recorded in class_resource_hotfix_results.json. The changed-only ZIP overlays that release and contains no library files.
