local XUiRiftPluginGrid = XClass(nil, "UiRiftPluginGrid")

function XUiRiftPluginGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsUiPluginBag = false

    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiRiftPluginGrid:Init(clickCb, isUiPluginBag)
    self.ClickCb = clickCb
    self.IsUiPluginBag = isUiPluginBag
end

function XUiRiftPluginGrid:Refresh(plugin, isSelect)
    self.XPlugin = plugin
    local icon = plugin:GetIcon()
    self.RImgIcon:SetRawImage(icon)
    local qualityImage, qualityImageBg = plugin:GetQualityImage()
    self.ImgQuality:SetSprite(qualityImage)
    self.ImgQualityBg:SetSprite(qualityImageBg)
    self.TxtName.text = plugin:GetName()

    if self.IsUiPluginBag then
        local isHave = plugin:GetHave()
        if not isHave then 
            local icon =  CS.XGame.ClientConfig:GetString("PluginUnlockIcon")
            self.RImgIcon:SetRawImage(icon)
            self.TxtName.text = XUiHelper.GetText("RiftUnlockPluginName")
        end
        self.ImgNormalLock.gameObject:SetActiveEx(not isHave)
        self:RefreshRed()
    end
end

function XUiRiftPluginGrid:ShowSelect(isSelect)
    self.ImgActive.gameObject:SetActiveEx(isSelect)
    if isSelect and self.XPlugin:GetHave() then
        XDataCenter.RiftManager.ClosePluginRed(self.XPlugin:GetId())
        self:RefreshRed()
    end
end

function XUiRiftPluginGrid:SetIsWear(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiRiftPluginGrid:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        if self.ClickCb then
            self:ClickCb(self)
        end
    end
end

function XUiRiftPluginGrid:SetBan(value)
    self.ImgBan.gameObject:SetActiveEx(value)
end

function XUiRiftPluginGrid:RefreshRed()
    local isRed = XDataCenter.RiftManager.IsPluginRed(self.XPlugin:GetId())
    self.BtnClick:ShowReddot(isRed)
end

return XUiRiftPluginGrid
