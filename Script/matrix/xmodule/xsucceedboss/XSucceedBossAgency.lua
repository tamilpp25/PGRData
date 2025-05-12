local TableInsert = table.insert

local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XSucceedBossAgency : XAgency
---@field private _Model XSucceedBossModel
local XSucceedBossAgency = XClass(XFubenActivityAgency, "XSucceedBossAgency")
local ACTIVITY_NOT_IN_TIME_CODE = 20220001 -- 活动不在时间内ErrorCode
local SucceedBossProto = {
    SucceedBossSelectChapterRequest = "SucceedBossSelectChapterRequest", -- 选择章节
    SucceedBossSelectElementRequest = "SucceedBossSelectElementRequest", -- 选择弱点
    SucceedBossSelectMonsterRequest = "SucceedBossSelectMonsterRequest", -- 选择Boss（凹分章节使用）
    SucceedBossSetDefendCharacterRequest = "SucceedBossSetDefendCharacterRequest", -- 设置驻守角色
    SucceedBossSweepRequest = "SucceedBossSweepRequest", -- 扫荡
    SucceedBossResetChapterRequest = "SucceedBossResetChapterRequest", -- 重置章节
}

function XSucceedBossAgency:OnInit()
    self:RegisterActivityAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.SucceedBoss)
end

function XSucceedBossAgency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifySucceedBossData = function(data)
        if not XTool.IsTableEmpty(data.SucceedBossData) then
            self:_OnNotifySucceedBossData(data.SucceedBossData)
        end
    end
end

function XSucceedBossAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

function XSucceedBossAgency:GetCurActivityId()
    return self._Model:GetCurActivityId()
end

--function XSucceedBossAgency:ExOpenMainUi()
--    if self:CheckActivityOpen() then
--        XLuaUiManager.Open("UiSucceedBossMain")
--    else
--        XUiManager.TipText("SucceedBossActivityNotOpen")
--    end
--end

function XSucceedBossAgency:EnterActivity()
    if self:CheckActivityOpen() then
        XLuaUiManager.Open("UiSucceedBossMain")
        return true
    else
        XUiManager.TipText("SucceedBossActivityNotOpen")
    end
    
    return false
end

function XSucceedBossAgency:CheckActivityOpen()
    if XTool.IsTableEmpty(self._Model:GetSucceedGameData()) then
        return false
    end

    local curActivityId = self:GetCurActivityId()
    if not XTool.IsNumberValid(curActivityId) then
        return false
    end
    
    local timeId = self._Model:GetSucceedBossActivityTimeId(curActivityId)
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end

    return true
end

function XSucceedBossAgency:GetSucceedBossActivityConfigs()
    return self._Model:GetSucceedBossActivityConfigs()
end

function XSucceedBossAgency:GetTeam()
    return self._Model:GetTeam()
end

function XSucceedBossAgency:GetGarrisonEntityIds()
    local garrisonEntityIds = {}

    local curProgressIndex = self._Model:GetStageProgressIndex()
    local stageInfos = self._Model:GetCurStageInfos()
    for i = 1, curProgressIndex - 1 do
        if stageInfos[i] then
            local defendCharacterId = stageInfos[i]:GetDefendCharacterId()
            local defendRobotId = stageInfos[i]:GetDefendRobotId()
            local entityId = XTool.IsNumberValid(defendCharacterId) and defendCharacterId or defendRobotId
            if XTool.IsNumberValid(entityId) then
                garrisonEntityIds[entityId] = entityId
            end
        end
    end

    return garrisonEntityIds
end

--- 获取战斗房间的成员实体列表
function XSucceedBossAgency:GetActivityRobotsEntityList()
    local entities = {}
    local curActivityId = self:GetCurActivityId()
    if not XTool.IsNumberValid(curActivityId) then
        return entities
    end

    local activityCfg = self._Model:GetSucceedBossActivityById(curActivityId)
    for _, robotId in ipairs(activityCfg.RobotIds) do
        local entity = XRobotManager.GetRobotById(robotId)
        TableInsert(entities, entity)
    end

    return entities
