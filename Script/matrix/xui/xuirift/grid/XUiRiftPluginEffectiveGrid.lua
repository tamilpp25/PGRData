local XUiRiftPluginEffectiveGrid = XClass(nil, "XUiRiftPluginEffectiveGrid")

function XUiRiftPluginEffectiveGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.Btn.CallBack = function ()
        self:OnBtnClick()
    end
end

function XUiRiftPluginEffectiveGrid:OnBtnClick()
    if self.OnClickCb then
        self.OnClickCb()
    end
end

function XUiRiftPluginEffectiveGrid:InitClickCb(OnClickCb)
    self.OnClickCb = OnClickCb
end

function XUiRiftPluginEffectiveGrid:Refresh(xPlugin, index)
    self.XPlugin = xPlugin
    self.Index = index
    self.RImgIcon:SetRawImage(xPlugin:GetIcon())
    local qualityImage, qualityImageBg = xPlugin:GetQualityImage()
    self.ImgQuality:SetSprite(qualityImage)
    self.ImgQualityBg:SetSprite(qualityImageBg)
    self.TxtPluginName.text = xPlugin:GetName()
    self.TxtLoad.text = CS.XTextManager.GetText("RiftLoad", xPlugin.Config.Load)
    self.TxtPluginEffective.text = xPlugin:GetDesc()
end

return XUiRiftPluginEffectiveGrid
