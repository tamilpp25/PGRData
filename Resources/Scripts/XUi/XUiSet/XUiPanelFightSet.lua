XUiPanelFightSet = XClass(nil, "XUiPanelFightSet")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local XUiBtnKeyItem = require("XUi/XUiSet/ChildItem/XUiBtnKeyItem")

local XInputManager = CS.XInputManager

function XUiPanelFightSet:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self.PanelSetKeyTip.gameObject:SetActiveEx(false)
    self:GetDataThenLoadSchemeName()
    self:RegisterCustomUiEvent()
    self.PageType =    {
        Touch = 1, --触摸设置
        GameController = 2, --外接手柄键位设置
        Keyboard = 3, -- 键盘键位设置
    }
    self._CurKeySetType = false
    self:UpdateKeySetType()

    self.CurSelectBtn = nil
    self.CurSelectKey = nil

    self.BtnTabGroup:Init({ self.BtnTabTouch, self.BtnTabGameController, self.BtnTabKeyboard }, function(index) self:OnTabClick(index) end)
    self.PatternGroup:Init({ self.BtnXbox, self.BtnPS4 }, function(index) self:OnPatternGroupClick(index) end)
    self.JoystickGroup:Init({ self.TogStatic, self.TogDynamic }, nil)
    self.TogStatic.CallBack = function() self:OnTogStaticJoystickClick() end
    self.TogDynamic.CallBack = function() self:OnTogDynamicJoystickClick() end
    self.BtnCustomUi.CallBack = function() self:OnBtnCustomUiClick() end
    self.TogEnableJoystick.CallBack = function() self:OnTogEnableJoystickClick() end
    self.TogEnableKeyboard.CallBack = function() self:OnTogEnableKeyboardClick() end
    self.BtnCloseInput.CallBack = function() self:OnBtnCloseInputClick() end

    self:InitControllerPanel()
    self:RefreshJoystickPanel()
    self:InitKeyboardPanel()

    self:RefreshKeyboardPanel()
    self.BtnTabGroup:SelectIndex(self:GetDefaultIndex())
    self.PatternGroup:SelectIndex(XInputManager.GetJoystickType())
    local behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    if self.Update then
        behaviour.LuaUpdate = function() self:Update() end
    end

    self.CustomUi.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CustomUi))
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

function XUiPanelFightSet:InitControllerPanel(resetTextOnly)
    if self.CtrlPanelInit then
        for _, v in ipairs(self.CtrlKeyItemList) do
            v:SetKeySetType(self:GetCurKeySetType())
            v:Refresh(nil, nil, resetTextOnly)
        end
        self.SliderCameraMoveSensitivity.value = self:GetCameraMoveSensitivity()
        return
    end
    self.CtrlKeyItemList = {}
    local list = XSetConfigs.GetControllerMapCfg()

    for _, v in ipairs(list) do
        if v.Type == XSetConfigs.ControllerSetItemType.SetButton then
            local grid = XUiBtnKeyItem.New(CSUnityEngineObjectInstantiate(self.BtnKeyItem, self.ControllerSetContent), self.UiRoot)
            table.insert(self.CtrlKeyItemList, grid)
            grid.GameObject:SetActiveEx(true)
            grid:SetKeySetType(self:GetCurKeySetType())
            grid:Refresh(v, handler(self, self.EditKey), resetTextOnly)
        elseif v.Type == XSetConfigs.ControllerSetItemType.Section then
            local gridSection = CSUnityEngineObjectInstantiate(self.TxtSection, self.ControllerSetContent)
            gridSection.gameObject:SetActiveEx(true)
            local txtTitle = gridSection:Find("TxtTitle"):GetComponent("Text")
            txtTitle.text = v.Title
        elseif v.Type == XSetConfigs.ControllerSetItemType.Slider then
            self.GridSlider:SetParent(self.ControllerSetContent, false)
            self.GridSlider.gameObject:SetActiveEx(true)
            self.SliderCameraMoveSensitivity.value = self:GetCameraMoveSensitivity()
            XUiHelper.RegisterSliderChangeEvent(self, self.SliderCameraMoveSensitivity, function(_, value)
                 self:SetCameraMoveSensitivity(value)
            end)
        end
    end
    self.BtnKeyItem.gameObject:SetActiveEx(false)
    self.CtrlPanelInit = true
end

--TODO:键盘自定义
function XUiPanelFightSet:InitKeyboardPanel()
    if self.KeyboardPanelInit then
        return
    end

    local list = XSetConfigs.GetKeyboardMapCfg()

    for _, item in ipairs(list) do
        local grid = XUiBtnKeyItem.New(CSUnityEngineObjectInstantiate(self.BtnKeyItem, self.KeyboardSetContent), self)
        grid.GameObject:SetActive(true)
        grid:SetKeySetType(CS.KeySetType.Keyboard)
        grid:Refresh(item)
    end
    self.BtnKeyItem.gameObject:SetActiveEx(false)
    self.KeyboardPanelInit = true
