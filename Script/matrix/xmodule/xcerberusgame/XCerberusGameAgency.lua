local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")
---@class XCerberusGameAgency : XFubenSimulationChallengeAgency
---@field private _Model XCerberusGameModel
local XCerberusGameAgency = XClass(XFubenSimulationChallengeAgency, "XCerberusGameAgency")

function XCerberusGameAgency:OnInit()
    --初始化一些变量
    self:RegisterChapterAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.CerberusGame)
end

function XCerberusGameAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyCerberusGameData = handler(self, self.NotifyCerberusGameData)
    XRpc.NotifyCerberusGameStageInfo = handler(self, self.NotifyCerberusGameStageInfo)
end

function XCerberusGameAgency:NotifyCerberusGameData(data)
    local data = data.CerberusGameData
    self:RefreshStoryPointDataByLoginServer(data)
    self:RefreshStageDataByLoginServer(data.StageInfos)
    self:SetLastSelectStoryLineDifficulty(nil) -- 每次下发，重置选择难度缓存
end

function XCerberusGameAgency:NotifyCerberusGameStageInfo(data)
    self:RefreshStageDataByLoginServer({data.CerberusGameStageInfo})
end

function XCerberusGameAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

--战斗相关接口
--region
-- function XCerberusGameAgency:InitStageInfo()
--     -- 剧情关stage
--     local allConfigsStory = self._Model:GetCerberusGameStoryPoint()
--     for k, config in pairs(allConfigsStory) do
--         if config.StoryPointType == XEnumConst.CerberusGame.StoryPointType.Battle or config.Type == XEnumConst.CerberusGame.StoryPointType.Story then
--             local stageId = tonumber(config.StoryPointTypeParams[1])
--             local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId) -- 1号位就是stageId
--             stageInfo.Type = XDataCenter.FubenManager.StageType.CerberusGame
--             self._Model.AllStoryStageIdDic[stageId] = stageId
--         end
--     end

--     -- 挑战关stage
--     local allConfigsChallenge = self._Model:GetCerberusGameChallenge()
--     for stageId, v in pairs(allConfigsChallenge) do
--         local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
--         stageInfo.Type = XDataCenter.FubenManager.StageType.CerberusGame
--         self._Model.AllChallengeStageIdDic[stageId] = stageId
--     end
-- end

function XCerberusGameAgency:CheckInSecondTimeActivity()
    local secondTimeId = self:GetClientConfigValueByKey("CerberusGameRound2Time")
    return XFunctionManager.CheckInTimeByTimeId(secondTimeId) 
end

function XCerberusGameAgency:CheckPassedByStageId(stageId)
    local xStage = self:GetXStageById(stageId)
    if xStage:GetXStoryPoint() then
        return xStage:GetXStoryPoint():GetIsPassed()
    end

    return xStage:GetIsPassed()
end

function XCerberusGameAgency:SetLastSelectXStoryPoint(xStoryPoint)
    self._Model.LastSelectXStoryPoint = xStoryPoint
end

function XCerberusGameAgency:GetLastSelectXStoryPoint()
    return self._Model.LastSelectXStoryPoint
end

function XCerberusGameAgency:SetLastSelectStoryLineDifficulty(difficulty)
    local key = "LastSelectStoryLineDifficulty"
    XSaveTool.SaveData(key, difficulty)
end

function XCerberusGameAgency:GetLastSelectStoryLineDifficulty()
    local key = "LastSelectStoryLineDifficulty"
    local data = XSaveTool.GetData(key)
    return data
end

function XCerberusGameAgency:SetLastSelectChapterStoryLineDifficulty(chapterId, difficulty)
    local key = "LastSelectChapterStoryLineDifficulty"
    local data = XSaveTool.GetData(key)
    if not data then
        data = {}
    end
    data[chapterId] = difficulty
    XSaveTool.SaveData(key, data)
end

function XCerberusGameAgency:GetLastSelectChapterStoryLineDifficulty(chapterId)
    local key = "LastSelectChapterStoryLineDifficulty"
    local data = XSaveTool.GetData(key)
    if not data then
        return nil
    end
    return data[chapterId]
end

function XCerberusGameAgency:PreFight(stage, xTeam, isAssist, challengeCount)
    local xStage = self:GetXStageById(stage.StageId)
    local preFight = {}
    preFight.CardIds = xTeam:GetCharacterIdsOrder()
    preFight.RobotIds = xTeam:GetRobotIdsOrder()
    preFight.CaptainPos = xTeam:GetCaptainPos()
    preFight.FirstFightPos = xTeam:GetFirstFightPos()
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1

    -- 检查extraRobotId
    local extraRobotId = nil
    local xStoryPoint = xStage:GetXStoryPoint()
    if xStoryPoint then
        extraRobotId = xStoryPoint:GetConfig().ExtraRobotId
    end
    local pos = nil
    for k, v in pairs(xTeam:GetEntityIds()) do
        if not XTool.IsNumberValid(v) then
            pos = k
            break
        end
    end
    if extraRobotId and pos then
        preFight.RobotIds[pos] = extraRobotId
    end

    return preFight
