---@class XBWPopupConfirmToggleData
local XBWPopupConfirmToggleData = XClass(nil, "XBWPopupConfirmToggleData")

function XBWPopupConfirmToggleData:Ctor()
    self.Text = ""
    self.Callback = false
    self.IsActive = true
end

function XBWPopupConfirmToggleData:InvokeToggle(isToggle)
    if self.Callback then
        self.Callback(isToggle)
    end
end

function XBWPopupConfirmToggleData:Init(text, callback, isActive)
    self.Text = text or ""
    self.Callback = callback
    if isActive ~= nil then
        self.IsActive = isActive
    end 
end

function XBWPopupConfirmToggleData:Clear()
    self.Text = ""
    self.Callback = false
    self.IsActive = true
end

return XBWPopupConfirmToggleData