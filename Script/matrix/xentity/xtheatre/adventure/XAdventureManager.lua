local XAdventureChapter = require("XEntity/XTheatre/Adventure/XAdventureChapter")
local XAdventureDifficulty = require("XEntity/XTheatre/Adventure/XAdventureDifficulty")
local XAdventureMultiDeploy = require("XEntity/XTheatre/Adventure/Deploy/XAdventureMultiDeploy")
local XTheatreToken = require("XEntity/XTheatre/Token/XTheatreToken")
local XTheatreTeam = require("XEntity/XTheatre/XTheatreTeam")
local XAdventureRole = require("XEntity/XTheatre/Adventure/XAdventureRole")
local XAdventureSkill = require("XEntity/XTheatre/Adventure/XAdventureSkill")
local XAdventureEnd = require("XEntity/XTheatre/Adventure/XAdventureEnd")
local XAdventureManager = XClass(nil, "XAdventureManager")

function XAdventureManager:Ctor()
    -- 当前难度数据 XAdventureDifficulty
    self.CurrentDifficulty = nil
    -- 当前章节数据 XAdventureChapter
    self.CurrentChapter = nil
    -- 当前选择的信物 XTheatreToken
    self.CurrentToken = nil
    -- 当前可用的角色 XAdventureRole
    self.CurrentRoles = {}
    -- 多队伍编队管理
    self.AdventureMultiDeploy = XAdventureMultiDeploy.New()
    -- 当前冒险等级，可通过升级节点增加
    self.CurrentLevel = XTheatreConfigs.GetInitLevel()
    -- 已重开的次数
    self.ReopenedCount = 0
    -- 单队伍数据 XTheatreTeam
    self.SingleTeam = nil
    -- 当前的获取的技能 XAdventureSkill
    self.CurrentSkills = nil
    -- 当前操作队列
    self.OperationQueue = XQueue.New()
    -- 是否能够使用自己的角色
    self.CanUseLocalRole = false
    -- 当前获取的好感度
    self.CurrentFavorCoin = 0
    -- 当前获得的装修点
    self.CurrentDecorationCoin = 0
end

function XAdventureManager:InitWithServerData(data)
    local chapaterData = data.CurChapterDb
    -- 更新当前章节数据
    self.CurrentChapter = XAdventureChapter.New(chapaterData.ChapterId)
    self.CurrentChapter:InitWithServerData({
        RefreshRoleCount = chapaterData.RefreshRoleCount,   -- 刷新角色次数
        CurNodeDb = chapaterData.CurNodeDb, -- 当前节点数据
        RefreshRole = chapaterData.RefreshRole, -- 已刷新的角色
        -- 选择技能，战斗结束，发放选择技能奖励，重新登录恢复这页面
        SkillToSelect = chapaterData.SkillToSelect,
        PassNodeCount = data.PassNodeCount -- 当前已通过的节点数
        -- FavorCoin = data.FavorCoin, -- 当前章节获取的好感度
        -- DecorationCoin = data.DecorationCoin,   -- 当前章节获取的装修点
    })
    -- 更新当前难度
    self.CurrentDifficulty = XAdventureDifficulty.New(data.DifficultyId)
    -- 更新当前选择的信物
    if data.KeepsakeId > 0 then
        local tokenId = XDataCenter.TheatreManager.GetTokenManager():GetTokenId(data.KeepsakeId)
        self.CurrentToken = XTheatreToken.New(tokenId)
    end
    -- 更新当前冒险等级
    self:UpdateCurrentLevel(data.CurRoleLv)
    -- 更新已重开的次数
    self.ReopenedCount = data.ReopenCount
    -- 更新当前拥有的技能
    self.CurrentSkills = nil
    for _, skillId in ipairs(data.Skills) do
        self:AddSkill(skillId)
    end
    -- 更新当前可用的角色
    for _, roleId in ipairs(data.RecruitRole) do
        self:AddRoleById(roleId)
    end
    -- 更新是否能够使用自己的角色
    self.CanUseLocalRole = data.UseOwnCharacter == 1
    -- 更新好感度
    self.CurrentFavorCoin = data.FavorCoin
    -- 更新装修点
    self.CurrentDecorationCoin = data.DecorationCoin
    -- 更新单队伍数据
    self:UpdateTeamByServerData(self:GetSingleTeam(), data.SingleTeamData)
    -- 更新多队伍数据
    if data.MultiTeamDatas then
        for i, v in ipairs(data.MultiTeamDatas) do
            self:UpdateTeamByServerData(self:GetMultipleTeamByIndex(v.TeamIndex)
                , data.MultiTeamDatas[i])
        end
    end
