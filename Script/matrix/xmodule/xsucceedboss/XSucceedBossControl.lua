local TableInsert = table.insert

---@class XSucceedBossControl : XControl
---@field private _Model XSucceedBossModel
local XSucceedBossControl = XClass(XControl, "XSucceedBossControl")
function XSucceedBossControl:OnInit()
end

function XSucceedBossControl:AddAgencyEvent()
    XMVCA.XSucceedBoss:AddEventListener(XEventId.EVENT_SUCCEED_BOSS_ERROR_CODE_ACTIVITY_NOT_IN_TIME, self._OnErrorCodeActivityNotInTime, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_BEFORE_ENTER, self._OnEnterFight, self)
end

function XSucceedBossControl:RemoveAgencyEvent()
    XMVCA.XSucceedBoss:RemoveEventListener(XEventId.EVENT_SUCCEED_BOSS_ERROR_CODE_ACTIVITY_NOT_IN_TIME, self._OnErrorCodeActivityNotInTime, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_BEFORE_ENTER, self._OnEnterFight, self)
end

function XSucceedBossControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

function XSucceedBossControl:GetActivityTitle()
    return self._Model:GetCurActivityConfig().Name
end

function XSucceedBossControl:GetActivityShowRewardId()
    return self._Model:GetCurActivityConfig().ShowRewardId
end

function XSucceedBossControl:GetActivityTaskGroups()
    return self._Model:GetCurActivityConfig().TaskGroups
end

function XSucceedBossControl:GetStartAndEndTime()
    local config = self._Model:GetCurActivityConfig()
    local timeId = config.TimeId
    if XTool.IsNumberValid(timeId) then
        local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
        return startTime, endTime
    end
end

function XSucceedBossControl:HandleActivityEndTime()
    XLuaUiManager.RunMain()
    XUiManager.TipText("ActivityAlreadyOver")
end

--region 配置相关
function XSucceedBossControl:GetChapterIds()
    local config = self._Model:GetCurActivityConfig()
    return config.ChapterIds
end

function XSucceedBossControl:GetChapterConfig(id)
    return self._Model:GetSucceedBossChapterById(id)
end

function XSucceedBossControl:GetMonsterGroupConfig(id)
    return self._Model:GetSucceedBossMonsterGroupById(id)
end

function XSucceedBossControl:GetMonsterConfig(id)
    return self._Model:GetSucceedBossMonsterById(id)
end

function XSucceedBossControl:GetAllFightEventShowConfig()
    return self._Model:GetAllFightEventShowConfig()
end

function XSucceedBossControl:GetFightEventShowConfig(fightEventId)
    return self._Model:GetFightEventShowConfigById(fightEventId)
end

function XSucceedBossControl:GetSucceedBossElementName(elementId)
    return self._Model:GetSucceedBossElementName(elementId)
end

function XSucceedBossControl:GetSucceedBossElementIcon(elementId)
    return self._Model:GetSucceedBossElementIcon(elementId)
end

function XSucceedBossControl:GetSucceedBossElementDesc(elementId)
    return self._Model:GetSucceedBossElementDesc(elementId)
end

function XSucceedBossControl:GetMonsterLevelScore(monsterId, level)
    return self._Model:GetSucceedBossMonsterLevelMonsterScore(monsterId, level)
end

function XSucceedBossControl:GetMonsterLevelConfig(monsterId, level)
    return self._Model:GetSucceedBossMonsterLevelConfigByIdAndLevel(monsterId, level)
end
--endregion

function XSucceedBossControl:SaveSelectChapterLocalCache(chapterId)
    self._Agency:SaveSelectChapterLocalCache(chapterId)
end

--获取当前活动Id
function XSucceedBossControl:GetCurActivityId()
    return self._Model:GetCurActivityId()
end

--获取当前章节Id
function XSucceedBossControl:GetCurrentChapterId()
    return self._Model:GetCurChapterId()
end

function XSucceedBossControl:GetFightingChapterId()
    return self._Model:GetFightingChapterId()
end

