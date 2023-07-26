local TABLE_WORLDBOSS_ACTIVITY = "Share/Fuben/WorldBoss/WorldBossActivity.tab"
local TABLE_WORLDBOSS_ATTRIBUTE_AREA = "Share/Fuben/WorldBoss/WorldBossAttributeArea.tab"
local TABLE_WORLDBOSS_ATTRIBUTE_STAGE = "Share/Fuben/WorldBoss/WorldBossAttributeStage.tab"
local TABLE_WORLDBOSS_BOSS_AREA = "Share/Fuben/WorldBoss/WorldBossBossArea.tab"
local TABLE_WORLDBOSS_BOSS_SHOP = "Share/Fuben/WorldBoss/WorldBossBossShop.tab"
local TABLE_WORLDBOSS_BOSS_SHOP_DISCOUNT = "Share/Fuben/WorldBoss/WorldBossBossShopDiscount.tab"
local TABLE_WORLDBOSS_BOSS_STAGE = "Share/Fuben/WorldBoss/WorldBossBossStage.tab"
local TABLE_WORLDBOSS_BUFF = "Share/Fuben/WorldBoss/WorldBossBuff.tab"
local TABLE_WORLDBOSS_PHASESREWARD = "Share/Fuben/WorldBoss/WorldBossPhasesReward.tab"
local TABLE_WORLDBOSS_REPORT = "Share/Fuben/WorldBoss/WorldBossFightReport.tab"


local ActivityTemplates = {}
local AttributeAreaTemplates = {}
local AttributeStageTemplates = {}
local BossAreaTemplates = {}
local BossShopTemplates = {}
local BossShopDiscountTemplates = {}
local BossStageTemplates = {}
local BuffTemplates = {}
local ReportTemplates = {}
local PhasesRewardemplates = {}
local BossStageDic = {}

XWorldBossConfigs = XWorldBossConfigs or {}

XWorldBossConfigs.BuffType = {
    Buff = 1,
    Robot = 2
}

XWorldBossConfigs.AreaType = {
    Attribute = 1,
    Boss = 2
}

XWorldBossConfigs.ReportType = {
    System = 1,
    Player = 2
}

XWorldBossConfigs.DefaultTeam = {
    ["CaptainPos"] = 1,
    ["FirstFightPos"] = 1,
    ["TeamData"] = { 1021001, 0, 0 },
}

function XWorldBossConfigs.Init()
    ActivityTemplates = XTableManager.ReadByIntKey(TABLE_WORLDBOSS_ACTIVITY, XTable.XTableWorldBossActivity, "Id")
    AttributeAreaTemplates = XTableManager.ReadByIntKey(TABLE_WORLDBOSS_ATTRIBUTE_AREA, XTable.XTableWorldBossAttributeArea, "Id")
    AttributeStageTemplates = XTableManager.ReadByIntKey(TABLE_WORLDBOSS_ATTRIBUTE_STAGE, XTable.XTableWorldBossAttributeStage, "Id")
    BossAreaTemplates = XTableManager.ReadByIntKey(TABLE_WORLDBOSS_BOSS_AREA, XTable.XTableWorldBossBossArea, "Id")
    BossShopTemplates = XTableManager.ReadByIntKey(TABLE_WORLDBOSS_BOSS_SHOP, XTable.XTableWorldBossBossShop, "Id")
    BossShopDiscountTemplates = XTableManager.ReadByIntKey(TABLE_WORLDBOSS_BOSS_SHOP_DISCOUNT, XTable.XTableWorldBossBossShopDiscount, "Id")
    BossStageTemplates = XTableManager.ReadByIntKey(TABLE_WORLDBOSS_BOSS_STAGE, XTable.XTableWorldBossBossStage, "Id")
    BuffTemplates = XTableManager.ReadByIntKey(TABLE_WORLDBOSS_BUFF, XTable.XTableWorldBossBuff, "Id")
    PhasesRewardemplates = XTableManager.ReadByIntKey(TABLE_WORLDBOSS_PHASESREWARD, XTable.XTableWorldBossPhasesReward, "Id")
    ReportTemplates = XTableManager.ReadByIntKey(TABLE_WORLDBOSS_REPORT, XTable.XTableWorldBossFightReport, "Id")
