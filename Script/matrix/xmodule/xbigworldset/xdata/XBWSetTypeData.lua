---@class XBWSetTypeData
local XBWSetTypeData = XClass(nil, "XBWSetTypeData")

function XBWSetTypeData:Ctor(config)
    self:SetConfig(config)
end

---@param config XTableBigWorldSetType
function XBWSetTypeData:SetConfig(config)
    if config then
        self._Config = config
    end
end

function XBWSetTypeData:GetName()
    if self:IsNil() then
        return ""
    end

    return self._Config.TypeName
end

function XBWSetTypeData:GetType()
    if self:IsNil() then
        return 0
    end

    return self._Config.Type
end

function XBWSetTypeData:GetIcon()
    if self:IsNil() then
        return ""
    end

    return self._Config.Icon
end

function XBWSetTypeData:GetPriority()
    if self:IsNil() then
        return 0
    end

    return self._Config.Priority
end

function XBWSetTypeData:GetUiName()
    if self:IsNil() then
        return ""
    end

    if XDataCenter.UiPcManager.IsPc() and not string.IsNilOrEmpty(self._Config.PcUiName) then
        return self._Config.PcUiName
    end

    return self._Config.UiName
end

function XBWSetTypeData:IsNil()
    return self._Config == nil
end

return XBWSetTypeData