local TABLE_HEADPORTRAITS = "Share/HeadPortrait/HeadPortrait.tab"
XHeadPortraitConfigs = XHeadPortraitConfigs or {}

XHeadPortraitConfigs.HeadTimeLimitType = {
    Forever = 0,
    Duration = 1,
    FixedTime = 2,
}

XHeadPortraitConfigs.HeadType = {
    HeadPortrait = 1,
    HeadFrame = 2,
    Medal = 3,
    Nameplate = 4,
    ChatBoard = 5,
}

XHeadPortraitConfigs.BtnState = {
    Use = 1,
    NonUse = 2,
}

local HeadPortraitsCfg = {}

function XHeadPortraitConfigs.Init()
    HeadPortraitsCfg = XTableManager.ReadByIntKey(TABLE_HEADPORTRAITS, XTable.XTableHeadPortrait, "Id")
end

function XHeadPortraitConfigs.GetHeadPortraitsCfg()
    return HeadPortraitsCfg
end

