local XReformEnvironment = require("XEntity/XReform/Environment/XReformEnvironment")
local XReformEnvironmentGroup = XClass(nil, "XReformEnvironmentGroup")

-- config : XReformConfigs.EnvironmentGroupConfig
function XReformEnvironmentGroup:Ctor(config)
    -- XReformEnvironment
    self.Environments = {}
    -- key : id, value : XReformEnvironment
    self.EnvironmentDic = {}
    self.Config = config
    self:InitEnvironments()
    self.CurrentChallengeScore = 0
    self.MaxSelectableCount = 0
end

function XReformEnvironmentGroup:SetMaxSelectableCount(value)
    self.MaxSelectableCount = value
end

-- 所有环境数据
function XReformEnvironmentGroup:GetEnvironments()
    return self.Environments
end

function XReformEnvironmentGroup:GetName()
    return CS.XTextManager.GetText("ReformEvolvableEnvNameText")
end

function XReformEnvironmentGroup:GetEnvironmentById(id)
    return self.EnvironmentDic[id]
end

function XReformEnvironmentGroup:UpdateChallengeScore(envIds)
    local result = 0
    local envConfig = nil
    for _, envId in ipairs(envIds) do
        envConfig = XReformConfigs.GetEnvironmentConfig(envId)
        result = result + envConfig.AddScore
    end
    self.CurrentChallengeScore = result
end

function XReformEnvironmentGroup:GetChallengeScore()
    return self.CurrentChallengeScore
end

function XReformEnvironmentGroup:GetMaxChallengeScore()
    if self.__MaxChallengeScore == nil then
        local maxScores = {}
        local maxCount = self.MaxSelectableCount
        local minScore = 0
        local currentScore = 0
        for _, environment in ipairs(self.Environments) do
            currentScore = environment:GetScore()
            if #maxScores < maxCount then
                local minTableValue = maxScores[#maxScores]
                -- 说明没有值，直接设置即可
                -- or 当前值小于等于最小值
                if minTableValue == nil
                or currentScore <= minTableValue then 
                    minScore = currentScore
                    table.insert(maxScores, currentScore)
                else
                    for i = 1, #maxScores do
                        if currentScore >= maxScores[i] then
                            table.insert(maxScores, i, currentScore)
                            break
                        end
                    end
                    minScore = maxScores[#maxScores]
                end
            else
                if currentScore <= minScore then break end
                for i = 1, #maxScores do
                    if currentScore >= maxScores[i] then
                        table.insert(maxScores, i, currentScore)
                        break
                    end
                end
                table.remove(maxScores, #maxScores)
                minScore = maxScores[#maxScores] or 0
            end
        end
        local result = 0
        for _, v in ipairs(maxScores) do
            result = result + v
        end
        self.__MaxChallengeScore = result
    end
    return self.__MaxChallengeScore
end

--######################## 私有方法 ########################

function XReformEnvironmentGroup:InitEnvironments()
    local config = nil
    local data = nil
    for _, id in ipairs(self.Config.SubId) do
        config = XReformConfigs.GetEnvironmentConfig(id)
        if config then
            data = XReformEnvironment.New(config)
            table.insert(self.Environments, data)
            self.EnvironmentDic[data:GetId()] = data
        end
    end
end

return XReformEnvironmentGroup