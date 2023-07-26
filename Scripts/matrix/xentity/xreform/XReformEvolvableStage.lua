local XReformEnemyGroup = require("XEntity/XReform/Enemy/XReformEnemyGroup")
local XReformMemberGroup = require("XEntity/XReform/Member/XReformMemberGroup")
local XReformEnvironmentGroup = require("XEntity/XReform/Environment/XReformEnvironmentGroup")
local XReformBuffGroup = require("XEntity/XReform/Buff/XReformBuffGroup")
local XReformStageTimeGroup = require("XEntity/XReform/StageTime/XReformStageTimeGroup")
local XTeam = require("XEntity/XTeam/XTeam")
local XReformEvolvableStage = XClass(nil, "XReformEvolvableStage")

-- config : XReformConfigs.StageDiffConfig
function XReformEvolvableStage:Ctor(config)
    -- XReformConfigs.StageDiffConfig
    self.Config = config
    -- XReformEnemyGroup | XReformMemberGroup | XReformEnvironmentGroup | XReformBuffGroup
    self.EvolvableGroupDic = {}
    -- 当前关卡成员替换的数据
    -- key : sourceId, value : targetId
    self.MemberReplaceIdDic = {}
    -- 当前关卡拥有的环境id
    self.EnvIds = {}
    -- 当前关卡拥有的加成id
    self.BuffIds = {}
    -- 当前关卡拥有的时间id
    self.StageTimeId = 0
    -- 当前选择的挑战分数
    self.ChallengeScore = 0
    -- 历史最高积分
    self.MaxScore = 0
    -- 当前改造关队伍数据, 已废弃，请使用self.Team
    -- self.TeamData = nil
    self.SaveTeamDataKey = nil
    self.InheritTeamKey = nil
    self:InitEnemyGroups()
    self:InitMemberGroup()
    self:InitEnvironmentGroup()
    self:InitBuffGroup()
    self:InitStageTimeGroup()
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

function XReformEvolvableStage:CheckStageTimeMaxCount()
    if self.StageTimeId <= 0 then
        return true
    end
    return false
end

function XReformEvolvableStage:GetStageTimeId()
    return self.StageTimeId
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

function XReformEvolvableStage:GetEnemyReplaceIdDic(groupIndex)
    if groupIndex == nil then groupIndex = 1 end
    local enemyGroup = self:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Enemy)[groupIndex]
    if enemyGroup == nil then return {} end
    return enemyGroup:GetReplaceIdDic()
end

function XReformEvolvableStage:GetEnemyGroupIndexById(enemyType, groupId)
    if enemyType == XReformConfigs.EnemyGroupType.NormanEnemy then
        for i, id in ipairs(self.Config.ReformEnemys) do
            if id == groupId then
                return i
            end
        end
    end
    if enemyType == XReformConfigs.EnemyGroupType.ExtraEnemy then
        for i, id in ipairs(self.Config.ExtraReformEnemys) do
            if id == groupId then
                return #self.Config.ReformEnemys + i
            end
        end
    end
end

function XReformEvolvableStage:UpdateEnemyReplaceIds(replaceIdDbs, isUpdateChallengeScore, enemyGroupId, enemyGroupType)
    local enemyReplaceIdDic = {}
    local tempReplaceIdDbDic = {}
    local groupIndex = self:GetEnemyGroupIndexById(enemyGroupType, enemyGroupId) or 0
    for _, replaceIdDb in ipairs(replaceIdDbs) do
        groupIndex = self:GetEnemyGroupIndexById(replaceIdDb.EnemyType, replaceIdDb.EnemyGroupId) or 0
        enemyReplaceIdDic[groupIndex] = enemyReplaceIdDic[groupIndex] or {}
        tempReplaceIdDbDic[groupIndex] = tempReplaceIdDbDic[groupIndex] or {}
        enemyReplaceIdDic[groupIndex][replaceIdDb.SourceId] = replaceIdDb.TargetId
        tempReplaceIdDbDic[groupIndex][replaceIdDb.SourceId] = replaceIdDb
    end
    local enemyGroups = self:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Enemy)
    if enemyGroups == nil then return end
    local replaceIdDbDic = nil
    for index, enemyGroup in ipairs(enemyGroups) do
        if isUpdateChallengeScore == nil then isUpdateChallengeScore = true end
        if enemyGroupId == nil 
            or (enemyGroupId == enemyGroup:GetId() and enemyGroupType == enemyGroup:GetEnemyGroupType()) then 
            enemyGroup:UpdateReplaceIdDic(enemyReplaceIdDic[index] or {}, isUpdateChallengeScore)
            replaceIdDbDic = tempReplaceIdDbDic[index]
            -- 更新敌人词缀改造
            enemyGroup:UpdateEnemyReformBuff(replaceIdDbDic)
            if isUpdateChallengeScore then
                self:UpdateChallengeScore()
            end 
        end
    end
    -- 根据groupIndex移除扩展波数数据
    if groupIndex > #self.Config.ReformEnemys and enemyReplaceIdDic[groupIndex] == nil then
        for i = #enemyGroups, groupIndex + 1, -1 do
            enemyGroups[i]:UpdateReplaceIdDic({}, isUpdateChallengeScore)
            enemyGroups[i]:UpdateEnemyReformBuff({})
        end
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

