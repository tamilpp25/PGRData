local XUiRiftPluginAdditonGrid = XClass(nil, "XUiRiftPluginAdditonGrid")

function XUiRiftPluginAdditonGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.Btn.CallBack = function ()
        self:OnBtnClick()
    end
end

function XUiRiftPluginAdditonGrid:OnBtnClick()
    if self.OnClickCb then
        self.OnClickCb()
    end
end

function XUiRiftPluginAdditonGrid:InitClickCb(OnClickCb)
    self.OnClickCb = OnClickCb
end

function XUiRiftPluginAdditonGrid:Refresh(xPlugin, index)
    self.XPlugin = xPlugin
    self.Index = index
    self.RImgIcon:SetRawImage(xPlugin:GetIcon())
    local qualityImage, qualityImageBg = xPlugin:GetQualityImage()
    self.ImgQuality:SetSprite(qualityImage)
    self.ImgQualityBg:SetSprite(qualityImageBg)

    self.TxtCoreName.text = xPlugin:GetName()
    self.TxtLoad.text = CS.XTextManager.GetText("RiftLoad", xPlugin.Config.Load)

    -- 补正属性
    local attrList = xPlugin:GetAttrFixTypeList()
    self.TxtAttr1.text = attrList[1]
    self.TxtAttr2.text = attrList[2]

    -- 补正效果
    local attrFixList = xPlugin:GetEffectStringList()
    for i = 1, 2 do
        local isShow = #attrFixList >= i
        self["PanelEntry" .. i].gameObject:SetActiveEx(isShow)
        if isShow then
            local attrFix = attrFixList[i]
            self["TxtEntry" .. i].text = attrFix.Name
            self["TxtEntryNum" .. i].text = attrFix.ValueString
        end
    end
end

return XUiRiftPluginAdditonGrid
