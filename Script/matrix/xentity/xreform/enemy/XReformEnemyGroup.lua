local XReformEnemySource = require("XEntity/XReform/Enemy/XReformEnemySource")
local XReformBaseSourceGroup = require("XEntity/XReform/XReformBaseSourceGroup")
local XReformEnemyGroup = XClass(XReformBaseSourceGroup, "XReformEnemyGroup")

-- config : XReformConfigs.EnemyGroupConfig
function XReformEnemyGroup:Ctor(config)
    self.EnemyGroupType = XReformConfigs.EnemyGroupType.NormanEnemy
    self.EnemyGroupIndex = 0
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

function XReformEnemyGroup:GetReplaceIdDic()
    local result = {}
    local target = nil
    for _, source in ipairs(self.Sources) do
        target = source:GetCurrentTarget()
        if target then
            result[source:GetId()] = target:GetId()
        else
            result[source:GetId()] = 0
        end
    end
    return result
end

function XReformEnemyGroup:UpdateEnemyReformBuff(replaceIdDbDic)
    replaceIdDbDic = replaceIdDbDic or {}
    local target = nil
    local buffIds = nil
    for _, source in ipairs(self.Sources) do
        target = source:GetCurrentTarget()
        if replaceIdDbDic[source:GetId()] then
            buffIds = replaceIdDbDic[source:GetId()].AffixSourceId
        else
            buffIds = {}
        end
        if target then
            target:GetBuffGroup():UpdateActiveBuffIds(buffIds)
        elseif source:GetDefaultTarget() then
            source:GetDefaultTarget():GetBuffGroup():UpdateActiveBuffIds(buffIds)
        end
    end
end

function XReformEnemyGroup:GetChallengeScore()
    return self.CurrentChallengeScore
end

-- 获取敌人buff挑战积分
function XReformEnemyGroup:GetBuffChallengeScore()
    local result = 0
    local target = nil
    for _, source in ipairs(self.Sources) do
        target = source:GetCurrentTarget() or source:GetDefaultTarget()
        if target then
            for _, buff in ipairs(target:GetBuffGroup():GetActiveBuffs()) do
                result = result + buff:GetScore()
            end
        end
    end
    return result
end

function XReformEnemyGroup:GetBuffMaxChallengeScore()
    if self.__MaxBuffChallengeScore == nil then
        self.__MaxBuffChallengeScore = 0
        for _, source in ipairs(self.Sources) do
            self.__MaxBuffChallengeScore = self.__MaxBuffChallengeScore 
                + source:GetMaxTargetBuffScore()
        end
    end
    return self.__MaxBuffChallengeScore
end

function XReformEnemyGroup:GetEnemyReformBuffIdsByTargetId(sourceId, targetId)
    local source = self:GetSourceById(sourceId)
    local target = source:GetTargetById(targetId)
    if target == nil then return end
    return target:GetBuffGroup():GetActiveBuffIds()
end

function XReformEnemyGroup:GetDefaultTargetBuffIds(sourceId)
    local source = self:GetSourceById(sourceId)
    local target = source:GetDefaultTarget()
    if target == nil then return {} end
    return target:GetBuffGroup():GetActiveBuffIds()
end

function XReformEnemyGroup:GetEnemyReformBuffIds(sourceId, checkDefault)
    if checkDefault == nil then checkDefault = true end
    local source = self:GetSourceById(sourceId)
    local target = source:GetCurrentTarget()
    if target == nil and checkDefault then
        target = source:GetDefaultTarget()
    end
    if target == nil then return end
    return target:GetBuffGroup():GetActiveBuffIds()
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

function XReformEnemyGroup:SetEnemyGroupType(value)
    self.EnemyGroupType = value
end

function XReformEnemyGroup:GetEnemyGroupType()
    return self.EnemyGroupType
end

function XReformEnemyGroup:SetEnemyGroupIndex(value)
    self.EnemyGroupIndex = value
end

function XReformEnemyGroup:GetEnemyGroupIndex()
    return self.EnemyGroupIndex
end

function XReformEnemyGroup:GetIsActive(checkNormal)
    if checkNormal == nil then checkNormal = true end
    if checkNormal and self.EnemyGroupType == XReformConfigs.EnemyGroupType.NormanEnemy then
        return true
    end
    for _, source in ipairs(self.Sources) do
        if source:GetCurrentTarget() then
            return true
        end
    end
    return false
end

function XReformEnemyGroup:GetCurrentEnemyCount()
    return #self:GetSourcesWithEntity()
    -- local result = 0
    -- for _, source in ipairs(self.Sources) do
    --     if source:CheckIsReformed() then
    --         result = result + 1
    --     end
    -- end
    -- return result
end

function XReformEnemyGroup:GetMaxEnemyCount()
    return #self.Sources
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