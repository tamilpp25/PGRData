--工会boss关卡上排行榜组件
local XUiGuildBossStageRankItem = XClass(nil, "XUiGuildBossStageRankItem")

function XUiGuildBossStageRankItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    if self.BtnInfo then
        self.BtnInfo.CallBack = function() self:OnBtnInfoClick() end
    end
end

function XUiGuildBossStageRankItem:Init(data, rank)
    self.Id = data.Id
    self.TxtName.text = data.PlayerName
    self.TxtRank.text = "No." .. rank
    XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.UObjHead)
    --data.RankLevel 职位
    self.TxtScore.text = CS.XTextManager.GetText("GuildBossTopPlayerScoreName", XUiHelper.GetLargeIntNumText(data.Score or 0))  
end

function XUiGuildBossStageRankItem:OnBtnInfoClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Id)
end

return XUiGuildBossStageRankItem