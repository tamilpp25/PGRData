---@class XUiSpecialTrainGrid
local XUiSpecialTrainGrid = XClass(nil, "XUiSpecialTrainGrid")

function XUiSpecialTrainGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiSpecialTrainGrid:Update(data)
    self.Bg:SetSprite(data.Image)
    self.Text.text = data.Desc1
    self.TxtCoreDescription.text = data.Desc2
end

return XUiSpecialTrainGrid