XFubenUrgentEventConfig = XFubenUrgentEventConfig or {}

local UrgentEventCfg = {}

local TABLE_URGENT_EVENT = "Share/Fuben/UrgentEvent/UrgentEvent.tab"

function XFubenUrgentEventConfig.Init()
    UrgentEventCfg = XTableManager.ReadByIntKey(TABLE_URGENT_EVENT, XTable.XTableUrgentEvent, "Id")
end
function XFubenUrgentEventConfig.GetUrgentEventCfg()
    return UrgentEventCfg
end

function XFubenUrgentEventConfig.GetUrgentEventCfgById(urgentId)
    if UrgentEventCfg[urgentId] then
        return UrgentEventCfg[urgentId]
    end
end