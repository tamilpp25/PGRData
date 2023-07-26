---@class XPlanelBuildRecycleTog
local XPlanelBuildRecycleTog = XClass(nil, "XPlanelBuildRecycleTog")

function XPlanelBuildRecycleTog:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)

    self:Refresh()
    self:AddBtnClickListener()
end

function XPlanelBuildRecycleTog:Refresh()
    local isQuickRecycle = XDataCenter.PlanetManager.GetReformQuickRecycleMode()
    self.BtnSelectBg.gameObject:SetActiveEx(not isQuickRecycle)
    self.Checkmark.gameObject:SetActiveEx(isQuickRecycle)
end

--region 按钮绑定
function XPlanelBuildRecycleTog:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XPlanelBuildRecycleTog:OnBtnClick()
    local isQuickRecycle = XDataCenter.PlanetManager.GetReformQuickRecycleMode()
    XDataCenter.PlanetManager.SetReformQuickRecycleMode(not isQuickRecycle)
    self:Refresh()
end
--endregion

return XPlanelBuildRecycleTog