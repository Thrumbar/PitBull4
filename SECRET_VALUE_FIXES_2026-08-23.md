# PitBull4 Secret-Value Boundary Fixes

Single-line description: Prevents restricted unit data from reaching tooltip color checks, CombatFader comparisons, VisualHeal arithmetic, and LuaTexts equality or conversion logic.

## Changes

- Leaves unit-tooltip title coloring to Blizzard's `GameTooltip:SetUnit` path, avoiding restricted identity checks for compound tokens such as `targettarget`.
- Validates health, power, GUID, boolean, table-key, and heal-prediction values with Blizzard's secret-access predicates before Lua evaluates them.
- Makes CombatFader fail visible when health or power data is inaccessible.
- Clears VisualHeal for an affected update when prediction data is secret; normal predictions resume automatically when the values are accessible.
- Prevents LuaTexts from comparing restricted GUID, cast, power, and unit-flag values.
- Preserves all earlier LeaderIcon, RoleIcon, bar, aura, PvPIcon, CastBar, and restricted-state fixes in the supplied base.

## Compatibility

| Client source checked | Build | Secret API path |
| --- | ---: | --- |
| Retail | 12.1.0.69404 | `canaccessvalue`, `canaccesstable`, `scrubsecretvalues` |
| Mists of Pandaria Classic | 5.5.4.69383 | Same guarded path |
| Classic Era | 1.15.9.69109 | Same guarded path |
| Burning Crusade Classic | 2.5.6.69110 | Same guarded path |

## Validation

- All changed Lua files pass syntax compilation.
- Secret-value simulations confirm comparisons, arithmetic, and string conversion are not reached for inaccessible values.
- Unmodified addon files remain byte-identical to the supplied package.
