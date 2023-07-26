local XReform2ndStage = require("XEntity/XReform2/XReform2ndStage")
local XReform2ndMob = require("XEntity/XReform2/XReform2ndMob")
local XReform2ndAffix = require("XEntity/XReform2/XReform2ndAffix")

---@class XReform2ndData
local XReform2ndData = XClass(nil, "XReform2ndData")

function XReform2ndData:Ctor()
    -- 开始
    self._IsPlaying = false

    -- 活动Id
    self._ActivityId = XReform2ndConfigs.GetActivityDefaultId()

    ---@type XReform2ndStage[]
    self._Stage = {}
end

---@return XReform2ndStage
function XReform2ndData:GetStage(stageId)
    if not XReform2ndConfigs.IsStageValid(stageId) then
        XLog.Error("[XReform2ndData] stageId invalid", stageId)
        return
    end
    local stage = self._Stage[stageId]
    if not stage then
        stage = XReform2ndStage.New(stageId)
        self._Stage[stageId] = stage
    end
    return stage
end

function XReform2ndData:GetStageDic()
    return self._Stage
end

-- 这个结构有点复杂
function XReform2ndData:SetData(data)
    local stages = data.StageDbs

    -- stage
    for i = 1, #stages do
        local stageData = stages[i]
        local stageId = stageData.Id
        if XReform2ndConfigs.IsStageValid(stageId) then
            local stage = self:GetStage(stageId)
            local pass = stageData.Pass
            stage:SetIsPassed(pass)

            -- abandon: 每个stage有难度，现在默认为1
            local difficulty = stageData.CurDiffIndex + 1
            local detailData = stageData.DifficultyDbs[difficulty]
            if detailData then
                stage:SetStarHistory(XReform2ndConfigs.GetStarByPressure(detailData.Score, stageId))
                stage:SetExtraStar(detailData.ExtraStar > 0)

                -- 每个难度有n组mobGroup
                local enemyList = detailData.EnemyReplaceIds
                for j = 1, #enemyList do
                    local enemy = enemyList[j]
                    local groupId = enemy.EnemyGroupId
                    local mobGroup = stage:GetMonsterGroupByGroupId(groupId)

                    -- 每个mobGroup有一组mob
                    if mobGroup then
                        local sourceId = enemy.SourceId
                        local index = mobGroup:GetIndexBySourceId(sourceId)
                        if index then
                            local mobId = enemy.TargetId
                            ---@type XReform2ndMob
                            local mob = XReform2ndMob.New(mobId)
                            mobGroup:SetMob(index, mob)

                            -- 每个mob有一组affix
                            local affixList = enemy.AffixSourceId
                            for k = 1, #affixList do
                                local affixId = affixList[k]
                                if XReform2ndConfigs.IsAffixValid(affixId) then
                                    local affix = XReform2ndAffix.New(affixId)
                                    mob:SetAffixSelected(affix)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    self._IsPlaying = data.IsPlaying
    local activityId = data.ActivityId
    if not XReform2ndConfigs.IsActivityExist(activityId) then
        activityId = XReform2ndConfigs.GetActivityDefaultId()
    end
    self._ActivityId = activityId
end

function XReform2ndData:GetHelpKey1()
    return XReform2ndConfigs.GetActivityHelpKey1(self._ActivityId)
end

function XReform2ndData:GetHelpKey2()
    return XReform2ndConfigs.GetActivityHelpKey2(self._ActivityId)
end

function XReform2ndData:GetOpenTimeId()
    return XReform2ndConfigs.GetActivityOpenTimeId(self._ActivityId)
end

function XReform2ndData:GetName()
    return XReform2ndConfigs.GetActivityName(self._ActivityId)
end

function XReform2ndData:GetIcon()
    return XReform2ndConfigs.GetActivityBannerIcon(self._ActivityId)
end

function XReform2ndData:GetActivityId()
    return self._ActivityId
end

return XReform2ndData
