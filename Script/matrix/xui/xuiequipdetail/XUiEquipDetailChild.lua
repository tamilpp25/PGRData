local CsXTextManager = CS.XTextManager

local MAX_AWARENESS_ATTR_COUNT = 2 --不包括共鸣属性，最大有2条
local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
local XUiEquipOverrunDetail = require("XUi/XUiEquipOverrun/XUiEquipOverrunDetail")

local XUiEquipDetailChild = XLuaUiManager.Register(XLuaUi, "UiEquipDetailChild")

XUiEquipDetailChild.BtnTabIndex = {
    SuitSkill = 1,
    ResonanceSkill = 2,
    Overrun = 3,
}

function XUiEquipDetailChild:OnAwake()
    self:AutoAddListener()

    local tabGroupList = {
        self.BtnSuitSkill,
        self.BtnResonanceSkill,
        self.BtnEquipOverrun,
    }
    self.TabGroupRight:Init(tabGroupList, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    self.CurTabIndex = XUiEquipDetailChild.BtnTabIndex.SuitSkill
end

function XUiEquipDetailChild:OnStart(equipId, isPreview, openUiType)
    self.IsPreview = isPreview
    self.EquipId = equipId
    self.TemplateId = isPreview and self.EquipId or XDataCenter.EquipManager.GetEquipTemplateId(equipId)
    self.GridResonanceSkills = {}
    self.OpenUiType = openUiType

    self:InitTabBtns()
    self:InitClassifyPanel()
    self:InitEquipInfo()
end

function XUiEquipDetailChild:OnEnable()
    self:UpdateEquipAttr()
    self:UpdateEquipLevel()
    self:UpdateEquipBreakThrough()
    self:UpdateEquipLock()
    self:UpdateEquipRecycle()
    self:OnClickTabCallBack(self.CurTabIndex)
end

function XUiEquipDetailChild:RefreshData(equipId,isPreview)
    self.EquipId = equipId
    self.TemplateId = isPreview and self.EquipId or XDataCenter.EquipManager.GetEquipTemplateId(equipId)
    self:InitClassifyPanel()
    self:InitEquipInfo()
    self:OnEnable()
end

function XUiEquipDetailChild:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY
        , XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY
        , XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY
    }
end

function XUiEquipDetailChild:OnNotify(evt, ...)
    local args = { ... }
    local equipId = args[1]
    if self.IsPreview or equipId ~= self.EquipId then return end

    if evt == XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY then
        self:UpdateEquipLevel()
        self:UpdateEquipAttr()
    elseif evt == XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY then
        self:UpdateEquipLock()
        self:UpdateEquipRecycle()
    elseif evt == XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY then
        self:UpdateEquipRecycle()
    elseif evt == XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY then
        self:UpdateEquipBreakThrough()
    end
end

function XUiEquipDetailChild:OnClickTabCallBack(tabIndex)
    self.CurTabIndex = tabIndex
    if tabIndex == XUiEquipDetailChild.BtnTabIndex.SuitSkill then
        self.PanelSuitSkill.gameObject:SetActive(true)
        self.PanelResonanceSkill.gameObject:SetActive(false)
        self:UpdateEquipSkillDes()
        self:PlayAnimation("SuitSkill")
    elseif tabIndex == XUiEquipDetailChild.BtnTabIndex.ResonanceSkill then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipResonance) then
            return
        end
        self.PanelSuitSkill.gameObject:SetActive(false)
        self.PanelResonanceSkill.gameObject:SetActive(true)
        self:UpdateResonanceSkills()
        self:PlayAnimation("SuitSkill")
    elseif tabIndex == XUiEquipDetailChild.BtnTabIndex.Overrun then
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then 
            local tips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.EquipOverrun)
            XUiManager.TipError(tips)
            return
        end
        self.PanelSuitSkill.gameObject:SetActive(true)
        self.PanelResonanceSkill.gameObject:SetActive(false)
        self:PlayAnimation("SuitSkill")
        self:UpdateOverrun()
    end
end

