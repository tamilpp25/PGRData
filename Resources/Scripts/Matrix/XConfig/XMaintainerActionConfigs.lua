
XMaintainerActionConfigs = XMaintainerActionConfigs or {}

local TABLE_ACTIONCFG = "Share/Fuben/MaintainerAction/MaintainerActionConfig.tab"
local TABLE_STAGE_LEVEL = "Share/Fuben/MaintainerAction/MaintainerActionLevel.tab"
local TABLE_EVENT = "Share/Fuben/MaintainerAction/MaintainerActionEvent.tab"

local tableSort = table.sort

local MaintainerActionTemplates = {}
local MaintainerActionLevelTemplates = {}
local MaintainerActionEventTemplates = {}

local MaintainerActionRecordInfoDic = {}

XMaintainerActionConfigs.NodeType = {
    UnKnow = 0,
    Start = 1,
    Fight = 2,
    Box = 3,
    None = 4,
    Forward = 5,
    FallBack = 6,
    CardChange = 7,
    DirectionChange = 8,
    ActionPoint = 9,
    SimulationFight = 10,
    Warehouse = 11,
    Explore = 12,
    Mentor = 13,
}

XMaintainerActionConfigs.EventType = {
    Fight = 2,
}

XMaintainerActionConfigs.NodeState = {
    Normal = 1,
    OnRoute = 2,
    Target = 3,
}

XMaintainerActionConfigs.CardState = {
    Normal = 1,
    Select = 2,
    Disable = 3,
} 

XMaintainerActionConfigs.MessageType = {
    DayUpdate = 1,
    WeekUpdate = 2,
    FightComplete = 3,
    EventComplete = 4,
    MentorComplete = 5,
}

XMaintainerActionConfigs.RecordType = {
    PlayMove = 1,
    NodeEvent = 2,
    FubenWin = 3,
}

XMaintainerActionConfigs.TipType = {
    FightComplete = 1,
    EventComplete = 2,
    MentorComplete = 3,
}

XMaintainerActionConfigs.MonterNodeStatus = {
    NotActive = 0,
    ActiveSelf = 1,
    ActiveOther = 2,
    Finish = 3,
}

function XMaintainerActionConfigs.Init()
    MaintainerActionTemplates = XTableManager.ReadByIntKey(TABLE_ACTIONCFG, XTable.XTableMaintainerActionConfig, "Id")
    MaintainerActionLevelTemplates = XTableManager.ReadByIntKey(TABLE_STAGE_LEVEL, XTable.XTableMaintainerActionLevel, "Level")
    MaintainerActionEventTemplates = XTableManager.ReadByIntKey(TABLE_EVENT, XTable.XTableMaintainerActionEvent, "Id")
end

function XMaintainerActionConfigs.CreateRecordInfoDic()
    for _,record in pairs(MaintainerActionRecordTemplates)do
        MaintainerActionRecordInfoDic = MaintainerActionRecordInfoDic or {}
        MaintainerActionRecordInfoDic[record.GroupType] = MaintainerActionRecordInfoDic[record.GroupType] or {}
        MaintainerActionRecordInfoDic[record.GroupType][record.SubType] = record
    end
end

function XMaintainerActionConfigs.GetMaintainerActionTemplates()
    local defaultId = XMaintainerActionConfigs.GetDefaultId()
    return MaintainerActionTemplates[defaultId]
end

function XMaintainerActionConfigs.GetDefaultId()
    local defaultId = 0
    local spareId = 0
    local nowTime = XTime.GetServerNowTimestamp()
    local miniEndTime
    local MaxBeginTime
    for id,cfg in pairs(MaintainerActionTemplates) do
        local beginTime, endTime = XFunctionManager.GetTimeByTimeId(cfg.TimeId)
        if endTime > nowTime then
            if miniEndTime == nil or miniEndTime == 0 or endTime < miniEndTime then
                defaultId = id
                miniEndTime = endTime
            end
        else
            if endTime == 0 then
                if miniEndTime == nil then
                    defaultId = id
                    miniEndTime = endTime
                end
            end
        end
        
        if MaxBeginTime == nil or beginTime > MaxBeginTime then
            spareId = id
            MaxBeginTime = beginTime
        end
    end
    
    defaultId = defaultId == 0 and spareId or defaultId
    
    return defaultId
end

function XMaintainerActionConfigs.GetMaintainerActionLevelTemplates()
    return MaintainerActionLevelTemplates
end

function XMaintainerActionConfigs.GetMaintainerActionEventTemplates()
    return MaintainerActionEventTemplates
end

function XMaintainerActionConfigs.GetMaintainerActionRecordInfoByType(GroupType,SubType)
    return MaintainerActionRecordInfoDic and 
    MaintainerActionRecordInfoDic[GroupType] and 
    MaintainerActionRecordInfoDic[GroupType][SubType]
end

function XMaintainerActionConfigs.GetMaintainerActionTemplateById(id)
    if not MaintainerActionTemplates[id] then
        XLog.Error("Share/Fuben/MaintainerAction/MaintainerActionConfig.tab Id = " .. id .. " Is Null")
    end
    return MaintainerActionTemplates[id]
end

function XMaintainerActionConfigs.GetMaintainerActionEventTemplateById(id)
    if not MaintainerActionEventTemplates[id] then
        XLog.Error("Share/Fuben/MaintainerAction/MaintainerActionEvent.tab Id = " .. id .. " Is Null")
    end
    return MaintainerActionEventTemplates[id]
end

function XMaintainerActionConfigs.IsFightEvent(id)
    if not MaintainerActionEventTemplates[id] then
        XLog.Error("Share/Fuben/MaintainerAction/MaintainerActionEvent.tab Id = " .. id .. " Is Null")
    end
    return MaintainerActionEventTemplates[id].Id == XMaintainerActionConfigs.EventType.Fight
end


