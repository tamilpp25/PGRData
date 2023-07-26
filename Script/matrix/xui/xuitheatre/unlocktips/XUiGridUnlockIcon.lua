local XUiGridUnlockIcon = XClass(nil, "XUiGridUnlockIcon")

function XUiGridUnlockIcon:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
end

function XUiGridUnlockIcon:SetData(data)
    local name = data.Name
    local icon = data.Icon
    if self.TxtName and name then
        self.TxtName.text = name
    end
    if self.RImgIcon and icon then
        if self.RImgIcon:GetComponent("Image") then
            self.RImgIcon:SetSprite(icon)
        else
            self.RImgIcon:SetRawImage(icon)
        end
    end
end

return XUiGridUnlockIcon