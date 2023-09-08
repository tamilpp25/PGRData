local tableInsert = table.insert
local Pairs = pairs
local StringFormat = string.format

XEquipConfig = XEquipConfig or {}

XEquipConfig.MAX_STAR_COUNT = 6                 -- 最大星星数
XEquipConfig.MAX_SUIT_SKILL_COUNT = 3           -- 最大套装激活技能个数
XEquipConfig.MAX_RESONANCE_SKILL_COUNT = 3      -- 最大共鸣属性/技能个数
XEquipConfig.MAX_AWAKE_COUNT = 2                -- 最大超频个数
XEquipConfig.MIN_RESONANCE_EQUIP_STAR_COUNT = 5 -- 装备共鸣最低星级
XEquipConfig.MAX_SUIT_COUNT = 6                 -- 套装最大数量
XEquipConfig.DEFAULT_SUIT_ID = {                -- 用来显示全部套装数量的默认套装Id
    Normal = 1, --构造体               
    Isomer = 2, --感染体
}
XEquipConfig.CAN_NOT_AUTO_EAT_STAR = 5          -- 大于等于该星级的装备不会被当做默认狗粮选中
XEquipConfig.AWAKE_SKILL_COUNT = 2              -- 觉醒技能数量
XEquipConfig.OVERRUN_ADD_SUIT_CNT = 2           -- 超限增加意识数量
XEquipConfig.OVERRUN_BLIND_SUIT_MIN_QUALITY = 6 -- 超限绑定意识的最低品质

--武器类型
XEquipConfig.EquipType = {
    Universal = 0, -- 通用
    Suncha = 1, -- 双枪
    Sickle = 2, -- 太刀
    Mount = 3, -- 挂载
    Arrow = 4, -- 弓箭
    Chainsaw = 5, -- 电锯
    Sword = 6, -- 大剑
    Hcan = 7, -- 巨炮
    DoubleSwords = 8, -- 双短刀
    sickle = 9, --镰刀
    IsomerSword = 10, -- 感染者专用大剑
    Food = 99, -- 狗粮
}

XEquipConfig.UserType = {
    All = 0, --通用
    Normal = 1, --构造体
    Isomer = 2, --异构体/感染体
}

XEquipConfig.AddAttrType = {
    Numeric = 1, -- 数值
    Rate = 2, -- 基础属性的百分比
    Promoted = 3, -- 等级加成
}

--要显示的属性排序
XEquipConfig.AttrSortType = {
    XNpcAttribType.Life,
    XNpcAttribType.AttackNormal,
    XNpcAttribType.DefenseNormal,
    XNpcAttribType.Crit,
}

XEquipConfig.EquipSite = {
    Weapon = 0, -- 武器
    Awareness = { -- 意识
        One = 1, -- 1号位
        Two = 2, -- 2号位
        Three = 3, -- 3号位
        Four = 4, -- 4号位
        Five = 5, -- 5号位
        Six = 6, -- 6号位
    },
}

XEquipConfig.AwarenessSiteToStr = {
    [XEquipConfig.EquipSite.Awareness.One] = CS.XTextManager.GetText("AwarenessSiteOne"),
    [XEquipConfig.EquipSite.Awareness.Two] = CS.XTextManager.GetText("AwarenessSiteTwo"),
    [XEquipConfig.EquipSite.Awareness.Three] = CS.XTextManager.GetText("AwarenessSiteThree"),
    [XEquipConfig.EquipSite.Awareness.Four] = CS.XTextManager.GetText("AwarenessSiteFour"),
    [XEquipConfig.EquipSite.Awareness.Five] = CS.XTextManager.GetText("AwarenessSiteFive"),
    [XEquipConfig.EquipSite.Awareness.Six] = CS.XTextManager.GetText("AwarenessSiteSix"),
}

XEquipConfig.Classify = {
    Weapon = 1, -- 武器
    Awareness = 2, -- 意识
}

XEquipConfig.EquipResonanceType = {
    Attrib = 1, -- 属性共鸣
    CharacterSkill = 2, -- 角色技能共鸣
    WeaponSkill = 3, -- 武器技能共鸣
}

--排序优先级选项
XEquipConfig.PriorSortType = {
    Star = 0, -- 星级
    Breakthrough = 1, -- 突破次数
    Level = 2, -- 等级
    Proceed = 3, -- 入手顺序
}

-- 武器部位
XEquipConfig.WeaponCase = {
    Case1 = 1,
    Case2 = 2,
    Case3 = 3,
--[[支持继续扩展
    Case4 = 4,
    ...
]]
}

-- 狗粮类型
XEquipConfig.EatType = {
    Equip = 0,
    Item = 1,
}

-- 武器模型用途
XEquipConfig.WeaponUsage = {
    Role = 1, -- ui角色身上
    Battle = 2, -- 战斗
    Show = 3, -- ui单独展示
}

-- 装备详情UI页签
XEquipConfig.EquipDetailBtnTabIndex = {
    Detail = 1,
    Strengthen = 2,
    Resonance = 3,
    Overclocking = 4,
    Overrun = 5,
}

--武器超频界面页签状态 V2.0版本后超频共振只需要晶币
XEquipConfig.EquipAwakeTabIndex = {
    CrystalMoney = 2, --晶币
}

-- 共鸣后武器显示延时时间
XEquipConfig.WeaponResonanceShowDelay = CS.XGame.ClientConfig:GetInt("WeaponResonanceShowDelay")

-- 分解数量溢出提示文本
XEquipConfig.DecomposeRewardOverLimitTip = {
    [XEquipConfig.Classify.Weapon] = CS.XTextManager.GetText("WeaponBoxWillBeFull"),
    [XEquipConfig.Classify.Awareness] = CS.XTextManager.GetText("WaferBoxWillBeFull"),
}

-- 武器超限解锁类型
XEquipConfig.WeaponOverrunUnlockType = {
    Suit = 1,                      -- 意识套装
    AttrEffect = 2,                -- 属性效果
}

local EquipBreakThroughIcon = {
    [0] = CS.XGame.ClientConfig:GetString("EquipBreakThrough0"),
    [1] = CS.XGame.ClientConfig:GetString("EquipBreakThrough1"),
    [2] = CS.XGame.ClientConfig:GetString("EquipBreakThrough2"),
    [3] = CS.XGame.ClientConfig:GetString("EquipBreakThrough3"),
    [4] = CS.XGame.ClientConfig:GetString("EquipBreakThrough4"),
}

local EquipBreakThroughSmallIcon = {
    [1] = CS.XGame.ClientConfig:GetString("EquipBreakThroughSmall1"),
    [2] = CS.XGame.ClientConfig:GetString("EquipBreakThroughSmall2"),
    [3] = CS.XGame.ClientConfig:GetString("EquipBreakThroughSmall3"),
    [4] = CS.XGame.ClientConfig:GetString("EquipBreakThroughSmall4"),
}

local EquipBreakThroughBigIcon = {
    [0] = CS.XGame.ClientConfig:GetString("EquipBreakThroughBig0"),
    [1] = CS.XGame.ClientConfig:GetString("EquipBreakThroughBig1"),
    [2] = CS.XGame.ClientConfig:GetString("EquipBreakThroughBig2"),
    [3] = CS.XGame.ClientConfig:GetString("EquipBreakThroughBig3"),
    [4] = CS.XGame.ClientConfig:GetString("EquipBreakThroughBig4"),
}