end

function XAdventureManager:UpdateTeamByServerData(team, data)
    team:Clear()
    if data == nil then return end
    team:UpdateCaptainPos(data.CaptainPos)
    team:UpdateFirstFightPos(data.FirstFightPos)
    -- 本地角色处理
    for pos, id in ipairs(data.CardIds) do
        if id > 0 then
            team:UpdateEntityTeamPos(id, pos, true)
        end
    end
    -- 机器人角色处理
    for pos, id in ipairs(data.RobotIds) do
        if id > 0 then
            team:UpdateEntityTeamPos(self:GetRoleIdByRobotId(id)
                , pos, true)
        end
    end
end

function XAdventureManager:UpdateReopenCount(value)
    self.ReopenedCount = value
end

function XAdventureManager:UpdateUseOwnCharacter(value)
    self.CanUseLocalRole = value == 1
end

function XAdventureManager:UpdateCurrentFavorCoin(value)
    self.CurrentFavorCoin = value
end

function XAdventureManager:UpdateCurrentDecorationCoin(value)
    self.CurrentDecorationCoin = value
end

function XAdventureManager:GetCurrentFavorCoin()
    return self.CurrentFavorCoin
end

function XAdventureManager:GetCurrentDecorationCoin()
    return self.CurrentDecorationCoin
end

function XAdventureManager:Enter()
    if self.CurrentDifficulty == nil then
        -- 未选择难度
        XUiManager.TipErrorWithKey("TheatreNotSelectDifficulty")
        return
    end
    XDataCenter.TheatreManager.UpdateCurrentAdventureManager(self)
    -- 请求开始冒险
    self:RequestStartAdventure(function()
        self:EnterChapter()
    end)
end

function XAdventureManager:Release()
    self:ClearTeam()
end

function XAdventureManager:ClearTeam()
    if self.SingleTeam then 
        self.SingleTeam:Clear()
        self.SingleTeam = nil
    end
    self.AdventureMultiDeploy:ClearTeam()
end

function XAdventureManager:AddNextOperationData(data, isFront)
    if isFront then
        self.OperationQueue:EnqueueFront(data)
    else
        self.OperationQueue:Enqueue(data)
    end
end

function XAdventureManager:ShowNextOperation(callback)
    if self.OperationQueue:IsEmpty() then
        if callback then callback() end
        return
    end
    local data = self.OperationQueue:Dequeue()
    local chapter = self:GetCurrentChapter()
    if data.OperationQueueType == XTheatreConfigs.OperationQueueType.NodeReward then
        -- 技能选择奖励
        if data.RewardType == XTheatreConfigs.AdventureRewardType.SelectSkill then
            if table.nums(data.Skills) <= 0 then
                self:RequestOpenSkill(function(res)
                    XLuaUiManager.Open("UiTheatreChooseBuff", res.Skills
                    , function() self:ShowNextOperation(callback) end)
                end)
            else
                XLuaUiManager.Open("UiTheatreChooseBuff", data.Skills
                , function() self:ShowNextOperation(callback) end)
            end 
        -- 升级
        elseif data.RewardType == XTheatreConfigs.AdventureRewardType.LevelUp then
            XLuaUiManager.Open("UiTheatreTeamUp", data.LastLevel, data.LastAveragePower
            , function() self:ShowNextOperation(callback) end)
        -- 装修点
        elseif data.RewardType == XTheatreConfigs.AdventureRewardType.Decoration then
            XUiManager.OpenUiObtain({{
                RewardType = XRewardManager.XRewardType.Item,
                TemplateId = XTheatreConfigs.TheatreDecorationCoin,
                Count = data.DecorationPoint
            }}, nil, function() self:ShowNextOperation(callback) end)
        -- 好感度
        elseif data.RewardType == XTheatreConfigs.AdventureRewardType.PowerFavor then
            XUiManager.OpenUiObtain({{
                RewardType = XRewardManager.XRewardType.Item,
                TemplateId = XTheatreConfigs.TheatreFavorCoin,
                Count = data.FavorPoint
            }}, nil, function() self:ShowNextOperation(callback) end)
        end
    elseif data.OperationQueueType == XTheatreConfigs.OperationQueueType.ChapterSettle then
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.Remove("UiTheatrePlayMain")
            -- 进入下一个章节
            self:EnterChapter(data.LastChapteEndStoryId)    
        end, 1)
        -- if callback then callback() end
    elseif data.OperationQueueType == XTheatreConfigs.OperationQueueType.AdventureSettle then
        XDataCenter.TheatreManager.SetCurLoadSceneChapterId(nil)
        XLuaUiManager.Remove("UiTheatreContinue")
        XLuaUiManager.Remove("UiTheatreOutpost")
        XLuaUiManager.Remove("UiTheatrePlayMain")
        local adventureEnd = XAdventureEnd.New(data.SettleData.Ending)
        adventureEnd:InitWithServerData(data.SettleData)
        XLuaUiManager.Open("UiTheatreInfiniteSettleWin", adventureEnd, data.LastChapteEndStoryId)
        -- if callback then callback() end
    elseif data.OperationQueueType == XTheatreConfigs.OperationQueueType.BattleSettle then
        if table.nums(data.RewardGoodsList) > 0 then
            XUiManager.OpenUiObtain(data.RewardGoodsList
            , nil, function() self:ShowNextOperation(callback) end)
        else
            self:ShowNextOperation(callback)
        end
    end
