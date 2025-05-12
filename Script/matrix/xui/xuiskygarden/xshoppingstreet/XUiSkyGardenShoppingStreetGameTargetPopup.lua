---@class XUiSkyGardenShoppingStreetGameTargetPopup : XLuaUi
local XUiSkyGardenShoppingStreetGameTargetPopup = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetGameTargetPopup")
local XUiSkyGardenShoppingStreetTargetGridTarget = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetTargetGridTarget")

--region 生命周期
function XUiSkyGardenShoppingStreetGameTargetPopup:OnAwake()
    self._TargetList = {}
    self._IdList = {}
end

function XUiSkyGardenShoppingStreetGameTargetPopup:OnGetLuaEvents()
    return {
        XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_FINISH_TASK_REFRESH,
    }
end

function XUiSkyGardenShoppingStreetGameTargetPopup:OnNotify(event, idList)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_FINISH_TASK_REFRESH then
        for _, id in pairs(idList) do
            self._IdList[id] = true
        end
    end
end

function XUiSkyGardenShoppingStreetGameTargetPopup:OnStart(idList)
    self:_RefreshFinishTask(idList)
end

function XUiSkyGardenShoppingStreetGameTargetPopup:_RefreshFinishTask(idList)
    XTool.UpdateDynamicItem(self._TargetList, idList, self.GridTarget, XUiSkyGardenShoppingStreetTargetGridTarget, self)
    for i = 1, #self._TargetList do
        self._TargetList[i]:SetFinish(function(index)
            self._TargetList[index]:Close()
        end)
    end
    self:AddNextCheckTimer()
end

function XUiSkyGardenShoppingStreetGameTargetPopup:RemoveNextCheckTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = false
    end
end

function XUiSkyGardenShoppingStreetGameTargetPopup:AddNextCheckTimer()
    self:RemoveNextCheckTimer()
    self.Timer = XScheduleManager.ScheduleOnce(function()
        self:CheckTaskFinishIds()
    end, 3000)
end

function XUiSkyGardenShoppingStreetGameTargetPopup:CheckTaskFinishIds()
    local idList = {}
    for id, _ in ipairs(self._IdList) do
        table.insert(idList, id)
    end
    self._IdList = {}
    if #idList > 0 then
        self:_RefreshFinishTask(idList)
    else
        self:Close()
    end
end
--endregion

return XUiSkyGardenShoppingStreetGameTargetPopup