end

-- 获取当前章节战斗成员实体列表（包括驻守成员）
function XSucceedBossAgency:GetTotalTeamEntityList()
    local entities = {}

    local team = self._Model:GetTeam()
    local entityIds = team:GetEntityIds()
    local garrisonEntityIds = self:GetGarrisonEntityIds()
    for _, entityId in pairs(XTool.MergeArray(entityIds, garrisonEntityIds)) do
        if XTool.IsNumberValid(entityId) then
            local entity = nil
            if XRobotManager.CheckIsRobotId(entityId) then
                entity = XRobotManager.GetRobotById(entityId)
            else
                entity = XMVCA.XCharacter:GetCharacter(entityId)
            end
            if not XTool.IsTableEmpty(entity) then

                TableInsert(entities, entity)
            end
        end
    end

    return entities
end

-- 判断章节是否上锁
function XSucceedBossAgency:CheckChapterUnLock(chapterId)
    local chapterConfig = self._Model:GetSucceedBossChapterById(chapterId)

    if XTool.IsNumberValid(chapterConfig.TimeId) then
        local nowTime = XTime.GetServerNowTimestamp()
        local startTime, endTime = XFunctionManager.GetTimeByTimeId(chapterConfig.TimeId)
        if nowTime < startTime then
            local mouth = XTime.TimestampToLocalDateTimeString(startTime, "MM")
            local day = XTime.TimestampToLocalDateTimeString(startTime, "dd")
            return false, XUiHelper.GetText("SucceedBossChapterLockTimeTips", mouth, day)
        elseif nowTime > endTime then
            return false, XUiHelper.GetText("SucceedBossChapterLockTimeEnd")
        end
    end

    if XTool.IsNumberValid(chapterConfig.PreChapter) then
        local preChapterPass = self:CheckChapterPass(chapterConfig.PreChapter)
        if not preChapterPass then
            return false, XUiHelper.GetText("SucceedBossChapterLockPreTips")
        end
    end

    return true
end

-- 判断章节是否通关
function XSucceedBossAgency:CheckChapterPass(chapterId)
    return self._Model:GetPassChapter(chapterId) ~= nil
end

-- 判断章节是否是凹分章节
function XSucceedBossAgency:CheckChapterIsOptional(chapterId)
    local chapterConfig = self._Model:GetSucceedBossChapterById(chapterId)
    return chapterConfig.Type == XEnumConst.SucceedBoss.ChapterType.Optional
end

-- 检查当前编队对于当前关卡是否合法
function XSucceedBossAgency:CheckTeamValid()
    local team = self._Model:GetTeam()
    -- 判断人数是否满足
    local teamEntityCount = self:GetCurTeamEntityCount()
    local stageProcess = self._Model:GetStageProgressIndex()
    if teamEntityCount ~= (4 - stageProcess) then
        return false, "SucceedBossTeamInvalidCount"
    end

    -- 判断首发和队长位
    if not XTool.IsNumberValid(team:GetCaptainPosEntityId()) or not XTool.IsNumberValid(team:GetFirstFightPosEntityId()) then
        return false, "SucceedBossTeamInvalidFirstPosOrCaptain"
    end

    return true
end

-- 检查当前进度是否能修改编队角色
function XSucceedBossAgency:CheckCanChangeTeamEntity()
    local stageProcess = self._Model:GetStageProgressIndex()
    return stageProcess == 1 -- 只有在第一关才能打开队伍预设
end

-- 检查是否是最后一关
function XSucceedBossAgency:CheckIsChapterEnd(stageSettleCount)
    -- 获取当前章节的关卡数量
    local curChapterId = self._Model:GetCurChapterId()
    local chapterConfig = self._Model:GetSucceedBossChapterById(curChapterId)
    return stageSettleCount == XTool.GetTableCount(chapterConfig.MonsterGroupIds)
