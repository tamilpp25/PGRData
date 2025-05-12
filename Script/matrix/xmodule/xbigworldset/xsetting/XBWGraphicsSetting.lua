local XBWSettingBase = require("XModule/XBigWorldSet/XSetting/XBWSettingBase")
local XBWSettingValue = require("XModule/XBigWorldSet/XSetting/XBWSettingValue")

---@class XBWGraphicsSetting : XBWSettingBase
local XBWGraphicsSetting = XClass(XBWSettingBase, "XBWGraphicsSetting")

function XBWGraphicsSetting:InitValue()
    self:_InitGraphicsQualityValue()
    self:_InitVSyncValue()
    self:_InitFullScreenValue()
    self:_InitScreenResolutionValue()
end

function XBWGraphicsSetting:Reset()
    self._GraphicsQualityValue:Reset()
    self._GraphicsLevelValue:Reset()
    self._EffectLevelValue:Reset()
    self._OtherEffectLevelValue:Reset()
    self._ShadowLevelValue:Reset()
    self._MirrorLevelValue:Reset()
    self._ResolutionLevelValue:Reset()
    self._DistortionLevelValue:Reset()
    self._FrameRateLevelValue:Reset()
    self._BloomLevelValue:Reset()
    self._HDRValue:Reset()
    self._FAXXValue:Reset()

    if self._VSyncValue then
        self._VSyncValue:Reset()
    end
    if self._FullScreenValue then
        self._FullScreenValue:Reset()
    end
    if self._ScreenResolutionValue then
        self._ScreenResolutionValue:Reset()
    end
end

function XBWGraphicsSetting:RestoreDefault()
    self._GraphicsQualityValue:RestoreDefault()
    self._GraphicsLevelValue:RestoreDefault()
    self._EffectLevelValue:RestoreDefault()
    self._OtherEffectLevelValue:RestoreDefault()
    self._ShadowLevelValue:RestoreDefault()
    self._MirrorLevelValue:RestoreDefault()
    self._ResolutionLevelValue:RestoreDefault()
    self._DistortionLevelValue:RestoreDefault()
    self._FrameRateLevelValue:RestoreDefault()
    self._BloomLevelValue:RestoreDefault()
    self._HDRValue:RestoreDefault()
    self._FAXXValue:RestoreDefault()

    if self._VSyncValue then
        self._VSyncValue:RestoreDefault()
    end
end

function XBWGraphicsSetting:SaveChange()
    local quality = self:GetGraphicsQualityValue()

    if quality == XEnumConst.BWSetting.GraphicsQuality.Custom then
        local setting = self:__ToCsQualitySetting()

        CS.XQualityManager.Instance:SetQualitySettings(quality, setting)
    else
        CS.XQualityManager.Instance:SetQualitySettings(quality)
    end

    self._GraphicsQualityValue:SaveChange()
    self._GraphicsLevelValue:SaveChange()
    self._EffectLevelValue:SaveChange()
    self._OtherEffectLevelValue:SaveChange()
    self._ShadowLevelValue:SaveChange()
    self._MirrorLevelValue:SaveChange()
    self._ResolutionLevelValue:SaveChange()
    self._DistortionLevelValue:SaveChange()
    self._FrameRateLevelValue:SaveChange()
    self._BloomLevelValue:SaveChange()
    self._HDRValue:SaveChange()
    self._FAXXValue:SaveChange()

    if self._VSyncValue then
        if self._VSyncValue:IsChanged() then
            CS.XSettingHelper.UseVSync = self:GetVSyncValue()
        end

        self._VSyncValue:SaveChange()
    end
    if self._FullScreenValue then
        local isFullScreen = self:GetFullScreenValue()

        if isFullScreen then
            self:__ChangeFullScreen()
        else
            self:__ChangeWindowScreen()
        end

        self._FullScreenValue:SaveChange()
    end
end