end

function XCerberusGameAgency:ShowReward(winData)
    local settleData = winData.SettleData
    local stageId = settleData.StageId
    local xStage = self:GetXStageById(stageId)
    xStage:SetPassed(true)
    local xStoryPoint = xStage:GetXStoryPoint()
    if xStoryPoint then
        xStoryPoint:SetPassed(true)
    end

    XLuaUiManager.Open("UiSettleWinMainLine", winData)
    -- XDataCenter.FubenManager.ShowReward(winData)
end
--endregion

function XCerberusGameAgency:CheckIsActivityOpen()
    if not XTool.IsNumberValid(self._Model.ActivityId) then
        return false
    end

    local config = self._Model:GetCerberusGameActivity()[self._Model.ActivityId]
    if not config then
        return false
    end

    local timeId = config.TimeId
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return
    end

    return true
end

function XCerberusGameAgency:GetActivityConfig()
    if not self:CheckIsActivityOpen() then
        return {}
    end

    return self._Model:GetCerberusGameActivity()[self._Model.ActivityId]
end

function XCerberusGameAgency:GetStortyChapterConfig()
    local challengeChapterId = XMVCA.XCerberusGame:GetChapterIdList()[XEnumConst.CerberusGame.ChapterIdIndex.Story]
    if not challengeChapterId then
        return {}
    end
    return self._Model:GetCerberusGameChapter()[challengeChapterId]
end

function XCerberusGameAgency:GetChallengeChapterConfig()
    local challengeChapterId = XMVCA.XCerberusGame:GetChapterIdList()[XEnumConst.CerberusGame.ChapterIdIndex.Challenge]
    if not challengeChapterId then
        return {}
    end
    return self._Model:GetCerberusGameChapter()[challengeChapterId]
end

function XCerberusGameAgency:GetBassRoleIdListForStoryMode(chapterId, difficulty)
    local allRoleIds = {}
    local allEnableRoleId = self._Model:GetCerberusGameRole()
    for k, v in pairs(allEnableRoleId) do
        if difficulty == v.Difficulty and chapterId == v.Chapter and XRobotManager.CheckIsRobotId(v.RoleId) then
            table.insert(allRoleIds, XRobotManager.GetRobotById(v.RoleId))

            local charId = XRobotManager.GetCharacterId(v.RoleId)
            if XMVCA.XCharacter:IsOwnCharacter(charId) then
                table.insert(allRoleIds, XMVCA.XCharacter:GetCharacter(charId))
            end
        end
    end

    return allRoleIds
end

-- 获取挑战能选择的角色列表
function XCerberusGameAgency:GetCanSelectRoleListForChallengeMode(stageId)
    local xConfig = self:CheckIsChallengeStage(stageId)
    if not xConfig then
        return {}
    end

    if xConfig then
        local ids = {}
        ids = appendArray(ids, xConfig.CharacterIds)
        ids = appendArray(ids, xConfig.RobotIds)
        local res = {}
        for k, id in pairs(ids) do
            if XRobotManager.CheckIsRobotId(id) then
                table.insert(res, XRobotManager.GetRobotById(id))
            else
                local charId = XRobotManager.GetCharacterId(id)
                if XMVCA.XCharacter:IsOwnCharacter(charId) then
                    table.insert(res, XMVCA.XCharacter:GetCharacter(charId))
                end
            end
        end
        return res
    end
    return {}
end

-- 获取剧情能选择的角色列表(会根据上一次点击过的StoryPoint来获取)
function XCerberusGameAgency:GetCanSelectRoleListForStoryMode(xStoryPoint)
    local xStoryPoint = xStoryPoint or self:GetLastSelectXStoryPoint()
    local baseRoleList = self:GetBassRoleIdListForStoryMode(xStoryPoint:GetChapterId(), self:GetLastSelectStoryLineDifficulty())
    local showEnableCharList = xStoryPoint:GetTargetCharacterList()
    -- 剔除不在StoryPointTypeParams的角色
    local res = {}
    for k, v in pairs(baseRoleList) do
        local checkId = v:GetId()
        if XRobotManager.CheckIsRobotId(checkId) then
            checkId = XRobotManager.GetCharacterId(checkId)
        end
        if table.contains(showEnableCharList, checkId) then
            table.insert(res, v)
        end
    end
    
    return res
end

