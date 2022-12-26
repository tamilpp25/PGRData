XSpecialShopConfigs = XSpecialShopConfigs or {}

XSpecialShopConfigs.MAX_COUNT = 5  -- 商店每一行最大的商品数量

local TABLE_SPECIAL_SHOP = "Client/SpecialShop/SpecialShop.tab"
local SpecialShopConfig = {}

function XSpecialShopConfigs.Init()
    SpecialShopConfig = XTableManager.ReadByIntKey(TABLE_SPECIAL_SHOP, XTable.XTableSpecialShop, "Id")
end


---------------------------------------------------SpecialShop.tab数据读取---------------------------------------------------------

---
--- 内部接口获取配置
--- 'cfgId'默认为1
---@overload fun():table
---@return table
local function GetSpecialShopCfg(cfgId)
    local paramId = cfgId or 1
    local cfg = SpecialShopConfig[paramId]
    if cfg == nil then
        XLog.ErrorTableDataNotFound("XSpecialShopConfigs.GetSpecialShopCfg",
                "商店信息",
                TABLE_SPECIAL_SHOP,
                "Id",
                tostring(paramId))
        return {}
    end
    return cfg
end

---
--- 获取商店Id
--- 'cfgId'默认为1
---@overload fun():number
---@return number
function XSpecialShopConfigs.GetShopId(cfgId)
    local cfg = GetSpecialShopCfg(cfgId)
    if not cfg.ShopId then
        XLog.ErrorTableDataNotFound("XSpecialShopConfigs.GetShopId",
                "商店Id",
                TABLE_SPECIAL_SHOP,
                "Id",
                tostring(cfgId))
        return 0
    end
    return cfg.ShopId
end

---
--- 获取商店TimeId
--- 'cfgId'默认为1
---@overload fun():number
---@return number
function XSpecialShopConfigs.GetTimeId(cfgId)
    local cfg = GetSpecialShopCfg(cfgId)
    if not cfg.TimeId then
        XLog.ErrorTableDataNotFound("XSpecialShopConfigs.GetTimeId",
                "商店持续时间",
                TABLE_SPECIAL_SHOP,
                "Id",
                tostring(cfgId))
        return 0
    end
    return cfg.TimeId
end

---
--- 获取商店持续时间（开启与关闭时间）的时间戳
--- 'cfgId'默认为1
---@overload fun():number,number
---@return number 开启时间
---@return number 结束时间
function XSpecialShopConfigs.GetDurationTimeStamp(cfgId)
    local cfg = GetSpecialShopCfg(cfgId)
    if not cfg.TimeId then
        XLog.ErrorTableDataNotFound("XSpecialShopConfigs.GetDurationTime",
                "商店持续时间",
                TABLE_SPECIAL_SHOP,
                "Id",
                tostring(cfgId))
        return 0, 0
    end
    return XFunctionManager.GetTimeByTimeId(cfg.TimeId)
end

---
--- 获取商店持续时间（开启与关闭时间）的字符串
--- 'cfgId'默认为1
---@overload fun():number,number
---@return string 开启时间
---@return string 结束时间
function XSpecialShopConfigs.GetDurationTimeStr(cfgId)
    local cfg = GetSpecialShopCfg(cfgId)
    if not cfg.TimeId then
        XLog.ErrorTableDataNotFound("XSpecialShopConfigs.GetDurationTime",
                "商店持续时间",
                TABLE_SPECIAL_SHOP,
                "Id",
                tostring(cfgId))
        return "0", "0"
    end

    local startTime, endTime = XFunctionManager.GetTimeByTimeId(cfg.TimeId)
    return XTime.TimestampToGameDateTimeString(startTime, "MM/dd hh:mm"), XTime.TimestampToGameDateTimeString(endTime, "MM/dd hh:mm")
end