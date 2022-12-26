XFubenHackConfig = XFubenHackConfig or {}

local TABLE_HACK_ACTIVITY = "Share/Fuben/Hack/HackActivity.tab"
local TABLE_HACK_BUFF = "Share/Fuben/Hack/HackBuff.tab"
local TABLE_HACK_CHAPTER = "Share/Fuben/Hack/HackChapter.tab"
local TABLE_HACK_EFFECT = "Share/Fuben/Hack/HackCharacterEffect.tab"
local TABLE_HACK_EXPLEVEL = "Share/Fuben/Hack/HackExpLevel.tab"
local TABLE_HACK_REWARD = "Share/Fuben/Hack/HackReward.tab"
local TABLE_HACK_STAGE = "Share/Fuben/Hack/HackStage.tab"

local HackActivity = {}
local HackBuff = {}
local HackChapter = {}
local HackCharEffect = {}
local HackExpLevel = {}
local HackStage = {}
local HackReward = {}
local HackLevelGroup = {}

XFubenHackConfig.PopUpPos = {
    Left = 1,
    Right = 2,
}

XFubenHackConfig.BuffBarCapacity = 3

function XFubenHackConfig.Init()
    HackActivity = XTableManager.ReadByIntKey(TABLE_HACK_ACTIVITY, XTable.XTableHackActivity, "Id")
    HackBuff = XTableManager.ReadByIntKey(TABLE_HACK_BUFF, XTable.XTableHackBuff, "Id")
    HackChapter = XTableManager.ReadByIntKey(TABLE_HACK_CHAPTER, XTable.XTableHackChapter, "Id")
    HackCharEffect = XTableManager.ReadByIntKey(TABLE_HACK_EFFECT, XTable.XTableHackCharacterEffect, "Id")
    HackExpLevel = XTableManager.ReadByIntKey(TABLE_HACK_EXPLEVEL, XTable.XTableHackExpLevel, "Id")
    HackStage = XTableManager.ReadByIntKey(TABLE_HACK_STAGE, XTable.XTableHackStage, "Id")
    HackReward = XTableManager.ReadByIntKey(TABLE_HACK_REWARD, XTable.XTableHackReward, "Id")
    for _, v in pairs(HackExpLevel) do
        if not HackLevelGroup[v.ChapterId] then
            HackLevelGroup[v.ChapterId] = {}
        end
        HackLevelGroup[v.ChapterId][v.Level] = v
    end
end

function XFubenHackConfig.GetStageInfo(id)
    local template = HackStage[id]
    if not template then
        XLog.ErrorTableDataNotFound("XFubenHackConfig.GetStageInfo", "HackStage", TABLE_HACK_STAGE, "id", tostring(id))
        return
    end
    return template
end

function XFubenHackConfig.GetStages()
    return HackStage
end

function XFubenHackConfig.GetChapterTemplate(id)
    return HackChapter[id]
end

function XFubenHackConfig.GetActTemplates()
    return HackActivity
end

function XFubenHackConfig.GetActivityTemplateById(id)
    return HackActivity[id]
end

function XFubenHackConfig.GetReward()
    return HackReward
end

function XFubenHackConfig.GetRewardById(id)
    return HackReward[id]
end

function XFubenHackConfig.GetBuffById(id)
    return HackBuff[id]
end

function XFubenHackConfig.GetLevelCfg(chapterId, level)
    return HackLevelGroup[chapterId] and HackLevelGroup[chapterId][level]
end

function XFubenHackConfig.GetLevelCfgs(chapterId)
    return HackLevelGroup[chapterId]
end