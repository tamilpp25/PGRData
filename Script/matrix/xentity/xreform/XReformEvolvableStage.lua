local XReformEnemyGroup = require("XEntity/XReform/Enemy/XReformEnemyGroup")
local XReformMemberGroup = require("XEntity/XReform/Member/XReformMemberGroup")
local XReformEnvironmentGroup = require("XEntity/XReform/Environment/XReformEnvironmentGroup")
local XReformBuffGroup = require("XEntity/XReform/Buff/XReformBuffGroup")
local XTeam = require("XEntity/XTeam/XTeam")
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
    -- 当前改造关队伍数据, 已废弃，请使用self.Team
    -- self.TeamData = nil
    self.SaveTeamDataKey = nil
    self.InheritTeamKey = nil
    self:InitEnemyGroup()
    self:InitMemberGroup()
    self:InitEnvironmentGroup()
    self:InitBuffGroup()
    self.Id = self.Config.Id
    -- XTeam
    self.Team = nil
end

-- data : ReformStageDifficultyDb
function XReformEvolvableStage:InitWithServerData(data)
    self.MaxScore = data.Score
    self:UpdateEnemyReplaceIds(data.EnemyReplaceIds, true)
    self:UpdateMemberReplaceIds(data.MemberReplaceIds, true)
    self:UpdateEnvironmentIds(data.EnvIds, true)
    self:UpdateBuffIds(data.BuffIds, true)
    self:UpdateChallengeScore()
end

function XReformEvolvableStage:UpdateMaxScore(value)
    self.MaxScore = value
end

function XReformEvolvableStage:SetSaveTeamDataKey(value)
    self.SaveTeamDataKey = value .. XPlayer.Id .. XDataCenter.ReformActivityManager.GetId()
    self.InheritTeamKey = self.SaveTeamDataKey .. "Inherit"
    self.TeamData = XSaveTool.GetData(self.SaveTeamDataKey)
end

function XReformEvolvableStage:GetId()
    return self.Config.Id
end

-- -- 已废弃，请使用GetTeam
-- function XReformEvolvableStage:GetTeamData()
--     if self.TeamData == nil then
--         local memberGroup = self:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
--         self.TeamData = {
--             -- 默认都是空位置
--             SourceIdsInTeam = {0, 0, 0},
--             FirstFightPos = 1,
--             CaptainPos = 1,
--         }
--     end
--     return self.TeamData
-- end

function XReformEvolvableStage:GetTeam()
    if self.Team == nil then
        self.Team = XTeam.New(self.SaveTeamDataKey .. "2.0")
        self.Team:SetCustomCharacterType(XCharacterConfigs.CharacterType.Normal)
    end
    return self.Team
end

-- 继承指定的队伍数据，并验证
-- stage : XReformEvolvableStage
function XReformEvolvableStage:InheritTeamFromEvolableStage(stage)
    local selfTeam = self:GetTeam()
    -- 自身队伍不是空的或者已经继承过的，就不需要再继承
    if not selfTeam:GetIsEmpty() 
        or XSaveTool.GetData(self.InheritTeamKey) then
        return
    end
    local selfGroup = self:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
    local fromTeam = stage:GetTeam()
    local fromGroup = stage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
    local characterIds = {}
    local characterId, fromSource, isLocal
    for pos, entityId in ipairs(fromTeam:GetEntityIds()) do
        fromSource = fromGroup:GetSourceById(entityId)
        if fromSource then -- 源
            characterId = fromSource:GetCharacterId()
            isLocal = false
        else -- 本地
            characterId = entityId
            isLocal = true
        end
        local result, sourceId = selfGroup:CheckSourcesWithSameCharacterId(characterId)
        if result then
            if isLocal then -- 本地的用回本地的
                selfTeam:UpdateEntityTeamPos(characterId, pos, true)
            else -- 用回源的
                selfTeam:UpdateEntityTeamPos(sourceId, pos, true)
            end
        end
    end
    selfTeam:UpdateFirstFightPos(fromTeam:GetFirstFightPos())
    selfTeam:UpdateCaptainPos(fromTeam:GetCaptainPos())
    XSaveTool.SaveData(self.InheritTeamKey, true)
