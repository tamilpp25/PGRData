local XUiGridTalentListItem = XClass(nil, "XUiGridTalentListItem")

function XUiGridTalentListItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
end

function XUiGridTalentListItem:Refresh(talentConfig)
    self.TalentData = talentConfig
    self.TalentConfig = XGuildConfig.GetGuildTalentConfigById(talentConfig.Id)
    self.TxtTalentName.text = self.TalentConfig.Name
    self.TxtTalentDes.text = self.TalentConfig.Descriptions[#self.TalentConfig.Descriptions]
    self.RImgTalent:SetRawImage(self.TalentConfig.TalentIcon)
end

return XUiGridTalentListItem