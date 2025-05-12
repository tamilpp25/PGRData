local XUiBigWorldSetPanelGraphics = require("XUi/XUiBigWorld/XSet/SubUi/XUiBigWorldSetPanelGraphics")

-- region XClass
---@class XUiBigWorldSetPanelGraphicsPC : XUiBigWorldSetPanelGraphics
---@field TGroupAuto XUiButtonGroup
---@field TogQuality_1 XUiComponent.XUiButton
---@field TogQuality_2 XUiComponent.XUiButton
---@field TogQuality_3 XUiComponent.XUiButton
---@field TogQuality_4 XUiComponent.XUiButton
---@field TogQuality_5 XUiComponent.XUiButton
---@field TogQuality_0 XUiComponent.XUiButton
---@field TGroupGraphics XUiButtonGroup
---@field TogGraphics_0 XUiComponent.XUiButton
---@field TogGraphics_1 XUiComponent.XUiButton
---@field TogGraphics_2 XUiComponent.XUiButton
---@field TogGraphics_3 XUiComponent.XUiButton
---@field TogGraphics_4 XUiComponent.XUiButton
---@field TGroupResolution XUiButtonGroup
---@field TogResolution_1 XUiComponent.XUiButton
---@field TogResolution_2 XUiComponent.XUiButton
---@field TogResolution_3 XUiComponent.XUiButton
---@field TogResolution_4 XUiComponent.XUiButton
---@field TGroupShadow XUiButtonGroup
---@field TogShadow_1 XUiComponent.XUiButton
---@field TogShadow_2 XUiComponent.XUiButton
---@field TogShadow_3 XUiComponent.XUiButton
---@field TogShadow_4 XUiComponent.XUiButton
---@field TGroupEffect XUiButtonGroup
---@field TogEffect_1 XUiComponent.XUiButton
---@field TogEffect_2 XUiComponent.XUiButton
---@field TogEffect_3 XUiComponent.XUiButton
---@field TogEffect_4 XUiComponent.XUiButton
---@field TGroupOtherEffect XUiButtonGroup
---@field TogOtherEffect_1 XUiComponent.XUiButton
---@field TogOtherEffect_2 XUiComponent.XUiButton
---@field TogOtherEffect_3 XUiComponent.XUiButton
---@field TogOtherEffect_4 XUiComponent.XUiButton
---@field TGroupMirror XUiButtonGroup
---@field TogMirror_1 XUiComponent.XUiButton
---@field TogMirror_2 XUiComponent.XUiButton
---@field TogMirror_3 XUiComponent.XUiButton
---@field TogMirror_4 XUiComponent.XUiButton
---@field TGroupFrameRate XUiButtonGroup
---@field TogFrameRate_0 XUiComponent.XUiButton
---@field TogFrameRate_1 XUiComponent.XUiButton
---@field TogFrameRate_2 XUiComponent.XUiButton
---@field TogFrameRate_3 XUiComponent.XUiButton
---@field TogFrameRate_4 XUiComponent.XUiButton
---@field TGroupBloom XUiButtonGroup
---@field TogBloom_1 XUiComponent.XUiButton
---@field TogBloom_2 XUiComponent.XUiButton
---@field TogBloom_3 XUiComponent.XUiButton
---@field TGroupDistortion XUiButtonGroup
---@field TogDistortion_1 XUiComponent.XUiButton
---@field TogDistortion_2 XUiComponent.XUiButton
---@field TogDistortion_3 XUiComponent.XUiButton
---@field TogHDR UnityEngine.UI.Toggle
---@field TogFXAA UnityEngine.UI.Toggle
---@field TogVSync UnityEngine.UI.Toggle
---@field TogFullscreen_1 UnityEngine.UI.Toggle
---@field TogFullscreen_0 UnityEngine.UI.Toggle
---@field TGroupFullscreen UnityEngine.UI.ToggleGroup
---@field DrdSort UnityEngine.UI.Dropdown
---@field GraphicsLevel UnityEngine.RectTransform
---@field ResolutionLevel UnityEngine.RectTransform
---@field ShadowLevel UnityEngine.RectTransform
---@field EffectLevel UnityEngine.RectTransform
---@field OtherEffectLevel UnityEngine.RectTransform
---@field MirrorLevel UnityEngine.RectTransform
---@field FrameRateLevel UnityEngine.RectTransform
---@field BloomLevel UnityEngine.RectTransform
---@field DistortionLevel UnityEngine.RectTransform
---@field PanelLiangge UnityEngine.RectTransform
---@field PanelVSync UnityEngine.RectTransform
---@field SafeAreaContentPanel XUiSafeAreaAdapter
---@field ParentUi XUiBigWorldSet
---@field Super XUiBigWorldSetPanelGraphics
---@field _Control XBigWorldSetControl
local XUiBigWorldSetPanelGraphicsPC = XMVCA.XBigWorldUI:Register(XUiBigWorldSetPanelGraphics,
    "UiBigWorldSetPanelGraphicsPC")

-- endregion

function XUiBigWorldSetPanelGraphicsPC:OnAwake()
    self.Super.OnAwake(self)

    self._DropDownProviderData = false

    self:_InitDropdownResolution()
end

function XUiBigWorldSetPanelGraphicsPC:OnTGroupFrameRateClick(index)
    self._Setting:SetFrameRateLevelValue(index - 1)
end

