local XReformEnemyGroup = require("XEntity/XReform/Enemy/XReformEnemyGroup")
local XReformMemberGroup = require("XEntity/XReform/Member/XReformMemberGroup")
local XReformEnvironmentGroup = require("XEntity/XReform/Environment/XReformEnvironmentGroup")
local XReformBuffGroup = require("XEntity/XReform/Buff/XReformBuffGroup")
local XReformEvolvableStage = XClass(nil, "XReformEvolvableStage")

-- config : XReformConfigs.StageDiffConfig
function XReformEvolvableStage:Ctor(config)
    -- XReformConfigs.StageDiffConfig
    self.Config = config
    -- XReformEnemyGroup | XReformMemberGroup | XReformEnvironmentGroup | XReformBuffGroup
    self.EvolvableGroupDic = {}
    -- 当前关卡敌人替换的数据
    -- key : sourceId, value : targetId
    self.EnemyReplaceIdDic = {}
    -- 当前关卡成员替换的数据
    -- key : sourceId, value : targetId
    self.MemberReplaceIdDic = {}
    -- 当前关卡拥有的环境id
    self.EnvIds = {}
    -- 当前关卡拥有的加成id
    self.BuffIds = {}
    -- 当前选择的挑战分数
    self.ChallengeScore = 0
    -- 历史最高积分
    self.MaxScore = 0
    -- 当前改造关队伍数据
    self.TeamData = nil
    self.SaveTeamDataKey = nil
    self:InitEnemyGroup()
    self:InitMemberGroup()
    self:InitEnvironmentGroup()
    self:InitBuffGroup()
    self.Id = self.Config.Id
end

-- data : ReformStageDifficultyDb
function XReformEvolvableStage:InitWithServerData(data)
    self.MaxScore = data.Score
    self:UpdateEnemyReplaceIds(data.EnemyReplaceIds, false)
    self:UpdateMemberReplaceIds(data.MemberReplaceIds, false)
    self:UpdateEnvironmentIds(data.EnvIds, false)
    self:UpdateBuffIds(data.BuffIds, false)
    self:UpdateChallengeScore()
end

function XReformEvolvableStage:UpdateMaxScore(value)
    self.MaxScore = value
end

function XReformEvolvableStage:SetSaveTeamDataKey(value)
    self.SaveTeamDataKey = value .. XPlayer.Id .. XDataCenter.ReformActivityManager.GetId()
    self.TeamData = XSaveTool.GetData(self.SaveTeamDataKey)
end

function XReformEvolvableStage:GetId()
    return self.Config.Id
end

function XReformEvolvableStage:GetTeamData()
    if self.TeamData == nil then
        local memberGroup = self:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
        self.TeamData = {
            -- 默认都是空位置
            SourceIdsInTeam = {0, 0, 0},
            FirstFightPos = 1,
            CaptainPos = 1,
        }
    end
    return self.TeamData
end

function XReformEvolvableStage:SaveTeamData(data)
    self.TeamData = data
    if self.SaveTeamDataKey then
        XSaveTool.SaveData(self.SaveTeamDataKey, data)
    end
end

function XReformEvolvableStage:CheckEnvironmentMaxCount()
    return #self.EnvIds < self.Config.ReformEnvMaxCount
end

function XReformEvolvableStage:CheckBuffMaxCount()
    return #self.BuffIds < self.Config.ReformBuffMaxCount
end

function XReformEvolvableStage:GetMaxEnvrionmentCount()
    return self.Config.ReformEnvMaxCount
end

function XReformEvolvableStage:GetMaxBuffCount()
    return self.Config.ReformBuffMaxCount
end

function XReformEvolvableStage:GetMemberReplaceIdDic()
    return self.MemberReplaceIdDic
end

function XReformEvolvableStage:GetUnlockScore()
    return self.Config.UnlockScore
end

function XReformEvolvableStage:GetEnemyReplaceIdDic()
    return self.EnemyReplaceIdDic
