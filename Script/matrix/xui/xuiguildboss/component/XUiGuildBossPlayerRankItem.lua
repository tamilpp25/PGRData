--工会boss个人排行榜组件
local XUiGuildBossPlayerRankItem = XClass(nil, "XUiGuildBossPlayerRankItem")

function XUiGuildBossPlayerRankItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    if self.BtnInfo then
        self.BtnInfo.CallBack = function() self:OnBtnInfoClick() end
    end
end

function XUiGuildBossPlayerRankItem:Init(data, rank)
    self.Id = data.Id
    self.TxtName.text = data.Name
    if rank == 0 then
        self.TxtRank.text = CS.XTextManager.GetText("GuildBossRankNone")
        self.TxtRankName.text = ""
    else
        self.TxtRank.text = "No." .. rank
        self.TxtRankName.text = XDataCenter.GuildManager.GetRankNameByLevel(data.RankLevel)
    end
    if self.TxtScore then
        self.TxtScore.text = XUiHelper.GetLargeIntNumText(data.Score)
    end
    XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.UObjHead)
    --data.RankLevel 职位
end

function XUiGuildBossPlayerRankItem:OnBtnInfoClick()
    if self.Id ~= XPlayer.Id then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Id)
    end
end

return XUiGuildBossPlayerRankItem