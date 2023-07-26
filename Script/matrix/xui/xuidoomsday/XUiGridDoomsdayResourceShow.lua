local XUiGridDoomsdayResourceShow = XClass(nil, "XUiGridDoomsdayResourceShow")

function XUiGridDoomsdayResourceShow:Refresh(resourceInfo)
    self.RImgIcon:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceInfo.Id, "Icon"))

    if not resourceInfo.Daily then
        self.TxtCount.text = resourceInfo.Count
    else
        self.TxtCount.text = CsXTextManagerGetText("DoomsdayFubenDetailConsumeDaily", resourceInfo.Count)
    end
end

return XUiGridDoomsdayResourceShow
