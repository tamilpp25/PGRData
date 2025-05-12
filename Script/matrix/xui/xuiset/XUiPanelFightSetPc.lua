local ToInt32 = CS.System.Convert.ToInt32
local XInputManager = CS.XInputManager
local XJoystickCursorHelper = CS.XPc.XJoystickCursorHelper
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local XUiBtnKeyItem = require("XUi/XUiSet/ChildItem/XUiBtnKeyItem")
local XUiNotCustomKeyItem = require("XUi/XUiSet/ChildItem/XUiNotCustomKeyItem")
local XUiOneKeyCustomKeyItem = require("XUi/XUiSet/ChildItem/XUiOneKeyCustomKeyItem")
local XUiNotCustomKeyItemHandle = require("XUi/XUiSet/ChildItem/XUiNotCustomKeyItemHandle")
local XUiPanelFightSet = require("XUi/XUiSet/XUiPanelFightSet")
---@class XUiPanelFightSetPc : XUiPanelFightSet
---@field Parent XUiSet
local XUiPanelFightSetPc = XClass(XUiPanelFightSet, "XUiPanelFightSetPc")

function XUiPanelFightSetPc:OnStart(secondIndex)
    self.SecondIndex = secondIndex
    XUiPanelFightSetPc.Super.OnStart(self)
    local isPc = XDataCenter.UiPcManager.IsPc()
    self.PanelJoystick.gameObject:SetActiveEx(false)    --移到布局设置里了
    self.PanelSwitch.gameObject:SetActiveEx(not isPc)
    if self.KeyboardText then
        self.KeyboardText.gameObject:SetActiveEx(isPc)
    end

    local btnTouchName = isPc and "UiSetPCBtnTabTouchName" or "UiSetBtnTabTouchName"
    self.BtnTabTouch:SetName(XUiHelper.GetText(btnTouchName))

    if not isPc then
        local gameControllerPos = self.BtnTabGameController.transform.localPosition
        local keyboardPos = self.BtnTabKeyboard.transform.localPosition
        self.BtnTabGameController.transform.localPosition = keyboardPos
        self.BtnTabKeyboard.transform.localPosition = gameControllerPos
    end

    self._IsShowFPS = XInputManager.GetFPSActive()
    self._IsShowJoystick = XInputManager.GetJoystickActive()
    self._IsShowSystemButton = false
    self._IsNoUiMode = CS.XFightUiManager.NoUiMode
    self._IsDirtyPc = false
    self:InitPc()
    
    self:SetVisiblePcToggle(isPc)
end

function XUiPanelFightSetPc:InitDrdSort()
    if self.IsInitDrdSort then
        return
    end

    self.KeyboardDrdSort:ClearOptions()
    self.ControllerDrdSort:ClearOptions()

    local CsDropdown = CS.UnityEngine.UI.Dropdown
    for _, operationType in ipairs(self.InputMapIdList) do
        local op = CsDropdown.OptionData()
        op.text = XSetConfigs.GetInputMapIdStr(operationType)
        self.KeyboardDrdSort.options:Add(op)
        self.ControllerDrdSort.options:Add(op)
    end

    local firstIndex = 1
    self.KeyboardDrdSelectIndex = firstIndex
    self.KeyboardDrdSort.onValueChanged:AddListener(function()
        local CSArrayIndexToLuaTableIndex = function(index)
            return index + 1
        end
        self:OnKeyboardDrdSortClick(CSArrayIndexToLuaTableIndex(self.KeyboardDrdSort.value))
    end)

    self.ControllerDrdSelectIndex = firstIndex
    self.ControllerDrdSort.onValueChanged:AddListener(function()
        local CSArrayIndexToLuaTableIndex = function(index)
            return index + 1
        end
        self:OnControllerDrdSortClick(CSArrayIndexToLuaTableIndex(self.ControllerDrdSort.value))
    end)

    local operationType = self.InputMapIdList[firstIndex]
    local firstOptionStr = XSetConfigs.GetInputMapIdStr(operationType)
    self.KeyboardDrdSort.captionText.text = firstOptionStr
    self.ControllerDrdSort.captionText.text = firstOptionStr
    self.IsInitDrdSort = true
end

