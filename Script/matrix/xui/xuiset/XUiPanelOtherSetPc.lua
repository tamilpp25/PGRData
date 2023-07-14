local XUiPanelOtherSet = require("XUi/XUiSet/XUiPanelOtherSet")
local XUiPanelOtherSetPc = XClass(XUiPanelOtherSet, "XUiPanelOtherSetPc")
local XInputManager = CS.XInputManager
local XCursorHelper = CS.XPc.XCursorHelper

function XUiPanelOtherSetPc:Ctor()
    self._IsShowFPS = XInputManager.GetFPSActive()
    self._IsShowJoystick = XInputManager.GetJoystickActive()
    self._IsShowFightButton = XInputManager.GetKeyCodeTipActive(CS.XOperationType.Fight)
    self._IsShowSystemButton = false
    self._IsDirtyPc = false
    self._CursorSizeIndex = XCursorHelper.CursorSizeIndex
    self:InitPc()
end

function XUiPanelOtherSetPc:InitPc()
    self.TogFPS.isOn = self._IsShowFPS
    self.TogJoystick.isOn = self._IsShowJoystick
    self.TogFightButton.isOn = self._IsShowFightButton
    self.TogSystemButton.isOn = self._IsShowSystemButton
    self.TogFPS.onValueChanged:AddListener(handler(self, self.OnTogFPSValueChanged))
    self.TogJoystick.onValueChanged:AddListener(handler(self, self.OnTogJoystickValueChanged))
    self.TogFightButton.onValueChanged:AddListener(handler(self, self.OnTogFightButtonValueChanged))
    self.TogSystemButton.onValueChanged:AddListener(handler(self, self.OnTogSystemButtonChanged))
    self:InitCursorToggles()
end

function XUiPanelOtherSetPc:OnTogFPSValueChanged(value)
    if self._IsShowFPS ~= value then
        self._IsShowFPS = value
        self._IsDirtyPc = true
    end
end

function XUiPanelOtherSetPc:OnTogJoystickValueChanged(value)
    if self._IsShowJoystick ~= value then
        self._IsShowJoystick = value
        self._IsDirtyPc = true
    end
end

function XUiPanelOtherSetPc:OnTogFightButtonValueChanged(value)
    if self._IsShowFightButton ~= value then
        self._IsShowFightButton = value
        self._IsDirtyPc = true
    end
end

function XUiPanelOtherSetPc:OnTogSystemButtonChanged(value)
    if self._IsShowSystemButton ~= value then
        self._IsShowSystemButton = value
        self._IsDirtyPc = true
    end
end

function XUiPanelOtherSetPc:InitCursorToggles()
    self:UpdateCursorToggles()

    self.TogCursorSize_0.onValueChanged:AddListener(function() 
        if self._RevertingCursorSize then
            return
        end
        if self.TogCursorSize_0.isOn then
            self._IsDirtyPc = true
            self._CursorSizeIndex = 0
        end
    end)

    self.TogCursorSize_1.onValueChanged:AddListener(function()
        if self._RevertingCursorSize then
            return
        end
        if self.TogCursorSize_1.isOn then
            self._IsDirtyPc = true
            self._CursorSizeIndex = 1
        end
    end)

    self.TogCursorSize_2.onValueChanged:AddListener(function()
        if self._RevertingCursorSize then
            return
        end
        if self.TogCursorSize_2.isOn then
            self._IsDirtyPc = true
            self._CursorSizeIndex = 2 
        end
    end)
end

function XUiPanelOtherSetPc:UpdateCursorToggles()
    self.TogCursorSize_0.isOn = self._CursorSizeIndex == 0
    self.TogCursorSize_1.isOn = self._CursorSizeIndex == 1
    self.TogCursorSize_2.isOn = self._CursorSizeIndex == 2
end

function XUiPanelOtherSetPc:RevertCursorSetting()
    self._RevertingCursorSize = true
    self._CursorSizeIndex = 1
    self:UpdateCursorToggles()
    self._RevertingCursorSize = false
end

function XUiPanelOtherSetPc:SaveChange()
    XUiPanelOtherSetPc.Super.SaveChange(self)
    self._IsDirtyPc = false
    XInputManager.SetFPSActive(self._IsShowFPS)
    XInputManager.SetJoystickActive(self._IsShowJoystick)
    XInputManager.SetFightKeyCodeTipActive(self._IsShowFightButton)
    XCursorHelper.CursorSizeIndex = self._CursorSizeIndex
end

function XUiPanelOtherSetPc:CheckDataIsChange()
    return self._IsDirtyPc or XUiPanelOtherSetPc.Super.CheckDataIsChange(self)
end

function XUiPanelOtherSetPc:ResetToDefault()
    XUiPanelOtherSetPc.Super.ResetToDefault(self)
    self._IsShowFPS = XInputManager.DEFAULT_KEYCODE_TIP_ACTIVE == 1
    self._IsShowJoystick = XInputManager.DEFAULT_JOYSTICK_ACTIVE == 1
    self._IsShowFightButton = XInputManager.DEFAULT_FPS_ACTIVE == 1
    self._IsShowSystemButton = false
    self.TogFPS.isOn = self._IsShowFPS
    self.TogJoystick.isOn = self._IsShowJoystick
    self.TogFightButton.isOn = self._IsShowFightButton
    self.TogSystemButton.isOn = self._IsShowSystemButton
    self:RevertCursorSetting()
    XInputManager.SetFPSActive(self._IsShowFPS)
    XInputManager.SetJoystickActive(self._IsShowJoystick)
    XInputManager.SetFightKeyCodeTipActive(self._IsShowFightButton)
    XCursorHelper.CursorSizeIndex = self._CursorSizeIndex
end

return XUiPanelOtherSetPc