local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPivotCombatTaskGrid = XClass(nil, "XUiPivotCombatTaskGrid")

function XUiPivotCombatTaskGrid:Ctor(ui)
    self.RewardGrids = {}
    XTool.InitUiObjectByUi(self, ui)
    self:InitCB()
end

function XUiPivotCombatTaskGrid:Init(rootUi)
    self.RootUi = rootUi
    self.GridCommon.gameObject:SetActiveEx(false)
end

function XUiPivotCombatTaskGrid:Refresh(taskData)
    self.Data = taskData or self.Data
    self.Config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    
    self:UpdateRewards()
    self:UpdateProgress()
    self:UpdateTaskText()
end

--更新奖励
function XUiPivotCombatTaskGrid:UpdateRewards()
    local rewards = XRewardManager.GetRewardList(self.Config.RewardId)
    if not rewards then
        return
    end

    for idx, item in ipairs(rewards) do
        local grid
        if self.RewardGrids[idx] then
            grid = self.RewardGrids[idx]
        else
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.GridCommon.parent)
            grid = XUiGridCommon.New(self.RootUi, ui)
            self.RewardGrids[idx] = grid
        end
        grid:Refresh(item)
        grid.GameObject:SetActiveEx(true)
    end
end

--更新进度条
function XUiPivotCombatTaskGrid:UpdateProgress()
    -- 判断条件大于2 不显示进度条
    if #self.Config.Condition < 2 then
        self.ImgProgress.transform.parent.gameObject:SetActiveEx(true)
        self.TxtTaskNumQian.gameObject:SetActiveEx(true)
        local result = self.Config.Result > 0 and self.Config.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            self.TxtTaskNumQian.text = pair.Value .. "/" .. result
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActiveEx(false)
        self.TxtTaskNumQian.gameObject:SetActiveEx(false)
    end
    
    --更新按钮状态
    if self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved and self.Data.State ~= XDataCenter.TaskManager.TaskState.Finish then
        self.BtnSkip.gameObject:SetActiveEx(true)
        if self.Config.SkipId == nil or self.Config.SkipId == 0 then
            self.BtnSkip:SetButtonState(CS.UiButtonState.Disable)
        else
            self.BtnSkip:SetButtonState(CS.UiButtonState.Normal)
        end
    else
        self.BtnSkip.gameObject:SetActiveEx(false)
    end
    
    self.BtnFinish.gameObject:SetActiveEx(self.Data.State == XDataCenter.TaskManager.TaskState.Achieved)
    self.BtnReceiveHave.gameObject:SetActiveEx(self.Data.State == XDataCenter.TaskManager.TaskState.Finish)
end

function XUiPivotCombatTaskGrid:UpdateTaskText()
    self.TxtTaskName.text = self.Config.Title
    self.TxtTaskDescribe.text = self.Config.Desc
end

function XUiPivotCombatTaskGrid:InitCB()
    self.BtnSkip.CallBack = function() XFunctionManager.SkipInterface(self.Config.SkipId)  end
    self.BtnFinish.CallBack = function() 
        self:OnClickBtnFinish()
    end
end

function XUiPivotCombatTaskGrid:OnClickBtnFinish()
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList) 
        XUiManager.OpenUiObtain(rewardGoodsList)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_PIVOTCOMBAT_GET_TASK_REWARD)
    end)
end


return XUiPivotCombatTaskGrid