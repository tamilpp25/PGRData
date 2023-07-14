---@class XUiPanelGraphicsSetPc
local XUiPanelGraphicsSetPc = XClass(XUiPanelGraphicsSet, 'XUiPanelGraphicsSetPc')

function XUiPanelGraphicsSetPc:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._FullScreen = self:IsFullScreen()
    self._Resolution = self:GetCurrentResolution()
    self._DropDownDataProvider = false
    self._IsDirtyPc = false
    self:InitPc()
end

function XUiPanelGraphicsSetPc:InitPc()
    self:InitDropDownResolution()
    self:InitToggleFullScreen()
    self:UpdateToggle()
    self:UpdateDropDownResolution()
end

function XUiPanelGraphicsSetPc:InitDropDownResolution()
    local dataProvider, index = self:GetResolutionArray()
    self._DropDownDataProvider = dataProvider
    local UnityDropdown = CS.UnityEngine.UI.Dropdown
    local dropDown = self.DrdSort
    dropDown:ClearOptions()
    for i = 1, #self._DropDownDataProvider do
        local op = UnityDropdown.OptionData()
        local text = self:GetTextResolution(self._DropDownDataProvider[i])
        op.text = text
        dropDown.options:Add(op)
    end
    dropDown.value = index - 1
    dropDown.onValueChanged:AddListener(
            function(index)
                self._IsDirtyPc = true
                -- dropDown从0开始, 故+1
                local resolutionIndex = index + 1
                local size = self._DropDownDataProvider[resolutionIndex]
                self._Resolution = size
            end
    )
end

function XUiPanelGraphicsSetPc:InitToggleFullScreen()
    self.TogGraphics_0.onValueChanged:AddListener(function()
        if self.TogGraphics_0.isOn then
            if self._FullScreen ~= true then
                self._FullScreen = true
                self._IsDirtyPc = true
                self:UpdateDropDownResolution()
            end
        end
    end)
    self.TogGraphics_1.onValueChanged:AddListener(function()
        if self.TogGraphics_1.isOn then
            if self._FullScreen ~= false then
                self._FullScreen = false
                self._IsDirtyPc = true
                self:UpdateDropDownResolution()
            end
        end
    end)
end

function XUiPanelGraphicsSetPc:UpdateToggle()
    local isFullScreen = self:IsFullScreen()
    self.TGroupResolution:SetAllTogglesOff()
    if isFullScreen then
        self.TogGraphics_0.isOn = true
    else
        self.TogGraphics_1.isOn = true
    end
end

function XUiPanelGraphicsSetPc:IsFullScreen()
    return CS.UnityEngine.Screen.fullScreen
end

function XUiPanelGraphicsSetPc:UpdateDropDownResolution()
    local isFullScreen = self._FullScreen
    local dropDown = self.DrdSort
    if isFullScreen then
        dropDown.gameObject:SetActiveEx(false)
    else
        dropDown.gameObject:SetActiveEx(true)
    end
end

function XUiPanelGraphicsSetPc:GetCurrentResolution()
    local UnityScreen = CS.UnityEngine.Screen
    return { x = UnityScreen.width, y = UnityScreen.height }
end

function XUiPanelGraphicsSetPc:GetTextResolution(size)
    return string.format('%d x %d', size.x, size.y)
end

function XUiPanelGraphicsSetPc:GetResolutionArray()
    local currentSize = self:GetCurrentResolution()
    local defaultSizeArray = XDataCenter.UiPcManager.GetTabUiPcResolution()
    local defaultSizeIndex = false
    for i = 1, #defaultSizeArray do
        if defaultSizeArray[i].x == currentSize.x and defaultSizeArray[i].y == currentSize.y then
            defaultSizeIndex = i
            break
        end
    end
    if not defaultSizeIndex then
        defaultSizeIndex = #defaultSizeArray
    end
    return defaultSizeArray, defaultSizeIndex
end

function XUiPanelGraphicsSetPc:SetFullScreen(isFullScreen)
    if isFullScreen then
        local deviceWidth, deviceHeight = XDataCenter.UiPcManager.GetDeviceScreenResolution()
        self:SetResolution(deviceWidth, deviceHeight, true)
    else
        CS.UnityEngine.Screen.fullScreen = isFullScreen
    end
end

function XUiPanelGraphicsSetPc:SetResolution(x, y, isFullScreen)
    CS.UnityEngine.Screen.SetResolution(x, y, isFullScreen or false)
end

function XUiPanelGraphicsSetPc:CheckDataIsChange()
    return self._IsDirtyPc or XUiPanelGraphicsSetPc.Super.CheckDataIsChange(self)
end

function XUiPanelGraphicsSetPc:SaveChange()
    XUiPanelGraphicsSetPc.Super.SaveChange(self)
    if self._FullScreen then
        self:SetFullScreen(true)
    else
        self:SetResolution(self._Resolution.x, self._Resolution.y)
    end
    self._IsDirtyPc = false
end

return XUiPanelGraphicsSetPc
