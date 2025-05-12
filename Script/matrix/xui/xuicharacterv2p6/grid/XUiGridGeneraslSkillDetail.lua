local XUiGridGeneralSkillDetail = XClass(XUiNode, 'XUiGridGeneralSkillDetail')

function XUiGridGeneralSkillDetail:OnStart()
    self.BtnTeach.CallBack = handler(self, self.OnTeachBtnClick)
end

function XUiGridGeneralSkillDetail:Refresh(generalSkillCfg, showCurrent)
    if generalSkillCfg then
        self._GeneralSkillId = generalSkillCfg.Id
        self.TxtContent.text = generalSkillCfg.Desc
        self.TxtName.text = generalSkillCfg.Name
        self.RImgIcon:SetRawImage(generalSkillCfg.Icon)
        self.PanelCur.gameObject:SetActiveEx(showCurrent)
    end
end

function XUiGridGeneralSkillDetail:OnTeachBtnClick()
    if XTool.IsNumberValid(self._GeneralSkillId) then
        XDataCenter.PracticeManager.OpenUiFubenPracticeWithGeneralSkill(self._GeneralSkillId)
    end
end

return XUiGridGeneralSkillDetail