function XBWGraphicsSetting:IsChanged()
    if self._GraphicsQualityValue:IsChanged() then
        return true
    end
    if self._GraphicsLevelValue:IsChanged() then
        return true
    end
    if self._EffectLevelValue:IsChanged() then
        return true
    end
    if self._OtherEffectLevelValue:IsChanged() then
        return true
    end
    if self._ShadowLevelValue:IsChanged() then
        return true
    end
    if self._MirrorLevelValue:IsChanged() then
        return true
    end
    if self._ResolutionLevelValue:IsChanged() then
        return true
    end
    if self._DistortionLevelValue:IsChanged() then
        return true
    end
    if self._FrameRateLevelValue:IsChanged() then
        return true
    end
    if self._FrameRateLevelValue:IsChanged() then
        return true
    end
    if self._VSyncValue and self._VSyncValue:IsChanged() then
        return true
    end
    if self._FullScreenValue and self._FullScreenValue:IsChanged() then
        return true
    end
    if self._ScreenResolutionValue and self._ScreenResolutionValue:IsChanged() then
        return true
    end
    if self._HDRValue:IsChanged() then
        return true
    end
    if self._FAXXValue:IsChanged() then
        return true
    end

    return false
end

-- region Getter/Setter

function XBWGraphicsSetting:GetGraphicsQualityValue()
    return self._GraphicsQualityValue:GetValue()
end

function XBWGraphicsSetting:GetDefaultGraphicsQualityValue()
    return self._GraphicsQualityValue:GetDefaultValue()
end

function XBWGraphicsSetting:SetGraphicsQualityValue(value)
    self._GraphicsQualityValue:SetValue(value)
end

function XBWGraphicsSetting:GetHDRValue()
    return self._HDRValue:GetValue()
end

function XBWGraphicsSetting:SetHDRValue(value)
    self._HDRValue:SetValue(value)
end

function XBWGraphicsSetting:GetFAXXValue()
    return self._FAXXValue:GetValue()
end

function XBWGraphicsSetting:SetFAXXValue(value)
    self._FAXXValue:SetValue(value)
end

function XBWGraphicsSetting:GetEffectLevelValue()
    return self._EffectLevelValue:GetValue()
end

function XBWGraphicsSetting:SetEffectLevelValue(value)
    self._EffectLevelValue:SetValue(value)
end

function XBWGraphicsSetting:GetOtherEffectLevelValue()
    return self._OtherEffectLevelValue:GetValue()
end

function XBWGraphicsSetting:SetOtherEffectLevelValue(value)
    self._OtherEffectLevelValue:SetValue(value)
end

function XBWGraphicsSetting:GetGraphicsLevelValue()
    return self._GraphicsLevelValue:GetValue()
end

function XBWGraphicsSetting:SetGraphicsLevelValue(value)
    self._GraphicsLevelValue:SetValue(value)
end

function XBWGraphicsSetting:GetShadowLevelValue()
    return self._ShadowLevelValue:GetValue()
end

function XBWGraphicsSetting:SetShadowLevelValue(value)
    self._ShadowLevelValue:SetValue(value)
end

function XBWGraphicsSetting:GetMirrorLevelValue()
    return self._MirrorLevelValue:GetValue()
end

function XBWGraphicsSetting:SetMirrorLevelValue(value)
    self._MirrorLevelValue:SetValue(value)
end

function XBWGraphicsSetting:GetResolutionLevelValue()
    return self._ResolutionLevelValue:GetValue()
end

function XBWGraphicsSetting:SetResolutionLevelValue(value)
    self._ResolutionLevelValue:SetValue(value)
end

function XBWGraphicsSetting:GetDistortionLevelValue()
    return self._DistortionLevelValue:GetValue()
end

function XBWGraphicsSetting:SetDistortionLevelValue(value)
    self._DistortionLevelValue:SetValue(value)
end

function XBWGraphicsSetting:GetFrameRateLevelValue()
    return self._FrameRateLevelValue:GetValue()
end

function XBWGraphicsSetting:SetFrameRateLevelValue(value)
    self._FrameRateLevelValue:SetValue(value)
end

function XBWGraphicsSetting:GetBloomLevelValue()
    return self._BloomLevelValue:GetValue()
end

function XBWGraphicsSetting:SetBloomLevelValue(value)
    self._BloomLevelValue:SetValue(value)
end

function XBWGraphicsSetting:GetVSyncValue()
    if self._VSyncValue then
        return self._VSyncValue:GetValue()
    end

    return false
end

function XBWGraphicsSetting:SetVSyncValue(value)
    if self._VSyncValue then
        return self._VSyncValue:SetValue(value)
    end
