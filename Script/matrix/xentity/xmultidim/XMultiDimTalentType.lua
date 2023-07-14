local type = type
local pairs = pairs

local Default = {
    _TalentType = 0, -- 天赋类型
    _Level = 0 -- 天赋等级
}

---@class XMultiDimTalentType
local XMultiDimTalentType = XClass(nil, "XMultiDimTalentType")

function XMultiDimTalentType:Ctor(talentType)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    
    self._TalentType = talentType
end

function XMultiDimTalentType:UpdateLevel(level)
    self._Level = level
end

function XMultiDimTalentType:GetLevel()
    return self._Level
end

return XMultiDimTalentType