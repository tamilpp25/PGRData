local XMonsterTeam = require("XEntity/XMonsterCombat/XMonsterTeam")
-- 章节配置类
---@class XMonsterCombatChapterEntity
---@field MonsterTeam XMonsterTeam
local XMonsterCombatChapterEntity = XClass(nil, "XMonsterCombatChapterEntity")

function XMonsterCombatChapterEntity:Ctor(chapterId)
    self:UpdateChapterId(chapterId)
    self.MonsterTeam = nil
end

function XMonsterCombatChapterEntity:UpdateChapterId(chapterId)
    self.ChapterId = chapterId
    self.Config = XMonsterCombatConfigs.GetCfgByIdKey(XMonsterCombatConfigs.TableKey.MonsterCombatChapter, chapterId)
    self.ConfigDetail = XMonsterCombatConfigs.GetCfgByIdKey(XMonsterCombatConfigs.TableKey.MonsterCombatChapterDetail, chapterId)
end

function XMonsterCombatChapterEntity:GetTimeId()
    return self.Config.TimeId or 0
end
-- 章节名称
function XMonsterCombatChapterEntity:GetName()
    return self.Config.Name or ""
end
-- 章节类型（1-普通章节，2-核心章节）
function XMonsterCombatChapterEntity:GetType()
    return self.Config.Type or 1
end
-- 前置章节Id
function XMonsterCombatChapterEntity:GetPreChapterId()
    return self.Config.PreChapterId or 0
end
-- 解锁怪物id列表
function XMonsterCombatChapterEntity:GetUnlockMonsterIds()
    return self.Config.UnlockMonsterIds or {}
end
-- 章节关卡列表
function XMonsterCombatChapterEntity:GetStageIds()
    return self.Config.StageIds or {}
end
-- 章节限制怪物
function XMonsterCombatChapterEntity:GetLimitMonsters()
    return self.Config.LimitMonsters or {}
end
-- 章节限制机器人
function XMonsterCombatChapterEntity:GetLimitRobotIds()
    return self.Config.LimitRobotIds or {}
end

--region 详情信息

function XMonsterCombatChapterEntity:GetDescription()
    local desc = self.ConfigDetail.Description or ""
    return XUiHelper.ConvertLineBreakSymbol(desc)
end

function XMonsterCombatChapterEntity:GetPrefabName()
    return self.ConfigDetail.PrefabName or ""
end

function XMonsterCombatChapterEntity:GetBgIcon()
    return self.ConfigDetail.BgIcon or ""
end

--endregion

-- 章节评分
function XMonsterCombatChapterEntity:GetChapterScore()
    local maxScore = -1
    for _, stageId in pairs(self:GetStageIds()) do
        local stageEntity = XDataCenter.MonsterCombatManager.GetStageEntity(stageId)
        if stageEntity:CheckIsScoreModel() and stageEntity:CheckIsPass() then
            local score = stageEntity:GetStageMaxScore()
            if score > maxScore then
                maxScore = score
            end
        end
    end
    if maxScore > 0 then
        return maxScore
    end
    return XUiHelper.GetText("UiMonsterCombatStageNotClear")
end

-- 检查是否是核心章节
function XMonsterCombatChapterEntity:CheckIsCoreChapter()
    return self:GetType() == XMonsterCombatConfigs.ChapterType.Core
end

-- 检查是否在开启时间内
function XMonsterCombatChapterEntity:CheckInTime()
    return XFunctionManager.CheckInTimeByTimeId(self:GetTimeId())
end

-- 检查章节是否解锁
-- 参数1 是否解锁 true为解锁 参数2 未解锁提示信息
function XMonsterCombatChapterEntity:CheckIsUnlock()
    -- 是否在开启时间内
    if not self:CheckInTime() then
        return false, XUiHelper.GetText("UiMonsterCombatChapterNotOpen")
    end
    -- 前置章节是否通关
    local preChapterId = self:GetPreChapterId()
    local viewModel = XDataCenter.MonsterCombatManager.GetViewModel()
    if not viewModel then
        return false, ""
    end
    if XTool.IsNumberValid(preChapterId) and not viewModel:CheckChapterPass(preChapterId) then
        local preChapterEntity = XDataCenter.MonsterCombatManager.GetChapterEntity(preChapterId)
        return false, XUiHelper.GetText("UiMonsterCombatChapterNotClear", preChapterEntity:GetName())
    end
    return true, ""
end

-- 获取未解锁显示信息 默认显示空
function XMonsterCombatChapterEntity:GetLockShowDesc()
    if not self:CheckInTime() then
        local startTime = XFunctionManager.GetStartTimeByTimeId(self:GetTimeId())
        return XUiHelper.GetText("UiMonsterCombatChapterOpenTime", XTime.TimestampToGameDateTimeString(startTime, "MM-dd"))
    end
    -- 前置章节是否通关
    local preChapterId = self:GetPreChapterId()
    local viewModel = XDataCenter.MonsterCombatManager.GetViewModel()
    if not viewModel then
        return ""
    end
    if XTool.IsNumberValid(preChapterId) and not viewModel:CheckChapterPass(preChapterId) then
        local preChapterEntity = XDataCenter.MonsterCombatManager.GetChapterEntity(preChapterId)
        return XUiHelper.GetText("UiMonsterCombatChapterClearUnlock", preChapterEntity:GetName())
    end
    return ""
end

-- 获取未解锁关卡的最小下标
function XMonsterCombatChapterEntity:GetUnPassedStageIndex()
    local stageIds = self:GetStageIds()
    local minIndex = table.nums(stageIds)
    for i, stageId in pairs(stageIds) do
        local stageEntity = XDataCenter.MonsterCombatManager.GetStageEntity(stageId)
        if not stageEntity:CheckIsPass() then
            if i < minIndex then
                minIndex = i
            end
        end
    end
    return minIndex
end

-- 检查是否有新章节解锁
-- 规则为：解锁且未点击
function XMonsterCombatChapterEntity:CheckNewUnlockChapter()
    local isUnlock = self:CheckIsUnlock()
    local isClick = XDataCenter.MonsterCombatManager.CheckChapterClick(self.ChapterId)
    return isUnlock and not isClick
end

-- 队伍信息
-- 编队保存规则：编队数据仅会在章节内进行保存，不继承到下一个章节中。
-- 优先使用本地数据 如果没有本地数据使用服务端数据
-- 本地数据必须同时存在角色和怪物，否则使用服务端数据
function XMonsterCombatChapterEntity:GetMonsterTeam()
    if not self.MonsterTeam then
        self.MonsterTeam = XMonsterTeam.New(self.ChapterId)
    end
    local isEmpty = self.MonsterTeam:GetIsEmpty()
    local isMonsterEmpty = self.MonsterTeam:GetMonsterIsEmpty()
    if not isEmpty and not isMonsterEmpty then
        return self.MonsterTeam
    end
    -- 同步服务端数据
    self.MonsterTeam:Clear()
    local viewModel = XDataCenter.MonsterCombatManager.GetViewModel()
    if viewModel then
        -- 角色Id
        local entityId = viewModel:GetFormationEntityId(self.ChapterId)
        if XTool.IsNumberValid(entityId) then
            self.MonsterTeam:UpdateEntityTeamPos(entityId, self.MonsterTeam:GetCaptainPos(), true)
        end
        -- 怪物列表
        local monsterIds = viewModel:GetFormationMonsters(self.ChapterId)
        if not XTool.IsTableEmpty(monsterIds) then
            self.MonsterTeam:UpdateMonsterIds(monsterIds)
        end
    end
    return self.MonsterTeam
end

return XMonsterCombatChapterEntity