function XReformEvolvableStage:UpdateStageTimeId(id, isUpdateChallengeScore)
    self.StageTimeId = id
    local timeGroup = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.StageTime]
    if not timeGroup then return end
    if isUpdateChallengeScore == nil then isUpdateChallengeScore = true end
    for _, stageTime in ipairs(timeGroup:GetStageTimes()) do
        stageTime:SetIsActive(false)
    end
    local stageTime = timeGroup:GetStageTimeById(id)
    if stageTime then 
        stageTime:SetIsActive(true)    
    end
    if isUpdateChallengeScore then
        timeGroup:UpdateChallengeScore(id)
        self:UpdateChallengeScore()
    end
end

function XReformEvolvableStage:UpdateChallengeScore()
    local result = 0
    -- 敌人
    local enemyGroups = self:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Enemy)
    if enemyGroups then
        for _, enemyGroup in ipairs(enemyGroups) do
            result = result + enemyGroup:GetChallengeScore()
            -- 敌人词缀
            result = result + enemyGroup:GetBuffChallengeScore()
        end
    end
    -- 成员
    local group = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Member]
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
    -- 时间
    group = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.StageTime]
    if group then
        result = result + group:GetChallengeScore()
    end
    self.ChallengeScore = result
end

function XReformEvolvableStage:GetMaxChallengeScore(withTeamScore)
    if withTeamScore == nil then withTeamScore = false end
    local result = 0
    -- 敌人
    local enemyGroups = self:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Enemy)
    if enemyGroups then
        for _, enemyGroup in ipairs(enemyGroups) do
            result = result + enemyGroup:GetMaxChallengeScore()
            -- 敌人词缀
            result = result + enemyGroup:GetBuffMaxChallengeScore()
        end
    end
    -- 环境
    local group = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Environment]
    if group then
        result = result + group:GetMaxChallengeScore()
    end
    -- 成员
    group = self:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
    if group then
        if withTeamScore then
            result = result + group:GetTeamMaxChallengeScore()
        end
    end
    -- 时间
    group = self:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.StageTime)
    if group then
        result = result + group:GetMaxChallengeScore()
    end
    return result
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

function XReformEvolvableStage:GetChallengeScore(withTeamScore)
    if withTeamScore == nil then withTeamScore = false end
    local teamMemberScore = 0
    if withTeamScore then
        local team = self:GetTeam()
        local group = self:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
        local source
        for _, id in ipairs(team:GetEntityIds()) do
            if id > 0 then
                source = group:GetSourceById(id)
                if source then -- 源
                    teamMemberScore = teamMemberScore + source:GetScore()
                else -- 本地
                    teamMemberScore = teamMemberScore + group:GetRoleScoreByCharacterId(id)
                end
            end
        end
    end
    return self.ChallengeScore + teamMemberScore
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

function XReformEvolvableStage:GetTeamRoleScore(characterId)
    local memberGroup = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Member]
    if not memberGroup then return 0 end
    return memberGroup:GetRoleScoreByCharacterId(characterId)
end

function XReformEvolvableStage:GetEvolvableGroupCurrentScore(evolvableGroupType)
    local result = 0
    local group = self:GetEvolvableGroupByType(evolvableGroupType)
    if evolvableGroupType == XReformConfigs.EvolvableGroupType.Enemy then
        for _, value in ipairs(group) do
            result = result + value:GetChallengeScore()
        end
    elseif evolvableGroupType == XReformConfigs.EvolvableGroupType.EnemyBuff then
        for _, value in ipairs(group) do
            result = result + value:GetBuffChallengeScore()
        end
    else
        result = group:GetChallengeScore()
    end
    return result