function XUiPanelFightSetPc:OnControllerDrdSortClick(index)
    if self.ControllerDrdSelectIndex == index then
        return
    end
    self.ControllerDrdSelectIndex = index
    self:UpdatePanel()
end

function XUiPanelFightSetPc:OnKeyboardDrdSortClick(index)
    if self.KeyboardDrdSelectIndex == index then
        return
    end
    self.KeyboardDrdSelectIndex = index
    self:UpdatePanel()
end

function XUiPanelFightSetPc:GetInputMapId()
    if self.CurPageType == self.PageType.GameController then
        return self.InputMapIdList[self.ControllerDrdSelectIndex]
    elseif self.CurPageType == self.PageType.Keyboard then
        return self.InputMapIdList[self.KeyboardDrdSelectIndex]
    end
end

function XUiPanelFightSetPc:GetInputMapIdEnum()
    return CS.XInputMapId.__CastFrom(self:GetInputMapId())
end

function XUiPanelFightSetPc:GetDefaultIndex()
    return XDataCenter.UiPcManager.IsPc() and self.PageType.Keyboard or self.PageType.Touch
end

function XUiPanelFightSetPc:RefreshKeyboardPanel()
    if XDataCenter.UiPcManager.IsPc() then
        self.PanelKeyboardSet.gameObject:SetActiveEx(true)
    else
        self.Super.RefreshKeyboardPanel(self)
    end
end

function XUiPanelFightSetPc:UpdatePanel()
    if self.CurPageType == self.PageType.Touch then
        self.Parent.BtnSave.gameObject:SetActiveEx(true)
        self.Parent.BtnDefault.gameObject:SetActiveEx(false)
    elseif self.CurPageType == self.PageType.GameController then
        local enableInputJoystick = XInputManager.EnableInputJoystick
        self.Parent.BtnDefault.gameObject:SetActiveEx(enableInputJoystick)
        self.Parent.BtnSave.gameObject:SetActiveEx(enableInputJoystick)
        self.PanelGameControlOperationType.gameObject:SetActiveEx(enableInputJoystick)
        self:InitControllerPanel(false)
    elseif self.CurPageType == self.PageType.Keyboard then
        local enableInputKeyboard = XInputManager.EnableInputKeyboard
        self.Parent.BtnDefault.gameObject:SetActiveEx(enableInputKeyboard)
        self.Parent.BtnSave.gameObject:SetActiveEx(enableInputKeyboard)
        self.PanelKeyboardOperationType.gameObject:SetActiveEx(enableInputKeyboard)
        self:InitKeyboardPanel()
    end
    self:ShowSubPanel(self.CurPageType)
end

function XUiPanelFightSetPc:ResetToDefault()
    if self.CurPageType == self.PageType.Touch then
        self.DynamicJoystick = XSetConfigs.DefaultDynamicJoystick
        self.JoystickGroup:SelectIndex(self.DynamicJoystick + 1)
        
        self._IsShowJoystick = XInputManager.DEFAULT_JOYSTICK_ACTIVE == 1
        self._IsShowSystemButton = false
        self._IsNoUiMode = CS.XFightUiManager.NoUiMode
        self.TogSystemButton.isOn = self._IsShowSystemButton

    elseif self.CurPageType == self.PageType.GameController then
        self:ResetToDefaultTips(function()
            XInputManager.InputMapper:DefaultKeysSetting(self:GetInputMapIdEnum(), self:GetCurKeySetType())
            XInputManager.DefaultCameraMoveSensitivitySetting(self:GetCurKeySetType())
            self.SliderCameraMoveSensitivityPc.value = self:GetCameraMoveSensitivity()
            XJoystickCursorHelper.SetDefaultSensitivity()
            self.CursorMoveSensitivity.value = self:GetCursorMoveSensitivity()
            self:InitControllerPanel(true)
        end)
    elseif self.CurPageType == self.PageType.Keyboard then
        self:ResetToDefaultTips(function()
            XInputManager.InputMapper:DefaultKeysSetting(self:GetInputMapIdEnum(), CS.InputDeviceType.Keyboard)
            XInputManager.DefaultCameraMoveSensitivitySetting(CS.InputDeviceType.Keyboard)
            self:InitKeyboardPanel(true)
        end)
    end
end

