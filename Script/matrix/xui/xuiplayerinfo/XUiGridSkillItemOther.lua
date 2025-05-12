local XUiGridSkillItemOther = XClass(nil, "XUiGridSkillItemOther")

function XUiGridSkillItemOther:Ctor(rootUi, ui, skill, character, equipList, assignChapterRecords, cb)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.SkillInfo = skill
    self.EquipList = equipList
    self.Character = character
    self.AssignChapterRecords = assignChapterRecords
    self.ClickCallback = cb
    self:InitAutoScript()

    self:UpdateInfo(self.SkillInfo)
end

function XUiGridSkillItemOther:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridSkillItemOther:AutoInitUi()
    self.RImgSkillIcon = XUiHelper.TryGetComponent(self.Transform, "RImgSkillIcon", "RawImage")
    self.BtnIconBg = XUiHelper.TryGetComponent(self.Transform, "BtnIconBg", "Button")
    self.TxtSkillName = XUiHelper.TryGetComponent(self.Transform, "BtnIconBg/ImgBg/TxtSkillName", "Text")
    self.PanelIconTip = XUiHelper.TryGetComponent(self.Transform, "PanelIconTip", nil)
    self.ImgUpgradeTip = XUiHelper.TryGetComponent(self.Transform, "PanelIconTip/ImgUpgradeTip", "Image")
end

function XUiGridSkillItemOther:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnIconBg, self.OnBtnIconBgClick)
end

function XUiGridSkillItemOther:OnBtnIconBgClick()
    if self.ClickCallback then
        self.ClickCallback()
    end
end

function XUiGridSkillItemOther:UpdateInfo(skill)
    self.TxtSkillName.text = skill.Name
    self.RImgSkillIcon:SetRawImage(skill.Icon)
    self.ImgUpgradeTip.gameObject:SetActive(false)
end

return XUiGridSkillItemOther