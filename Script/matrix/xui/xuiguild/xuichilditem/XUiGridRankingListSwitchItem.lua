local XUiGridRankingListSwitchItem = XClass(nil, "XUiGridRankingListSwitchItem")

function XUiGridRankingListSwitchItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridRankingListSwitchItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

-- 更新数据
function XUiGridRankingListSwitchItem:OnRefresh(itemdata, index)
    if not itemdata then
        return
    end

    self.TxtPlayerName.text = itemdata.GuildName
    -- TxtLastLanding 是列表里的【成员数】
    self.TxtLastLanding.text = itemdata.MemberCount
    self.TxtRankNum.text = index
    self.TxtSevenDay.text = itemdata.Score
    self.TxtTitleScore.text = XGuildConfig.GuildSortName[itemdata.Type]

    local config = XGuildConfig.GetGuildHeadPortraitById(itemdata.IconId)
    if config then
        local isHasGuildRankBgIcon = not string.IsNilOrEmpty(config.GuildRankBgIcon)
        self.HeadBgNormal.gameObject:SetActiveEx(not isHasGuildRankBgIcon)
        self.HeadBgSpecific.gameObject:SetActiveEx(isHasGuildRankBgIcon)
        if isHasGuildRankBgIcon then
            self.HeadBgSpecific:SetSprite(config.GuildRankBgIcon)
        end
        self.ImgHead:SetRawImage(config.Icon)
    end
    self:SetSelect(itemdata.IsSelect)
end

function XUiGridRankingListSwitchItem:SetSelect(status)
    self.Btn:SetButtonState(status and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

return XUiGridRankingListSwitchItem