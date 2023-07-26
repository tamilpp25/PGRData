
local XUiGuildDormGiftGrid = XClass(nil, "XUiGuildDormGiftGrid")

function XUiGuildDormGiftGrid:Ctor(grid)
    XTool.InitUiObjectByUi(self, grid)
    self.RewardPanelList = {}
    self.GridReward.gameObject:SetActiveEx(false)
    self.BtnReceive.CallBack = function() self:OnClickBtnReceive() end
end

function XUiGuildDormGiftGrid:RefreshData(rootUi, data)
    self.GiftLevel = data.GiftLevel
    self.TxtScore.text = data.GiftContribute or 0
    self:RefreshRewards(rootUi, data)
    self.PanelAlreadyGet.gameObject:SetActive(false)
    self.BtnReceive.gameObject:SetActive(true)
    self.BtnReceive:SetButtonState(CS.UiButtonState.Disable)
    local giftContribute = XDataCenter.GuildManager.GetGiftContribute()
    local lastGuildId = XDataCenter.GuildManager.GetGiftGuildGot() --上个领奖品的公会Id
    local curGuildId = XDataCenter.GuildManager.GetGuildId() --现在的公会Id
    local giftLevelGots = XDataCenter.GuildManager.GetGiftLevelGot()
    local giftGuildLevel = XDataCenter.GuildManager.GetGiftGuildLevel()
    local giftData = XGuildConfig.GetGuildGiftByGuildLevelAndGiftLevel(giftGuildLevel, data.GiftLevel)
    if not giftData then
        return
    end
    if giftContribute < giftData.GiftContribute then
        return
    end
    self.IsGet = giftLevelGots[self.GiftLevel]
    self.PanelAlreadyGet.gameObject:SetActive(self.IsGet)
    self.BtnReceive.gameObject:SetActive(not self.IsGet)
    self.CanGet = false
    if lastGuildId > 0 and lastGuildId ~= curGuildId then
        self.CanGet = false
    else
        self.CanGet = giftContribute >= data.GiftContribute
    end
    if not self.CanGet then
        self.BtnReceive:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnReceive:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiGuildDormGiftGrid:RefreshRewards(rootUi, data)
    local rewardId = XDataCenter.GuildManager.GetGuildGiftRewardId(data.Id)
    local rewards = XRewardManager.GetRewardList(rewardId)
    -- reset reward panel
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end

    if not rewards then
        return
    end

    for i = 1, #rewards do
        local panel = self.RewardPanelList[i]
        if not panel then
            local ui = XUiHelper.Instantiate(self.GridReward, self.PanelRewardContent)
            panel = XUiGridCommon.New(rootUi, ui)
            table.insert(self.RewardPanelList, panel)
        end
        panel:Refresh(rewards[i])
    end
end

function XUiGuildDormGiftGrid:OnClickBtnReceive()
    if self.IsGet then
        return
    end

    if self.CanGet then
        XDataCenter.GuildManager.GuildGetGift(self.GiftLevel, function()

            end)
    end
end

return XUiGuildDormGiftGrid