end

-- 检查是否能查看驻守信息
function XSucceedBossAgency:CheckCanCheckGarrisonInfo()
    local stageProcess = self._Model:GetStageProgressIndex()
    return stageProcess > 1 -- 只有在第一关之后才能查看驻守信息
end

-- 检查当前章节当前进度下是否能够扫荡
function XSucceedBossAgency:CheckChapterStageCanSweep(notCheckStageInfo)
    local curChapterId = self._Model:GetCurChapterId()
    if not XTool.IsNumberValid(curChapterId) then
        return false
    end
    local chapterConfig = self._Model:GetSucceedBossChapterById(curChapterId)
    if XTool.IsTableEmpty(chapterConfig) then
        return false
    end

    local curProgressIndex = self._Model:GetStageProgressIndex()

    if not XTool.IsNumberValid(curProgressIndex) then
        return false
    end

    -- 在未选择弱点之前，都不存在stageInfos
    if not notCheckStageInfo then
        local stageInfos = self._Model:GetCurStageInfos()
        if not stageInfos[curProgressIndex] then
            return false
        end
    end

    return chapterConfig.CanSweep[curProgressIndex]
end

-- 检查怪物是否能扫荡
function XSucceedBossAgency:CheckMonsterCanSweep(monsterId, level)
    local passMonsterInfo = self._Model:GetPassMonster(monsterId)
    local isMonsterPassed = not XTool.IsTableEmpty(passMonsterInfo)
    if not isMonsterPassed then
        return false, XUiHelper.GetText("SucceedBossCanNotSweepMonsterPass")
    end

    local sweepScore = self._Model:GetSucceedBossMonsterLevelSweepScore(monsterId, level)
    if XTool.IsNumberValid(sweepScore) then
        local curChapterPassInfo = self._Model:GetPassChapter(self._Model:GetCurChapterId())
        if not curChapterPassInfo then
            return false, XUiHelper.GetText("SucceedBossCanNotSweepMonsterPass")
        else
            if curChapterPassInfo:GetMaxScore() < sweepScore then
                return false, XUiHelper.GetText("SucceedBossCanNotSweepMonsterScore", sweepScore)
            end
        end
    end

    --local chapterConfig = self._Model:GetSucceedBossChapterById(self._Model:GetCurChapterId())


    return true
end

function XSucceedBossAgency:CheckEntityIdIsGarrisoned(entityId)
    local stageInfos = self._Model:GetCurStageInfos()
    for _, stageInfo in pairs(stageInfos) do
        if stageInfo:GetDefendCharacterId() == entityId or stageInfo:GetDefendRobotId() == entityId then
            return true
        end
    end

    return false
end

function XSucceedBossAgency:CheckChapterInTime(chapterId)
    local chapterTimeId = self._Model:GetSucceedBossChapterTimeId(chapterId)
    return XFunctionManager.CheckInTimeByTimeId(chapterTimeId, true)
end

function XSucceedBossAgency:CheckCanEnterChapter(chapterId)
    -- 判断章节是否上锁
    if not self:CheckChapterUnLock(chapterId) then
        return false
    end

    -- 判断章节是否在章节活动时间内
    if not self:CheckChapterInTime(chapterId) then
        return false
    end

    return true
end

--region 战斗流程函数

function XSucceedBossAgency:CheckUnlockByStageId(stageId)
    return true
end

function XSucceedBossAgency:PreFight(stage, teamId, isAssist, challengeCount, challengeId)
    local preFight = {}

    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1

    local team = self._Model:GetTeam()
    preFight.CardIds = team:GetCharacterIdsOrder()
    preFight.RobotIds = team:GetRobotIdsOrder()
    preFight.CaptainPos = team:GetCaptainPos()
    preFight.FirstFightPos = team:GetFirstFightPos()

    if team and team.GetCurGeneralSkill then
        preFight.GeneralSkill = team:GetCurGeneralSkill()
    end

    return preFight
