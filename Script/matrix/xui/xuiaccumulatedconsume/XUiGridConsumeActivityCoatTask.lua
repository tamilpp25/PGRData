local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridConsumeActivityCoatTask = XClass(nil, "XUiGridConsumeActivityCoatTask")

function XUiGridConsumeActivityCoatTask:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.RewardPanelList = nil
    self:RegisterUiEvents()
end

function XUiGridConsumeActivityCoatTask:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridConsumeActivityCoatTask:OnBtnClick()
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
    end)
end

function XUiGridConsumeActivityCoatTask:Refresh(taskId)
    if not XTool.IsNumberValid(taskId) then
        return
    end
    self.Data = XDataCenter.TaskManager.GetTaskDataById(taskId)
    -- 进度
    self:UpdateProgress()
    --物品
    self:UpdateReward()
end

function XUiGridConsumeActivityCoatTask:UpdateProgress()
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    if #config.Condition < 2 then
        self.Imgjindutiao.transform.parent.gameObject:SetActiveEx(true)
        self.TxtQuantity.gameObject:SetActiveEx(true)
        --显示进度
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            self.Imgjindutiao.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            self.TxtQuantity.text = string.format("%d/%d", pair.Value, result)
        end)
    else
        self.Imgjindutiao.transform.parent.gameObject:SetActiveEx(false)
        self.TxtQuantity.gameObject:SetActiveEx(false)
    end
    
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.TxtQuantity.gameObject:SetActiveEx(false)
    self.ImgBg01.gameObject:SetActiveEx(false)
    self.Red.gameObject:SetActiveEx(false)
    self.BtnClick.gameObject:SetActiveEx(false)
    
    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then -- 未领取
        self.PanelEffect.gameObject:SetActiveEx(true)
        self.Red.gameObject:SetActiveEx(true)
        self.BtnClick.gameObject:SetActiveEx(true)
    elseif self.Data.State ~= XDataCenter.TaskManager.TaskState.Finish then -- 未完成
        self.ImgBg01.gameObject:SetActiveEx(true)
        self.TxtQuantity.gameObject:SetActiveEx(true)
    end
end

function XUiGridConsumeActivityCoatTask:UpdateReward()
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    if not XTool.IsTableEmpty(rewards) then
        if not self.RewardPanelList then
            self.RewardPanelList = XUiGridCommon.New(self.RootUi, self.Grid256New)
        end
        self.RewardPanelList:Refresh(rewards[1], { ShowReceived = self.Data.State == XDataCenter.TaskManager.TaskState.Finish })
    end
end

return XUiGridConsumeActivityCoatTask