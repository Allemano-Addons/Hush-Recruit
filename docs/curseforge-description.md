# Hush Recruit

**Guild recruitment without the spreadsheet.** Hush Recruit is a module for [Hush](https://www.curseforge.com/wow/addons/hush) on WoW Forever. It keeps your recruitment ads ready, sends your apply link with one click and tracks every candidate from the first whisper to the end of the trial.

> **Alpha.** Requires Hush.

## What it does

### Recruitment ads, ready to post
Save up to **five recruitment texts**. Post one to General, Trade, LFG, guild chat or any channel number with one click. Each line becomes its own message, and long lines are split safely so nothing is cut off. A cooldown asks for a second click before you post to the same channel again, so you never spam by accident.

### One-click apply link
Set your guild's apply link and message once in the game (you can use `{name}` and `{link}` in the text). The **Apply link** button in the Hush header whispers it to the person you are talking to and starts tracking them as a candidate.

### Know where every candidate stands
Each player has a status: **New, Link sent, Applied, Trial, Member** or **Declined**. It shows as a colored chip in the Hush header (for example `Trial · day 5/14`), and your notes appear under the name. Guild invites are in the chat right-click menu.

### Candidates sort themselves
For 30 minutes after you post an ad, unknown players who whisper you become candidates in the **Recruits** category. Guild members, friends and people you whispered first are never touched, and **"Not a recruit"** undoes it.

### Trials that do not get forgotten
When a candidate joins the guild, their trial starts. Trials that have run past their length are listed when you log in, so nobody stays a trial member forever by mistake.

*Example:* Post your ad in Trade. A player whispers "still recruiting?", you press Apply link, and later they show up as **Trial · day 3/14** in the header when you talk to them.

## Commands
- `/hr` (or `/recruit`) opens the ad panel
- `/hr options` settings (also under Hush settings > Recruit)
- `/hr window` opens the candidate window without posting an ad
- `/hr status` shows your saved ads and channels

## Good to know
- Guild invites are protected on WoW Forever, so Hush runs `/ginvite` through a secure button. That means it is not available in combat.
- Channel buttons find the channel by name among the channels you have joined, or use a fixed channel number.

## Installing manually (WoW Forever)
Requires **Hush**. Made for WoW Forever (interface 16001). If the CurseForge app does not install it into the right folder, download the file from the **Files** tab and unzip it so that the folder is `World of Warcraft\_classic_beta_\Interface\AddOns\Hush_Recruit`, next to the Hush folder. Restart the game.

Part of **Allemano Addons**. Source code and issues: https://github.com/Allemano-Addons/Hush-Recruit
