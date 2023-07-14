XPartnerConfigs = XPartnerConfigs or {}

local TABLE_PARTNER = "Share/Partner/Partner.tab"
local TABLE_PARTNER_LEVELUP_PATH = "Share/Partner/LevelUpTemplate"
local TABLE_PARTNER_BREAK_THROIGH = "Share/Partner/PartnerBreakThrough.tab"
local TABLE_PARTNER_QUALITY = "Share/Partner/PartnerQuality.tab"
local TABLE_PARTNER_SKILL = "Share/Partner/PartnerSkill.tab"
local TABLE_PARTNER_MAINSKILL_GROUP = "Share/Partner/PartnerMainSkillGroup.tab"
local TABLE_PARTNER_PASSIVESKILL_GROUP = "Share/Partner/PartnerPassiveSkillGroup.tab"
local TABLE_PARTNER_SKILLEFFECT = "Share/Partner/PartnerSkillEffect.tab"
local TABLE_PARTNER_SKILLINFO = "Client/Partner/PartnerSkillInfo.tab"
local TABLE_PARTNER_MODEL = "Client/Partner/PartnerModel.tab"
local TABLE_PARTNER_ITEM_SKIP = "Client/Partner/PartnerItemSkipId.tab"

local PartnerTemplateCfg = {}
local PartnerBreakthroughCfg = {}
local PartnerQualityCfg = {}
local PartnerSkillCfg = {}
local PartnerMainSkillGroupCfg = {}
local PartnerPassiveSkillGroupCfg = {}
local PartnerSkillEffectCfg = {}
local PartnerSkillInfoCfg = {}
local PartnerModelCfg = {}
local PartnerItemSkipIdCfg = {}

local PartnerBreakthroughDic = {}
local PartnerQualityDic = {}
local PartnerSkillEffectDic = {}
local PartnerSkillInfoDic = {}
local PartnerMainSkillGroupDic = {}
local PartnerPassiveSkillGroupDic = {}
local LevelUpTemplates = {}

XPartnerConfigs.SkillType = {
    MainSkill = 1,
    PassiveSkill = 2,
    }

XPartnerConfigs.SkillElement = {
    Physics = 1,
    Fire = 2,
    Ice = 3,
    Thunder = 4,
    Dark = 5,
}

XPartnerConfigs.SortType = {
    Ability = 1,--战力
    Quality = 2,--品质
    Breakthrough = 3,--突破
    Level = 4,--等级
    SkillLevel = 5,--技能等级
    Lock = 6,--上锁
    Priority = 7,--优先级
    Stack = 8,--堆叠
    CanCompose = 9,--可以合成
    Carry = 10,--是否佩戴
}

XPartnerConfigs.MainUiState = {
    None = 0,
    Overview = 1,--总览
    Compose = 2,--合成
    Property = 3,--养成
}

XPartnerConfigs.PartnerState = {
    Standby = 1,--待机模式
    Combat = 2,--战斗模式
}

XPartnerConfigs.PartnerType = {
    All = 0,
    Normal = 1,
    Isomer = 2,
}

XPartnerConfigs.CameraType = {
    Standby = 1,
    Combat = 2,
    Overview = 2,
    Compose = 3,
    Level = 4,
    Quality = 5,
    Skill = 6,
    Story = 7,
    StandbyNoSelect = 8,
    CombatNoSelect = 9,
}

XPartnerConfigs.DataSyncType = {
    Obtain = 1,
    Skill = 2,
    Carry = 3,
    UnlockSkillGroup = 4,
    QualityUp = 5,
}

XPartnerConfigs.AttrSortType = {
    XNpcAttribType.AttackNormal,
}

XPartnerConfigs.BagShowType = {
    View = 1,
    Decompose = 2,
}

XPartnerConfigs.BagSortType = {
    [0] = XPartnerConfigs.SortType.Quality,
    [1] = XPartnerConfigs.SortType.Breakthrough,
    [2] = XPartnerConfigs.SortType.Level,
}

