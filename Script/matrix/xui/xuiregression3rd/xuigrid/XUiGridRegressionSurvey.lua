local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridRegressionSurvey
---@field _Cfg XTableRegression3Survey
---@field Parent XUiPanelRegressionQuestionnaire
local XUiGridRegressionSurvey = XClass(XUiNode, 'XUiGridRegressionSurvey')

local Day = 3600 * 24

function XUiGridRegressionSurvey:OnStart(cfg)
    self._Cfg = cfg
    
    self.Btn.CallBack = handler(self, self.OnBtnClickEvent)
    self._RegressionBeginTime = self.Parent.ViewModel._BeginTime
    self._LockSeconds = self._Cfg.OpenDay * Day
end

function XUiGridRegressionSurvey:OnEnable()
    self:Refresh()
end

function XUiGridRegressionSurvey:OnDisable()

end

function XUiGridRegressionSurvey:OnBtnClickEvent()
    if self._IsUnLock then
        if not self._IsAchieve then
            local taskId = self:GetTaskId()
            if XTool.IsNumberValid(taskId) then
                XDataCenter.TaskManager.RequestClientTaskFinish(taskId, function()
                    XDataCenter.TaskManager.FinishTask(taskId, function(rewards)
                        XUiManager.OpenUiObtain(rewards, nil, function()
                            self._IsAchieve = self:CheckIsFinished()
                            self:Refresh()
                        end, nil)
                    end)
                end)
            else
                if XTool.IsNumberValid(self._Cfg.TaskId) then
                    XLog.Error('回归问卷服务器数据中不存在有效的任务Id, 与当前配置不符:', 'SurveyId:'..tostring(self._Cfg.Id),'TaskId:'..tostring(self._Cfg.TaskId))
                end
            end
            
            XMVCA.XUrl:SkipByUrlId(self._Cfg.UrlId)
        else
            XUiManager.TipMsg(XRegression3rdConfigs.GetClientConfigValue('SurveyAchievedTips', 1))
        end
        
    else
        XUiManager.TipMsg(self._Cfg.LockTips)
    end
end

function XUiGridRegressionSurvey:Refresh()
    self._IsUnLock = self:CheckIsUnLock(XTime.GetServerNowTimestamp())
    self._IsAchieve = self:CheckIsFinished()
    self.TxtLock.text = self._Cfg.LockTips
    self.Btn:SetButtonState(self._IsUnLock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.Received.gameObject:SetActiveEx(self._IsAchieve)
    self:RefreshRewards()
end

function XUiGridRegressionSurvey:RefreshRewards()
    ---@type XRegression3rdSurvey
    local surveyViewModel = self.Parent.ViewModel._SurveyViewModel
    if surveyViewModel then
        local taskId = surveyViewModel:GetSurveyTaskIdBySurveyId(self._Cfg.Id) or self._Cfg.TaskId
        if XTool.IsNumberValid(taskId) then
            local complete = XDataCenter.TaskManager.CheckTaskFinished(taskId)
            local rewardId = XTaskConfig.GetTaskRewardId(taskId)
            if XTool.IsNumberValid(rewardId) then
                local rewardGoods = XRewardManager.GetRewardList(rewardId)
                if not XTool.IsTableEmpty(rewardGoods) then
                    self._GoodsPreview = {}
                    XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, rewardGoods and #rewardGoods or 0, function(index, obj)
                        local gridCommont = XUiGridCommon.New(nil, obj)
                        gridCommont:Refresh(rewardGoods[index])
                        gridCommont:SetReceived(complete)
                        table.insert(self._GoodsPreview, gridCommont)
                    end)
                    return
                end
            end
        end
    end
    self.Grid256New.gameObject:SetActiveEx(false)
end

function XUiGridRegressionSurvey:CheckIsUnLock(now)
    return now > self._RegressionBeginTime + self._LockSeconds
end

function XUiGridRegressionSurvey:CheckIsFinished()
    local surveyViewModel = self.Parent.ViewModel._SurveyViewModel
    if surveyViewModel then
        local taskId = surveyViewModel:GetSurveyTaskIdBySurveyId(self._Cfg.Id)
        if XTool.IsNumberValid(taskId) then
            return XDataCenter.TaskManager.CheckTaskFinished(taskId)
        end
    end
    return false
end

function XUiGridRegressionSurvey:GetTaskId()
    local surveyViewModel = self.Parent.ViewModel._SurveyViewModel
    if surveyViewModel then
        local taskId = surveyViewModel:GetSurveyTaskIdBySurveyId(self._Cfg.Id)
        return taskId
    end
end

return XUiGridRegressionSurvey