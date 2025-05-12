local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local stringGsub = string.gsub
local tableInsert = table.insert
local CSGameEventManager = CS.XGameEventManager.Instance
local XUiPanelLink = XClass(nil, "XUiPanelLink")

function XUiPanelLink:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.RewardList = {}
    self:AutoAddListener()
end

function XUiPanelLink:AutoAddListener()
    self.BtnGo.CallBack = function()
        self:OnBtnGoClick()
    end
    self.BtnFinish.CallBack = function()
        self:OnBtnFinishClick()
    end
end

function XUiPanelLink:Refresh(activityCfg)
    self.ActivityCfg = activityCfg or self.ActivityCfg
    self.ActivityType = self.ActivityCfg.ActivityType

    self.UrlId = self.ActivityCfg.Params[1]
    self.TxtTitle.text = stringGsub(self.ActivityCfg.ActivityTitle, "\\n", "\n")

    if self.ActivityType == XActivityConfigs.ActivityType.BackFlowLink then
        self:RefreshBackFlowTxtTime()
    else
        self:RefreshTxtTime()
    end
    
    self.TxtContent.text = stringGsub(self.ActivityCfg.ActivityDes, "\\n", "\n")

    self:GetTaskData()
    
    if not self.TaskData then
        return
    end
    local taskConfig = XDataCenter.TaskManager.GetTaskTemplate(self.TaskData.Id)
    self:RefreshButton()
    --刷新奖励列表
    local rewards = XRewardManager.GetRewardList(taskConfig.RewardId)
    if not rewards then
        return
    end

    for i = 1, #rewards do
        local grid = self.RewardList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            local tempTab = {}
            tempTab.Transform = ui.transform
            tempTab.GameObject = ui.gameObject
            XTool.InitUiObject(tempTab)
            ui.gameObject:SetActiveEx(true)
            ui.transform:SetParent(self.PanelReward, false)
            tempTab.Item = XUiGridCommon.New(self.RootUi, tempTab.GirdItem)
            grid = tempTab
            tableInsert(self.RewardList, tempTab)
        end
        grid.Item:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
        grid.PanelReceive.gameObject:SetActiveEx(false)
        grid.PanelReceived.gameObject:SetActiveEx(false)
        if self.TaskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            grid.PanelReceive.gameObject:SetActiveEx(true)
        elseif self.TaskData.State == XDataCenter.TaskManager.TaskState.Finish then
            grid.PanelReceived.gameObject:SetActiveEx(true)
        end
    end
    for i = #rewards + 1, #self.RewardList do
        self.RewardList[i].GameObject:SetActiveEx(false)
    end
end

function XUiPanelLink:RefreshTxtTime()
    local openTime = XDataCenter.TaskManager.GetLinkTimeTaskOpenTime(self.ActivityCfg.Params[2])
    local format = "yyyy-MM-dd HH:mm"
    local openTimeStr = XTime.TimestampToGameDateTimeString(openTime, format)
    --获取持续时间
    local timeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(self.ActivityCfg.Params[2])
    local durationTime = timeLimitCfg.Duration
    local endTime = openTime + durationTime
    local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, format)
    self.TxtTime.text = string.format("%s%s%s", openTimeStr, '~', endTimeStr)
end

-- 回流问卷
function XUiPanelLink:RefreshBackFlowTxtTime()
    local endTime = XDataCenter.ActivityManager.GetBackFlowEndTime()
    local format = "yyyy-MM-dd HH:mm"
    local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, format)
    --获取持续时间
    local backFlowCfg = XTaskConfig.GetBackFlowById(self.ActivityCfg.Params[3])
    local durationTime = backFlowCfg.Duration
    local openTime = endTime - durationTime
    local openTimeStr = XTime.TimestampToGameDateTimeString(openTime, format)
    self.TxtTime.text = string.format("%s%s%s", openTimeStr, '~', endTimeStr)
end

function XUiPanelLink:GetTaskData()
    if self.ActivityType == XActivityConfigs.ActivityType.BackFlowLink then
        self.TaskData = XDataCenter.TaskManager.GetTaskDataById(self.ActivityCfg.Params[2])
    else
        --获取该活动对应的任务
        self.TaskDatas = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.ActivityCfg.Params[2])
        self.TaskData = self.TaskDatas[1] or nil
    end
end

--根据任务状态刷新按钮显示
function XUiPanelLink:RefreshButton()
    self.BtnFinish.gameObject:SetActiveEx(false)
    self.BtnGo.gameObject:SetActiveEx(false)
    
    if self.TaskData.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnFinish.gameObject:SetActiveEx(true)
    elseif self.TaskData.State == XDataCenter.TaskManager.TaskState.Active or self.TaskData.State == XDataCenter.TaskManager.TaskState.Finish then
        self.BtnGo.gameObject:SetActiveEx(true)
    end
end

function XUiPanelLink:RefreshInfo()
    if self.ActivityType == XActivityConfigs.ActivityType.BackFlowLink then
        CSGameEventManager:Notify(XEventId.EVENT_ACTIVITY_INFO_UPDATE, XActivityConfigs.ActivityType.BackFlowLink)
    else
        CSGameEventManager:Notify(XEventId.EVENT_ACTIVITY_INFO_UPDATE, XActivityConfigs.ActivityType.Link)
    end
end

function XUiPanelLink:OnBtnGoClick()
    --通知后端任务完成了
    if self.TaskData then
        local taskCfg = XTaskConfig.GetTaskCfgById(self.TaskData.Id)
        local conditionTemplates = XTaskConfig.GetTaskCondition(taskCfg.Condition[1])
        XDataCenter.ActivityManager.TellFinishLinkTask(conditionTemplates.Params[2], function()
                self:Refresh()
                self:RefreshInfo()
            end)
    end
    
    XMVCA.XUrl:SkipByUrlId(self.UrlId)
end

function XUiPanelLink:OnBtnFinishClick()
    XDataCenter.TaskManager.FinishTask(self.TaskData.Id, function(rewards)
        XUiManager.OpenUiObtain(rewards, nil, function()
            self:Refresh()
        end, nil)
    end)
end

return XUiPanelLink