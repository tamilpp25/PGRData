-- region XClass
---@class XUiBigWorldSetPanelGraphics : XBigWorldUi
---@field TogQuality_1 XUiComponent.XUiButton
---@field TogQuality_2 XUiComponent.XUiButton
---@field TogQuality_3 XUiComponent.XUiButton
---@field TogQuality_4 XUiComponent.XUiButton
---@field TogQuality_0 XUiComponent.XUiButton
---@field TGroupAuto XUiButtonGroup
---@field TGroupGraphics XUiButtonGroup
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
---@field TogFrameRate UnityEngine.UI.Toggle
---@field PanelLiangge UnityEngine.RectTransform
---@field DistortionLevel UnityEngine.RectTransform
---@field OtherEffectLevel UnityEngine.RectTransform
---@field EffectLevel UnityEngine.RectTransform
---@field ResolutionLevel UnityEngine.RectTransform
---@field GraphicsLevel UnityEngine.RectTransform
---@field ShadowLevel UnityEngine.RectTransform
---@field MirrorLevel UnityEngine.RectTransform
---@field BloomLevel UnityEngine.RectTransform
---@field SafeAreaContentPanel XUiSafeAreaAdapter
---@field ParentUi XUiBigWorldSet
---@field _Control XBigWorldSetControl
local XUiBigWorldSetPanelGraphics = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldSetPanelGraphics")

-- endregion

function XUiBigWorldSetPanelGraphics:OnAwake()
    ---@type XBWGraphicsSetting
    self._Setting = false

    self:_InitTogGroup()
    self:_RegisterButtonClicks()
end

function XUiBigWorldSetPanelGraphics:OnStart()
    self._Setting = self._Control:GetSettingBySetType(XEnumConst.BWSetting.SetType.Graphics)
end

function XUiBigWorldSetPanelGraphics:OnEnable()
    self._Control:RefreshSpecialScreenOff(self.SafeAreaContentPanel)
    self:_Refresh()
    self:_RefreshQualityTag()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldSetPanelGraphics:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldSetPanelGraphics:OnDestroy()
end

-- region 按钮事件

function XUiBigWorldSetPanelGraphics:OnTGroupAutoClick(index)
    self._Setting:SetGraphicsQualityValue(index - 1)
    self:_RefreshOther()
end

function XUiBigWorldSetPanelGraphics:OnTGroupGraphicsClick(index)
    self._Setting:SetGraphicsLevelValue(index)
    self:_RefreshAutoGroup()
end

function XUiBigWorldSetPanelGraphics:OnTGroupResolutionClick(index)
    self._Setting:SetResolutionLevelValue(index - 1)
    self:_RefreshAutoGroup()
end

function XUiBigWorldSetPanelGraphics:OnTGroupShadowClick(index)
    self._Setting:SetShadowLevelValue(index - 1)
    self:_RefreshAutoGroup()
end

function XUiBigWorldSetPanelGraphics:OnTGroupEffectClick(index)
    self._Setting:SetEffectLevelValue(index - 1)
    self:_RefreshAutoGroup()
end

function XUiBigWorldSetPanelGraphics:OnTGroupOtherEffectClick(index)
    self._Setting:SetOtherEffectLevelValue(index - 1)
    self:_RefreshAutoGroup()
end

function XUiBigWorldSetPanelGraphics:OnTGroupMirrorClick(index)
    self._Setting:SetMirrorLevelValue(index - 1)
    self:_RefreshAutoGroup()
end

function XUiBigWorldSetPanelGraphics:OnTGroupBloomClick(index)
    self._Setting:SetBloomLevelValue(index - 1)
    self:_RefreshAutoGroup()
end

function XUiBigWorldSetPanelGraphics:OnTGroupDistortionClick(index)
    self._Setting:SetDistortionLevelValue(index - 1)
    self:_RefreshAutoGroup()
end

function XUiBigWorldSetPanelGraphics:OnTogHDRClick(value)
    self._Setting:SetHDRValue(value == 1)
    self:_RefreshAutoGroup()
end

function XUiBigWorldSetPanelGraphics:OnTogFXAAClick(value)
    self._Setting:SetFAXXValue(value == 1)
    self:_RefreshAutoGroup()
end