end

function XAdventureManager:GetCurrentChapter(autoCreatre)
    if autoCreatre == nil then autoCreatre = true end
    if self.CurrentChapter == nil and autoCreatre then
        self:UpdateNextChapter()
    end
    return self.CurrentChapter
end

function XAdventureManager:CreatreChapterById(id)
    self.CurrentChapter = XAdventureChapter.New(id)
    return self.CurrentChapter
end

function XAdventureManager:UpdateNextChapter()
    if self.CurrentChapter == nil then
        self.CurrentChapter = XAdventureChapter.New(self:GetDefaultChapterId())
    else
        local nextChapterId = self.CurrentChapter:GetId() + 1
        if XTheatreConfigs.GetTheatreChapter(nextChapterId) then
            self.CurrentChapter = XAdventureChapter.New(nextChapterId)
        end
    end
end

-- 进入下一个章节
function XAdventureManager:EnterChapter(lastChapterStoryId)
    local currentChapter = self:GetCurrentChapter()
    -- 如果当前章节没有开启，直接触发冒险结算
    if not currentChapter:GetIsOpen(true) then
        -- 触发冒险结算
        self:RequestSettleAdventure()
        return
    end
    -- 打开章节开启界面
    XLuaUiManager.Remove("UiTheatreChoose")
    XLuaUiManager.Open("UiTheatreLoading", function()
        XDataCenter.TheatreManager.SetCurLoadSceneChapterId(currentChapter:GetId())
        currentChapter:SetIsReady(true)
        -- 如果有招募，打开成员招募界面
        if currentChapter:GetIsCanRecruit() then
            XLuaUiManager.Remove("UiTheatreContinue")
            XLuaUiManager.Open("UiTheatreRecruit", currentChapter:GetId(), true)
        else
            -- 进入选择界面
            XLuaUiManager.Open("UiTheatrePlayMain")
        end
    end, lastChapterStoryId)
end

function XAdventureManager:GetDefaultChapterId()
    return 1
end

-- token : XTheatreToken
function XAdventureManager:UpdateCurrentToken(token)
    self.CurrentToken = token
end

function XAdventureManager:GetCurrentToken()
    return self.CurrentToken
end

-- 检查是否能够使用本地角色
function XAdventureManager:CheckCanUseLocalRole()
    return self.CanUseLocalRole
end

-- includeLocal : 是否包含本地角色
function XAdventureManager:GetCurrentRoles(includeLocal)
    if includeLocal == nil then includeLocal = false end
    local canUseLocal = false
    if includeLocal then
        canUseLocal = self:CheckCanUseLocalRole()
        if canUseLocal then
            for _, role in ipairs(self.CurrentRoles) do
                role:GenerateLocalRole()
            end
        end
    end
    if includeLocal then return self.CurrentRoles end
    local result = {}
    for _, role in ipairs(self.CurrentRoles) do
        if not role:GetIsLocalRole() then 
            table.insert(result, role)
        end
    end
    return result
