local XUiMoeWarSupportTips = XLuaUiManager.Register(XLuaUi,"UiMoeWarSupportTips")

function XUiMoeWarSupportTips:OnStart(voteCount,playerId)
    self.PlayerId = playerId
    self.VoteCount = voteCount
    self:InitUiView()
    self:RegisterButtonEvent()
end

function XUiMoeWarSupportTips:InitUiView()
    local playerEntity = XDataCenter.MoeWarManager.GetPlayer(self.PlayerId)
    self.TxtAllNumber.text = playerEntity:GetMySupportCount(XDataCenter.MoeWarManager.GetCurMatch():GetSessionId())
    self.TxtOnceNumber.text = self.VoteCount
    self.TxtTalk.text = CS.XTextManager.GetText("MoeWarSupportSuccess",playerEntity:GetName())
    self.RImgRoleIcon:SetRawImage(playerEntity:GetBigCharacterImage())
	if self.ImgAllIcon then
		self.ImgAllIcon:SetRawImage(CS.XGame.ClientConfig:GetString("MoeWarScheduleSupportIcon"))
		self.ImgOnceIcon:SetRawImage(CS.XGame.ClientConfig:GetString("MoeWarScheduleSupportIcon"))
	end
end

function XUiMoeWarSupportTips:OnClickBtnShare()
	XDataCenter.MoeWarManager.RequestShare(self.PlayerId,function()
		XLuaUiManager.Open("UiMoeWarPhotograph", self.PlayerId)	
	end)
end

function XUiMoeWarSupportTips:OnClickBtnSure()
	CS.XGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_PLAY_THANK_ANIMATION,self.PlayerId)
    XLuaUiManager.Close("UiMoeWarSupportTips")
end

function XUiMoeWarSupportTips:RegisterButtonEvent()
    self.BtnConfirm.CallBack = function() self:OnClickBtnSure() end
    self.BtnShare.CallBack = function() self:OnClickBtnShare() end
end

return XUiMoeWarSupportTips