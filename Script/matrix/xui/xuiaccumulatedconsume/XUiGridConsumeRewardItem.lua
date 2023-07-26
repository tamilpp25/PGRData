local XUiGridConsumeRewardItem = XClass(nil, "XUiGridConsumeRewardItem")

function XUiGridConsumeRewardItem:Ctor(rootUi, ui, progressId)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ProgressId = progressId
    self:InitView()
end

function XUiGridConsumeRewardItem:InitView()
    ---@type ConsumeDrawActivityEntity
    self.ConsumeDrawActivity = XDataCenter.AccumulatedConsumeManager.GetConsumeDrawActivity()
    -- 抽卡次数
    self.ProgressRequired = self.ConsumeDrawActivity:GetProgressRequiredByProgressId(self.ProgressId)
    self.TxtNumber.text = self.ProgressRequired
    -- 特效
    self.PanelEffect.gameObject:SetActiveEx(false)
    -- 按钮
    self.BtnActive.gameObject:SetActiveEx(true)
    self.BtnActive.CallBack = function()
        self:OnBtnActive()
    end
end

function XUiGridConsumeRewardItem:Refresh(count)
    local isShow = count >= self.ProgressRequired
    if self.Bg1 then
        self.Bg1.gameObject:SetActiveEx(not isShow)
    end
    self.Bg2.gameObject:SetActiveEx(isShow)
    self.ImgRe.gameObject:SetActiveEx(isShow)
end

function XUiGridConsumeRewardItem:OnBtnActive()
    -- 物品
    local progressRewardId = self.ConsumeDrawActivity:GetProgressRewardIdByProgressId(self.ProgressId)
    local rewards = XRewardManager.GetRewardList(progressRewardId)
    XUiManager.OpenUiTipReward(rewards, CS.XTextManager.GetText("DailyActiveRewardTitle"))
end

return XUiGridConsumeRewardItem