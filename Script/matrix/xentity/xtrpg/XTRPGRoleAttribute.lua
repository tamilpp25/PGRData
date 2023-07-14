local type = type

local Default = {
    __Type = 0,
    __Value = 0,
    __MinRollValue = 0,
    __MaxRollValue = 0,
}

local XTRPGRoleAttribute = XClass(nil, "XTRPGRoleAttribute")

function XTRPGRoleAttribute:Ctor(attributeType, initValue)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.__Type = attributeType
    self.__Value = initValue
end

function XTRPGRoleAttribute:UpdateData(data)
    if XTool.IsTableEmpty(data) then return end

    self.__Value = data.Value or self.__Value
    self.__MinRollValue = data.MinRollValue or self.__MinRollValue
    self.__MaxRollValue = data.MaxRollValue or self.__MaxRollValue
end

function XTRPGRoleAttribute:GetValue()
    return self.__Value
end

function XTRPGRoleAttribute:GetMinRollValue()
    return self.__MinRollValue
end

function XTRPGRoleAttribute:GetMaxRollValue()
    return self.__MaxRollValue
end

return XTRPGRoleAttribute