end

function XBWGraphicsSetting:GetFullScreenValue()
    if self._FullScreenValue then
        return self._FullScreenValue:GetValue()
    end

    return false
end

function XBWGraphicsSetting:SetFullScreenValue(value)
    if self._FullScreenValue then
        self._FullScreenValue:SetValue(value)
    end
end

function XBWGraphicsSetting:GetScreenResolutionValue()
    if self._ScreenResolutionValue then
        return self._ScreenResolutionValue:GetValue()
    end

    return nil
end

function XBWGraphicsSetting:SetScreenResolutionValue(value)
    if self._ScreenResolutionValue then
        self._ScreenResolutionValue:SetValue(value)
    end
end

-- endregion

-- region Init

function XBWGraphicsSetting:_InitGraphicsQualityValue()
    local defaultQuality = CS.XQualityManager.Instance:GetDefaultLevel()
    local graphicsQuality = CS.XQualityManager.Instance:GetCurQualitySettings()

    if not XDataCenter.UiPcManager.IsPc() and defaultQuality >= XEnumConst.BWSetting.GraphicsQuality.Highest then
        defaultQuality = XEnumConst.BWSetting.GraphicsQuality.High
    end

    if not self._GraphicsQualityValue then
        ---@type XBWSettingValue
        self._GraphicsQualityValue = XBWSettingValue.New(defaultQuality, graphicsQuality)
        self._GraphicsQualityValue:RegisterValueChangedEvent(function(value)
            if value ~= XEnumConst.BWSetting.GraphicsQuality.Custom then
                self:_InitQualityValue(value)
            end
        end)
    else
        self._GraphicsQualityValue:Init(defaultQuality, graphicsQuality)
    end

    self:_InitOther(defaultQuality, graphicsQuality)
end

function XBWGraphicsSetting:_InitHDRValue(defaultValue, value)
    if not self._HDRValue then
        ---@type XBWSettingValue
        self._HDRValue = XBWSettingValue.New(defaultValue, value)
        self._HDRValue:RegisterValueChangedEvent(Handler(self, self.__OnQualitySettingChanged))
    else
        self._HDRValue:Init(defaultValue, value)
    end
end

function XBWGraphicsSetting:_InitFAXXValue(defaultValue, value)
    if not self._FAXXValue then
        ---@type XBWSettingValue
        self._FAXXValue = XBWSettingValue.New(defaultValue, value)
        self._FAXXValue:RegisterValueChangedEvent(Handler(self, self.__OnQualitySettingChanged))
    else
        self._FAXXValue:Init(defaultValue, value)
    end
end

function XBWGraphicsSetting:_InitEffectLevelValue(defaultValue, value)
    if not self._EffectLevelValue then
        ---@type XBWSettingValue
        self._EffectLevelValue = XBWSettingValue.New(defaultValue, value)
        self._EffectLevelValue:RegisterValueChangedEvent(Handler(self, self.__OnQualitySettingChanged))
    else
        self._EffectLevelValue:Init(defaultValue, value)
    end
end

function XBWGraphicsSetting:_InitOtherEffectLevelValue(defaultValue, value)
    if not self._OtherEffectLevelValue then
        ---@type XBWSettingValue
        self._OtherEffectLevelValue = XBWSettingValue.New(defaultValue, value)
        self._OtherEffectLevelValue:RegisterValueChangedEvent(Handler(self, self.__OnQualitySettingChanged))
    else
        self._OtherEffectLevelValue:Init(defaultValue, value)
    end
end

function XBWGraphicsSetting:_InitGraphicsLevelValue(defaultValue, value)
    if not self._GraphicsLevelValue then
        ---@type XBWSettingValue
        self._GraphicsLevelValue = XBWSettingValue.New(defaultValue, value)
        self._GraphicsLevelValue:RegisterValueChangedEvent(Handler(self, self.__OnQualitySettingChanged))
    else
        self._GraphicsLevelValue:Init(defaultValue, value)
    end
end

function XBWGraphicsSetting:_InitShadowLevelValue(defaultValue, value)
    if not self._ShadowLevelValue then
        ---@type XBWSettingValue
        self._ShadowLevelValue = XBWSettingValue.New(defaultValue, value)
        self._ShadowLevelValue:RegisterValueChangedEvent(Handler(self, self.__OnQualitySettingChanged))
    else
        self._ShadowLevelValue:Init(defaultValue, value)
    end
