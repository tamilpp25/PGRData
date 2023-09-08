local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XTwoSideTowerAgency : XFubenActivityAgency
---@field private _Model XTwoSideTowerModel
local XTwoSideTowerAgency = XClass(XFubenActivityAgency, "XTwoSideTowerAgency")
function XTwoSideTowerAgency:OnInit()
    --初始化一些变量
    ---@type XFubenExAgency
    local fubenExAgency = XMVCA:GetAgency(ModuleId.XFubenEx)
    fubenExAgency:RegisterActivityAgency(self)

    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    fubenAgency:RegisterFuben(XEnumConst.FuBen.StageType.TwoSideTower, ModuleId.XTwoSideTower)
end

function XTwoSideTowerAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyTwoSideTowerActivityData = handler(self, self.NotifyTwoSideTowerActivityData)
    XRpc.NotifyTwoSideTowerChapterData = handler(self, self.NotifyTwoSideTowerChapterData)
end

function XTwoSideTowerAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region Rpc

-- 推送正逆塔活动数据
function XTwoSideTowerAgency:NotifyTwoSideTowerActivityData(data)
    self._Model:NotifyTwoSideTowerActivityData(data)
end

-- 推送正逆塔单个章节数据
function XTwoSideTowerAgency:NotifyTwoSideTowerChapterData(data)
    if not data then
        return
    end
    self._Model:NotifyTwoSideTowerChapterData(data.ChapterData)
end

--endregion

--region 活动表信息

-- 获取机器人Id
function XTwoSideTowerAgency:GetRobotIds()
    local config = self._Model:GetActivityConfig()
    return config and config.RobotIds or {}
end

-- 获取活动结束时间
function XTwoSideTowerAgency:GetActivityEndTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XTwoSideTowerAgency:GetOutSideLimitTaskId()
    local config = self._Model:GetActivityConfig()
    return config and config.LimitTaskId or 0
end

function XTwoSideTowerAgency:GetInsideLimitTaskId()
    local config = self._Model:GetActivityConfig()
    return config and config.InsideLimitTaskId or 0
end

function XTwoSideTowerAgency:GetStartTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetStartTimeByTimeId(timeId)
end

function XTwoSideTowerAgency:GetEndTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XTwoSideTowerAgency:GetOutSideChapterIds()
    local config = self._Model:GetActivityConfig()
    return config and config.ChapterIds or {}
end

function XTwoSideTowerAgency:GetInsideChapterIds()
    local config = self._Model:GetActivityConfig()
    return config and config.InsideChapterIds or {}
end

--endregion

function XTwoSideTowerAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.TwoSideTower, false, noTips) then
        return false
    end
    if not self._Model.ActivityData or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipText("CommonActivityNotStart")
        end
        return false
    end
    return true
end

-- 获取章节最大分数
function XTwoSideTowerAgency:GetMaxChapterScore(chapterId)
    return self._Model:GetMaxChapterScore(chapterId)
end

--region 红点相关

-- 检查是否有新章节开启
function XTwoSideTowerAgency:CheckChapterOpenRed()
    if not self._Model.ActivityData then
        return false
    end
    local outSideChapterIds = self:GetOutSideChapterIds()
    if self._Model:CheckNewChapterOpenRedPoint(outSideChapterIds) then
        return true
    end
    local inSideChapterIds = self:GetInsideChapterIds()
    if self._Model:CheckNewChapterOpenRedPoint(inSideChapterIds) then
        return true
    end
    return false
end

-- 检查是否有可领取的任务
function XTwoSideTowerAgency:CheckTaskFinish()
    if not self._Model.ActivityData then
        return false
    end
    local groupIds = {
        self:GetOutSideLimitTaskId(),
        self:GetInsideLimitTaskId()
    }
    return self._Model:CheckTaskAchievedRedPoint(groupIds)
end

--endregion

--region 副本相关

function XTwoSideTowerAgency:InitStageInfo()
    -- 设置StageInfo的Type操作移到Stage配置表里
end

function XTwoSideTowerAgency:PreFight(stage, teamId, isAssist, challengeCount)
    local team = self._Model:GetTeam()
    local preFight = {}
    preFight.RobotIds = team:GetRobotIdsOrder()
    preFight.CardIds = team:GetCharacterIdsOrder()
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1
    preFight.CaptainPos = team:GetCaptainPos()
    preFight.FirstFightPos = team:GetFirstFightPos()
    return preFight
end

function XTwoSideTowerAgency:FinishFight(settle)
    local result = settle.TwoSideTowerSettleResult or {}
    self._Model.FirstCleared = result.FirstCleared
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    if settle.IsWin then
        fubenAgency:ChallengeWin(settle)
    else
        fubenAgency:ChallengeLose(settle)
    end
end

-- 检查关卡是否通关
function XTwoSideTowerAgency:CheckPassedByStageId(stageId)
    local isPass = self._Model:CheckPassedByStageId(stageId)
    return isPass 
end

--endregion

--region 副本入口扩展

function XTwoSideTowerAgency:ExOpenMainUi()
    if not self:GetIsOpen() then
        return
    end

    --打开主界面
    XLuaUiManager.Open("UiTwoSideTowerMainZhu")
end

function XTwoSideTowerAgency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenActivity
        self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    end
    return self.ExConfig
end

function XTwoSideTowerAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.TwoSideTower
end

function XTwoSideTowerAgency:ExCheckInTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XTwoSideTowerAgency:ExGetProgressTip()
    local taskList = {}
    local outSideLimitTaskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self:GetOutSideLimitTaskId(), false)
    local insideLimitTaskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self:GetInsideLimitTaskId(), false)
    taskList = XTool.MergeArray(outSideLimitTaskList, insideLimitTaskList)
    local passCount, allCount = XDataCenter.TaskManager.GetTaskProgressByTaskList(taskList)
    local desc = self._Model:GetClientConfig("ActivityBannerProcess", 1)
    return XUiHelper.FormatText(desc, passCount, allCount)
end

--endregion

return XTwoSideTowerAgency
