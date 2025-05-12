local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiReCallTaskGrid
---@field _Control XReCallActivityControl
local XUiReCallTaskGrid = XClass(nil, "XUiReCallTaskGrid")

function XUiReCallTaskGrid:Ctor(ui, uiRegression)
    XTool.InitUiObjectByUi(self, ui)
    self.UiRegression = uiRegression
    self.GridCommon.gameObject:SetActiveEx(false)
    self.GridItems = {}
    self.TaskContent = self.GridCommon.transform.parent
    self.DynamicGrid = self.Transform:GetComponent("DynamicGrid")
    if self.DynamicGrid then
        self.DynamicGrid.PlayOnEnable = true
    end
    self:InitCb()
end

function XUiReCallTaskGrid:RefreshTask(taskData)
    if not taskData then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.Data = taskData

    self.TxtTitle.text = self.Data.desc
    self.TxtProgress.text = string.format("%s/%s", self.Data.recvTimes,self.Data.taskTimesLimit)
    if not string.IsNilOrEmpty(self.Data.icon) then
        --self.RImgTaskType:SetRawImage(self.Data.icon)
    end
    self:RefreshReward(self.Data.rewardId)

    --进度条
    self.ImgProgress.fillAmount = XUiHelper.GetFillAmountValue(self.Data.progress, 1)
    self:RefreshButton(self.Data.isComplete, self.Data.Finish)
end

function XUiReCallTaskGrid:RefreshReward(rewardId)
    self.RewardId = rewardId
    self:HideAllReward()
    local rewardList = XRewardManager.GetRewardList(rewardId)
    if XTool.IsTableEmpty(rewardList) then
        return
    end

    for idx, reward in ipairs(rewardList) do
        local grid = self.GridItems[idx]
        if not grid then
            local ui = idx == 1 and self.GridCommon or XUiHelper.Instantiate(self.GridCommon, self.TaskContent)
            grid = XUiGridCommon.New(self.UiRegression, ui)
            self.GridItems[idx] = grid
        end
        grid:Refresh(reward)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiReCallTaskGrid:HideAllReward()
    for _, grid in pairs(self.GridItems) do
        grid.GameObject:SetActiveEx(false)
    end
end

--- 刷新按钮状态
---@param finish 已完成且领取
---@param achieved 已完成未领取
---@return nil
--------------------------
function XUiReCallTaskGrid:RefreshButton(finish, achieved)
    self.BtnCollect.gameObject:SetActiveEx(not finish and achieved)
    self.ImgComplete.gameObject:SetActiveEx(finish)
    self.BtnSkip.gameObject:SetActiveEx(not finish and not achieved)
    self.BtnSkip:SetButtonState(CS.UiButtonState.Normal)
    --不可领取且任务到期时显示已结束
    local curTime = XTime.GetServerNowTimestamp()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.Data.timeId)
    if curTime > endTime and not achieved then
        self.BtnSkip:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiReCallTaskGrid:InitCb()
    self.BtnSkip.CallBack = function() 
        --暂无跳转需求
    end
    
    self.BtnCollect.CallBack = function() 
        self:OnBtnFinishClick()
    end
end

function XUiReCallTaskGrid:OnBtnFinishClick()
    if self.Data.Finish then
        self.UiRegression:GetTaskReward(self.Data.id)
    end
end

return XUiReCallTaskGrid