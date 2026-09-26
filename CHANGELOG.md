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