end

function XReformEvolvableStage:UpdateEnemyReplaceIds(replaceIdDbs, isUpdateChallengeScore)
    self.EnemyReplaceIdDic = {}
    for _, replaceIdDb in ipairs(replaceIdDbs) do
        self.EnemyReplaceIdDic[replaceIdDb.SourceId] = replaceIdDb.TargetId
    end
    local enemyGroup = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Enemy]
    if not enemyGroup then return end
    if isUpdateChallengeScore == nil then isUpdateChallengeScore = true end
    enemyGroup:UpdateReplaceIdDic(self.EnemyReplaceIdDic)
    if isUpdateChallengeScore then
        self:UpdateChallengeScore()
    end
end

function XReformEvolvableStage:UpdateMemberReplaceIds(replaceIdDbs, isUpdateChallengeScore)
    self.MemberReplaceIdDic = {}
    for _, replaceIdDb in ipairs(replaceIdDbs) do
        self.MemberReplaceIdDic[replaceIdDb.SourceId] = replaceIdDb.TargetId
    end
    local memberGroup = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Member]
    if not memberGroup then return end
    if isUpdateChallengeScore == nil then isUpdateChallengeScore = true end
    memberGroup:UpdateReplaceIdDic(self.MemberReplaceIdDic)
    if isUpdateChallengeScore then
        self:UpdateChallengeScore()
    end
    -- 清除队伍数据
    local source
    local teamData = self:GetTeamData()
    for i, sourceId in ipairs(teamData.SourceIdsInTeam) do
        source = memberGroup:GetSourceById(sourceId)
        if source == nil or source:GetRobotId() == 0 then
            teamData.SourceIdsInTeam[i] = 0
        end
    end
    self:SaveTeamData(teamData)
end 

function XReformEvolvableStage:UpdateBuffIds(buffIds, isUpdateChallengeScore)
    self.BuffIds = buffIds
    local buffGroup = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Buff]
    if not buffGroup then return end
    if isUpdateChallengeScore == nil then isUpdateChallengeScore = true end    
    for _, buff in ipairs(buffGroup:GetBuffs()) do
        buff:SetIsActive(false)
    end
    local buff = nil
    for _, buffId in ipairs(buffIds) do
        buff = buffGroup:GetBuffById(buffId)
        if buff == nil then
            XLog.Warning(string.format("服务器加成Id%s在本地配置找不到", buffId))
        else
            buff:SetIsActive(true)
        end
    end
    if isUpdateChallengeScore then
        self:UpdateChallengeScore()
    end
end

function XReformEvolvableStage:UpdateEnvironmentIds(environmentIds, isUpdateChallengeScore)
    self.EnvIds = environmentIds
    local environmentGroup = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Environment]
    if not environmentGroup then return end
    if isUpdateChallengeScore == nil then isUpdateChallengeScore = true end
    for _, env in ipairs(environmentGroup:GetEnvironments()) do
        env:SetIsActive(false)
    end
    local env = nil
    for _, envId in ipairs(environmentIds) do
        env = environmentGroup:GetEnvironmentById(envId)
        if env == nil then
            XLog.Warning(string.format("服务器环境Id%s在本地配置找不到", envId))
        else
            env:SetIsActive(true)
        end
    end
    if isUpdateChallengeScore then
        self:UpdateChallengeScore()
    end
end

