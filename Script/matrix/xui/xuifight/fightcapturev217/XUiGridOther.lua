---@class XUiGridOther 拍照后其他列表的格子
---@field RootUi XUiStickerOtherList
local XUiGridOther = XClass(nil, "XUiGridOther")

function XUiGridOther:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ToggleDof.onValueChanged:AddListener(handler(self, self.OnToggleValueChanged))
end

function XUiGridOther:Init(rootUi)
    self.RootUi = rootUi
end

--- 设置数据
---@param screenEffectId - CaptureV217ScreenEffect表的Id
function XUiGridOther:SetData(screenEffectId)
    self.ScreenEffectId = screenEffectId
    self.Text.text = self.RootUi.Parent._Control._Model:GetScreenEffectName(screenEffectId) or ""
    self:Refresh()
end

function XUiGridOther:Refresh()
    self.ToggleDof.isOn = self.RootUi.Parent._Control.UseScreenEffectId == self.ScreenEffectId
end

function XUiGridOther:ChangeToggle()
    self.ToggleDof.isOn = not self.ToggleDof.isOn
end

function XUiGridOther:OnToggleValueChanged(value)
    if self.RootUi.Parent._Control.UseScreenEffectId ~= self.ScreenEffectId and not value then
        return
    end
    
    self.RootUi.Parent._Control:SetUseScreenEffectId(value and self.ScreenEffectId or 0)
    self:Refresh()
    self.RootUi:Refresh(self)
end

return XUiGridOther