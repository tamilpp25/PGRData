-- V1.29 角色技能优化 该类不在使用 具体使用在 UiSkillDetailsOther
local RESONANCED_GRID_TEXT_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("fee82aff"),
    [false] = XUiHelper.Hexcolor2Color("ffffffff"),
}

XUiGridSubSkillOther = XClass(nil, "XUiGridSubSkillOther")

function XUiGridSubSkillOther:Ctor(ui, index, npcData,assignChapterRecords, callback)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Index = index
    self.NpcaData = npcData
    self.AssignChapterRecords = assignChapterRecords
    self.ClickCallback = callback
    self:InitAutoScript()
    self:SetSelect(false)
    self.PanelIconTip.gameObject:SetActive(true)
    self.ImgUpgrade.gameObject:SetActiveEx(false)
end

function XUiGridSubSkillOther:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiGridSubSkillOther:AutoInitUi()
    self.TxtSubSkillLevel = XUiHelper.TryGetComponent(self.Transform, "ImgLevelBg/TxtSubSkillLevel", "Text")
    self.PanelIconTip = XUiHelper.TryGetComponent(self.Transform, "PanelIconTip", nil)
    self.ImgUpgrade = XUiHelper.TryGetComponent(self.Transform, "PanelIconTip/ImgUpgrade", "Image")
    self.ImgLock = XUiHelper.TryGetComponent(self.Transform, "PanelIconTip/ImgLock")
    self.ImgBgSelected = XUiHelper.TryGetComponent(self.Transform, "ImgBgSelected", "Image")
    self.RImgSubSkillIconSelected = XUiHelper.TryGetComponent(self.Transform, "ImgBgSelected/RImgSubSkillIconSelected", "RawImage")
    self.RImgSubSkillIconNormal = XUiHelper.TryGetComponent(self.Transform, "RImgSubSkillIconNormal", "RawImage")
    self.BtnSubSkillIconBg = XUiHelper.TryGetComponent(self.Transform, "BtnSubSkillIconBg", "Button")
end

function XUiGridSubSkillOther:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnSubSkillIconBg, self.OnBtnSubSkillIconBgClick)
end

function XUiGridSubSkillOther:OnBtnSubSkillIconBgClick()
    if (self.ClickCallback) then
        self.ClickCallback(self.SubSkillInfo, self.Index)
    end
end

function XUiGridSubSkillOther:UpdateGrid(subSkillInfo)
    self.SubSkillInfo = subSkillInfo

    if (subSkillInfo.configDes.Icon and subSkillInfo.configDes.Icon ~= "") then
        self.RImgSubSkillIconNormal:SetRawImage(subSkillInfo.configDes.Icon)
        self.RImgSubSkillIconSelected:SetRawImage(subSkillInfo.configDes.Icon)
    else
        XLog.Warning("sub skill config icon is null. id = " .. subSkillInfo.SubSkillId)
    end

    local addLevel = 0
    local resonanceSkillLevelMap = XMagicSkillManager.GetResonanceSkillLevelMap(self.NpcaData)
    local resonanceSkillLevel = resonanceSkillLevelMap[subSkillInfo.SubSkillId] or 0
    addLevel = addLevel + resonanceSkillLevel + XDataCenter.FubenAssignManager.GetSkillLevelByCharacterData(self.NpcaData.Character, subSkillInfo.SubSkillId, self.AssignChapterRecords)

    local totalLevel = subSkillInfo.Level + addLevel
    local curLevel = totalLevel == 0 and '' or CS.XTextManager.GetText("HostelDeviceLevel") .. ':' .. totalLevel
    self.TxtSubSkillLevel.color = RESONANCED_GRID_TEXT_COLOR[addLevel > 0]
    self.TxtSubSkillLevel.text = curLevel

    local min_max = XCharacterConfigs.GetSubSkillMinMaxLevel(subSkillInfo.SubSkillId)
    if (subSkillInfo.Level >= min_max.Max) then
        self.ImgLock.gameObject:SetActive(false)
    else
        self.ImgLock.gameObject:SetActive(subSkillInfo.Level <= 0)
    end
    self.GameObject:SetActive(true)
end

function XUiGridSubSkillOther:SetSelect(isSelect)
    if (self.ImgBgSelected) then
        self.ImgBgSelected.gameObject:SetActive(isSelect)
    end
end

function XUiGridSubSkillOther:Reset()
    self.SubSkillInfo = nil
    self.GameObject:SetActive(false)
    self:SetSelect(false)
end

function XUiGridSubSkillOther:ResetSelect(subSkillId)
    self:SetSelect(self.SubSkillInfo and self.SubSkillInfo.SubSkillId == subSkillId)
end