-- 共鸣图标（觉醒后图标变更）
local EquipResonanceIconPath = {
    [true] = CS.XGame.ClientConfig:GetString("EquipAwakenIcon"),
    [false] = CS.XGame.ClientConfig:GetString("EquipResonanceIcon"),
}

local TABLE_EQUIP_PATH = "Share/Equip/Equip.tab"
local TABLE_EQUIP_BREAKTHROUGH_PATH = "Share/Equip/EquipBreakThrough.tab"
local TABLE_EQUIP_SUIT_PATH = "Share/Equip/EquipSuit.tab"
local TABLE_EQUIP_SUIT_EFFECT_PATH = "Share/Equip/EquipSuitEffect.tab"
local TABLE_LEVEL_UP_TEMPLATE_PATH = "Share/Equip/LevelUpTemplate/"
local TABLE_EQUIP_DECOMPOSE_PATH = "Share/Equip/EquipDecompose.tab"
local TABLE_EAT_EQUIP_COST_PATH = "Share/Equip/EatEquipCost.tab"
local TABLE_EQUIP_RESONANCE_PATH = "Share/Equip/EquipResonance.tab"
local TABLE_EQUIP_RESONANCE_CONSUME_ITEM_PATH = "Share/Equip/EquipResonanceUseItem.tab"
local TABLE_WEAPON_SKILL_PATH = "Share/Equip/WeaponSkill.tab"
local TABLE_WEAPON_SKILL_POOL_PATH = "Share/Equip/WeaponSkillPool.tab"
local TABLE_EQUIP_AWAKE_PATH = "Share/Equip/EquipAwake.tab"
local TABLE_WEAPON_OVERRUN_PATH = "Share/Equip/WeaponOverrun.tab"
local TABLE_EQUIP_RES_PATH = "Client/Equip/EquipRes.tab"
local TABLE_EQUIP_MODEL_PATH = "Client/Equip/EquipModel.tab"
local TABLE_EQUIP_MODEL_TRANSFORM_PATH = "Client/Equip/EquipModelTransform.tab"
local TABLE_EQUIP_SKIPID_PATH = "Client/Equip/EquipSkipId.tab"
local TABLE_EQUIP_ANIM_PATH = "Client/Equip/EquipAnim.tab"
local TABLE_EQUIP_MODEL_SHOW_PATH = "Client/Equip/EquipModelShow.tab"
local TABLE_EQUIP_RES_BY_FOOL_PATH = "Client/Equip/EquipResByFool.tab"
local TABLE_EQUIP_SIGNBOARD_PATH = "Client/Equip/EquipSignboard.tab"
local TABLE_WEAPON_DEREGULATE_UI = "Client/Equip/WeaponDeregulateUI.tab"
local TABLE_EQUIP_ANIM_RESET = "Client/Equip/EquipAnimReset.tab"

local MAX_WEAPON_COUNT                      -- 武器拥有最大数量
local MAX_AWARENESS_COUNT                   -- 意识拥有最大数量
local EQUIP_EXP_INHERIT_PRECENT             -- 强化时的经验继承百分比
local EQUIP_RECYCLE_ITEM_PERCENT             -- 回收获得道具数量百分比
local MIN_RESONANCE_BIND_STAR               -- 只有6星以上的意识才可以共鸣出绑定角色的技能
local MIN_AWAKE_STAR                        -- 最低可觉醒星数

local EquipBreakthroughTemplate = {}            -- 突破配置
local EquipResonanceTemplate = {}               -- 共鸣配置
local EquipResonanceConsumeItemTemplates = {}   -- 共鸣消耗物品配置
local LevelUpTemplates = {}                     -- 升级模板
local EquipSuitTemplate = {}                    -- 套装技能表
local EquipSuitEffectTemplate = {}              -- 套装效果表
local WeaponSkillTemplate = {}                  -- 武器技能配置
local WeaponSkillPoolTemplate = {}              -- 武器技能池（共鸣用）配置
local EatEquipCostTemplate = {}                 -- 装备强化消耗配置
local EquipResTemplates = {}                    -- 装备资源配置
local EquipModelTemplates = {}                  -- 武器模型配置
local EquipModelTransformTemplates = {}          -- 武器模型UI偏移配置
local EquipEatSkipIdTemplates = {}                 -- 装备升级材料来源跳转ID配置
local EquipSkipIdTemplates = {}                 -- 装备升级材料来源跳转ID配置
local EquipAwakeTemplate = {}                   -- 觉醒配置
local EquipAnimTemplates = {}                   -- 动画配置
local EquipModelShowTemplate = {}                   -- 控制武器模型显示
local EquipResByFoolTemplate = {}               -- 愚人节装备资源替换配置
local WeaponOverrunTemplate = {}                -- 武器超限配置
local WeaponDeregulateUITemplate = {}           -- 武器超限的UI配置

local EquipBorderDic = {}                   -- 装备边界属性构造字典
local EquipDecomposeDic = {}
local SuitIdToEquipTemplateIdsDic = {}      -- 套装Id索引的装备Id字典 --这个是根据装备位置为key存储的
local SuitIdToEquipTemplateIdsList = {}     -- 套装Id索引的装备Id数组 --这个是有序数组
local SuitSitesDic = {}                     -- 套装产出部位字典
local WeaponOverrunDic = {}                 -- 武器超限字典

local EquipSignboardCfg = nil                -- 绑定武器到动作、皮肤配置
local EquipSignboardDic = nil                -- 绑定武器到动作、皮肤字典
local EquipAnimResetDic = {}                 -- 武器动画重置

--记录超频界面的页签状态
local EquipAwakeTabIndex = XEquipConfig.EquipAwakeTabIndex.CrystalMoney

local CompareBreakthrough = function(templateId, breakthrough)
    local template = EquipBorderDic[templateId]
    if not template then
        return
    end

    if not template.MaxBreakthrough or template.MaxBreakthrough < breakthrough then
        template.MaxBreakthrough = breakthrough
    end
end

local CheckEquipBorderConfig = function()
    for k, v in pairs(EquipBorderDic) do
        local template = EquipBorderDic[k]
        template.MinLevel = 1
        local equipBreakthroughCfg = XEquipConfig.GetEquipBreakthroughCfg(k, v.MaxBreakthrough)
        template.MaxLevel = equipBreakthroughCfg.LevelLimit
        template.MinBreakthrough = 0
    end
end

local InitEquipBreakthroughConfig = function()
    local tab = XTableManager.ReadByIntKey(TABLE_EQUIP_BREAKTHROUGH_PATH, XTable.XTableEquipBreakthrough, "Id")
    for _, config in pairs(tab) do
        if not EquipBreakthroughTemplate[config.EquipId] then
            EquipBreakthroughTemplate[config.EquipId] = {}
        end

        if config.AttribPromotedId == 0 then
            XLog.ErrorTableDataNotFound("InitEquipBreakthroughConfig", "EquipBreakthroughTemplate",
            TABLE_EQUIP_BREAKTHROUGH_PATH, "config.EquipId", tostring(config.EquipId))
        end

        EquipBreakthroughTemplate[config.EquipId][config.Times] = config
        CompareBreakthrough(config.EquipId, config.Times)
    end
