---@class XSuperTowerShopManager
local XSuperTowerShopManager = XClass(nil, "XSuperTowerShopManager")

function XSuperTowerShopManager:Ctor()
    self.RefreshCd = 0
    self.RefreshCount = 0
    self.ManualRefreshCount = 0
    self.MallId = 101
    self.BuyList = {}
    -- self:RegisterNotify()
end

function XSuperTowerShopManager:UpdateShopData(data)
    if not data then
        return
    end
    self.MallId = data.MallId   --商店id
    self.RefreshCd = data.MallRefreshCd --刷新cd
    self.RefreshCount = data.MallRefreshCount   --免费刷新次数
    self.ManualRefreshCount = data.ManualRefreshCount   --手动刷新次数
    self.BuyList = data.BuyList --商品列表
    CS.XGameEventManager.Instance:Notify(XEventId.EVENT_ST_SHOP_REFRESH)
end

function XSuperTowerShopManager:GetRefreshCount()
    return self.RefreshCount
end

function XSuperTowerShopManager:GetRefreshCd()
    return self.RefreshCd
end

function XSuperTowerShopManager:GetManualRefreshCount()
    return self.ManualRefreshCount
end

function XSuperTowerShopManager:GetBuyList()
    return self.BuyList
end

function XSuperTowerShopManager:GetMallId()
    return self.MallId
end

function XSuperTowerShopManager:GetSpendItemCountInfo()
    local spendCount = self:GetRefreshInfo(self.ManualRefreshCount)
    local mallConfig = XSuperTowerConfigs.GetMallConfig(self.MallId)
    local itemCount = XDataCenter.ItemManager.GetCount(mallConfig.ManualRefreshSpendItemId)
    return spendCount,itemCount
end

function XSuperTowerShopManager:GetRefreshInfo(refreshCount)
    local mallConfig = XSuperTowerConfigs.GetMallConfig(self.MallId)
    if not mallConfig then
        XLog.Error("XSuperTowerShopManager:GetRefreshInfo 配置不存在 shopId:", self.MallId)
        return
    end
    refreshCount = refreshCount + 1
    local manualRefreshCountList = mallConfig.ManualRefreshSpendItemCount
    refreshCount = XMath.Clamp(refreshCount, 1, #manualRefreshCountList)
    return manualRefreshCountList[refreshCount]
end

function XSuperTowerShopManager:GetMallItemInfo(id)
    local config
    for i = 1, #self.BuyList do
        if self.BuyList[i].Id == id then
            config = self.BuyList[i]
        end
    end
    return config
end

function XSuperTowerShopManager:RequestBugPlugin(listIndex, count, cb)
    local req = {
        Index = listIndex,
        Count = count
    }

    XNetwork.Call("StBuyPluginRequest", req, function(rsp)
        if rsp.Code ~= XCode.Success then
            XUiManager.TipCode(rsp.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

function XSuperTowerShopManager:RequestRefreshMall(cb)
    XNetwork.Call("StRefreshMallRequest", nil, function(rsp)
        if rsp.Code ~= XCode.Success then
            XUiManager.TipCode(rsp.Code)
            return
        end
        self.RefreshCd = rsp.MallRefreshCd --刷新cd
        self.RefreshCount = rsp.FreeRefreshCount   --免费刷新次数
        self.ManualRefreshCount = rsp.ManualRefreshCount   --手动刷新次数
        self.BuyList = rsp.PluginId --商品列表
        if cb then
            cb()
        end
    end)
end

-- function XSuperTowerShopManager:RegisterNotify()
--     XRpc.NotifySuperTowerMallRefreshData = function(data)
--         self.RefreshCd = data.MallRefreshCd
--         self.RefreshCount = data.MallRefreshCount
--         self.ManualRefreshCount = data.ManualRefreshCount
--         CS.XGameEventManager.Instance:Notify(XEventId.EVENT_ST_SHOP_REFRESH)
--     end

--     XRpc.NotifySuperTowerMallData = function(data)
--         self:UpdateShopData(data.MallInfo)
--     end
-- end

function XSuperTowerShopManager:OnrMallRefreshData(data)
    self.RefreshCd = data.MallRefreshCd
    self.RefreshCount = data.MallRefreshCount
    self.ManualRefreshCount = data.ManualRefreshCount
    CS.XGameEventManager.Instance:Notify(XEventId.EVENT_ST_SHOP_REFRESH)
end

return XSuperTowerShopManager