function XReformEvolvableStage:UpdateChallengeScore()
    local result = 0
    -- 敌人
    local enemyTargetConfig = nil
    local enemySourceConfig = nil
    for sourceId, targetId in pairs(self.EnemyReplaceIdDic) do        
        enemyTargetConfig = XReformConfigs.GetEnemyTargetConfig(targetId)
        if enemyTargetConfig then
            enemySourceConfig = XReformConfigs.GetEnemySourceConfig(sourceId)
            if enemySourceConfig.NpcId == 0 then
                result = result + enemySourceConfig.AddScore
            end
            result = result + enemyTargetConfig.AddScore
        end
    end
    -- 成员
    local memberTargetConfig = nil
    local memberSourceConfig = nil
    for sourceId, targetId in pairs(self.MemberReplaceIdDic) do        
        memberTargetConfig = XReformConfigs.GetMemberTargetConfig(targetId)
        if memberTargetConfig then
            memberSourceConfig = XReformConfigs.GetMemberSourceConfig(sourceId)
            if memberSourceConfig.RobotId == 0 then
                result = result - memberSourceConfig.SubScore
            end
            result = result - memberTargetConfig.SubScore
        end
    end
    -- 加成
    local buffConfig = nil
    for _, buffId in ipairs(self.BuffIds) do
        buffConfig = XReformConfigs.GetBuffConfig(buffId)
        result = result - buffConfig.SubScore
    end
    -- 环境
    local envConfig = nil
    for _, envId in ipairs(self.EnvIds) do
        envConfig = XReformConfigs.GetEnvironmentConfig(envId)
        result = result + envConfig.AddScore
    end
    self.ChallengeScore = result
end

function XReformEvolvableStage:GetBuffIds()
    return self.BuffIds
end

function XReformEvolvableStage:GetEnvIds()
    return self.EnvIds
end

function XReformEvolvableStage:GetDifficulty()
    -- 因为配置表从0开始，为了匹配lua下标特意+1
    return self.Config.Diff + 1
end

function XReformEvolvableStage:GetChallengeScore()
    return self.ChallengeScore
end

function XReformEvolvableStage:GetEvolvableGroupByType(groupType)
    return self.EvolvableGroupDic[groupType]
end

function XReformEvolvableStage:GetDefaultFirstGroupType()
    local result = {}
    for _, groupType in pairs(XReformConfigs.EvolvableGroupType) do
        if self:GetEvolvableGroupByType(groupType) then
            table.insert(result, groupType)
        end
    end
    table.sort(result, function(groupTypeA, groupTypeB)
        return XReformConfigs.GetGroupTypeSortWeight(groupTypeA) < XReformConfigs.GetGroupTypeSortWeight(groupTypeB)
    end)
    return result[1]
end

function XReformEvolvableStage:GetMaxScore()
    return self.MaxScore
end

function XReformEvolvableStage:GetName()
    return CS.XTextManager.GetText("ReformEvolvableStageName" .. self.Config.Diff)
end

--######################## 私有方法 ########################

function XReformEvolvableStage:InitEnemyGroup()
    local enemyGroupConfig = XReformConfigs.GetEnemyGroupConfig(self.Config.ReformEnemy)
    local enemyGroup = nil
    if enemyGroupConfig then
        enemyGroup = XReformEnemyGroup.New(enemyGroupConfig)
        self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Enemy] = enemyGroup
    end
end

function XReformEvolvableStage:InitMemberGroup()
    local memberGroupConfig = XReformConfigs.GetMemberGroupConfig(self.Config.ReformMember)
    local memberGroup = nil
    if memberGroupConfig then
        memberGroup = XReformMemberGroup.New(memberGroupConfig)
        self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Member] = memberGroup
    end
end

function XReformEvolvableStage:InitEnvironmentGroup()
    local environmentGroupConfig = XReformConfigs.GetEnvironmentGroupConfig(self.Config.ReformEnv)
    local environmentGroup = nil
    if environmentGroupConfig then
        environmentGroup = XReformEnvironmentGroup.New(environmentGroupConfig)
        self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Environment] = environmentGroup
    end
end

function XReformEvolvableStage:InitBuffGroup()
    local buffGroupConfig = XReformConfigs.GetBuffGroupConfig(self.Config.ReformBuff)
    local buffGroup = nil
    if buffGroupConfig then
        buffGroup = XReformBuffGroup.New(buffGroupConfig)
        self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Buff] = buffGroup
    end
end

return XReformEvolvableStage