function XUiEquipDetailChild:InitTabBtns()
    local canOverrun = XEquipConfig.CanOverrunByTemplateId(self.TemplateId) and not self.IsPreview
    self.BtnEquipOverrun.gameObject:SetActiveEx(canOverrun)
    if canOverrun then
        self.BtnEquipOverrun:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun))
    end

    if not XDataCenter.EquipManager.CanResonanceByTemplateId(self.TemplateId) or (self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI) then
        self.BtnResonanceSkill.gameObject:SetActive(false)
        self.BtnSuitSkill.gameObject:SetActive(false)
        return
    end

    self.BtnResonanceSkill:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipResonance))
    self.TabGroupRight:SelectIndex(XUiEquipDetailChild.BtnTabIndex.SuitSkill)
end

function XUiEquipDetailChild:InitClassifyPanel()
    if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon) then
        self.TxtTitle.text = CsXTextManager.GetText("WeaponDetailTitle")
        self.PanelPainter.gameObject:SetActive(false)
    else
        local breakthroughTimes = not self.IsPreview and XDataCenter.EquipManager.GetBreakthroughTimes(self.EquipId) or 0
        self.TxtPainter.text = XDataCenter.EquipManager.GetEquipPainterName(self.TemplateId, breakthroughTimes)
        self.PanelPainter.gameObject:SetActive(true)
        self.TxtTitle.text = CsXTextManager.GetText("AwarenessDetailTitle")
    end
end

function XUiEquipDetailChild:UpdateEquipSkillDes()
    self.PanelEquipOverrun.gameObject:SetActive(false)
    if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon) then
        local weaponSkillInfo = XDataCenter.EquipManager.GetOriginWeaponSkillInfo(self.TemplateId)
        local noWeaponSkill = not weaponSkillInfo.Name and not weaponSkillInfo.Description

        self.TxtSkillName.text = weaponSkillInfo.Name
        self.TxtSkillDes.text = weaponSkillInfo.Description

        self.PanelAwarenessSkillDes.gameObject:SetActive(false)
        self.PanelNoAwarenessSkill.gameObject:SetActive(false)
        self.PanelWeaponSkillDes.gameObject:SetActive(not noWeaponSkill)
        self.PanelNoWeaponSkill.gameObject:SetActive(noWeaponSkill)
    elseif XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Awareness) then
        local suitId = XDataCenter.EquipManager.GetSuitIdByTemplateId(self.TemplateId)
        local skillDesList = XDataCenter.EquipManager.GetSuitSkillDesList(suitId)

        local noSuitSkill = true
        for i = 1, XEquipConfig.MAX_SUIT_SKILL_COUNT do
            if skillDesList[i * 2] then
                self["TxtSkillDes" .. i].text = skillDesList[i * 2]
                self["TxtSkillDes" .. i].gameObject:SetActive(true)
                noSuitSkill = false
            else
                self["TxtSkillDes" .. i].gameObject:SetActive(false)
            end
        end

        self.PanelNoAwarenessSkill.gameObject:SetActive(noSuitSkill)
        self.PanelAwarenessSkillDes.gameObject:SetActive(not noSuitSkill)
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelAwarenessSkillDes:FindTransform("PaneContent"))
        self.PanelWeaponSkillDes.gameObject:SetActive(false)
        self.PanelNoWeaponSkill.gameObject:SetActive(false)
    end
end

function XUiEquipDetailChild:UpdateEquipLock()
    if self.IsPreview then
        self.BtnUnlock.gameObject:SetActive(false)
        self.BtnLock.gameObject:SetActive(false)
        return
    end

    local isLock = XDataCenter.EquipManager.IsLock(self.EquipId)
    self.BtnUnlock.gameObject:SetActive(not isLock)
    self.BtnLock.gameObject:SetActive(isLock)
end

function XUiEquipDetailChild:UpdateEquipRecycle()
    if self.IsPreview then
        self.BtnLaJi.gameObject:SetActive(false)
        self.BtnUnLaJi.gameObject:SetActive(false)
        return
    end

    local isCanRecycle = XDataCenter.EquipManager.IsEquipCanRecycle(self.EquipId)
    local isRecycle = XDataCenter.EquipManager.IsRecycle(self.EquipId)
    self.BtnLaJi.gameObject:SetActiveEx(isCanRecycle and isRecycle)
    self.BtnUnLaJi.gameObject:SetActiveEx(isCanRecycle and not isRecycle)
end

