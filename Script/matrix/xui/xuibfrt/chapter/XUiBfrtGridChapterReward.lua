local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiBfrtGridChapterReward : XUiNode
---@field _Control
local XUiBfrtGridChapterReward = XClass(XUiNode, "XUiBfrtGridChapterReward")

function XUiBfrtGridChapterReward:OnStart()
    self._RewardGridList = {}
    self:AddBtnListener()
end

---@param taskData XBfrtTaskData
function XUiBfrtGridChapterReward:Refresh(taskData)
    self._TaskData = taskData
    
    if self._TaskData.IsReward then
        self:_RefreshRewardTask()
    else
        self:_RefreshTask()
    end
    self.BtnReceive.gameObject:SetActiveEx(taskData.State == XDataCenter.TaskManager.TaskState.Achieved)
    self.ImgCannotReceive.gameObject:SetActiveEx(taskData.State == XDataCenter.TaskManager.TaskState.Active)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(taskData.State == XDataCenter.TaskManager.TaskState.Finish)
end

--region Ui - Task
function XUiBfrtGridChapterReward:_RefreshTask()
    local config = XDataCenter.TaskManager.GetTaskTemplate(self._TaskData.Id)

    self.TxtGrade.text = config.Title
    self.TxtTaskDescribe.text = config.Desc
    self:_RefreshReward(config.RewardId)
    self:_RefreshTaskProcess(self._TaskData, config)
end

function XUiBfrtGridChapterReward:_RefreshTaskProcess(taskData, config)
    if #config.Condition < 2 then--显示进度
        self.ImgProgress.transform.parent.gameObject:SetActive(true)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(true)
        end
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(taskData.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            if self.TxtTaskNumQian then
                self.TxtTaskNumQian.text = pair.Value .. "/" .. result
            end
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(false)
        end
    end
end
--endregion

--region Ui - RewardTask
function XUiBfrtGridChapterReward:_RefreshRewardTask()
    self.TxtGrade.text = self._TaskData.Title
    self.TxtTaskDescribe.text = self._TaskData.Desc
    self:_RefreshReward(self._TaskData.Id)
    self:_RefreshRewardTaskProcess(self._TaskData)
end

function XUiBfrtGridChapterReward:_RefreshRewardTaskProcess(taskData)
    local result = 1
    XTool.LoopMap(taskData.Schedule, function(_, pair)
        self.ImgProgress.fillAmount = pair.Value / result
        pair.Value = (pair.Value >= result) and result or pair.Value
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.text = pair.Value .. "/" .. result
        end
    end)
end
--endregion

--region Ui - Process
function XUiBfrtGridChapterReward:_RefreshTaskProcess(taskData, config)
    if #config.Condition < 2 then--显示进度
        self.ImgProgress.transform.parent.gameObject:SetActive(true)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(true)
        end
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(taskData.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            if self.TxtTaskNumQian then
                self.TxtTaskNumQian.text = pair.Value .. "/" .. result
            end
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(false)
        end
    end
end
--endregion

--region Ui - Reward
function XUiBfrtGridChapterReward:_RefreshReward(rewardId)
    local rewards = XRewardManager.GetRewardList(rewardId)
    for i = 1, #self._RewardGridList do
        self._RewardGridList[i]:Refresh()
    end

    if not rewards then
        return
    end

    for i = 1, #rewards do
        local gird = self._RewardGridList[i]
        local reward = rewards[i]
        if not gird then
            if #self._RewardGridList == 0 then
                gird = XUiGridCommon.New(self.RootUi, self.GridCommon)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                ui.transform:SetParent(self.GridCommon.parent, false)
                gird = XUiGridCommon.New(self.RootUi, ui)
            end

            if self.ClickFunc then
                XUiHelper.RegisterClickEvent(gird, gird.BtnClick, function()
                    self.ClickFunc(reward)
                end)
            end

            table.insert(self._RewardGridList, gird)
        end
        gird:Refresh(reward)
    end
end
--endregion

--region Ui - BtnListener
function XUiBfrtGridChapterReward:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnReceive, handler(self, self.OnBtnAchieved))
end

function XUiBfrtGridChapterReward:OnBtnAchieved()
    if XTool.IsTableEmpty(self._TaskData) then
        return
    end
    if self._TaskData.IsReward then
        XDataCenter.BfrtManager.RequestReceiveChapterGroupReward(self._TaskData.ChapterId, self._TaskData.GroupId)
    else
        XDataCenter.TaskManager.FinishTask(self._TaskData.Id, function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
        end)
    end
end
--endregion

return XUiBfrtGridChapterReward