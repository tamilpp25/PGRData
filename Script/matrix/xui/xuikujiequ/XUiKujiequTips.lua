local XUiKujiequTips = XLuaUiManager.Register(XLuaUi, "UiKujiequTips")

function XUiKujiequTips:OnAwake()
    self:SetButtonCallBack()
end 

function XUiKujiequTips:OnStart()
    self:Refresh()
end

function XUiKujiequTips:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnClickBtnGo)
    XUiHelper.RegisterClickEvent(self, self.BtnChoice, self.OnClickBtnChoice)
end

function XUiKujiequTips:OnClickBtnGo()
    self:Close()
    XDataCenter.KujiequManager.OpenURL()
end

function XUiKujiequTips:OnEnable()

end

function XUiKujiequTips:OnDisable()

end

function XUiKujiequTips:OnClickBtnChoice()
    XDataCenter.KujiequManager.SetIgnoreTips()
    self.BtnChoice:SetButtonState(CS.UiButtonState.Select)
    self:OnClickBtnGo()
end

function XUiKujiequTips:Refresh()
    local taskId = XDataCenter.KujiequManager.GetTaskId()
    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    local showReward = taskData.State ~= XDataCenter.TaskManager.TaskState.Finish
    self.TxtMessage.gameObject:SetActiveEx(showReward)
    self.RImgIcon.gameObject:SetActiveEx(showReward)
    self.TxtCount.gameObject:SetActiveEx(showReward)

    -- 刷新奖励
    if showReward then
        local taskConfig = XDataCenter.TaskManager.GetTaskTemplate(taskId)
        local rewards = XRewardManager.GetRewardList(taskConfig.RewardId)
        local icon = XItemConfigs.GetItemIconById(rewards[1].TemplateId)
        self.RImgIcon:SetRawImage(icon)
        self.TxtCount.text = rewards[1].Count
    end
end
