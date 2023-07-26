XDlcHuntConfigs = XDlcHuntConfigs or {}
local XDlcHuntConfigs = XDlcHuntConfigs

XDlcHuntConfigs.TeamId = {
    Multi = "Multi", -- 暂时只有多人
}

XDlcHuntConfigs.TUTORIAL_WORLD = {
    Id = 1,
    LevelId = 12
}

XDlcHuntConfigs.PlayerState = {
    Normal = 0,
    Ready = 1,
    Select = 2,
    Clump = 3,
    Fight = 4,
    Settle = 5,
}

XDlcHuntConfigs.RoomSelect = {
    Character = 0,
    Chip = 1
}

XDlcHuntConfigs.RECONNECT_FAIL = {
    TEAM_SUCCESS = 1,
    TEAM_FAIL = 2,
    TIME_OUT = 3,
}

XDlcHuntConfigs.TAB_BAG = {
    MAIN_CHIP = 1,
    SUB_CHIP = 2,
    OTHERS = 3
}

XDlcHuntConfigs.TEAM_PLAYER_AMOUNT = 3

XDlcHuntConfigs.HELP_KEY = {
    MAIN = "DlcHuntMain", -- 主界面
    CHIP_STRENGTHEN = "DlcHuntChipStrengthen", -- 培养
    CHIP_GROUP = "DlcHuntChipEquip", -- 芯片组
}

---@type XConfig
local _ConfigShare

---@type XConfig
local _ConfigActivity

function XDlcHuntConfigs.Init()
    _ConfigShare = XConfig.New("Share/DlcHunt/DlcHuntShareCfg.tab", XTable.XTableDlcHuntShareCfg, "Key")
    _ConfigActivity = XConfig.New("Share/DlcHunt/DlcHuntActivity.tab", XTable.XTableDlcHuntActivity, "Id")
end

function XDlcHuntConfigs.GetLoseTipIdWeak()
    return _ConfigShare:GetProperty("LostTipId", "IntValues")[1]
end

function XDlcHuntConfigs.GetLoseTipIdDisband()
    return _ConfigShare:GetProperty("RoomTipId", "IntValues")[1]
end

function XDlcHuntConfigs.GetWeekTaskGroupId()
    return _ConfigShare:GetProperty("WeekTaskGroupId", "IntValues")[1]
end

function XDlcHuntConfigs.GetTaskGroupId()
    return _ConfigShare:GetProperty("TaskGroupId", "IntValues")[1]
end

function XDlcHuntConfigs.GetChipGroupAmount()
    return _ConfigShare:GetProperty("ChipFormCount", "IntValues")[1]
end

function XDlcHuntConfigs.GetChipCapacity()
    return _ConfigShare:GetProperty("ChipMaxCount", "IntValues")[1]
end

function XDlcHuntConfigs.GetHelpKey()
    return _ConfigShare:GetProperty("HelpKey", "StringValues")[1]
end

function XDlcHuntConfigs.GetIconBreakthrough(times)
    return _ConfigShare:GetProperty("IconBreakthrough" .. times, "StringValues")[1]
end

function XDlcHuntConfigs.GetIconBreakthrough2(times)
    return _ConfigShare:GetProperty("IconBreakthrough" .. times, "StringValues")[2]
end

function XDlcHuntConfigs.GetModelMainUi()
    return _ConfigShare:GetProperty("ModelMainUi", "StringValues")[1]
end

function XDlcHuntConfigs.GetCharacterAttrOnUi()
    return _ConfigShare:GetProperty("CharacterAttr", "StringValues")
end

function XDlcHuntConfigs.GetDurationRequestFriendAssistantChipClient()
    return _ConfigShare:GetProperty("DurationRequestFriendAssistantChipClient", "IntValues")[1]
end

function XDlcHuntConfigs.GetAssistantPointFromFriend()
    return _ConfigShare:GetProperty("BorrowSocialAssist", "IntValues")[1]
end

function XDlcHuntConfigs.GetAssistantPointFromTeammate()
    return _ConfigShare:GetProperty("BorrowTeammateAssist", "IntValues")[1]
end

function XDlcHuntConfigs.GetAssistantPointFromRandom()
    return _ConfigShare:GetProperty("BorrowRandomAssist", "IntValues")[1]
end

function XDlcHuntConfigs.GetAmountAssistantChip()
    return _ConfigShare:GetProperty("AssistantChipAmount", "IntValues")
end

function XDlcHuntConfigs.GetRoomKickCountDownTime()
    return _ConfigShare:GetProperty("RoomKickCountDownTime", "IntValues")[1]
end

function XDlcHuntConfigs.GetRoomKickCountDownShowTime()
    return _ConfigShare:GetProperty("RoomKickCountDownShowTime", "IntValues")[1]
end

function XDlcHuntConfigs.GetAssistPointItemId()
    return _ConfigShare:GetProperty("AssistPointItemId", "IntValues")[1]
end

function XDlcHuntConfigs.GetWeekGainAssistLimit()
    return _ConfigShare:GetProperty("WeekGainAssistLimit", "IntValues")[1]
end

function XDlcHuntConfigs.GetWeekGainSocialAssistLimit()
    return _ConfigShare:GetProperty("WeekGainSocialAssistLimit", "IntValues")[1]
end

-- 芯片特效 芯片详情界面
function XDlcHuntConfigs.GetChipEffect(starAmount)
    return _ConfigShare:GetProperty("ChipEffect", "StringValues")[starAmount]
end

-- 副芯片特效 芯片界面
function XDlcHuntConfigs.GetChipSubEffect(starAmount)
    return _ConfigShare:GetProperty("ChipSubEffect", "StringValues")[starAmount]
end

-- 主芯片特效 芯片界面
function XDlcHuntConfigs.GetChipMainEffect(starAmount)
    return _ConfigShare:GetProperty("ChipMainEffect", "StringValues")[starAmount]
end

-- 排行榜 123
function XDlcHuntConfigs.GetRankImage(starAmount)
    return _ConfigShare:GetProperty("RankNumber", "StringValues")[starAmount]
end

-- 先锋服，只有chapter1可选
function XDlcHuntConfigs.GetDefaultChapterId()
    return 1
end

local _TeamMaxPos
function XDlcHuntConfigs.GetOnlineMemberCount()
    if not _TeamMaxPos then
        _TeamMaxPos = CS.XGame.Config:GetInt("TeamMaxPos")
    end
    return _TeamMaxPos
end

function XDlcHuntConfigs.GetSortTextGroup()
    return _ConfigShare:GetProperty("SortGroup", "StringValues")
end

function XDlcHuntConfigs.GetIconChipGroupEmpty()
    return _ConfigShare:GetProperty("EmptyChipGroup", "StringValues")[1]
end

function XDlcHuntConfigs.GetTimeId()
    local configs = _ConfigActivity:GetConfigs()
    for i = 1, #configs do
        local timeId = configs[i].TimeId
        if timeId > 0 then
            return timeId
        end
    end
    return 0
end 