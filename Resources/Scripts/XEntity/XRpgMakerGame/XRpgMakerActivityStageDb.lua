local type = type
local pairs = pairs

local Default = {
    _StageCfgId = 0,    --关卡id
    _RoleId = 0,        --最后使用通过的角色
    _StepCount = 0,     --通关时候的步数
    _StarCondition = {},   --通关获得的星星id列表
}

--关卡数据
local XRpgMakerActivityStageDb = XClass(nil, "XRpgMakerActivityStageDb")

function XRpgMakerActivityStageDb:Ctor(day)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XRpgMakerActivityStageDb:UpdateData(data)
    self._StageCfgId = data.StageCfgId
    self._RoleId = data.RoleId
    self._StepCount = data.StepCount
    self._StarCondition = data.StarCondition
end

function XRpgMakerActivityStageDb:SetRoleId(roleId)
    self._RoleId = roleId
end

function XRpgMakerActivityStageDb:SetStepCount(stepCount)
    self._StepCount = stepCount
end

function XRpgMakerActivityStageDb:SetStarCondition(starCondition)
    self._StarCondition = starCondition
end

function XRpgMakerActivityStageDb:GetStarCount()
    return self._StarCondition and #self._StarCondition or 0
end

function XRpgMakerActivityStageDb:IsStarConditionClear(starConditionId)
    for _, starCondition in ipairs(self._StarCondition or {}) do
        if starCondition == starConditionId then
            return true
        end
    end
    return false
end

function XRpgMakerActivityStageDb:GetStageCfgId()
    return self._StageCfgId
end

function XRpgMakerActivityStageDb:GetRoleId()
    return self._RoleId
end

function XRpgMakerActivityStageDb:GetStepCount()
    return self._StepCount
end

function XRpgMakerActivityStageDb:GetStar()
    return self._Star
end

return XRpgMakerActivityStageDb