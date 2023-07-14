local CSInstantiate = CS.UnityEngine.Object.Instantiate

local XUiExhibitionOverclockingV2P6 = XLuaUiManager.Register(XLuaUi, "UiExhibitionOverclockingV2P6")

function XUiExhibitionOverclockingV2P6:OnAwake()
    self.GridSkill2 = CSInstantiate(self.GridSkill1.gameObject, self.SkillPos2):GetComponent("UiObject")
    self.GridSkill2.transform.localPosition = CS.UnityEngine.Vector3.zero

    self.UiGridSkill1 = {}
    XTool.InitUiObjectByUi(self.UiGridSkill1, self.GridSkill1)
    self.UiGridSkill2 = {}
    XTool.InitUiObjectByUi(self.UiGridSkill2, self.GridSkill2)
    self:SetButtonCallBack()
end

function XUiExhibitionOverclockingV2P6:OnStart(parent, characterId, forceShowBindCharacter)
    self.Parent = parent
    self.CharacterId = characterId
    self.ForceShowBindCharacter = forceShowBindCharacter
end

function XUiExhibitionOverclockingV2P6:OnEnable()
    self.EquipId = self.Parent.EquipId
    self:UpdateView()
end

function XUiExhibitionOverclockingV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.UiGridSkill1.BtnLock, function() self:OnBtnLockClick(1) end)
    self:RegisterClickEvent(self.UiGridSkill1.BtnAwake, function() self:OnBtnAwakeClick(1) end)
    self:RegisterClickEvent(self.UiGridSkill1.BtnAwarenessOccupy, function() self:OnBtnAwarenessOccupyClick(1) end)

    self:RegisterClickEvent(self.UiGridSkill2.BtnLock, function() self:OnBtnLockClick(2) end)
    self:RegisterClickEvent(self.UiGridSkill2.BtnAwake, function() self:OnBtnAwakeClick(2) end)
    self:RegisterClickEvent(self.UiGridSkill2.BtnAwarenessOccupy, function() self:OnBtnAwarenessOccupyClick(2) end)
end

function XUiExhibitionOverclockingV2P6:UpdateView()
    self:RefreshByPos(1)
    self:RefreshByPos(2)
end

function XUiExhibitionOverclockingV2P6:RefreshByPos(pos)
    local Panel = self["UiGridSkill" .. pos]

    local canAwake = XDataCenter.EquipManager.CheckEquipCanAwake(self.EquipId, pos)
    local isAwake = XDataCenter.EquipManager.IsEquipPosAwaken(self.EquipId, pos)
    local characterId = XDataCenter.EquipManager.GetResonanceBindCharacterId(self.EquipId, pos)
    local notActiveResonance = characterId ~= 0 and self.CharacterId ~= characterId
    if self.ForceShowBindCharacter then
        notActiveResonance = false
    end
    local equipSite = XDataCenter.EquipManager.GetEquipSite(self.EquipId)
    local awarenessChapterData = XDataCenter.FubenAwarenessManager.GetChapterDataBySiteNum(equipSite)
    local isOccupy = awarenessChapterData:IsOccupy() and not notActiveResonance
    -- 显隐
    Panel.PanelLock.gameObject:SetActiveEx(not canAwake)
    Panel.PanelInfo.gameObject:SetActiveEx(canAwake)
    Panel.PanelAwarenessOccupy.gameObject:SetActiveEx(isAwake)
    Panel.BtnAwake.gameObject:SetActiveEx(not isAwake and canAwake)
    -- 数据
    if XTool.IsNumberValid(characterId) then
        Panel.RImgHead:SetRawImage(XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(characterId))
    end

    Panel.ImgNotResonance.gameObject:SetActiveEx(notActiveResonance)

    local descList = XDataCenter.EquipManager.GetAwakeSkillDesList(self.EquipId, pos)
    local skillStr = descList[1] .. "\n" .. descList[2]
    Panel.TxtSkillDesActive.text = skillStr
    Panel.TxtSkillDesUnActive.text = skillStr
    Panel.TxtSkillDesActive.gameObject:SetActiveEx(isAwake and not notActiveResonance)
    Panel.TxtSkillDesUnActive.gameObject:SetActiveEx(not isAwake or notActiveResonance)

    local skillInfo = XDataCenter.EquipManager.GetResonanceSkillInfo(self.EquipId, pos)
    Panel.RImgResonanceSkill.gameObject:SetActiveEx(skillInfo.Icon)
    Panel.TxtSkillName.text = skillInfo.Name
    if skillInfo.Icon then
        Panel.RImgResonanceSkill:SetRawImage(skillInfo.Icon)
    end
    Panel.TxtPos.text = "0"..pos

    -- 公约加成
    local harmStr = XDataCenter.EquipManager.GetEquipAwarenessOccupyHarmDesc(self.EquipId, 1)
    Panel.TxtHarmActive.text = harmStr
    Panel.TxtHarmUnActive.text = harmStr
    Panel.ImgHarmActive.gameObject:SetActiveEx(isOccupy)
    Panel.ImgHarmUnActive.gameObject:SetActiveEx(not isOccupy)
end

function XUiExhibitionOverclockingV2P6:OnBtnLockClick(pos)
    XUiManager.TipError(CS.XTextManager.GetText("EquipResonancedLimit"))
    self.Parent:JumpToEquipResonanceSelect(pos)
end

function XUiExhibitionOverclockingV2P6:OnBtnAwakeClick(pos)
    if not XDataCenter.EquipManager.CheckEquipCanAwake(self.EquipId, pos) then
        XUiManager.TipText("EquipCanNotAwakeCondition")
        return
    end

    self.Parent:OpenChildUiResonanceAwake(pos)
end

function XUiExhibitionOverclockingV2P6:OnBtnAwarenessOccupyClick(pos)
    XLuaUiManager.Open("UiAwarenessOccupyPosTips", self.EquipId, pos)
end

return XUiExhibitionOverclockingV2P6
