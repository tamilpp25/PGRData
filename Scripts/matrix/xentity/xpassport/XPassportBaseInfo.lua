local type = type

--通行证基础信息
local XPassportBaseInfo = XClass(nil, "XPassportBaseInfo")

local Default = {
    _Level = 0, --等级
}

function XPassportBaseInfo:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XPassportBaseInfo:UpdateData(level)
    self._Level = level
end

function XPassportBaseInfo:SetToLevel(toLevel)
    self._Level = toLevel
end

function XPassportBaseInfo:GetLevel()
    return self._Level
end

return XPassportBaseInfo