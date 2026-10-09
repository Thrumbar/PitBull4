Offline verification only; these files are not loaded by Warcraft.

Run from the directory containing PitBull4: `texlua PitBull4/Tests/compatibility_regressions.lua`.

Also run `texlua PitBull4/Tests/hide_blizzard_regressions.lua` for the Mists Blizzard-frame hiding repair.

Runtime: Lua 5.3. Narrow API/widget stubs; no taint/secret-engine emulation or in-game validation. A Lua 5.1 compiler is unavailable in this environment.

The hotfix suite passes 257 assertions. Texture stubs reject nil/empty atlas names and clear atlas state when SetTexture is called. Added cases execute the real bar controls and aura-filter initializer/profile migration under client-specific API stubs. They cover normal/custom textures, atlas clearing, matching underlying assets, control reuse, renderer changes, unavailable Era spell IDs, supported expansion spells, and legacy spell API fallback.

The supplied native documentation and the user's Era error log establish the atlas input requirement. Stub results are isolated checks and do not certify client rendering, secrecy, taint, or secure behavior.

The HideBlizzard suite passes 99 additional assertions. It reproduces the reported Mists frame layout, exercises both Classic aliases, skips absent optional frames, retains modern names on Retail/Camelot without touching mixins, and checks profile refresh, the reload notice, castbar secure-hook retention, and combat callback scheduling. It fails on the unmodified compat-20261008.2 HideBlizzard module. The combat wrapper is stubbed; these checks do not certify protected execution or taint isolation in-game.