function XUiPanelFightSetPc:ResetToDefaultTips(callFunc)
    XUiManager.DialogTip(nil, XUiHelper.GetText("DefaultKeyCodesTip"), nil, nil, callFunc)
end

function XUiPanelFightSetPc:IsSameKeySet(keySetTypes)
    if XTool.IsTableEmpty(keySetTypes) then
        return true
    end

    local curKeySetType = ToInt32(self:GetCurKeySetType())
    for _, keySetType in ipairs(keySetTypes) do
        if curKeySetType == keySetType then
            return true
        end
    end
    return false
end

function XUiPanelFightSetPc:InitControllerPanel(resetTextOnly)
    self:InitDrdSort()

    local curInputMapId = self:GetInputMapId()
    if not curInputMapId then
        return
    end

    self.CtrlKeyItemList = self.CtrlKeyItemList or {}
    local list = XSetConfigs.GetControllerMapCfg()

    for id, v in ipairs(list) do
        local grid = self.CtrlKeyItemList[id]
        if curInputMapId == v.InputMapId and self:IsSameKeySet(v.KeySetTypes) then
            if v.Type == XSetConfigs.ControllerSetItemType.SetButton then
                local defaultKeyMapTable = XSetConfigs.GetDefaultKeyMapTable(v.DefaultKeyMapIds[1])
                if not defaultKeyMapTable then
                    goto CONTINUE
                end
                
                local keyCodeType = defaultKeyMapTable.KeyCodeType
                if keyCodeType == XSetConfigs.KeyCodeType.NotCustom or keyCodeType == XSetConfigs.KeyCodeType.NotCustomIgnoreCheck then
                    grid = grid or XUiNotCustomKeyItemHandle.New(CSUnityEngineObjectInstantiate(self.NotCustomKeyItemHandle, self.ControllerSetContent), self.Parent)
                else
                    grid = grid or XUiBtnKeyItem.New(CSUnityEngineObjectInstantiate(self.BtnKeyItem, self.ControllerSetContent), self.Parent)
                end

                grid:SetKeySetType(self:GetCurKeySetType())
                grid:Refresh(v, handler(self, self.EditKey), resetTextOnly, curInputMapId, defaultKeyMapTable.OperationType)
            elseif v.Type == XSetConfigs.ControllerSetItemType.Section then
                grid = grid or CSUnityEngineObjectInstantiate(self.TxtSection, self.ControllerSetContent)
                local txtTitle = grid:Find("TxtTitle"):GetComponent("Text")
                txtTitle.text = v.Title
            elseif v.Type == XSetConfigs.ControllerSetItemType.Slider then
                if not grid then
                    if v.InputMapId == 1 then
                        self.GridSlider:SetParent(self.ControllerSetContent, false)
                        XUiHelper.RegisterSliderChangeEvent(self, self.SliderCameraMoveSensitivity, function(_, value)
                            if self:GetCameraMoveSensitivity() == value then
                                return
                            end
                            self:SetCameraMoveSensitivity(value)
                        end)
                        grid = grid or self.GridSlider
                    elseif v.InputMapId == 4 then
                        self.VirtualCursorPC:SetParent(self.ControllerSetContent, false)
                        XUiHelper.RegisterSliderChangeEvent(self, self.CursorMoveSensitivity, function(_, value)
                            self:SetCursorMoveSensitivity(value)
                        end)
                        grid = grid or self.VirtualCursorPC
                    end
                end
                self.SliderCameraMoveSensitivity.value = self:GetCameraMoveSensitivity()
                grid = grid or self.GridSlider
            end

            self.SliderCameraMoveSensitivity.value = self:GetCameraMoveSensitivity()
            self.CursorMoveSensitivity.value = self:GetCursorMoveSensitivity()

            self.CtrlKeyItemList[id] = grid
            
            :: CONTINUE ::
        end
    end
    self.BtnKeyItem.gameObject:SetActiveEx(false)
end

