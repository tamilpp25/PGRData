XDailyDungeonConfigs = {}

local TABLE_DAILY_DROP_GROUP = "Client/Fuben/Daily/DailyDropGroup.tab"
local TABLE_DAILT_DUNGEON_RULES = "Share/Fuben/Daily/DailyDungeonRules.tab"
local TABLE_DAILY_DUNGEON_DATA = "Share/Fuben/Daily/DailyDungeonData.tab"
local TABLE_DAILY_SPECOAL_CONDITION = "Share/Fuben/Daily/DailySpecialCondition.tab"

local DailyDungeonRulesTemplates = {}
local DailyDungeonDataTemplates = {}
local DailySpecialConditionTemplates = {}
local DailyDropGroupTemplates = {}

function XDailyDungeonConfigs.Init()
    DailyDungeonRulesTemplates = XTableManager.ReadByIntKey(TABLE_DAILT_DUNGEON_RULES, XTable.XTableDailyDungeonRules, "Id")
    DailyDungeonDataTemplates = XTableManager.ReadByIntKey(TABLE_DAILY_DUNGEON_DATA, XTable.XTableDailyDungeonData, "Id")
    DailySpecialConditionTemplates = XTableManager.ReadByIntKey(TABLE_DAILY_SPECOAL_CONDITION, XTable.XTableDailySpecialCondition, "Id")
    DailyDropGroupTemplates = XTableManager.ReadByIntKey(TABLE_DAILY_DROP_GROUP, XTable.XTableDailyDropGroup, "Id")
end

function XDailyDungeonConfigs.GetDailyDungeonRulesList()
    return DailyDungeonRulesTemplates
end

function XDailyDungeonConfigs.GetDailyDungeonRulesById(id)
    return DailyDungeonRulesTemplates[id]
end

function XDailyDungeonConfigs.GetDailyDungeonDayOfWeek(Id)
    local tmpTab = {}
    for _, v in pairs(DailyDungeonRulesTemplates[Id].OpenDayOfWeek) do
        table.insert(tmpTab, v)
    end
    return tmpTab
end

function XDailyDungeonConfigs.GetDailyDungeonDataList()
    return DailyDungeonDataTemplates
end

function XDailyDungeonConfigs.GetDailyDungeonData(Id)
    return DailyDungeonDataTemplates[Id]
end

function XDailyDungeonConfigs.GetDailySpecialConditionList()
    return DailySpecialConditionTemplates
end

function XDailyDungeonConfigs.GetDailyDungeonIdByStageId(stageId)
    for _, v in pairs(DailyDungeonDataTemplates) do
        for _, v2 in pairs(v.StageId) do
            if v2 == stageId then
                return v.Id
            end
        end
    end
    return nil
end

function XDailyDungeonConfigs.GetDailyDropGroupList()
    return DailyDropGroupTemplates
end

function XDailyDungeonConfigs.GetFubenDailyShopId(id)
    local data = DailyDungeonDataTemplates[id]
    return data and data.ShopId
end