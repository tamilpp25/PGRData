local XReformEnemySource = require("XEntity/XReform/Enemy/XReformEnemySource")
local XReformBaseSourceGroup = require("XEntity/XReform/XReformBaseSourceGroup")
local XReformEnemyGroup = XClass(XReformBaseSourceGroup, "XReformEnemyGroup")

-- config : XReformConfigs.EnemyGroupConfig
function XReformEnemyGroup:Ctor(config)
    self:InitSources()
end

function XReformEnemyGroup:UpdateReplaceIdDic(replaceIdDic, isUpdateChallengeScore)
    for _, source in ipairs(self.Sources) do
        source:UpdateTargetId(replaceIdDic[source:GetId()])
    end
    if isUpdateChallengeScore then
        local result = 0
        -- 更新当前挑战分数
        local enemyTargetConfig = nil
        local enemySourceConfig = nil
        for sourceId, targetId in pairs(replaceIdDic) do        
            enemyTargetConfig = XReformConfigs.GetEnemyTargetConfig(targetId)
            if enemyTargetConfig then
                enemySourceConfig = XReformConfigs.GetEnemySourceConfig(sourceId)
                if enemySourceConfig.NpcId == 0 then
                    result = result + enemySourceConfig.AddScore
                end
                result = result + enemyTargetConfig.AddScore
            end
        end
        self.CurrentChallengeScore = result
    end
end

function XReformEnemyGroup:GetMaxChallengeScore()
    if self.__MaxChallengeScore == nil then
        local result = 0
        for _, source in ipairs(self.Sources) do
            result = result + source:GetMaxTagerScore()
        end
        self.__MaxChallengeScore = result
    end
    return self.__MaxChallengeScore
end

function XReformEnemyGroup:GetName()
    return CS.XTextManager.GetText("ReformEvolvableEnemyNameText")
end

--######################## 私有方法 ########################

function XReformEnemyGroup:InitSources()
    local config = nil
    local data = nil
    for _, sourceId in ipairs(self.Config.SubId) do
        config = XReformConfigs.GetEnemySourceConfig(sourceId)
        data = XReformEnemySource.New(config)
        table.insert(self.Sources, data)
        self.SourceDic[data:GetId()] = data
    end
end

return XReformEnemyGroup