end

function XBWGraphicsSetting:_InitMirrorLevelValue(defaultValue, value)
    if not self._MirrorLevelValue then
        ---@type XBWSettingValue
        self._MirrorLevelValue = XBWSettingValue.New(defaultValue, value)
        self._MirrorLevelValue:RegisterValueChangedEvent(Handler(self, self.__OnQualitySettingChanged))
    else
        self._MirrorLevelValue:Init(defaultValue, value)
    end
end

function XBWGraphicsSetting:_InitResolutionLevelValue(defaultValue, value)
    if not self._ResolutionLevelValue then
        ---@type XBWSettingValue
        self._ResolutionLevelValue = XBWSettingValue.New(defaultValue, value)
        self._ResolutionLevelValue:RegisterValueChangedEvent(Handler(self, self.__OnQualitySettingChanged))
    else
        self._ResolutionLevelValue:Init(defaultValue, value)
    end
end

function XBWGraphicsSetting:_InitDistortionLevelValue(defaultValue, value)
    if not self._DistortionLevelValue then
        ---@type XBWSettingValue
        self._DistortionLevelValue = XBWSettingValue.New(defaultValue, value)
        self._DistortionLevelValue:RegisterValueChangedEvent(Handler(self, self.__OnQualitySettingChanged))
    else
        self._DistortionLevelValue:Init(defaultValue, value)
    end
end

function XBWGraphicsSetting:_InitFrameRateLevelValue(defaultValue, value)
    if not self._FrameRateLevelValue then
        ---@type XBWSettingValue
        self._FrameRateLevelValue = XBWSettingValue.New(defaultValue, value)
        self._FrameRateLevelValue:RegisterValueChangedEvent(Handler(self, self.__OnQualitySettingChanged))
    else
        self._FrameRateLevelValue:Init(defaultValue, value)
    end
end

function XBWGraphicsSetting:_InitBloomLevelValue(defaultValue, value)
    if not self._BloomLevelValue then
        ---@type XBWSettingValue
        self._BloomLevelValue = XBWSettingValue.New(defaultValue, value)
        self._BloomLevelValue:RegisterValueChangedEvent(Handler(self, self.__OnQualitySettingChanged))
    else
        self._BloomLevelValue:Init(defaultValue, value)
    end
end

function XBWGraphicsSetting:_InitOther(defaultQuality, quality)
    local defaultValue = CS.XQualityManager.Instance:GetQualitySettings(defaultQuality)
    local value = CS.XQualityManager.Instance:GetQualitySettings(quality)

    self:_InitHDRValue(defaultValue.UseHdr, value.UseHdr)
    self:_InitFAXXValue(defaultValue.UseFxaa, value.UseFxaa)
    self:_InitEffectLevelValue(defaultValue:GetEffectLevel(), value:GetEffectLevel())
    self:_InitOtherEffectLevelValue(defaultValue:GetOtherEffectLevel(), value:GetOtherEffectLevel())
    self:_InitGraphicsLevelValue(defaultValue:GetGraphicsLevel(), value:GetGraphicsLevel())
    self:_InitShadowLevelValue(defaultValue:GetShadowLevel(), value:GetShadowLevel())
    self:_InitMirrorLevelValue(defaultValue:GetMirrorLevel(), value:GetMirrorLevel())
    self:_InitResolutionLevelValue(defaultValue:GetResolutionLevel(), value:GetResolutionLevel())
    self:_InitDistortionLevelValue(defaultValue:GetDistortionLevel(), value:GetDistortionLevel())
    self:_InitFrameRateLevelValue(defaultValue:GetFrameRateLevel(), value:GetFrameRateLevel())
    self:_InitBloomLevelValue(defaultValue:GetBloomLevel(), value:GetBloomLevel())
end