function XUiBigWorldSetPanelGraphicsPC:OnTGroupGraphicsClick(index)
    self._Setting:SetGraphicsLevelValue(index - 1)
end

function XUiBigWorldSetPanelGraphicsPC:OnDropdownResolutionValueChanged(index)
    self._Setting:SetScreenResolutionValue(self._DropDownProviderData[index + 1])
end

function XUiBigWorldSetPanelGraphicsPC:OnTogFullScreenClick(value)
    if value then
        self._Setting:SetFullScreenValue(true)
        self.ImgMask.gameObject:SetActiveEx(true)
    end
end

function XUiBigWorldSetPanelGraphicsPC:OnTogWindowScreenClick(value)
    if value then
        self._Setting:SetFullScreenValue(false)
        self.ImgMask.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldSetPanelGraphicsPC:OnTogVSyncClick(value)
    self._Setting:SetVSyncValue(value == 1)
end

function XUiBigWorldSetPanelGraphicsPC:_InitTogGroup()
    self.Super._InitTogGroup(self)

    table.insert(self._TogQualityGroup, self.TogQuality_5)
    table.insert(self._TogGraphicsGroup, 1, self.TogGraphics_0)

    self._TogFrameRateGroup = {
        self.TogFrameRate_0,
        self.TogFrameRate_1,
        self.TogFrameRate_2,
        self.TogFrameRate_3,
        self.TogFrameRate_4,
    }
end

function XUiBigWorldSetPanelGraphicsPC:_InitDropdownResolution()
    local unityDropdown = CS.UnityEngine.UI.Dropdown

    self.DrdSort:ClearOptions()
    self._DropDownProviderData = self._Control:GetResolutionSizeArray()
    for i = 1, #self._DropDownProviderData do
        local option = unityDropdown.OptionData()
        local text = self._Control:GetResolutionSizeText(self._DropDownProviderData[i])

        option.text = text
        self.DrdSort.options:Add(option)
    end
end

function XUiBigWorldSetPanelGraphicsPC:_RegisterButtonClicks()
    self.Super._RegisterButtonClicks(self)
    self:_RegisterTGroupFrameRate()
    self:_RegisterToggleFullScreen()
    self:_RegisterToggleWindowScreen()
    self:_RegisterToggleVSyncScreen()
    self:_RegisterDropdownResolution()
end

function XUiBigWorldSetPanelGraphicsPC:_RegisterTGroupFrameRate()
    self.TGroupFrameRate:Init(self._TogFrameRateGroup, Handler(self, self.OnTGroupFrameRateClick))
end

function XUiBigWorldSetPanelGraphicsPC:_RegisterDropdownResolution()
    self.DrdSort.onValueChanged:AddListener(Handler(self, self.OnDropdownResolutionValueChanged))
end

function XUiBigWorldSetPanelGraphicsPC:_RegisterToggleFullScreen()
    self.TogFullscreen_0.onValueChanged:AddListener(Handler(self, self.OnTogFullScreenClick))
end

function XUiBigWorldSetPanelGraphicsPC:_RegisterToggleWindowScreen()
    self.TogFullscreen_1.onValueChanged:AddListener(Handler(self, self.OnTogWindowScreenClick))
end

function XUiBigWorldSetPanelGraphicsPC:_RegisterToggleVSyncScreen()
    self.TogVSync.CallBack = Handler(self, self.OnTogVSyncClick)
end

function XUiBigWorldSetPanelGraphicsPC:_RegisterToggleFrameRate()
end

function XUiBigWorldSetPanelGraphicsPC:_Refresh()
    self.Super._Refresh(self)
    self:_RefreshToggleVSync()
    self:_RefreshToggleFullScreen()
    self:_RefreshDropdownResolution()
end

function XUiBigWorldSetPanelGraphicsPC:_RefreshOther()
    self.Super._RefreshOther(self)
    self:_RefreshFrameRateGroup()
end

function XUiBigWorldSetPanelGraphicsPC:_RefreshGraphicsGroup()
    self.TGroupGraphics:SelectIndex(self._Setting:GetGraphicsLevelValue() + 1, false)
end

function XUiBigWorldSetPanelGraphicsPC:_RefreshToggleFrameRate()
end

function XUiBigWorldSetPanelGraphicsPC:_RefreshFrameRateGroup()
    self.TGroupFrameRate:SelectIndex(self._Setting:GetFrameRateLevelValue() + 1, false)
end

function XUiBigWorldSetPanelGraphicsPC:_RefreshToggleFullScreen()
    local isFullScreen = self._Setting:GetFullScreenValue()

    self.TogFullscreen_0.isOn = isFullScreen
    self.TogFullscreen_1.isOn = not isFullScreen
end

function XUiBigWorldSetPanelGraphicsPC:_RefreshToggleVSync()
    local isVSync = self._Setting:GetVSyncValue()

    if isVSync then
        self.TogVSync:SetButtonState(CS.UiButtonState.Select)
    else
        self.TogVSync:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiBigWorldSetPanelGraphicsPC:_RefreshDropdownResolution()
    local isFullScreen = self._Setting:GetFullScreenValue()

    if not isFullScreen then
        local currentIndex = self._Control:GetResolutionSizeCurrentIndex()

        self.ImgMask.gameObject:SetActiveEx(false)
        self.DrdSort.value = currentIndex - 1
    else
        self.ImgMask.gameObject:SetActiveEx(true)
    end
end

return XUiBigWorldSetPanelGraphicsPC