function XSucceedBossControl:GetChapterIndex(chapterId)
    local index
    local chapterIds = self:GetChapterIds()
    for i, id in ipairs(chapterIds) do
        if id == chapterId then
            index = i
        end
    end
    return index
end

--获取当前章节的关卡进度
function XSucceedBossControl:GetStageProgressIndex()
    return self._Model:GetStageProgressIndex()
end

-- 获取当前选择的关卡信息
function XSucceedBossControl:GetCurStageInfos()
    return self._Model:GetCurStageInfos()
end

--获取当前章节当前关卡的技能战斗事件Id（包括之前通关的关卡继承）
function XSucceedBossControl:GetCurrentSkillFightEventIds()
    local curFightEventIds = {}
    local stageProgressIndex = self._Model:GetStageProgressIndex()
    local stageInfos = self._Model:GetCurStageInfos()
    local hasNew = false
    for i = 1, stageProgressIndex do
        if stageInfos[i] then
            local monsterId = stageInfos[i]:GetMonsterId()
            local monsterConfig = self:GetMonsterConfig(monsterId)
            if monsterConfig then
                local skillFightEventId = monsterConfig.SkillFightEventId
                if XTool.IsNumberValid(skillFightEventId) then
                    TableInsert(curFightEventIds, skillFightEventId)
                    if i == stageProgressIndex then
                        hasNew = true
                    end
                end
            end
        end
    end

    return curFightEventIds, hasNew
end

--获取当前章节当前关卡的技能战斗事件Id（包括之前通关的关卡继承）(凹分关)
function XSucceedBossControl:GetCurrentSkillFightEventIdsOptional(selectBossIndex)
    local curFightEventIds = {}
    local stageInfos = self._Model:GetCurStageInfos()
    local stageProgressIndex = self._Model:GetStageProgressIndex()
    for i = 1, stageProgressIndex - 1 do
        if stageInfos[i] then
            local monsterId = stageInfos[i]:GetMonsterId()
            local monsterConfig = self:GetMonsterConfig(monsterId)
            if monsterConfig then
                local skillFightEventId = monsterConfig.SkillFightEventId
                if XTool.IsNumberValid(skillFightEventId) then
                    TableInsert(curFightEventIds, skillFightEventId)
                end
            end
        end
    end

    local hasNew = false
    if XTool.IsNumberValid(selectBossIndex) then
        local curChapterId = self:GetCurrentChapterId()
        local monsterGroupIds = self:GetChapterConfig(curChapterId).MonsterGroupIds
        local monsterGroupId = monsterGroupIds[stageProgressIndex]
        local monsterGroupConfig = self:GetMonsterGroupConfig(monsterGroupId)
        local monsterId = monsterGroupConfig.MonsterIds[selectBossIndex]
        local monsterConfig = self:GetMonsterConfig(monsterId)
        if monsterConfig then
            local skillFightEventId = monsterConfig.SkillFightEventId
            if XTool.IsNumberValid(skillFightEventId) then
                TableInsert(curFightEventIds, skillFightEventId)
                hasNew = true
            end
        end
    end

    return curFightEventIds, hasNew
end

--获取当前章节当前关卡的Buff战斗事件Id（包括之前通关的关卡继承）
function XSucceedBossControl:GetCurrentBuffFightEventIds()
    local curFightEventIds = {}
    local stageProgressIndex = self._Model:GetStageProgressIndex()
    local stageInfos = self._Model:GetCurStageInfos()
    for i = 1, stageProgressIndex do
        if stageInfos[i] then
            local monsterId = stageInfos[i]:GetMonsterId()
            local monsterConfig = self:GetMonsterConfig(monsterId)
            if monsterConfig then
                local buffFightEventId = monsterConfig.BuffFightEventId
                if XTool.IsNumberValid(buffFightEventId) then
                    TableInsert(curFightEventIds, buffFightEventId)
                end
            end
        end
    end

    return curFightEventIds
end

