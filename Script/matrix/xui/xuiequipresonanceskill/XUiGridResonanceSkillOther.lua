local CsXTextManagerGetText = CS.XTextManager.GetText

local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("188649FF"),
    [false] = XUiHelper.Hexcolor2Color("FF4E4EFF"),
}

local XUiGridResonanceSkillOther = XClass(XUiNode, "XUiGridResonanceSkillOther")

function XUiGridResonanceSkillOther:OnStart(equipId, pos, characterId, clickCb, isAwakeDes, forceShowBindCharacter, isShowPos)
    self.EquipId = equipId
    self.Pos = pos
    self.CharacterId = characterId
    self.ClickCb = clickCb
    self.IsAwakeDes = isAwakeDes
    self.ForceShowBindCharacter = forceShowBindCharacter
    self.IsShowPos = isShowPos
    self:InitAutoScript()
end

function XUiGridResonanceSkillOther:SetEquipIdAndPos(equipData, pos, isAwakeDes)
    self.EquipData = equipData
    self.EquipId = equipData.Id
    self.Pos = pos
    self.IsAwakeDes = isAwakeDes
end

function XUiGridResonanceSkillOther:SetCharacterId(characterId)
    self.CharacterId = characterId
end

function XUiGridResonanceSkillOther:Refresh(skillInfo, bindCharacterId)
    local equipId = self.EquipId
    local pos = self.Pos
    local characterId = self.CharacterId
    local isAwakeDes = self.IsAwakeDes
    skillInfo = skillInfo 
    bindCharacterId = bindCharacterId

    if self.PanelBindCharacter and self.RImgHead then
        if bindCharacterId > 0 then
            self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(bindCharacterId))
            self.PanelBindCharacter.gameObject:SetActiveEx(true)
        else
            self.PanelBindCharacter.gameObject:SetActiveEx(false)
        end
    end

    if self.RImgResonanceSkill and skillInfo.Icon then
        self.RImgResonanceSkill:SetRawImage(skillInfo.Icon)
    end

    if self.TxtSkillName then
        self.TxtSkillName.text = skillInfo.Name
    end

    if self.TxtSkillDes then
        self.TxtSkillDes.text = skillInfo.Description
        self.TxtSkillDes.gameObject:SetActiveEx(not self.IsAwakeDes)
    end

    if self.TxtPos then
        self.TxtPos.text = "0"..tostring(self.Pos)
        self.TxtPos.gameObject:SetActiveEx(self.IsShowPos == true)
    end

    if self.PanelAwakeSkills then
        if isAwakeDes then
            local awakeSkillDes = XDataCenter.EquipManager.GetAwakeSkillDesList(equipId, pos)
            for i = 1, XEquipConfig.AWAKE_SKILL_COUNT do
                self["TxtAwakeSkill" .. i].text = awakeSkillDes[i]
            end
            self.PanelAwakeSkills.gameObject:SetActiveEx(true)
        else
            self.PanelAwakeSkills.gameObject:SetActiveEx(false)
        end
    end

    local notBindResonance = bindCharacterId ~= 0 and characterId ~= bindCharacterId
    if self.ForceShowBindCharacter then
        notBindResonance = false
    end
    local isAwaken = self.EquipData.AwakeSlotListCheck and self.EquipData.AwakeSlotListCheck[pos]
    if self.PanelAwaken then
        self.PanelAwaken.gameObject:SetActiveEx(isAwaken)
    end

    if self.PanelAwakenNotResonance then
        if self.PanelAwaken then
            self.PanelAwaken.gameObject:SetActiveEx(isAwaken and not notBindResonance)
        end
        self.PanelAwakenNotResonance.gameObject:SetActiveEx(isAwaken and notBindResonance)
    end

    if self.ImgNotResonance then
        self.ImgNotResonance.gameObject:SetActiveEx(notBindResonance)
        if self.PanelAwaken then
            self.PanelAwaken.gameObject:SetActiveEx(not notBindResonance and isAwaken)
        end
    end

    if self.TxtAwake then
        if isAwakeDes then
            if bindCharacterId ~= 0 then
                local characterName = XMVCA.XCharacter:GetCharacterTradeName(bindCharacterId)
                self.TxtAwake.text = CsXTextManagerGetText("AwakeCharacterName", characterName)
                self.TxtAwake.color = CONDITION_COLOR[not notBindResonance]
                self.TxtAwake.gameObject:SetActiveEx(true)
            else
                self.TxtAwake.gameObject:SetActiveEx(false)
            end
        else
            self.TxtAwake.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridResonanceSkillOther:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridResonanceSkillOther:AutoInitUi()
    self.TxtSkillDes = XUiHelper.TryGetComponent(self.Transform, "TxtSkillDes", "Text")
    self.TxtSkillName = XUiHelper.TryGetComponent(self.Transform, "TxtSkillName", "Text")
    self.PanelBindCharacter = XUiHelper.TryGetComponent(self.Transform, "PanelBindCharacter", nil)
    self.RImgHead = XUiHelper.TryGetComponent(self.Transform, "PanelBindCharacter/RImgHead", "RawImage")
    self.RImgResonanceSkill = XUiHelper.TryGetComponent(self.Transform, "RImgResonanceSkill", "RawImage")
    self.ImgNotResonance = XUiHelper.TryGetComponent(self.Transform, "ImgNotResonance", "Image")
    self.BtnClick = XUiHelper.TryGetComponent(self.Transform, "BtnClick", "Button")
end

function XUiGridResonanceSkillOther:AutoAddListener()
    CsXUiHelper.RegisterClickEvent(self.BtnClick, function() self:OnBtnClickClick() end)
end

function XUiGridResonanceSkillOther:OnBtnClickClick()
    if self.ClickCb then self.ClickCb(self.EquipId, self.Pos, self.CharacterId) end
end

return XUiGridResonanceSkillOther