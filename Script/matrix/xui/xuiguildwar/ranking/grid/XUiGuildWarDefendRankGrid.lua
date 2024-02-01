local XUiGuildWarDefendRankGrid = XClass(nil, 'XUiGuildWarDefendRankGrid')

function XUiGuildWarDefendRankGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self,uiPrefab)
    self._BeforePanel = {}
    XTool.InitUiObjectByUi(self._BeforePanel,self.PanelBefore)
    self.PanelBefore.gameObject:SetActiveEx(true)
    self.PanelStay.gameObject:SetActiveEx(false)
    if self.BtnDetail then
        self.BtnDetail.CallBack = function() self:OnClickBtnDetail() end
    end
end

function XUiGuildWarDefendRankGrid:RefreshData(data, isStay)
    XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)
    self.PlayerId = data.Uid
    self._BeforePanel.TxtPlayerName.text = data.Name
    self._BeforePanel.TxtActiveScore.text = data.Activation
    local memberdata = XDataCenter.GuildManager.GetMemberDataByPlayerId(self.PlayerId) 
    self:UpdateMemberData(memberdata) 
end

function XUiGuildWarDefendRankGrid:OnClickBtnDetail()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerId)
end

function XUiGuildWarDefendRankGrid:UpdateMemberData(memberdata)
    if memberdata == nil then
        self.GameObject:SetActiveEx(false)
        return
    else
        self.GameObject:SetActiveEx(true)
    end
    if memberdata.OnlineFlag == 1 then
        self._BeforePanel.TxtPoint.text = XUiHelper.GetText('GuildMemberOnline')
    else
        self._BeforePanel.TxtPoint.text = XUiHelper.CalcLatelyLoginTime(memberdata.LastLoginTime)
    end

    self._BeforePanel.TxtPlayerLevel.text = XUiHelper.FormatText(XGuildWarConfig.GetClientConfigValues('MemberLevel')[1],memberdata.Level)
    self._BeforePanel.TxtTitled.text = XDataCenter.GuildManager.GetRankNameByLevel(memberdata.RankLevel)
end

return XUiGuildWarDefendRankGrid