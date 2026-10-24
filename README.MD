# pfUI Better Totems
Looks and works very similarly to pfUI's default totem module, but with extra features.

## Features
- Looks exactly like pfUI's default totem timer
- Totem timers disappear when you cast Totemic Recall (Turtle WoW spell)
- Totem timer for an individual totem is cleared if that totem is destroyed
- Totem timer turns red if you out range a totem
- Sends a reminder to recall your totems if they are too far away

## Screenshots & Gifs
- Recall warning at 45 yards

<img src="https://i.imgur.com/CaEZPnj.png" width = 200><br><br>

- Totemic Recall Cast removing timers

<img src="https://imgur.com/8Gr7BNp.gif" width = 200 ><br><br>

- Timers turn red when you out range the totems

<img src="https://imgur.com/S2Q6A5s.gif" width = 200><br><br>

- Totem being destroyed

<img src="https://imgur.com/PItpzSQ.gif" width = 200> <br><br>

## Installation
** This addon requires [SuperWoW](https://github.com/balakethelock/SuperWoW) **

** Make sure you have [pfUI](https://gitlab.com/shagu/pfUI) downloaded and installed first **
1. Download Better Totems
2. Unzip
3. Rename the unzipped folder to "pfUI-bettertotems"
4. Copy or cut the now renamed "pfUI-bettertotems" and paste it into Interface\AddOns
5. Restart World of Warcraft
6. Disable pfUI's default totem module

## Changelog

### 1.1 (2026-10-24)

- Fixed crash when placing totems: `COOLDOWN_FRAME_TYPE` was undefined (nil), so cooldown frames were never created and `CooldownFrame_SetTimer` received `nil`.
- Guarded `GetSuperWoWDistance` against missing SuperWoW DLL (`UnitPosition`).
- Added nil guards to `GetRemainingDuration`, `IsTotemTransition`, `IsTotemDestroyed`, and `GetBetterTotemInfo`.
- Fixed operator precedence bug in `IsTotemTransition`.
- Capture `event`/`arg1` as parameters in all script handlers (Classic 1.12-safe).
- Cache `GetTalentInfo(3,8)` (totemic mastery) instead of querying every 0.5s.
- Cache recall settings and precompute slot colors to reduce per-refresh work.
- Removed dead code (`IsTableEmpty`).
- Added `## SavedVariables` to TOC; bumped version to 1.1.

## Credit
I'm new to modding WoW, so I learned from other addons. Most of the code in this addon isn't mine
- pfUI's original totem module, it's mostly the same code.
- https://github.com/MarcelineVQ/Twister  - Used the superwow range calculations