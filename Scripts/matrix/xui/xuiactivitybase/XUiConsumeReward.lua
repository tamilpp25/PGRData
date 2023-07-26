local CSXTextManagerGetText = CS.XTextManager.GetText
local tableInsert = table.insert
local ForceRebuildLayoutImmediate = CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate

local XUiGridConsumeReward = require("XUi/XUiActivityBase/XUiGridConsumeReward")

local XPuzzleActivityManager
local XUiConsumeReward = XClass(nil, "XUiConsumeReward")

function XUiConsumeReward:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Init()
end

function XUiConsumeReward:Init()
    self.LayoutGroup = self.GridRewardPanel:GetComponent("HorizontalLayoutGroup")
    self.GridRewardPool = {}
    self.GridMiniRewardPool = {}
    self.LimitPosArr = {}
    self.BarWidth = self.ImgJd.transform.rect.width
end

function XUiConsumeReward:Refresh(activityCfg)
    local taskLimitId = activityCfg.Params[1]
    local taskLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(taskLimitId)
    self.TaskIdList = taskLimitCfg.TaskId
    local showBeginTime = activityCfg.ShowBeginTime
    local showEndTime = activityCfg.ShowEndTime
    self.TxtTime.text = CSXTextManagerGetText("ActivityConsumeRewardTime", showBeginTime, showEndTime)

    self.CurIndex, self.CurProgress, self.CurConsumeValue, self.CurTargetValue = self:GetTargetRewardIndexandProgress()
    -- XLog.Debug(self.CurIndex, self.CurProgress, self.CurConsumeValue, self.CurTargetValue)
    self.TxtTarget.text = "/"..self.CurTargetValue

    self:RefreshGridReward()
    self:RefreshProgressBar()
    self.TxtNumber.text = self.CurConsumeValue
    self:RefreshFinalReward(activityCfg)
end

function XUiConsumeReward:RefreshFinalReward(activityCfg)
    if activityCfg.Params[2] and activityCfg.Params[2] ~= 0 then
        local taskLimitId = activityCfg.Params[2]
        local taskLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(taskLimitId)
        local onCreate = function(item, data)
            item:Refresh(data)
        end
        XUiHelper.CreateTemplates(self.RootUi, self.GridMiniRewardPool, taskLimitCfg.TaskId, XUiGridConsumeReward.New, self.GridMiniReward.gameObject, self.GridMiniRewardPanel, onCreate)
    end
end

function XUiConsumeReward:RefreshGridReward()
    local halfGapWidth = (self.BarWidth / #self.TaskIdList - self.GridReward.transform.rect.width) / 2
    self.LayoutGroup.padding.left = math.ceil(-halfGapWidth)
    self.LayoutGroup.padding.right = math.ceil(-halfGapWidth)
    local onCreate = function(item, data)
        item:Refresh(data)
    end
    XUiHelper.CreateTemplates(self.RootUi, self.GridRewardPool, self.TaskIdList, XUiGridConsumeReward.New, self.GridReward.gameObject, self.GridRewardPanel, onCreate)
    ForceRebuildLayoutImmediate(self.GridRewardPanel) -- 强制刷新布局
end

function XUiConsumeReward:RefreshProgressBar()
    local halfBarWidth = math.ceil(self.BarWidth/2)
    self.LimitPosArr = {}
    for i = 0, self.GridRewardPanel.childCount - 1 do
        local limitPos = halfBarWidth + math.floor(self.GridRewardPanel:GetChild(i).transform.localPosition.x)
        tableInsert(self.LimitPosArr, limitPos)
    end

    if self.CurIndex == 1 then
        self.ImgJd.fillAmount = self.LimitPosArr[1] * self.CurProgress / self.BarWidth
    elseif self.CurIndex == #self.LimitPosArr and self.CurConsumeValue >= self.CurTargetValue then
        self.ImgJd.fillAmount = 1
        self.CurConsumeValue = self.CurTargetValue
    else
        local curBarPix = (self.LimitPosArr[self.CurIndex] - self.LimitPosArr[self.CurIndex-1]) * self.CurProgress
        self.ImgJd.fillAmount = (curBarPix + self.LimitPosArr[self.CurIndex-1]) / self.BarWidth
    end
end

function XUiConsumeReward:GetTargetRewardIndexandProgress() -- 返回值：当前的目标序号，从上一目标到当前目标的进度，当前的总消费值，当前目标的消费值
    if not self.TaskIdList then
        return 1, 0
    end

    local curConsumeValue = XDataCenter.TaskManager.GetTaskDataById(self.TaskIdList[#self.TaskIdList]).Schedule[1].Value -- 取最后一个任务进度作为当前任务总进度
    local targetRewardIndex = 1
    local progress = 0
    local lastTargetConsumeValue = 0
    for _, taskId in ipairs(self.TaskIdList) do
        local taskCfg = XTaskConfig.GetTaskCfgById(taskId)
        if curConsumeValue >= taskCfg.Result then
            targetRewardIndex = targetRewardIndex + 1
            lastTargetConsumeValue = taskCfg.Result
        else
            local remainConsume = curConsumeValue - lastTargetConsumeValue
            progress = remainConsume / (taskCfg.Result - lastTargetConsumeValue)

            break
        end
    end

    if targetRewardIndex > #self.TaskIdList then
        targetRewardIndex = #self.TaskIdList
        progress = 1
    end

    return targetRewardIndex, progress, curConsumeValue, XTaskConfig.GetTaskCfgById(self.TaskIdList[targetRewardIndex]).Result
end

return XUiConsumeReward