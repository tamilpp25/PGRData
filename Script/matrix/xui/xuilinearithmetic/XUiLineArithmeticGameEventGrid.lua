---@class XUiLineArithmeticGameEventGrid : XUiNode
---@field _Control XLineArithmeticControl
local XUiLineArithmeticGameEventGrid = XClass(XUiNode, "XUiLineArithmeticGameEventGrid")

---@param data XLineArithmeticControlDataEventDesc
function XUiLineArithmeticGameEventGrid:Update(data)
    --self.ImgBg
    self.TxtNum.gameObject:SetActiveEx(false)
    self.RImgType:SetRawImage(data.Icon)
    self.TxtName.text = data.Name
    self.TxtDetail.text = data.Desc
end

return XUiLineArithmeticGameEventGrid