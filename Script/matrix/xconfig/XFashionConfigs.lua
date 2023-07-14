XFashionConfigs = XFashionConfigs or {}

local TABLE_FASHION_SERIES = "Client/Fashion/FashionSeries.tab"
local FashionSeriesConfig = {}

--涂装头像类型
XFashionConfigs.HeadPortraitType = {
    Default = 0, --默认
    Liberation = 1, --终解
    Fashion = 2, --涂装头像
}

function XFashionConfigs.Init()
    FashionSeriesConfig = XTableManager.ReadByIntKey(TABLE_FASHION_SERIES, XTable.XTableFashionSeries, "Id")
end


---------------------------------------------------FashionSeries.tab数据读取---------------------------------------------------------
local function GetFashionSeriesConfig(id)
    local cfg = FashionSeriesConfig[id]
    if cfg == nil then
        XLog.ErrorTableDataNotFound("XFashionConfigs.GetFashionSeriesConfig",
        "涂装系列",
        TABLE_FASHION_SERIES,
        "Id",
        tostring(id))
        return {}
    end
    return cfg
end

---
--- 获取涂装系列名称
function XFashionConfigs.GetSeriesName(id)
    local cfg = GetFashionSeriesConfig(id)
    if not cfg.Name then
        XLog.ErrorTableDataNotFound("XFashionConfigs.GetSeriesName",
        "涂装名称",
        TABLE_FASHION_SERIES,
        "Id",
        tostring(id))
        return ""
    end
    return cfg.Name
end