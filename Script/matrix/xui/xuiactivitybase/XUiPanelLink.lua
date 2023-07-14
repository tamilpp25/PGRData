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

    self.LinkCfg = XActivityConfigs.GetActivityLinkCfg(self.ActivityCfg.Params[1])
    self.TxtTitle.text = stringGsub(self.ActivityCfg.ActivityTitle, "\\n", "\n")

    local openTime = XDataCenter.TaskManager.GetLinkTimeTaskOpenTime(self.ActivityCfg.Params[2])
    local format = "yyyy-MM-dd HH:mm"
    local openTimeStr = XTime.TimestampToGameDateTimeString(openTime, format)
    --获取持续时间
    local timeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(self.ActivityCfg.Params[2])
    local durationTime = timeLimitCfg.Duration
    local endTime = openTime + durationTime
    local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, format)
    self.TxtTime.text = string.format("%s%s%s", openTimeStr, '~', endTimeStr)
    self.TxtContent.text = stringGsub(self.ActivityCfg.ActivityDes, "\\n", "\n")

    --获取该活动对应的任务
    self.TaskDatas = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.ActivityCfg.Params[2])
    if not self.TaskDatas or not self.TaskDatas[1] then
        return
    end
    local taskConfig = XDataCenter.TaskManager.GetTaskTemplate(self.TaskDatas[1].Id)
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
        grid.PanelReceive.gameObject:SetActiveEx(false)
        grid.PanelReceived.gameObject:SetActiveEx(false)
        if self.TaskDatas[1].State == XDataCenter.TaskManager.TaskState.Achieved then
            grid.PanelReceive.gameObject:SetActiveEx(true)
        elseif self.TaskDatas[1].State == XDataCenter.TaskManager.TaskState.Finish then
            grid.PanelReceived.gameObject:SetActiveEx(true)
        end
    end
end

--根据任务状态刷新按钮显示
function XUiPanelLink:RefreshButton()
    self.BtnFinish.gameObject:SetActiveEx(false)
    self.BtnGo.gameObject:SetActiveEx(false)
    
    if self.TaskDatas[1].State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnFinish.gameObject:SetActiveEx(true)
    elseif self.TaskDatas[1].State == XDataCenter.TaskManager.TaskState.Active or self.TaskDatas[1].State == XDataCenter.TaskManager.TaskState.Finish then
        self.BtnGo.gameObject:SetActiveEx(true)
    end
end

function XUiPanelLink:OnBtnGoClick()
    --通知后端任务完成了
    if self.TaskDatas and self.TaskDatas[1] then
        local taskCfg = XTaskConfig.GetTaskCfgById(self.TaskDatas[1].Id)
        local conditionTemplates = XTaskConfig.GetTaskCondition(taskCfg.Condition[1])
        XDataCenter.ActivityManager.TellFinishLinkTask(conditionTemplates.Params[2], function()
                self:Refresh()
                CSGameEventManager:Notify(XEventId.EVENT_ACTIVITY_INFO_UPDATE, XActivityConfigs.ActivityType.Link)
            end)
    end
    CS.UnityEngine.Application.OpenURL(self.LinkCfg.LinkUrl)
end

function XUiPanelLink:OnBtnFinishClick()
    XDataCenter.TaskManager.FinishTask(self.TaskDatas[1].Id, function(rewards)
        XUiManager.OpenUiObtain(rewards, nil, function()
            self:Refresh()
        end, nil)
    end)
end

return XUiPanelLink