function XUiPanelFightSetPc:InitKeyboardPanel(resetTextOnly)
    self:InitDrdSort()
    local curInputMapId = self:GetInputMapId()

    if not curInputMapId then
        return
    end

    self._KeyboardGridList = self._KeyboardGridList or {}
    local list = XSetConfigs.GetControllerMapCfg()

    for id, item in ipairs(list) do
        local grid = self._KeyboardGridList[id]
        if curInputMapId == item.InputMapId and self:IsSameKeySet(item.KeySetTypes) then
            if item.Type == XSetConfigs.ControllerSetItemType.SetButton then
                local defaultKeyMapTable = XSetConfigs.GetDefaultKeyMapTable(item.DefaultKeyMapIds[1])
                if not defaultKeyMapTable then
                    goto CONTINUE
                end
                
                local keyCodeType = CS.XInputManager.GetKeyCodeTypeByInt(defaultKeyMapTable.OperationKey, curInputMapId, defaultKeyMapTable.OperationType)
                if keyCodeType == XSetConfigs.KeyCodeType.NotCustom or keyCodeType == XSetConfigs.KeyCodeType.NotCustomIgnoreCheck then
                    grid = grid or XUiNotCustomKeyItem.New(CSUnityEngineObjectInstantiate(self.NotCustomKeyItem, self.KeyboardSetContent), self.Parent)
                elseif keyCodeType == XSetConfigs.KeyCodeType.OneKeyCustom or
                        keyCodeType == XSetConfigs.KeyCodeType.KeyMouseCustom or
                        keyCodeType == XSetConfigs.KeyCodeType.SingleKey or
                        keyCodeType == XSetConfigs.KeyCodeType.Default
                then
                    grid = grid or XUiOneKeyCustomKeyItem.New(CSUnityEngineObjectInstantiate(self.OneKeyCustomKeyItem, self.KeyboardSetContent), self.Parent)
                    -- elseif keyCodeType == XSetConfigs.KeyCodeType.Default then
                    --     grid = XUiBtnKeyItem.New(CSUnityEngineObjectInstantiate(self.BtnKeyItem, self.KeyboardSetContent), self.Parent)
                end

                grid:SetKeySetType(CS.InputDeviceType.Keyboard)
                grid:Refresh(item, handler(self, self.EditKey), resetTextOnly, curInputMapId, defaultKeyMapTable.OperationType)
            elseif item.Type == XSetConfigs.ControllerSetItemType.Section then
                grid = grid or CSUnityEngineObjectInstantiate(self.TxtSection, self.KeyboardSetContent)
                local txtTitle = grid:Find("TxtTitle"):GetComponent("Text")
                txtTitle.text = item.Title
            elseif item.Type == XSetConfigs.ControllerSetItemType.Slider then
                local isNotClone = not grid
                if not grid then
                    grid = XUiHelper.Instantiate(self.GridSliderPC, self.KeyboardSetContent)
                end
                local slider = XUiHelper.TryGetComponent(grid.transform, "SliderCameraMoveSensitivityPc", "Slider")
                if isNotClone then
                    XUiHelper.RegisterSliderChangeEvent(self, slider, function(_, value)
                        if value == self:GetCameraMoveSensitivity() then
                            return
                        end
                        self:SetCameraMoveSensitivity(value)
                    end)
                end
                slider.value = self:GetCameraMoveSensitivity()
            end

            self._KeyboardGridList[id] = grid
        end
        
        :: CONTINUE ::
    end
    self.BtnKeyItem.gameObject:SetActiveEx(false)
    self.KeyboardPanelInit = true
end

function XUiPanelFightSetPc:SetGridActive(grid, enable)
    if not grid then
        return
    end

    if grid.GameObject then
        if enable then
            grid:Open()
        else
            grid:Close()
        end
    elseif grid.gameObject then
        grid.gameObject:SetActiveEx(enable)
    end
end

function XUiPanelFightSetPc:SetEnableInputKeyboard(value)
    XInputManager.SetEnableInputKeyboard(value)
end

function XUiPanelFightSetPc:RefreshGridList(curKeySetType, blockTip)
    if not curKeySetType then
        return
    end

    local gridList
    if curKeySetType == CS.InputDeviceType.Xbox or curKeySetType == CS.InputDeviceType.Ps then
        gridList = self.CtrlKeyItemList
    elseif curKeySetType == CS.InputDeviceType.Keyboard then
        gridList = self._KeyboardGridList
    end
    if gridList then
        for _, v in pairs(gridList) do
            if v.SetKeySetType then
                v:SetKeySetType(self:GetCurKeySetType())
            end
            if v.Refresh then
                v:Refresh(nil, nil, true)
            end
        end
    end

    if blockTip then
        return
    end

    XUiManager.TipSuccess(XUiHelper.GetText("SetJoyStickSuccess"))