end

function XWorldBossConfigs.GetActivityTemplates()
    return ActivityTemplates
end

function XWorldBossConfigs.GetAttributeAreaTemplates()
    return AttributeAreaTemplates
end

function XWorldBossConfigs.GetAttributeStageTemplates()
    return AttributeStageTemplates
end

function XWorldBossConfigs.GetBossAreaTemplates()
    return BossAreaTemplates
end

function XWorldBossConfigs.GetBossShopTemplates()
    return BossShopTemplates
end

function XWorldBossConfigs.GetBossShopDiscountTemplates()
    return BossShopDiscountTemplates
end

function XWorldBossConfigs.GetBossStageTemplates()
    return BossStageTemplates
end

function XWorldBossConfigs.GetBuffTemplates()
    return BuffTemplates
end

function XWorldBossConfigs.GetPhasesRewardemplates()
    return PhasesRewardemplates
end

function XWorldBossConfigs.GetActivityTemplatesById(id)
    if not ActivityTemplates[id] then
        XLog.Error("Share/Fuben/WorldBoss/WorldBossActivity.tab Id = " .. id .. " Is Null")
    end
    return ActivityTemplates[id]
end

function XWorldBossConfigs.GetAttributeAreaTemplatesById(id)
    if not AttributeAreaTemplates[id] then
        XLog.Error("Share/Fuben/WorldBoss/WorldBossAttributeArea.tab Id = " .. id .. " Is Null")
    end
    return AttributeAreaTemplates[id]
end

function XWorldBossConfigs.GetAttributeStageTemplatesById(id)
    if not AttributeStageTemplates[id] then
        XLog.Error("Share/Fuben/WorldBoss/WorldBossAttributeStage.tab Id = " .. id .. " Is Null")
    end
    return AttributeStageTemplates[id]
end

function XWorldBossConfigs.GetBossAreaTemplatesById(id)
    if not BossAreaTemplates[id] then
        XLog.Error("Share/Fuben/WorldBoss/WorldBossBossArea.tab Id = " .. id .. " Is Null")
    end
    return BossAreaTemplates[id]
end

function XWorldBossConfigs.GetBossShopTemplatesById(id)
    if not BossShopTemplates[id] then
        XLog.Error("Share/Fuben/WorldBoss/WorldBossBossShop.tab Id = " .. id .. " Is Null")
    end
    return BossShopTemplates[id]
end

function XWorldBossConfigs.GetBossShopDiscountTemplatesById(id)
    if not BossShopDiscountTemplates[id] then
        XLog.Error("Share/Fuben/WorldBoss/WorldBossBossShopDiscount.tab Id = " .. id .. " Is Null")
    end
    return BossShopDiscountTemplates[id]
end

function XWorldBossConfigs.GetBossStageTemplatesById(id)
    if not BossStageTemplates[id] then
        XLog.Error("Share/Fuben/WorldBoss/WorldBossBossStage.tab Id = " .. id .. " Is Null")
    end
    return BossStageTemplates[id]
end

function XWorldBossConfigs.GetBuffTemplatesById(id)
    if not BuffTemplates[id] then
        XLog.Error("Share/Fuben/WorldBoss/WorldBossBuff.tab Id = " .. id .. " Is Null")
    end
    return BuffTemplates[id]
end

function XWorldBossConfigs.GetPhasesRewardemplatesById(id)
    if not PhasesRewardemplates[id] then
        XLog.Error("Share/Fuben/WorldBoss/WorldBossPhasesReward.tab Id = " .. id .. " Is Null")
    end
    return PhasesRewardemplates[id]
end

function XWorldBossConfigs.GetReportTemplatesById(id)
    if not ReportTemplates[id] then
        XLog.Error("Share/Fuben/WorldBoss/WorldBossFightReport.tab Id = " .. id .. " Is Null")
    end
    return ReportTemplates[id]
end

function XWorldBossConfigs.GetActivityLastTemplate()
    local templat = {}
    for _, activityTemplate in pairs(ActivityTemplates) do
        templat = activityTemplate
    end
    return templat
end
