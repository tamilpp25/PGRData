local type = type
local pairs = pairs

local Default = {
    _StageCfgId = 0,    --关卡id
    _RoleId = 0,        --最后使用通过的角色
    _StepCount = 0,     --通关时候的步数
    _StarCondition = {},   --通关获得的星星id列表
    _StarReward = {},  --是否获得星级奖励，存的是条件ID
    _Hint = 0,  --是否已解锁提示
    _Answer = 0,    --是否已解锁答案
}

---推箱子关卡数据
---@class XRpgMakerActivityStageDb
local XRpgMakerActivityStageDb = XClass(nil, "XRpgMakerActivityStageDb")

function XRpgMakerActivityStageDb:Ctor(stageId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    if stageId then
        self:SetStageId(stageId)
    end
    self._FirstStarReward = {}  --是否首次显示星级奖励，存的是条件
end

function XRpgMakerActivityStageDb:UpdateData(data)
    self._StageCfgId = data.StageCfgId
    self._RoleId = data.RoleId
    self._StepCount = data.StepCount
    self._StarCondition = data.StarCondition
    self:SetStarReward(data.StarReward)
    self:SetHint(data.Hint)
    self:SetAnswer(data.Answer)
end

function XRpgMakerActivityStageDb:SetAnswer(answer)
    self._Answer = answer
end

function XRpgMakerActivityStageDb:SetHint(hint)
    self._Hint = hint
end

function XRpgMakerActivityStageDb:SetStarReward(starReward, isFirstStarReward)
    for _, conditionId in ipairs(starReward) do
        self._StarReward[conditionId] = true
        self:SetFirstStarReward(conditionId, isFirstStarReward)
    end
end

function XRpgMakerActivityStageDb:SetFirstStarReward(conditionId, isShow)
    self._FirstStarReward[conditionId] = isShow
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

function XRpgMakerActivityStageDb:SetStageId(stageId)
    self._StageCfgId = stageId
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

function XRpgMakerActivityStageDb:GetStartReward()
    return self._StartReward
end

function XRpgMakerActivityStageDb:IsUnlockHint()
    return XTool.IsNumberValid(self._Hint) 
end

function XRpgMakerActivityStageDb:IsUnlockAnswer()
    return XTool.IsNumberValid(self._Answer)
end

function XRpgMakerActivityStageDb:IsStageClear()
    return XTool.IsNumberValid(self:GetRoleId())
end

function XRpgMakerActivityStageDb:IsStagePerfectClear()
    return self:GetStarCount() == XRpgMakerGameConfigs.GetRpgMakerGameStageTotalStar(self:GetStageCfgId())
end

function XRpgMakerActivityStageDb:IsStarReward(conditionId)
    return self._StarReward[conditionId] or false
end

function XRpgMakerActivityStageDb:IsShowFirstStarReward(conditionId)
    return self._FirstStarReward[conditionId] or false
end

return XRpgMakerActivityStageDb