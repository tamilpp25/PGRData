local XBWPopupConfirmClickData = require("XModule/XBigWorldCommon/XData/XConfirmData/XBWPopupConfirmClickData")
local XBWPopupConfirmToggleData = require("XModule/XBigWorldCommon/XData/XConfirmData/XBWPopupConfirmToggleData")

---@class XBWPopupConfirmData
local XBWPopupConfirmData = XClass(nil, "XBWPopupConfirmData")

function XBWPopupConfirmData:Ctor()
    self.Key = 0
    self.Title = ""
    self.Tips = ""
    self.IsNotify = false

    ---@type XBWPopupConfirmClickData
    self.SureClickData = XBWPopupConfirmClickData.New()
    ---@type XBWPopupConfirmClickData
    self.CancelClickData = XBWPopupConfirmClickData.New()
    ---@type XBWPopupConfirmClickData
    self.CloseClickData = XBWPopupConfirmClickData.New()
    ---@type XBWPopupConfirmToggleData
    self.ToggleData = XBWPopupConfirmToggleData.New()
end

function XBWPopupConfirmData:IsShowSureClick()
    return self.SureClickData.IsActive
end

function XBWPopupConfirmData:IsShowCancelClick()
    return self.CancelClickData.IsActive
end

function XBWPopupConfirmData:IsShowCloseClick()
    return self.CloseClickData.IsActive
end

function XBWPopupConfirmData:IsShowToggle()
    return self.ToggleData.IsActive
end

---@return XBWPopupConfirmData
function XBWPopupConfirmData:InitKey(key)
    self.Key = key

    return self
end

---@return XBWPopupConfirmData
function XBWPopupConfirmData:InitInfo(title, tips, isNotify)
    self.Title = title
    self.Tips = tips
    self.IsNotify = isNotify or false

    return self
end

---@return XBWPopupConfirmData
function XBWPopupConfirmData:InitSureClick(text, callback, isActive)
    self.SureClickData:Init(text, callback, isActive)

    return self
end

---@return XBWPopupConfirmData
function XBWPopupConfirmData:InitSureActive(isActive)
    self.SureClickData.IsActive = isActive

    return self
end

---@return XBWPopupConfirmData
function XBWPopupConfirmData:InitCancelClick(text, callback, isActive)
    self.CancelClickData:Init(text, callback, isActive)
    
    return self
end

---@return XBWPopupConfirmData
function XBWPopupConfirmData:InitCancelActive(isActive)
    self.CancelClickData.IsActive = isActive

    return self
end

---@return XBWPopupConfirmData
function XBWPopupConfirmData:InitCloseClick(text, callback, isActive)
    self.CloseClickData:Init(text, callback, isActive)
    
    return self
end

---@return XBWPopupConfirmData
function XBWPopupConfirmData:InitCloseActive(isActive)
    self.CloseClickData.IsActive = isActive

    return self
end

---@return XBWPopupConfirmData
function XBWPopupConfirmData:InitCancelAndCloseClick(text, callback, isActive)
    self:InitCancelClick(text, callback, isActive)
    self:InitCloseClick(text, callback, isActive)

    return self
end

---@return XBWPopupConfirmData
function XBWPopupConfirmData:InitToggle(text, callback, isActive)
    self.ToggleData:Init(text, callback, isActive)

    return self
end

---@return XBWPopupConfirmData
function XBWPopupConfirmData:InitToggleActive(isActive)
    self.ToggleData.IsActive = isActive

    return self
end

function XBWPopupConfirmData:InvokeSureClick()
    self.SureClickData:InvokeClick()
end

function XBWPopupConfirmData:InvokeCancelClick()
    self.CancelClickData:InvokeClick()
end

function XBWPopupConfirmData:InvokeCloseClick()
    self.CloseClickData:InvokeClick()
end

function XBWPopupConfirmData:InvokeToggle(isToggle)
    self.ToggleData:InvokeToggle(isToggle)
end

function XBWPopupConfirmData:GetValidTitle()
    if not string.IsNilOrEmpty(self.Title) then
        return self.Title
    end

    return XMVCA.XBigWorldService:GetText("CommmonTipsTitle")
end

function XBWPopupConfirmData:GetSureClickText()
    return self.SureClickData.Text
end

function XBWPopupConfirmData:GetCancelClickText()
    return self.CancelClickData.Text
end

function XBWPopupConfirmData:GetToggleText()
    return self.ToggleData.Text
end

function XBWPopupConfirmData:Clear()
    self.Key = 0
    self.Title = false
    self.Tips = false
    self.IsNotify = false

    self.SureClickData:Clear()
    self.CancelClickData:Clear()
    self.CloseClickData:Clear()
    self.ToggleData:Clear()
end

return XBWPopupConfirmData
