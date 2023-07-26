local XUiGridReward = XClass(nil, "XUiGridReward")

XUiGridReward.ViewState = {
    CannotBeReceived = 0,
    CanBeReceived = 1,
    HasReceived = 2,
}

function XUiGridReward:Ctor(ui, root, index)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui:GetComponent("RectTransform") ---@type UnityEngine.RectTransform
    self.Root = root
    XTool.InitUiObject(self)

    self.Index = index
    self.RewardEntity = XDataCenter.DiceGameManager.GetRewardEntityByIndex(index)

    self.TxtScoreRequired = self.TxtCurStage
    self.TxtScoreRequired.text = tostring(self.RewardEntity:GetScoreRequired())
    self.Grid = XUiGridCommon.New(self.Root, self.GridCommon)
    local rewardItems = XRewardManager.GetRewardList(self.RewardEntity:GetRewardId())
    for i, item in ipairs(rewardItems) do
        self.Grid:Refresh(item)
    end

    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)

    self:ChangeViewState(self.ViewState.CannotBeReceived)
end

function XUiGridReward:OnBtnClick()
    if self.state == self.ViewState.CanBeReceived then
        XDataCenter.DiceGameManager.DiceGameGetRewardRequest(self.Index, function(response)
            XUiManager.OpenUiObtain(response.RewardGoodsList)
            self:ChangeViewState(self.ViewState.HasReceived)
        end)
    else
        XUiManager.OpenUiTipRewardByRewardId(self.RewardEntity:GetRewardId())
    end
end

function XUiGridReward:UpdateView(curScore)
    local scoreRequired = self.RewardEntity:GetScoreRequired()
    if self.RewardEntity:HasReceived() then
        self:ChangeViewState(self.ViewState.HasReceived)
    else
        local state = curScore >= scoreRequired and self.ViewState.CanBeReceived or self.ViewState.CannotBeReceived
        self:ChangeViewState(state)
    end
end

function XUiGridReward:ChangeViewState(state)
    self.state = state
    self.PanelFinish.gameObject:SetActive(state & self.ViewState.HasReceived ~= 0)
    self.Red.gameObject:SetActive(state & self.ViewState.CanBeReceived ~= 0)
end

function XUiGridReward:UpdatePosition(maxScore, progressImgWidth, templatePosition)
    local offsetX = self.RectTransform.rect.size.x / 2
    local newPosition = Vector3(self.RewardEntity:GetScoreRequired() / maxScore * progressImgWidth + offsetX, templatePosition.y, templatePosition.z)
    self.RectTransform.anchoredPosition3D = newPosition
end

return XUiGridReward