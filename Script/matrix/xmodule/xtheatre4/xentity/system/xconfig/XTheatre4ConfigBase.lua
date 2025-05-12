---@class XTheatre4ConfigBase
local XTheatre4ConfigBase = XClass(nil, "XTheatre4ConfigBase")

function XTheatre4ConfigBase:Ctor(config)
    self:SetData(config)
end

function XTheatre4ConfigBase:SetData(config)
    if config then
        self._Config = config
    end
end

function XTheatre4ConfigBase:IsEmpty()
    return self._Config == nil
end

---@param config XTheatre4ConfigBase
function XTheatre4ConfigBase:IsEquals(config)
    return self._Config == config._Config
end

function XTheatre4ConfigBase:Release()
    self._Config = nil
end

function XTheatre4ConfigBase:_GetValueOrDefaultByKey(key, defaultValue)
    if not self:IsEmpty() then
        return self._Config[key] or defaultValue
    end

    return defaultValue
end

return XTheatre4ConfigBase