local tableInsert = table.insert
local CSXTextManagerGetText = CS.XTextManager.GetText

local XSlotMachineTaskGrid = XClass(nil, "XSlotMachineTaskGrid")

function XSlotMachineTaskGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    XTool.InitUiObject(self)
end

function XSlotMachineTaskGrid:Init(rootUi)
    self.RootUi = rootUi
    self:AutoRegisterBtn()
end

function XSlotMachineTaskGrid:UpdateGrid(data)
    self.Data = data
    self.TaskConfig = XTaskConfig.GetTaskConfigById(data.Id)
    self.TxtTaskName.text = self.TaskConfig.Title
    self.TxtTaskDescribe.text = self.TaskConfig.Desc
    local scheduleValue = data.Schedule[1] and data.Schedule[1].Value or 0
    self.TxtTaskNumQian.text = CSXTextManagerGetText("SlotMachineTaskNumProcess", scheduleValue, self.TaskConfig.Result)
    self.ImgProgress.fillAmount = scheduleValue / self.TaskConfig.Result
    local rewards = XRewardManager.GetRewardList(self.TaskConfig.RewardId)
    local rewardCount = #rewards
    local GridCommonUiList = {}
    for i = 0, self.GridCommon.parent.childCount-1 do
        if i > rewardCount-1 then
            self.GridCommon.parent:GetChild(i).gameObject:SetActiveEx(false)
        else
            tableInsert(GridCommonUiList, self.GridCommon.parent:GetChild(i))
        end
    end
    for i = 1, #rewards do
        local gridCommonUi = GridCommonUiList[i]
        local gridCommon = nil
        if not gridCommonUi then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            ui.transform:SetParent(self.GridCommon.parent, false)
            gridCommon = XUiGridCommon.New(self.RootUi, ui)
        else
            gridCommon = XUiGridCommon.New(self.RootUi, gridCommonUi)
        end
        gridCommon:Refresh(rewards[i])
    end

    self:SetState(data.State)
end

function XSlotMachineTaskGrid:SetState(state)
    if state == XDataCenter.TaskManager.TaskState.Active then
        self.BtnSkip.gameObject:SetActiveEx(true)
        self.ImgComplete.gameObject:SetActiveEx(false)
        self.BtnFinish.gameObject:SetActiveEx(false)
    elseif state == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnSkip.gameObject:SetActiveEx(false)
        self.ImgComplete.gameObject:SetActiveEx(false)
        self.BtnFinish.gameObject:SetActiveEx(true)
    elseif state == XDataCenter.TaskManager.TaskState.Finish then
        self.BtnSkip.gameObject:SetActiveEx(false)
        self.ImgComplete.gameObject:SetActiveEx(true)
        self.BtnFinish.gameObject:SetActiveEx(false)
    end
end

function XSlotMachineTaskGrid:AutoRegisterBtn()
    self.BtnFinish.CallBack = function () self:OnClickBtnReceive() end
    self.BtnSkip.CallBack = function () self:OnClickBtnSkip() end
end

function XSlotMachineTaskGrid:OnClickBtnReceive()
    if not self.Data then
        return
    end

    XDataCenter.SlotMachineManager.FinishTask(self.Data.Id)
end

function XSlotMachineTaskGrid:OnClickBtnSkip()
    if not self.TaskConfig then
        return
    end

    XFunctionManager.SkipInterface(self.TaskConfig.SkipId)
end

return XSlotMachineTaskGrid