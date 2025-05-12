XReportConfigs = XReportConfigs or {}

local TABLE_REPORT_PATH = "Share/Report/ReportTag.tab"
local TABLE_REPORT_ENTRY_PATH = "Share/Report/ReportEntry.tab"

local ReportCfg = {}
local ReportEntryCfg = {}

local ReportTagIdToChildTagIdList = {}

--举报入口类型，对应ReportEntry表的Id
XReportConfigs.EnterType = {
    Chat = 1,       --聊天频道
    Guild = 2,      --公会信息
    Player = 3,     --个人信息
    Friend = 4,     --好友私聊频道
    DlcMultiplayer = 5,     --Dlc多人联机
}

--页签级别
XReportConfigs.TagLevel = {
    One = 1,
    Two = 2,
    Three = 3,
}

--举报内容类型
XReportConfigs.ContentType = {
    Name = 1,                   --名字
    PlayerIntroduction = 2,     --玩家简介
    GuildOuterIntroduction = 3, --公会对外简介
    GuildInsideIntroduction = 4,    --公会对内简介
}

local InitReportTagIdToChildTagIdList = function()
    local parentId
    for _, v in pairs(ReportCfg) do
        parentId = v.ParentId
        if XTool.IsNumberValid(parentId) then
            if not ReportTagIdToChildTagIdList[parentId] then
                ReportTagIdToChildTagIdList[parentId] = {}
            end
            table.insert(ReportTagIdToChildTagIdList[parentId], v.Id)
        end
    end

    for _, idList in pairs(ReportTagIdToChildTagIdList) do
        table.sort(idList, function(a, b)
            local orderPriorityA = XReportConfigs.GetReportOrderPriority(a)
            local orderPriorityB = XReportConfigs.GetReportOrderPriority(b)
            if orderPriorityA ~= orderPriorityB then
                return orderPriorityA > orderPriorityB
            end
            return a < b
        end)
    end
end

function XReportConfigs.Init()
    ReportCfg = XTableManager.ReadByIntKey(TABLE_REPORT_PATH, XTable.XTableReportTag, "Id")
    ReportEntryCfg = XTableManager.ReadByIntKey(TABLE_REPORT_ENTRY_PATH, XTable.XTableReportEntry, "Id")

    InitReportTagIdToChildTagIdList()
end

function XReportConfigs.GetReportCfg()
    return ReportCfg
end

local GetReportConfig = function(id)
    local config = ReportCfg[id]
    if not config then
        XLog.ErrorTableDataNotFound("XReportConfigs.GetReportConfig", "ReportCfg", TABLE_REPORT_PATH, "Id", id)
        return
    end
    return config
end

function XReportConfigs.GetReportName(id)
    local config = GetReportConfig(id)
    return config.Name or ""
end

function XReportConfigs.GetReportParentId(id)
    local config = GetReportConfig(id)
    return config.ParentId
end

function XReportConfigs.GetReportSelectPriority(id)
    local config = GetReportConfig(id)
    return config.SelectPriority
end

function XReportConfigs.GetReportOrderPriority(id)
    local config = GetReportConfig(id)
    return config.OrderPriority
end

function XReportConfigs.GetReportTagIdToChildTagIdList(reportTagId)
    return ReportTagIdToChildTagIdList[reportTagId] or {}
end

function XReportConfigs.GetReportContentType(id)
    local config = GetReportConfig(id)
    return config.ContentType
end

local GetReportEntryConfig = function(id)
    local config = ReportEntryCfg[id]
    if not config then
        XLog.ErrorTableDataNotFound("XReportConfigs.GetReportEntryConfig", "ReportEntryCfg", TABLE_REPORT_ENTRY_PATH, "Id", id)
        return
    end
    return config
end

function XReportConfigs.GetReportEntryName(id)
    local config = GetReportEntryConfig(id)
    return config.Name
end

function XReportConfigs.GetReportEntryTagIds(id)
    local config = GetReportEntryConfig(id)
    local tagIds = XTool.Clone(config.TagIds)
    table.sort(tagIds, function(a, b)
        local orderPriorityA = XReportConfigs.GetReportOrderPriority(a)
        local orderPriorityB = XReportConfigs.GetReportOrderPriority(b)
        if orderPriorityA ~= orderPriorityB then
            return orderPriorityA > orderPriorityB
        end
        return a < b
    end)
    return tagIds
end

function XReportConfigs.GetReportEntryTagLevel(id)
    local config = GetReportEntryConfig(id)
    return config.TagLevel
end

function XReportConfigs.GetReportEntryTitle(id)
    local config = GetReportEntryConfig(id)
    return config.Title
end

function XReportConfigs.IsShowReportChat(id)
    local config = GetReportEntryConfig(id)
    return XTool.IsNumberValid(config.IsShowReportChat)
end