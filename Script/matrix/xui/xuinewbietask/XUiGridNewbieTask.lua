local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
-- 新手任务二期
local XUiGridNewbieTask = XClass(nil, "XUiGridNewbieTask")

function XUiGridNewbieTask:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:RegisterUiEvents()

    self.RewardPanelList = {}

    self.PanelReward.gameObject:SetActiveEx(false)
end

function XUiGridNewbieTask:Refresh(taskId)
    self.TaskId = taskId
    local templateTaskData = XDataCenter.TaskManager.GetTaskTemplate(taskId)
    local stateTaskData = XDataCenter.TaskManager.GetTaskDataById(taskId)

    self.TxtTitle.text = XUiHelper.ConvertLineBreakSymbol(templateTaskData.Desc)
    local result = templateTaskData.Result > 0 and templateTaskData.Result or 1
    XTool.LoopMap(stateTaskData.Schedule, function(_, pair)
        pair.Value = pair.Value > result and result or pair.Value
        self.TxtProgress.text = string.format("%d/%d", pair.Value, result)
    end)
    
    self:RefreshBtn()
    self:RefreshRewards()
end

function XUiGridNewbieTask:RefreshBtn()
    if self.TaskId == nil then
        return
    end
    local stateTaskData = XDataCenter.TaskManager.GetTaskDataById(self.TaskId)
    self.TxtProgress.gameObject:SetActiveEx(true)
    self.BtnCollect.gameObject:SetActiveEx(false)
    self.BtnSkip.gameObject:SetActiveEx(false)
    self.ImgComplete.gameObject:SetActiveEx(false)
    if stateTaskData.State == XDataCenter.TaskManager.TaskState.Achieved then
        --可领取
        self.BtnCollect.gameObject:SetActiveEx(true)
    elseif stateTaskData.State ~= XDataCenter.TaskManager.TaskState.Finish and stateTaskData.State ~= XDataCenter.TaskManager.TaskState.Invalid then
        --跳转
        self.BtnSkip.gameObject:SetActiveEx(true)
    elseif stateTaskData.State == XDataCenter.TaskManager.TaskState.Finish then
        -- 已完成
        self.ImgComplete.gameObject:SetActiveEx(true)
        self.TxtProgress.gameObject:SetActiveEx(false)
    end
end

function XUiGridNewbieTask:RefreshRewards()
    if self.TaskId == nil then
        return
    end
    local templateTaskData = XDataCenter.TaskManager.GetTaskTemplate(self.TaskId)
    local rewards = XRewardManager.GetRewardList(templateTaskData.RewardId)
    if not rewards then
        return
    end
    local rewardCount = #rewards

    for i = 1, rewardCount do
        local panel = self.RewardPanelList[i]
        if not panel then
            local ui = XUiHelper.Instantiate(self.PanelReward, self.UiContent)
            ui.gameObject:SetActiveEx(true)
            ui.gameObject.name = string.format("PanelReward%d", i)
            panel = XUiGridCommon.New(self.RootUi, ui)
            table.insert(self.RewardPanelList, i, panel)
        end
        panel:Refresh(rewards[i])
    end
    
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i].GameObject:SetActiveEx(i <= rewardCount)
    end
end

function XUiGridNewbieTask:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnCollect, self.OnBtnCollectClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)
end

function XUiGridNewbieTask:OnBtnCollectClick()
    if not self.TaskId then
        return
    end

    local taskData = XDataCenter.TaskManager.GetTaskDataById(self.TaskId)
    if taskData.State ~= XDataCenter.TaskManager.TaskState.Achieved then
        return
    end

    local weaponCount = 0
    local chipCount = 0
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

    XDataCenter.TaskManager.FinishTask(taskData.Id, function(rewards)
        XUiManager.OpenUiObtain(rewards, nil, function()
            self.RootUi:OnRewardTaskFinish(rewards)
        end, nil)
    end)
end

function XUiGridNewbieTask:OnBtnSkipClick()
    local templateTaskData = XDataCenter.TaskManager.GetTaskTemplate(self.TaskId)
    local stateTaskData = XDataCenter.TaskManager.GetTaskDataById(self.TaskId)
    if not templateTaskData then
        return
    end

    if stateTaskData.State ~= XDataCenter.TaskManager.TaskState.Achieved then
        XFunctionManager.SkipInterface(templateTaskData.SkipId)
    end
end

return XUiGridNewbieTask