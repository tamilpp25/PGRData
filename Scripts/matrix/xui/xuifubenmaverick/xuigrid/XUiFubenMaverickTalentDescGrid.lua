local XUiFubenMaverickTalentDescGrid = XClass(nil, "XUiFubenMaverickTalentDescGrid")

function XUiFubenMaverickTalentDescGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiFubenMaverickTalentDescGrid:Refresh(talentId)
    self.TalentId = talentId or self.TalentId
    
    local talentConfig = XDataCenter.MaverickManager.GetTalentConfig(self.TalentId)
    self.RImgSkill:SetRawImage(talentConfig.Icon)
    self.TxtDescribe.text = talentConfig.Intro
end

return XUiFubenMaverickTalentDescGrid