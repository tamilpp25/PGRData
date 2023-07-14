local tableInsert = table.insert
XSlotMachineConfigs = XSlotMachineConfigs or {}

local TABLE_SLOT_MACHINE_ACTIVITY_PATH = "Share/SlotMachines/SlotMachinesActivity.tab"
local TABLE_SLOT_MACHINE_PATH = "Share/SlotMachines/SlotMachines.tab"
local TABLE_SLOT_MACHINE_ICON_PATH = "Share/SlotMachines/SlotMachinesIcon.tab"
local TABLE_SLOT_MACHINE_RULES_PATH = "Share/SlotMachines/SlotMachinesRules.tab"

local SlotMachinesActivityTemplates = {}
local SlotMachinesTemplates = {}
local SlotMachinesIconTemplates = {}
local SlotMachinesRulesTemplates = {}

XSlotMachineConfigs.SlotMachineState = {
    Locked = 1,
    Running = 2,
    Finish = 3,
}

XSlotMachineConfigs.RewardTakeState = {
    NotFinish = 1,
    NotTook = 2,
    Took = 3,
}

XSlotMachineConfigs.TaskType = {
    Daily = 1,
    Cumulative = 2,
}

XSlotMachineConfigs.RulesPanelType = {
    Rules = 1,
    Research = 2,
}

XSlotMachineConfigs.ExchangeType = {
    Normal = 0,
    OnlyTask = 1,
}

function XSlotMachineConfigs.Init()
    SlotMachinesActivityTemplates = XTableManager.ReadByIntKey(TABLE_SLOT_MACHINE_ACTIVITY_PATH, XTable.XTableSlotMachinesActivity, "Id")
    SlotMachinesTemplates = XTableManager.ReadByIntKey(TABLE_SLOT_MACHINE_PATH, XTable.XTableSlotMachines, "Id")
    SlotMachinesIconTemplates = XTableManager.ReadByIntKey(TABLE_SLOT_MACHINE_ICON_PATH, XTable.XTableSlotMachinesIcon, "Id")
    SlotMachinesRulesTemplates = XTableManager.ReadByIntKey(TABLE_SLOT_MACHINE_RULES_PATH, XTable.XTableSlotMachinesRules, "Id")
end

function XSlotMachineConfigs.GetSlotMachinesActivityTemplate()
    if not SlotMachinesActivityTemplates then
        XLog.Error("XSlotMachineConfigs.GetSlotMachinesActivityTemplate Error, SlotMachinesActivityTemplates is nil")
    end

    return SlotMachinesActivityTemplates
end

function XSlotMachineConfigs.GetSlotMachinesActivityTemplateById(id)
    if not SlotMachinesActivityTemplates[id] then
        XLog.Error("XSlotMachineConfigs.GetSlotMachinesActivityTemplateById Error, Can't find Template by Id:"..id)
    end

    return SlotMachinesActivityTemplates[id]
end

function XSlotMachineConfigs.GetSlotMachinesTemplateById(id)
    if not SlotMachinesTemplates[id] then
        XLog.Error("XSlotMachineConfigs.GetSlotMachinesTemplateById Error, Can't find Template by Id:"..id)
    end

    return SlotMachinesTemplates[id]
end

function XSlotMachineConfigs.GetSlotMachinesIconTemplateById(id)
    if not SlotMachinesIconTemplates[id] then
        XLog.Error("XSlotMachineConfigs.GetSlotMachinesIconTemplateById Error, Can't find Template by Id:"..id)
    end

    return SlotMachinesIconTemplates[id]
end

function XSlotMachineConfigs.GetSlotMachinesRulesTemplateById(id)
    if not SlotMachinesRulesTemplates[id] then
        XLog.Error("XSlotMachineConfigs.GetSlotMachinesRulesTemplateById Error, Can't find Template by Id:"..id)
    end

    return SlotMachinesRulesTemplates[id]
end

function XSlotMachineConfigs.GetActivityStartTimeByActId(id)
    local activityTmp = XSlotMachineConfigs.GetSlotMachinesActivityTemplateById(id)
    if not activityTmp then
        return
    end

    return activityTmp.StartTimeStr, activityTmp.EndTimeStr
end

function XSlotMachineConfigs.GetIconImageById(iconId)
    local iconTmp = XSlotMachineConfigs.GetSlotMachinesIconTemplateById(iconId)
    if not iconTmp then
        return
    end

    return iconTmp.IconImage
end

function XSlotMachineConfigs.GetIconNameById(iconId)
    local iconTmp = XSlotMachineConfigs.GetSlotMachinesIconTemplateById(iconId)
    if not iconTmp then
        return
    end

    return iconTmp.IconName
end

function XSlotMachineConfigs.GetSlotMachinesItemExchangeRatio(actId)
    if not actId then
        return
    end

    local activityTmp = XSlotMachineConfigs.GetSlotMachinesActivityTemplateById(actId)
    if not activityTmp then
        return
    end

    return activityTmp.ExchangeRatio
end

function XSlotMachineConfigs.GetSlotMachinesItemExchangeType(actId)
    if not actId then
        return
    end

    local activityTmp = XSlotMachineConfigs.GetSlotMachinesActivityTemplateById(actId)
    if not activityTmp then
        return
    end
    if activityTmp.ExchangeType then
        return activityTmp.ExchangeType
    else
        return XSlotMachineConfigs.ExchangeType.Normal
    end
end