local XUiPanelNameplate = XClass(nil, "XUiPanelNameplate")

function XUiPanelNameplate:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)
end

function XUiPanelNameplate:UpdateDataById(id)
    self.PanelGold.gameObject:SetActiveEx(true)
    self.PanelSilver.gameObject:SetActiveEx(false)
    self.PanelCopper.gameObject:SetActiveEx(false)
    if XMedalConfigs.GetNameplateIconType(id) == XMedalConfigs.NameplateShow.ShowIcon then
        self.ImgGold:SetSprite(XMedalConfigs.GetNameplateIcon(id))
        self.TxtGold.gameObject:SetActiveEx(false)
    else
        local icon, title = XMedalConfigs.GetNameplateIcon(id)
        self.ImgGold:SetSprite(icon)
        self.TxtGold.gameObject:SetActiveEx(true)
        self.TxtGold.text = title
        self.TxtGoldOutLine.effectColor = XUiHelper.Hexcolor2Color(XMedalConfigs.GetNameplateOutLineColor(id))
    end

    -- if Quality == XMedalConfigs.NameplateQuality.Copper then
    --     self.PanelGold.gameObject:SetActiveEx(false)
    --     self.PanelSilver.gameObject:SetActiveEx(false)
    --     self.PanelCopper.gameObject:SetActiveEx(true)
    --     --self.ImgCopper:SetSprite("")
    --     self.TxtCopper.text = Title
    -- elseif Quality == XMedalConfigs.NameplateQuality.Silver then
    --     self.PanelGold.gameObject:SetActiveEx(false)
    --     self.PanelSilver.gameObject:SetActiveEx(true)
    --     self.PanelCopper.gameObject:SetActiveEx(false)
    --     --self.ImgSilver:SetSprite("")
    --     self.TxtSilver.text = Title
    -- elseif Quality == XMedalConfigs.NameplateQuality.Gold then
    --     self.PanelGold.gameObject:SetActiveEx(true)
    --     self.PanelSilver.gameObject:SetActiveEx(false)
    --     self.PanelCopper.gameObject:SetActiveEx(false)
    --     --self.ImgGold:SetSprite("")
    --     self.TxtGold.text = Title
    -- end
end

return XUiPanelNameplate