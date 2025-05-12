---@class XUiSkyGardenShoppingStreetToastEventReward : XLuaUi
---@field TxtDetail UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetToastEventReward = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetToastEventReward")

local XUiSkyGardenShoppingStreetBuffGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuffGrid")
local TIP_MSG_SHOW_TIME = 3000

--region 生命周期
function XUiSkyGardenShoppingStreetToastEventReward:OnStart()
    self._BuffUi = XUiSkyGardenShoppingStreetBuffGrid.New(self.UiSkyGardenShoppingStreetGridBuff, self)
    
    local buffData = self._Control:PopGetShowBuff()
    self:_ShowGetInfo(buffData)
end

function XUiSkyGardenShoppingStreetToastEventReward:_ShowGetInfo(buffData)
    self._BuffUi:Update(buffData)
    local buffCfg = self._Control:GetBuffConfigById(buffData.BuffId)
    self.TxtName.text = buffCfg.Name
    self:_AddCloseTimer()
end

function XUiSkyGardenShoppingStreetToastEventReward:_AddCloseTimer()
    self:_RemoveCloseTimer()
    self._CheckCloseTimer = XScheduleManager.ScheduleOnce(function()
        self:CheckClose()
    end, TIP_MSG_SHOW_TIME)
end

function XUiSkyGardenShoppingStreetToastEventReward:_RemoveCloseTimer()
    if not self._CheckCloseTimer then return end
    XScheduleManager.UnSchedule(self._CheckCloseTimer)
    self._CheckCloseTimer = false
end

function XUiSkyGardenShoppingStreetToastEventReward:CheckClose()
    local buffData = self._Control:PopGetShowBuff()
    if not buffData then
        self:Close()
    else
        self:_ShowGetInfo(buffData)
    end
end

function XUiSkyGardenShoppingStreetToastEventReward:OnDestroy()
    self:_RemoveCloseTimer()
end
--endregion

return XUiSkyGardenShoppingStreetToastEventReward
