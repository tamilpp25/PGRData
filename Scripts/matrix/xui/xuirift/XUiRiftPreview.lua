local XUiRiftPreview = XLuaUiManager.Register(XLuaUi, "UiRiftPreview")
local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

function XUiRiftPreview:OnAwake()
    self.GridRewardList = {}
    self.GridPluginList = {}

    self:InitButton()
end

function XUiRiftPreview:InitButton()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnPreviewClose, self.Close)
end

function XUiRiftPreview:OnStart(xFightLayer)
    self.XFightLayer = xFightLayer
end

function XUiRiftPreview:OnEnable()
    self.TxtKm.text = self.XFightLayer:GetId().."Km"
    -- 刷新奖励信息
    local rewards = {}
    local rewardId = self.XFightLayer:GetConfig().RewardId
    if rewardId > 0 then
        rewards = XRewardManager.GetRewardList(rewardId) 
    end
    for i, grid in pairs(self.GridRewardList) do
        grid.GameObject:SetActiveEx(false)
    end
    for i, item in ipairs(rewards) do
        local grid =  self.GridRewardList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.Grid256, self.Grid256.parent)
            grid = XUiGridCommon.New(self, ui)
            self.GridRewardList[i] = grid
        end
        grid:Refresh(item)
        grid:SetReceived(self.XFightLayer:CheckHasPassed())
        grid.GameObject:SetActive(true)
    end
    
    -- 刷新插件信息
    for i, grid in pairs(self.GridPluginList) do
        grid.GameObject:SetActiveEx(false)
    end
    local pluginIds = self.XFightLayer.ClientConfig.PluginList
    for i, pluginId in ipairs(pluginIds) do
        local grid =  self.GridPluginList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridRiftPlugin, self.GridRiftPlugin.parent)
            grid = XUiRiftPluginGrid.New(ui)
            self.GridPluginList[i] = grid
        end
        local xPlugin = XDataCenter.RiftManager.GetPlugin(pluginId)
        grid:Refresh(xPlugin)
        grid:Init(function ()
            XLuaUiManager.Open("UiRiftPluginShopTips", {PluginId = pluginId})
        end)
        grid.GameObject:SetActive(true)
    end
end


return XUiRiftPreview