---@class XUiBlackRockChessBubbleSkill : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessBubbleSkill = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessBubbleSkill")

function XUiBlackRockChessBubbleSkill:OnAwake()
    self:RegisterClickEvent(self.BtnMask, self.Close)
    self.PanelCd.gameObject:SetActiveEx(false)
end

function XUiBlackRockChessBubbleSkill:OnStart(id, dimObj, showType, alignment, hideCloseBtn)
    if not XTool.IsNumberValid(id) then
        return
    end
    self._DimObj = dimObj.transform
    self._Alignment = alignment or XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_ALIGN.LEFT
    if showType == XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON_SKILL then
        self:ShowWeaponSkill(id)
    elseif showType == XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.CHARACTER_SKILL then
        self:ShowCharacterSkill(id)
    elseif showType == XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON then
        self:ShowWeapon(id)
    elseif showType == XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.CHARACTER then
        self:ShowCharacter(id)
    else
        XLog.Error("BlackRockChess tip error. undefined showtype:" .. showType)
    end

    
    if hideCloseBtn then
        self.BtnMask.gameObject:SetActiveEx(false)
    end
end

function XUiBlackRockChessBubbleSkill:ShowWeaponSkill(skillId)
    self.TxtName.text = self._Control:GetWeaponSkillName(skillId)
    self.TxtDetail.text = self._Control:GetWeaponSkillDesc(skillId)
    self.RImgLegend:SetRawImage(self._Control:GetWeaponSkillMapIcon(skillId))
    local cost = self._Control:GetWeaponSkillCost(0, skillId, true)
    local cd = self._Control:GetWeaponSkillCd(0, skillId, true)
    self.PanelCd.gameObject:SetActiveEx(cd > 0)
    self.TxtCdNum.text = cd
    self.PanelEnergyNum.gameObject:SetActiveEx(cost > 0)
    self.TxtNum.text = cost
    self.Weapon.gameObject:SetActiveEx(true)
    self.Character.gameObject:SetActiveEx(false)
    self:SetPositionByAlign(self.Weapon)
end

function XUiBlackRockChessBubbleSkill:ShowCharacterSkill(buffId)
    local buff = self._Control:GetBuffConfig(buffId)
    self.TxtCharacterName.text = buff.Name
    self.TxtCharacterDetail.text = buff.Desc
    self.Weapon.gameObject:SetActiveEx(false)
    self.Character.gameObject:SetActiveEx(true)
    self:SetPositionByAlign(self.Character)
end

function XUiBlackRockChessBubbleSkill:ShowWeapon(weaponId)
    self.TxtName.text = self._Control:GetWeaponName(weaponId)
    self.TxtDetail.text = self._Control:GetWeaponDesc(weaponId)
    self.RImgLegend:SetRawImage(self._Control:GetWeaponMapIcon(weaponId))
    self.Weapon.gameObject:SetActiveEx(true)
    self.Character.gameObject:SetActiveEx(false)
    self.PanelEnergyNum.gameObject:SetActiveEx(false)
    self:SetPositionByAlign(self.Weapon)
end

function XUiBlackRockChessBubbleSkill:ShowCharacter(roleId)
    local weaponId = self._Control:GetRoleWeaponId(roleId)
    self:ShowWeapon(weaponId)
end

function XUiBlackRockChessBubbleSkill:OnDestroy()
    self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.CLOSE_BUBBLE_SKILL)
end

function XUiBlackRockChessBubbleSkill:SetPositionByAlign(srcDim)
    if not self._DimObj then
        return
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(srcDim.transform)
    -- 超框
    local centerW = srcDim.parent.rect.width / 2
    local centerH = srcDim.parent.rect.height / 2
    local tipW = srcDim.rect.width
    local tipH = srcDim.rect.height
    local minW = tipW - centerW
    local maxW = centerW - tipW
    local minH = tipH - centerH
    local maxH = centerH

    local posX = 0
    local pos = srcDim.parent:InverseTransformPoint(self._DimObj.transform.position)
    if self._Alignment == XEnumConst.THEATRE3.TipAlign.Left then
        srcDim.pivot = Vector2(1, 1)
        posX = pos.x - self._DimObj.rect.width * self._DimObj.localScale.x * self._DimObj.pivot.x
        posX = math.max(posX, minW)
    else
        srcDim.pivot = Vector2(0, 1)
        posX = pos.x + self._DimObj.rect.width * self._DimObj.localScale.x * (1 - self._DimObj.pivot.x)
        posX = math.min(posX, maxW)
    end
    local posY = pos.y + self._DimObj.rect.height * self._DimObj.localScale.y * (1 - self._DimObj.pivot.y)
    posY = math.min(math.max(posY, minH), maxH)

    srcDim.localPosition = Vector3(posX, posY, 0)
end

return XUiBlackRockChessBubbleSkill