---@class XUiTransfiniteAnimationGridEvent
local XUiTransfiniteAnimationGridEvent = XClass(nil, "XUiTransfiniteAnimationGridEvent")

function XUiTransfiniteAnimationGridEvent:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

---@param event XTransfiniteEvent
function XUiTransfiniteAnimationGridEvent:Update(event)
    if event then
        self.Select.gameObject:SetActiveEx(true)
        self.Normal.gameObject:SetActiveEx(false)
        self.RImgIconBuff1:SetRawImage(event:GetIcon())
        self.Name01.text = event:GetName()
        self.Text.text = event:GetDesc()
    else
        self.Select.gameObject:SetActiveEx(false)
        self.Normal.gameObject:SetActiveEx(true)
    end
end

return XUiTransfiniteAnimationGridEvent