--获取当前章节当前关卡的Buff战斗事件Id（包括之前通关的关卡继承）(凹分关)
function XSucceedBossControl:GetCurrentBuffFightEventIdsOptional(selectBossIndex)
    local curFightEventIds = {}
    local stageInfos = self._Model:GetCurStageInfos()
    local stageProgressIndex = self._Model:GetStageProgressIndex()
    for i = 1, stageProgressIndex - 1 do
        if stageInfos[i] then
            local monsterId = stageInfos[i]:GetMonsterId()
            local monsterConfig = self:GetMonsterConfig(monsterId)
            if monsterConfig then
                local buffFightEventId = monsterConfig.BuffFightEventId
                if XTool.IsNumberValid(buffFightEventId) then
                    TableInsert(curFightEventIds, buffFightEventId)
                end
            end
        end
    end

    if XTool.IsNumberValid(selectBossIndex) then
        local curChapterId = self:GetCurrentChapterId()
        local monsterGroupIds = self:GetChapterConfig(curChapterId).MonsterGroupIds
        local monsterGroupId = monsterGroupIds[stageProgressIndex]
        local monsterGroupConfig = self:GetMonsterGroupConfig(monsterGroupId)
        local monsterId = monsterGroupConfig.MonsterIds[selectBossIndex]
        local monsterConfig = self:GetMonsterConfig(monsterId)
        if monsterConfig then
            local buffFightEventId = monsterConfig.BuffFightEventId
            if XTool.IsNumberValid(buffFightEventId) then
                TableInsert(curFightEventIds, buffFightEventId)
            end
        end
    end

    return curFightEventIds
end

function XSucceedBossControl:GetFightEventIcon(fightEventId)
    return self._Model:GetFightEventIcon(fightEventId)
end

-- 获取全部可选择弱点
function XSucceedBossControl:GetSucceedBossElements()
    return self._Model:GetSucceedBossElements()
end

-- 获取弱点Id
function XSucceedBossControl:GetElementId()
    return self._Model:GetElementId()
end

-- (当前章节下)普通关根据关卡进度获取MonsterConfig
function XSucceedBossControl:GetMonsterConfigByStageProcessIndex(stageIndex)
    local monsterGroupId = self:GetChapterConfig(self:GetCurrentChapterId()).MonsterGroupIds[stageIndex]
    local monsterId = self:GetMonsterGroupConfig(monsterGroupId).SelectMonster -- 当前关默认选中的MonsterId
    return self._Model:GetSucceedBossMonsterStageId(monsterId)
end

-- 获取当前战斗的编队数据
function XSucceedBossControl:GetTeam(chapterId)
    local team = self._Model:GetTeam(chapterId)
    if not team then
        return
    end
    XDataCenter.TeamManager.SetXTeam(team)
    return team
end

-- 根据角色Id获取角色的Icon,职业Icon,BuffFightEvent的详情 （可以传机器人Id）  GetNpcTypeTemplate
function XSucceedBossControl:GetSucceedBossCharacterBuffIconAndDesc(characterId)
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    if not characterAgency then
        return
    end

    local realCharacterId = characterId
    if characterAgency:CheckIsCharOrRobot(characterId) then
        realCharacterId = XRobotManager.GetCharacterId(characterId)
    end
    local characterBigIcon = characterAgency:GetCharBigHeadIcon(realCharacterId)

    local elementId = characterAgency:GetCharacterElement(characterId)
    local careerId = characterAgency:GetCharacterCareer(characterId)
    local careerIcon = characterAgency:GetNpcTypeTemplate(careerId).Icon

    if not XTool.IsNumberValid(elementId) or not XTool.IsNumberValid(careerId) then
        return
    end

    local fightEventId = self._Model:GetSucceedBossCharacterBuffFightEventId(elementId, careerId)
    local fightEventName = ""
    local desc = ""
    if XTool.IsNumberValid(fightEventId) then
        local fightEventCfg = self:GetFightEventShowConfig(fightEventId)
        fightEventName = fightEventCfg.Name
        desc = fightEventCfg.Desc
    end

    return characterBigIcon, careerIcon, desc, fightEventName
end

