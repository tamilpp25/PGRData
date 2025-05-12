
---@class XUiPanelBossDetails : XUiNode
---@field _Control XBlackRockChessControl
local XUiPanelBossDetails = XClass(XUiNode, "XUiPanelBubbleSkill")

function XUiPanelBossDetails:OnStart()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiPanelBossDetails:OnEnable()
    self._Control:SetEnemySelect(true)
end

function XUiPanelBossDetails:OnDisable()
    self._Control:SetEnemySelect(false)
end

function XUiPanelBossDetails:OnBtnCloseClick()
    ---@type XChessBoss
    local bossInfo = self._Control:GetChessEnemy():GetBossInfo(self.BossId)
    local imp = bossInfo:GetImp()
    imp.Weapon:OnClick()
end

function XUiPanelBossDetails:RefreshView(bossId, skillId)
    self.BossId = bossId
    self.SkillId = skillId

    -- 名称
    self.TxtName.text = self._Control:GetRoleName(self.BossId)
    -- 血量
    ---@type XChessBoss
    local bossInfo = self._Control:GetChessEnemy():GetBossInfo(self.BossId)
    self.TxtHp.text = tostring(bossInfo:GetHp())

    if self.SkillId then
        self:RefreshSkillDetails(bossInfo)
    else
        self:RefreshMoveDetails(bossInfo)
    end
end

-- 刷新技能详情
---@param bossInfo XChessBoss
function XUiPanelBossDetails:RefreshSkillDetails(bossInfo)
    -- 技能名称
    local isStrengthen = bossInfo:IsInSkillStrengthen(self.SkillId)
    local name = isStrengthen and self._Control:GetWeaponSkillName2(self.SkillId) or self._Control:GetWeaponSkillName(self.SkillId)
    local desc = isStrengthen and self._Control:GetWeaponSkillDesc2(self.SkillId) or self._Control:GetWeaponSkillDesc(self.SkillId)
    local mapIcon = isStrengthen and self._Control:GetWeaponSkillMapIcon2(self.SkillId) or self._Control:GetWeaponSkillMapIcon(self.SkillId)
    self.TxtSkillName.text = name
    self.TxtDetails.text = XUiHelper.ConvertLineBreakSymbol(desc) 
    self.RImgLegend:SetRawImage(mapIcon)
    local cd = self._Control:GetWeaponSkillCd(self.RoleId, self.SkillId, true)
    self.TxtSkillCd.gameObject:SetActiveEx(cd > 0)
    if cd > 0 then
        self.TxtSkillCd.text = tostring(cd)
    end

    -- 行动倒计时
    local isInDelay, delayRound = bossInfo:IsSkillInDelay(self.SkillId)
    self.PanelAction.gameObject:SetActiveEx(isInDelay)
    if isInDelay then
        if delayRound == 0 then
            self.TxtActionCd.text = self._Control:GetClientConfigWithIndex("ActionCountdownTips", 2)
        else
            local format = self._Control:GetClientConfigWithIndex("ActionCountdownTips", 1)
            self.TxtActionCd.text = string.format(format, delayRound)
        end
    end
end

-- 刷新移动详情
---@param bossInfo XChessBoss
function XUiPanelBossDetails:RefreshMoveDetails(bossInfo)
    local weaponId = bossInfo:GetWeaponId()
    local isStrengthen = bossInfo:IsInMoveStrengthen()
    local desc = isStrengthen and self._Control:GetWeaponDesc2(weaponId) or self._Control:GetWeaponDesc(weaponId)
    local mapIcon = isStrengthen and self._Control:GetWeaponMapIcon2(weaponId) or self._Control:GetWeaponMapIcon(weaponId)
    self.TxtDetails.text = desc
    self.RImgLegend:SetRawImage(mapIcon)
    self.TxtSkillName.text = self._Control:GetWeaponName(weaponId)
    self.TxtSkillCd.gameObject:SetActiveEx(false)
    self.PanelAction.gameObject:SetActiveEx(false)
end

return XUiPanelBossDetails