local XUiGrid3DBase = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DBase")

---@class XUiGrid3DOrder : XUiGrid3DBase
---@field BtnClick XUiComponent.XUiButton
local XUiGrid3DOrder = XClass(XUiGrid3DBase, "XUiGrid3DOrder")

function XUiGrid3DOrder:InitUi()
    self.TipAnimation = self.Transform:Find("Animation/TipsEnable")
    if self.TipAnimation then
        self.TipAnimation.gameObject:SetActiveEx(false)
    end
end

function XUiGrid3DOrder:InitCb()
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

function XUiGrid3DOrder:OnBtnClick()
    local perform = self._Control:GetPerform(self.PerformId)
    if not perform or perform:IsFinish() then
        self:Hide()
        return
    end
    self._Control:OpenPerformUi(perform:GetPerformId())
end

function XUiGrid3DOrder:OnRefresh(performId)
    self.PerformId = performId
    local perform = self._Control:GetPerform(performId)
    if not perform or perform:IsFinish() then
        self:Hide()
        return
    end
    local finish = perform:CheckPerformFinish()
    local isNotStart = perform:IsNotStart()
    local isOnGoing = perform:IsOnGoing()
    
    self.PanelComplete.gameObject:SetActiveEx(finish)
    self.PanelOnGoing.gameObject:SetActiveEx(isOnGoing and not finish)
    self.PanelNotStart.gameObject:SetActiveEx(isNotStart)
end

function XUiGrid3DOrder:Hide()
    self.PerformId = nil
    XUiGrid3DBase.Hide(self)
end

function XUiGrid3DOrder:GetPerformId()
    return self.PerformId
end

function XUiGrid3DOrder:ShowTip()
    if not self.TipAnimation then
        return
    end
    if not self:IsShow() then
        return
    end
    self.TipAnimation.gameObject:SetActiveEx(false)
    self.TipAnimation.gameObject:SetActiveEx(true)
end

return XUiGrid3DOrder