function XUiBigWorldSetPanelGraphics:OnTogFrameRateClick(value)
    if value == 1 then
        self._Setting:SetFrameRateLevelValue(XEnumConst.BWSetting.GraphicsFrameRate.Middle)
    else
        self._Setting:SetFrameRateLevelValue(XEnumConst.BWSetting.GraphicsFrameRate.Lowest)
    end
    self:_RefreshAutoGroup()
end

-- endregion

function XUiBigWorldSetPanelGraphics:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:_RegisterTGroupAuto()
    self:_RegisterTGroupGraphics()
    self:_RegisterTGroupResolution()
    self:_RegisterTGroupShadow()
    self:_RegisterTGroupEffect()
    self:_RegisterTGroupOtherEffect()
    self:_RegisterTGroupMirror()
    self:_RegisterTGroupBloom()
    self:_RegisterTGroupDistortion()
    self:_RegisterToggleHDR()
    self:_RegisterToggleFXAA()
    self:_RegisterToggleFrameRate()
end

function XUiBigWorldSetPanelGraphics:_RegisterTGroupAuto()
    self.TGroupAuto:Init(self._TogQualityGroup, Handler(self, self.OnTGroupAutoClick))
end

function XUiBigWorldSetPanelGraphics:_RegisterTGroupGraphics()
    self.TGroupGraphics:Init(self._TogGraphicsGroup, Handler(self, self.OnTGroupGraphicsClick))
end

function XUiBigWorldSetPanelGraphics:_RegisterTGroupResolution()
    self.TGroupResolution:Init(self._TogResolutionGroup, Handler(self, self.OnTGroupResolutionClick))
end

function XUiBigWorldSetPanelGraphics:_RegisterTGroupShadow()
    self.TGroupShadow:Init(self._TogShadowGroup, Handler(self, self.OnTGroupShadowClick))
end

function XUiBigWorldSetPanelGraphics:_RegisterTGroupEffect()
    self.TGroupEffect:Init(self._TogEffectGroup, Handler(self, self.OnTGroupEffectClick))
end

function XUiBigWorldSetPanelGraphics:_RegisterTGroupOtherEffect()
    self.TGroupOtherEffect:Init(self._TogOtherEffectGroup, Handler(self, self.OnTGroupOtherEffectClick))
end

function XUiBigWorldSetPanelGraphics:_RegisterTGroupMirror()
    self.TGroupMirror:Init(self._TogMirrorGroup, Handler(self, self.OnTGroupMirrorClick))
end

function XUiBigWorldSetPanelGraphics:_RegisterTGroupBloom()
    self.TGroupBloom:Init(self._TogBloomGroup, Handler(self, self.OnTGroupBloomClick))
end

function XUiBigWorldSetPanelGraphics:_RegisterTGroupDistortion()
    self.TGroupDistortion:Init(self._TogDistortionGroup, Handler(self, self.OnTGroupDistortionClick))
end

function XUiBigWorldSetPanelGraphics:_RegisterToggleHDR()
    self.TogHDR.CallBack = Handler(self, self.OnTogHDRClick)
end

function XUiBigWorldSetPanelGraphics:_RegisterToggleFXAA()
    self.TogFXAA.CallBack = Handler(self, self.OnTogFXAAClick)
end

function XUiBigWorldSetPanelGraphics:_RegisterToggleFrameRate()
    self.TogFrameRate.CallBack = Handler(self, self.OnTogFrameRateClick)
end

function XUiBigWorldSetPanelGraphics:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESET, self._Refresh, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESTORE, self._Refresh, self)
end

function XUiBigWorldSetPanelGraphics:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESET, self._Refresh, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESTORE, self._Refresh, self)
end

function XUiBigWorldSetPanelGraphics:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldSetPanelGraphics:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldSetPanelGraphics:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldSetPanelGraphics:_Refresh()
    self:_RefreshAutoGroup()
    self:_RefreshOther()
end

function XUiBigWorldSetPanelGraphics:_RefreshOther()
    self:_RefreshGraphicsGroup()
    self:_RefreshResolutionGroup()
    self:_RefreshShadowGroup()
    self:_RefreshEffectGroup()
    self:_RefreshOtherEffectGroup()
    self:_RefreshMirrorGroup()
    self:_RefreshBloomGroup()
    self:_RefreshDistortionGroup()
    self:_RefreshToggleHDR()
    self:_RefreshToggleFXAA()
    self:_RefreshToggleFrameRate()
end