end

function XUiPanelFightSet:Update()
    if self.CurSelectBtn and self.CurSelectKey and XInputManager.GetCurEditKeyNum() > 0 then
        self.TxtInput.text = XInputManager.GetCurEditKeyString() .. CS.XTextManager.GetText("SetInputFirstKey")
    end
end

function XUiPanelFightSet:EditKey(keyCode, targetItem)
    XInputManager.EndEdit()
    local cb = function(isConflict)
        self.CurSelectBtn = nil
        self.CurSelectKey = nil
        targetItem:Refresh()
        self.PanelSetKeyTip.gameObject:SetActiveEx(false)
        if isConflict then
            local curKeySetType = self:GetCurKeySetType()
            local keyCurrent = CS.XInputManager.GetConflictKey1()
            local keyConflict = CS.XInputManager.GetConflictKey2()
            local textKeyCurrent = XSetConfigs.GetControllerKeyText(keyCurrent)
            local textKeyConflict = XSetConfigs.GetControllerKeyText(keyConflict)
            if textKeyCurrent and textKeyConflict then
                XUiManager.DialogTip(
                        nil,
                        XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("SetKeyConflict", textKeyConflict, textKeyCurrent)),
                        XUiManager.DialogType.Normal,
                        function()
                            CS.XInputManager.ClearConflictKey()
                        end,
                        function()
                            CS.XInputManager.SwapConflictKey(curKeySetType)
                            local gridList
                            if curKeySetType == CS.KeySetType.Xbox or curKeySetType == CS.KeySetType.Ps4 then
                                gridList = self.CtrlKeyItemList
                            elseif curKeySetType == CS.KeySetType.Keyboard then
                                gridList = self._KeyboardGridList
                            end
                            if gridList then
                                for _, v in ipairs(gridList) do
                                    v:SetKeySetType(self:GetCurKeySetType())
                                    v:Refresh(nil, nil, true)
                                end
                            end
                            XUiManager.TipSuccess(XUiHelper.GetText("SetJoyStickSuccess"))
                        end
                )
            end
        end
    end

    if self:GetCurKeySetType() == CS.KeySetType.Keyboard then
        self.TxtInput.text = CS.XTextManager.GetText("SetInputStartNoCombine")
    else
        self.TxtInput.text = CS.XTextManager.GetText("SetInputStart")
    end
    self.TxtFunction.text = targetItem.Data.Title
    XInputManager.StartEditKey(self:GetCurKeySetType(), keyCode, cb)
    self.PanelSetKeyTip.gameObject:SetActiveEx(true)
    self.CurSelectBtn = targetItem
    self.CurSelectKey = keyCode
end

function XUiPanelFightSet:OnTabClick(index)
    self.CurPageType = index
    self:UpdateKeySetType()
    self:UpdatePanel()
end

function XUiPanelFightSet:UpdatePanel()
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
        self.UiRoot.BtnDefault.gameObject:SetActiveEx(false)
        self:InitKeyboardPanel()
    end
    self:ShowSubPanel(self.CurPageType)
end

function XUiPanelFightSet:ShowSubPanel(type)
    self.PanelTouch.gameObject:SetActiveEx(type == self.PageType.Touch)
    self.PanelGameController.gameObject:SetActiveEx(type == self.PageType.GameController)
    self.PanelKeyboard.gameObject:SetActiveEx(type == self.PageType.Keyboard)
end

function XUiPanelFightSet:OnPatternGroupClick(index)
    self:UpdateKeySetType()
    self:InitControllerPanel()
end

function XUiPanelFightSet:ShowPanel()
    self:UpdatePanel()
    self:GetCache()
    self.GameObject:SetActive(true)
    self.RedPoint = XRedPointManager.AddRedPointEvent(self.BtnCustomUi, self.OnCheckCustomUiSetNews, self, { XRedPointConditions.Types.CONDITION_MAIN_SET }, nil, true)
    self.IsShow = true
end

function XUiPanelFightSet:HidePanel()
    XInputManager.EndEdit()
    self.IsShow = false
    self.GameObject:SetActive(false)
end

function XUiPanelFightSet:OnTogStaticJoystickClick()
    self.DynamicJoystick = 0
end

function XUiPanelFightSet:OnTogDynamicJoystickClick()
    self.DynamicJoystick = 1
end

function XUiPanelFightSet:CheckDataIsChange()
    return self.DynamicJoystick ~= XDataCenter.SetManager.DynamicJoystick
end

