local XUiGridUnionRankItem = XClass(nil, "XUiGridUnionRankItem")
local XUiGridUnionRankMember = require("XUi/XUiFubenUnionKill/XUiGridUnionRankMember")

local MAX_SPECIAL_NUM = 3
local MAX_MEMBER_NUM = 3

function XUiGridUnionRankItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RankType = XFubenUnionKillConfigs.UnionRankType.KillNumber--by default

    XTool.InitUiObject(self)
    self.TeamMember = {}

    for i = 1, MAX_MEMBER_NUM do
        if not self.TeamMember[i] then
            self.TeamMember[i] = XUiGridUnionRankMember.New(self[string.format("Team%d", i)])
        end
    end
end

function XUiGridUnionRankItem:Init(rootUi, rankType)
    self.RootUi = rootUi
    self.RankType = rankType
end

function XUiGridUnionRankItem:Refresh(rankInfo)
    self.TxtPlayerName.text = XDataCenter.SocialManager.GetPlayerRemark(rankInfo.Id, rankInfo.Name)
    self.TxtRankNormal.text = rankInfo.Rank
    local icon = XFubenBabelTowerConfigs.RankIcon[rankInfo.Rank]

    if rankInfo.Rank <= MAX_SPECIAL_NUM then
        self.RootUi:SetUiSprite(self.ImgRankSpecial, icon)
    end
    self.TxtRankNormal.gameObject:SetActiveEx(rankInfo.Rank > MAX_SPECIAL_NUM)
    self.ImgRankSpecial.gameObject:SetActiveEx(rankInfo.Rank <= MAX_SPECIAL_NUM)

    XUiPlayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
    
    local charLength = 0
    if rankInfo.CharacterInfos then
        charLength = #rankInfo.CharacterInfos
    end
    if self.RankType == XFubenUnionKillConfigs.UnionRankType.KillNumber then
        self.TxtRankScore.text = CS.XTextManager.GetText("UnionBlackFightPoint", rankInfo.Score)
        for i = 1, charLength do
            self.TeamMember[i]:RefreshKillRank(rankInfo.CharacterInfos[i], rankInfo.Id)
        end
    end

    if self.RankType == XFubenUnionKillConfigs.UnionRankType.ThumbsUp then
        self.TxtRankScore.text = CS.XTextManager.GetText("UnionBlackPraiseNum", rankInfo.Score)
        for i = 1, charLength do
            self.TeamMember[i]:RefreshPraiseRank(rankInfo.CharacterInfos[i])
        end
    end
    for i = charLength + 1, MAX_MEMBER_NUM do
        self.TeamMember[i].GameObject:SetActiveEx(false)
    end
end

return XUiGridUnionRankItem