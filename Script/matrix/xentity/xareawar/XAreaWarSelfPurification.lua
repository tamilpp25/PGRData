local type = type
local pairs = pairs
local tableInsert = table.insert

local Default = {
    _Level = 0, --净化等级
    _Exp = 0, --净化经验
}

local XAreaWarSelfPurification = XClass(nil, "XAreaWarSelfPurification")

function XAreaWarSelfPurification:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XAreaWarSelfPurification:UpdateLevelExp(level, exp)
    self._Level = level or self._Level
    self._Exp = exp or self._Exp
end

function XAreaWarSelfPurification:GetLevel()
    return self._Level
end

function XAreaWarSelfPurification:GetExp()
    return self._Exp
end

return XAreaWarSelfPurification