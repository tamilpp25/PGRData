local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridCoupletTask = XClass(nil, "XUiGridCoupletTask")

function XUiGridCoupletTask:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    XTool.InitUiObject(self)
end

function XUiGridCoupletTask:Init(rootUi)
    self.RootUi = rootUi
    self:AutoRegisterBtn()
    self.RewardPanelList = {}
end

function XUiGridCoupletTask:UpdateGrid(data)
    self.Data = data
    self.TaskConfig = XTaskConfig.GetTaskCfgById(data.Id)
    self.TxtGrade.text = self.TaskConfig.Title
    self.TxtTaskDescribe.text = self.TaskConfig.Desc
    self.TxtTaskNumQian.text = CSXTextManagerGetText("CoupletGameTaskNumProcess", data.Schedule[1].Value, self.TaskConfig.Result)
    self.ImgProgress.fillAmount = data.Schedule[1].Value / self.TaskConfig.Result

    local rewards = XRewardManager.GetRewardList(self.TaskConfig.RewardId)
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

    self:SetState(data.State)
end

function XUiGridCoupletTask:SetState(state)
    if state == XDataCenter.TaskManager.TaskState.Active then
        self.ImgCannotReceive.gameObject:SetActiveEx(true)
        self.ImgAlreadyReceived.gameObject:SetActiveEx(false)
        self.BtnReceive.gameObject:SetActiveEx(false)
    elseif state == XDataCenter.TaskManager.TaskState.Achieved then
        self.ImgCannotReceive.gameObject:SetActiveEx(false)
        self.ImgAlreadyReceived.gameObject:SetActiveEx(false)
        self.BtnReceive.gameObject:SetActiveEx(true)
    elseif state == XDataCenter.TaskManager.TaskState.Finish then
        self.ImgCannotReceive.gameObject:SetActiveEx(false)
        self.ImgAlreadyReceived.gameObject:SetActiveEx(true)
        self.BtnReceive.gameObject:SetActiveEx(false)
    end
end

function XUiGridCoupletTask:AutoRegisterBtn()
    self.BtnReceive.CallBack = function () self:OnClickBtnReceive() end
end

function XUiGridCoupletTask:OnClickBtnReceive()
    if not self.Data then
        return
    end

    XDataCenter.CoupletGameManager.FinishTask(self.Data.Id)
end

return XUiGridCoupletTask