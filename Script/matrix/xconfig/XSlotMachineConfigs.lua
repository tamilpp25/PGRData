-- 老虎机
XSlotMachineConfigs = XConfigCenter.CreateTableConfig(XSlotMachineConfigs, "XSlotMachineConfigs", "SlotMachines")

--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============

XSlotMachineConfigs.TableKey = enum({
    SlotMachinesActivity = {}, -- 活动表
    SlotMachines = {},
    SlotMachinesIcon = {},
    SlotMachinesRules = {},
})

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

function XSlotMachineConfigs.Init()
end

function XSlotMachineConfigs.GetSlotMachinesActivityTemplate()
    return XSlotMachineConfigs.GetAllConfigs(XSlotMachineConfigs.TableKey.SlotMachinesActivity)
end

function XSlotMachineConfigs.GetSlotMachinesActivityTemplateById(id)
    return XSlotMachineConfigs.GetCfgByIdKey(XSlotMachineConfigs.TableKey.SlotMachinesActivity, id)
end

function XSlotMachineConfigs.GetSlotMachinesTemplateById(id)
    return XSlotMachineConfigs.GetCfgByIdKey(XSlotMachineConfigs.TableKey.SlotMachines, id)
end

function XSlotMachineConfigs.GetSlotMachinesIconTemplateById(id)
    return XSlotMachineConfigs.GetCfgByIdKey(XSlotMachineConfigs.TableKey.SlotMachinesIcon, id)
end

function XSlotMachineConfigs.GetSlotMachinesRulesTemplateById(id)
    return XSlotMachineConfigs.GetCfgByIdKey(XSlotMachineConfigs.TableKey.SlotMachinesRules, id)
end

function XSlotMachineConfigs.GetActivityTimeIdByActId(id)
    local activityTmp = XSlotMachineConfigs.GetSlotMachinesActivityTemplateById(id)
    if not activityTmp then
        return
    end

    return activityTmp.TimeId
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

function XSlotMachineConfigs.GetSlotMachinesIdsByActivityId(activityId)
    local activityTmp = XSlotMachineConfigs.GetSlotMachinesActivityTemplateById(activityId)
    if not activityTmp then
        return {}
    end
    return activityTmp.SlotMachinesIds or {}
end