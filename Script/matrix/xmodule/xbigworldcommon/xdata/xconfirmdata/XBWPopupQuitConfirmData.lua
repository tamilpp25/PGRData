local XBWPopupConfirmClickData = require("XModule/XBigWorldCommon/XData/XConfirmData/XBWPopupConfirmClickData")

---@class XBWPopupQuitConfirmData
local XBWPopupQuitConfirmData = XClass(nil, "XBWPopupQuitConfirmData")

function XBWPopupQuitConfirmData:Ctor()
    self.Title = ""
    self.Tips = ""
    self.IsNotify = false

    ---@type XBWPopupConfirmClickData
    self.SureClickData = XBWPopupConfirmClickData.New()
    ---@type XBWPopupConfirmClickData
    self.CancelClickData = XBWPopupConfirmClickData.New()
    ---@type XBWPopupConfirmClickData
    self.CloseClickData = XBWPopupConfirmClickData.New()
end

---@return XBWPopupQuitConfirmData
function XBWPopupQuitConfirmData:InitInfo(title, tips, isNotify)
    self.Title = title
    self.Tips = tips
    self.IsNotify = isNotify or false

    return self
end

---@return XBWPopupQuitConfirmData
function XBWPopupQuitConfirmData:InitSureClick(text, callback)
    self.SureClickData:Init(text, callback, true)

    return self
end

---@return XBWPopupQuitConfirmData
function XBWPopupQuitConfirmData:InitCancelClick(text, callback)
    self.CancelClickData:Init(text, callback, true)

    return self
end

---@return XBWPopupQuitConfirmData
function XBWPopupQuitConfirmData:InitCloseClick(text, callback)
    self.CloseClickData:Init(text, callback, true)

    return self
end

---@return XBWPopupQuitConfirmData
function XBWPopupQuitConfirmData:InitCancelAndCloseClick(text, callback)
    self:InitCancelClick(text, callback)
    self:InitCloseClick(text, callback)

    return self
end

function XBWPopupQuitConfirmData:InvokeSureClick()
    self.SureClickData:InvokeClick()
end

function XBWPopupQuitConfirmData:InvokeCancelClick()
    self.CancelClickData:InvokeClick()
end

function XBWPopupQuitConfirmData:InvokeCloseClick()
    self.CloseClickData:InvokeClick()
end

function XBWPopupQuitConfirmData:GetValidTitle()
    if not string.IsNilOrEmpty(self.Title) then
        return self.Title
    end

    return XMVCA.XBigWorldService:GetText("CommmonTipsTitle")
end

function XBWPopupQuitConfirmData:GetSureClickText()
    return self.SureClickData.Text
end

function XBWPopupQuitConfirmData:GetCancelClickText()
    return self.CancelClickData.Text
end

function XBWPopupQuitConfirmData:Clear()
    self.Title = ""
    self.Tips = ""
    self.IsNotify = false

    self.SureClickData:Clear()
    self.CancelClickData:Clear()
    self.CloseClickData:Clear()
end

return XBWPopupQuitConfirmData
