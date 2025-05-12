local XUiGrid3DOrder = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DOrder")

---@class XUiGrid3DPerform : XUiGrid3DOrder
---@field BtnClick XUiComponent.XUiButton
local XUiGrid3DPerform = XClass(XUiGrid3DOrder, "XUiGrid3DOrder")

function XUiGrid3DPerform:InitCb()
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

function XUiGrid3DPerform:OnBtnClick()
    local perform = self._Control:GetRunningPerform()
    if not perform or perform:IsFinish() then
        self:Hide()
        return
    end
    self._Control:OpenPerformUi(perform:GetPerformId())
end

function XUiGrid3DPerform:OnRefresh()
    local perform = self._Control:GetRunningPerform()
    if not perform or perform:IsFinish() then
        self:Hide()
        return
    end
    local finish = self._Control:CheckRunningPerformFinish()
    local isNotStart = perform:IsNotStart()
    local isOnGoing = perform:IsOnGoing()

    self.PanelComplete.gameObject:SetActiveEx(finish)
    self.PanelOnGoing.gameObject:SetActiveEx(isOnGoing and not finish)
    self.PanelNotStart.gameObject:SetActiveEx(isNotStart)
end

return XUiGrid3DPerform