-- 重置检查队伍逻辑
-- 1.如果队伍为空先检查自己或其他队伍是否有数据
-- 2.如果自己队伍有服务器数据则用自己的，否则用最近1个的关卡的队伍数据
-- 3.如果其他关卡队伍也没数据则用默认的队伍数据
-- 4.最后使用队伍数据赋值前，根据每个stage的情况剔除不能用的角色
-- 5.如果上阵了队伍还为空，则在1号为上阵1个战力最高的角色
function XCerberusGameAgency:ReInitXTeam(curStageIndex, stageId, canSeleRoleList, chapterId, currDifficulty)
    curStageIndex = curStageIndex or 1
    local xStage = self:GetXStageById(stageId)

    local serverXTeamInfo = self:CheckStageHasSaveTeamByServer(xStage.StageId)
    -- 查找最近的其他队伍
    if not serverXTeamInfo then
        local allCanUseTeamInfo = {}
        if self:CheckIsChallengeStage(stageId) then
            local storyIdList = self:GetChallegeIdListByDifficulty(currDifficulty)
            for k, stageId in pairs(storyIdList) do
                local teamInfo = self:CheckStageHasSaveTeamByServer(stageId)
                if teamInfo then -- 如果是这个章节的stage
                    table.insert(allCanUseTeamInfo, {Index = k, StageId = stageId, TeamInfo = teamInfo})
                end
            end
        else
            local storyLineCfg = self:GetStoryLineCfgByChapterAndDifficulty(chapterId, currDifficulty)
            -- 如果是剧情模式就查剧情的
            for k, storyPointId in pairs(storyLineCfg.StoryPointIds) do
                local xStoryPoint = self:GetXStoryPointById(storyPointId)
                local teamInfo = xStoryPoint.StageId and self:CheckStageHasSaveTeamByServer(xStoryPoint.StageId)
                if xStoryPoint.StageId and teamInfo then -- 如果是这个章节的stage
                    table.insert(allCanUseTeamInfo, {Index = k, StageId = xStoryPoint.StageId, TeamInfo = teamInfo})
                end
            end
        end

        -- 用距离当前节点最近的队伍数据
        table.sort(allCanUseTeamInfo, function (a, b)
            local absA = math.abs(a.Index - curStageIndex)
            local absB = math.abs(b.Index - curStageIndex)
            return absA < absB
        end)
        serverXTeamInfo = allCanUseTeamInfo[1] and allCanUseTeamInfo[1].TeamInfo
    end

    local tempRes = {CharacterIdList = {}, RobotIdList = {}}
    if serverXTeamInfo then
        -- 服务器队伍信息剔除
        for k, id in pairs(serverXTeamInfo.CharacterIdList) do
            if table.containsKey(canSeleRoleList, "Id",  id) then
                tempRes.CharacterIdList[k] = id
            else
                tempRes.CharacterIdList[k] = 0
            end
        end

        for k, id in pairs(serverXTeamInfo.RobotIdList) do
            if table.containsKey(canSeleRoleList, "Id",  id) then
                tempRes.RobotIdList[k] = id
            else
                tempRes.RobotIdList[k] = 0
            end
        end
        serverXTeamInfo.CharacterIdList = tempRes.CharacterIdList
        serverXTeamInfo.RobotIdList = tempRes.RobotIdList
        xStage:SetXTeamByServer(serverXTeamInfo)
        local xTeam = xStage:GetXTeam()
        if xTeam:GetIsEmpty() then
            local maxAblityRole = nil
            local maxAbility = 0
            for k, v in pairs(canSeleRoleList) do
                if v.Ability and (v.Ability > maxAbility) then
                    maxAbility = v.Ability
                    maxAblityRole = v
                end
            end
            if maxAblityRole then
                xTeam:UpdateEntityTeamPos(maxAblityRole.Id, 1, true)
            end
        end
        return    
    end

    tempRes = {}
    local defaultTeamList = self:GetDefaultTeamCharListByChapterAndDifficulty(chapterId, currDifficulty)
    for k, id in pairs(defaultTeamList) do
        -- 默认队伍剔除
        if table.containsKey(canSeleRoleList, "Id", id) then
            tempRes[k] = id
        else
            tempRes[k] = 0
        end
    end

    defaultTeamList = tempRes
    if not XTool.IsTableEmpty(defaultTeamList) then
        xStage:GetXTeam():UpdateEntityIds(defaultTeamList)
    end
end

-- 2.9重新更改编队逻辑，改为服务端记录绑定chapter编队
function XCerberusGameAgency:ReInitXTeamV2P9(canSeleRoleList, chapterId)
    local xTeam = self:GetXTeamByChapterId(chapterId)
    local allEntityIds = XTool.Clone(xTeam:GetEntityIds())

    -- 服务器队伍信息剔除
    for k, id in pairs(allEntityIds) do
        if table.containsKey(canSeleRoleList, "Id",  id) then
            allEntityIds[k] = id
        else
            allEntityIds[k] = 0
        end
    end
    xTeam:UpdateEntityIds(allEntityIds)
