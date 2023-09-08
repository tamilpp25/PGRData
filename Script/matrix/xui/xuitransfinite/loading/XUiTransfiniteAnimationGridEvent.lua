---@class XUiTransfiniteAnimationGridEvent
local XUiTransfiniteAnimationGridEvent = XClass(nil, "XUiTransfiniteAnimationGridEvent")

---@class EventBackgroundType
---@field Normal number
---@field Special number
local EventBackgroundType = enum({
    Normal = 1,  --普通背板
    Special = 2,  --特殊背板
})

function XUiTransfiniteAnimationGridEvent:Ctor(ui)
    self.Effect = nil
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

---@param event XTransfiniteEvent
function XUiTransfiniteAnimationGridEvent:Update(event)
    if event then
        self.Select.gameObject:SetActiveEx(true)
        self.Normal.gameObject:SetActiveEx(false)
        self.ImgBg.gameObject:SetActiveEx(true)
        self.RImgIconBuff1:SetRawImage(event:GetIcon())
        self.Name01.text = event:GetName()
        self.Text.text = event:GetDesc()
        -- self:ShowSpecialEffect(event:GetType() == EventBackgroundType.Special)
    else
        self.Select.gameObject:SetActiveEx(false)
        self.Normal.gameObject:SetActiveEx(true)
    end
end

function XUiTransfiniteAnimationGridEvent:ShowSpecialEffect(isSpecial)
    if not self.Effect then
        self.Effect = self.Transform:Find("Effect")
    end

    if self.Effect then
        self.Effect.gameObject:SetActiveEx(isSpecial)
    end
end

return XUiTransfiniteAnimationGridEvent