end

local InitEquipLevelConfig = function()
    local paths = CS.XTableManager.GetPaths(TABLE_LEVEL_UP_TEMPLATE_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = tonumber(XTool.GetFileNameWithoutExtension(path))
        LevelUpTemplates[key] = XTableManager.ReadByIntKey(path, XTable.XTableEquipLevelUp, "Level")
    end)
end

local InitWeaponSkillPoolConfig = function()
    local tab = XTableManager.ReadByIntKey(TABLE_WEAPON_SKILL_POOL_PATH, XTable.XTableWeaponSkillPool, "Id")
    for _, config in pairs(tab) do
        WeaponSkillPoolTemplate[config.PoolId] = WeaponSkillPoolTemplate[config.PoolId] or {}
        WeaponSkillPoolTemplate[config.PoolId][config.CharacterId] = WeaponSkillPoolTemplate[config.PoolId][config.CharacterId] or {}

        for i, skillId in ipairs(config.SkillId) do
            tableInsert(WeaponSkillPoolTemplate[config.PoolId][config.CharacterId], skillId)
        end
    end
end

local InitEquipModelTransformConfig = function()
    local tab = XTableManager.ReadByIntKey(TABLE_EQUIP_MODEL_TRANSFORM_PATH, XTable.XTableEquipModelTransform, "Id")
    for id, config in pairs(tab) do
        local indexId = config.IndexId
        if not indexId then
            XLog.ErrorTableDataNotFound("InitEquipModelTransformConfig", "tab", TABLE_EQUIP_MODEL_TRANSFORM_PATH, "id", tostring(id))
        end
        EquipModelTransformTemplates[indexId] = EquipModelTransformTemplates[indexId] or {}

        local uiName = config.UiName
        if not uiName then
            XLog.ErrorTableDataNotFound("InitEquipModelTransformConfig", "配置表中UiName字段", TABLE_EQUIP_MODEL_TRANSFORM_PATH, "id", tostring(id))
        end
        EquipModelTransformTemplates[indexId][uiName] = config
    end
end

local InitEquipSkipIdConfig = function()
    local tab = XTableManager.ReadByIntKey(TABLE_EQUIP_SKIPID_PATH, XTable.XTableEquipSkipId, "Id")
    for id, config in pairs(tab) do
        local eatType = config.EatType
        EquipEatSkipIdTemplates[eatType] = EquipEatSkipIdTemplates[eatType] or {}

        local site = config.Site
        if not site then
            XLog.ErrorTableDataNotFound("InitEquipSkipIdConfig", "配置表中Site字段", TABLE_EQUIP_SKIPID_PATH, "id", tostring(id))
        end
        --装备来源
        if XTool.IsNumberValid(config.EquipType) then
            EquipSkipIdTemplates[config.EquipType] = config
        else --装备升级材料来源
            EquipEatSkipIdTemplates[eatType][site] = config
        end
       
    end
end

local InitEquipSuitConfig = function()
    EquipSuitTemplate = XTableManager.ReadByIntKey(TABLE_EQUIP_SUIT_PATH, XTable.XTableEquipSuit, "Id")
    EquipSuitEffectTemplate = XTableManager.ReadByIntKey(TABLE_EQUIP_SUIT_EFFECT_PATH, XTable.XTableEquipSuitEffect, "Id")
end

local InitWeaponDeregulateConfig = function()
    WeaponOverrunTemplate = XTableManager.ReadByIntKey(TABLE_WEAPON_OVERRUN_PATH, XTable.XTableWeaponOverrun, "Id")
    for _, cfg in ipairs(WeaponOverrunTemplate) do
        local weaponId = cfg.WeaponId
        local cfgs = WeaponOverrunDic[weaponId]
        if not cfgs then 
            cfgs = {}
            WeaponOverrunDic[weaponId] = cfgs
        end
        table.insert(cfgs, cfg)
    end
end

function XEquipConfig.Init()
    MAX_WEAPON_COUNT = CS.XGame.Config:GetInt("EquipWeaponMaxCount")
    MAX_AWARENESS_COUNT = CS.XGame.Config:GetInt("EquipChipMaxCount")
    EQUIP_EXP_INHERIT_PRECENT = CS.XGame.Config:GetInt("EquipExpInheritPercent")
    EQUIP_RECYCLE_ITEM_PERCENT = CS.XGame.Config:GetInt("EquipRecycleItemPercent")
    MIN_RESONANCE_BIND_STAR = CS.XGame.Config:GetInt("MinResonanceBindStar")
    MIN_AWAKE_STAR = CS.XGame.Config:GetInt("MinEquipAwakeStar")

    EquipResTemplates = XTableManager.ReadByIntKey(TABLE_EQUIP_RES_PATH, XTable.XTableEquipRes, "Id")
    EquipAwakeTemplate = XTableManager.ReadByIntKey(TABLE_EQUIP_AWAKE_PATH, XTable.XTableEquipAwake, "Id")
    local equipTemplates = XEquipConfig.GetEquipTemplates()
    XTool.LoopMap(equipTemplates, function(id, equipCfg)
        EquipBorderDic[id] = {}
        local suitId = equipCfg.SuitId
        if suitId and suitId > 0 then
            SuitIdToEquipTemplateIdsDic[suitId] = SuitIdToEquipTemplateIdsDic[suitId] or {}
            SuitIdToEquipTemplateIdsDic[suitId][equipCfg.Site] = id

            SuitIdToEquipTemplateIdsList[suitId] = SuitIdToEquipTemplateIdsList[suitId] or {}
            tableInsert(SuitIdToEquipTemplateIdsList[suitId], id)

            SuitSitesDic[suitId] = SuitSitesDic[suitId] or {}
            SuitSitesDic[suitId][equipCfg.Site] = true
        end
    end)

    InitEquipSuitConfig()
    InitEquipBreakthroughConfig()
    InitEquipLevelConfig()
    InitWeaponSkillPoolConfig()
    InitEquipModelTransformConfig()
    InitEquipSkipIdConfig()
    InitWeaponDeregulateConfig()

    CheckEquipBorderConfig()

    --EquipBorderDic = XReadOnlyTable.Create(EquipBorderDic)
    WeaponSkillTemplate = XTableManager.ReadByIntKey(TABLE_WEAPON_SKILL_PATH, XTable.XTableWeaponSkill, "Id")
    EquipResonanceTemplate = XTableManager.ReadByIntKey(TABLE_EQUIP_RESONANCE_PATH, XTable.XTableEquipResonance, "Id")
    EquipResonanceConsumeItemTemplates = XTableManager.ReadByIntKey(TABLE_EQUIP_RESONANCE_CONSUME_ITEM_PATH, XTable.XTableEquipResonanceUseItem, "Id")
    EquipModelTemplates = XTableManager.ReadByIntKey(TABLE_EQUIP_MODEL_PATH, XTable.XTableEquipModel, "Id")
    EquipAnimTemplates = XTableManager.ReadByStringKey(TABLE_EQUIP_ANIM_PATH, XTable.XTableEquipAnim, "ModelId")
    EquipModelShowTemplate = XTableManager.ReadByStringKey(TABLE_EQUIP_MODEL_SHOW_PATH, XTable.XTableEquipModelShow, "Id")
    EquipResByFoolTemplate = XTableManager.ReadByIntKey(TABLE_EQUIP_RES_BY_FOOL_PATH, XTable.XTableEquipResByFool, "Id")
    WeaponDeregulateUITemplate = XTableManager.ReadByIntKey(TABLE_WEAPON_DEREGULATE_UI, XTable.XTableWeaponDeregulateUI, "Lv")

    local decomposetab = XTableManager.ReadByIntKey(TABLE_EQUIP_DECOMPOSE_PATH, XTable.XTableEquipDecompose, "Id")
    for _, v in pairs(decomposetab) do
        EquipDecomposeDic[v.Site .. v.Star .. v.Breakthrough] = v
    end

    local eatCostTab = XTableManager.ReadByIntKey(TABLE_EAT_EQUIP_COST_PATH, XTable.XTableEatEquipCost, "Id")
    for _, v in pairs(eatCostTab) do
        EatEquipCostTemplate[v.Site .. v.Star] = v.UseMoney
    end

    local animResetTab = XTableManager.ReadByIntKey(TABLE_EQUIP_ANIM_RESET, XTable.XTableEquipAnimReset, "Id")
    for _, v in pairs(animResetTab) do
        EquipAnimResetDic[v.CharacterModel] = true
    end
