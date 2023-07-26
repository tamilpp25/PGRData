local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XViewModelDlcHuntCharacter
local XViewModelDlcHuntCharacter = XClass(nil, "XViewModelDlcHuntCharacter")

function XViewModelDlcHuntCharacter:Ctor()
    self._CharacterId = XDataCenter.DlcHuntCharacterManager.GetFightCharacterId()
end

function XViewModelDlcHuntCharacter:OnStart()
end

function XViewModelDlcHuntCharacter:OnDestroy()
end

---@param character XDlcHuntCharacter
function XViewModelDlcHuntCharacter:SetCharacter(character)
    self._CharacterId = character:GetCharacterId()
end

function XViewModelDlcHuntCharacter:GetCharacterId()
    return self._CharacterId
end

---@param character XDlcHuntCharacter
function XViewModelDlcHuntCharacter:IsSelected(character)
    return self:GetCharacterId() == character:GetCharacterId()
end

function XViewModelDlcHuntCharacter:GetDataProvider()
    local allCharacter = XDataCenter.DlcHuntCharacterManager.GetCharacterList()
    return allCharacter
end

function XViewModelDlcHuntCharacter:GetSelectedIndex()
    local characterId = self:GetCharacterId()
    local allCharacter = self:GetDataProvider()
    for i = 1, #allCharacter do
        local character = allCharacter[i]
        if character:IsCharacter(characterId) then
            return i
        end
    end
    return 1
end

function XViewModelDlcHuntCharacter:IsCharacterFighting()
    return self:GetCharacterId() == XDataCenter.DlcHuntCharacterManager.GetFightCharacterId()
end

function XViewModelDlcHuntCharacter:GetCharacterName()
    return self:GetCharacter():GetName()
end

function XViewModelDlcHuntCharacter:GetCharacterNameEn()
    return self:GetCharacter():GetNameEn()
end

function XViewModelDlcHuntCharacter:GetCharacterEnergy()
    return self:GetCharacter():GetElementIconList()
end

function XViewModelDlcHuntCharacter:GetWeaponIcon()
    return XDlcHuntCharacterConfigs.GetCharacterWeaponIcon(self:GetCharacterId())
end

function XViewModelDlcHuntCharacter:GetWeaponName()
    return XDlcHuntCharacterConfigs.GetCharacterWeaponName(self:GetCharacterId())
end

function XViewModelDlcHuntCharacter:GetElementIcon()
    return XDlcHuntCharacterConfigs.GetCharacterElementIcon(self:GetCharacterId())
end

function XViewModelDlcHuntCharacter:GetElementName()
    return XDlcHuntCharacterConfigs.GetCharacterElementName(self:GetCharacterId())
end

function XViewModelDlcHuntCharacter:GetCharacter()
    return XDataCenter.DlcHuntCharacterManager.GetCharacter(self._CharacterId)
end

function XViewModelDlcHuntCharacter:GetAttrTable4Display(justBaseAttr)
    return self:GetCharacter():GetAttrTable4Display(justBaseAttr)
end

---@return XDlcHuntChipGroup
function XViewModelDlcHuntCharacter:GetChipGroup()
    local character = self:GetCharacter()
    if not character then
        return false
    end
    return character:GetChipGroup()
end

function XViewModelDlcHuntCharacter:RequestFight()
    local character = self:GetCharacter()
    if not character then
        return
    end
    XDataCenter.DlcHuntCharacterManager.RequestSetFightCharacter(character)
end

function XViewModelDlcHuntCharacter:GetDataModel()
    local character = self:GetCharacter()
    if not character then
        return
    end
    return character:GetDataModel()
end

function XViewModelDlcHuntCharacter:GetCharacterIcon()
    return self:GetCharacter():GetIcon()
end

function XViewModelDlcHuntCharacter:GetChipGroupAmount()
    local group = self:GetChipGroup()
    if not group then
        return 0, XDlcHuntChipConfigs.CHIP_GROUP_CHIP_AMOUNT
    end
    return group:GetAmount(), group:GetCapacity()
end

function XViewModelDlcHuntCharacter:GetChipGroupName()
    local group = self:GetChipGroup()
    if not group then
        return ""
    end
    return group:GetName()
end

function XViewModelDlcHuntCharacter:GetSkill()
    return XDlcHuntSkillConfigs.GetData4Display(self:GetCharacter())
end

return XViewModelDlcHuntCharacter