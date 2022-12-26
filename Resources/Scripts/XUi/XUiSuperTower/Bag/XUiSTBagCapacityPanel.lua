local ChildPanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--===========================
--超级爬塔背包容量面板
--===========================
local XUiSTBagCapacityPanel = XClass(ChildPanel, "XUiSTBagCapacityPanel")

function XUiSTBagCapacityPanel:InitPanel()
    
end

function XUiSTBagCapacityPanel:Refresh()
    self.TxtNowCapacity.text = self.RootUi.BagManager:GetCurrentCapacity()
    self.TxtMaxCapacity.text = "/" .. self.RootUi.BagManager:GetMaxCapacity()
end

function XUiSTBagCapacityPanel:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_ST_PLUGIN_REFRESH, self.Refresh, self)
end

function XUiSTBagCapacityPanel:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_ST_PLUGIN_REFRESH, self.Refresh, self)
end

return XUiSTBagCapacityPanel