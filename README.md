# Hush Recruit

Guild recruitment module for [Hush](../Hush) on WoW Forever. Requires Hush 0.1.7 or later.

## What it does

- **Ads** – five saved recruitment texts. Post them to General, Trade, LFG, guild chat or any channel number with one click. Each line is its own message; long lines are split safely. A cooldown asks for a second click before posting to the same channel again.
- **Apply link** – set your guild's apply link and message in game (`{name}`, `{link}`). The **Apply link** button in the Hush header whispers it and starts tracking the player.
- **Candidates** – status per player: New, Link sent, Applied, Trial, Member, Declined. Shown as a colored chip in the Hush header (`Trial · day 5/14`). Notes appear under the name. Guild invites are in the chat right-click menu ("Guild invite").
- **Auto-sorting** – for 30 minutes after an ad, unknown players who whisper you become candidates in the Recruits category. Guild members, friends and people you whisper first are never touched. **Not a recruit** undoes it.
- **Trials** – a candidate joining the guild starts the trial; trials past their length are listed at login.

## Commands

| Command | |
|---|---|
| `/hr` (or `/recruit`) | Ad panel |
| `/hr options` | Settings (also Hush settings → Recruit) |
| `/hr window` | Start the candidate window without posting an ad |
| `/hr status` | Saved ads and channels |

## Notes

- Guild invites are protected on WoW Forever; Hush runs `/ginvite` through a secure button, so it is not available in combat.
- Channel buttons look up the channel by name among the channels you have joined, or use a fixed number.
