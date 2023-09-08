---@class XTwoSideTowerControl : XControl
---@field private _Model XTwoSideTowerModel
local XTwoSideTowerControl = XClass(XControl, "XTwoSideTowerControl")

local RequestProto = {
    TwoSideTowerResetChapterRequest = "TwoSideTowerResetChapterRequest",                           -- 重置章节请求
    TwoSideTowerResetPointRequest = "TwoSideTowerResetPointRequest",                               -- 重置节点请求
    TwoSideTowerSweepPositiveStageRequest = "TwoSideTowerSweepPositiveStageRequest",               -- 扫荡普通节点关卡请求
    TwoSideTowerShieldOrUnShieldFeatureIdRequest = "TwoSideTowerShieldOrUnShieldFeatureIdRequest", -- 屏蔽解除特性请求
}

function XTwoSideTowerControl:OnInit()
    --初始化内部变量
end

function XTwoSideTowerControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XTwoSideTowerControl:RemoveAgencyEvent()

end

function XTwoSideTowerControl:OnRelease()
    -- 这里执行Control的释放
end

function XTwoSideTowerControl:GetHelpKey()
    return self:GetClientConfig("HelpDataKey")
end

function XTwoSideTowerControl:GetClientConfig(key, index)
    if not index then
        index = 1
    end
    return self._Model:GetClientConfig(key, index)
end

--region 活动相关

function XTwoSideTowerControl:GetOutSideTimeId()
    local config = self._Model:GetActivityConfig()
    return config and config.OutSideTimeId or 0
end

function XTwoSideTowerControl:GetOutSideBannerBg()
    local config = self._Model:GetActivityConfig()
    return config and config.OutSideBannerBg or ""
end

function XTwoSideTowerControl:GetInsideTimeId()
    local config = self._Model:GetActivityConfig()
    return config and config.InsideTimeId or 0
end

function XTwoSideTowerControl:GetInsideBannerBg()
    local config = self._Model:GetActivityConfig()
    return config and config.InsideBannerBg or ""
end

function XTwoSideTowerControl:GetOutSideLimitTaskId()
    local config = self._Model:GetActivityConfig()
    return config and config.LimitTaskId or 0
end

function XTwoSideTowerControl:GetInsideLimitTaskId()
    local config = self._Model:GetActivityConfig()
    return config and config.InsideLimitTaskId or 0
end

function XTwoSideTowerControl:GetOutSideChapterIds()
    local config = self._Model:GetActivityConfig()
    return config and config.ChapterIds or {}
end

function XTwoSideTowerControl:GetInsideChapterIds()
    local config = self._Model:GetActivityConfig()
    return config and config.InsideChapterIds or {}
end

function XTwoSideTowerControl:GetRobotIds()
    local config = self._Model:GetActivityConfig()
    return config and config.RobotIds or {}
end

-- 获取活动结束时间
function XTwoSideTowerControl:GetActivityEndTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

-- 活动结束
function XTwoSideTowerControl:HandleActivityEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipText("ActivityAlreadyOver")
end

-- 获取解锁状态和未解锁的描述
function XTwoSideTowerControl:GetActivitySideOpenByTimeId(timeId)
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local nowTime = XTime.GetServerNowTimestamp()
    if startTime > 0 and nowTime < startTime then
        local lockDesc = self:GetClientConfig("ActivityLockDesc", 1)
        local time = startTime - nowTime
        if time <= 0 then
            time = 0
        end
        local timeDesc = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
        return false, XUiHelper.FormatText(lockDesc, timeDesc)
    end
    if endTime > 0 and nowTime >= endTime then
        return false, self:GetClientConfig("ActivityLockDesc", 2)
    end
    return true, ""
end

