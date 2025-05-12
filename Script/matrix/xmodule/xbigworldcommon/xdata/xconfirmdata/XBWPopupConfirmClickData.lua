---@class XBWPopupConfirmClickData
local XBWPopupConfirmClickData = XClass(nil, "XBWPopupConfirmClickData")

function XBWPopupConfirmClickData:Ctor(text, callback, isActive)
    self:Init(text, callback, isActive)
end

function XBWPopupConfirmClickData:InvokeClick()
    if self.Callback then
        self.Callback()
    end
end

function XBWPopupConfirmClickData:Init(text, callback, isActive)
    self.Text = text or ""
    self.Callback = callback
    if isActive ~= nil then
        self.IsActive = isActive
    end
end

function XBWPopupConfirmClickData:Clear()
    self.Text = ""
    self.Callback = false
    self.IsActive = true
end

return XBWPopupConfirmClickData
