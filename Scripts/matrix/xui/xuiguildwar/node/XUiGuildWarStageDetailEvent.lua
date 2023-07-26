---@class XUiGuildWarStageDetailEvent
local XUiGuildWarStageDetailEvent = XClass(nil, "XUiGuildWarStageDetailEvent")

function XUiGuildWarStageDetailEvent:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGuildWarStageDetailEvent:Update(event)
    self.Text.text = event.Description
    self.ImgIcon:SetRawImage(event.Icon)
    if self.TextName then
        self.TextName.text = event.Name
    end
end

return XUiGuildWarStageDetailEvent