-- 返回主界面显示的任务Id和是否领取完奖励
function XTwoSideTowerControl:GetShowTaskId(taskGroupIds)
    local taskList = {}
    for _, groupId in pairs(taskGroupIds) do
        local tasks = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, false)
        taskList = XTool.MergeArray(taskList, tasks)
    end
    if XTool.IsTableEmpty(taskList) then
        return nil, false
    end
    -- 排序
    XDataCenter.TaskManager.SortTaskList(taskList)
    local isAllFinish = self:CheckAllTaskFinished(taskList)
    if isAllFinish then
        return taskList[#taskList].Id, true
    end
    return taskList[1].Id, false
end

-- 检查所有的任务是否都已完成
function XTwoSideTowerControl:CheckAllTaskFinished(taskList)
    for _, task in pairs(taskList) do
        if not XDataCenter.TaskManager.CheckTaskFinished(task.Id) then
            return false
        end
    end
    return true
end

--endregion

--region 章节相关

function XTwoSideTowerControl:GetChapterTimeId(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.TimeId or 0
end

function XTwoSideTowerControl:GetChapterName(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.Name or ""
end

function XTwoSideTowerControl:GetChapterFubenPrefab(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.FubenPrefab or ""
end

function XTwoSideTowerControl:GetChapterIcon(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.Icon or ""
end

function XTwoSideTowerControl:GetChapterMonsterBg(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.MonsterBg or ""
end

function XTwoSideTowerControl:GetUnlockChapterIds(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.UnlockChapterIds or {}
end

function XTwoSideTowerControl:GetChapterPointIds(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.PointIds or {}
end

function XTwoSideTowerControl:GetChapterEndPointId(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.EndPointId or 0
end

function XTwoSideTowerControl:GetChapterScoreLevel(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.ScoreLevel or {}
end

function XTwoSideTowerControl:GetChapterOverviewIcon(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.OverviewIcon or ""
end

function XTwoSideTowerControl:GetChapterOverviewDesc(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.OverviewDesc or ""
end

-- 检查章节是否通关
function XTwoSideTowerControl:CheckChapterCleared(chapterId)
    return self._Model:CheckChapterCleared(chapterId)
end

-- 获取最高分数对应的分数等级
function XTwoSideTowerControl:GetMaxChapterScoreLevel(chapterId)
    local maxScore = self._Model:GetMaxChapterScore(chapterId)
    local scoreLevels = self:GetChapterScoreLevel(chapterId)
    local scoreLv = 1
    for i, score in pairs(scoreLevels) do
        if maxScore >= score then
            scoreLv = i
        end
    end
    return scoreLv
end

-- 获取最高分数对应图
function XTwoSideTowerControl:GetMaxChapterScoreIcon(chapterId)
    local scoreLv = self:GetMaxChapterScoreLevel(chapterId)
    return self:GetClientConfig("ScoreLevelIcons", scoreLv)
end

-- 获取章节当前分数对应的分数等级
function XTwoSideTowerControl:GetCurChapterScoreLevel(chapterId)
    local curScore = self._Model:GetLastChapterScore(chapterId)
    local scoreLevels = self:GetChapterScoreLevel(chapterId)
    local scoreLv = 1
    for i, score in pairs(scoreLevels) do
        if curScore >= score then
            scoreLv = i
        end
    end
    return scoreLv
end

-- 获取当前章节分数对应图
function XTwoSideTowerControl:GetCurChapterScoreIcon(chapterId)
    local scoreLv = self:GetCurChapterScoreLevel(chapterId)
    return self:GetClientConfig("ScoreLevelIcons", scoreLv)
end

function XTwoSideTowerControl:GetChapterTypeByChapterId(chapterId)
    local outSideChapterIds = self:GetOutSideChapterIds()
    if table.contains(outSideChapterIds, chapterId) then
        return XEnumConst.TwoSideTower.ChapterType.OutSide
    end
    local inSideChapterIds = self:GetInsideChapterIds()
    if table.contains(inSideChapterIds, chapterId) then
        return XEnumConst.TwoSideTower.ChapterType.Inside
    end
    return 1
end

-- 检查章节是否解锁
function XTwoSideTowerControl:CheckChapterIsUnlock(chapterId)
    local timeId = self:GetChapterTimeId(chapterId)
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local now = XTime.GetServerNowTimestamp()
    if startTime > 0 and now < startTime then
        local timeStr = XUiHelper.GetTime(startTime - now, XUiHelper.TimeFormatType.ACTIVITY)
        return false, XUiHelper.FormatText(self:GetClientConfig("ChapterLockDesc", 1), timeStr)
    end
    if endTime > 0 and now >= endTime then
         return false, self:GetClientConfig("ChapterLockDesc", 3)
    end
    local unlockChapterIds = self:GetUnlockChapterIds(chapterId)
    for _, id in pairs(unlockChapterIds) do
        if not self:CheckChapterCleared(id) then
            return false, XUiHelper.FormatText(self:GetClientConfig("ChapterLockDesc", 2), self:GetChapterName(id))
        end
    end
    return true, ""
end

-- 首次通关章节时弹框
function XTwoSideTowerControl:CheckOpenUiChapterSettle(chapterId)
    if self._Model.FirstCleared then
        XLuaUiManager.Open("UiTwoSideTowerSettle", chapterId)
    end
    self._Model.FirstCleared = false
end

-- 检测打开章节特性总览界面
function XTwoSideTowerControl:CheckOpenUiChapterOverview(chapterId)
    local key = self._Model:GetChapterOverviewSaveKey(chapterId)
    if XSaveTool.GetData(key) then
        return
    end
    XLuaUiManager.Open("UiTwoSideTowerOverview", chapterId)
    XSaveTool.SaveData(key, true)
end

--endregion

--region 节点相关

function XTwoSideTowerControl:GetPointInitScore(pointId)
    local config = self._Model:GetPointConfig(pointId)
    return config and config.InitScore or 0
end

function XTwoSideTowerControl:GetPointReduceScoreParam(pointId)
    local config = self._Model:GetPointConfig(pointId)
    return config and config.ReduceScoreParam or 0
end

function XTwoSideTowerControl:GetPointStageIds(pointId)
    local config = self._Model:GetPointConfig(pointId)
    return config and config.StageIds or {}
end

function XTwoSideTowerControl:GetPointName(pointId)
    local config = self._Model:GetPointConfig(pointId)
    return config and config.Name or ""
end

function XTwoSideTowerControl:GetPointNumberName(pointId)
    local config = self._Model:GetPointConfig(pointId)
    return config and config.NumberName or ""
end

function XTwoSideTowerControl:GetPointIsEndPoint(pointId)
    local config = self._Model:GetPointConfig(pointId)
    return config and config.IsEndPoint or 0
end

-- 获取节点已通关关卡Id
function XTwoSideTowerControl:GetPointPassStageId(chapterId, pointId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:GetPointPassStageId(chapterId, pointId)
    end
    return 0
end

-- 获取已通关关卡的特性Id
function XTwoSideTowerControl:GetPassStageFeatureIdByPointId(chapterId, pointId)
    local stageId = self:GetPointPassStageId(chapterId, pointId)
    if not XTool.IsNumberValid(stageId) then
        return 0
    end
    return self:GetStageFeatureId(stageId)
end

-- 检查节点是否通关
function XTwoSideTowerControl:CheckPointIsPass(chapterId, pointId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckPointIsPass(chapterId, pointId)
    end
    return false
end

-- 检查所有普通节点是否都通关
function XTwoSideTowerControl:CheckNormalPointIsPass(chapterId)
    local pointIds = self:GetChapterPointIds(chapterId)
    for _, pointId in pairs(pointIds) do
        if not self:CheckPointIsPass(chapterId, pointId) then
            return false
        end
    end
    return true
end

--endregion

--region 关卡相关

function XTwoSideTowerControl:GetStageFeatureId(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.FeatureId or 0
end

function XTwoSideTowerControl:GetStageExtraFeatureId(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.ExtraFeatureId or 0
end

function XTwoSideTowerControl:GetStageWeakIcon(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.WeakIcon or ""
end

function XTwoSideTowerControl:GetStageSmallMonsterIcon(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.SmallMonsterIcon or ""
end

function XTwoSideTowerControl:GetStageBigMonsterIcon(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.BigMonsterIcon or ""
end

function XTwoSideTowerControl:GetStageTypeName(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.StageTypeName or ""
end

function XTwoSideTowerControl:GetStageNumberName(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.StageNumberName or ""
end

-- 检查是否是可扫荡关卡
function XTwoSideTowerControl:CheckIsCanSweepStageId(chapterId, stageId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckIsCanSweepStageId(chapterId, stageId)
    end
    return false
end

--endregion

--region 特性相关

function XTwoSideTowerControl:GetFeatureType(featureId)
    local config = self._Model:GetFeatureConfig(featureId)
    return config and config.Type or 0
end

function XTwoSideTowerControl:GetFeatureName(featureId)
    local config = self._Model:GetFeatureConfig(featureId)
    return config and config.Name or ""
end

function XTwoSideTowerControl:GetFeatureIcon(featureId)
    local config = self._Model:GetFeatureConfig(featureId)
    return config and config.Icon or ""
end

function XTwoSideTowerControl:GetFeatureDesc(featureId)
    local config = self._Model:GetFeatureConfig(featureId)
    return config and config.Desc or ""
end

function XTwoSideTowerControl:GetFeatureImage(featureId)
    local config = self._Model:GetFeatureConfig(featureId)
    return config and config.Image or ""
end

function XTwoSideTowerControl:GetFeatureDescZonglan(featureId)
    local config = self._Model:GetFeatureConfig(featureId)
    return config and config.DescZonglan or ""
end

-- 检查当前特性是否已屏蔽
function XTwoSideTowerControl:CheckChapterIsShieldFeature(chapterId, featureId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckChapterIsShieldFeature(chapterId, featureId)
    end
    return false
end

-- 检查上一次特性是否已屏蔽
function XTwoSideTowerControl:CheckChapterIsLastShieldFeature(chapterId, featureId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckChapterIsLastShieldFeature(chapterId, featureId)
    end
    return false
end

-- 检查屏蔽特性是否大于等于2次
function XTwoSideTowerControl:CheckChapterShieldFeaturesCount(chapterId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckChapterShieldFeaturesCount(chapterId)
    end
    return false
end

--endregion

--region 编队信息

function XTwoSideTowerControl:GetTeam()
    local team = self._Model:GetTeam()
    local lookupTable = {}
    local robotIdList = self:GetRobotIds()
    for _, id in pairs(robotIdList) do
        lookupTable[id] = id
    end
    for index, entityId in pairs(team:GetEntityIds()) do
        if XRobotManager.CheckIsRobotId(entityId) then
            if not XTool.IsNumberValid(lookupTable[entityId]) then
                team:UpdateEntityTeamPos(entityId, index, false)
            end
        else
            ---@type XCharacterAgency
            local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
            if not characterAgency:IsOwnCharacter(entityId) then
                team:UpdateEntityTeamPos(entityId, index, false)
            end
        end
    end
    return team
end

--endregion

--region 网络请求相关

-- 重置章节请求
function XTwoSideTowerControl:TwoSideTowerResetChapterRequest(chapterId, cb)
    local request = { ChapterId = chapterId }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.TwoSideTowerResetChapterRequest, request, function(res)
        -- 章节数据
        self._Model:NotifyTwoSideTowerChapterData(res.ChapterData)
        if cb then
            cb()
        end
    end)
end

-- 重置节点请求
function XTwoSideTowerControl:TwoSideTowerResetPointRequest(chapterId, pointId, cb)
    local request = { ChapterId = chapterId, PointId = pointId }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.TwoSideTowerResetPointRequest, request, function(res)
        -- 章节数据
        self._Model:NotifyTwoSideTowerChapterData(res.ChapterData)
        XEventManager.DispatchEvent(XEventId.EVENT_TWO_SIDE_TOWER_POINT_STATUS_CHANGE)
        if cb then
            cb()
        end
    end)
end

-- 扫荡普通节点关卡请求
function XTwoSideTowerControl:TwoSideTowerSweepPositiveStageRequest(stageId, cb)
    local request = { StageId = stageId }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.TwoSideTowerSweepPositiveStageRequest, request, function(res)
        -- 章节数据
        self._Model:NotifyTwoSideTowerChapterData(res.ChapterData)
        XEventManager.DispatchEvent(XEventId.EVENT_TWO_SIDE_TOWER_POINT_STATUS_CHANGE)
        if cb then
            cb()
        end
    end)
end

-- 屏蔽解除特性请求
function XTwoSideTowerControl:TwoSideTowerShieldOrUnShieldFeatureIdRequest(stageId, featureId, isShield, cb)
    local request = { StageId = stageId, FeatureId = featureId, IsShield = isShield }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.TwoSideTowerShieldOrUnShieldFeatureIdRequest, request, function(res)
        -- 章节数据
        self._Model:NotifyTwoSideTowerChapterData(res.ChapterData)
        XEventManager.DispatchEvent(XEventId.EVENT_TWO_SIDE_TOWER_FEATURE_STATUS_CHANGE)
        if cb then
            cb()
        end
    end)
end

--endregion

--region 红点相关

-- 检查是否有可领取的任务红点
function XTwoSideTowerControl:CheckTaskAchievedRedPoint(taskGroupIds)
    return self._Model:CheckTaskAchievedRedPoint(taskGroupIds)
end

-- 检查是否有新章节开启红点
function XTwoSideTowerControl:CheckNewChapterOpenRedPoint(chapterIds)
    return self._Model:CheckNewChapterOpenRedPoint(chapterIds)
end

--endregion

--region 本地数据相关

-- 保存章节是否点击
function XTwoSideTowerControl:SaveChapterIsClick(chapterId)
    local key = self._Model:GetChapterIsClickKey(chapterId)
    local data = XSaveTool.GetData(key) or false
    if data then
        return
    end
    XSaveTool.SaveData(key, true)
end

function XTwoSideTowerControl:GetBattleDialogHintCookie()
    local key = self._Model:GetBattleDialogHintCookieKey()
    return XSaveTool.GetData(key) or false
end

function XTwoSideTowerControl:SaveBattleDialogHintCookie(value)
    local key = self._Model:GetBattleDialogHintCookieKey()
    XSaveTool.SaveData(key, value)
end
    
--endregion

--带今日内不再提示选项的提示框
function XTwoSideTowerControl:DialogHintTip(title, content, content2, closeCallback, sureCallback, hintInfo)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Tip_Big)
    XLuaUiManager.Open("UiTwoSideTowerCueMark", title, content, content2, closeCallback, sureCallback, hintInfo)
end

return XTwoSideTowerControl