end

function XCerberusGameAgency:GetXStoryPointById(id)
    if not id then
        XLog.Error("GetXStoryPointById id 不能为空", id)
        return
    end

    local xStoryPoint = self._Model.StoryPointDic[id]
    if not xStoryPoint then
        local config = self._Model:GetCerberusGameStoryPoint()[id]
        if not config then
            XLog.Error("GetXStoryPointById ， 表CerberusGameStoryPoint 找不到Id", id)
            return
        end
        local XCerberusGameStoryPoint = require("XEntity/XCerberusGame/XCerberusGameStoryPoint")
        xStoryPoint = XCerberusGameStoryPoint.New(config)
        self._Model.StoryPointDic[id] = xStoryPoint
    end
    return xStoryPoint
end

function XCerberusGameAgency:GetStoryPointByStageIdPointDic(stageId)
    return self._Model:GetStoryPointByStageIdPointDic(stageId)
end

function XCerberusGameAgency:GetXStageById(stageId)
    if not stageId then
        XLog.Error("GetXStageById stageId 不能为空", stageId)
        return
    end

    local xStage = self._Model.StageIdDataDic[stageId]
    if not xStage then
        local XCerberusGameStage = require("XEntity/XCerberusGame/XCerberusGameStage")
        xStage = XCerberusGameStage.New(stageId)
        self._Model.StageIdDataDic[stageId] = xStage
    end
    return xStage
end

function XCerberusGameAgency:GetChapterIdByStageId(id)
    if XTool.IsTableEmpty(self._Model.StageIdChapterIdDic) then
        self._Model:CteateStageIdChapterIdDic()
    end

    local chapterId = self._Model.StageIdChapterIdDic[id]
    if not chapterId then
        XLog.Error("GetChapterIdByStageId 找不到StageId对应的ChapterId", id)
    end
    return chapterId
end

function XCerberusGameAgency:GetXTeamByChapterId(id)
    local xTeam = self._Model.ChapterTeamDic[id]
    if not xTeam then
        local XCerberusGameTeam = require("XEntity/XCerberusGame/XCerberusGameTeam")
        xTeam = XCerberusGameTeam.New(id)
        self._Model.ChapterTeamDic[id] = xTeam
    end
    return xTeam
end

function XCerberusGameAgency:GetStoryLineCfgByChapterAndDifficulty(chapterId, difficulty)
    for k, v in pairs(self._Model:GetCerberusGameStoryLine()) do
        if chapterId == v.ChapterId and v.Difficulty == difficulty then
            return v
        end
    end
end

-- 获得路线的总星数
function XCerberusGameAgency:GetAllStoryStarsCountByDifficulty(chapter, difficulty)
    local configs = self:GetStoryLineCfgByChapterAndDifficulty(chapter, difficulty)
    local count = 0
    for k, storyPointId in pairs(configs.StoryPointIds) do
        local xStoryPoint = self:GetXStoryPointById(storyPointId)
        if xStoryPoint.StageId then
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(xStoryPoint.StageId)
            count = count + #stageCfg.StarDesc
        end
    end
    return count
end

-- 获得路线的已达成星数
function XCerberusGameAgency:GetStoryActiveStarsCountByDifficulty(chapter, difficulty)
    local configs = self:GetStoryLineCfgByChapterAndDifficulty(chapter, difficulty)
    local count = 0
    for k, storyPointId in pairs(configs.StoryPointIds) do
        local xStoryPoint = self:GetXStoryPointById(storyPointId)
        if xStoryPoint.StageId then
            count = count + xStoryPoint:GetXStage():GetStarsCount()
        end
    end
    return count
end

-- 获取挑战模式的总星数
function XCerberusGameAgency:GetAllChallengeStarsCount(chapterId)
    local count = 0
    local allConfigs = self._Model:GetCerberusGameChallenge()
    for stageId, v in pairs(allConfigs) do
        if chapterId == v.ChapterId then
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
            count = count + #stageCfg.StarDesc
        end
    end
    return count
end

-- 获得挑战模式的已达成星数
function XCerberusGameAgency:GetChallengeActiveStarsCount(chapterId)
    local count = 0
    local allConfigs = self._Model:GetCerberusGameChallenge()
    for stageId, v in pairs(allConfigs) do
        if chapterId == v.ChapterId then
            local xStage = self:GetXStageById(stageId)
            count = count + xStage:GetStarsCount()
        end
    end
    return count
end