XPartnerConfigs.QualityString = {
    [1] = "B",
    [2] = "A",
    [3] = "S",
    [4] = "SS",
    [5] = "SSS",
    [6] = "SSS+",
}

local PartnerBreakThroughIcon = {
    [0] = CS.XGame.ClientConfig:GetString("PartnerBreakThrough0"),
    [1] = CS.XGame.ClientConfig:GetString("PartnerBreakThrough1"),
    [2] = CS.XGame.ClientConfig:GetString("PartnerBreakThrough2"),
    [3] = CS.XGame.ClientConfig:GetString("PartnerBreakThrough3"),
}

local QualityBgPath = {
    CS.XGame.ClientConfig:GetString("CommonBagGold"),
    CS.XGame.ClientConfig:GetString("CommonBagGold"),
    CS.XGame.ClientConfig:GetString("CommonBagRed"),
    CS.XGame.ClientConfig:GetString("CommonBagRed"),
    CS.XGame.ClientConfig:GetString("CommonBagRed"),
    CS.XGame.ClientConfig:GetString("CommonBagRed"),
}


XPartnerConfigs.MainSkillCount = 1

XPartnerConfigs.PassiveSkillCount = 5


function XPartnerConfigs.Init()
    PartnerTemplateCfg = XTableManager.ReadByIntKey(TABLE_PARTNER, XTable.XTablePartner, "Id")
    PartnerBreakthroughCfg = XTableManager.ReadByIntKey(TABLE_PARTNER_BREAK_THROIGH, XTable.XTablePartnerBreakThrough, "Id")
    PartnerQualityCfg = XTableManager.ReadByIntKey(TABLE_PARTNER_QUALITY, XTable.XTablePartnerQuality, "Id")
    PartnerSkillCfg = XTableManager.ReadByIntKey(TABLE_PARTNER_SKILL, XTable.XTablePartnerSkill, "PartnerId")
    PartnerMainSkillGroupCfg = XTableManager.ReadByIntKey(TABLE_PARTNER_MAINSKILL_GROUP, XTable.XTablePartnerMainSkillGroup, "Id")
    PartnerPassiveSkillGroupCfg = XTableManager.ReadByIntKey(TABLE_PARTNER_PASSIVESKILL_GROUP, XTable.XTablePartnerPassiveSkillGroup, "Id")
    PartnerSkillEffectCfg = XTableManager.ReadByIntKey(TABLE_PARTNER_SKILLEFFECT, XTable.XTablePartnerSkillEffect, "Id")
    PartnerSkillInfoCfg = XTableManager.ReadByIntKey(TABLE_PARTNER_SKILLINFO, XTable.XTablePartnerSkillInfo, "Id")
    PartnerModelCfg = XTableManager.ReadByIntKey(TABLE_PARTNER_MODEL, XTable.XTablePartnerModel, "Id")
    PartnerItemSkipIdCfg = XTableManager.ReadByIntKey(TABLE_PARTNER_ITEM_SKIP, XTable.XTablePartnerItemSkipId, "PartnerId")
    
    local paths = CS.XTableManager.GetPaths(TABLE_PARTNER_LEVELUP_PATH)
    XTool.LoopCollection(paths, function(path)
            local key = tonumber(XTool.GetFileNameWithoutExtension(path))
            LevelUpTemplates[key] = XTableManager.ReadByIntKey(path, XTable.XTablePartnerLevelUp, "Level")
        end)
    
    XPartnerConfigs.CreatePartnerBreakthroughDic()
    XPartnerConfigs.CreatePartnerQualityDic()
    XPartnerConfigs.CreatePartnerSkillEffectDic()
    XPartnerConfigs.CreatePartnerSkillInfoDic()
    XPartnerConfigs.CreateMainSkillGroupDic()
    XPartnerConfigs.CreatePassiveSkillGroupDic()
end

