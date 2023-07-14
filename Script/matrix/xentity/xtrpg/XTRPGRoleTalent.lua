local type = type

local Default = {
    __Id = 0,
    __IsActive = false,
    __CostPoint = 0,
}

local XTRPGRoleTalent = XClass(nil, "XTRPGRoleTalent")

function XTRPGRoleTalent:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.__Id = id
end

function XTRPGRoleTalent:Init(roleId)
    self.__CostPoint = XTRPGConfigs.GetRoleTalentCostPoint(roleId, self.__Id)
end

function XTRPGRoleTalent:IsActive()
    return self.__IsActive or false
end

function XTRPGRoleTalent:SetActive(value)
    self.__IsActive = value and true or false
end

function XTRPGRoleTalent:GetCostPoint()
    return self.__CostPoint
end

return XTRPGRoleTalent