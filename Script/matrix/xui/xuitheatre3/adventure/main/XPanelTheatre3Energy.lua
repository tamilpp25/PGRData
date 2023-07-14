---@class XPanelTheatre3Energy : XUiNode
---@field _Control XTheatre3Control
local XPanelTheatre3Energy = XClass(XUiNode, "XPanelTheatre3Energy")

function XPanelTheatre3Energy:OnStart()
    for i = 1, XEnumConst.THEATRE3.MaxEnergyCount do
        local name = "Energy"..i
        if not self[name] then
            self[name] = XUiHelper.TryGetComponent(self.Transform, "ListEnergy/"..name)
        end
    end
end

function XPanelTheatre3Energy:Refresh()
    local curEnergy, maxEnergy = self._Control:GetCurEnergy()
    local residue = maxEnergy - curEnergy
    local name
    for i = 1, maxEnergy do
        name = "Energy"..i
        if self[name] then
            self[name].gameObject:SetActiveEx(true)
            local ImgEnergyOn = XUiHelper.TryGetComponent(self[name].transform, "ImgEnergyOn")
            local ImgEnergyOff = XUiHelper.TryGetComponent(self[name].transform, "ImgEnergyOff")
            if ImgEnergyOn then
                ImgEnergyOn.gameObject:SetActiveEx(i <= residue)
            end
            if ImgEnergyOff then
                ImgEnergyOff.gameObject:SetActiveEx(i > residue)
            end
        end
    end
    for i = maxEnergy + 1, XEnumConst.THEATRE3.MaxEnergyCount do
        name = "Energy"..i
        if self[name] then
            self[name].gameObject:SetActiveEx(false)
        end
    end
    self.TxtEnergyNum.text = XUiHelper.GetText("Theatre3EnergyNum", residue, maxEnergy)
    if self.TxtTips then
        if XTool.IsNumberValid(residue) then
            self.TxtTips.text = XUiHelper.GetText("Theatre3EnergyUnused", self._Control:GetEnergyUnusedDesc(residue))
        else
            self.TxtTips.text = ""
        end
    end
end

return XPanelTheatre3Energy