end

-- function XReformEvolvableStage:SaveTeamData(data)
--     self.TeamData = data
--     if self.SaveTeamDataKey then
--         XSaveTool.SaveData(self.SaveTeamDataKey, data)
--     end
-- end

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
    enemyGroup:UpdateReplaceIdDic(self.EnemyReplaceIdDic, isUpdateChallengeScore)
    if isUpdateChallengeScore then
        self:UpdateChallengeScore()
    end
end

function XReformEvolvableStage:UpdateMemberReplaceIds(replaceIdDbs, isUpdateChallengeScore, isFromRequest)
    if isFromRequest == nil then isFromRequest = false end
    local memberGroup = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Member]
    if not memberGroup then return end
    local team = self:GetTeam()
    local oldTeamCharacterIdDic = {}
    if isFromRequest then
        -- 在更新前拿回旧队伍原来的角色id数据，为了后面方便作对比
        local oldSource
        for pos, sourceId in ipairs(team:GetEntityIds()) do
            oldSource = memberGroup:GetSourceById(sourceId)
            if oldSource then
                oldTeamCharacterIdDic[pos] = oldSource:GetCharacterId()
            end
        end
    end
    -- 更新替换数据
    self.MemberReplaceIdDic = {}
    for _, replaceIdDb in ipairs(replaceIdDbs) do
        self.MemberReplaceIdDic[replaceIdDb.SourceId] = replaceIdDb.TargetId
    end
    -- 更新分数数据
    if isUpdateChallengeScore == nil then isUpdateChallengeScore = true end
    memberGroup:UpdateReplaceIdDic(self.MemberReplaceIdDic, isUpdateChallengeScore)
    if isUpdateChallengeScore then
        self:UpdateChallengeScore()
    end
    -- 清除队伍数据
    local source
    for i, sourceId in ipairs(team:GetEntityIds()) do
        if sourceId > 0 then
            -- 如果是属于本地角色，要检查有没有同源角色
            if XDataCenter.CharacterManager.GetCharacter(sourceId) then
                if not memberGroup:CheckSourcesWithSameCharacterId(sourceId) then
                    team:UpdateEntityTeamPos(0, i, true)
                end
            else
                source = memberGroup:GetSourceById(sourceId)
                if source == nil or source:GetRobotId() <= 0
                    or (isFromRequest and oldTeamCharacterIdDic[i] ~= source:GetCharacterId()) then
                    team:UpdateEntityTeamPos(0, i, true)
                end
            end
        end
    end
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
        buffGroup:UpdateChallengeScore(buffIds)
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
        environmentGroup:UpdateChallengeScore(environmentIds)
        self:UpdateChallengeScore()
    end
end

function XReformEvolvableStage:UpdateChallengeScore()
    local result = 0
    -- 敌人
    local group = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Enemy]
    if group then
        result = result + group:GetChallengeScore()
    end
    -- 成员
    group = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Member]
    if group then
        result = result + group:GetChallengeScore()
    end
    -- 加成
    group = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Buff]
    if group then
        result = result + group:GetChallengeScore()
    end
    -- 环境
    group = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Environment]
    if group then
        result = result + group:GetChallengeScore()
    end
    self.ChallengeScore = result
end

function XReformEvolvableStage:GetMaxChallengeScore()
    if self.__MaxChallengeScore == nil then
        local result = 0
        -- 敌人
        local group = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Enemy]
        if group then
            result = result + group:GetMaxChallengeScore()
        end
        -- 环境
        group = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Environment]
        if group then
            result = result + group:GetMaxChallengeScore()
        end
        self.__MaxChallengeScore = result
    end
    return self.__MaxChallengeScore
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

-- groupType : XReformConfigs.EvolvableGroupType
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
        environmentGroup:SetMaxSelectableCount(self:GetMaxEnvrionmentCount())
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