local ToInt32 = CS.System.Convert.ToInt32
local XInputManager = CS.XInputManager
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local XUiBtnKeyItem = require("XUi/XUiSet/ChildItem/XUiBtnKeyItem")
local XUiNotCustomKeyItem = require("XUi/XUiSet/ChildItem/XUiNotCustomKeyItem")
local XUiOneKeyCustomKeyItem = require("XUi/XUiSet/ChildItem/XUiOneKeyCustomKeyItem")
local XUiNotCustomKeyItemHandle = require("XUi/XUiSet/ChildItem/XUiNotCustomKeyItemHandle")
local XUiPanelFightSet = require("XUi/XUiSet/XUiPanelFightSet")

local XUiPanelFightSetPc = XClass(XUiPanelFightSet, "XUiPanelFightSetPc")

function XUiPanelFightSetPc:Ctor(ui, uiRoot)
    local isPc = XDataCenter.UiPcManager.IsPc()
    self.PanelJoystick.gameObject:SetActiveEx(not isPc)
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
end

function XUiPanelFightSetPc:InitDrdSort()
    if self.IsInitDrdSort then
        return
    end
    
    self.KeyboardDrdSort:ClearOptions()
    self.ControllerDrdSort:ClearOptions()
    
    local CsDropdown = CS.UnityEngine.UI.Dropdown
    for _, operationType in ipairs(self.OperationTypeList) do
        local op = CsDropdown.OptionData()
        op.text = XSetConfigs.GetOperationTypeStr(operationType)
        self.KeyboardDrdSort.options:Add(op)
        self.ControllerDrdSort.options:Add(op)
    end
    
    local firstIndex = 1
    self.KeyboardDrdSelectIndex = firstIndex
    self.KeyboardDrdSort.onValueChanged:AddListener(function()
        local CSArrayIndexToLuaTableIndex = function(index) return index + 1 end
        self:OnKeyboardDrdSortClick(CSArrayIndexToLuaTableIndex(self.KeyboardDrdSort.value))
    end)

    self.ControllerDrdSelectIndex = firstIndex
    self.ControllerDrdSort.onValueChanged:AddListener(function()
        local CSArrayIndexToLuaTableIndex = function(index) return index + 1 end
        self:OnControllerDrdSortClick(CSArrayIndexToLuaTableIndex(self.ControllerDrdSort.value))
    end)

    local operationType = self.OperationTypeList[firstIndex]
    local firstOptionStr = XSetConfigs.GetOperationTypeStr(operationType)
    self.KeyboardDrdSort.captionText.text = firstOptionStr
    self.ControllerDrdSort.captionText.text = firstOptionStr
    self.IsInitDrdSort = true
end

function XUiPanelFightSetPc:OnControllerDrdSortClick(index)
    if self.ControllerDrdSelectIndex == index then return end
    self.ControllerDrdSelectIndex = index
    self:UpdatePanel()
end

function XUiPanelFightSetPc:OnKeyboardDrdSortClick(index)
    if self.KeyboardDrdSelectIndex == index then return end
    self.KeyboardDrdSelectIndex = index
    self:UpdatePanel()
end

function XUiPanelFightSetPc:GetCurOperationType()
    if self.CurPageType == self.PageType.GameController then
        return self.OperationTypeList[self.ControllerDrdSelectIndex]
    elseif self.CurPageType == self.PageType.Keyboard then
        return self.OperationTypeList[self.KeyboardDrdSelectIndex]
    end
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
        self.UiRoot.BtnDefault.gameObject:SetActiveEx(true)
    elseif self.CurPageType == self.PageType.GameController then
        local enableInputJoystick = XInputManager.EnableInputJoystick
        self.UiRoot.BtnDefault.gameObject:SetActiveEx(enableInputJoystick)
        self.UiRoot.BtnSave.gameObject:SetActiveEx(enableInputJoystick)
        self.PanelGameControlOperationType.gameObject:SetActiveEx(enableInputJoystick)
        self:InitControllerPanel(false)
    elseif self.CurPageType == self.PageType.Keyboard then
        local enableInputKeyboard = XInputManager.EnableInputKeyboard
        self.UiRoot.BtnDefault.gameObject:SetActiveEx(enableInputKeyboard)
        self.UiRoot.BtnSave.gameObject:SetActiveEx(enableInputKeyboard)
        self.PanelKeyboardOperationType.gameObject:SetActiveEx(enableInputKeyboard)
        self:InitKeyboardPanel()
    end
    self:ShowSubPanel(self.CurPageType)
