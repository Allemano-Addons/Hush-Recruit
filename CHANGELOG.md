# Changelog

## 0.1.0 (in progress)

### Step 1 – Skeleton
- Module skeleton (`## Dependencies: Hush`), account-wide `HushRecruitDB` (5 ad texts, channel buttons, apply message, settings).
- One-time import of ad texts and channel settings from SlakthusetRecruit.
- `/hr` (and `/recruit`), `/hr status`.

### Step 2 – Ad panel
- Recruitment panel in the Hush style (`/hr`, the megaphone button in the Hush title row, or the launcher menu): 5 saved ads (Ad 1–5), multi-line editor with character/message counter, each line sent as its own message and split at 255 characters (links kept intact).
- Send to General / Trade / LFG (configured channel name or number, looked up among joined channels) or Guild, or any channel number. Sends inside the click (channel messages need a hardware event).
- Cooldown guard: sending to the same channel again within 60 s asks for a second click.
- Apply link and apply message (`{name}`, `{link}`) editable in game.
- Requires Hush 0.1.3 (`AddTitleButton`, `AddLauncherMenuItems`, `SplitMessage`).

### Step 3 – Candidates
- Recruit status per conversation: New, Link sent, Applied, Trial, Member, Declined. Status chip in the Hush header in the status color; trials show "Trial · day 5/14" and "Trial ended" (red) after the trial length.
- Header buttons: **Apply link** (on whispers with non-guild players: sends the apply message, marks the player as a candidate with "Link sent" and moves the chat to Recruits), **Status**, **Note**, **Invite** (guild invite, only for candidates not in the guild).
- Chat menu: Send apply link, Recruit status, Add/Edit note, Track as recruit; "Not a recruit" clears everything and moves the chat back to Other.
- Candidates live in Recruits, members move to Guild; ordinary whispers are never touched. The note is shown on the header info line.
- Requires Hush 0.1.4 (`AddHeaderInfo`).
- Fix: the Invite button uses `/ginvite` through Hush's secure button (guild invites are protected). Requires Hush 0.1.6.
