---@class XUiPanelGraphicsSetPc
local XUiPanelGraphicsSetPc = XClass(XUiPanelGraphicsSet, 'XUiPanelGraphicsSetPc')

-- FullScreenWindow     是无边框全屏
-- ExclusiveFullScreen  是独占全屏

function XUiPanelGraphicsSetPc:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._FullScreen = self:IsFullScreen()
    self._Resolution = self:GetCurrentResolution()
    self._DropDownDataProvider = false
    self._IsDirtyPc = false
    self._ResolutionIndex = 1
    self._NoFrameWindowed = XDataCenter.UiPcManager.GetLastNoFrame()
    self:InitPc()
end

function XUiPanelGraphicsSetPc:AutoInitUi()
    self.Super.AutoInitUi(self)
    self.TogFrameRate_3 = self.Transform:Find("SView /Viewport/PanelContent/FrameRateLevel/Array/TGroupResolution/TogFrameRate_3"):GetComponent("Toggle")
    self.ImgResStandX = self.Transform:Find("SView /Viewport/PanelContent/FrameRateLevel/Array/TGroupResolution/TogFrameRate_3/ImgResStand"):GetComponent("Image")
    self.TxtResStandX = self.Transform:Find("SView /Viewport/PanelContent/FrameRateLevel/Array/TGroupResolution/TogFrameRate_3/TxtResStand"):GetComponent("Text")
    self.TogFrameRate_4 = self.Transform:Find("SView /Viewport/PanelContent/FrameRateLevel/Array/TGroupResolution/TogFrameRate_4"):GetComponent("Toggle")
    self.ImgResStandY = self.Transform:Find("SView /Viewport/PanelContent/FrameRateLevel/Array/TGroupResolution/TogFrameRate_4/ImgResStand"):GetComponent("Image")
    self.TxtResStandY = self.Transform:Find("SView /Viewport/PanelContent/FrameRateLevel/Array/TGroupResolution/TogFrameRate_4/TxtResStand"):GetComponent("Text")

    -- 全屏
    self.FullscreenTogGraphics_0 = self.Transform:Find("Jiemian/Shezhi/Array/TGroupResolution/FullscreenTogGraphics_0"):GetComponent("Toggle")
    self.FullscreenTogGraphics_1 = self.Transform:Find("Jiemian/Shezhi/Array/TGroupResolution/FullscreenTogGraphics_1"):GetComponent("Toggle")
    self.FullscreenTogGraphics_2 = self.Transform:Find("Jiemian/Shezhi/Array/TGroupResolution/FullscreenTogGraphics_2"):GetComponent("Button")
    self.FullscreenTogGraphics_3 = self.Transform:Find("Jiemian/Shezhi/Array/TGroupResolution/FullscreenTogGraphics_3"):GetComponent("Toggle")

    if CS.XSettingHelper.ForceWindow then
        self.FullscreenTogGraphics_0.gameObject:SetActiveEx(false)
        self.FullscreenTogGraphics_2.gameObject:SetActiveEx(true)
    else
        self.FullscreenTogGraphics_0.gameObject:SetActiveEx(true)
        self.FullscreenTogGraphics_2.gameObject:SetActiveEx(false)
    end
end

function XUiPanelGraphicsSetPc:InitPc()
    self._Initing = true
    self:InitDropDownResolution()
    self:UpdateToggle()
    self:InitToggleFullScreen()
    self:UpdateDropDownResolution()
    self.UseVSync = CS.XSettingHelper.UseVSync
    self:UpdateVSyncToggle()
    XUiHelper.RegisterClickEvent(self, self.TogVSync, function(isEnable)
        self:OnClickVSync(isEnable)
    end)
    self._Initing = false
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
    self._ResolutionIndex = index
    dropDown.value = index - 1
    dropDown.onValueChanged:AddListener(
            function(index)
                self._IsDirtyPc = true
                -- dropDown从0开始, 故+1
                local resolutionIndex = index + 1
                local size = self._DropDownDataProvider[resolutionIndex]
                self._ResolutionIndex = resolutionIndex
                self._Resolution = size
            end
    )
end

