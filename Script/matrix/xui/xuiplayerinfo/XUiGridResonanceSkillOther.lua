local CsXTextManagerGetText = CS.XTextManager.GetText

local XUiGridResonanceSkillOther = XClass(nil, "XUiGridResonanceSkillOther")

local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("188649FF"),
    [false] = XUiHelper.Hexcolor2Color("FF4E4EFF"),
}

function XUiGridResonanceSkillOther:Ctor(ui, equip, pos, fromTip, character, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Equip = equip
    self.EquipId = equip.Id
    self.Pos = pos
    self.FromTip = fromTip
    self.Character = character
    self.ClickCb = clickCb
    self:InitAutoScript()
end

function XUiGridResonanceSkillOther:InitAutoScript()
    self:AutoInitUi()
    XTool.InitUiObject(self)
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

function XUiGridResonanceSkillOther:Refresh()
    local pos = self.Pos
    local isAwakeDes = self.FromTip

    local skillInfo = XMVCA.XEquip:GetResonanceSkillInfoByEquipData(self.Equip, pos)
    local bindCharacterId = XMVCA.XEquip:GetResonanceBindCharacterIdByEquipData(self.Equip, pos)

    if self.PanelBindCharacter and self.RImgHead then
        if not isAwakeDes then
            if bindCharacterId > 0 then
                self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(bindCharacterId))
                self.PanelBindCharacter.gameObject:SetActiveEx(true)
            else
                self.PanelBindCharacter.gameObject:SetActiveEx(false)
            end
        else
            self.PanelBindCharacter.gameObject:SetActiveEx(false)
        end
    end

    if self.TxtPos then
        self.TxtPos.gameObject:SetActiveEx(false)
    end

    if self.RImgResonanceSkill and skillInfo.Icon then
        self.RImgResonanceSkill:SetRawImage(skillInfo.Icon)
    end

    if self.TxtSkillName then
        self.TxtSkillName.text = skillInfo.Name
    end

    if self.TxtSkillDes then
        self.TxtSkillDes.text = skillInfo.Description
        self.TxtSkillDes.gameObject:SetActiveEx(not isAwakeDes)
    end

    local isAwaken = self.Equip:IsEquipPosAwaken(pos)
    if self.PanelAwaken then
        self.PanelAwaken.gameObject:SetActiveEx(isAwaken)
    end

    local notBindResonance = bindCharacterId ~= 0 and self.Character.Id ~= bindCharacterId

    if self.PanelAwakeSkills then
        local awakeSkillDes = XMVCA.XEquip:GetAwakeSkillDesListByEquipData(self.Equip, pos)
        for i = 1, XEnumConst.EQUIP.MAX_AWAKE_COUNT do
            self["TxtAwakeSkill" .. i].text = awakeSkillDes[i]
        end
        self.PanelAwakeSkills.gameObject:SetActiveEx(true)
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

function XUiGridResonanceSkillOther:AutoAddListener()
    if self.BtnClick then
        CsXUiHelper.RegisterClickEvent(self.BtnClick, function()
            self:OnBtnClickClick()
        end)
    end
end

function XUiGridResonanceSkillOther:OnBtnClickClick()
    if self.Equip:IsEquipPosAwaken(self.Pos) then
        if self.ClickCb then
            self.ClickCb()
        end
    end
end

return XUiGridResonanceSkillOther