function XCerberusGameAgency:GetStoryPointIdsByDifficulty(difficulty)
    for k, v in pairs(self._Model:GetCerberusGameStoryLine()) do
        if v.Difficulty == difficulty then
            return v.StoryPointIds
        end
    end
end

function XCerberusGameAgency:GetStoryPointIdsByChapterId(chapterId)
    local res = {}
    for k, v in pairs(self._Model:GetCerberusGameStoryLine()) do
        if v.ChapterId == chapterId then
            res = appendArray(res, v.StoryPointIds)
        end 
    end
    return res
end

function XCerberusGameAgency:GetPassStoryIdsByDifficulty(difficulty)
    local ids = self:GetStoryPointIdsByDifficulty(difficulty)
    local count = 0
    for k, storyPointId in pairs(ids) do
        local xStoryPoint = self:GetXStoryPointById(storyPointId)
        if xStoryPoint:GetIsPassed() then
            count = count + 1
        end
    end
    return count
end

-- 挑战模式boss表
function XCerberusGameAgency:GetStageListByBossId(id)
    local allConfig = self._Model:GetCerberusGameBoss()
    local stageList = allConfig[id].StageId
    return stageList
end

-- 挑战模式stageId
function XCerberusGameAgency:GetChallengeStageIdListByChapterId(id)
    local allConfig = self._Model:GetCerberusGameChallenge()
    local res = {}
    for stageId, v in pairs(allConfig) do
        if v.ChapterId == id then
            table.insert(res, stageId)
        end
    end
    return res
end

function XCerberusGameAgency:GetChapterIdList()
    if not XTool.IsTableEmpty(self._Model.ChapterIdList) then
        return self._Model.ChapterIdList
    end

    local allConfig = self._Model:GetCerberusGameChapter()
    local res = {}
    for chapterId, v in pairs(allConfig) do
        table.insert(res, chapterId)
    end
    table.sort(res, function (a,b)
        return a < b
    end)
    self._Model.ChapterIdList = res
    return res
end

-- 获取默认队伍成员，返回3个charId组成的顺序table
function XCerberusGameAgency:GetDefaultTeamCharListByChapterAndDifficulty(chapterId, difficulty)
    if not chapterId or not difficulty then
        return
    end
    local cfgString = self._Model:GetCerberusGameChapter()[chapterId].DefaultTeam[difficulty]
    local teamList = string.Split(cfgString, '|')
    for k, v in pairs(teamList) do
        teamList[k] = tonumber(v)
    end
    return teamList
end

-- 获取storyLine的进度
function XCerberusGameAgency:GetProgressStoryLine(storyChapterId, difficult)
    local stortLineCfg = self:GetStoryLineCfgByChapterAndDifficulty(storyChapterId, difficult)
    local passCount = 0
    for k, storyPointId in pairs(stortLineCfg.StoryPointIds) do
        local xStoryPoint = self:GetXStoryPointById(storyPointId)
        if xStoryPoint:GetIsPassed() then
            passCount = passCount + 1
        end
    end
    return passCount, #stortLineCfg.StoryPointIds
end

function XCerberusGameAgency:GetProgressByChapterId(chapterId)
    local funName = "GetProgressChapter"
    local chapterIdList = self:GetChapterIdList()
    local _, chapterIndex = table.contains(chapterIdList, chapterId)
    local allEnum = XEnumConst.CerberusGame.ChapterIdIndex
    local isInEnum, enumKey = table.contains(allEnum, chapterIndex)
    if not isInEnum then
        return
    end

    local targetFunName = funName..enumKey
    local cur, total = self[targetFunName](self)
    return cur, total
end

-- 一期故事进度
function XCerberusGameAgency:GetProgressChapterStory()
    local storyChapterId = self:GetChapterIdList()[XEnumConst.CerberusGame.ChapterIdIndex.Story]
    local allStartCount1 = self:GetAllStoryStarsCountByDifficulty(storyChapterId, XEnumConst.CerberusGame.StageDifficulty.Normal)
    local allStartCount2 = self:GetAllStoryStarsCountByDifficulty(storyChapterId, XEnumConst.CerberusGame.StageDifficulty.Hard)
    local avtiveStarCount1 = self:GetStoryActiveStarsCountByDifficulty(storyChapterId, XEnumConst.CerberusGame.StageDifficulty.Normal)
    local avtiveStarCount2 = self:GetStoryActiveStarsCountByDifficulty(storyChapterId, XEnumConst.CerberusGame.StageDifficulty.Hard)
    local cur = avtiveStarCount1 + avtiveStarCount2
    local total = allStartCount1 + allStartCount2
    return cur, total
end

