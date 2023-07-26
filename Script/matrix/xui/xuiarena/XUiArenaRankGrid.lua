local XUiArenaRankGrid = XClass(nil, "XUiArenaRankGrid")
local XUiArenaContributeScore = require("XUi/XUiArena/XUiArenaContributeScore")

function XUiArenaRankGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiArenaRankGrid:AutoAddListener()
    self.BtnHead.CallBack = function() self:OnBtnHeadClick() end
end

function XUiArenaRankGrid:OnBtnHeadClick()
    if self.PlayerInfo.Id == XPlayer.Id then
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerInfo.Id)
end

function XUiArenaRankGrid:Refresh(data)
    local playerInfo = data.PlayerInfo
    self.PlayerInfo = playerInfo
    local challengeCfg = XDataCenter.ArenaManager.GetLastChallengeCfg()
    local contributeScore = XDataCenter.ArenaManager.GetContributeScoreByCfg(data.Rank, challengeCfg, playerInfo.Point)

    self.TxtNickname.text = XDataCenter.SocialManager.GetPlayerRemark(playerInfo.Id, playerInfo.Name)
    XUiPLayerHead.InitPortrait(playerInfo.CurrHeadPortraitId, playerInfo.CurrHeadFrameId, self.Head)

    self.TxtRank.text = "No." .. data.Rank
    self.TxtPoint.text = CS.XTextManager.GetText("ArenaRankPonit", playerInfo.Point)

    if playerInfo.LastPointTime == nil or playerInfo.LastPointTime == 0 then
        self.TxtTime.gameObject:SetActiveEx(false)
    else
        self.TxtTime.gameObject:SetActiveEx(true)
        local timeStr = XTime.TimestampToGameDateTimeString(playerInfo.LastPointTime, "yyyy/MM/dd   HH:mm")
        self.TxtTime.text = CS.XTextManager.GetText("ArenaRankPlayerPointTimeDesc", timeStr)
    end

    local rankNum = XDataCenter.ArenaManager.GetResultFormLocal(playerInfo.Id)
    if not rankNum then
        self.ImgChangeJia.gameObject:SetActiveEx(false)
        self.ImgChangeJian.gameObject:SetActiveEx(false)
        self.ImgChange.gameObject:SetActiveEx(false)
        return
    end

    local score = rankNum - data.Rank
    if score > 0 then
        self.ImgChangeJia.gameObject:SetActiveEx(true)
        self.ImgChangeJian.gameObject:SetActiveEx(false)
        self.ImgChange.gameObject:SetActiveEx(false)
        self.TxtJia.text = score
    elseif score < 0 then
        self.ImgChangeJia.gameObject:SetActiveEx(false)
        self.ImgChangeJian.gameObject:SetActiveEx(true)
        self.ImgChange.gameObject:SetActiveEx(false)
        self.TxtJian.text = math.abs(score)
    else
        self.ImgChangeJia.gameObject:SetActiveEx(false)
        self.ImgChangeJian.gameObject:SetActiveEx(false)
        self.ImgChange.gameObject:SetActiveEx(true)
    end

    XUiArenaContributeScore.Refresh(self.TxtNumber, contributeScore, playerInfo.Point, "FFFFFFFF")
    self.GameObject:SetActive(true)
end

function XUiArenaRankGrid:SetSiblingIndex(siblingIndex)
    self.Transform:SetSiblingIndex(siblingIndex)
end

return XUiArenaRankGrid