end

function XUiPanelFightSetPc:EditKey(keyCode, targetItem, pressKeyIndex)
    if not pressKeyIndex then
        pressKeyIndex = XSetConfigs.PressKeyIndex.One
    end
    
    local operationType = targetItem:GetCurOperationType()
    local inputMapId = targetItem:GetCurInputMapId()

    XInputManager.EndEdit()
    self.PanelJoypadKeyIcon.gameObject:SetActiveEx(false)
    local cb = function(isConflict)
        self.CurSelectBtn = nil
        self.CurSelectKey = nil
        targetItem:Refresh()
        self:ShowSetKeyTip(false)
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
                            CS.XInputManager.InputMapper:ClearConflictKey()
                        end,
                        function()
                            CS.XInputManager.InputMapper:SwapConflictKey(curKeySetType, pressKeyIndex, inputMapId)
                            self:RefreshGridList(curKeySetType)
                        end
                )
            end
        end
    end

    self.TxtInput.text = CS.XTextManager.GetText("SetInputStart")
    self.TxtFunction.text = targetItem.Data.Title

    XInputManager.StartEditKey(self:GetCurKeySetType(), keyCode, pressKeyIndex, cb, inputMapId, operationType, targetItem:GetDataId())
    self:ShowSetKeyTip(true)
    self.CurSelectBtn = targetItem
    self.CurSelectKey = keyCode
end

function XUiPanelFightSetPc:CheckDataIsChange()
    local changed = self.Super.CheckDataIsChange(self)
    changed = XJoystickCursorHelper.IsCursorSensitivityChanged() or changed
    changed = self._IsDirtyPc or changed
    return changed
end

function XUiPanelFightSetPc:SaveChange()
    self.Super.SaveChange(self);
    XJoystickCursorHelper.SaveSensitivityChange();

    self._IsDirtyPc = false
    CS.XFightUiManager.NoUiMode = self._IsNoUiMode
    self:LoadSchemeName()
end

function XUiPanelFightSetPc:CancelChange()
    self.Super.CancelChange(self);
    XJoystickCursorHelper.RevertSensitivity();
end

function XUiPanelFightSetPc:SetCursorMoveSensitivity(value)
    XJoystickCursorHelper.PreSetCursorMoveSensitivity(value)
end

function XUiPanelFightSetPc:GetCursorMoveSensitivity()
    return XJoystickCursorHelper.CursorMoveSensitivity
end

function XUiPanelFightSetPc:InitPc()
    self.TogSystemButton.isOn = self._IsShowSystemButton
    self.TogSystemButton.onValueChanged:AddListener(handler(self, self.OnTogSystemButtonChanged))
end

function XUiPanelFightSetPc:OnTogFPSValueChanged(value)
    if self._IsShowFPS ~= value then
        self._IsShowFPS = value
        self._IsDirtyPc = true
    end
end

function XUiPanelFightSetPc:OnTogJoystickValueChanged(value)
    if self._IsShowJoystick ~= value then
        self._IsShowJoystick = value
        self._IsDirtyPc = true
    end
end

function XUiPanelFightSetPc:OnTogSystemButtonChanged(value)
    if self._IsShowSystemButton ~= value then
        self._IsShowSystemButton = value
        self._IsDirtyPc = true
    end
end

function XUiPanelFightSetPc:OnTogClearUIButtonChanged(value)
    if self._IsNoUiMode ~= value then
        self._IsNoUiMode = value
        self._IsDirtyPc = true
    end
end

function XUiPanelFightSetPc:IsPageTypeTouch()
    return self.CurPageType == self.PageType.Touch
end

function XUiPanelFightSetPc:HidePanel()
    XUiPanelFightSet.HidePanel(self)
    if self._KeyboardGridList then
        for _, grid in pairs(self._KeyboardGridList) do
            if grid and grid.Close then
                grid:Close()
            end
        end
    end
end

return XUiPanelFightSetPc