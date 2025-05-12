--工会boss工会排行榜组件
local XUiGuildBossGuildRankItem = XClass(nil, "XUiGuildBossGuildRankItem")

function XUiGuildBossGuildRankItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    if self.BtnInfo then
        self.BtnInfo.CallBack = function() self:OnBtnInfoClick() end
    end
end

function XUiGuildBossGuildRankItem:Init(data, rank)
    self.Id = data.Id
    self.TxtName.text = data.Name
    if rank >= 1 then
        self.TxtRank.text = XUiHelper.GetText("GuildBossRank", math.modf(rank))
    elseif rank == 0 then
        self.TxtRank.text = CS.XTextManager.GetText("GuildBossRankNone")
    else
        local rankNum = 1
        if rank * 100 > 1 then
            rankNum = math.modf(rank * 100)
        end

        self.TxtRank.text = XUiHelper.GetText("GuildBossRank", rankNum .. "%")
    end
    self.TxtScore.text = XUiHelper.GetLargeIntNumText(data.Score)
    local headPortrait = XGuildConfig.GetGuildHeadPortraitById(data.IconId)
    self.ImgIcon:SetRawImage(headPortrait.Icon)
end

function XUiGuildBossGuildRankItem:OnBtnInfoClick()
    XDataCenter.GuildManager.GetVistorGuildDetailsReq(self.Id,function ()
        XLuaUiManager.Open("UiGuildRankingList",self.Id)
    end)
end

return XUiGuildBossGuildRankItem