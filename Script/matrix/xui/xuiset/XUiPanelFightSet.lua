---@class XUiPanelFightSet : XUiNode
local XUiPanelFightSet = XClass(XUiNode, "XUiPanelFightSet")

local XInputManager = CS.XInputManager
local XUiRespondBarrierType = CS.XUiComponent.XUiButton.XUiRespondBarrierType
local Pairs = pairs

function XUiPanelFightSet:OnStart()
    self.OperationTypeList = XDataCenter.SetManager.GetOperationTypeList()
    
    self:ShowSetKeyTip(false)
    self:GetDataThenLoadSchemeName()
    self.PageType = {
        Touch = 1, --触摸设置
        GameController = 2, --外接手柄键位设置
        Keyboard = 3, -- 键盘键位设置
    }
    self._CurKeySetType = false
    self:UpdateKeySetType()

    self.CurSelectBtn = nil
    self.CurSelectKey = nil

    self.BtnTabGroup:Init({ self.BtnTabTouch, self.BtnTabGameController, self.BtnTabKeyboard }, function(index)
        self:OnTabClick(index)
    end)
    self.PatternGroup:Init({ self.BtnXbox, self.BtnPS4 }, function(index)
        self:OnPatternGroupClick(index)
    end)
    self.JoystickGroup:Init({ self.TogStatic, self.TogDynamic }, nil)
    self.TogStatic.CallBack = function()
        self:OnTogStaticJoystickClick()
    end
    self.TogDynamic.CallBack = function()
        self:OnTogDynamicJoystickClick()
    end
    self.BtnCustomUi.CallBack = function()
        self:OnBtnCustomUiClick()
    end
    self.TogEnableJoystick.CallBack = function()
        self:OnTogEnableJoystickClick()
    end
    self.TogEnableKeyboard.CallBack = function()
        self:OnTogEnableKeyboardClick()
    end
    self.BtnCloseInput.CallBack = function()
        self:OnBtnCloseInputClick()
    end
    self.BtnCloseInput:SetBarrierType(XUiRespondBarrierType.Mouse2)

    self:InitControllerPanel()
    self:RefreshJoystickPanel()

    self:InitKeyboardPanel()
    self:RefreshKeyboardPanel()

    self.CurPageType = self:GetDefaultIndex()
    self.BtnTabGroup:SelectIndex(self.CurPageType, false)
    self.PatternGroup:SelectIndex(XInputManager.GetJoystickType())

    local behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    if self.Update then
        behaviour.LuaUpdate = function()
            self:Update()
        end
    end

    self.CustomUi.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CustomUi))

    self:SetVisiblePcToggle(false)
end

function XUiPanelFightSet:OnEnable()
    self:RegisterCustomUiEvent()
    XEventManager.AddEventListener(XEventId.EVENT_JOYSTICK_TYPE_CHANGED, self.OnJoystickTypeChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_JOYSTICK_ACTIVE_CHANGED, self.OnJoystickActiveChanged, self)
    self:ShowPanel()
end

function XUiPanelFightSet:OnDisable()
    self:HidePanel()
    self:RemoveCustomUiEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_JOYSTICK_TYPE_CHANGED, self.OnJoystickTypeChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_JOYSTICK_ACTIVE_CHANGED, self.OnJoystickActiveChanged, self)
end

function XUiPanelFightSet:OnJoystickTypeChanged()
    self.PatternGroup:SelectIndex(XInputManager.GetJoystickType())
    self:OnPatternGroupClick()
end

function XUiPanelFightSet:OnJoystickActiveChanged()
    self:RefreshJoystickPanel()
    self:OnBtnCloseInputClick()
end

function XUiPanelFightSet:GetCurKeySetType()
    return self._CurKeySetType or CS.KeySetType.Xbox --默认会显示xbox
end

function XUiPanelFightSet:GetDefaultIndex()
    return self.PageType.Touch
end

--自定义按键
function XUiPanelFightSet:OnCheckCustomUiSetNews(count)
    self.BtnCustomUi:ShowReddot(count >= 0)
end

function XUiPanelFightSet:GetCache()
    self.DynamicJoystick = XDataCenter.SetManager.DynamicJoystick
    self.JoystickGroup:SelectIndex(self.DynamicJoystick + 1)
end