end

-- 获得已招募角色和剩余可招募的格子数
function XAdventureManager:GetRecruitTotalRoles()
    local adventureChapter = self:GetCurrentChapter()
    local currentRoles = self:GetCurrentRoles()
    currentRoles = XTool.Clone(currentRoles)

    local recruitGridCount = XTheatreConfigs.GetChapterRecruitGrid(adventureChapter:GetId())
    local lastGridCount = recruitGridCount - #currentRoles

    for i = 1, lastGridCount do
        table.insert(currentRoles, {})
    end

    return currentRoles
end

function XAdventureManager:AddRoleById(roleId, configId)
    if configId == nil then configId = roleId end
    for _, role in ipairs(self.CurrentRoles or {}) do
        if role:GetId() == roleId then 
            -- 重复添加
            return role
        end
    end
    table.insert(self.CurrentRoles, XAdventureRole.New(configId))
    return self.CurrentRoles[#self.CurrentRoles]
end

function XAdventureManager:GetRole(id)
    for _, role in ipairs(self:GetCurrentRoles(true)) do
        if role:GetId() == id then
            return role
        end
    end
end

-- 获取角色平均战力
function XAdventureManager:GeRoleAveragePower()
    local result = 0
    local roles = self:GetCurrentRoles(false)
    for _, role in ipairs(roles) do
        result = result + role:GetAbility()
    end
    if result == 0 then
        return 0
    end
    result = math.floor(result / #roles)
    return result
end

-- 获取开启的所有难度数据
function XAdventureManager:GetDifficulties(checkOpen)
    if checkOpen == nil then checkOpen = false end
    if self.__Difficulties == nil then
        self.__Difficulties = {}
        local difficultyConfigDic = XTheatreConfigs.GetTheatreDifficulty()
        for id, _ in pairs(difficultyConfigDic) do
            table.insert(self.__Difficulties, XAdventureDifficulty.New(id))
        end    
        table.sort(self.__Difficulties, function(a, b)
            return a:GetId() < b:GetId()
        end)
    end
    if checkOpen then
        local result = {}
        for _, difficulty in ipairs(self.__Difficulties) do
            if difficulty:GetIsOpen() then
                table.insert(result, difficulty)
            end
        end
        return result
    end
    return self.__Difficulties
end

function XAdventureManager:UpdateCurrentDifficulty(value)
    self.CurrentDifficulty = value
end

function XAdventureManager:GetCurrentDifficulty()
    return self.CurrentDifficulty
end
 
function XAdventureManager:GetPlayableCount()
    local currentDifficulty = self:GetCurrentDifficulty()
    local reopenCount = currentDifficulty and currentDifficulty:GetReopenCount() or 0
    XDataCenter.TheatreManager.GetDecorationManager():HandleActiveDecorationTypeParam(XTheatreConfigs.DecorationReopenOptionType
    , function(param)
        reopenCount = reopenCount + tonumber(param)
    end)
    return math.max(reopenCount - self.ReopenedCount, 0)
end

function XAdventureManager:GetSingleTeam()
    if self.SingleTeam == nil then
        self.SingleTeam = XTheatreTeam.New("Theatre_Adventure_Single_Team")
    end
    return self.SingleTeam
end

function XAdventureManager:GetMultipleTeamByIndex(index)
    return self.AdventureMultiDeploy:GetMultipleTeamByIndex(index)
end

function XAdventureManager:GetTeamById(id)
    if self.SingleTeam and self.SingleTeam:GetId() == id then 
        return self.SingleTeam
    end

    return self.AdventureMultiDeploy:GetTeamById(id)
end

function XAdventureManager:GetAdventureMultiDeploy()
    return self.AdventureMultiDeploy
end

-- 获取冒险等级
function XAdventureManager:GetCurrentLevel()
    return self.CurrentLevel
end

function XAdventureManager:UpdateCurrentLevel(value)
    self.CurrentLevel = value
    self:UpdateCurrentRoleRobots(value)
end

function XAdventureManager:UpdateCurrentRoleRobots(level)
    for _, role in ipairs(self.CurrentRoles) do
        if not role:GetIsLocalRole() then
            role:GenerateNewRobot(level)
        end
    end
end

function XAdventureManager:GetCurrentSkills()
    return self.CurrentSkills or {}
end

function XAdventureManager:GetCoreSkills()
    local result = {}
    local additionalSkillCount = 0
    for _, skill in ipairs(self:GetCurrentSkills()) do
        if skill:GetSkillType() == XTheatreConfigs.SkillType.Core then
            table.insert(result, skill)
        else
            additionalSkillCount = additionalSkillCount + 1
        end
    end
    table.sort(result, function(aSkill, bSkill)
        return aSkill:GetPos() < bSkill:GetPos()
    end)
    return result, additionalSkillCount
end

--获得对应位置的技能
function XAdventureManager:GetCoreSkillByPos(pos)
    local coreSkills = self:GetCoreSkills()
    for i, v in ipairs(coreSkills) do
        if v:GetPos() == pos then
            return v
        end
    end
end

function XAdventureManager:GetCoreSkillLv(skillType)
    local coreSkills = self:GetCoreSkills()
    for _, v in ipairs(coreSkills) do
        local skillTypeList = XTheatreConfigs.GetTheatreSkillPosDefineSkillType(v:GetPos())
        for _, skillTypeTemp in ipairs(skillTypeList) do
            if skillType == skillTypeTemp then
                return v:GetCurrentLevel()
            end
        end
    end
end

function XAdventureManager:GetAdditionSkillDic()
    local result = {}
    local powerCountDic = {}
    local powerId = nil
    for _, skill in ipairs(self:GetCurrentSkills()) do
        if skill:GetSkillType() == XTheatreConfigs.SkillType.Additional then
            powerId = skill:GetPowerId()
            if not powerCountDic[powerId] then
                table.insert(result, skill)
            end
            powerCountDic[powerId] = powerCountDic[powerId] and powerCountDic[powerId] + 1 or 1
        end
    end
    return result, powerCountDic
end

function XAdventureManager:AddSkill(id)
    self.CurrentSkills = self.CurrentSkills or {}
    table.insert(self.CurrentSkills, XAdventureSkill.New(id))
end

-- 获取当前所有技能附加的战力
function XAdventureManager:GetCurrentSkillsPower()
    local result = 0
    for _, skill in ipairs(self:GetCurrentSkills()) do
        result = result + skill:GetAdditionalPower()
    end
    return result
end

function XAdventureManager:EnterFight(inStageId, index, callback)
    if index == nil then index = 1 end
    local theatreStageConfig = XTheatreConfigs.GetTheatreStage(inStageId)
    -- 获取关卡id
    local stageId = theatreStageConfig and theatreStageConfig.StageId[index] or inStageId
    local team = nil
    local isMultiFight = theatreStageConfig and theatreStageConfig.StageCount > 1
    if isMultiFight then -- 使用多队伍的队伍数据
        team = self:GetMultipleTeamByIndex(index)
    else
        team = self:GetSingleTeam()
    end
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    if stageConfig == nil then return end
    local teamId = team:GetId()
    local isAssist = false
    local challengeCount = 1
    XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount, nil, callback)
end

function XAdventureManager:GetCardIdsAndRobotIdsFromTeam(team)
    local cardIds = {0, 0, 0}
    local robotIds = {0, 0, 0}
    local role
    for pos, entityId in ipairs(team:GetEntityIds()) do
        if entityId > 0 then
            role = self:GetRole(entityId)
            if role then 
                if role:GetIsLocalRole() then -- 本地角色
                    cardIds[pos] = role:GetRawDataId()
                else
                    robotIds[pos] = role:GetRawDataId()
                end
            else
                XLog.Error("肉鸽找不到角色，Id为" .. entityId)
            end
        end
    end
    return cardIds, robotIds
end

function XAdventureManager:GetRoleIdByRobotId(robotId)
    local configs
    for _, role in ipairs(self:GetCurrentRoles(false)) do
        configs = role:GetAllRobotConfigs()
        for _, config in ipairs(configs) do
            if config.RobotId == robotId then
                return config.RoleId
            end
        end
    end
end

-- function XAdventureManager:GetCurrentState()
--     return self.CurrentState
-- end

--######################## 协议 begin ########################

-- 请求开始冒险
function XAdventureManager:RequestStartAdventure(callback)
    local requestBody = {
        Difficulty = self.CurrentDifficulty:GetId(), -- 难度Id
        KeepsakeId = self.CurrentToken and self.CurrentToken:GetKeepsakeId() or nil, -- 信物id
    }
    self.CurrentChapter = nil -- 避免其他GetChapter时创建了默认的章节数据
    XNetwork.CallWithAutoHandleErrorCode("TheatreStartAdventureRequest", requestBody, function(res)
        -- hack : 服务器通知节点有可能比该请求返回还要快，因此如果不为空就用节点通知的
        if self.CurrentChapter == nil then
            self.CurrentChapter = XAdventureChapter.New(res.ChapterId)
        end
        -- 进入默认章节
        if callback then callback() end
    end)
end

-- 请求结束冒险
function XAdventureManager:RequestSettleAdventure(callback)
    local requestBody = {}
    XNetwork.CallWithAutoHandleErrorCode("TheatreSettleAdventureRequest", requestBody, function(res)
        -- 更新全局通过的章节和事件数据
        local theatreManager = XDataCenter.TheatreManager
        theatreManager.SetCurLoadSceneChapterId(nil)
        theatreManager.UpdatePassChapterIds(res.SettleData.PassChapterId)
        theatreManager.UpdatePassEventRecord(res.SettleData.PassEventRecord)
        theatreManager.UpdateEndingIdRecords(res.SettleData.EndingRecord)
        -- 清除队伍数据
        self:ClearTeam()
        -- 打开结算冒险界面
        local adventureEnd = XAdventureEnd.New(res.SettleData.Ending)
        adventureEnd:InitWithServerData(res.SettleData)
        if callback then callback() end
        XLuaUiManager.Open("UiTheatreInfiniteSettleWin", adventureEnd)
    end)
end

function XAdventureManager:RequestOpenSkill(callback)
    XNetwork.CallWithAutoHandleErrorCode("TheatreNodeShopOpenSkillRequest", {}, function(res)
        if callback then callback(res) end
    end)
end

-- operationType : XTheatreConfigs.SkillOperationType
-- fromSkill : XAdventureSkill
function XAdventureManager:RequestSelectSkill(skillId, operationType, fromSkill, callback)
    local requestBody = {
        SkillId = skillId,
    }
    XNetwork.CallWithAutoHandleErrorCode("TheatreSelectSkillRequest", requestBody, function(res)
        if (operationType == XTheatreConfigs.SkillOperationType.LevelUp and skillId ~= fromSkill:GetId())
            or operationType == XTheatreConfigs.SkillOperationType.Replace then
            local currentSkills = self:GetCurrentSkills()
            for i = #currentSkills, 1, -1 do
                if currentSkills[i]:GetId() == fromSkill:GetId() then
                    table.remove(currentSkills, i)
                    break
                end
            end
        end
        XDataCenter.TheatreManager.GetTokenManager():UpdateSkillPowerAndPosToSkillIdDic({skillId})
        self:AddSkill(skillId)
        if callback then callback() end
    end)
end

function XAdventureManager:RequestSkipSelectSkill(callback)
    XNetwork.CallWithAutoHandleErrorCode("TheatreSkipSelectSkillRequest", {}, function(res)
        if callback then callback() end
    end)
end

-- 请求设置单队伍
function XAdventureManager:RequestSetSingleTeam(callback)
    local cardIds, robotIds = self:GetCardIdsAndRobotIdsFromTeam(self.SingleTeam)
    local requestBody = {
        TeamData = {
            TeamIndex = 0,
            CaptainPos = self.SingleTeam:GetCaptainPos(),
            FirstFightPos = self.SingleTeam:GetFirstFightPos(),
            CardIds = cardIds,
            RobotIds = robotIds,
        }
    }
    XNetwork.CallWithAutoHandleErrorCode("TheatreSetSingleTeamRequest", requestBody, function(res)
        if callback then callback() end
    end)
end

--######################## 协议 end ########################

return XAdventureManager