XUiGridSkillItemOther = XClass(nil, "XUiGridSkillItemOther")

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
    self.TxtTotalPoint = XUiHelper.TryGetComponent(self.Transform, "TxtTotalPoint", "Text")
    self.RImgSkillIcon = XUiHelper.TryGetComponent(self.Transform, "RImgSkillIcon", "RawImage")
    self.BtnIconBg = XUiHelper.TryGetComponent(self.Transform, "BtnIconBg", "Button")

    self.PanelIconTip = XUiHelper.TryGetComponent(self.Transform, "PanelIconTip", nil)
    self.PanelLock = XUiHelper.TryGetComponent(self.Transform, "PanelIconTip/PanelLock", nil)
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
    self.RImgSkillIcon:SetRawImage(skill.Icon)

    self.PanelLock.gameObject:SetActive(false)
    self.ImgUpgradeTip.gameObject:SetActive(false)
    if (skill.TotalLevel <= 0) then
        self.PanelLock.gameObject:SetActive(true)
    end

    local addLevel = 0
    local npcData = {Character = self.Character,Equips = self.EquipList}

    for _, skillId in pairs(skill.SkillIdList) do
        local resonanceSkillLevelMap = XMagicSkillManager.GetResonanceSkillLevelMap(npcData)
        local resonanceSkillLevel = resonanceSkillLevelMap[skillId] or 0

        addLevel = addLevel + resonanceSkillLevel + XDataCenter.FubenAssignManager.GetSkillLevelByCharacterData(self.Character, skillId, self.AssignChapterRecords)
    end

    if addLevel > 0 then
        self.TxtTotalPoint.text = CS.XTextManager.GetText("CharacterResonanceSkillDes", skill.TotalLevel, addLevel)
    else
        self.TxtTotalPoint.text = CS.XTextManager.GetText("HostelDeviceLevel") .. ':' .. skill.TotalLevel
    end
end