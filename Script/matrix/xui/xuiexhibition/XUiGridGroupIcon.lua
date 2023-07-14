local XUiGridGroupIcon = XClass(nil, "XUiGridGroupIcon")

function XUiGridGroupIcon:Ctor(ui, exhibitionCfg)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:RefreshGroupIcon(exhibitionCfg)
    self.BtnGroupInfo.CallBack = function() self:OnBtnGroupInfoClick() end
end

function XUiGridGroupIcon:RefreshGroupIcon()
    self.RImgIcon:SetRawImage(self.ImgPath)
end

function XUiGridGroupIcon:Refresh(exhibitionCfg)
    self.ImgPath = exhibitionCfg and exhibitionCfg.GroupLogo or CS.XGame.ClientConfig:GetString("DefaultGroupExhibitionImagePath")
    self.GroupID = exhibitionCfg and exhibitionCfg.GroupId or 0
	self.ShowType = exhibitionCfg and exhibitionCfg.Type or 1
	self.CanClick = exhibitionCfg and exhibitionCfg.CanClickGroup or 1
    self:RefreshGroupIcon()
end

function XUiGridGroupIcon:OnBtnGroupInfoClick()
	if self.CanClick == 0 then
		XLuaUiManager.Open("UiExhibitionGroupTip", self.GroupID, self.ShowType)
	end
end

return XUiGridGroupIcon