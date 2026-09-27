# Changelog

## 0.1.0 – 2026-09-27

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

### Step 4 – Auto-routing and guild join
- Posting an ad to a channel opens a 30-minute candidate window. Unknown players (not guild members or friends) who whisper you first during the window become candidates with status New and go straight to Recruits in the Whispers tab (not Requests). Ordinary whispers are never touched.
- The ad panel shows until when the window is open. `/hr window` opens it without posting an ad (e.g. after advertising on Discord).
- "X has joined the guild" for a candidate starts the trial (Trial · day 1/14).
- At login, trials past their length are listed so they can be set to Member or Declined.

### Step 5 – Options
- "Recruit" page in the Hush settings (`/hr options`): channel buttons, candidate window (10–120 min), trial length (7–28 days), ad cooldown (off–300 s), apply link and message, shortcuts to the ad panel and the candidate window.
- README.md. Replaces SlakthusetRecruit (import done in step 1).

## 0.1.1 – 2026-09-27
- The ad panel no longer captures the keyboard; ESC closes it through `UISpecialFrames` (window name `HushRecruitFrame`). Requires Hush 0.1.8.