-- 获取当前驻守的角色Id列表(已经驻守不能更改的Id列表，不包括当前可更改的)
function XSucceedBossControl:GetUnalterableGarrisonIds()
    local garrisonIds = {}

    local stageInfos = self._Model:GetCurStageInfos()
    local curProgressIndex = self._Model:GetStageProgressIndex()
    for i = 1, curProgressIndex - 2 do
        local stageInfo = stageInfos[i]
        if stageInfo then
            local defendCharacterId = stageInfo:GetDefendCharacterId()
            local defendRobotId = stageInfo:GetDefendRobotId()
            if XTool.IsNumberValid(defendCharacterId) then
                TableInsert(garrisonIds, defendCharacterId)
            elseif XTool.IsNumberValid(defendRobotId) then
                TableInsert(garrisonIds, defendRobotId)
            end
        end
    end

    return garrisonIds
end

-- 获取当前进度下的驻守角色Id（即上一关的驻守ID）
function XSucceedBossControl:GetCurGarrisonId()
    local stageInfos = self._Model:GetCurStageInfos()
    local curProgressIndex = self._Model:GetStageProgressIndex()
    local stageInfo = stageInfos[curProgressIndex - 1]
    if stageInfo then
        local defendCharacterId = stageInfo:GetDefendCharacterId()
        local defendRobotId = stageInfo:GetDefendRobotId()
        if XTool.IsNumberValid(defendCharacterId) then
            return defendCharacterId
        elseif XTool.IsNumberValid(defendRobotId) then
            return defendRobotId
        end
    end
end

-- 获取章节的通关记录信息
function XSucceedBossControl:GetPassChapterInfo(chapterId)
    return self._Model:GetPassChapter(chapterId)
end

function XSucceedBossControl:GetGarrisonEntityIds()
    return self:GetAgency():GetGarrisonEntityIds()
end

-- 获取当前章节的驻守FightEventId列表并去重, 并额外获取对应的角色头像列表
function XSucceedBossControl:GetGarrisonFightEventIds()
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    if not characterAgency then
        return
    end

    local fightEventIdDic = {}
    local fightEventToCharacterIconsDic = {}
    local garrisonEntityIds = self:GetGarrisonEntityIds()
    for _, entityId in pairs(garrisonEntityIds) do
        local elementId = characterAgency:GetCharacterElement(entityId)
        local careerId = characterAgency:GetCharacterCareer(entityId)
        local fightEventId = self._Model:GetSucceedBossCharacterBuffFightEventId(elementId, careerId)
        if XTool.IsNumberValid(fightEventId) and not XTool.IsNumberValid(fightEventIdDic[fightEventId]) then
            fightEventIdDic[fightEventId] = fightEventId
        end

        local realCharacterId = entityId
        if characterAgency:CheckIsCharOrRobot(entityId) then
            realCharacterId = XRobotManager.GetCharacterId(entityId)
        end
        local characterBigIcon = characterAgency:GetCharBigHeadIcon(realCharacterId)
        if not fightEventToCharacterIconsDic[fightEventId] then
            fightEventToCharacterIconsDic[fightEventId] = {}
        end
        TableInsert(fightEventToCharacterIconsDic[fightEventId], characterBigIcon)
    end

    local fightEventIds = {}
    for _, fightEventId in pairs(fightEventIdDic) do
        TableInsert(fightEventIds, fightEventId)
    end

    return fightEventIds, fightEventToCharacterIconsDic
end

--region 判断方法
-- 判断章节是否上锁
function XSucceedBossControl:CheckChapterUnLock(chapterId)
    return self:GetAgency():CheckChapterUnLock(chapterId)
end

function XSucceedBossControl:CheckChapterInTime(chapterId)
    local chapterTimeId = self._Model:GetSucceedBossChapterTimeId(chapterId)
    if XTool.IsNumberValid(chapterTimeId) then
        return XFunctionManager.CheckInTimeByTimeId(chapterTimeId)
    else
        return true
    end
end

--判断是否有当前章节数据
function XSucceedBossControl:CheckHasCurChapterData()
    return XTool.IsNumberValid(self._Model:GetCurChapterId())