function XUiPanelFightSet:Update()
    if self.CurSelectBtn and self.CurSelectKey and XInputManager.GetCurEditKeyNum() > 0 then
        local curKeySetType = self:GetCurKeySetType()
        if curKeySetType == CS.KeySetType.Keyboard then
            self.TxtInput.text = XInputManager.GetCurEditKeyString() .. CS.XTextManager.GetText("SetInputFirstKey")
            self.PanelJoypadKeyIcon.gameObject:SetActiveEx(false)
        else
            self.TxtInput.text = ""
            local mainKeyIcon = XInputManager.GetCurEditKeyIcon(CS.KeyPos.MainKey, curKeySetType)
            local subKeyIcon = XInputManager.GetCurEditKeyIcon(CS.KeyPos.SubKey, curKeySetType)
            if not string.IsNilOrEmpty(mainKeyIcon) then
                self.JoypadIcon1:SetSprite(mainKeyIcon)
            end
            
            local subKeyIsNil = string.IsNilOrEmpty(subKeyIcon)
            if not subKeyIsNil then
                self.JoypadIcon2:SetSprite(subKeyIcon)
            end
            self.JoypadIcon2.gameObject:SetActiveEx(not subKeyIsNil)
            self.TxtAdd.gameObject:SetActiveEx(not subKeyIsNil)

            self.PanelJoypadKeyIcon.gameObject:SetActiveEx(true)
        end
    end
end

function XUiPanelFightSet:ShowSetKeyTip(show)
    XDataCenter.UiPcManager.SetEditingKeyState(show);
    self.PanelSetKeyTip.gameObject:SetActiveEx(show)
end

function XUiPanelFightSet:OnTabClick(index)
    self.CurPageType = index
    self:UpdateKeySetType()
    self:UpdatePanel()
end

function XUiPanelFightSet:UpdatePanel()
    if self.CurPageType == self.PageType.Touch then
        self.Parent.BtnSave.gameObject:SetActiveEx(true)
        self.Parent.BtnDefault.gameObject:SetActiveEx(true)
    elseif self.CurPageType == self.PageType.GameController then
        self.Parent.BtnSave.gameObject:SetActiveEx(false)
        if XInputManager.EnableInputJoystick then
            self.Parent.BtnDefault.gameObject:SetActiveEx(true)
        else
            self.Parent.BtnDefault.gameObject:SetActiveEx(false)
        end
        self:InitControllerPanel()
    elseif self.CurPageType == self.PageType.Keyboard then
        self.Parent.BtnSave.gameObject:SetActiveEx(false)
        self.Parent.BtnDefault.gameObject:SetActiveEx(false)
        self:InitKeyboardPanel()
    end
    self:ShowSubPanel(self.CurPageType)
end

function XUiPanelFightSet:ShowSubPanel(type)
    self.PanelTouch.gameObject:SetActiveEx(type == self.PageType.Touch)
    self.PanelGameController.gameObject:SetActiveEx(type == self.PageType.GameController)
    self.PanelKeyboard.gameObject:SetActiveEx(type == self.PageType.Keyboard)
    self:RefreshKeyboardItem(type == self.PageType.Keyboard and (self.TogEnableKeyboard:GetToggleState() or XDataCenter.UiPcManager.IsPc()))
    self:RefreshJoystickItem(type == self.PageType.GameController and self.TogEnableJoystick:GetToggleState())
end

function XUiPanelFightSet:OnPatternGroupClick(index)
    self:UpdateKeySetType()
    self:InitControllerPanel()
end

function XUiPanelFightSet:ShowPanel()
    self:UpdatePanel()
    self:GetCache()
    self:AddRedPointEvent(self.BtnCustomUi, self.OnCheckCustomUiSetNews, self, { XRedPointConditions.Types.CONDITION_MAIN_SET }, nil, true)
    self.IsShow = true
end

function XUiPanelFightSet:HidePanel()
    XInputManager.EndEdit()
    self.IsShow = false
end

function XUiPanelFightSet:OnTogStaticJoystickClick()
    self.DynamicJoystick = 0
end

function XUiPanelFightSet:OnTogDynamicJoystickClick()
    self.DynamicJoystick = 1
end

function XUiPanelFightSet:CheckDataIsChange()
    if self._CurKeySetTypeInt and self._CurKeySetTypeInt ~= XInputManager.GetJoystickType() then
        return true
    end
    return  self.DynamicJoystick ~= XDataCenter.SetManager.DynamicJoystick or XInputManager.IsKeyMappingChange() or XInputManager.IsCameraMoveSensitivitiesChange()
