local XInputManager = CS.XInputManager
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local XUiBtnKeyItem = require("XUi/XUiSet/ChildItem/XUiBtnKeyItem")
local XUiPanelFightSet = require("XUi/XUiSet/XUiPanelFightSet")

local XUiPanelFightSetPc = XClass(XUiPanelFightSet, "XUiPanelFightSetPc")

function XUiPanelFightSetPc:GetDefaultIndex()
    return self.PageType.Keyboard
end

function XUiPanelFightSetPc:RefreshKeyboardPanel()
    self.PanelKeyboardSet.gameObject:SetActiveEx(true)
end

function XUiPanelFightSetPc:UpdatePanel()
    if self.CurPageType == self.PageType.Touch then
        self.UiRoot.BtnSave.gameObject:SetActiveEx(true)
        self.UiRoot.BtnDefault.gameObject:SetActiveEx(true)
    elseif self.CurPageType == self.PageType.GameController then
        self.UiRoot.BtnSave.gameObject:SetActiveEx(false)
        if XInputManager.EnableInputJoystick then
            self.UiRoot.BtnDefault.gameObject:SetActiveEx(true)
        else
            self.UiRoot.BtnDefault.gameObject:SetActiveEx(false)
        end
        self:InitControllerPanel()
    elseif self.CurPageType == self.PageType.Keyboard then
        self.UiRoot.BtnSave.gameObject:SetActiveEx(false)
        self.UiRoot.BtnDefault.gameObject:SetActiveEx(true)
        self:InitKeyboardPanel()
    end
    self:ShowSubPanel(self.CurPageType)
end

function XUiPanelFightSetPc:ResetToDefault()
    if self.CurPageType == self.PageType.Touch then
        self.DynamicJoystick = XSetConfigs.DefaultDynamicJoystick
        self.JoystickGroup:SelectIndex(self.DynamicJoystick + 1)
    elseif self.CurPageType == self.PageType.GameController then
        XInputManager.DefaultKeysSetting(self:GetCurKeySetType())
        XInputManager.DefaultCameraMoveSensitivitySetting(self:GetCurKeySetType())
        self.SliderCameraMoveSensitivityPc.value = self:GetCameraMoveSensitivity()
        self:InitControllerPanel(true)
    elseif self.CurPageType == self.PageType.Keyboard then
        XInputManager.DefaultKeysSetting(CS.KeySetType.Keyboard)
        XInputManager.DefaultCameraMoveSensitivitySetting(CS.KeySetType.Keyboard)
        self:InitKeyboardPanel(true)
    end
end

function XUiPanelFightSetPc:InitKeyboardPanel(resetTextOnly)
    if self.KeyboardPanelInit then
        for _, v in ipairs(self._KeyboardGridList) do
            v:Refresh(nil, nil, resetTextOnly)
        end
        self.SliderCameraMoveSensitivityPc.value = self:GetCameraMoveSensitivity()
        return
    end

    self._KeyboardGridList = {}
    local list = XSetConfigs.GetControllerMapCfg()

    for _, item in ipairs(list) do
        if item.Type == XSetConfigs.ControllerSetItemType.SetButton then
            local grid = XUiBtnKeyItem.New(CSUnityEngineObjectInstantiate(self.BtnKeyItem, self.KeyboardSetContent), self.UiRoot)
            grid.GameObject:SetActive(true)
            grid:SetKeySetType(CS.KeySetType.Keyboard)
            grid:Refresh(item, handler(self, self.EditKey), resetTextOnly)
            self._KeyboardGridList[#self._KeyboardGridList + 1] = grid
        elseif item.Type == XSetConfigs.ControllerSetItemType.Section then
            local gridSection = CSUnityEngineObjectInstantiate(self.TxtSection, self.KeyboardSetContent)
            gridSection.gameObject:SetActiveEx(true)
            local txtTitle = gridSection:Find("TxtTitle"):GetComponent("Text")
            txtTitle.text = item.Title
        elseif item.Type == XSetConfigs.ControllerSetItemType.Slider then
            self.GridSliderPC:SetParent(self.KeyboardSetContent, false)
            self.GridSliderPC.gameObject:SetActiveEx(true)
            self.SliderCameraMoveSensitivityPc.value = self:GetCameraMoveSensitivity()
            XUiHelper.RegisterSliderChangeEvent(self, self.SliderCameraMoveSensitivityPc, function(_, value)
                self:SetCameraMoveSensitivity(value)
            end)
        end
    end
    self.BtnKeyItem.gameObject:SetActiveEx(false)
    self.KeyboardPanelInit = true
end

function XUiPanelFightSetPc:SetEnableInputKeyboard(value)
    --XInputManager.SetEnableInputKeyboard(value)
end

return XUiPanelFightSetPc