function XUiEquipDetailChild:UpdateEquipLevel()
    local level, levelLimit
    local equipId = self.EquipId

    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        local character = XDataCenter.NieRManager.GetSelNieRCharacter()
        level = character:GetNieRWeaponLevel()
        local equipSite = XDataCenter.EquipManager.GetEquipSiteByTemplateId(self.TemplateId)
        local breakTimes = character:GetNieRWeaponBreakThrough()
        if equipSite and equipSite ~= XEquipConfig.EquipSite.Weapon then
            level = character:GetNieRWaferLevel(equipId)
            breakTimes = character:GetNieRWaferBreakThroughById(equipId)
        end
        levelLimit = XDataCenter.EquipManager.GetBreakthroughLevelLimitByTemplateId(self.TemplateId, breakTimes)
        self.PanelMaxLevel.gameObject:SetActive(XDataCenter.EquipManager.IsMaxLevelByTemplateId(self.TemplateId, breakTimes, level) and not XDataCenter.EquipManager.CanBreakThroughByTemplateId(equipId, breakTimes, level))
    elseif self.IsPreview then
        level = 1
        levelLimit = XDataCenter.EquipManager.GetBreakthroughLevelLimitByTemplateId(self.TemplateId)
        self.PanelMaxLevel.gameObject:SetActive(false)
    else
        local equip = XDataCenter.EquipManager.GetEquip(equipId)
        level = equip.Level
        levelLimit = XDataCenter.EquipManager.GetBreakthroughLevelLimit(equipId)
        self.PanelMaxLevel.gameObject:SetActive(XDataCenter.EquipManager.IsMaxLevel(equipId) and not XDataCenter.EquipManager.CanBreakThrough(equipId))
    end

    if level and levelLimit then
        self.TxtLevel.text = CsXTextManager.GetText("EquipLevelText", level, levelLimit)
    end
end

function XUiEquipDetailChild:UpdateEquipBreakThrough()
    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        local character = XDataCenter.NieRManager.GetSelNieRCharacter()
        local equipSite = XDataCenter.EquipManager.GetEquipSiteByTemplateId(self.TemplateId)
        local breakTimes = character:GetNieRWeaponBreakThrough()
        if equipSite and equipSite ~= XEquipConfig.EquipSite.Weapon then
            breakTimes = character:GetNieRWaferBreakThroughById(self.EquipId)
        end
        self:SetUiSprite(self.ImgBreakThrough, XEquipConfig.GetEquipBreakThroughIcon(breakTimes))
        return
    elseif self.IsPreview then
        self:SetUiSprite(self.ImgBreakThrough, XEquipConfig.GetEquipBreakThroughIcon(0))
        return
    end

    self:SetUiSprite(self.ImgBreakThrough, XDataCenter.EquipManager.GetEquipBreakThroughIcon(self.EquipId))
end

function XUiEquipDetailChild:InitEquipInfo()
    local star = XDataCenter.EquipManager.GetEquipStar(self.TemplateId)
    for i = 1, XEquipConfig.MAX_STAR_COUNT do
        if i <= star then
            self["ImgStar" .. i].gameObject:SetActive(true)
        else
            self["ImgStar" .. i].gameObject:SetActive(false)
        end
    end

    self.TxtEquipName.text = XDataCenter.EquipManager.GetEquipName(self.TemplateId)

    local equipSite = XDataCenter.EquipManager.GetEquipSiteByTemplateId(self.TemplateId)
    if equipSite ~= XEquipConfig.EquipSite.Weapon then
        local breakthrough = 0
        if not self.IsPreview then
            local equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
            breakthrough = equip.Breakthrough
        end
        self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconBagPath(self.TemplateId, breakthrough))
        self.TxtPos.text = "0" .. equipSite
        self.PanelPos.gameObject:SetActive(true)
        self.RImgType.gameObject:SetActive(false)
    else
        self.RImgType:SetRawImage(XEquipConfig.GetWeaponTypeIconPath(self.TemplateId))
        self.RImgType.gameObject:SetActive(true)
        self.PanelPos.gameObject:SetActive(false)
    end

    local equipSpecialCharacterId = XDataCenter.EquipManager.GetEquipSpecialCharacterIdByTemplateId(self.TemplateId)
    if equipSpecialCharacterId then
        self.RImgHead:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(equipSpecialCharacterId))
        self.PanelSpecialCharacter.gameObject:SetActive(true)
    else
        self.PanelSpecialCharacter.gameObject:SetActive(false)
    end
end

