---@class XBWSettingValue
local XBWSettingValue = XClass(nil, "XBWSettingValue")

function XBWSettingValue:Ctor(defaultValue, originalValue, value)
    self:Init(defaultValue, originalValue, value)
end

function XBWSettingValue:Init(defaultValue, originalValue, value)
    self._OriginalValue = originalValue
    self._DefaultValue = defaultValue
    self._Value = value or originalValue
end

function XBWSettingValue:RegisterValueChangedEvent(event)
    self._ValueChangedEvent = event
end

function XBWSettingValue:RegisterCompareHandler(compareTo)
    self._CompareTo = compareTo
end

function XBWSettingValue:GetOriginalValue()
    return self._OriginalValue
end

function XBWSettingValue:GetDefaultValue()
    return self._DefaultValue
end

function XBWSettingValue:GetValue()
    return self._Value
end

function XBWSettingValue:SetValue(value)
    if not self:__CompareValue(value, self._Value) then
        self._Value = value
        self:__InvokeValueChangedEvent(value)
    end
end

function XBWSettingValue:SetValueWithoutEvent(value)
    self._Value = value
end

function XBWSettingValue:IsChanged()
    return not self:__CompareValue(self:GetValue(), self:GetOriginalValue())
end

function XBWSettingValue:Reset()
    self:SetValue(self._OriginalValue)
end

function XBWSettingValue:RestoreDefault()
    self:SetValue(self._DefaultValue)
end

function XBWSettingValue:SaveChange()
    self._OriginalValue = self:GetValue()
end

function XBWSettingValue:__InvokeValueChangedEvent(value)
    if self._ValueChangedEvent then
        self._ValueChangedEvent(value)
    end
end

function XBWSettingValue:__CompareValue(valueA, valueB)
    if self._CompareTo then
        return self._CompareTo(valueA, valueB)
    end

    return valueA == valueB
end

return XBWSettingValue