end

function XUiPanelFightSet:SaveTouchChange()
    if self.DynamicJoystick == XDataCenter.SetManager.DynamicJoystick then
        return
    end

    XDataCenter.SetManager.SetDynamicJoystick(self.DynamicJoystick)
    CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.DynamicJoystick, self.DynamicJoystick)
    CS.UnityEngine.PlayerPrefs.Save()
    
    local dict = {}
    dict["mobile_control"] = {
        scheme_name = CS.XCustomUi.Instance.SchemeName,
        joystick_type = self.DynamicJoystick
    }
    dict["controller_control"] = {
        open = self.TogEnableJoystick:GetToggleState()
    }
    dict["keyboard_control"] = {
        open = self.TogEnableKeyboard:GetToggleState()
    }

    XDataCenter.SetManager.SystemSettingBuriedPoint(dict)
end

function XUiPanelFightSet:SaveChange()
    self:SaveTouchChange()
    if self._CurKeySetTypeInt then
        XInputManager.SetJoystickType(self._CurKeySetTypeInt)
    end
    XInputManager.SaveChange()
end

function XUiPanelFightSet:CancelChange()
    self.JoystickGroup:SelectIndex(self.DynamicJoystick + 1)
    self.PatternGroup:SelectIndex(XInputManager.GetJoystickType())
    self._CurKeySetTypeInt = XInputManager.GetJoystickType()
    XInputManager.RevertKeyMappings()
end

function XUiPanelFightSet:OnTogEnableJoystickClick(value)
    if value ~= nil then
        XInputManager.SetEnableInputJoystick(value)
    else
        XInputManager.SetEnableInputJoystick(self.TogEnableJoystick:GetToggleState())
    end

    if XInputManager.EnableInputJoystick and not XDataCenter.UiPcManager.IsPc() then
        XInputManager.SetEnableInputKeyboard(false)
        self:RefreshKeyboardPanel()
    end

    self:InitControllerPanel()
    self:RefreshJoystickPanel()
end

function XUiPanelFightSet:RefreshJoystickItem(enable)
    if self.CtrlKeyItemList then
        for i, grid in Pairs(self.CtrlKeyItemList) do
            local list = XSetConfigs.GetControllerMapCfg()
            local item = list[i]
            local curOperationType = self:GetCurOperationType()
            local isActive = curOperationType == item.OperationType and self:IsSameKeySet(item.KeySetTypes)

            self:SetGridActive(grid, enable and isActive)
        end
    end
end

function XUiPanelFightSet:RefreshJoystickPanel()
    local enable = XInputManager.EnableInputJoystick
    local isPc = XDataCenter.UiPcManager.IsPc()
    self.TogEnableJoystick:SetButtonState(enable and XUiButtonState.Select or XUiButtonState.Normal)
    if enable then
        self.PanelJoystickSet.gameObject:SetActiveEx(true)
        self.TipDisableJoyStick.gameObject:SetActiveEx(false)
        self.Parent.BtnDefault.gameObject:SetActiveEx(true)
        self.Parent.BtnSave.gameObject:SetActiveEx(true)
        self.PanelGameControlOperationType.gameObject:SetActiveEx(true)
        self:InitControllerPanel()
        if not isPc then
            self:SetEnableInputKeyboard(false)
        end
    else
        self.PanelJoystickSet.gameObject:SetActiveEx(false)
        self.TipDisableJoyStick.gameObject:SetActiveEx(true)
        self.Parent.BtnDefault.gameObject:SetActiveEx(false)
        self.Parent.BtnSave.gameObject:SetActiveEx(false)
        self.PanelGameControlOperationType.gameObject:SetActiveEx(false)
        if isPc then  -- pc时,手柄被禁用了则要立即开启键盘
            self:SetEnableInputKeyboard(true)
        end
    end
    self:RefreshJoystickItem(enable)
end

function XUiPanelFightSet:OnTogEnableKeyboardClick(value)
    if value ~= nil then
        self:SetEnableInputKeyboard(value)
    else
        self:SetEnableInputKeyboard(self.TogEnableKeyboard:GetToggleState())
    end

    if XInputManager.EnableInputKeyboard and not XDataCenter.UiPcManager.IsPc() then
        XInputManager.SetEnableInputJoystick(false)
        self:RefreshJoystickPanel()
    end

    self:InitKeyboardPanel()
    self:RefreshKeyboardPanel()
end

