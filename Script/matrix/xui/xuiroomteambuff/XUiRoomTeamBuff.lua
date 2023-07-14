local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiRoomTeamBuff = XLuaUiManager.Register(XLuaUi, "UiRoomTeamBuff")

function XUiRoomTeamBuff:OnAwake()
    self:AutoAddListener()
end

function XUiRoomTeamBuff:OnStart(teamBuffId)
    self.RImgOnIcon:SetRawImage(XFubenConfigs.GetTeamBuffOnIcon(teamBuffId))
    self.RImgOffIcon:SetRawImage(XFubenConfigs.GetTeamBuffOffIcon(teamBuffId))
    self.TxtTile.text = XFubenConfigs.GetTeamBuffTitle(teamBuffId)
    self.TxtDesc.text = XFubenConfigs.GetTeamBuffDesc(teamBuffId)
end

function XUiRoomTeamBuff:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnClose.CallBack = function() self:Close() end
end