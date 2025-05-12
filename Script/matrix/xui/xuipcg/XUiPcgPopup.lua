---@class XUiPcgPopup : XLuaUi
---@field private _Control XPcgControl
local XUiPcgPopup = XLuaUiManager.Register(XLuaUi, "UiPcgPopup")

function XUiPcgPopup:OnAwake()
    self:RegisterUiEvents()
end

function XUiPcgPopup:OnStart(content, cb)
    self.Content = content
    self.Cb = cb
end

function XUiPcgPopup:OnEnable()
    self:Refresh()
end

function XUiPcgPopup:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnCloseBg, self.OnBtnCancelClick)
end

function XUiPcgPopup:OnBtnConfirmClick()
    if self.Cb then
        self.Cb()
    end
    self:Close()
end

function XUiPcgPopup:OnBtnCancelClick()
    self:Close()
end

-- 刷新界面
function XUiPcgPopup:Refresh()
    self.TxtContent.text = self.Content
end

return XUiPcgPopup
