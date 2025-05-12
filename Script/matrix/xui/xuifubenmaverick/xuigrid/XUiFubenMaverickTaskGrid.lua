local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiFubenMaverickTaskGrid = XClass(nil, "XUiFubenMaverickTaskGrid")
local Instantiate = CS.UnityEngine.Object.Instantiate

function XUiFubenMaverickTaskGrid:Ctor(ui)
    self.RewardGrids = { }
    
    XTool.InitUiObjectByUi(self, ui)
    
    self:InitButtons()
end

function XUiFubenMaverickTaskGrid:InitButtons()
    self.BtnSkip.CallBack = function() XFunctionManager.SkipInterface(self.Config.SkipId) end
    self.BtnFinish.CallBack = function() self:OnBtnFinishClick() end
end

function XUiFubenMaverickTaskGrid:Refresh(data)
    self.Data = data or self.Data
    self.Config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    
    self:UpdateRewards()
    self:UpdateProgress()
    self:UpdateTaskTexts()
end

function XUiFubenMaverickTaskGrid:UpdateTaskTexts()
    self.TxtTaskName.text = self.Config.Title
    self.TxtTaskDescribe.text = self.Config.Desc
end

function XUiFubenMaverickTaskGrid:UpdateRewards()
    local rewards = XRewardManager.GetRewardList(self.Config.RewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.RewardGrids[i] then
                grid = self.RewardGrids[i]
            else
                local ui = Instantiate(self.GridCommon, self.GridCommon.parent)
                grid = XUiGridCommon.New(self.RootUi, ui)
                self.RewardGrids[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.RewardGrids do
        if j > rewardsCount then
            self.RewardGrids[j].GameObject:SetActiveEx(false)
        end
    end

    self.GridCommon.gameObject:SetActiveEx(false)
end

function XUiFubenMaverickTaskGrid:OnBtnFinishClick()
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MAVERICK_MEMBER_GET_TASK_REWARD)
    end)
end

function XUiFubenMaverickTaskGrid:UpdateProgress()
    if #self.Config.Condition < 2 then--显示进度
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

return XUiFubenMaverickTaskGrid