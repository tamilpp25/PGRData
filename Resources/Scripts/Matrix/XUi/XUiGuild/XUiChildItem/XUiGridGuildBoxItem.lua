XUiGridGuildBoxItem = XClass(nil, "XUiGridGuildBoxItem")

function XUiGridGuildBoxItem:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.BtnActive.CallBack = function() self:OnBtnActiveClick() end
end

function XUiGridGuildBoxItem:RefreshGift(giftTemplate, index, maxContribute)
    self.GiftTemplate = giftTemplate
    self.Index = index

    self.TxtValue.text = giftTemplate.GiftContribute
    local totalLength = self.Transform.parent.rect.width
    local localposition = self.Transform.localPosition
    local adjustX = totalLength * giftTemplate.GiftContribute / maxContribute
    self.Transform.localPosition = CS.UnityEngine.Vector3(adjustX - totalLength / 2, localposition.y, localposition.z)

    self.ImgRe.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)

    local lastGuildId = XDataCenter.GuildManager.GetGiftGuildGot()
    local curGuildId = XDataCenter.GuildManager.GetGuildId()

    local giftLevelGots = XDataCenter.GuildManager.GetGiftLevelGot()
    local giftContribute = XDataCenter.GuildManager.GetGiftContribute()
    local giftGuildLevel = XDataCenter.GuildManager.GetGiftGuildLevel()

    if XDataCenter.GuildManager.IsGuildTourist() then
        return
    end

    if lastGuildId > 0 and lastGuildId ~= curGuildId then
        return
    end

    local giftData = XGuildConfig.GetGuildGiftByGuildLevelAndGiftLevel(giftGuildLevel, giftTemplate.GiftLevel)
    if not giftData then
        return
    end

    if giftContribute < giftData.GiftContribute then
        return
    end

    if giftLevelGots[giftTemplate.GiftLevel] then
        self.ImgRe.gameObject:SetActiveEx(true)
        return
    end

    self.PanelEffect.gameObject:SetActiveEx(true)
    
end

function XUiGridGuildBoxItem:OnBtnActiveClick()
    if self.RootUi:ChecKickOut() then return end
    if not self.GiftTemplate then return end

    local lastGuildId = XDataCenter.GuildManager.GetGiftGuildGot()
    local curGuildId = XDataCenter.GuildManager.GetGuildId()

    local giftLevelGots = XDataCenter.GuildManager.GetGiftLevelGot()
    local giftContribute = XDataCenter.GuildManager.GetGiftContribute()
    local giftGuildLevel = XDataCenter.GuildManager.GetGiftGuildLevel()

    -- 游客
    if XDataCenter.GuildManager.IsGuildTourist() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildTourstAccess"))
        return
    end

    -- 本周换过公会
    if lastGuildId > 0 and lastGuildId ~= curGuildId then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildGiftChangeGuildCondition"))
        return
    end

    local giftData = XGuildConfig.GetGuildGiftByGuildLevelAndGiftLevel(giftGuildLevel, self.GiftTemplate.GiftLevel)
    if not giftData then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildGiftMaxLevel"))
        return
    end

    if giftContribute < giftData.GiftContribute then
        XUiManager.OpenUiTipRewardByRewardId(self.GiftTemplate.GiftReward, CS.XTextManager.GetText("DailyActiveRewardTitle"))
        return
    end

    -- 已领取：活显示奖励
    if giftLevelGots[self.GiftTemplate.GiftLevel] then
        XUiManager.OpenUiTipRewardByRewardId(self.GiftTemplate.GiftReward, CS.XTextManager.GetText("DailyActiveRewardTitle"))
        return
    end
    
    XDataCenter.GuildManager.GuildGetGift(self.GiftTemplate.GiftLevel, function()
    end)

end

return XUiGridGuildBoxItem