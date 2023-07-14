local XUiPanelOtherSet = require("XUi/XUiSet/XUiPanelOtherSet")
local XUiPanelOtherSetPc = XClass(XUiPanelOtherSet, "XUiPanelOtherSetPc")
local XInputManager = CS.XInputManager

function XUiPanelOtherSetPc:Ctor()
    self._IsShowFPS = CS.XInputManager.GetFPSActive()
    self._IsShowJoystick = CS.XInputManager.GetJoystickActive()
    self._IsShowFightButton = CS.XInputManager.GetKeyCodeTipActive()
    self._IsShowSystemButton = false
    self._IsDirtyPc = false
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

function XUiPanelOtherSetPc:SaveChange()
    XUiPanelOtherSetPc.Super.SaveChange(self)
    self._IsDirtyPc = false
    CS.XInputManager.SetFPSActive(self._IsShowFPS)
    CS.XInputManager.SetJoystickActive(self._IsShowJoystick)
    CS.XInputManager.SetKeyCodeTipActive(self._IsShowFightButton)
end

function XUiPanelOtherSetPc:CheckDataIsChange()
    return self._IsDirtyPc or XUiPanelOtherSetPc.Super.CheckDataIsChange(self)
end

function XUiPanelOtherSetPc:ResetToDefault()
    XUiPanelOtherSetPc.Super.ResetToDefault(self)
    self._IsShowFPS = CS.XInputManager.DEFAULT_KEYCODE_TIP_ACTIVE == 1
    self._IsShowJoystick = CS.XInputManager.DEFAULT_JOYSTICK_ACTIVE == 1
    self._IsShowFightButton = CS.XInputManager.DEFAULT_FPS_ACTIVE == 1
    self._IsShowSystemButton = false
    self.TogFPS.isOn = self._IsShowFPS
    self.TogJoystick.isOn = self._IsShowJoystick
    self.TogFightButton.isOn = self._IsShowFightButton
    self.TogSystemButton.isOn = self._IsShowSystemButton
    CS.XInputManager.SetFPSActive(self._IsShowFPS)
    CS.XInputManager.SetJoystickActive(self._IsShowJoystick)
    CS.XInputManager.SetKeyCodeTipActive(self._IsShowFightButton)
end

return XUiPanelOtherSetPc