local XUiPanelHome = XClass(nil, "XUiPanelHome")

function XUiPanelHome:Ctor(ui)
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.Node = nil
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnPlayer, self.OnBtnPlayerClicked)
end

function XUiPanelHome:SetData(node)
    self.Node = node
    self.TxtName.text = node:GetName()
    self.BtnPlayer:SetNameByGroup(1, node:GetMemberCount())
    self.RImgIcon:SetRawImage(node:GetShowMonsterIcon())
    self.TxtHP.text = node:GetPercentageHP()
    self.PrograssHP.fillAmount = node:GetHP() / node:GetMaxHP()
    local buffData = node:GetFightEventDetailConfig()
    if buffData == nil then return end 
    -- self.RImgBuffIcon:SetRawImage(buffData.Icon)
    self.TxtBuffName.text = buffData.Name
    self.TxtBuffDetails.text = buffData.Description
end

function XUiPanelHome:OnBtnHelpClicked()
    XLuaUiManager.Open("UiGuildWarStageTips", self.Node)
end

function XUiPanelHome:OnBtnPlayerClicked()
    self.GuildWarManager.RequestRanking(XGuildWarConfig.RankingType.NodeStay, self.Node:GetUID()
    , function(rankList, myRankInfo)
        XLuaUiManager.Open("UiGuildWarStageRank", rankList, myRankInfo, XGuildWarConfig.RankingType.NodeStay, self.Node:GetUID(), self.Node)
    end)
end

return XUiPanelHome
