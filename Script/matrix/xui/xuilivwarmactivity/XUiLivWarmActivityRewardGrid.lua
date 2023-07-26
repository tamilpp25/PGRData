local XUiLivWarmActivityRewardGrid = XClass(nil, "XUiLivWarmActivityRewardGrid")

local CSTextManagerGetText = CS.XTextManager.GetText

function XUiLivWarmActivityRewardGrid:Ctor(rootUi, ui, receiveCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ReceiveCb = receiveCb
    XTool.InitUiObject(self)

    self:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnActive, self.OnBtnReceiveClick)
end

function XUiLivWarmActivityRewardGrid:Init()
    self.Grid = XUiGridCommon.New(self.RootUi, self.GridCommon)
end

function XUiLivWarmActivityRewardGrid:SetData(data)
    self.StageId = data.StageId
    self.RewardId = data.RewardId
    self.RewardProgress = data.RewardProgress
    self.RewardProgressIndex = data.RewardProgressIndex
    self.IsReward = data.IsReward

    self.TxtValue.text = self.RewardProgress

    local rewardList = XTool.IsNumberValid(self.RewardId) and XRewardManager.GetRewardList(self.RewardId)
    local itemId = rewardList and rewardList[1]
    if XTool.IsNumberValid(itemId) then
        self.Grid:Refresh(itemId)
    end

    self:Refresh()
end

function XUiLivWarmActivityRewardGrid:Refresh()
    if not self.GameObject.activeSelf then
        return
    end

    local stageDb = XDataCenter.LivWarmActivityManager.GetStageDb(self.StageId)
    local dismisCount = stageDb:GetDismisCount()
    local takeRewardProgressIndex = stageDb:GetTakeRewardProgressIndex()
    local isAlreadyReceive = self.RewardProgressIndex <= takeRewardProgressIndex      --是否已领取
    local isCanReceive = self.RewardProgress <= dismisCount and not isAlreadyReceive    --是否可领取
    self.ImgRe.gameObject:SetActiveEx(isAlreadyReceive)
    self.BtnActive.gameObject:SetActiveEx(self.IsReward or false)  --有可领取的奖励时，显示领奖按钮

    --所有奖励的特效同时播放
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(isCanReceive)
end

function XUiLivWarmActivityRewardGrid:OnBtnReceiveClick()
    if self.ReceiveCb then
        self.ReceiveCb()
    end
end

function XUiLivWarmActivityRewardGrid:SetRewardGridRectAnchoredPosition3D(adjustPosition)
    local rectTransform = self.Transform:GetComponent("RectTransform")
    rectTransform.anchoredPosition3D = adjustPosition
end

return XUiLivWarmActivityRewardGrid