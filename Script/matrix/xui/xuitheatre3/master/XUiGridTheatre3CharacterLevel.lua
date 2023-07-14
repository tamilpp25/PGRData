---@class XUiGridTheatre3CharacterLevel : XUiNode
---@field _Control XTheatre3Control
---@field BtnCharacter XUiComponent.XUiButton
local XUiGridTheatre3CharacterLevel = XClass(XUiNode, "XUiGridTheatre3CharacterLevel")

function XUiGridTheatre3CharacterLevel:OnStart()
    self.LvBuffOn = XTool.InitUiObjectByUi({}, self.PanelLvBuffOn)
    self.LvBuffOff = XTool.InitUiObjectByUi({}, self.PanelLvBuffOff)
end

function XUiGridTheatre3CharacterLevel:Refresh(levelId, characterId)
    self.CharacterId = characterId
    -- 等级
    local level = self._Control:GetCharacterLevelByLevelId(levelId)
    self.LvBuffOn.TxtLvNum.text = level
    self.LvBuffOff.TxtLvNum.text = level
    local strengthenPoint = self._Control:GetCharacterLevelStrengthenPoint(levelId)
    local isShowPoint = XTool.IsNumberValid(strengthenPoint)
    -- 图标
    if isShowPoint then
        -- 物品图片
        local icon = XDataCenter.ItemManager.GetItemIcon(XEnumConst.THEATRE3.Theatre3TalentPoint)
        self.LvBuffOn.Icon:SetRawImage(icon)
        self.LvBuffOff.Icon:SetRawImage(icon)
    end
    self.LvBuffOn.Icon.gameObject:SetActiveEx(isShowPoint)
    self.LvBuffOff.Icon.gameObject:SetActiveEx(isShowPoint)
    -- Buff
    local buffDesc
    if isShowPoint then
        local desc = self._Control:GetClientConfig("CharacterLevelUpGetBuffDesc", 1)
        buffDesc = string.format(desc, strengthenPoint)
    else
        buffDesc = self._Control:GetCharacterLevelDesc(level)
    end
    self.LvBuffOn.TxtBuff.text = buffDesc
    self.LvBuffOff.TxtBuff.text = buffDesc
    -- 状态
    local curLevel = self._Control:GetCharacterLv(characterId)
    self.LvBuffOn.GameObject:SetActiveEx(curLevel >= level)
    self.LvBuffOff.GameObject:SetActiveEx(curLevel < level)
end

return XUiGridTheatre3CharacterLevel