local XUiSupertowerExpansion = XLuaUiManager.Register(XLuaUi, "UiSupertowerExpansion")

function XUiSupertowerExpansion:OnAwake()
    -- XSuperTowerRole
    self.SuperTowerRole = nil
    self:RegisterUiEvents()
end

function XUiSupertowerExpansion:OnStart(superTowerRoleId, oldLevel, newLevel)
    self.SuperTowerRole = XDataCenter.SuperTowerManager.GetRoleManager():GetRole(superTowerRoleId)
    if newLevel == nil then newLevel = self.SuperTowerRole:GetSuperLevel() end
    -- local characterViewModel = self.SuperTowerRole:GetCharacterViewModel()
    -- local attributeDic = characterViewModel:GetAttributes(self.SuperTowerRole:GetEquipViewModels())
    local levelText = CS.XTextManager.GetText("STExpansionLevelTitle")
    -- 旧的信息
    self.TxtOldLevel.text = string.format("<size=60>%s</size> %s", levelText, oldLevel)
    self.TxtOldLife.text = self.SuperTowerRole:GetAttributeValue(XNpcAttribType.Life, oldLevel) -- FixToInt(attributeDic[XNpcAttribType.Life]) + 
    self.TxtOldAttack.text = self.SuperTowerRole:GetAttributeValue(XNpcAttribType.AttackNormal, oldLevel) -- FixToInt(attributeDic[XNpcAttribType.AttackNormal]) + 
    self.TxtOldDefense.text = self.SuperTowerRole:GetAttributeValue(XNpcAttribType.DefenseNormal, oldLevel) -- FixToInt(attributeDic[XNpcAttribType.DefenseNormal]) + 
    self.TxtOldCrit.text = self.SuperTowerRole:GetAttributeValue(XNpcAttribType.Crit, oldLevel) -- FixToInt(attributeDic[XNpcAttribType.Crit]) + 
    -- 新的信息
    self.TxtCurLevel.text = string.format("<size=60>%s</size> %s", levelText, newLevel)
    self.TxtCurLife.text = self.SuperTowerRole:GetAttributeValue(XNpcAttribType.Life, newLevel) -- FixToInt(attributeDic[XNpcAttribType.Life]) + 
    self.TxtCurAttack.text = self.SuperTowerRole:GetAttributeValue(XNpcAttribType.AttackNormal, newLevel) -- FixToInt(attributeDic[XNpcAttribType.AttackNormal]) + 
    self.TxtCurDefense.text = self.SuperTowerRole:GetAttributeValue(XNpcAttribType.DefenseNormal, newLevel) -- FixToInt(attributeDic[XNpcAttribType.DefenseNormal]) + 
    self.TxtCurCrit.text = self.SuperTowerRole:GetAttributeValue(XNpcAttribType.Crit, newLevel) -- FixToInt(attributeDic[XNpcAttribType.Crit]) + 
end

function XUiSupertowerExpansion:RegisterUiEvents()
    self.BtnClose.CallBack = function() self:Close() end
end

return XUiSupertowerExpansion