function XUiPanelGraphicsSetPc:InitToggleFullScreen()
    self.FullscreenTogGraphics_3.isOn = self._NoFrameWindowed
    self.FullscreenTogGraphics_0.onValueChanged:AddListener(function()
        if self.FullscreenTogGraphics_0.isOn then
            if self._FullScreen ~= true then
                self._FullScreen = true
                self._IsDirtyPc = true
                self:UpdateDropDownResolution()
            end
        end
        self.FullscreenTogGraphics_3.gameObject:SetActiveEx(self.FullscreenTogGraphics_0.isOn)
    end)

    self.FullscreenTogGraphics_1.onValueChanged:AddListener(function()
        if self.FullscreenTogGraphics_1.isOn then
            if self._FullScreen ~= false then
                self._FullScreen = false
                self._IsDirtyPc = true
                self:UpdateDropDownResolution()
            end
        end
    end)

    self.FullscreenTogGraphics_2.onClick:AddListener(function()
        XUiManager.TipText("PcUnableFullScreen")
    end)

    self.FullscreenTogGraphics_3.onValueChanged:AddListener(function() 
        if not self._Initing then
            self._NoFrameWindowed = self.FullscreenTogGraphics_3.isOn
            self._IsDirtyPc = true
        end
    end)
end

function XUiPanelGraphicsSetPc:UpdateToggle()
    local isFullScreen = self:IsFullScreen()
    self.TGroupResolution:SetAllTogglesOff()
    if isFullScreen then
        self.FullscreenTogGraphics_0.isOn = true
        self.FullscreenTogGraphics_3.gameObject:SetActiveEx(true)
        self.FullscreenTogGraphics_3.isOn = self._NoFrameWindowed
    else
        self.FullscreenTogGraphics_1.isOn = true
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

function XUiPanelGraphicsSetPc:SetFullScreen()
    local isFullScreen = self._FullScreen
    local isNoFrame = self._NoFrameWindowed
    if isFullScreen then
        local deviceWidth, deviceHeight = XDataCenter.UiPcManager.GetDeviceScreenResolution()
        if not isNoFrame then
            XDataCenter.UiPcManager.SetResolution(deviceWidth, deviceHeight, CS.UnityEngine.FullScreenMode.ExclusiveFullScreen)
        else 
            XDataCenter.UiPcManager.SetResolution(deviceWidth, deviceHeight, CS.UnityEngine.FullScreenMode.FullScreenWindow)
        end
    else
        CS.UnityEngine.Screen.fullScreen = isFullScreen
    end
    XDataCenter.UiPcManager.SetNoFrame(isNoFrame)
end

function XUiPanelGraphicsSetPc:CheckDataIsChange()
    return self._IsDirtyPc or XUiPanelGraphicsSetPc.Super.CheckDataIsChange(self)
end

function XUiPanelGraphicsSetPc:UpdateVSyncToggle()
    self.TogVSync.isOn = self.UseVSync
end

function XUiPanelGraphicsSetPc:OnClickVSync()
    self.UseVSync = self.TogVSync.isOn
    self._IsDirtyPc = true
end

function XUiPanelGraphicsSetPc:SaveChange()
    XUiPanelGraphicsSetPc.Super.SaveChange(self)
    if self._FullScreen then
        self:SetFullScreen()
    else
        local resolution = self._DropDownDataProvider[self._ResolutionIndex]
        if resolution then
            if self._Resolution.x ~= resolution.x or self._Resolution.y ~= resolution.y then
                self._Resolution.x = resolution.x
                self._Resolution.y = resolution.y
            end
        end
        XDataCenter.UiPcManager.SetResolution(self._Resolution.x, self._Resolution.y, CS.UnityEngine.FullScreenMode.Windowed)
    end
    CS.XSettingHelper.UseVSync = self.UseVSync
    self._IsDirtyPc = false
end

function XUiPanelGraphicsSetPc:ResetToDefault()
    XUiPanelGraphicsSetPc.Super.ResetToDefault(self)
    self.UseVSync = true
    self.TogVSync.isOn = self.UseVSync
end

function XUiPanelGraphicsSetPc:CancelChange()
    XUiPanelGraphicsSetPc.Super.CancelChange(self)
    self.UseVSync = CS.XSettingHelper.UseVSync
    self.TogVSync.isOn = self.UseVSync
    self.FullscreenTogGraphics_0.isOn = self:IsFullScreen()
    self.FullscreenTogGraphics_1.isOn = not self:IsFullScreen()
    self.FullscreenTogGraphics_3.isOn = XDataCenter.UiPcManager.GetLastNoFrame()
    self._IsDirtyPc = false
end

return XUiPanelGraphicsSetPc
