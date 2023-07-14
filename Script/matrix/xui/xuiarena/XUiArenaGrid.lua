local XUiArenaGrid = XClass(nil, "XUiArenaGrid")
local XUiArenaContributeScore = require("XUi/XUiArena/XUiArenaContributeScore")

function XUiArenaGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiArenaGrid:AutoAddListener()
    CsXUiHelper.RegisterClickEvent(self.BtnHead, function()
        if self.PlayerInfo.Id == XPlayer.Id then
            return
        else
            XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerInfo.Id)
        end
    end)
end

function XUiArenaGrid:Refresh(index, playerInfo, regionIndex)
    local challengeCfg = XDataCenter.ArenaManager.GetCurChallengeCfg()
    local contributeScore = XDataCenter.ArenaManager.GetContributeScoreByCfg(index, challengeCfg, playerInfo.Point)
    self.PlayerInfo = playerInfo

    local pos = regionIndex % 3
    if pos == 1 then
        self.PanelInfo.localPosition = self.PanelPos1.localPosition
    elseif pos == 2 then
        self.PanelInfo.localPosition = self.PanelPos2.localPosition
    else
        self.PanelInfo.localPosition = self.PanelPos3.localPosition
    end
    self.TxtNickname.text = XDataCenter.SocialManager.GetPlayerRemark(playerInfo.Id, playerInfo.Name)
    XUiPLayerHead.InitPortrait(playerInfo.CurrHeadPortraitId, playerInfo.CurrHeadFrameId, self.Head)
    
    self.TxtRank.text = "No." .. index
    self.TxtPoint.text = playerInfo.Point

    XUiArenaContributeScore.Refresh(self.TxtNumber, contributeScore, playerInfo.Point, "FFFFFFFF")

    self.GameObject:SetActive(true)
end

function XUiArenaGrid:SetSiblingIndex(siblingIndex)
    self.Transform:SetSiblingIndex(siblingIndex)
end

return XUiArenaGrid