end

function XEquipConfig.GetMaxWeaponCount()
    return MAX_WEAPON_COUNT
end

function XEquipConfig.GetMaxAwarenessCount()
    return MAX_AWARENESS_COUNT
end

function XEquipConfig.GetEquipExpInheritPercent()
    return EQUIP_EXP_INHERIT_PRECENT
end

function XEquipConfig.GetEquipRecycleItemId()
    return XDataCenter.ItemManager.ItemId.EquipRecycleItemId
end

function XEquipConfig.GetEquipRecycleItemPercent()
    return EQUIP_RECYCLE_ITEM_PERCENT / 100
end

function XEquipConfig.GetMinResonanceBindStar()
    return MIN_RESONANCE_BIND_STAR
end

function XEquipConfig.GetMinAwakeStar()
    return MIN_AWAKE_STAR
end

function XEquipConfig.GetEquipCfg(templateId)
    return XMVCA:GetAgency(ModuleId.XEquip):GetConfigEquip(templateId)
end

--todo 道具很多地方没有检查ID类型就调用了，临时处理下
function XEquipConfig.CheckTemplateIdIsEquip(templateId)
    if not templateId then
        return false
    end

    local equipTemplates = XEquipConfig.GetEquipTemplates()
    return equipTemplates[templateId] ~= nil
end

function XEquipConfig.GetEatEquipCostMoney(site, star)
    if not site then
        XLog.Error("XEquipConfig.GetEatEquipCostMoney函数参数错误，site不能为空")
        return
    end
    if not star then
        XLog.Error("XEquipConfig.GetEatEquipCostMoney函数参数错误，star不能为空")
        return
    end

    return EatEquipCostTemplate[site .. star]
end

function XEquipConfig.GetEquipBorderCfg(templateId)
    local template = EquipBorderDic[templateId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipBorderCfg", "template", TABLE_EQUIP_PATH, "templateId", tostring(templateId))
        return
    end
    return template
end

function XEquipConfig.GetEquipBreakthroughCfg(templateId, times)
    local template = EquipBreakthroughTemplate[templateId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipBreakthroughCfg", "template",
        TABLE_EQUIP_BREAKTHROUGH_PATH, "templateId", tostring(templateId))
        return
    end

    template = template[times]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipBreakthroughCfg", "template",
        TABLE_EQUIP_BREAKTHROUGH_PATH, "templateId : times", tostring(templateId) .. " : " .. tostring(times))
        return
    end

    return template
end

