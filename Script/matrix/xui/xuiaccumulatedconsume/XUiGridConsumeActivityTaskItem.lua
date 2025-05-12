local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridConsumeActivityTaskItem = XClass(nil, "XUiGridConsumeActivityTaskItem")

function XUiGridConsumeActivityTaskItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RewardPanelList = {}
    self:RegisterUiEvents()
end

function XUiGridConsumeActivityTaskItem:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTcanchaungBlue, self.OnBtnFinishClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGoTo, self.OnBtnSkipClick)
end

function XUiGridConsumeActivityTaskItem:Refresh(data)
    self.Data = data
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    --名字
    self.TxtName.text = config.Title
    --描述
    self.TxtDesc.text = config.Desc
    --进度
    self:UpdateProgress()
    --物品
    self:UpdateReward(config.RewardId)
    -- 已领取
    local isFinish = data.State == XDataCenter.TaskManager.TaskState.Finish
    self.Received.gameObject:SetActive(isFinish)
end

function XUiGridConsumeActivityTaskItem:UpdateProgress()
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    if #config.Condition < 2 then --显示进度
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            self.Imgjindutiao.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            self.TxtProgress.text = CSXTextManagerGetText("ConsumeActivityMainTaskProgressText", pair.Value, result)
        end)
    else
        self.Imgjindutiao.transform.parent.gameObject:SetActiveEx(false)
    end

    self.BtnTcanchaungBlue.gameObject:SetActiveEx(false)
    self.BtnGoTo.gameObject:SetActiveEx(false)

    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnTcanchaungBlue.gameObject:SetActiveEx(true)
    elseif self.Data.State ~= XDataCenter.TaskManager.TaskState.Finish then
        self.BtnGoTo.gameObject:SetActiveEx(true)

        local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
        if skipId == nil or skipId == 0 then
            self.BtnGoTo.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridConsumeActivityTaskItem:UpdateReward(rewardId)
    local rewards = XRewardManager.GetRewardList(rewardId)
    if rewards then
        for i = 1, #rewards do
            local panel = self.RewardPanelList[i]
            if not panel then
                local go =  #self.RewardPanelList == 0 and self.Grid256 or XUiHelper.Instantiate(self.Grid256, self.Transform)
                panel = XUiGridCommon.New(self.RootUi, go)
                table.insert(self.RewardPanelList, panel)
            end
            panel:Refresh(rewards[i])
        end
    end
end

function XUiGridConsumeActivityTaskItem:OnBtnFinishClick()
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
    end)
end

function XUiGridConsumeActivityTaskItem:OnBtnSkipClick()
    local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
    XFunctionManager.SkipInterface(skipId)
end

return XUiGridConsumeActivityTaskItem