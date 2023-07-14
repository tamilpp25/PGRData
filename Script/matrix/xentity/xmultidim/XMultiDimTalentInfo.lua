local type = type
local pairs = pairs

local Default = {
    _ClassId = 0, -- 职业类型Id
    _TalentType = {} -- 天赋类型
}

---@class XMultiDimTalentInfo
local XMultiDimTalentInfo = XClass(nil, "XMultiDimTalentInfo")
local XMultiDimTalentType = require("XEntity/XMultiDim/XMultiDimTalentType")

function XMultiDimTalentInfo:GetTalentType(typeId)
    if not XTool.IsNumberValid(typeId) then
        XLog.Error("XMultiDimTalentInfo GetTalentType error: 获取天赋类型失败, typeId: ", typeId)
        return
    end
    
    local talentType = self._TalentType[typeId]
    if not talentType then
        talentType = XMultiDimTalentType.New(typeId)
        self._TalentType[typeId] = talentType
    end
    return talentType
end

function XMultiDimTalentInfo:UpdateTalentType(typeId, level)
    ---@type XMultiDimTalentType
    local talentType = self:GetTalentType(typeId)
    talentType:UpdateLevel(level)
end

function XMultiDimTalentInfo:Ctor(classId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._ClassId = classId
    self:ResetTalent()
end

function XMultiDimTalentInfo:UpdateData(id)
    local talentType = XMultiDimConfig.GetMultiDimTalentType(id)
    if not XTool.IsNumberValid(talentType) then
        return
    end
    local level = XMultiDimConfig.GetMultiDimTalentLevel(id)
    self:UpdateTalentType(talentType, level)
end

function XMultiDimTalentInfo:GetTalentLevel(typeId)
    ---@type XMultiDimTalentType
    local talentType = self:GetTalentType(typeId)
    return talentType:GetLevel()
end

function XMultiDimTalentInfo:ResetTalent()
    -- 默认值
    for _, typeId in pairs(XMultiDimConfig.TalentType) do
        self:UpdateTalentType(typeId, 0)
    end
end
-- 返回当前职业类型下的天赋总点数
-- 点数计算方式是：之天赋和核心天赋的等级之和
function XMultiDimTalentInfo:GetCareerTalentPoint()
    local allLevel = 0
    for _, typeId in pairs(XMultiDimConfig.TalentType) do
        local level = self:GetTalentLevel(typeId)
        allLevel = allLevel + level
    end
    return allLevel
end

return XMultiDimTalentInfo