-- 一期挑战进度
function XCerberusGameAgency:GetProgressChapterChallenge()
    local chapterId = self:GetChapterIdList()[XEnumConst.CerberusGame.ChapterIdIndex.Challenge]
    local allStartCount = self:GetAllChallengeStarsCount(chapterId)
    local activeStartCount = self:GetChallengeActiveStarsCount(chapterId)
    return activeStartCount, allStartCount
end

-- 二期故事进度
function XCerberusGameAgency:GetProgressChapterFashionStory()
    local chapterId = self:GetChapterIdList()[XEnumConst.CerberusGame.ChapterIdIndex.FashionStory]
    local storyLineStageIdlist = XMVCA.XCerberusGame:GetStoryPointIdsByChapterId(chapterId)
    local cur = 0
    for k, storyPointId in pairs(storyLineStageIdlist) do
        local xStoryPoint = XMVCA.XCerberusGame:GetXStoryPointById(storyPointId)
        if xStoryPoint:GetIsPassed() then
            cur = cur + 1
        end
    end
    return cur, #storyLineStageIdlist
end

-- 二期挑战进度
function XCerberusGameAgency:GetProgressChapterFashionChallenge()
    local chapterId = self:GetChapterIdList()[XEnumConst.CerberusGame.ChapterIdIndex.FashionChallenge]
    local challengeStageIdList = XMVCA.XCerberusGame:GetChallengeStageIdListByChapterId(chapterId)
    local curr = 0
    for k, stageId in pairs(challengeStageIdList) do
        local xStage = XMVCA.XCerberusGame:GetXStageById(stageId)
        if xStage:GetIsPassed() then
            curr = curr + 1
        end
    end

    return curr, #challengeStageIdList
end

function XCerberusGameAgency:GetProgressTips()
    -- 1.剧情模式未通关
    local storyChapterId = self:GetChapterIdList()[XEnumConst.CerberusGame.ChapterIdIndex.Story]
    local allStartCount1 = self:GetAllStoryStarsCountByDifficulty(storyChapterId, XEnumConst.CerberusGame.StageDifficulty.Normal)
    local allStartCount2 = self:GetAllStoryStarsCountByDifficulty(storyChapterId, XEnumConst.CerberusGame.StageDifficulty.Hard)
    local avtiveStarCount1 = self:GetStoryActiveStarsCountByDifficulty(storyChapterId, XEnumConst.CerberusGame.StageDifficulty.Normal)
    local avtiveStarCount2 = self:GetStoryActiveStarsCountByDifficulty(storyChapterId, XEnumConst.CerberusGame.StageDifficulty.Hard)
    if (avtiveStarCount1 + avtiveStarCount2) < (allStartCount1 + allStartCount2) then
        local prog = (avtiveStarCount1 + avtiveStarCount2) / (allStartCount1 + allStartCount2)
        prog = string.format("%.0f%%", prog * 100)  -- 将小数转换为百分比字符串
        return CS.XTextManager.GetText("CerbrusGameStoryProgress", prog)
    end

    -- 2.挑战模式未通关
    local allStartCount = self:GetAllChallengeStarsCount()
    local activeStartCount = self:GetChallengeActiveStarsCount()
    if allStartCount < activeStartCount then
        local prog = allStartCount/activeStartCount
        prog = string.format("%.0f%%", prog * 100)
        return CS.XTextManager.GetText("CerbrusGameStoryProgress", prog)
    end

    return CS.XTextManager.GetText("SuperSmashFinish")
end

-- 检查该Stage是否被服务端存储过队伍数据
function XCerberusGameAgency:CheckStageHasSaveTeamByServer(stageId)
    local info = XTool.Clone(self._Model.StageTeamInfoByServer[stageId])
    return info
end

-- 特殊ui业务
function XCerberusGameAgency:CheckBtnFashionStoryRed()
    local key = string.format("%dCheckBtnFashionStoryRed", XPlayer.Id)
    local data = XSaveTool.GetData(key)
    if not data then
        return true
    end
    return false
end

function XCerberusGameAgency:CheckBtnFashionChallengeRed()
    local key = string.format("%dCheckBtnFashionChallengeRed", XPlayer.Id)
    local data = XSaveTool.GetData(key)
    if not data then
        return true
    end
    return false
end

function XCerberusGameAgency:SetBtnFashionStoryClick()
    local key = string.format("%dCheckBtnFashionStoryRed", XPlayer.Id)
    XSaveTool.SaveData(key, true)
end

function XCerberusGameAgency:SetBtnFashionChallengeClick()
    local key = string.format("%dCheckBtnFashionChallengeRed", XPlayer.Id)
    XSaveTool.SaveData(key, true)
end