function XBWGraphicsSetting:_InitQualityValue(quality)
    local value = CS.XQualityManager.Instance:GetQualitySettings(quality)

    self._HDRValue:SetValueWithoutEvent(value.UseHdr)
    self._FAXXValue:SetValueWithoutEvent(value.UseFxaa)
    self._EffectLevelValue:SetValueWithoutEvent(value:GetEffectLevel())
    self._OtherEffectLevelValue:SetValueWithoutEvent(value:GetOtherEffectLevel())
    self._GraphicsLevelValue:SetValueWithoutEvent(value:GetGraphicsLevel())
    self._ShadowLevelValue:SetValueWithoutEvent(value:GetShadowLevel())
    self._MirrorLevelValue:SetValueWithoutEvent(value:GetMirrorLevel())
    self._ResolutionLevelValue:SetValueWithoutEvent(value:GetResolutionLevel())
    self._DistortionLevelValue:SetValueWithoutEvent(value:GetDistortionLevel())
    self._FrameRateLevelValue:SetValueWithoutEvent(value:GetFrameRateLevel())
    self._BloomLevelValue:SetValueWithoutEvent(value:GetBloomLevel())
end

function XBWGraphicsSetting:_InitVSyncValue()
    if XDataCenter.UiPcManager.IsPc() then
        local vSync = CS.XSettingHelper.UseVSync

        if not self._VSyncValue then
            ---@type XBWSettingValue
            self._VSyncValue = XBWSettingValue.New(true, vSync)
        else
            self._VSyncValue:Init(true, vSync)
        end
    end
end

function XBWGraphicsSetting:_InitFullScreenValue()
    if XDataCenter.UiPcManager.IsPc() then
        local isFullScreen = CS.UnityEngine.Screen.fullScreen

        if not self._FullScreenValue then
            ---@type XBWSettingValue
            self._FullScreenValue = XBWSettingValue.New(isFullScreen, isFullScreen)
        else
            self._FullScreenValue:Init(isFullScreen, isFullScreen)
        end
    end
end

function XBWGraphicsSetting:_InitScreenResolutionValue()
    if XDataCenter.UiPcManager.IsPc() then
        local resolution = {
            x = CS.UnityEngine.Screen.width,
            y = CS.UnityEngine.Screen.height,
        }

        if not self._ScreenResolutionValue then
            ---@type XBWSettingValue
            self._ScreenResolutionValue = XBWSettingValue.New(resolution, resolution)
            self._ScreenResolutionValue:RegisterCompareHandler(function(valueA, valueB)
                return valueA.x == valueB.x and valueA.y == valueB.y
            end)
        else
            self._ScreenResolutionValue:Init(resolution, resolution)
        end
    end
end

-- endregion

-- region Private

function XBWGraphicsSetting:__OnQualitySettingChanged()
    self:SetGraphicsQualityValue(XEnumConst.BWSetting.GraphicsQuality.Custom)
end

function XBWGraphicsSetting:__ToCsQualitySetting()
    local quality = CS.XQualitySettings()

    quality.UseHdr = self:GetHDRValue()
    quality.UseFxaa = self:GetFAXXValue()
    quality:SetEffectLevel(self:GetEffectLevelValue())
    quality:SetOtherEffectLevel(self:GetOtherEffectLevelValue())
    quality:SetGraphicsLevel(self:GetGraphicsLevelValue())
    quality:SetShadowLevel(self:GetShadowLevelValue())
    quality:SetMirrorLevel(self:GetMirrorLevelValue())
    quality:SetResolutionLevel(self:GetResolutionLevelValue())
    quality:SetDistortionLevel(self:GetDistortionLevelValue())
    quality:SetFrameRateLevel(self:GetFrameRateLevelValue())
    quality:SetBloomLevel(self:GetBloomLevelValue())

    return quality
end

function XBWGraphicsSetting:__ChangeFullScreen()
    local deviceWidth, deviceHeight = XDataCenter.UiPcManager.GetDeviceScreenResolution()

    XDataCenter.UiPcManager.SetResolution(deviceWidth, deviceHeight, CS.UnityEngine.FullScreenMode.ExclusiveFullScreen)
end

function XBWGraphicsSetting:__ChangeWindowScreen()
    if self._ScreenResolutionValue then
        local resolution = self._ScreenResolutionValue:GetValue()

        XDataCenter.UiPcManager.SetResolution(resolution.x, resolution.y, CS.UnityEngine.FullScreenMode.Windowed)

        self._ScreenResolutionValue:SaveChange()
    end
end

-- endregion

return XBWGraphicsSetting
