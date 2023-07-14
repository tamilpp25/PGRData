--工会boss 奖励按钮组件
local XUiGuildBossRewardItem = XClass(nil, "XUiGuildBossRewardItem")
local Vector2 = CS.UnityEngine.Vector2

function XUiGuildBossRewardItem:Ctor(ui, parentUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ParentUi = parentUi
    XTool.InitUiObject(self)
    self.BtnReward.CallBack = function() self:OnBtnRewardClick() end

    self.EnableIconPath = CS.XGame.ClientConfig:GetString("GuildBossRewardEnableIcon")
    self.DisableIconPath = CS.XGame.ClientConfig:GetString("GuildBossRewardDisableIcon")

    self.ImgProgress.gameObject:SetActiveEx(false)
    self.ProgressRT = self.ImgProgress.transform:GetComponent("RectTransform")
    self.ProgressSize = self.ProgressRT.sizeDelta

    self.MyRewardType = GuildBossRewardType.Disable
end

function XUiGuildBossRewardItem:Init(data, lastScore)
    self.Data = data
    self.MyTotalScore = XDataCenter.GuildBossManager.GetMyTotalScore()
    --是否已领取
    self.IsGet = XDataCenter.GuildBossManager.IsScoreRewardReceive(self.Data.Id)
    self.TxtScore.text = XUiHelper.GetLargeIntNumText(self.Data.Score)
    --三种情况
    --未达到分数要求不能领取
    if self.MyTotalScore < self.Data.Score then
        self.MyRewardType = GuildBossRewardType.Disable
    --达到分数但未领取
    elseif not self.IsGet then
        self.MyRewardType = GuildBossRewardType.Available
    --已领取
    else
        self.MyRewardType = GuildBossRewardType.Acquired
    end
    
    local itemScore = self.MyTotalScore - lastScore
    local gapScore = (self.Data.Score - lastScore)
    local progress = math.min(math.max(0, itemScore / gapScore), 1)
    self.ProgressRT.sizeDelta = Vector2(self.ProgressSize.x, progress * self.ProgressSize.y)
    self.ImgProgress.gameObject:SetActiveEx(true)

    self:UpdateUi()
end

function XUiGuildBossRewardItem:UpdateUi()
    if self.MyRewardType == GuildBossRewardType.Disable then
        self.ImgIcon:SetSprite(self.DisableIconPath)
        self.ImgIsGet.gameObject:SetActiveEx(false)
        self.Red.gameObject:SetActiveEx(false)
    elseif self.MyRewardType == GuildBossRewardType.Available then
        self.ImgIcon:SetSprite(self.EnableIconPath)
        self.ImgIsGet.gameObject:SetActiveEx(false)
        self.Red.gameObject:SetActiveEx(true)
    elseif self.MyRewardType == GuildBossRewardType.Acquired then
        self.ImgIcon:SetSprite(self.DisableIconPath)
        self.ImgIsGet.gameObject:SetActiveEx(true)
        self.Red.gameObject:SetActiveEx(false)
    end
end

function XUiGuildBossRewardItem:OnBtnRewardClick()
    if self.MyRewardType == GuildBossRewardType.Disable then
        self:ShowRewardUi()
    elseif self.MyRewardType == GuildBossRewardType.Available then
        self.ParentUi:OnBtnRewardClick(self.Data)
    elseif self.MyRewardType == GuildBossRewardType.Acquired then
        self:ShowRewardUi()
    end
end

function XUiGuildBossRewardItem:ShowRewardUi()
    local rewardId = XDataCenter.GuildBossManager.GetScoreRewardId(self.Data.Id)
    XUiManager.OpenUiTipRewardByRewardId(rewardId, CS.XTextManager.GetText("DailyActiveRewardTitle"))
end

return XUiGuildBossRewardItem