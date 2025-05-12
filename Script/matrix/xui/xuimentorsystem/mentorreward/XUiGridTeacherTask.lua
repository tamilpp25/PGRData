local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridTeacherTask = XClass(nil, "XUiGridTeacherTask")

function XUiGridTeacherTask:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RewardPanelList = {}
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.GridCommon.gameObject:SetActiveEx(false)
    self.ImgComplete.gameObject:SetActiveEx(false)
    self.PanelAnimation.gameObject:SetActiveEx(true)
end

function XUiGridTeacherTask:PlayAnimation()
    if self.IsAnimation then
        return
    end

    self.IsAnimation = true
    self.GridTaskTimeline:PlayTimelineAnimation()
end

function XUiGridTeacherTask:ResetData(data, student)
    self.ImgComplete.gameObject:SetActiveEx(data.State == XDataCenter.TaskManager.TaskState.Finish)
    self.Data = data
    self.StudentId = student.PlayerId
    self.IsGraduate = student.IsGraduate
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.TaskId)
    self.tableData = config
    self.TxtTaskName.text = config.Title
    self.TxtTaskDescribe.text = config.Desc
    self.TxtSubTypeTip.text = config.Suffix or ""
    self.RImgTaskType:SetRawImage(config.Icon)
    self:UpdateProgress(self.Data)
    local rewardId = XMentorSystemConfigs.GetTeacherChallengeRewardById(self.Data.TaskId).RewardId
    local rewards = XRewardManager.GetRewardList(rewardId)

    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end

    if not rewards then
        return
    end

    for i = 1, #rewards do
        
        local panel = self.RewardPanelList[i]
        if not panel then
            if #self.RewardPanelList == 0 then
                panel = XUiGridCommon.New(self.RootUi, self.GridCommon)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                ui.transform:SetParent(self.GridCommon.parent, false)
                panel = XUiGridCommon.New(self.RootUi, ui)
            end
            table.insert(self.RewardPanelList, panel)
        end
        panel:Refresh(rewards[i])
        
    end
    if self.PanelAnimationGroup then
        self.PanelAnimationGroup.alpha = 1
    end

end

function XUiGridTeacherTask:SetButtonCallBack()
    self.BtnFinish.CallBack = function() self:OnBtnFinishClick() end
end

function XUiGridTeacherTask:OnBtnFinishClick()
    local weaponCount = 0
    local chipCount = 0
    if self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved or not self.IsGraduate then
        XUiManager.TipText("MentorTeacherTaskHintText")
        return
    end
    for i = 1, #self.RewardPanelList do
        local rewardsId = self.RewardPanelList[i].TemplateId
        if XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
            weaponCount = weaponCount + 1
        elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
            chipCount = chipCount + 1
        end
    end
    if weaponCount > 0 and XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false or
    chipCount > 0 and XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false then
        return
    end
    XDataCenter.MentorSystemManager.MentorGetChallengeRewardRequest(self.StudentId, self.Data.TaskId, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
    end)
end

function XUiGridTeacherTask:UpdateProgress(data)
    self.Data = data
    local config = XDataCenter.TaskManager.GetTaskTemplate(data.TaskId)
    if #config.Condition < 2 then--显示进度
        self.ImgProgress.transform.parent.gameObject:SetActiveEx(true)
        self.TxtTaskNumQian.gameObject:SetActiveEx(true)
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            self.TxtTaskNumQian.text = string.format("%d/%d", pair.Value, result)
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActiveEx(false)
        self.TxtTaskNumQian.gameObject:SetActiveEx(false)
    end

    self.BtnFinish.gameObject:SetActiveEx(false)
    self.BtnReceiveHave.gameObject:SetActiveEx(false)
    
    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved and self.IsGraduate then
        self.BtnFinish.gameObject:SetActiveEx(true)
        self.BtnFinish:SetDisable(false)
    elseif self.Data.State == XDataCenter.TaskManager.TaskState.Finish and self.IsGraduate then
        self.BtnReceiveHave.gameObject:SetActiveEx(true)
    else
        self.BtnFinish.gameObject:SetActiveEx(true)
        self.BtnFinish:SetDisable(true)
    end
end

return XUiGridTeacherTask