function XEquipConfig.GetEquipResCfg(templateId, breakthroughTimes)
    breakthroughTimes = breakthroughTimes or 0
    local breakthroughCfg = XEquipConfig.GetEquipBreakthroughCfg(templateId, breakthroughTimes)

    local resId = breakthroughCfg.ResId
    if not resId then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipResCfg", "resId",
        TABLE_EQUIP_BREAKTHROUGH_PATH, "templateId : times", tostring(templateId) .. " : " .. tostring(breakthroughTimes))
        return
    end

    local template = EquipResTemplates[resId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipResCfg", "template", TABLE_EQUIP_RES_PATH, "resId", tostring(resId))
        return
    end

    return template
end

--=========== EquipModel接口(begin) ===========
function XEquipConfig.GetEquipModelName(modelTransId, usage)
    -- 修正V2.7 黑岩武器挂点，模型资源未按规范制作
    if modelTransId == 0 then
        return ""
    end

    local template = EquipModelTemplates[modelTransId]

    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipModelName", "template", TABLE_EQUIP_MODEL_PATH, "modelTransId", tostring(modelTransId))
        return
    end

    usage = usage or XEquipConfig.WeaponUsage.Role
    return template.ModelName[usage] or template.ModelName[XEquipConfig.WeaponUsage.Role]
end

function XEquipConfig.GetEquipAnimController(modelTransId, usage)
    -- 修正V2.7 黑岩武器挂点，模型资源未按规范制作
    if modelTransId == 0 then
        return ""
    end
    
    local template = EquipModelTemplates[modelTransId]

    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipAnimController", "template", TABLE_EQUIP_MODEL_PATH, "modelTransId", tostring(modelTransId))
        return
    end

    usage = usage or XEquipConfig.WeaponUsage.Role

    local controller = template.AnimController[usage]
    if not controller and usage ~= XEquipConfig.WeaponUsage.Show then -- 单独展示不需默认值
        controller = template.AnimController[XEquipConfig.WeaponUsage.Role]
    end
    return controller
end

function XEquipConfig.GetEquipUiAnimStateName(modelTransId, usage)
    local template = EquipModelTemplates[modelTransId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipUiAnimStateName", "template", TABLE_EQUIP_MODEL_PATH, "modelTransId", tostring(modelTransId))
        return
    end

    usage = usage or XEquipConfig.WeaponUsage.Role
    return template.UiAnimStateName[usage] or template.UiAnimStateName[XEquipConfig.WeaponUsage.Role]
end

function XEquipConfig.GetEquipUiAnimCueId(modelTransId, usage)
    local template = EquipModelTemplates[modelTransId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipUiAnimCueId", "template", TABLE_EQUIP_MODEL_PATH, "modelTransId", tostring(modelTransId))
        return
    end

    usage = usage or XEquipConfig.WeaponUsage.Role
    return template.UiAnimCueId[usage] or template.UiAnimCueId[XEquipConfig.WeaponUsage.Role]
end

function XEquipConfig.GetEquipUiAnimDelay(modelTransId, usage)
    local template = EquipModelTemplates[modelTransId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipUiAnimDelay", "template", TABLE_EQUIP_MODEL_PATH, "modelTransId", tostring(modelTransId))
        return
    end

    usage = usage or XEquipConfig.WeaponUsage.Role
    return template.UiAnimDelay[usage] or template.UiAnimDelay[XEquipConfig.WeaponUsage.Role]
end

function XEquipConfig.GetEquipUiAutoRotateDelay(modelTransId, usage)
    local template = EquipModelTemplates[modelTransId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipUiAutoRotateDelay", "template", TABLE_EQUIP_MODEL_PATH, "modelTransId", tostring(modelTransId))
        return
    end

    usage = usage or XEquipConfig.WeaponUsage.Show -- 默认ui展示
    return template.UiAutoRotateDelay[usage] or template.UiAutoRotateDelay[XEquipConfig.WeaponUsage.Role]
end

function XEquipConfig.GetEquipModelEffectPath(modelTransId, usage)
    local template = EquipModelTemplates[modelTransId]

    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipModelEffectPath", "template", TABLE_EQUIP_MODEL_PATH, "modelTransId", tostring(modelTransId))
        return
    end

    usage = usage or XEquipConfig.WeaponUsage.Role
    return template.ResonanceEffectPath[usage] or template.ResonanceEffectPath[XEquipConfig.WeaponUsage.Role]
end
--=========== EquipModel接口(end) ===========
function XEquipConfig.GetEquipAnimParams(roleModelId)
    local template = EquipAnimTemplates[roleModelId]
    if not template then
        return 0
    end
    return template.Params or 0
end

function XEquipConfig.GetWeaponResonanceModelId(case, templateId, resonanceCount)
    local modelId
    local template = EquipResTemplates[templateId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetWeaponResonanceModelId", "template", TABLE_EQUIP_RES_PATH, "templateId", tostring(templateId))
        return
    end
    if resonanceCount == 1 then
        modelId = template.ResonanceModelTransId1[case]
    elseif resonanceCount == 2 then
        modelId = template.ResonanceModelTransId2[case]
    elseif resonanceCount == 3 then
        modelId = template.ResonanceModelTransId3[case]
    end
    return modelId or template.ModelTransId[case]
end

function XEquipConfig.GetWeaponResonanceEffectDelay(modelTransId)
    local template = EquipModelTemplates[modelTransId]

    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetWeaponResonanceEffectDelay",
        "template", TABLE_EQUIP_MODEL_PATH, "modelTransId", tostring(modelTransId))
        return
    end

    return template.ResonanceEffectShowDelay[XEquipConfig.WeaponUsage.Show] or 0
end

--返回武器模型和位置配置（双枪只返回一把）
function XEquipConfig.GetEquipModelTransformCfg(templateId, uiName, resonanceCount, modelTransId, equipType)
    local modelCfg, template

    --尝试用ModelTransId索引
    if not modelTransId then
        modelTransId = XEquipConfig.GetWeaponResonanceModelId(XEquipConfig.WeaponCase.Case1, templateId, resonanceCount)
        if not modelTransId then
            XLog.ErrorTableDataNotFound("XEquipConfig.GetWeaponResonanceModelId",
            "template", TABLE_EQUIP_RES_PATH, "templateId", tostring(templateId))
            return
        end
    end

    template = EquipModelTransformTemplates[modelTransId]
    if template then
        modelCfg = template[uiName]
    end

    --读不到配置时用equipType索引
    if not modelCfg then
        if not equipType then
            local equipCfg = XEquipConfig.GetEquipCfg(templateId)
            equipType = equipCfg.Type
        end

        template = EquipModelTransformTemplates[equipType]
        if not template then
            XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipModelTransformCfg",
            "template", TABLE_EQUIP_MODEL_TRANSFORM_PATH, "equipType", tostring(equipType))
            return
        end

        modelCfg = template[uiName]
        if not modelCfg then
            XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipModelTransformCfg",
            "uiName", TABLE_EQUIP_MODEL_TRANSFORM_PATH, "equipType", tostring(equipType))
            return
        end
    end

    return modelCfg
end


-- 获取一个武器所有的不同的模型列表
function XEquipConfig.GetWeaponModelCfgList(templateId, uiName, breakthroughTimes)
    local modelCfgList = {}

    if not templateId then
        XLog.Error("XEquipManager.GetWeaponModelCfgList函数参数错误, templateId不能为空")
        return modelCfgList
    end

    local template = XEquipConfig.GetEquipResCfg(templateId, breakthroughTimes)
    -- 目前只有共鸣改变形态，有可能有相同的模型，所以需要区别是否有相同的id，以左手id为准
    local resonanceCountList = {}
    local resonanceDic = {}
    local modelId
    for i = 0, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
        modelId = XEquipConfig.GetWeaponResonanceModelId(XEquipConfig.WeaponCase.Case1, template.Id, i)
        if modelId and not resonanceDic[modelId] then
            resonanceDic[modelId] = true
            table.insert(resonanceCountList, i)
        end
    end

    local modelCfg
    for _, resonanceCount in ipairs(resonanceCountList) do
        modelCfg = {}
        modelCfg.ModelId = XEquipConfig.GetWeaponResonanceModelId(XEquipConfig.WeaponCase.Case1, template.Id, resonanceCount)
        modelCfg.TransformConfig = XEquipConfig.GetEquipModelTransformCfg(templateId, uiName, resonanceCount)
        table.insert(modelCfgList, modelCfg)
    end

    return modelCfgList
end

function XEquipConfig.GetLevelUpCfg(templateId, times, level)
    local breakthroughCfg = XEquipConfig.GetEquipBreakthroughCfg(templateId, times)
    if not breakthroughCfg then
        return
    end

    templateId = breakthroughCfg.LevelUpTemplateId

    local template = LevelUpTemplates[templateId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetLevelUpCfg", "template", TABLE_LEVEL_UP_TEMPLATE_PATH, "templateId", tostring(templateId))
        return
    end

    template = template[level]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetLevelUpCfg", "level", TABLE_LEVEL_UP_TEMPLATE_PATH, "templateId", tostring(templateId))
        return
    end

    return template
end

function XEquipConfig.GetEquipSuitCfg(templateId)
    local template = EquipSuitTemplate[templateId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipSuitCfg", "template", TABLE_EQUIP_SUIT_PATH, "templateId", tostring(templateId))
        return
    end
    return template
end

function XEquipConfig.GetEquipSuitEffectCfg(templateId)
    local template = EquipSuitEffectTemplate[templateId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipSuitEffectCfg", "template",
        TABLE_EQUIP_SUIT_EFFECT_PATH, "templateId", tostring(templateId))
        return
    end

    return template
end

function XEquipConfig.GetEquipTemplateIdsBySuitId(suitId)
    return SuitIdToEquipTemplateIdsDic[suitId] or {}
end

--这个是获取数组的
function XEquipConfig.GetEquipTemplateIdsListBySuitId(suitId)
    return SuitIdToEquipTemplateIdsList[suitId] or {}
end

function XEquipConfig.GetSuitSites(suitId)
    return SuitSitesDic[suitId] or {}
end

function XEquipConfig.GetMaxSuitCount()
    return XTool.GetTableCount(SuitSitesDic)
end

function XEquipConfig.GetEquipBgPath(templateId)
    if not XEquipConfig.CheckTemplateIdIsEquip(templateId) then return end
    local template = XEquipConfig.GetEquipCfg(templateId)
    local quality = template.Quality
    return XArrangeConfigs.GeQualityBgPath(quality)
end

function XEquipConfig.GetEquipQualityPath(templateId)
    local template = XEquipConfig.GetEquipCfg(templateId)
    local quality = template.Quality
    if not quality then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipQualityPath", "Quality", TABLE_EQUIP_PATH, "templateId", tostring(templateId))
        return
    end
    return XArrangeConfigs.GeQualityPath(quality)
end

function XEquipConfig.GetEquipResoanceIconPath(isAwaken)
    return EquipResonanceIconPath[isAwaken]
end

function XEquipConfig.GetEquipDecomposeCfg(templateId, breakthroughTimes)
    if not XEquipConfig.CheckTemplateIdIsEquip(templateId) then return end
    breakthroughTimes = breakthroughTimes or 0

    local template = XEquipConfig.GetEquipCfg(templateId)
    local site = template.Site
    if not site then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipDecomposeCfg", "Site", TABLE_EQUIP_PATH, "templateId", tostring(templateId))
        return
    end

    local star = template.Star
    if not star then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipDecomposeCfg", "Star", TABLE_EQUIP_PATH, "templateId", tostring(templateId))
        return
    end

    return EquipDecomposeDic[site .. star .. breakthroughTimes]
end

function XEquipConfig.GetWeaponTypeIconPath(templateId)
    return XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId).Icon
end

function XEquipConfig.GetEquipBreakThroughIcon(breakthroughTimes)
    local icon = EquipBreakThroughIcon[breakthroughTimes]
    if not icon then
        XLog.Error("XEquipConfig.EquipBreakThroughIcon调用错误，得到的icon为空，原因：检查breakthroughTimes：" .. breakthroughTimes .. "和EquipBreakThroughIcon")
        return
    end
    return icon
end

function XEquipConfig.GetEquipBreakThroughSmallIcon(breakthroughTimes)
    local icon = EquipBreakThroughSmallIcon[breakthroughTimes]
    if not icon then
        XLog.Error("XEquipConfig.GetEquipBreakThroughSmallIcon调用错误，得到的icon为空，原因：检查breakthroughTimes：" .. breakthroughTimes .. "和EquipBreakThroughSmallIcon")
        return
    end
    return icon
end

function XEquipConfig.GetEquipBreakThroughBigIcon(breakthroughTimes)
    local icon = EquipBreakThroughBigIcon[breakthroughTimes]
    if not icon then
        XLog.Error("XEquipConfig.GetEquipBreakThroughBigIcon调用错误，得到的icon为空，原因：检查breakthroughTimes：" .. breakthroughTimes .. "和EquipBreakThroughBigIcon")
        return
    end
    return icon
end

function XEquipConfig.GetWeaponSkillTemplate(templateId)
    local template = WeaponSkillTemplate[templateId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetWeaponSkillTemplate", "template", TABLE_WEAPON_SKILL_PATH, "templateId", tostring(templateId))
        return
    end

    return template
end

function XEquipConfig.GetWeaponSkillInfo(weaponSkillId)
    local template = WeaponSkillTemplate[weaponSkillId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetWeaponSkillInfo", "template", TABLE_WEAPON_SKILL_PATH, "weaponSkillId", tostring(weaponSkillId))
        return
    end

    return template
end

function XEquipConfig.GetWeaponSkillAbility(weaponSkillId)
    local template = WeaponSkillTemplate[weaponSkillId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetWeaponSkillAbility", "template",
        TABLE_WEAPON_SKILL_PATH, "weaponSkillId", tostring(weaponSkillId))
        return
    end

    return template.Ability
end

function XEquipConfig.GetWeaponSkillPoolSkillIds(poolId, characterId)
    local template = WeaponSkillPoolTemplate[poolId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetWeaponSkillPoolSkillIds", "template", TABLE_WEAPON_SKILL_POOL_PATH, "poolId", tostring(poolId))
        return
    end

    local skillIds = template[characterId]
    if not skillIds then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetWeaponSkillPoolSkillIds",
        "characterId", TABLE_WEAPON_SKILL_POOL_PATH, "poolId", tostring(poolId))
        return
    end

    return skillIds
end

function XEquipConfig.GetEquipEatSkipIdTemplate(eatType, site)
    local template = EquipEatSkipIdTemplates[eatType][site]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipEatSkipIdTemplate", "site", TABLE_WEAPON_SKILL_POOL_PATH, "eatType", tostring(eatType))
        return
    end
    return template
end

function XEquipConfig.GetEquipSkipIdTemplate(equipType)
    local template = EquipSkipIdTemplates[equipType]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipSkipIdTemplate", "Config", TABLE_WEAPON_SKILL_POOL_PATH, "eatType", tostring(equipType))
        return
    end
    return template
end

function XEquipConfig.GetEquipResonanceCfg(templateId)
    local equipResonanceCfg = EquipResonanceTemplate[templateId]

    if not equipResonanceCfg then
        return
    end

    return equipResonanceCfg
end

function XEquipConfig.GetEquipCharacterType(templateId)
    local config = XEquipConfig.GetEquipCfg(templateId)
    return config.CharacterType
end

function XEquipConfig.GetEquipResonanceConsumeItemCfg(templateId)
    local equipResonanceItemCfg = EquipResonanceConsumeItemTemplates[templateId]

    if not equipResonanceItemCfg then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipResonanceConsumeItemCfg",
        "equipResonanceItemCfg", TABLE_EQUIP_RESONANCE_CONSUME_ITEM_PATH, "templateId", tostring(templateId))
        return
    end

    return equipResonanceItemCfg
end

function XEquipConfig.GetNeedFirstShow(templateId)
    local template = XEquipConfig.GetEquipCfg(templateId)
    return template.NeedFirstShow
end

function XEquipConfig.GetEquipTemplates()
    return XMVCA:GetAgency(ModuleId.XEquip):GetConfigEquip()
end

function XEquipConfig.GetEquipAwakeCfg(templateId)
    local equipAwakeCfg = EquipAwakeTemplate[templateId]
    if not equipAwakeCfg then
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipAwakeCfg", "equipAwakeCfg", TABLE_EQUIP_AWAKE_PATH, "templateId", tostring(templateId))
        return
    end
    return equipAwakeCfg
end

function XEquipConfig.GetEquipAwakeCfgs()
    return EquipAwakeTemplate
end

function XEquipConfig.GetEquipAwakeSkillDesList(templateId, pos)
    local equipAwakeCfg = XEquipConfig.GetEquipAwakeCfg(templateId)
    local desList = equipAwakeCfg["AttribDes" .. pos]
    if not desList then
        local tempStr = "AttribDes" .. pos
        XLog.ErrorTableDataNotFound("XEquipConfig.GetEquipAwakeSkillDesList", tempStr, TABLE_EQUIP_AWAKE_PATH, "templateId", tostring(templateId))
        return
    end
    return desList
end

function XEquipConfig.GetEquipSuitPath()
    return TABLE_EQUIP_SUIT_PATH
end

function XEquipConfig.GetEquipPath()
    return TABLE_EQUIP_PATH
end

function XEquipConfig.GetWeaponSkillPath()
    return TABLE_WEAPON_SKILL_PATH
end

function XEquipConfig.IsDefaultSuitId(suitId)
    return suitId == XEquipConfig.DEFAULT_SUIT_ID.Normal or suitId == XEquipConfig.DEFAULT_SUIT_ID.Isomer
end

function XEquipConfig.GetDefaultSuitIdCount()
    local count = 0
    for _, _ in pairs(XEquipConfig.DEFAULT_SUIT_ID) do
        count = count + 1
    end
    return count
end

function XEquipConfig.GetEquipAwakeTabIndex()
    return EquipAwakeTabIndex
end

function XEquipConfig.GetEquipModelShowHideNodeName(modelId, UiName)
    for _, cfg in pairs(EquipModelShowTemplate) do
        if cfg.ModelId == modelId and cfg.UiName == UiName then
            return cfg.HideNodeName or {}
        end
    end
    return {}
end

------------愚人节装备替换相关 begin----------------
function XEquipConfig.GetFoolEquipResCfg(templateId)
    return EquipResByFoolTemplate[templateId]
end

function XEquipConfig.GetFoolWeaponResonanceModelId(case, templateId, resonanceCount)
    local modelId
    local template = XEquipConfig.GetFoolEquipResCfg(templateId)
    if not template then
        return
    end
    if resonanceCount == 1 then
        modelId = template.ResonanceModelTransId1[case]
    elseif resonanceCount == 2 then
        modelId = template.ResonanceModelTransId2[case]
    elseif resonanceCount == 3 then
        modelId = template.ResonanceModelTransId3[case]
    end
    return modelId or template.ModelTransId[case]
end
------------愚人节装备替换相关 end----------------

--region-------------------------武器指定状态机相关-----------------------------------
---@class _EquipSignboardActiveEnum
---@field Character number
---@field Fashion number
local _EquipSignboardAllActiveEnum = enum({
    Character = 1,
    Fashion = 1,
})

local function GetEquipSignboardCfgs()
    if EquipSignboardCfg == nil then
        EquipSignboardCfg = XTableManager.ReadByIntKey(TABLE_EQUIP_SIGNBOARD_PATH, XTable.XTableEquipSignboard, "Id")
    end

    return EquipSignboardCfg
end

--[[
=======================================================================================
当EquipSignboar表ChaIsAllActive字段为1时
EquipSignboardDic = {
    [characterId] = {
        ChaIsAllActive = true,
        EquipModelIndex = config.EquipModelIndex
    },
}
否则
    当EquipSignboar表FashionId字段为空时
        当EquipSignboar表FashIsAllActive为1时
        EquipSignboardDic = {
            [characterId] = {
                ChaIsAllActive = false,
                AllFashion = true,
                FashIsAllActive = true,
                EquipModelIndex = config.EquipModelIndex
            },
        }
        否则
            当EquipSignboar表ActionId字段为空时
            EquipSignboardDic = {
                [characterId] = {
                    ChaIsAllActive = false,
                    AllFashion = true,
                    FashIsAllActive = false,
                    AllAction = true,
                    EquipModelIndex = config.EquipModelIndex
                },
            }
            否则
            EquipSignboardDic = {
                [characterId] = {
                    ChaIsAllActive = false,
                    AllFashion = true,
                    FashIsAllActive = false,
                    AllAction = false,
                    ActionIdDic = {
                        [actionId] = config.EquipModelIndex,
                    }
                },
            }
    否则
        当EquipSignboar表FashIsAllActive为1时
        EquipSignboardDic = {
            [characterId] = {
                ChaIsAllActive = false,
                AllFashion = false,
                FashionIdDic = {
                    [fashionId] = {
                        FashIsAllActive = true,
                        EquipModelIndex = config.EquipModelIndex
                    },
                }
            },
        }
        否则
            当EquipSignboar表ActionId字段为空时
            EquipSignboardDic = {
                [characterId] = {
                    ChaIsAllActive = false,
                    AllFashion = false,
                    FashionIdDic = {
                        [fashionId] = {
                            FashIsAllActive = false,
                            AllAction = true,
                            EquipModelIndex = config.EquipModelIndex
                        },
                    }
                }
            }
            否则
            EquipSignboardDic = {
                [characterId] = {
                    ChaIsAllActive = false,
                    AllFashion = false,
                    FashionIdDic = {
                        [fashionId] = {
                            FashIsAllActive = false,
                            AllAction = false,
                            ActionIdDic = {
                                [actionId] = config.EquipModelIndex,
                            }
                        },
                    }
                }
            }
=======================================================================================
]]

local function GetEquipSignboardDic()
    if EquipSignboardDic == nil then
        local configs = GetEquipSignboardCfgs()

        EquipSignboardDic = {}

        for id, config in Pairs(configs) do
            local equipModelIndex = config.EquipModelIndex
            local characterId = config.CharacterId
            local fashionId = config.FashionId
            local actionId = config.ActionId
            
            if not equipModelIndex then
                XLog.Error(StringFormat("EquipSignboard表的EquipModelIndex字段为空！Id:%d, 路径:%s", id, TABLE_EQUIP_SIGNBOARD_PATH))
                EquipSignboardDic = {}

                return EquipSignboardDic
            end
            EquipSignboardDic[characterId] = EquipSignboardDic[characterId] or {}

            if config.ChaIsAllActive and config.ChaIsAllActive == _EquipSignboardAllActiveEnum.Character then
                if not characterId then
                    XLog.Error(StringFormat("EquipSignboard表CharacterId为空！Id:%d, 路径:%s", id, TABLE_EQUIP_SIGNBOARD_PATH))
                    EquipSignboardDic = {}

                    return EquipSignboardDic
                end

                EquipSignboardDic[characterId].ChaIsAllActive = true
                EquipSignboardDic[characterId].EquipModelIndex = equipModelIndex
            else
                EquipSignboardDic[characterId].ChaIsAllActive = false

                if not fashionId or fashionId == 0 then
                    EquipSignboardDic[characterId].AllFashion = true

                    if EquipSignboardDic[characterId].FashionIdDic then
                        EquipSignboardDic[characterId].FashionIdDic = nil
                        XLog.Error(StringFormat("EquipSignboard表CharacterId(%d)配置全部涂装开启武器，会覆盖当前CharacterId的其它涂装配置！Id:%d, 路径:%s", characterId, id, TABLE_EQUIP_SIGNBOARD_PATH))
                    end

                    if config.FashIsAllActive and config.FashIsAllActive == _EquipSignboardAllActiveEnum.Fashion then
                        EquipSignboardDic[characterId].FashIsAllActive = true
                        EquipSignboardDic[characterId].EquipModelIndex = equipModelIndex
                    else
                        EquipSignboardDic[characterId].FashIsAllActive = false

                        if not actionId or actionId == 0 then
                            EquipSignboardDic[characterId].AllAction = true
                            EquipSignboardDic[characterId].EquipModelIndex = equipModelIndex
                        else
                            EquipSignboardDic[characterId].ActionIdDic = EquipSignboardDic[characterId].ActionIdDic or {}
                            EquipSignboardDic[characterId].ActionIdDic[actionId] = equipModelIndex
                        end
                    end
                else
                    EquipSignboardDic[characterId].AllFashion = false
                    EquipSignboardDic[characterId].FashionIdDic = EquipSignboardDic[characterId].FashionIdDic or {}
                    EquipSignboardDic[characterId].FashionIdDic[fashionId] = EquipSignboardDic[characterId].FashionIdDic[fashionId] or {}

                    if config.FashIsAllActive and config.FashIsAllActive == _EquipSignboardAllActiveEnum.Fashion then
                        EquipSignboardDic[characterId].FashionIdDic[fashionId].FashIsAllActive = true
                        EquipSignboardDic[characterId].FashionIdDic[fashionId].EquipModelIndex = equipModelIndex
                    else
                        EquipSignboardDic[characterId].FashionIdDic[fashionId].FashIsAllActive = false

                        if not actionId or actionId == 0 then
                            EquipSignboardDic[characterId].FashionIdDic[fashionId].AllAction = true
                            EquipSignboardDic[characterId].FashionIdDic[fashionId].EquipModelIndex = equipModelIndex

                            if EquipSignboardDic[characterId].FashionIdDic[fashionId].ActionIdDic then
                                EquipSignboardDic[characterId].FashionIdDic[fashionId].ActionIdDic = nil
                                XLog.Error(StringFormat("EquipSignboard表CharacterId(%d)配置全部动作开启武器，会覆盖当前CharacterId的其它动作配置！Id:%d, 路径:%s", characterId, id, TABLE_EQUIP_SIGNBOARD_PATH))
                            end
                        else
                            EquipSignboardDic[characterId].FashionIdDic[fashionId].AllAction = false
                            EquipSignboardDic[characterId].FashionIdDic[fashionId].ActionIdDic = EquipSignboardDic[characterId].FashionIdDic[fashionId].ActionIdDic or {}
                            EquipSignboardDic[characterId].FashionIdDic[fashionId].ActionIdDic[actionId] = equipModelIndex
                        end
                    end
                end
            end
        end
    end

    return EquipSignboardDic
end

function XEquipConfig.GetEquipAnimControllerBySignboard(characterId, fashionId, actionId)
    if not characterId then
        return
    end

    local equipSignboardDic = GetEquipSignboardDic()
    local equipCharacterSignboard = equipSignboardDic[characterId]

    if not equipCharacterSignboard then
        return
    end

    if equipCharacterSignboard.ChaIsAllActive then
        return equipCharacterSignboard.EquipModelIndex
    end

    if equipCharacterSignboard.AllFashion then
        if equipCharacterSignboard.FashIsAllActive then
            return EquipSignboardDic[characterId].EquipModelIndex
        else
            if equipCharacterSignboard.AllAction then
                return EquipSignboardDic[characterId].EquipModelIndex
            else
                if not actionId then
                    return
                end

                return EquipSignboardDic[characterId].ActionIdDic[actionId]
            end
        end
    end

    if not fashionId then
        return
    end

    local equipFashionSignboard = equipCharacterSignboard.FashionIdDic[fashionId]

    if not equipFashionSignboard then
        return
    end

    if equipFashionSignboard.FashIsAllActive then
        return equipFashionSignboard.EquipModelIndex
    end

    if equipFashionSignboard.AllAction then
        return equipFashionSignboard.EquipModelIndex
    end

    if not actionId then
        return
    end

    local equipActionSignboard = equipFashionSignboard.ActionIdDic[actionId]

    if not equipActionSignboard then
        return
    end

    return equipActionSignboard
end

function XEquipConfig.CheckHasLoadEquipBySignboard(characterId, fashionId, actionId)
    return XEquipConfig.GetEquipAnimControllerBySignboard(characterId, fashionId, actionId) ~= nil
end
--endregion

------------武器超限相关 begin----------------

-- 获取武器的超限配置
function XEquipConfig.GetWeaponOverrunCfgsByTemplateId(templateId)
    local cfgs = WeaponOverrunDic[templateId]
    return cfgs
end

-- 获取武器超限ui配置
function XEquipConfig.GetWeaponDeregulateUICfg(templateId)
    return WeaponDeregulateUITemplate[templateId]
end

-- 获取武器超限意识绑定的配置表
function XEquipConfig.GetWeaponOverrunSuitCfgByTemplateId(templateId)
    for _, cfg in ipairs(WeaponOverrunDic[templateId] or {}) do
        if cfg.OverrunType == XEquipConfig.WeaponOverrunUnlockType.Suit then
            return cfg
        end
    end
    return nil
end

-- 装备是否可超限
function XEquipConfig.CanOverrunByTemplateId(templateId)
    local cfgs = WeaponOverrunDic[templateId]
    local canDeregulate = cfgs and #cfgs > 0
    return canDeregulate
end

-- 获取意识套装列表
-- isType0 = true 时，只获装备类型为0的意识套装，即不包括意识强化素材
function XEquipConfig.GetSuitIdListByCharacterType(charType, minQuality, isFilterType0, isOverrun)
    minQuality = minQuality or 0
    local suitIdList = {}
    for _, suit in pairs(EquipSuitTemplate) do
        local equipIds = SuitIdToEquipTemplateIdsDic[suit.Id]
        if equipIds and #equipIds > 0 then
            local equipId = equipIds[1]
            local equipCfg = XEquipConfig.GetEquipCfg(equipId)
            local isShow = equipCfg.Quality >= minQuality
                       and (charType == XEquipConfig.UserType.All or XEquipConfig.GetEquipCharacterType(equipId) == charType) 
                       and ((isFilterType0 and equipCfg.Type == 0) or not isFilterType0)
                       and ((isOverrun and equipCfg.OverrunNoShow ~= 1) or not isOverrun)
            if isShow then
                table.insert(suitIdList, suit.Id)
            end
        end
    end

    return suitIdList
end

-- 获取意识套装的品质
function XEquipConfig.GetSuitQuality(suitId)
    local equipIds = XEquipConfig.GetEquipTemplateIdsBySuitId(suitId)
    if equipIds and #equipIds > 0 then
        local equipCfg = XEquipConfig.GetEquipCfg(equipIds[1])
        return equipCfg.Quality
    end
    
    return 0
end

-- 获取意识套装的适配角色类型
function XEquipConfig.GetSuitCharacterType(suitId)
    local equipIds = XEquipConfig.GetEquipTemplateIdsBySuitId(suitId)
    if equipIds and #equipIds > 0 then
        local equipCfg = XEquipConfig.GetEquipCfg(equipIds[1])
        return equipCfg.CharacterType
    end
    
    return 0
end
------------武器超限相关 end----------------

function XEquipConfig.GetEquipAnimIsReset(modelId)
    if XTool.IsTableEmpty(EquipAnimResetDic) then
        return false
    end
    return EquipAnimResetDic[modelId] or false
end