
---@class XUiDlcCasualGamesTaskGrid : XUiNode
---@field RImgTaskType UnityEngine.UI.RawImage
---@field ImgProgress UnityEngine.UI.Image
---@field GridCommon UnityEngine.RectTransform
---@field BtnFinish XUiComponent.XUiButton
---@field TxtTaskName UnityEngine.UI.Text
---@field TxtTaskDescribe UnityEngine.UI.Text
---@field TxtTaskNumQian UnityEngine.UI.Text
---@field TxtSubTypeTip UnityEngine.UI.Text
---@field ImgComplete UnityEngine.UI.Image
---@field ProgressBg UnityEngine.RectTransform
---@field RewardContent UnityEngine.RectTransform
local XUiDlcCasualGamesTaskGrid = XClass(XUiNode, "XUiDlcCasualGamesTaskGrid")

function XUiDlcCasualGamesTaskGrid:OnStart()
    self._Data = nil
    self._RewardList = {}
    self.GridCommon.gameObject:SetActiveEx(false)
    self:_RegisterButtons()
end

function XUiDlcCasualGamesTaskGrid:OnEnable()
    self:_Refresh()
end

function XUiDlcCasualGamesTaskGrid:OnBtnFinishClick()
    XDataCenter.TaskManager.FinishTask(self._Data.Id, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
    end)
end

function XUiDlcCasualGamesTaskGrid:SetData(data)
    self._Data = data
    self:_Refresh()
end

function XUiDlcCasualGamesTaskGrid:_Refresh()
    if not self._Data then
        self:Close()
        return
    end

    local config = XDataCenter.TaskManager.GetTaskTemplate(self._Data.Id)
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    local length = #rewards

    self.ImgComplete.gameObject:SetActiveEx(self._Data.State == XDataCenter.TaskManager.TaskState.Finish)
    self.TxtTaskName.text = config.Title
    self.TxtTaskDescribe.text = config.Desc
    self.TxtSubTypeTip.text = config.Suffix or ""
    self.RImgTaskType:SetRawImage(config.Icon)
    self:_RefreshProgress()

    for i = 1, length do
        local grid = self._RewardList[i]

        if not grid then
            local gridUi = XUiHelper.Instantiate(self.GridCommon, self.RewardContent)

            grid = XUiGridCommon.New(self.Parent, gridUi)
            self._RewardList[i] = grid
        end

        grid:Refresh(rewards[i])
    end

    for i = length + 1, #self._RewardList do
        self._RewardList[i].GameObject:SetActiveEx(false)
    end
end

function XUiDlcCasualGamesTaskGrid:_RefreshProgress()
    local data = self._Data
    local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    local isAchieved = data.State == XDataCenter.TaskManager.TaskState.Achieved

    if #config.Condition < 2 then
        local result = config.Result > 0 and config.Result or 1

        self.ProgressBg.gameObject:SetActiveEx(true)
        self.TxtTaskNumQian.gameObject:SetActive(true)

        XTool.LoopMap(data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            self.TxtTaskNumQian.text = pair.Value .. "/" .. result
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
        self.TxtTaskNumQian.gameObject:SetActive(false)
    end

    self.BtnFinish:SetButtonState(isAchieved and XUiButtonState.Normal or XUiButtonState.Disable)
    self.BtnFinish.gameObject:SetActiveEx(data.State ~= XDataCenter.TaskManager.TaskState.Finish)
    self.BtnReceiveHave.gameObject:SetActiveEx(data.State == XDataCenter.TaskManager.TaskState.Finish)
end

function XUiDlcCasualGamesTaskGrid:_RegisterButtons()
    XUiHelper.RegisterClickEvent(self, self.BtnFinish, self.OnBtnFinishClick)
end

return XUiDlcCasualGamesTaskGrid