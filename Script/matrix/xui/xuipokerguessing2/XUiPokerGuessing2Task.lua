local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiTaskActivity = require("XUi/XUiTask/XUiTaskActivity")

---@class XUiPokerGuessing2Task : XUiTaskActivity
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2Task = XLuaUiManager.Register(XUiTaskActivity, "UiPokerGuessing2Task")

function XUiPokerGuessing2Task:InitAssets()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiPokerGuessing2Task:GetTaskGroupIds()
    return self._Control:GetTaskGroupIds()
end

function XUiPokerGuessing2Task:GetActivityEndTime()
    return self._Control:GetActivityEndTime()
end

return XUiPokerGuessing2Task