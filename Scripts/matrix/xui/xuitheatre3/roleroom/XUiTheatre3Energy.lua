---@class XUiTheatre3Energy : XUiNode 能量条
---@field _Control XTheatre3Control
local XUiTheatre3Energy = XClass(XUiNode, "XUiTheatre3Energy")

function XUiTheatre3Energy:OnStart()

end

function XUiTheatre3Energy:SetNum(cur, total)
    self.TxtEnergyNum.text = XUiHelper.GetText("Theatre3EnergyNum", cur, total)
    local residue = total - cur
    for i = 1, 12 do
        local go = self["Energy" .. i]
        if i <= total then
            local uiObject = {}
            XTool.InitUiObjectByUi(uiObject, go)
            go.gameObject:SetActiveEx(true)
            uiObject.ImgEnergyOn.gameObject:SetActiveEx(i <= residue)
            uiObject.ImgEnergyOff.gameObject:SetActiveEx(i > residue)
        else
            go.gameObject:SetActiveEx(false)
        end
    end
    if residue then
        self.TxtTips.text = XUiHelper.GetText("Theatre3EnergyUnused", self._Control:GetEnergyUnusedDesc(residue))
    else
        self.TxtTips.text = ""
    end
end

return XUiTheatre3Energy