end

function XReformEvolvableStage:GetEvolvableGroupMaxScore(evolvableGroupType)
    local result = 0
    local group = self:GetEvolvableGroupByType(evolvableGroupType)
    if evolvableGroupType == XReformConfigs.EvolvableGroupType.Enemy then
        for _, value in ipairs(group) do
            result = result + value:GetMaxChallengeScore()
        end
    elseif evolvableGroupType == XReformConfigs.EvolvableGroupType.EnemyBuff then
        for _, value in ipairs(group) do
            result = result + value:GetBuffMaxChallengeScore()
        end
    else
        result = group:GetMaxChallengeScore()
    end
    return result
end

--######################## 私有方法 ########################

function XReformEvolvableStage:InitEnemyGroups()
    if self.Config.ReformEnemys == nil and self.Config.ExtraReformEnemys == nil then return end
    self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Enemy] = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Enemy] or {}
    local enemyGroupConfig
    local enemyGroup = nil
    for index, enemyGroupId in ipairs(self.Config.ReformEnemys or {}) do
        enemyGroupConfig = XReformConfigs.GetEnemyGroupConfig(enemyGroupId)
        enemyGroup = nil
        if enemyGroupConfig then
            enemyGroup = XReformEnemyGroup.New(enemyGroupConfig)
            enemyGroup:SetEnemyGroupType(XReformConfigs.EnemyGroupType.NormanEnemy)
            enemyGroup:SetEnemyGroupIndex(index)
            table.insert(self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Enemy], enemyGroup)
        end
    end
    for index, enemyGroupId in ipairs(self.Config.ExtraReformEnemys or {}) do
        enemyGroupConfig = XReformConfigs.GetEnemyGroupConfig(enemyGroupId)
        enemyGroup = nil
        if enemyGroupConfig then
            enemyGroup = XReformEnemyGroup.New(enemyGroupConfig)
            enemyGroup:SetEnemyGroupType(XReformConfigs.EnemyGroupType.ExtraEnemy)
            enemyGroup:SetEnemyGroupIndex(#self.Config.ReformEnemys + index)
            table.insert(self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Enemy], enemyGroup)
        end
    end
    self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.EnemyBuff] = self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Enemy]
end

function XReformEvolvableStage:InitMemberGroup()
    if self.Config.ReformMember <= 0 then return end
    local memberGroupConfig = XReformConfigs.GetMemberGroupConfig(self.Config.ReformMember)
    local memberGroup = nil
    if memberGroupConfig then
        memberGroup = XReformMemberGroup.New(memberGroupConfig)
        self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Member] = memberGroup
    end
end

function XReformEvolvableStage:InitEnvironmentGroup()
    if self.Config.ReformEnv <= 0 then return end
    local environmentGroupConfig = XReformConfigs.GetEnvironmentGroupConfig(self.Config.ReformEnv)
    local environmentGroup = nil
    if environmentGroupConfig then
        environmentGroup = XReformEnvironmentGroup.New(environmentGroupConfig)
        environmentGroup:SetMaxSelectableCount(self:GetMaxEnvrionmentCount())
        self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Environment] = environmentGroup
    end
end

function XReformEvolvableStage:InitBuffGroup()
    if self.Config.ReformBuff <= 0 then return end
    local buffGroupConfig = XReformConfigs.GetBuffGroupConfig(self.Config.ReformBuff)
    local buffGroup = nil
    if buffGroupConfig then
        buffGroup = XReformBuffGroup.New(buffGroupConfig)
        self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.Buff] = buffGroup
    end
end

function XReformEvolvableStage:InitStageTimeGroup()
    if self.Config.ReformTimeEnv <= 0 then return end
    local timeGroupConfig = XReformConfigs.GetCfgByIdKey(XReformConfigs.TableKey.ReformTimeEnvGroup
        , self.Config.ReformTimeEnv)
    local timeGroup = nil
    if timeGroupConfig then
        timeGroup = XReformStageTimeGroup.New(timeGroupConfig)
        self.EvolvableGroupDic[XReformConfigs.EvolvableGroupType.StageTime] = timeGroup
    end
end

return XReformEvolvableStage