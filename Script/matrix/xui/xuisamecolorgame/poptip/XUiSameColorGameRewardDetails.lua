local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class UiSameColorGameRewardDetails:XLuaUi
local UiSameColorGameRewardDetails = XLuaUiManager.Register(XLuaUi, "UiSameColorGameRewardDetails")

function UiSameColorGameRewardDetails:OnAwake()
    self:RegisterUiEvents()
    self.ItemList = {}
    self.PanelItemInfo.gameObject:SetActiveEx(false)
end

function UiSameColorGameRewardDetails:OnStart(rewardGoodsList)
    self.RewardGoodsList = rewardGoodsList
    self:Refresh()
end

function UiSameColorGameRewardDetails:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnBg, self.Close)
end

function UiSameColorGameRewardDetails:Refresh()
    local rewardDataList = XRewardManager.MergeAndSortRewardGoodsList(self.RewardGoodsList)
    XUiHelper.CreateTemplates(self, self.ItemList, rewardDataList, XUiGridCommon.New, self.PanelItemInfo, self.PanelItemInfo.parent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
end