function XPartnerConfigs.CreatePartnerBreakthroughDic()
    PartnerBreakthroughDic = {}
    for _,breakThrough in pairs(PartnerBreakthroughCfg) do
        PartnerBreakthroughDic[breakThrough.PartnerId] = 
        PartnerBreakthroughDic[breakThrough.PartnerId] or {}
        
        PartnerBreakthroughDic[breakThrough.PartnerId][breakThrough.BreakTimes] = 
        PartnerBreakthroughDic[breakThrough.PartnerId][breakThrough.BreakTimes] or breakThrough
    end
end

function XPartnerConfigs.CreatePartnerQualityDic()
    PartnerQualityDic = {}
    for _,qualityInfo in pairs(PartnerQualityCfg) do
        PartnerQualityDic[qualityInfo.PartnerId] =
        PartnerQualityDic[qualityInfo.PartnerId] or {}

        PartnerQualityDic[qualityInfo.PartnerId][qualityInfo.Quality] =
        PartnerQualityDic[qualityInfo.PartnerId][qualityInfo.Quality] or qualityInfo
    end
end

function XPartnerConfigs.CreatePartnerSkillEffectDic()
    PartnerSkillEffectDic = {}
    for _,effect in pairs(PartnerSkillEffectCfg) do
        PartnerSkillEffectDic[effect.SkillId] =
        PartnerSkillEffectDic[effect.SkillId] or {}

        PartnerSkillEffectDic[effect.SkillId][effect.Level] =
        PartnerSkillEffectDic[effect.SkillId][effect.Level] or effect
    end
end

function XPartnerConfigs.CreatePartnerSkillInfoDic()
    PartnerSkillInfoDic = {}
    for _,Info in pairs(PartnerSkillInfoCfg) do
        PartnerSkillInfoDic[Info.SkillId] =
        PartnerSkillInfoDic[Info.SkillId] or {}

        PartnerSkillInfoDic[Info.SkillId][Info.Level] =
        PartnerSkillInfoDic[Info.SkillId][Info.Level] or Info
    end
end

function XPartnerConfigs.CreateMainSkillGroupDic()
    PartnerMainSkillGroupDic = {}
    for _,groupInfo in pairs(PartnerMainSkillGroupCfg) do
        for _,skillId in pairs(groupInfo.SkillId) do
            if not PartnerMainSkillGroupDic[skillId] then
                PartnerMainSkillGroupDic[skillId] = groupInfo.Id
            else
                XLog.Error("skillId id Reuse in tab:"..TABLE_PARTNER_MAINSKILL_GROUP)
            end
        end
    end
end

function XPartnerConfigs.CreatePassiveSkillGroupDic()
    PartnerPassiveSkillGroupDic = {}
    for _,groupInfo in pairs(PartnerPassiveSkillGroupCfg) do
        for _,skillId in pairs(groupInfo.SkillId) do
            if not PartnerPassiveSkillGroupDic[skillId] then
                PartnerPassiveSkillGroupDic[skillId] = groupInfo.Id
            else
                XLog.Error("skillId id Reuse in tab:"..TABLE_PARTNER_PASSIVESKILL_GROUP)
            end
        end
    end
end

function XPartnerConfigs.GetPartnerTemplateCfg()
    return PartnerTemplateCfg
end

function XPartnerConfigs.GetPartnerBreakthroughCfg()
    return PartnerBreakthroughCfg
end

function XPartnerConfigs.GetPartnerQualityCfg()
    return PartnerQualityCfg
end

function XPartnerConfigs.GetPartnerTemplateById(id)
    if not PartnerTemplateCfg[id] then
        XLog.Error("id is not exist in "..TABLE_PARTNER.." id = " .. id)
        return
    end
    return PartnerTemplateCfg[id]
end

function XPartnerConfigs.GeQualityBgPath(quality)
    if not quality then
        XLog.Error("XPartnerConfigs.GeQualityBgPath 函数错误: 参数quality不能为空")
        return
    end
    return QualityBgPath[quality]
end

function XPartnerConfigs.GetPartnerTemplateName(id)
    return XPartnerConfigs.GetPartnerTemplateById(id).Name
end

function XPartnerConfigs.GetPartnerTemplateIcon(id)
    return XPartnerConfigs.GetPartnerTemplateById(id).Icon
end

