---@class XUiSpecialTrainGrid : XUiNode
local XUiSpecialTrainGrid = XClass(XUiNode, "XUiSpecialTrainGrid")

function XUiSpecialTrainGrid:Update(data)
    self.Bg:SetSprite(data.Image)
    self.Text.text = data.Desc1
    self.TxtCoreDescription.text = data.Desc2
end

return XUiSpecialTrainGrid