function XCerberusGameAgency:RefreshStoryPointDataByLoginServer(data)
    self._Model.ActivityId = data.ActivityId
    for _, v in pairs(data.ChapterInfos) do
        for _, value in pairs(v.StoryLineInfos) do
            for _, id in pairs(value.PassStoryPoints) do
                local xStoryPoint = self:GetXStoryPointById(id)
                xStoryPoint:SetPassed(true)
            end
        end

        local xTeam = self:GetXTeamByChapterId(v.ChapterId)
        xTeam:RefreshDataByCerberuseTeamInfo(v.TeamInfo)
    end
end

function XCerberusGameAgency:RefreshStageDataByLoginServer(stageInfos)
    for k, v in pairs(stageInfos) do
        local xStage = self:GetXStageById(v.StageId)
        xStage:SetServerData(v)
        self._Model.StageTeamInfoByServer[v.StageId] = v.TeamInfo
    end
end

-- 开始请求通讯节点
function XCerberusGameAgency:StartCommunication(storyPointId)
    local xStoryPoint = self:GetXStoryPointById(storyPointId)
    if xStoryPoint:GetType() ~= XEnumConst.CerberusGame.StoryPointType.Communicate then
        return
    end

    local commId = xStoryPoint:GetCommunicationId()
    local cfg = self._Model:GetCerberusGameCommunication()[commId]
    if xStoryPoint:GetIsPassed() then
        XLuaUiManager.Open("UiFunctionalOpen", cfg, false, false)
        return
    end

    -- 首次通过要请求协议
    self:CerberusGamePassStoryPointRequest(storyPointId, function ()
        XLuaUiManager.Open("UiFunctionalOpen", cfg, false, false)
    end)
end

-- 网络请求 start
-- 手动请求通过的节点只有剧情和通讯，且只在剧情模式的普通难度有
function XCerberusGameAgency:CerberusGamePassStoryPointRequest(storyPointId, cb)
    local xStoryPoint = self:GetXStoryPointById(storyPointId)
    local storyLineId = xStoryPoint:GetStoryLineId()
    local storyCfg = self._Model:GetCerberusGameStoryLine()[storyLineId]
    local chapterId = storyCfg.ChapterId
    XNetwork.Call("CerberusGamePassStoryPointRequest", {ChapterId = chapterId, StoryPointId = storyPointId, StoryLineId = storyLineId}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local xStoryPoint = self:GetXStoryPointById(storyPointId)
        xStoryPoint:SetPassed(true)

        XEventManager.DispatchEvent(XEventId.EVENT_CERBERUS_GAME_PASS_STORY_POINT)
        
        if cb then
            cb()
        end
    end)
end

-- 三头犬的服务器队伍数据有 stage绑定队伍和chapter绑定队伍。在2.9弃用了stage队伍，但是数据结构不删除
---@param xCerberusTeam XCerberusGameTeam
function XCerberusGameAgency:CerberusGameSetTeamRequest(stageId, xCerberusTeam, cb)
    local teamInfo = {}
    teamInfo.CharacterIdList = xCerberusTeam:GetCharacterIdsOrder()
    teamInfo.RobotIdList = xCerberusTeam:GetRobotIdsOrder()
    teamInfo.CaptainPos = xCerberusTeam:GetCaptainPos()
    teamInfo.FirstFightPos = xCerberusTeam:GetFirstFightPos()

    XNetwork.Call("CerberusGameSetTeamRequest", {StageId = stageId, TeamInfo = teamInfo}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新一遍队伍
        self._Model.StageTeamInfoByServer[stageId] = teamInfo
        local xStage = self:GetXStageById(stageId)
        xStage:SetXTeamByServer(teamInfo)

        local chapterId = self:GetChapterIdByStageId(stageId)
        local xTeam = self:GetXTeamByChapterId(chapterId)
        xTeam:RefreshDataByCerberuseTeamInfo(teamInfo)
        
        if cb then
            cb()
        end
    end)
end
-- 网络请求 end

--- 活动本地缓存
function XCerberusGameAgency:GetCacheKey(keyName)
    return keyName.."CerberusGame"
end

-- 上一次选择的难度缓存
function XCerberusGameAgency:GetLastDifficultyCacheKey(chapterId)
    return self:GetCacheKey("GetLastDifficultyCacheKey")..chapterId..XPlayer.Id
end

function XCerberusGameAgency:GetLastDifficulty(chapterId)
    return XSaveTool.GetData(self:GetLastDifficultyCacheKey(chapterId))
end

function XCerberusGameAgency:SetLastDifficulty(chapterId, value)
    return XSaveTool.SaveData(self:GetLastDifficultyCacheKey(chapterId), value)
end

function XCerberusGameAgency:GetConfigByTableKey(tableKey)
    return self._Model:GetConfigByTableKey(tableKey)
end

function XCerberusGameAgency:GetTableKey()
    return self._Model:GetTableKey()
end