function XPartnerConfigs.GetPartnerTemplateQuality(id)
    return XPartnerConfigs.GetPartnerTemplateById(id).InitQuality
end

function XPartnerConfigs.GetPartnerTemplateGoodsDesc(id)
    return XPartnerConfigs.GetPartnerTemplateById(id).GoodsDesc
end

function XPartnerConfigs.GetPartnerTemplateGoodsWorldDesc(id)
    return XPartnerConfigs.GetPartnerTemplateById(id).GoodsWorldDesc
end

function XPartnerConfigs.GetPartnerSkillById(id)
    if not PartnerSkillCfg[id] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_SKILL.." id = " .. id)
        return
    end
    return PartnerSkillCfg[id]
end

function XPartnerConfigs.GetPartnerMainSkillGroupById(id)
    if not PartnerMainSkillGroupCfg[id] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_MAINSKILL_GROUP.." id = " .. id)
        return
    end
    return PartnerMainSkillGroupCfg[id]
end

function XPartnerConfigs.GetPartnerPassiveSkillGroupById(id)
    if not PartnerPassiveSkillGroupCfg[id] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_PASSIVESKILL_GROUP.." id = " .. id)
        return
    end
    return PartnerPassiveSkillGroupCfg[id]
end

function XPartnerConfigs.GetPartnerBreakthroughByIdAndNum(partnerId, breakTimes)
    if not PartnerBreakthroughDic[partnerId] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_BREAK_THROIGH.." id = " .. partnerId)
        return
    end
    if not PartnerBreakthroughDic[partnerId][breakTimes] then
        XLog.Error("breakTimes is not exist in "..TABLE_PARTNER_BREAK_THROIGH.." breakTimes = " .. breakTimes)
        return
    end
    return PartnerBreakthroughDic[partnerId][breakTimes]
end

function XPartnerConfigs.GetPartnerBreakthroughLimit(partnerId)
    if not PartnerBreakthroughDic[partnerId] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_BREAK_THROIGH.." id = " .. partnerId)
        return
    end
    local tmpMax = 0
    for breakTimes,_ in pairs(PartnerBreakthroughDic[partnerId]) do
        if breakTimes > tmpMax then
            tmpMax = breakTimes
        end
    end
    return tmpMax
end

function XPartnerConfigs.GePartnerQualityByIdAndNum(partnerId, quality)
    if not PartnerQualityDic[partnerId] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_QUALITY.." id = " .. partnerId)
        return
    end
    if not PartnerQualityDic[partnerId][quality] then
        XLog.Error("quality is not exist in "..TABLE_PARTNER_QUALITY.." quality = " .. quality)
        return
    end
    return PartnerQualityDic[partnerId][quality]
end

function XPartnerConfigs.GetQualityLimit(partnerId)
    if not PartnerQualityDic[partnerId] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_QUALITY.." id = " .. partnerId)
        return
    end
    local tmpMax = 0
    for quality,_ in pairs(PartnerQualityDic[partnerId]) do
        if quality > tmpMax then
            tmpMax = quality
        end
    end
    return tmpMax
end

function XPartnerConfigs.GetPartnerSkillEffectByIdAndLevel(skillId, level)
    if not PartnerSkillEffectDic[skillId] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_SKILLEFFECT.." id = " .. skillId)
        return
    end
    if not PartnerSkillEffectDic[skillId][level] then
        XLog.Error("level is not exist in "..TABLE_PARTNER_SKILLEFFECT.." level = " .. level)
        return
    end
    return PartnerSkillEffectDic[skillId][level]
end

function XPartnerConfigs.GetPartnerSkillInfoByIdAndLevel(skillId, level)
    if not PartnerSkillInfoDic[skillId] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_SKILLINFO.." id = " .. skillId)
        return
    end
    if not PartnerSkillInfoDic[skillId][level] then
        XLog.Error("level is not exist in "..TABLE_PARTNER_SKILLINFO.." level = " .. level)
        return
    end
    return PartnerSkillInfoDic[skillId][level]
end


