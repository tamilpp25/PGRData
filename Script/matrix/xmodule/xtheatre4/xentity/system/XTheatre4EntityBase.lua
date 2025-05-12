---@class XTheatre4EntityBase
---@field _Model XTheatre4Model
---@field _Control XTheatre4SystemSubControl
local XTheatre4EntityBase = XClass(nil, "XTheatre4EntityBase")

function XTheatre4EntityBase:Ctor(control)
    self._Control = control
    self._Model = control._Model
    ---@type XTheatre4ConfigBase
    self._Config = nil
end

---@param config XTheatre4ConfigBase
function XTheatre4EntityBase:SetConfig(config)
    self._Config = config
end

---@return XTheatre4ConfigBase
function XTheatre4EntityBase:GetConfig()
    return self._Config
end

function XTheatre4EntityBase:IsEmpty()
    local config = self:GetConfig()

    return not config or config:IsEmpty()
end

---@param entity XTheatre4EntityBase
function XTheatre4EntityBase:IsEquals(entity)
    if self:IsEmpty() and entity:IsEmpty() then
        return true
    end
    if self:IsEmpty() or entity:IsEmpty() then
        return false
    end

    return self:GetConfig():IsEquals(entity:GetConfig())
end

function XTheatre4EntityBase:Release()
    if not self:IsEmpty() then
        self._Config:Release()
        self._Config = nil
    end

    self._Control = nil
    self._Model = nil
end

return XTheatre4EntityBase
