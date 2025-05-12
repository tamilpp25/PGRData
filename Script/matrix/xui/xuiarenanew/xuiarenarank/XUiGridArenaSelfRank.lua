---@class XUiGridArenaSelfRank : XUiNode
local XUiGridArenaSelfRank = XClass(XUiNode, "XUiGridArenaSelfRank")

function XUiGridArenaSelfRank:OnStart()
    self._PlayerId = nil
    self._CharacterDetail = nil
    self:_RegisterButtonClicks()
end

function XUiGridArenaSelfRank:OnBtnBattleRoleClick()
    XLuaUiManager.Open("UiArenaBattleRoleTips", self._CharacterDetail)
end

function XUiGridArenaSelfRank:OnBtnHeadClick()
    if not self._PlayerId or self._PlayerId == XPlayer.Id then
        return
    end

    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self._PlayerId)
end

function XUiGridArenaSelfRank:_RegisterButtonClicks()
    XUiHelper.RegisterClickEvent(self, self.BtnBattleRole, self.OnBtnBattleRoleClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnHead, self.OnBtnHeadClick, true)
end

function XUiGridArenaSelfRank:Refresh(data, rank)
    self._PlayerId = data.PlayerId
    self._CharacterDetail = data.CharacterRecords
    
    self.TxtName.text = data.Name
    self.TxtPoint.text = data.Score
    
    if string.IsNilOrEmpty(data.GuildName) then
        self.TxtGuildName.text = XUiHelper.GetText("ArenaNoGuildTips")
    else
        self.TxtGuildName.text = data.GuildName
    end
    
    XUiPlayerHead.InitPortrait(data.Head, data.Frame, self.Head)

    if rank == 1 then
        self.TxtRank.text = XUiHelper.GetText("Rank1Color", rank)
    elseif rank == 2 then
        self.TxtRank.text = XUiHelper.GetText("Rank2Color", rank)
    elseif rank == 3 then
        self.TxtRank.text = XUiHelper.GetText("Rank3Color", rank)
    else
        self.TxtRank.text = XUiHelper.GetText("RankOtherColor", rank)
    end
    if self.ImgTeamBg then
        self.ImgTeamBg.gameObject:SetActiveEx(rank % 2 == 0)
    end
end

return XUiGridArenaSelfRank
