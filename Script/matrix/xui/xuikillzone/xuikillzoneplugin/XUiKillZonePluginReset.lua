local CsXTextManagerGetText = CsXTextManagerGetText

local XUiKillZonePluginReset = XLuaUiManager.Register(XLuaUi, "UiKillZonePluginReset")

function XUiKillZonePluginReset:OnAwake()
    self:AutoAddListener()
end

function XUiKillZonePluginReset:OnStart(pluginIds)
    self.PluginIds = pluginIds
    self.CoinGrids = {}
end

function XUiKillZonePluginReset:OnEnable()
    self:UpdateView()
end

function XUiKillZonePluginReset:UpdateView()
    local pluginIds = self.PluginIds
    local pluginNum = #pluginIds

    local desc = ""
    if pluginNum > 1 then
        desc = CsXTextManagerGetText("KillZoneResetPlguinsTips", pluginNum)
    else
        local pluginId = pluginIds[1]
        local name = XKillZoneConfigs.GetPluginName(pluginId)
        local level = XDataCenter.KillZoneManager.GetPluginLevel(pluginId)
        desc = CsXTextManagerGetText("KillZoneResetPlguinTips", name, level)
    end
    self.TxtDesc.text = desc

    local itemId, itemCount = XDataCenter.KillZoneManager.GetPluginsResetCost(pluginIds)
    local icon = XItemConfigs.GetItemIconById(itemId)
    self.RImgCost:SetRawImage(icon)
    self.TxtCost.text = itemCount

    local obtainList = XDataCenter.KillZoneManager.GetPluginsResetObtainList(pluginIds)
    for index, item in ipairs(obtainList) do
        local grid = self.CoinGrids[index]
        if not grid then
            local ui = index == 1 and self.GridCoin or CS.UnityEngine.Object.Instantiate(self.GridCoin, self.PanelCoin)
            grid = XUiGridCommon.New(self, ui)
            self.CoinGrids[index] = grid
        end

        grid:Refresh(item)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #obtainList + 1, #self.CoinGrids do
        self.CoinGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiKillZonePluginReset:AutoAddListener()
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
    self.BtnCancel.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end

function XUiKillZonePluginReset:OnClickBtnConfirm()
    local pluginIds = self.PluginIds

    local callFunc = function()
        XDataCenter.KillZoneManager.KillZoneResetRequest(pluginIds, function(rewardGoods)
            if not XTool.IsTableEmpty(rewardGoods) then
                XUiManager.OpenUiObtain(rewardGoods)
            end
        end)
        self:Close()
    end

    local itemId, itemCount = XDataCenter.KillZoneManager.GetPluginsResetCost(pluginIds)
    if XDataCenter.ItemManager.DoNotEnoughBuyAsset(itemId, itemCount, 1, callFunc, "KillZonePlguinResetCostLack") then
        callFunc()
    end
end