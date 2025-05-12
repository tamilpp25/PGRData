---@class XUiSkyGardenShoppingStreetToastNormal : XLuaUi
---@field TxtDetail UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetToastNormal = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetToastNormal")
local TIP_MSG_SHOW_TIME = 3000

--region 生命周期
function XUiSkyGardenShoppingStreetToastNormal:OnStart(params)
    self.TxtDetail.text = params--.Tips
    
    self.Timer = XScheduleManager.ScheduleOnce(function()
        self:Close()
    end, TIP_MSG_SHOW_TIME)
end

function XUiSkyGardenShoppingStreetToastNormal:OnDestroy()
    XScheduleManager.UnSchedule(self.Timer)
end
--endregion

return XUiSkyGardenShoppingStreetToastNormal