end

function XSucceedBossAgency:FinishFight(settleData)
    if not settleData then
        return
    end

    local succeedBossBattleResult = settleData.SucceedBossBattleResult
    if not succeedBossBattleResult then
        return
    end

    local battleResults = succeedBossBattleResult.BattleResults
    local passChapters = succeedBossBattleResult.PassChapters
    local passMonsters = succeedBossBattleResult.PassMonsters
    local chapterId = succeedBossBattleResult.ChapterId

    if settleData.IsWin then
        if self._Model:GetStageProgressIndex() == 1 then
            self._Model:SaveChapterLocalTeam() -- 战斗胜利后编队缓存到本地
            self._Model:SaveChapterLocalElementId()
        end
        self._Model:UpdateBattleResults(battleResults)
        local count = XTool.GetTableCount(battleResults)
        local isChapterEnd = self:CheckIsChapterEnd(count)
        if isChapterEnd then
            self:_UpdateChapterEnd(passChapters, passMonsters, chapterId)
            XLuaUiManager.Open("UiSucceedBossSettlement", battleResults, chapterId)
        else
            -- 更新进度
            self:_UpdateProgressIndex()
            XDataCenter.FubenManager.ChallengeWin(settleData) -- 暂时用通用界面代替，后续可能有新的
        end
        XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_RESULT_WIN)
    else
        XDataCenter.FubenManager.ChallengeLose(settleData)
    end
end

function XSucceedBossAgency:GetCurTeamEntityCount()
    local team = self._Model:GetTeam()
    if not team then
        return 0
    end

    local entityIds = team:GetEntityIds()

    local count = 0
    for _, entityId in pairs(entityIds) do
        if XTool.IsNumberValid(entityId) then
            count = count + 1
        end
    end

    return count
end

--endregion

--region 协议请求
-- 选择章节
function XSucceedBossAgency:RequestSucceedBossSelectChapter(chapterId, cb)
    local curChapterId = self._Model:GetCurChapterId()
    if XTool.IsNumberValid(curChapterId) and self._Model:GetCurChapterId() == chapterId then
        return
    end

    if not self:CheckChapterUnLock(chapterId) then
        XUiManager.TipText("ChapterLock")
        return
    end

    local elementId = self._Model:GetChapterLocalElementId(chapterId)

    XNetwork.Call(SucceedBossProto.SucceedBossSelectChapterRequest, { ChapterId = chapterId, ElementId = elementId }, function(res)
        if res.Code ~= XCode.Success then
            if self:_HandleProtoErrorCode(res.Code) then
                return
            end
            XUiManager.TipCode(res.Code)
            return
        end

        self:_HandleBattleInfo(res.BattleInfo)
        self._Model:ClearTeam()

        if cb then
            cb()
        end
    end)
end

-- 选择怪物
function XSucceedBossAgency:RequestSucceedBossSelectMonster(monsterId, monsterLevel, cb)
    local curChapterId = self._Model:GetCurChapterId()
    if not XTool.IsNumberValid(curChapterId) then
        XUiManager.TipText("SucceedBossChapterNotSelect")
        return
    end

    -- 检查当前进度下是否已经选择了该怪物和等级（选过就不选了）
    local stageInfos = self._Model:GetCurStageInfos()
    local curProgressIndex = self._Model:GetStageProgressIndex()
    if stageInfos[curProgressIndex] then
        local curMonsterId = stageInfos[curProgressIndex]:GetMonsterId()
        local curMonsterLevel = stageInfos[curProgressIndex]:GetMonsterLevel()
        if curMonsterId == monsterId and curMonsterLevel == monsterLevel then
            if cb then
                cb()
            end
            return
        end
    end

    XNetwork.Call(SucceedBossProto.SucceedBossSelectMonsterRequest, { ChapterId = curChapterId, MonsterId = monsterId, MonsterLevel = monsterLevel }, function(res)
        if res.Code ~= XCode.Success then
            if self:_HandleProtoErrorCode(res.Code) then
                return
            end
            XUiManager.TipCode(res.Code)
            return
        end

        self:_HandleBattleInfo(res.BattleInfo)

        if cb then
            cb()
        end
    end)
