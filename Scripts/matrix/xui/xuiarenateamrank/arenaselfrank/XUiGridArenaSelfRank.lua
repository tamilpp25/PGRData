---@class XUiGridArenaSelfRank
local XUiGridArenaSelfRank = XClass(nil, "XUiGridArenaSelfRank")

---@param grid DynamicGrid
function XUiGridArenaSelfRank:Ctor(grid)
    self.Transform = grid.transform
    self.GameObject = grid.gameObject
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self,self.BtnBattleRole,handler(self,self.OnClickBtnTeamDetail))
    CsXUiHelper.RegisterClickEvent(self.BtnHead, function()
        if not self.PlayerId or self.PlayerId == XPlayer.Id then
            return
        end
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerId)
    end, true)
    self.ImgTeamBg = self.Transform:FindTransform("ImgTeamBg")
end

function XUiGridArenaSelfRank:OnClickBtnTeamDetail()
    XLuaUiManager.Open("UiArenaBattleRoleTips", self.CharacterDetail)
end

function XUiGridArenaSelfRank:Refresh(data,rank)
    self.PlayerId = data.PlayerId
    self.TxtName.text = data.Name
    self.TxtPoint.text = data.Score
    self.CharacterDetail = data.CharacterRecords
    if string.IsNilOrEmpty(data.GuildName) then
        self.TxtGuildName.text = CS.XTextManager.GetText("ArenaNoGuildTips")
    else
        self.TxtGuildName.text = data.GuildName
    end
    XUiPLayerHead.InitPortrait(data.Head, data.Frame, self.Head)
    if rank == 1 then
        self.TxtRank.text = CS.XTextManager.GetText("Rank1Color", rank)
    elseif rank == 2 then
        self.TxtRank.text = CS.XTextManager.GetText("Rank2Color", rank)
    elseif rank == 3 then
        self.TxtRank.text = CS.XTextManager.GetText("Rank3Color", rank)
    else
        self.TxtRank.text = CS.XTextManager.GetText("RankOtherColor", rank)
    end
    if self.ImgTeamBg then
        self.ImgTeamBg.gameObject:SetActiveEx(rank % 2 == 0)
    end
end

return XUiGridArenaSelfRank