std = "lua51"
max_line_length = false
self = false

globals = {
    "HushRecruitDB",
    "SLASH_HUSHRECRUIT1", "SLASH_HUSHRECRUIT2", "SlashCmdList",
    "HushRecruitFrame", -- window name, only so ESC closes it via UISpecialFrames
}

read_globals = {
    "Hush", "SlakthusetRecruitDB",
    "UISpecialFrames",
    "strjoin", "strsplit", "strtrim", "strlower", "strupper", "tostringall", "tinsert", "tremove", "wipe",
    "sort", "floor", "ceil", "min", "max", "format", "date", "time", "CopyTable", "geterrorhandler",
    "CreateFrame", "UIParent", "DEFAULT_CHAT_FRAME", "GetTime", "SendChatMessage", "C_ChatInfo",
    "GetChannelName", "IsInGuild", "UnitName", "InCombatLockdown", "IsShiftKeyDown", "GetCursorPosition",
    "ERR_GUILD_JOIN_S",
}
