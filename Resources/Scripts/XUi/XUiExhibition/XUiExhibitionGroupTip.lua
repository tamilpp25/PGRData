local XUiExhibitionGroupTip = XLuaUiManager.Register(XLuaUi, "UiExhibitionGroupTip")

function XUiExhibitionGroupTip:OnAwake()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
end

function XUiExhibitionGroupTip:OnStart(groupID, showType)
    self.GroupID = groupID
    self.ShowType = showType
    self:ShowGroupInfo()
end

function XUiExhibitionGroupTip:ShowGroupInfo()
    local config = XExhibitionConfigs.GetExhibitionConfigByTypeAndGroup(self.ShowType, self.GroupID)
    self.TxtGroupName.text = config and config.GroupName or CS.XTextManager.GetText("ExhibitionDefaultGroupName")
    self.RImgGroupIcon:SetRawImage(config and config.GroupLogo or CS.XGame.ClientConfig:GetString("DefaultGroupExhibitionImagePath"))
    self.TxtContent.text = config and config.GroupDescription or CS.XTextManager.GetText("ExhibitionDefaultGroupDescription")
end

function XUiExhibitionGroupTip:OnBtnCloseClick()
    self:Close()
end