end

-- 判断章节是否通关
function XSucceedBossControl:CheckChapterPass(chapterId)
    return self:GetAgency():CheckChapterPass(chapterId)
end

---@return 是否能进章节, 是否有当前章节数据
-- 判断是否能进入章节
function XSucceedBossControl:CheckCanEnterChapter(chapterId)
    -- 判断章节是否上锁
    if not self:CheckChapterUnLock(chapterId) then
        return false, false, "SucceedBossChapterNotOpen"
    end

    -- 判断章节是否在章节活动时间内
    if not self:CheckChapterInTime(chapterId) then
        return false, false, "SucceedBossChapterTimeEnd"
    end

    -- 检查是否存在当前章节数据
    if not self:CheckHasCurChapterData() then
        return true, false
    end

    -- 判断是否是当前章节
    local curChapterId = self:GetCurrentChapterId()
    if curChapterId == chapterId then
        return true, true
    else
        -- 判断其他章节是否在战斗中
        local stageProgressIndex = self:GetStageProgressIndex() -- 当前章节进度
        if stageProgressIndex > 1 then
            return false, false, "SucceedBossOtherChapterInBattle"
        else
            return true, false
        end
    end
end

-- 根据章节序号获取驻守信息
function XSucceedBossControl:GetGarrisonInfoByIndex(index)
    local garrisonInfo = {
        IsLocked = true,
        DefendId = 0,
        IsRobot = false,
        IsCanChange = false,
    }
    local stageInfos = self._Model:GetCurStageInfos()
    local stageInfo = stageInfos[index]
    if not stageInfo then
        return garrisonInfo
    end

    local stageProcess = self:GetStageProgressIndex()
    if index >= stageProcess then
        -- 说明关卡未通关
        return garrisonInfo
    end

    garrisonInfo.IsLocked = false
    local defendCharacterId = stageInfo:GetDefendCharacterId()
    local defendRobotId = stageInfo:GetDefendRobotId()
    if not XTool.IsNumberValid(defendCharacterId) and not XTool.IsNumberValid(defendRobotId) then
        -- 都为空说明没驻守
        return garrisonInfo
    end

    if XTool.IsNumberValid(defendCharacterId) then
        garrisonInfo.DefendId = defendCharacterId
        garrisonInfo.IsRobot = false
    else
        garrisonInfo.DefendId = defendRobotId
        garrisonInfo.IsRobot = true
    end

    if index == stageProcess - 1 then
        garrisonInfo.IsCanChange = true
    end

    return garrisonInfo
end

-- 判断当前是否需要驻守队员
function XSucceedBossControl:CheckNeedGarrison()
    local curProcess = self._Model:GetStageProgressIndex()
    if curProcess == 1 then
        -- 第一关不需要驻守队员
        return false
    end

    local lastStageIndex = curProcess - 1
    local lastStageInfo = self._Model:GetStageInfo(lastStageIndex)
    if not lastStageInfo then
        return false
    end

    local defendCharacterId = lastStageInfo:GetDefendCharacterId()
    local defendRobotId = lastStageInfo:GetDefendRobotId()

    if XTool.IsNumberValid(defendCharacterId) or XTool.IsNumberValid(defendRobotId) then
        return false
    end

    return true
end

-- 检查当前是否需要选择弱点
function XSucceedBossControl:CheckNeedChooseWeakness()
    local elementId = self:GetElementId()
    if XTool.IsNumberValid(elementId) then
        return false
    end

    return true
end

-- 检查当前是否能修改弱点
function XSucceedBossControl:CheckCanChangeWeakness()
    local stageProcess = self._Model:GetStageProgressIndex()
    return stageProcess == 1 -- 只有在第一关才能打开队伍预设
end

-- 检查Boss关卡是否已经通关过
function XSucceedBossControl:CheckMonsterPass(monsterId)
    local passMonster = self._Model:GetPassMonster(monsterId)
    if passMonster then
        return true, passMonster:GetLevel()
    else
        return false, self._Model:GetSucceedBossMonsterDefaultUnlockLevel(monsterId)
    end
