
local XUiFightWheelPickerSlotData = require("XUi/XUiFightWheelPicker/XUiFightWheelPickerSlotData")

---@class XUiFightWheelPickerSlot
---@field New fun(rootUi: XUiFightWheelPicker, gameObject: UnityEngine.GameObject) : XUiFightWheelPickerSlot
local XUiFightWheelPickerSlot = XClass(nil, "XUiFightWheelPickerSlot")

---@param rootUi XUiFightWheelPicker
---@param gameObject UnityEngine.GameObject
function XUiFightWheelPickerSlot:Ctor(rootUi, gameObject)
    self.RootUi = rootUi
    self.GameObject = gameObject
    self.Transform = gameObject.transform
    XTool.InitUiObject(self)

    self.DefaultData = XUiFightWheelPickerSlotData.Default()
    self.Data = self.DefaultData

    ---@type XUiComponent.XUiButton
    self.XUiButton = gameObject:GetComponent("XUiButton")
    self.XUiButton.ExitCheck = false
    self.EmptyObj = self.XUiButton.PressObj
    self.XUiButton.PressObj = nil

    XUiHelper.RegisterClickEvent(self, self.XUiButton, self.OnClick)
end

---直接点击UI
---@private
function XUiFightWheelPickerSlot:OnClick()
    local fight = CS.XFight.Instance
    if not fight then
        return
    end

    if self.Data.IsDisable or self.Data.IsEmpty then
        return
    end

    self.RootUi:UpdateOptionWithSlot(self)
    fight.InputControl:SimulateOnClick(self.Data.Key)              
end

---@param state UiButtonState
function XUiFightWheelPickerSlot:SetState(state)
    self.XUiButton:SetButtonState(state)
end

---@param data XUiFightWheelPickerSlotData
function XUiFightWheelPickerSlot:RefreshWithData(data)
    if data == nil then
        self.Data = self.DefaultData
    else
        self.Data = data
    end

    self.XUiButton:SetRawImageEx(self.Data.Icon)

    self.XUiButton.PressObj = self.EmptyObj
    if self.Data.IsDisable then
        self.XUiButton:SetButtonState(CS.UiButtonState.Disable)
    elseif self.Data.IsEmpty then
        self.XUiButton:SetButtonState(CS.UiButtonState.Press)
    else
        self.XUiButton:SetButtonState(CS.UiButtonState.Normal)
    end

    -- 这样做的原因是防止点击的时候触发Press状态导致样式修改
    self.XUiButton.PressObj = nil
end

function XUiFightWheelPickerSlot:GetXUiButton()
    return self.XUiButton
end

function XUiFightWheelPickerSlot:GetKey()
    return self.Data.Key
end

return XUiFightWheelPickerSlot