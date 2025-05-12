local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiTaskActivity = require("XUi/XUiTask/XUiTaskActivity")

---@class XUiLuckyTenantTask : XUiTaskActivity
---@field _Control XLuckyTenantControl
local XUiLuckyTenantTask = XLuaUiManager.Register(XUiTaskActivity, "UiLuckyTenantTask")

function XUiLuckyTenantTask:InitAssets()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiLuckyTenantTask:GetTaskGroupIds()
    return self._Control:GetTaskGroupIds()
    --local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
    --return XLuckyTenantEnum.Task
end

function XUiLuckyTenantTask:GetActivityEndTime()
    return self._Control:GetActivityEndTime()
end

return XUiLuckyTenantTask