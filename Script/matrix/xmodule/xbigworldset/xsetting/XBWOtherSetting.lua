local XBWSettingBase = require("XModule/XBigWorldSet/XSetting/XBWSettingBase")
local XBWSettingValue = require("XModule/XBigWorldSet/XSetting/XBWSettingValue")

---@class XBWOtherSetting : XBWSettingBase
local XBWOtherSetting = XClass(XBWSettingBase, "XBWOtherSetting")

function XBWOtherSetting:InitValue()
    self:_InitScreenOffValue()
    self:_InitCursorSizeValue()
end

function XBWOtherSetting:Reset()
    self._ScreenOffValue:Reset()

    if self._CursorSizeValue then
        self._CursorSizeValue:Reset()
    end
end

function XBWOtherSetting:RestoreDefault()
    self._ScreenOffValue:RestoreDefault()

    if self._CursorSizeValue then
        self._CursorSizeValue:RestoreDefault()
    end
end

function XBWOtherSetting:SaveChange()
    if self._ScreenOffValue:IsChanged() then
        XDataCenter.SetManager.SaveScreenOff(self:GetScreenOffValue())
    end

    self._ScreenOffValue:SaveChange()

    if self._CursorSizeValue then
        if self._CursorSizeValue:IsChanged() then
            CS.XPc.XCursorHelper.CursorSizeIndex = self._CursorSizeValue:GetValue()
        end

        self._CursorSizeValue:SaveChange()
    end
end

function XBWOtherSetting:IsChanged()
    if self._ScreenOffValue:IsChanged() then
        return true
    end
    if self._CursorSizeValue and self._CursorSizeValue:IsChanged() then
        return true
    end

    return false
end

-- region Getter/Setter

function XBWOtherSetting:GetScreenOffValue()
    return self._ScreenOffValue:GetValue()
end

function XBWOtherSetting:SetScreenOffValue(value)
    self._ScreenOffValue:SetValue(value)
end

function XBWOtherSetting:GetCursorSizeValue()
    if not self._CursorSizeValue then
        return 0
    end

    return self._CursorSizeValue:GetValue()
end

function XBWOtherSetting:SetCursorSizeValue(value)
    if self._CursorSizeValue then
        self._CursorSizeValue:SetValue(value)
    end
end

-- endregion

-- region Init

function XBWOtherSetting:_InitScreenOffValue()
    local originalValue = XSaveTool.GetData(XSetConfigs.ScreenOff) or 0

    if not self._ScreenOffValue then
        ---@type XBWSettingValue
        self._ScreenOffValue = XBWSettingValue.New(0, tonumber(originalValue))
        self._ScreenOffValue:RegisterValueChangedEvent(function(value)
            XMVCA.XBigWorldSet:SetSpecialScreenOff(value)
        end)
    else
        self._ScreenOffValue:Init(0, originalValue)
    end
end

function XBWOtherSetting:_InitCursorSizeValue()
    if XDataCenter.UiPcManager.IsPc() then
        local cursorSize = CS.XPc.XCursorHelper.CursorSizeIndex
        local defaultSize = XEnumConst.BWSetting.CursorSize.Small

        if not self._CursorSizeValue then
            ---@type XBWSettingValue
            self._CursorSizeValue = XBWSettingValue.New(defaultSize, cursorSize)
        else
            self._CursorSizeValue:Init(defaultSize, cursorSize)
        end
    end
end

-- endregion

return XBWOtherSetting