end

-- 选择弱点
function XSucceedBossAgency:RequestSucceedBossSelectElement(elementId, cb)
    local curChapterId = self._Model:GetCurChapterId()
    if not XTool.IsNumberValid(curChapterId) then
        XUiManager.TipText("SucceedBossChapterNotSelect")
        return
    end

    if not XTool.IsNumberValid(elementId) then
        XUiManager.TipText("SucceedBossElementNotSelect")
        return
    end
    
    XNetwork.Call(SucceedBossProto.SucceedBossSelectElementRequest, { ChapterId = curChapterId, ElementId = elementId }, function(res)
        if res.Code ~= XCode.Success then
            if self:_HandleProtoErrorCode(res.Code) then
                return
            end
            XUiManager.TipCode(res.Code)
            return
        end

        self:_HandleBattleInfo(res.BattleInfo)

        if cb then
            cb()
        end

        XEventManager.DispatchEvent(XEventId.EVENT_SUCCEED_BOSS_WEAKNESS_UPDATE)
    end)
end

-- 重置章节
function XSucceedBossAgency:RequestSucceedBossResetChapter(cb)
    XNetwork.Call(SucceedBossProto.SucceedBossResetChapterRequest, {}, function(res)
        if res.Code ~= XCode.Success then
            if self:_HandleProtoErrorCode(res.Code) then
                return
            end
            XUiManager.TipCode(res.Code)
            return
        end

        local isHasData = not XTool.IsTableEmpty(res.BattleInfo) -- 没有数据的情况是章节到期了

        if isHasData then
            self:_HandleBattleInfo(res.BattleInfo)
            self._Model:ClearChapterLocalTeam(res.BattleInfo.ChapterId)
            self._Model:ClearChapterLocalElementId(res.BattleInfo.ChapterId)
            self._Model:UpdateTeam()
        end

        if cb then
            cb(isHasData)
        end
    end)
end

-- 驻守成员
function XSucceedBossAgency:RequestSucceedBossSetDefendCharacter(entityId, cb)
    local curChapterId = self._Model:GetCurChapterId()
    if not XTool.IsNumberValid(curChapterId) then
        XUiManager.TipText("SucceedBossChapterNotSelect")
        return
    end

    if self:CheckEntityIdIsGarrisoned(entityId) then
        XUiManager.TipText("SucceedBossAlreadyGarrisoned")
        return
    end

    local characterId = 0
    local robotId = 0
    if XRobotManager.CheckIsRobotId(entityId) then
        robotId = entityId
    else
        characterId = entityId
    end

    XNetwork.Call(SucceedBossProto.SucceedBossSetDefendCharacterRequest, { ChapterId = curChapterId, CharacterId = characterId, RobotId = robotId }, function(res)
        if res.Code ~= XCode.Success then
            if self:_HandleProtoErrorCode(res.Code) then
                return
            end
            XUiManager.TipCode(res.Code)
            return
        end

        self:_HandleBattleInfo(res.BattleInfo)
        self._Model:UpdateTeamEntityIds() -- 相当于是用完全的编队还原一次
        self:_DoCheckTeamEntitiesValid()

        if cb then
            cb()
        end

        XEventManager.DispatchEvent(XEventId.EVENT_SUCCEED_BOSS_GARRISON_UPDATE)
    end)
end