function XUiPanelFightSet:SaveChange()
    if self.DynamicJoystick ~= XDataCenter.SetManager.DynamicJoystick then
        XDataCenter.SetManager.SetDynamicJoystick(self.DynamicJoystick)
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.DynamicJoystick, self.DynamicJoystick)
        CS.UnityEngine.PlayerPrefs.Save()
    end
end

function XUiPanelFightSet:CancelChange()
    self.JoystickGroup:SelectIndex(self.DynamicJoystick + 1)
end

function XUiPanelFightSet:ResetToDefault()
    if self.CurPageType == self.PageType.Touch then
        self.DynamicJoystick = XSetConfigs.DefaultDynamicJoystick
        self.JoystickGroup:SelectIndex(self.DynamicJoystick + 1)
    elseif self.CurPageType == self.PageType.GameController then
        XInputManager.DefaultKeysSetting(self:GetCurKeySetType())
        XInputManager.DefaultCameraMoveSensitivitySetting(self:GetCurKeySetType())
        self.SliderCameraMoveSensitivity.value = self:GetCameraMoveSensitivity()
        self:InitControllerPanel(true)
    end
end

function XUiPanelFightSet:OnTogEnableJoystickClick(value)
    if value ~= nil then
        XInputManager.SetEnableInputJoystick(value)
    else
        XInputManager.SetEnableInputJoystick(self.TogEnableJoystick:GetToggleState())
    end

    if XInputManager.EnableInputJoystick then
        self:SetEnableInputKeyboard(false)
        self:RefreshKeyboardPanel()
    end
    self:InitControllerPanel()
    self:RefreshJoystickPanel()
end

function XUiPanelFightSet:RefreshJoystickPanel()
    local enable = XInputManager.EnableInputJoystick
    self.TogEnableJoystick:SetButtonState(enable and XUiButtonState.Select or XUiButtonState.Normal)
    if enable then
        self.PanelJoystickSet.gameObject:SetActiveEx(true)
        self.TipDisableJoyStick.gameObject:SetActiveEx(false)
        self.UiRoot.BtnDefault.gameObject:SetActiveEx(true)
        self:SetEnableInputKeyboard(false)
    else
        self.PanelJoystickSet.gameObject:SetActiveEx(false)
        self.TipDisableJoyStick.gameObject:SetActiveEx(true)
        self.UiRoot.BtnDefault.gameObject:SetActiveEx(false)
    end
end

function XUiPanelFightSet:OnTogEnableKeyboardClick(value)
    if value ~= nil then
        self:SetEnableInputKeyboard(value)
    else
        self:SetEnableInputKeyboard(self.TogEnableKeyboard:GetToggleState())
    end

    if XInputManager.EnableInputKeyboard then
        XInputManager.SetEnableInputJoystick(false)
        self:RefreshJoystickPanel()
    end
    self:InitKeyboardPanel()
    self:RefreshKeyboardPanel()
end

function XUiPanelFightSet:RefreshKeyboardPanel()
    local enable = XInputManager.EnableInputKeyboard
    self.TogEnableKeyboard:SetButtonState(enable and XUiButtonState.Select or XUiButtonState.Normal)
    if enable then
        self.PanelKeyboardSet.gameObject:SetActiveEx(true)
        self.TipDisableKeyboard.gameObject:SetActiveEx(false)
        XInputManager.SetEnableInputJoystick(false)
    else
        self.PanelKeyboardSet.gameObject:SetActiveEx(false)
        self.TipDisableKeyboard.gameObject:SetActiveEx(true)
    end
    self.UiRoot.BtnDefault.gameObject:SetActiveEx(false)
end

function XUiPanelFightSet:OnBtnCloseInputClick()
    XInputManager.EndEdit()
    self.PanelSetKeyTip.gameObject:SetActiveEx(false)
end

function XUiPanelFightSet:OnBtnCustomUiClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CustomUi) then
        return
    end

    XLuaUiManager.Open("UiFightCustom", CS.XFight.Instance)
end

function XUiPanelFightSet:GetDataThenLoadSchemeName()
    CS.XCustomUi.Instance:GetData(function()
        self:LoadSchemeName()
    end)
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

function XUiPanelFightSet:OnDestroy()
    self:RemoveCustomUiEvent()
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
        XInputManager.SetJoystickType(3)
        return
    end
    if self.BtnTabGroup.CurSelectId == self.PageType.GameController then
        if self.PatternGroup.CurSelectId == 1 then
            self._CurKeySetType = CS.KeySetType.Xbox
            XInputManager.SetJoystickType(1)
            return
        end
        if self.PatternGroup.CurSelectId == 2 then
            self._CurKeySetType = CS.KeySetType.Ps4
            XInputManager.SetJoystickType(2)
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


return XUiPanelFightSet