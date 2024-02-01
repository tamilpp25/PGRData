
---@class XBlackRockChessActivity 战棋活动数据
---@field private _ActivityId number
---@field private _UnlockWeaponIdDict table<number, number>
---@field private _UnlockSkillIdDict table<number, number>
---@field private _PassStageDict table<number, number>
local XBlackRockChessActivity = XClass(nil, "XBlackRockChessActivity")

function XBlackRockChessActivity:Ctor(activityId)
    self._ActivityId = activityId
    self._UnlockWeaponIdDict = {} 
    self._UnlockSkillIdDict = {} 
    self._PassStageDict = {}
    self._BuffDict = {}
    self._RetractCount = 0 --悔棋次数
end

function XBlackRockChessActivity:GetActivityId()
    return self._ActivityId
end

function XBlackRockChessActivity:Reset()
    self._ActivityId = nil
    self._UnlockWeaponIdDict = {}
    self._UnlockSkillIdDict = {}
    self._PassStageDict = {}
    self._BuffDict = {}
    self._RetractCount = 0 --悔棋次数
end

function XBlackRockChessActivity:UpdateUnlockId(weaponIds, skillIds)
    for _, weaponId in ipairs(weaponIds or {}) do
        self._UnlockWeaponIdDict[weaponId] = weaponId
    end

    for _, skillId in ipairs(skillIds or {}) do
        self._UnlockSkillIdDict[skillId] = skillId
    end
end

function XBlackRockChessActivity:UpdatePassStage(passStage)
    for _, stage in ipairs(passStage or {}) do
        self._PassStageDict[stage.StageId] = stage.Star
    end
end

function XBlackRockChessActivity:UpdateBuffData(buffList)
    buffList = buffList or {}
    for _, data in ipairs(buffList) do
        self._BuffDict[data.BuffId] = {
            Id = data.BuffId,
            Overlays = data.Overlays
        }
    end
end

function XBlackRockChessActivity:GetGlobalBuffDict()
    return self._BuffDict
end

function XBlackRockChessActivity:IsWeaponUnlock(weaponId)
    return self._UnlockWeaponIdDict[weaponId] ~= nil
end

function XBlackRockChessActivity:IsSkillUnlock(skillId)
    return self._UnlockSkillIdDict[skillId] ~= nil
end

function XBlackRockChessActivity:IsStagePass(stageId)
    return self._PassStageDict[stageId] ~= nil
end

function XBlackRockChessActivity:GetStageStar(stageId)
    return self._PassStageDict[stageId] or 0
end

function XBlackRockChessActivity:GetPassedStageIdDict()
    return self._PassStageDict
end

function XBlackRockChessActivity:UpdateRetractCount(value)
    self._RetractCount = value
end

function XBlackRockChessActivity:GetRetractCount()
    return self._RetractCount
end

return XBlackRockChessActivity