-- 扫荡
function XSucceedBossAgency:RequestSucceedBossSweep(characterIds, robotIds, captainPos, FirstFightPos, cb)
    local curChapterId = self._Model:GetCurChapterId()
    if not XTool.IsNumberValid(curChapterId) then
        XUiManager.TipText("SucceedBossChapterNotSelect")
        return
    end

    if not self:CheckChapterStageCanSweep() then
        XUiManager.TipText("SucceedBossChapterStageCanNotSweep")
        return
    end

    local curStageInfo = self._Model:GetCurStageInfo()
    local isCanSweepMonster, desc = self:CheckMonsterCanSweep(curStageInfo:GetMonsterId(), curStageInfo:GetMonsterLevel())
    if not isCanSweepMonster then
        XUiManager.TipError(desc)
        return
    end

    local teamInfo = {
        CharacterIds = characterIds,
        RobotIds = robotIds,
        CaptainPos = captainPos,
        FirstFightPos = FirstFightPos,
    }
    
    XNetwork.Call(SucceedBossProto.SucceedBossSweepRequest, { ChapterId = curChapterId, TeamInfo = teamInfo }, function(res)
        if res.Code ~= XCode.Success then
            if self:_HandleProtoErrorCode(res.Code) then
                return
            end
            XUiManager.TipCode(res.Code)
            return
        end

        if self._Model:GetStageProgressIndex() == 1 then
            self._Model:SaveChapterLocalTeam() -- 战斗胜利后编队缓存到本地
            self._Model:SaveChapterLocalElementId()
        end

        local settleResult = res.SettleResult
        local battleResults = settleResult.BattleResults
        local passChapters = settleResult.PassChapters
        local passMonsters = settleResult.PassMonsters
        local chapterId = settleResult.ChapterId

        self._Model:UpdateBattleResults(battleResults)
        local count = XTool.GetTableCount(battleResults)
        local isChapterEnd = self:CheckIsChapterEnd(count)
        if isChapterEnd then
            self:_UpdateChapterEnd(passChapters, passMonsters, chapterId)
            XLuaUiManager.Open("UiSucceedBossSettlement", battleResults, chapterId)
        else
            -- 更新进度
            self:_UpdateProgressIndex()
        end

        if cb then
            cb(settleResult)
        end
    end)
end

--endregion

--region 红点判断

function XSucceedBossAgency:CheckTaskTabRedPoint(tabIndex)
    local curActivityConfig = self._Model:GetCurActivityConfig()
    if not curActivityConfig then
        return false
    end

    local taskGroups = curActivityConfig.TaskGroups
    if XTool.IsTableEmpty(taskGroups) then
        return false
    end

    if XTool.IsNumberValid(tabIndex) and XTool.IsNumberValid(taskGroups[tabIndex]) then
        return XDataCenter.TaskManager.CheckLimitTaskList(taskGroups[tabIndex])
    else
        for _, taskGroupId in pairs(taskGroups) do
            if XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId) then
                return true
            end
        end
    end

    return false
end

function XSucceedBossAgency:GetSelectChapterLocalCacheKey(chapterId)
    return "SucceedBossSelectChapter_" .. XPlayer.Id .. "_" .. self:GetCurActivityId() .. "_" .. chapterId
end

function XSucceedBossAgency:SaveSelectChapterLocalCache(chapterId)
    XSaveTool.SaveData(self:GetSelectChapterLocalCacheKey(chapterId), true)
end

function XSucceedBossAgency:CheckSelectChapterLocalCache(chapterId)
    if XSaveTool.GetData(self:GetSelectChapterLocalCacheKey(chapterId)) then
        return true
    end
end

function XSucceedBossAgency:CheckChapterRedPoint(chapterId)
    if XTool.IsNumberValid(chapterId) then
        if self:CheckCanEnterChapter(chapterId) and not self:CheckSelectChapterLocalCache(chapterId) then
            return true
        end
    else
        local curActivityId = self:GetCurActivityId()
        if not XTool.IsNumberValid(curActivityId) then
            return false
        end
        local chapterIds = self._Model:GetSucceedBossActivityChapterIds(curActivityId)
        for _, id in pairs(chapterIds) do
            if self:CheckChapterRedPoint(id) then
                return true
            end
        end
    end
