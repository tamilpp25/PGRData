local XUiGridStudentWeeklyTask = XClass(nil, "XUiGridStudentWeeklyTask")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridStudentWeeklyTask:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.RewardList = {}
end

function XUiGridStudentWeeklyTask:SetButtonCallBack()
    self.BtnVacancy.CallBack = function()
        self:OnBtnVacancyClick()
    end
    self.PanelUndone:GetObject("BtnDelect").CallBack = function()
        self:OnBtnDelectClick()
    end
    self.PanelFinishHasReward:GetObject("BtnGet").CallBack = function()
        self:OnBtnGetClick()
    end
end

function XUiGridStudentWeeklyTask:UpdateGrid(index)
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local curGetedCount = mentorData:GetStudentWeeklyTaskCountByIndex(XMentorSystemConfigs.MySelfIndex)
    local curDaliyCount = mentorData:GetStudentSystemTaskCountByIndex(XMentorSystemConfigs.MySelfIndex)
    local maxDaliyCount = XMentorSystemConfigs.GetMentorSystemData("GetTaskCount")

    self.StudentData = mentorData:GetNotGraduateStudentDataByIndex(XMentorSystemConfigs.MySelfIndex)
    self.Task = self.StudentData and self.StudentData.WeeklyTask[index]
    if self.Task then
        self.PanelUndone.gameObject:SetActiveEx(self:IsUnDone())
        self.PanelFinishNoReward.gameObject:SetActiveEx(self:IsNoReward())
        self.PanelFinishHasReward.gameObject:SetActiveEx(self:IsHasReward() or self:IsGetedReward())
        self.BtnVacancy.gameObject:SetActiveEx(false)

        if self:IsUnDone() then
            self:ShowPanelUndone()
        elseif self:IsNoReward() then
            self:ShowPanelFinishNoReward()
        elseif self:IsHasReward() or self:IsGetedReward()then
            self:ShowPanelFinishHasReward()
        end
    else
        local emptyIndex = index - curGetedCount
        local emptyCount = maxDaliyCount - curDaliyCount

        self.PanelUndone.gameObject:SetActiveEx(false)
        self.PanelFinishNoReward.gameObject:SetActiveEx(false)
        self.PanelFinishHasReward.gameObject:SetActiveEx(false)
        self.BtnVacancy.gameObject:SetActiveEx(emptyIndex <= emptyCount)
    end
end

function XUiGridStudentWeeklyTask:ShowPanelUndone()
    local taskCfg = XDataCenter.TaskManager.GetTaskTemplate(self.Task.TaskId)
    local txtTaskNumQian = self.PanelUndone:GetObject("TxtTaskNumQian")
    local imgProgress = self.PanelUndone:GetObject("ImgProgress")

    self.PanelUndone:GetObject("TaskText").text = taskCfg.Title
    self.PanelUndone:GetObject("TxtTaskDescribe").text = taskCfg.Desc

    if #taskCfg.Condition < 2 then
        imgProgress.transform.parent.gameObject:SetActiveEx(true)
        txtTaskNumQian.gameObject:SetActiveEx(true)
        local result = taskCfg.Result > 0 and taskCfg.Result or 1
        XTool.LoopMap(self.Task.Schedule, function(_, pair)
                imgProgress.fillAmount = pair.Value / result
                pair.Value = (pair.Value >= result) and result or pair.Value
                txtTaskNumQian.text = string.format("%d/%d", pair.Value, result)
            end)
    else
        imgProgress.transform.parent.gameObject:SetActiveEx(false)
        txtTaskNumQian.gameObject:SetActiveEx(false)
    end
end

function XUiGridStudentWeeklyTask:ShowPanelFinishNoReward()
    self.PanelFinishNoReward:GetObject("TextHint").text = CSTextManagerGetText("MentorStudentFinishTaskNoRewardHint")
end

function XUiGridStudentWeeklyTask:ShowPanelFinishHasReward()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local teacher = mentorData:GetTeacherData()
    local gridCommon = self.PanelFinishHasReward:GetObject("GridCommon")
    local textHint = self.PanelFinishHasReward:GetObject("TextHint")
    local Content = self.PanelFinishHasReward:GetObject("Content")

    textHint.text = CSTextManagerGetText("MentorStudentFinishTaskHasRewardHint",teacher.PlayerName)
    local rewardId = self.Task.RewardId > 0 and self.Task.RewardId or XMentorSystemConfigs.GetMentorSystemData("ActivationRewardId")
    local rewards = XRewardManager.GetRewardList(rewardId)
    gridCommon.gameObject:SetActiveEx(false)

    for i = 1, #self.RewardList do
        self.RewardList[i]:Refresh()
    end

    if rewards then
        for i = 1, #rewards do
            local grid = self.RewardList[i]
            if not grid then
                local ui = CS.UnityEngine.Object.Instantiate(gridCommon)
                ui.transform:SetParent(Content, false)
                ui.gameObject:SetActiveEx(true)
                grid = XUiGridCommon.New(self.Root, ui)
                table.insert(self.RewardList, grid)
            end
            grid:Refresh(rewards[i])
        end
    end

    self.PanelFinishHasReward:GetObject("BtnGet").gameObject:SetActiveEx(self:IsHasReward())
    self.PanelFinishHasReward:GetObject("BtnGeted").gameObject:SetActiveEx(self:IsGetedReward())
end

function XUiGridStudentWeeklyTask:OnBtnVacancyClick()
    XLuaUiManager.Open("UiMentorSelectTask", false, nil, self.StudentData)---要在里面加即时刷新
end

function XUiGridStudentWeeklyTask:OnBtnDelectClick()
    self:TipDialog(nil,function ()
            XDataCenter.MentorSystemManager.StudentDeleteDailyTaskRequest(self.Task.TaskId, function ()
                    self.Root:UpdatePanel()
                end)
        end,"MentorStudentDeleteTaskHint")
end

function XUiGridStudentWeeklyTask:OnBtnGetClick()
    --local IsOverLimit = XDataCenter.EquipManager.CheckBoxOverLimitOfGetAwareness()
    --if IsOverLimit then
    --    return
    --end
    XDataCenter.MentorSystemManager.StudentReceiveRewardRequest(self.Task.TaskId, function (rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
            self.Root:UpdatePanel()
        end)
end

function XUiGridStudentWeeklyTask:IsUnDone()
    return self.Task.Status == XMentorSystemConfigs.TaskStatus.Received
end

function XUiGridStudentWeeklyTask:IsNoReward()
    return self.Task.Status == XMentorSystemConfigs.TaskStatus.Completed or
    self.Task.Status == XMentorSystemConfigs.TaskStatus.GetReward
end

function XUiGridStudentWeeklyTask:IsHasReward()
    return self.Task.Status == XMentorSystemConfigs.TaskStatus.GiveEquip
end

function XUiGridStudentWeeklyTask:IsGetedReward()
    return self.Task.Status == XMentorSystemConfigs.TaskStatus.ReceiveEquip
end

function XUiGridStudentWeeklyTask:TipDialog(cancelCb, confirmCb,TextKey)
    CsXUiManager.Instance:Open("UiDialog", CSTextManagerGetText("TipTitle"), CSTextManagerGetText(TextKey),
        XUiManager.DialogType.Normal, cancelCb, confirmCb)
end

return XUiGridStudentWeeklyTask