---@class XUiTransfiniteRewardGrid
local XUiTransfiniteRewardGrid = XClass(nil, "XUiTransfiniteRewardGrid")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiTransfiniteRewardGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)

    ---@type XUiTransfiniteAchievement
    self._RootUi = nil
    self._Data = nil
    ---@type XUiGridCommon
    self._NormalCommon = nil
    ---@type XUiGridCommon
    self._SeniorCommon = nil
end

function XUiTransfiniteRewardGrid:Init(rootUi)
    self._RootUi = rootUi
end

function XUiTransfiniteRewardGrid:SetData(data)
    self._Data = data
end

function XUiTransfiniteRewardGrid:Refresh()
    self:RefreshAchievementReward()
end

function XUiTransfiniteRewardGrid:RefreshAchievementReward()
    local data = self._Data
    local achievedState = XDataCenter.TaskManager.TaskState.Achieved
    local finishState = XDataCenter.TaskManager.TaskState.Finish
    local isNormalComplete = data.NormalTaskState == achievedState or data.NormalTaskState == finishState
    local isSeniorComplete = data.SeniorTaskState == achievedState or data.SeniorTaskState == finishState

    self.TxtFinishTask.text = data.Desc
    self.ImgComplete.gameObject:SetActiveEx(isNormalComplete and isSeniorComplete)

    self:RefreshRewardPanel()
end

function XUiTransfiniteRewardGrid:RefreshRewardPanel()
    local data = self._Data

    local isNormalFinish = data.NormalTaskState == XDataCenter.TaskManager.TaskState.Finish
    local isSeniorFinish = data.SeniorTaskState == XDataCenter.TaskManager.TaskState.Finish and data.IsUnlock
    local isNormalAchieved = data.NormalTaskState == XDataCenter.TaskManager.TaskState.Achieved
    local isSeniorAchieved = data.SeniorTaskState == XDataCenter.TaskManager.TaskState.Achieved and data.IsUnlock

    self.ImgNormalReceive.gameObject:SetActiveEx(isNormalFinish or isNormalAchieved)
    self.TxtNormalReceive.gameObject:SetActiveEx(isNormalFinish or isNormalAchieved)
    self.ImgSeniorReceive.gameObject:SetActiveEx(isSeniorFinish or isSeniorAchieved)
    self.TxtSeniorReceive.gameObject:SetActiveEx(isSeniorFinish or isSeniorAchieved)

    if isNormalFinish then
        self.TxtNormalReceive.text = XUiHelper.GetText("TransfiniteRewardReceive")
    end
    if isSeniorFinish then
        self.TxtSeniorReceive.text = XUiHelper.GetText("TransfiniteRewardReceive")
    end
    if isNormalAchieved then
        self.TxtNormalReceive.text = XUiHelper.GetText("TransfiniteRewardCanReceive")
    end
    if isSeniorAchieved then
        self.TxtSeniorReceive.text = XUiHelper.GetText("TransfiniteRewardCanReceive")
    end
    if not self._NormalCommon then
        self._NormalCommon = XUiGridCommon.New(self._RootUi, self.NormalRewardCommon)
    end
    if not self._SeniorCommon then
        self._SeniorCommon = XUiGridCommon.New(self._RootUi, self.SeniorRewardCommon)
    end

    self._NormalCommon:Refresh(data.NormalReward)
    self._NormalCommon.GameObject:SetActiveEx(true)
    self._NormalCommon:SetProxyClickFunc(function()
        self:OnNormalGridClick()
    end)
    self._SeniorCommon:Refresh(data.SeniorReward)
    self._SeniorCommon.GameObject:SetActiveEx(true)
    self._SeniorCommon:SetProxyClickFunc(function()
        self:OnSeniorGridClick()
    end)
    self.SeniorRewardLock.gameObject:SetActiveEx(not data.IsUnlock)

    self.TextNumber1.text = data.Desc
    self.EffectNormal.gameObject:SetActiveEx(isNormalAchieved)
    self.EffectSenior.gameObject:SetActiveEx(isSeniorAchieved)

    if self.PanelSeniorReward then
        if data.IsUnlock then
            self.PanelSeniorReward.alpha = 1
        else
            self.PanelSeniorReward.alpha = 0.5
        end
    end
end

function XUiTransfiniteRewardGrid:OnNormalGridClick()
    if self._Data.NormalTaskState == XDataCenter.TaskManager.TaskState.Achieved then
        self:ReceiveNormalReward()
    else
        XLuaUiManager.Open("UiTip", self._Data.NormalReward)
    end
end

function XUiTransfiniteRewardGrid:OnSeniorGridClick()
    if self._Data.IsUnlock and self._Data.SeniorTaskState == XDataCenter.TaskManager.TaskState.Achieved then
        self:ReceiveSeniorReward()
    else
        XLuaUiManager.Open("UiTip", self._Data.SeniorReward)
    end
end

function XUiTransfiniteRewardGrid:ReceiveNormalReward()
    XDataCenter.TransfiniteManager.RequestFinishTask(self._Data.NormalTaskId, function(rewardGood)
        XEventManager.DispatchEvent(XEventId.EVENT_TRANSFINITE_SUCCESS_REFRESH)
        XUiManager.OpenUiObtain(rewardGood)
    end)
end

function XUiTransfiniteRewardGrid:ReceiveSeniorReward()
    XDataCenter.TransfiniteManager.RequestFinishTask(self._Data.SeniorTaskId, function(rewardGood)
        XEventManager.DispatchEvent(XEventId.EVENT_TRANSFINITE_SUCCESS_REFRESH)
        XUiManager.OpenUiObtain(rewardGood)
    end)
end

return XUiTransfiniteRewardGrid