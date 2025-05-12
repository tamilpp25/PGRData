---@class XUiLineArithmeticGameStarGrid : XUiNode
---@field _Control XLineArithmeticControl
local XUiLineArithmeticGameStarGrid = XClass(XUiNode, "XUiLineArithmeticGameStarGrid")

---@param data XLineArithmeticControlDataStarDesc
function XUiLineArithmeticGameStarGrid:Update(data)
    if data.IsFinish then
        self.Normal.gameObject:SetActiveEx(false)
        self.Select.gameObject:SetActiveEx(true)
        self.TxtTargetOn.text = data.Desc
        if self.TxtTargetTl2 then
            self.TxtTargetTl2.text = XUiHelper.GetText("LineArithmeticTarget", data.Index)
        end
    else
        self.Normal.gameObject:SetActiveEx(true)
        self.Select.gameObject:SetActiveEx(false)
        self.TxtTargetOff.text = data.Desc
        if self.TxtTargetTl1 then
            self.TxtTargetTl1.text = XUiHelper.GetText("LineArithmeticTarget", data.Index)
        end
    end
end

return XUiLineArithmeticGameStarGrid