end

function XSucceedBossAgency:ExCheckIsShowRedPoint()
    return self:CheckTaskTabRedPoint() or self:CheckChapterRedPoint()
end

--endregion

--region 外部检查

function XSucceedBossAgency:CheckIsOnChapter(chapterId)
    local curChapterId = self._Model:GetCurChapterId()
    if not XTool.IsNumberValid(curChapterId) then
        return false
    end

    return curChapterId == chapterId
end

function XSucceedBossAgency:CheckIsCanSweep()
    if not self:CheckChapterStageCanSweep() then -- 当前阶段不能扫荡
        return false
    end

    if not self:CheckTeamValid() then -- 编队不合法
        return false
    end
    
    return true
end

--endregion

----------public end----------

----------private start----------

function XSucceedBossAgency:_OnNotifySucceedBossData(data)
    self._Model:InitSucceedBossGameDataByNotify(data)
    self:_DoCheckTeamEntitiesValid() -- 首次下发数据时检查编队是否合法(要剔除驻守角色)
end

function XSucceedBossAgency:_HandleBattleInfo(battleInfo)
    self._Model:UpdateBattleInfo(battleInfo)
end

-- 更新进度
function XSucceedBossAgency:_UpdateProgressIndex()
    local curProgressIndex = self._Model:GetStageProgressIndex() -- 获取时已经+1
    self._Model:UpdateCurBattleProgress(curProgressIndex)
end

function XSucceedBossAgency:_UpdateChapterEnd(passChapters, passMonsters, chapterId)
    XSaveTool.SaveData("UiSucceedBossMainEffect" .. XPlayer.Id, chapterId)
    self._Model:UpdatePassChapters(passChapters)
    self._Model:UpdatePassMonsters(passMonsters)
    self._Model:ClearBattleInfo()
    self._Model:ClearTeam() -- 章节打完清空编队
end

-- 检查驻守信息，通过驻守信息更新编队
function XSucceedBossAgency:_DoCheckTeamEntitiesValid()
    local team = self._Model:GetTeam()
    local entityIds = team:GetEntityIds()
    local garrisonEntityIds = self:GetGarrisonEntityIds()
    local validEntityIds = {}
    for _, entityId in pairs(entityIds) do
        if garrisonEntityIds[entityId] == nil then
            TableInsert(validEntityIds, entityId)
        end
    end
    team:CheckEntitiesValid(validEntityIds)
end

function XSucceedBossAgency:_HandleProtoErrorCode(code)
    if code == ACTIVITY_NOT_IN_TIME_CODE then
        self:DispatchEvent(XEventId.EVENT_SUCCEED_BOSS_ERROR_CODE_ACTIVITY_NOT_IN_TIME)
        return true
    end
    
    return false
end

----------private end----------

function XSucceedBossAgency:GetStageProgressIndex()
    return self._Model:GetStageProgressIndex()
end

---@param team XTeam
function XSucceedBossAgency:CheckWeaknessUnuseful(team)
    local elementConfigId = self._Model:GetElementId()
    local elementId = self._Model:GetCharacterElementId(elementConfigId)
    
    local entityIds = team:GetEntityIds()
    local amount = 0
    for i, v in pairs(entityIds) do
        amount = amount + 1
    end
    -- 无效的队伍, 不进行弱点检测
    if amount == 0 then
        return false
    end
    
    if #entityIds == 0 then
        return false
    end
    
    for _, entityId in pairs(entityIds) do
        local elementList = XMVCA.XCharacter:GetCharacterAllElement(entityId, true)

        local isFind = false
        for j = 1, #elementList do
            local element = elementList[j]
            if element == elementId then
                isFind = true
                break
            end
        end
        if not isFind then
            return true
        end
    end
    return false
end

return XSucceedBossAgency