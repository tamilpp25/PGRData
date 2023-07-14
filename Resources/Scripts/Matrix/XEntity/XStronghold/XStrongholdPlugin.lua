local type = type
local pairs = pairs
local ipairs = ipairs
local isNumberValid = XTool.IsNumberValid
local tableInsert = table.insert
local clone = XTool.Clone

local Default = {
    _Id = 0, --插件Id
    _Count = 0, --已使用数量
    _CostElectric = 0, --总消耗电能
}

local XStrongholdPlugin = XClass(nil, "XStrongholdPlugin")

function XStrongholdPlugin:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Id = id
end

function XStrongholdPlugin:GetCostElectric()
    return self._CostElectric
end

function XStrongholdPlugin:GetCostElectricSingle()
    return XStrongholdConfigs.GetPluginUseElectric(self._Id)
end

function XStrongholdPlugin:GetAddAbility()
    return self._Count * XStrongholdConfigs.GetPluginAddAbility(self._Id)
end

function XStrongholdPlugin:SetCount(count)
    self._Count = count or self._Count

    self._CostElectric = self._Count * self:GetCostElectricSingle()
end

function XStrongholdPlugin:GetCount()
    return self._Count
end

function XStrongholdPlugin:GetCountLimit()
    return XStrongholdConfigs.GetPluginCountLimit(self._Id)
end

function XStrongholdPlugin:IsEmpty()
    return not isNumberValid(self._Count)
end

function XStrongholdPlugin:GetId()
    return self._Id
end

function XStrongholdPlugin:GetIcon()
    return XStrongholdConfigs.GetPluginIcon(self._Id)
end

function XStrongholdPlugin:GetName()
    return XStrongholdConfigs.GetPluginName(self._Id)
end

function XStrongholdPlugin:GetDesc()
    return XStrongholdConfigs.GetPluginDesc(self._Id)
end

function XStrongholdPlugin:Compare(cPlugin)
    if not cPlugin then return false end

    return self._Id == cPlugin:GetId()
    and self._Count == cPlugin:GetCount()
end

return XStrongholdPlugin