function XUiEquipDetailChild:UpdateEquipAttr()
    local attrMap
    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        local equipLevel = XDataCenter.NieRManager.GetSelNieRCharacter():GetNieRWeaponLevel()
        local equipSite = XDataCenter.EquipManager.GetEquipSiteByTemplateId(self.TemplateId)
        if equipSite and equipSite ~= XEquipConfig.EquipSite.Weapon then
            equipLevel = XDataCenter.NieRManager.GetSelNieRCharacter():GetNieRWaferLevel(self.EquipId)
        end
        attrMap = XDataCenter.EquipManager.GetTemplateEquipAttrMap(self.EquipId, equipLevel)
    elseif self.IsPreview then
        attrMap = XDataCenter.EquipManager.GetTemplateEquipAttrMap(self.EquipId)
    else
        attrMap = XDataCenter.EquipManager.GetEquipAttrMap(self.EquipId)
    end

    local attrCount = 1
    for _, attrInfo in pairs(attrMap) do
        if attrCount > MAX_AWARENESS_ATTR_COUNT then break end
        self["TxtName" .. attrCount].text = attrInfo.Name
        self["TxtAttr" .. attrCount].text = attrInfo.Value
        self["PanelAttr" .. attrCount].gameObject:SetActive(true)
        attrCount = attrCount + 1
    end
    for i = attrCount, MAX_AWARENESS_ATTR_COUNT do
        self["PanelAttr" .. i].gameObject:SetActive(false)
    end
end

function XUiEquipDetailChild:UpdateResonanceSkills()
    local count = 1
    local resonanceSkillNum = XDataCenter.EquipManager.GetResonanceSkillNumByTemplateId(self.TemplateId)
    for pos = 1, resonanceSkillNum do
        self["PanelSkill" .. pos].gameObject:SetActive(true)
        self["PanelEmptySkill" .. pos].gameObject:SetActive(true)
        count = count + 1
        self:UpdateResonanceSkill(pos)
    end
    for pos = count, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
        self["PanelSkill" .. pos].gameObject:SetActive(false)
    end
end

function XUiEquipDetailChild:UpdateResonanceSkill(pos)
    if self.IsPreview then return end
    local grid = self.GridResonanceSkills[pos]
    if XDataCenter.EquipManager.CheckEquipPosResonanced(self.EquipId, pos) then
        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(self.GridResonanceSkill)
            grid = XUiGridResonanceSkill.New(item, self.EquipId, pos)
            grid.Transform:SetParent(self["PanelSkill" .. pos], false)
            self.GridResonanceSkills[pos] = grid
        end
        grid:SetEquipIdAndPos(self.EquipId, pos)
        grid:Refresh()
        grid.GameObject:SetActive(true)
        self["PanelEmptySkill" .. pos].gameObject:SetActive(false)
    else
        if grid then
            grid.GameObject:SetActive(false)
        end
    end
end

function XUiEquipDetailChild:UpdateOverrun()
    self.PanelWeaponSkillDes.gameObject:SetActive(false)
    self.PanelEquipOverrun.gameObject:SetActive(true)
    if not self.UiEquipOverrunDetail then
        self.UiEquipOverrunDetail = XUiEquipOverrunDetail.New(self, self.OverrunDetail)
        self.UiEquipOverrunDetail:SetEquipId(self.EquipId)
    else
        self.UiEquipOverrunDetail:Refresh()
    end
end

function XUiEquipDetailChild:AutoAddListener()
    self:RegisterClickEvent(self.BtnLock, self.OnBtnLockClick)
    self:RegisterClickEvent(self.BtnUnlock, self.OnBtnUnlockClick)
    self:RegisterClickEvent(self.BtnLaJi, self.OnBtnLaJiClick)
    self:RegisterClickEvent(self.BtnUnLaJi, self.OnBtnBtnUnLaJiClick)
end

function XUiEquipDetailChild:OnBtnLockClick()
    XDataCenter.EquipManager.SetLock(self.EquipId, false)
end

function XUiEquipDetailChild:OnBtnUnlockClick()
    XDataCenter.EquipManager.SetLock(self.EquipId, true)
end

function XUiEquipDetailChild:OnBtnLaJiClick()
    XDataCenter.EquipManager.EquipUpdateRecycleRequest(self.EquipId, false)
end

function XUiEquipDetailChild:OnBtnBtnUnLaJiClick()
    XDataCenter.EquipManager.EquipUpdateRecycleRequest(self.EquipId, true)
end