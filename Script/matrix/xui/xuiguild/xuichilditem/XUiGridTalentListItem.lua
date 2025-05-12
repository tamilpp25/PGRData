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
    local index = #self.TalentConfig.Descriptions
    local desc = XGuildConfig.GetGuildTalentText(self.TalentConfig.Descriptions[index])
    local params = self.TalentConfig.DescriptionParams[index]
    self.TxtTalentDes.text = XUiHelper.FormatTextWithSplit(desc, params)
    self.RImgTalent:SetRawImage(self.TalentConfig.TalentIcon)
end

return XUiGridTalentListItem