function XPartnerConfigs.GetMainSkillGroupById(skillId)
    if not PartnerMainSkillGroupDic[skillId] then
        XLog.Error("skillId is not exist in "..TABLE_PARTNER_MAINSKILL_GROUP.." skillId = " .. skillId)
        return
    end
    return PartnerMainSkillGroupDic[skillId]
end

function XPartnerConfigs.GetPassiveSkillGroupById(skillId)
    if not PartnerPassiveSkillGroupDic[skillId] then
        XLog.Error("skillId is not exist in "..TABLE_PARTNER_PASSIVESKILL_GROUP.." skillId = " .. skillId)
        return
    end
    return PartnerPassiveSkillGroupDic[skillId]
end

function XPartnerConfigs.GetPartnerSkillLevelLimit(skillId)
    if not PartnerSkillEffectDic[skillId] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_SKILLEFFECT.." id = " .. skillId)
        return
    end
    local tmpMax = 0
    for skillLevel,_ in pairs(PartnerSkillEffectDic[skillId]) do
        if skillLevel > tmpMax then
            tmpMax = skillLevel
        end
    end
    return tmpMax
end

function XPartnerConfigs.GetPartnerModelById(id)
    if not PartnerModelCfg[id] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_MODEL.." id = " .. id)
        return {}
    end
    return PartnerModelCfg[id]
end

function XPartnerConfigs.GetPartnerBreakThroughIcon(breakthroughTimes)
    local icon = PartnerBreakThroughIcon[breakthroughTimes]
    if not icon then
        XLog.Error("XPartnerConfigs.PartnerBreakThroughIcon调用错误，得到的icon为空，原因：检查breakthroughTimes：" .. breakthroughTimes .. "和PartnerBreakThroughIcon的Index不匹配")
        return
    end
    return icon
end

---
--- 获取'id'伙伴待机模型
function XPartnerConfigs.GetPartnerModelStandbyModel(id)
    return XPartnerConfigs.GetPartnerModelById(id).StandbyModel
end

---
--- 获取'id'伙伴战斗模型
function XPartnerConfigs.GetPartnerModelCombatModel(id)
    return XPartnerConfigs.GetPartnerModelById(id).CombatModel
end

---
--- 获取'id'伙伴 待机->战斗 动画
function XPartnerConfigs.GetPartnerModelSToCAnime(id)
    return XPartnerConfigs.GetPartnerModelById(id).SToCAnime
end

---
--- 获取'id'伙伴战斗模型出生动画
function XPartnerConfigs.GetPartnerModelCombatBornAnime(id)
    return XPartnerConfigs.GetPartnerModelById(id).CombatBornAnime
end

---
--- 获取'id'伙伴 待机->战斗 音效
function XPartnerConfigs.GetPartnerModelSToCVoice(id)
    return XPartnerConfigs.GetPartnerModelById(id).SToCVoice
end

---
--- 获取'id'伙伴的 待机->战斗 变形特效
function XPartnerConfigs.GetPartnerModelSToCEffect(id)
    return XPartnerConfigs.GetPartnerModelById(id).SToCEffect
end

---
--- 获取'id'伙伴的 待机->战斗 出生特效
function XPartnerConfigs.GetPartnerModelCombatBornEffect(id)
    return XPartnerConfigs.GetPartnerModelById(id).CombatBornEffect
end

function XPartnerConfigs.GetPartnerLevelUpTemplateByIdAndLevel(id,level)
    if not LevelUpTemplates[id] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_LEVELUP_PATH.." id = " .. id)
        return
    end
    if not LevelUpTemplates[id][level] then
        XLog.Error("level is not exist in "..TABLE_PARTNER_LEVELUP_PATH.." level = " .. level)
        return
    end
    return LevelUpTemplates[id][level]
end

function XPartnerConfigs.GetPartnerItemSkipById(id)
    if not PartnerItemSkipIdCfg[id] then
        XLog.Error("id is not exist in "..TABLE_PARTNER_ITEM_SKIP.." id = " .. id)
        return
    end
    return PartnerItemSkipIdCfg[id]
end