function XUiPanelFightSet:RefreshKeyboardItem(enable)
    if self._KeyboardGridList then
        for i, grid in Pairs(self._KeyboardGridList) do
            local list = XSetConfigs.GetControllerMapCfg()
            local item = list[i]
            local curOperationType = self:GetCurOperationType()
            local isActive = curOperationType == item.OperationType and self:IsSameKeySet(item.KeySetTypes)

            self:SetGridActive(grid, enable and isActive)
        end
    end
end

function XUiPanelFightSet:RefreshKeyboardPanel()
    local enable = XInputManager.EnableInputKeyboard
    self.TogEnableKeyboard:SetButtonState(enable and XUiButtonState.Select or XUiButtonState.Normal)
    if enable then
        self.PanelKeyboardSet.gameObject:SetActiveEx(true)
        self.TipDisableKeyboard.gameObject:SetActiveEx(false)
        self.Parent.BtnDefault.gameObject:SetActiveEx(true)
        self.Parent.BtnSave.gameObject:SetActiveEx(true)
        self.PanelKeyboardOperationType.gameObject:SetActiveEx(true)
        if not XDataCenter.UiPcManager.IsPc() then
            XInputManager.SetEnableInputJoystick(false)
        end
    else
        self.PanelKeyboardSet.gameObject:SetActiveEx(false)
        self.TipDisableKeyboard.gameObject:SetActiveEx(true)
        self.Parent.BtnDefault.gameObject:SetActiveEx(false)
        self.Parent.BtnSave.gameObject:SetActiveEx(false)
        self.PanelKeyboardOperationType.gameObject:SetActiveEx(false)
    end
    self:RefreshKeyboardItem(enable)
end

function XUiPanelFightSet:OnBtnCloseInputClick()
    XInputManager.EndEdit()
    self:ShowSetKeyTip(false)
end

function XUiPanelFightSet:OnBtnCustomUiClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CustomUi) then
        return
    end

    XLuaUiManager.Open("UiFightCustom", CS.XFight.Instance)
end

function XUiPanelFightSet:GetDataThenLoadSchemeName()
    CS.XCustomUi.Instance:GetData()
    self:LoadSchemeName()
end

function XUiPanelFightSet:LoadSchemeName()
    self.TxtScheme.text = CS.XCustomUi.Instance.SchemeName
end

function XUiPanelFightSet:RegisterCustomUiEvent()
    self.LoadSchemeNameFunc = handler(self, self.LoadSchemeName)
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED, self.LoadSchemeNameFunc)
end

function XUiPanelFightSet:RemoveCustomUiEvent()
    CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED, self.LoadSchemeNameFunc)
    self.LoadSchemeNameFunc = nil
end

function XUiPanelFightSet:SetEnableInputKeyboard(value)
    XInputManager.SetEnableInputKeyboard(value)
end

function XUiPanelFightSet:UpdateKeySetType()
    if self.BtnTabGroup.CurSelectId == self.PageType.Touch then
        return
    end
    if self.BtnTabGroup.CurSelectId == self.PageType.Keyboard then
        self._CurKeySetType = CS.KeySetType.Keyboard
        self._CurKeySetTypeInt = nil
        return
    end
    if self.BtnTabGroup.CurSelectId == self.PageType.GameController then
        if self.PatternGroup.CurSelectId == 1 then
            self._CurKeySetType = CS.KeySetType.Xbox
            self._CurKeySetTypeInt = 1
            return
        end
        if self.PatternGroup.CurSelectId == 2 then
            self._CurKeySetType = CS.KeySetType.Ps
            self._CurKeySetTypeInt = 2
            return
        end
    end
end

function XUiPanelFightSet:SetCameraMoveSensitivity(value)
    value = value + 1
    XInputManager.SetCameraMoveSensitivity(self:GetCurKeySetType(), value)
end

function XUiPanelFightSet:GetCameraMoveSensitivity()
    local value = XInputManager.GetCameraMoveSensitivity(self:GetCurKeySetType())
    return math.max(0, value - 1)
end

function XUiPanelFightSet:SetVisiblePcToggle(value)
    self.TogFPS.transform.parent.gameObject:SetActiveEx(value)
    self.TogFightButton.transform.parent.gameObject:SetActiveEx(value)
    self.TogJoystick.transform.parent.gameObject:SetActiveEx(value)
    self.TogClearUI.transform.parent.gameObject:SetActiveEx(value)
end

return XUiPanelFightSet