function XUiBigWorldSetPanelGraphics:_RefreshAutoGroup()
    local index = self._Setting:GetGraphicsQualityValue() + 1

    self.TGroupAuto:SelectIndex(index)
end

function XUiBigWorldSetPanelGraphics:_RefreshGraphicsGroup()
    self.TGroupGraphics:SelectIndex(self._Setting:GetGraphicsLevelValue(), false)
end

function XUiBigWorldSetPanelGraphics:_RefreshResolutionGroup()
    self.TGroupResolution:SelectIndex(self._Setting:GetResolutionLevelValue() + 1, false)
end

function XUiBigWorldSetPanelGraphics:_RefreshShadowGroup()
    self.TGroupShadow:SelectIndex(self._Setting:GetShadowLevelValue() + 1, false)
end

function XUiBigWorldSetPanelGraphics:_RefreshEffectGroup()
    self.TGroupEffect:SelectIndex(self._Setting:GetEffectLevelValue() + 1, false)
end

function XUiBigWorldSetPanelGraphics:_RefreshOtherEffectGroup()
    self.TGroupOtherEffect:SelectIndex(self._Setting:GetOtherEffectLevelValue() + 1, false)
end

function XUiBigWorldSetPanelGraphics:_RefreshMirrorGroup()
    self.TGroupMirror:SelectIndex(self._Setting:GetMirrorLevelValue() + 1, false)
end

function XUiBigWorldSetPanelGraphics:_RefreshBloomGroup()
    self.TGroupBloom:SelectIndex(self._Setting:GetBloomLevelValue() + 1, false)
end

function XUiBigWorldSetPanelGraphics:_RefreshDistortionGroup()
    self.TGroupDistortion:SelectIndex(self._Setting:GetDistortionLevelValue() + 1, false)
end

function XUiBigWorldSetPanelGraphics:_RefreshToggleHDR()
    if self._Setting:GetHDRValue() then
        self.TogHDR:SetButtonState(CS.UiButtonState.Select)
    else
        self.TogHDR:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiBigWorldSetPanelGraphics:_RefreshToggleFXAA()
    if self._Setting:GetFAXXValue() then
        self.TogFXAA:SetButtonState(CS.UiButtonState.Select)
    else
        self.TogFXAA:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiBigWorldSetPanelGraphics:_RefreshToggleFrameRate()
    if self._Setting:GetFrameRateLevelValue() >= XEnumConst.BWSetting.GraphicsFrameRate.Middle then
        self.TogFrameRate:SetButtonState(CS.UiButtonState.Select)
    else
        self.TogFrameRate:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiBigWorldSetPanelGraphics:_RefreshQualityTag()
    local quality = self._Setting:GetDefaultGraphicsQualityValue() + 1

    for index, tog in pairs(self._TogQualityGroup) do
        tog:ShowTag(quality == index)
    end
end

function XUiBigWorldSetPanelGraphics:_InitTogGroup()
    self._TogQualityGroup = {
        self.TogQuality_0,
        self.TogQuality_1,
        self.TogQuality_2,
        self.TogQuality_3,
        self.TogQuality_4,
    }
    self._TogGraphicsGroup = {
        self.TogGraphics_1,
        self.TogGraphics_2,
        self.TogGraphics_3,
        self.TogGraphics_4,
    }
    self._TogResolutionGroup = {
        self.TogResolution_1,
        self.TogResolution_2,
        self.TogResolution_3,
        self.TogResolution_4,
    }
    self._TogShadowGroup = {
        self.TogShadow_1,
        self.TogShadow_2,
        self.TogShadow_3,
        self.TogShadow_4,
    }
    self._TogEffectGroup = {
        self.TogEffect_1,
        self.TogEffect_2,
        self.TogEffect_3,
        self.TogEffect_4,
    }
    self._TogOtherEffectGroup = {
        self.TogOtherEffect_1,
        self.TogOtherEffect_2,
        self.TogOtherEffect_3,
        self.TogOtherEffect_4,
    }
    self._TogMirrorGroup = {
        self.TogMirror_1,
        self.TogMirror_2,
        self.TogMirror_3,
        self.TogMirror_4,
    }
    self._TogBloomGroup = {
        self.TogBloom_1,
        self.TogBloom_2,
        self.TogBloom_3,
    }
    self._TogDistortionGroup = {
        self.TogDistortion_1,
        self.TogDistortion_2,
        self.TogDistortion_3,
    }
end

return XUiBigWorldSetPanelGraphics
