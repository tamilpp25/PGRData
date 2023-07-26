--工会boss排行榜中的grid
local XUiGuildBossTeamList = require("XUi/XUiGuildBoss/Component/XUiGuildBossTeamList")
local XUiGuildBossRankItem = XClass(nil, "XUiGuildBossRankItem")

function XUiGuildBossRankItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnDetail.CallBack = function() self:OnBtnDetailClick() end
end

function XUiGuildBossRankItem:Init(data, rank)
    self.Id = data.Id
    self.TxtScore.text = data.Score
    self.TxtName.text = data.Name
    self.TxtRank.text = rank
    if self.Team == nil then
        self.Team = XUiGuildBossTeamList.New(self.TeamObj)
    end
    XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.UObjHead)
    self.TxtRankName.text = XDataCenter.GuildManager.GetRankNameByLevel(data.RankLevel)
    self.Team:Init(data.CardIds, data.CharacterHeadInfoList, false)
end

function XUiGuildBossRankItem:OnBtnDetailClick()
    if self.Id ~= XPlayer.Id then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Id)
    end
end

return XUiGuildBossRankItem