end

-- 检查当前章节是否打过某个怪
function XSucceedBossControl:CheckMonsterFought(monsterId)
    local stageInfos = self._Model:GetCurStageInfos()
    local curProgressIndex = self._Model:GetStageProgressIndex()
    for i = 1, curProgressIndex - 1 do
        local stageInfo = stageInfos[i]
        if stageInfo then
            if stageInfo:GetMonsterId() == monsterId then
                return true
            end
        end
    end

    return false
end

-- 检查某个怪物是否可以选择指定等级
function XSucceedBossControl:CheckCanSelectLevel(monsterId, level)
    if not XTool.IsNumberValid(level) then
        return false
    end

    if level < 1 then
        return false
    end

    local levelConfig = self:GetMonsterLevelConfig(monsterId, level)
    if not levelConfig then
        return false
    end

    --if level == 1 then
    --    return true
    --else
    local _, maxLevel = self:CheckMonsterPass(monsterId)

    if level <= maxLevel then
        return true
    end
    --end

    return false
end

-- 检查某个怪物在当前挑战章节中是否已被挑战过
function XSucceedBossControl:CheckMonsterPassedInCurChapter(monsterId)
    ---@type XSucceedBossBattleResultData[]
    local historyResults = self._Model:GetCurChapterHistoryResults()
    for _, historyResult in ipairs(historyResults) do
        if historyResult:GetMonsterId() == monsterId then
            return true
        end
    end
    
    return false
end

--endregion

--region 请求转发

function XSucceedBossControl:RequestSucceedBossSelectChapter(chapterId, cb)
    self:GetAgency():RequestSucceedBossSelectChapter(chapterId, cb)
end

function XSucceedBossControl:RequestSucceedBossSelectElement(fightEventId, cb)
    self:GetAgency():RequestSucceedBossSelectElement(fightEventId, cb)
end

function XSucceedBossControl:RequestSucceedBossResetChapter(cb)
    self:GetAgency():RequestSucceedBossResetChapter(cb)
end

function XSucceedBossControl:RequestSucceedBossSetDefendCharacter(entityId, cb)
    self:GetAgency():RequestSucceedBossSetDefendCharacter(entityId, cb)
end

function XSucceedBossControl:RequestSucceedBossSelectMonster(monsterId, monsterLevel, cb)
    self:GetAgency():RequestSucceedBossSelectMonster(monsterId, monsterLevel, cb)
end

--endregion

function XSucceedBossControl:_OnErrorCodeActivityNotInTime()
    self:HandleActivityEndTime()
end

function XSucceedBossControl:GetMaxLevel(monsterId)
    local list = self._Model:GetSucceedBossMonsterLevelConfigById(monsterId)
    return #list
end

-- 获取monster的所有levelConfigs
function XSucceedBossControl:GetMonsterLevelConfigs(monsterId)
    local list = self._Model:GetSucceedBossMonsterLevelConfigById(monsterId)
    return list
end

function XSucceedBossControl:_OnEnterFight()
    self._Model:SetIsJustEnterFight(true)
end

function XSucceedBossControl:GetIsJustEnterFight()
    return self._Model:GetIsJustEnterFight()
end

function XSucceedBossControl:SetNotIsJustEnterFight()
    self._Model:SetIsJustEnterFight(false)
end

function XSucceedBossControl:GetMonsterPassedLevel(monsterId)
    ---@type XSucceedBossMonsterData
    local monsterData = self._Model:GetPassMonster(monsterId)
    if monsterData then
        local level = monsterData:GetLevel()
        return level
    end
    return 0
end

function XSucceedBossControl:IsMonsterLevelUnlock(monsterId, level)
    local defaultUnlockLevel = self._Model:GetSucceedBossMonsterDefaultUnlockLevel(monsterId)
    if level <= defaultUnlockLevel then
        return true
    end
    
    local currentLevel = self:GetMonsterPassedLevel(monsterId)
    if level <= currentLevel then
        return true
    end
    return false
end

return XSucceedBossControl