function XCerberusGameAgency:CheckIsChallengeStage(stageId)
    return self._Model:GetCerberusGameChallenge()[stageId]
end

function XCerberusGameAgency:GetChallegeIdListByDifficulty(difficulty)
    if XTool.IsTableEmpty(self._Model.ChallegeIdListByDifficulty) then
        self._Model:CreateChallegeIdListByDifficulty()
    end

    return self._Model.ChallegeIdListByDifficulty[difficulty]
end

-- complex config
function XCerberusGameAgency:GetClientConfigValueByKey(key)
    local config = self._Model:GetCerberusGameClientConfig()
    local value = config[key].Value
    if not value then
        return
    end
    
    if string.IsNumeric(value) then
        return tonumber(value)
    else
        return value
    end
end
-- complex config end

-- config
function XCerberusGameAgency:GetModelCerberusGameActivity()
    return self._Model:GetCerberusGameActivity()
end

function XCerberusGameAgency:GetModelCerberusGameChallenge()
    return self._Model:GetCerberusGameChallenge()
end

function XCerberusGameAgency:GetModelCerberusGameChapter()
    return self._Model:GetCerberusGameChapter()
end

function XCerberusGameAgency:GetModelCerberusGameCommunication()
    return self._Model:GetCerberusGameCommunication()
end

function XCerberusGameAgency:GetModelCerberusGameStoryLine()
    return self._Model:GetCerberusGameStoryLine()
end

function XCerberusGameAgency:GetModelCerberusGameStoryPoint() 
    return self._Model:GetCerberusGameStoryPoint() 
end

function XCerberusGameAgency:GetModelCerberusGameCharacterInfo() 
    return self._Model:GetCerberusGameCharacterInfo() 
end

function XCerberusGameAgency:GetModelCerberusGameBoss() 
    return self._Model:GetCerberusGameBoss() 
end

function XCerberusGameAgency:GetModelCerberusGameRole() 
    return self._Model:GetCerberusGameRole() 
end
-- config end

------------------副本入口扩展 start-------------------------
function XCerberusGameAgency:ExOpenMainUi()
    if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.CerberusGame) then
        return
    end
    if self:CheckInSecondTimeActivity() then
        XLuaUiManager.Open("UiCerberusGameMainV2P9")
        return
    end

    XLuaUiManager.Open("UiCerberusGameMain")
end

function XCerberusGameAgency:ExGetChapterType()
    return XDataCenter.FubenManager.ChapterType.CerberusGame
end

function XCerberusGameAgency:ExCheckInTime()
    local timeId = self:GetActivityConfig().TimeId
    if XFunctionManager.CheckInTimeByTimeId(timeId) then
        return true
    end
    return false
end

function XCerberusGameAgency:ExGetProgressTip()
    local text = ""
    local titleNameF = self:GetClientConfigValueByKey("CerberusGameName1")
    local titleNameS = self:GetClientConfigValueByKey("CerberusGameName2")
    local finishText = CS.XTextManager.GetText("SuperSmashFinish")

    -- 一期进度
    local curF, totalF = self:GetProgressChapterStory()
    local curF2, totalF2 = self:GetProgressChapterChallenge()
    local percentF =  math.modf((curF + curF2) / (totalF + totalF2) * 100 ) .. "%"
    local isFirstCompolete = curF + curF2 >= totalF + totalF2

    -- 二期进度
    local curS, totalS = self:GetProgressChapterFashionStory()
    local curS2, totalS2 = self:GetProgressChapterFashionChallenge()
    local percentS =  math.modf((curS + curS2) / (totalS + totalS2) * 100 ) .. "%"
    local isSecondCompolete = curS + curS2 >= totalS + totalS2
    if self:CheckInSecondTimeActivity() then
        if not isSecondCompolete then
            -- 2期活动 未完成
            text = titleNameS .. percentS
        else
            -- 2期活动 已完成
            if isFirstCompolete then
                -- 1期活动 已完成
                text = finishText
            else
                text = titleNameF .. percentF
            end
        end
    else
        if isFirstCompolete then
            text = finishText
        else
            text = titleNameF .. percentF
        end
    end

    return text
end

-- 重写活动入口
function XCerberusGameAgency:ExOverrideBaseMethod()
    return {
        ExGetProgressTip = function(proxy)
            -- 二期进度
            local curS, totalS = self:GetProgressChapterFashionStory()
            local curS2, totalS2 = self:GetProgressChapterFashionChallenge()
            local percentS = math.modf((curS + curS2) / (totalS + totalS2) * 100 ) .. "%"

            return CS.XTextManager.GetText("STStageProgress", percentS)
        end,
    }
end

------------------副本入口扩展 end-------------------------
----------public end----------

return XCerberusGameAgency