end

function XUiPanelFightSetPc:ResetToDefault()
    if self.CurPageType == self.PageType.Touch then
        self.DynamicJoystick = XSetConfigs.DefaultDynamicJoystick
        self.JoystickGroup:SelectIndex(self.DynamicJoystick + 1)
    elseif self.CurPageType == self.PageType.GameController then
        self:ResetToDefaultTips(function()
            XInputManager.DefaultKeysSetting(self:GetCurOperationType(), self:GetCurKeySetType())
            XInputManager.DefaultCameraMoveSensitivitySetting(self:GetCurKeySetType())
            self.SliderCameraMoveSensitivityPc.value = self:GetCameraMoveSensitivity()
            self:InitControllerPanel(true)
        end)
    elseif self.CurPageType == self.PageType.Keyboard then
        self:ResetToDefaultTips(function()
            XInputManager.DefaultKeysSetting(self:GetCurOperationType(), CS.KeySetType.Keyboard)
            XInputManager.DefaultCameraMoveSensitivitySetting(CS.KeySetType.Keyboard)
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
    
    local curOperationType = self:GetCurOperationType()
    self.CtrlKeyItemList = self.CtrlKeyItemList or {}
    local list = XSetConfigs.GetControllerMapCfg()

    for id, v in ipairs(list) do
        local grid = self.CtrlKeyItemList[id]
        if curOperationType ~= v.OperationType or not self:IsSameKeySet(v.KeySetTypes) then
            self:SetGridActive(grid, false)
            goto CONTINUE
        end
        
        if v.Type == XSetConfigs.ControllerSetItemType.SetButton then
            local keyCodeType = CS.XInputManager.GetKeyCodeTypeByInt(v.OperationKey, curOperationType)
            if keyCodeType == XSetConfigs.KeyCodeType.NotCustom then
                grid = grid or XUiNotCustomKeyItemHandle.New(CSUnityEngineObjectInstantiate(self.NotCustomKeyItemHandle, self.ControllerSetContent), self.UiRoot)
            else
                grid = grid or XUiBtnKeyItem.New(CSUnityEngineObjectInstantiate(self.BtnKeyItem, self.ControllerSetContent), self.UiRoot)
            end
            
            grid:SetKeySetType(self:GetCurKeySetType())
            grid:Refresh(v, handler(self, self.EditKey), resetTextOnly, curOperationType)
        elseif v.Type == XSetConfigs.ControllerSetItemType.Section then
            grid = grid or CSUnityEngineObjectInstantiate(self.TxtSection, self.ControllerSetContent)
            local txtTitle = grid:Find("TxtTitle"):GetComponent("Text")
            txtTitle.text = v.Title
        elseif v.Type == XSetConfigs.ControllerSetItemType.Slider then
            if not grid then
                self.GridSlider:SetParent(self.ControllerSetContent, false)
                XUiHelper.RegisterSliderChangeEvent(self, self.SliderCameraMoveSensitivity, function(_, value)
                    if value == self:GetCameraMoveSensitivity() then
                        return
                    end
                    self:SetCameraMoveSensitivity(value)
                end)
            end
            self.SliderCameraMoveSensitivity.value = self:GetCameraMoveSensitivity()
            grid = grid or self.GridSlider
        end

        self:SetGridActive(grid, true)
        self.CtrlKeyItemList[id] = grid
        :: CONTINUE ::
    end
    self.BtnKeyItem.gameObject:SetActiveEx(false)
end

function XUiPanelFightSetPc:InitKeyboardPanel(resetTextOnly)
    self:InitDrdSort()
    local curOperationType = self:GetCurOperationType()
    self._KeyboardGridList = self._KeyboardGridList or {}
    local list = XSetConfigs.GetControllerMapCfg()

    for id, item in ipairs(list) do
        local grid = self._KeyboardGridList[id]
        if curOperationType ~= item.OperationType or not self:IsSameKeySet(item.KeySetTypes) then
            self:SetGridActive(grid, false)
            goto CONTINUE
        end
        if item.Type == XSetConfigs.ControllerSetItemType.SetButton then
            local keyCodeType = CS.XInputManager.GetKeyCodeTypeByInt(item.OperationKey, self:GetCurOperationType())
            if keyCodeType == XSetConfigs.KeyCodeType.NotCustom then
                grid = grid or XUiNotCustomKeyItem.New(CSUnityEngineObjectInstantiate(self.NotCustomKeyItem, self.KeyboardSetContent), self.UiRoot)
            elseif keyCodeType == XSetConfigs.KeyCodeType.OneKeyCustom or 
                keyCodeType == XSetConfigs.KeyCodeType.KeyMouseCustom or
                keyCodeType == XSetConfigs.KeyCodeType.SingleKey or
                keyCodeType == XSetConfigs.KeyCodeType.Default
            then
                grid = grid or XUiOneKeyCustomKeyItem.New(CSUnityEngineObjectInstantiate(self.OneKeyCustomKeyItem, self.KeyboardSetContent), self.UiRoot)                
            -- elseif keyCodeType == XSetConfigs.KeyCodeType.Default then
            --     grid = XUiBtnKeyItem.New(CSUnityEngineObjectInstantiate(self.BtnKeyItem, self.KeyboardSetContent), self.UiRoot)
            end
            
            grid:SetKeySetType(CS.KeySetType.Keyboard)
            grid:Refresh(item, handler(self, self.EditKey), resetTextOnly, curOperationType)
        elseif item.Type == XSetConfigs.ControllerSetItemType.Section then
            grid = grid or CSUnityEngineObjectInstantiate(self.TxtSection, self.KeyboardSetContent)
            local txtTitle = grid:Find("TxtTitle"):GetComponent("Text")
            txtTitle.text = item.Title
        elseif item.Type == XSetConfigs.ControllerSetItemType.Slider then
            if not grid then
                self.GridSliderPC:SetParent(self.KeyboardSetContent, false)
                XUiHelper.RegisterSliderChangeEvent(self, self.SliderCameraMoveSensitivityPc, function(_, value)
                    if value == self:GetCameraMoveSensitivity() then
                        return
                    end
                    self:SetCameraMoveSensitivity(value)
                end)
            end
            self.SliderCameraMoveSensitivityPc.value = self:GetCameraMoveSensitivity()
            grid = grid or self.GridSliderPC
        end

        self:SetGridActive(grid, true)
        self._KeyboardGridList[id] = grid
        :: CONTINUE ::
    end
    self.BtnKeyItem.gameObject:SetActiveEx(false)
    self.KeyboardPanelInit = true
end

function XUiPanelFightSetPc:SetGridActive(grid, enable)
    local gameObject = (grid) and (grid.GameObject or grid.gameObject)
    if not gameObject then
        return
    end
    gameObject:SetActiveEx(enable)
end

function XUiPanelFightSetPc:SetEnableInputKeyboard(value)
    XInputManager.SetEnableInputKeyboard(value)
end

function XUiPanelFightSetPc:EditKey(keyCode, targetItem, pressKeyIndex)
    if not pressKeyIndex then
        pressKeyIndex = XSetConfigs.PressKeyIndex.One
    end

    local curOperationType = self:GetCurOperationType()
    
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
                            CS.XInputManager.ClearConflictKey()
                        end,
                        function()
                            CS.XInputManager.SwapConflictKey(curKeySetType, pressKeyIndex, curOperationType)
                            local gridList
                            if curKeySetType == CS.KeySetType.Xbox or curKeySetType == CS.KeySetType.Ps then
                                gridList = self.CtrlKeyItemList
                            elseif curKeySetType == CS.KeySetType.Keyboard then
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
                            XUiManager.TipSuccess(XUiHelper.GetText("SetJoyStickSuccess"))
                        end
                )
            end
        end
    end

    self.TxtInput.text = CS.XTextManager.GetText("SetInputStart")
    self.TxtFunction.text = targetItem.Data.Title

    XInputManager.StartEditKey(self:GetCurKeySetType(), keyCode, pressKeyIndex, cb, curOperationType)
    self:ShowSetKeyTip(true)
    self.CurSelectBtn = targetItem
    self.CurSelectKey = keyCode
end

return XUiPanelFightSetPc