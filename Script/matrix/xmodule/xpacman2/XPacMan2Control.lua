---@class XPacMan2Control : XControl
---@field private _Model XPacMan2Model
local XPacMan2Control = XClass(XControl, "XPacMan2Control")
function XPacMan2Control:OnInit()
end

function XPacMan2Control:OnRelease()
end

function XPacMan2Control:GetTimeId()
    local config = self._Model:GetActivityConfig()
    if not config then
        return false
    end
    return config.TimeId
end

function XPacMan2Control:IsStageInTime(stageId)
    local stageConfig = self._Model:GetStageConfig(stageId)
    if stageConfig then
        if stageConfig.TimeId == 0 then
            return true
        end
        return XFunctionManager.CheckInTimeByTimeId(stageConfig.TimeId)
    end
    return false
end

function XPacMan2Control:GetStageList()
    local stageList = {}
    local config = self._Model:GetActivityConfig()
    if not config then
        return {}
    end
    ---@type XTablePacMan2Stage[]
    local stageConfigs = {}
    local groupId = config.GroupId
    local stages = self._Model:GetStageConfigs()
    for i, stage in ipairs(stages) do
        if stage.GroupId == groupId then
            table.insert(stageConfigs, stage)
        end
    end
    for i = 1, #stageConfigs do
        local stage = stageConfigs[i]

        local isLock = false
        local isLock4PreStage = false
        local isLock4Time = false

        --判断时间是否通过
        local timeId = stage.TimeId
        if timeId and timeId ~= 0 then
            local isTimePassed = XFunctionManager.CheckInTimeByTimeId(timeId)
            if not isTimePassed then
                isLock = true
                isLock4Time = true
            end
        end

        --判断前置关卡是否通过
        if not isLock then
            local preStageId = stage.PreStageId
            if preStageId and preStageId ~= 0 then
                local isPreStagePassed = self._Model:IsStagePassed(preStageId)
                if not isPreStagePassed then
                    isLock = true
                    isLock4PreStage = true
                end
            end
        end

        local star = self._Model:GetStageStar(stage.Id)
        if not star then
            star = 0
        end

        local isPassed = self._Model:IsStagePassed(stage.Id)

        ---@class XUiPacMan2StageGridData
        local data = {
            StageId = stage.Id,
            Name = stage.Name,
            IsLock = isLock,
            Star = star,
            IsPassed = isPassed,
            RewardId = stage.KeyReward,
            IsLock4PreStage = isLock4PreStage,
            IsLock4Time = isLock4Time,
            Time = isLock4Time and XFunctionManager.GetStartTimeByTimeId(timeId)
        }
        table.insert(stageList, data)
    end

    return stageList
end

function XPacMan2Control:GetTargetList(stageId, getScore)
    local stageConfig = self._Model:GetStageConfig(stageId)
    if not stageConfig then
        return nil
    end
    local targetList = {}
    for i = 1, #stageConfig.Star do
        local score = stageConfig.Star[i]
        local target = {
            IsOn = getScore >= score,
            Score = score,
            RewardId = stageConfig.StarReward[i],
        }
        targetList[#targetList + 1] = target
    end
    return targetList
end

function XPacMan2Control:GetStageDetail(stageId)
    local stageConfig = self._Model:GetStageConfig(stageId)
    if not stageConfig then
        return nil
    end
    local star = self._Model:GetStageStar(stageId)
    local targetList = {}
    for i = 1, #stageConfig.Star do
        local score = stageConfig.Star[i]
        ---@class XUiPacMan2TargetData
        local target = {
            IsOn = i <= star,
            Score = score,
            RewardId = stageConfig.StarReward[i],
        }
        targetList[#targetList + 1] = target
    end

    local showProp = {}
    for i = 1, #stageConfig.ShowProp do
        local id = stageConfig.ShowProp[i]
        local entityConfig = self._Model:GetEntityConfig(id)
        if entityConfig then
            ---@class XUiPacMan2IconNodeData
            local data = {
                Id = entityConfig.Id,
                Icon = entityConfig.Icon,
                Name = entityConfig.Name,
                Desc = entityConfig.Desc,
                IsProp = true,
            }
            showProp[#showProp + 1] = data
        else
            XLog.Error("[XPacMan2Control] GetStageDetail stageId = " .. tostring(stageId) .. " propId = " .. tostring(id) .. " not found")
        end
    end
    local showGhost = {}
    for i = 1, #stageConfig.ShowGhost do
        local id = stageConfig.ShowGhost[i]
        local entityConfig = self._Model:GetEntityConfig(id)
        if entityConfig then
            local data = {
                Id = entityConfig.Id,
                Icon = entityConfig.Icon,
                Name = entityConfig.Name,
                Desc = entityConfig.Desc,
                IsGhost = true,
            }
            showGhost[#showGhost + 1] = data
        else
            XLog.Error("[XPacMan2Control] GetStageDetail stageId = " .. tostring(stageId) .. " ghostId = " .. tostring(id) .. " not found")
        end
    end
    local data = {
        Name = stageConfig.Name,
        Target = targetList,
        ShowProp = showProp,
        ShowGhost = showGhost,
    }
    return data
end

function XPacMan2Control:GetStageConfig(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config
end

function XPacMan2Control:GetGameConfig()
    return self._Model:GetGameConfig()
end

function XPacMan2Control:GetEntityConfig(id)
    return self._Model:GetEntityConfig(id)
end

function XPacMan2Control:GetNextStageId(stageId)
    local stages = self._Model:GetStageConfigs()
    for i, stage in pairs(stages) do
        if stage.PreStageId == stageId then
            return stage.Id
        end
    end
    return false
end

function XPacMan2Control:SetPlaying(value)
    self._Model.IsPlaying = value
end

function XPacMan2Control:GetCurrentStageId()
    local stages = self._Model:GetStageConfigs()
    for i, config in ipairs(stages) do
        if not self._Model:IsStagePassed(config.Id) then
            return config.Id
        end
    end
end

return XPacMan2Control