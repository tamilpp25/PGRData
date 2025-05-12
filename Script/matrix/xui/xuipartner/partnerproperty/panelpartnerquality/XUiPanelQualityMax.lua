local XUiPanelQualityMax = XClass(nil, "XUiPanelQualityMax")

function XUiPanelQualityMax:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    XTool.InitUiObject(self)
end

function XUiPanelQualityMax:UpdatePanel(data)---刷新掉这个
    self.Data = data
    self:UpdatePartnerInfo()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelQualityMax:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelQualityMax:UpdatePartnerInfo()
    local icon = XMVCA.XCharacter:GetCharacterQualityIcon(self.Data:GetQuality())
    self.TxtCount.text = self.Data:GetQualitySkillColumnCount()
    self.RawImageQuality:SetRawImage(icon)
end

return XUiPanelQualityMax