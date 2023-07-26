local XDlcHuntModel = require("XEntity/XDlcHunt/XDlcHuntModel")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XDlcHuntCharacter
local XDlcHuntCharacter = XClass(nil, "XDlcHuntCharacter")

function XDlcHuntCharacter:Ctor()
    self._TemplateId = false
    self._Level = 1
    self._ChipGroupId = false
    ---@type XDlcHuntModel
    self._DataModel = false
    -- 似乎没什么营养
    --self._CreateTime = 0
end

function XDlcHuntCharacter:SetData(data)
    self._TemplateId = data.Id
    self._ChipGroupId = data.ChipFormId
    --self._CreateTime = data.CreateTime
end

function XDlcHuntCharacter:SetCharacterId(id)
    self._TemplateId = id
end

function XDlcHuntCharacter:SetChipGroupId(groupId)
    self._ChipGroupId = groupId
end

function XDlcHuntCharacter:GetChipGroupId()
    return self._ChipGroupId
end

function XDlcHuntCharacter:GetChipGroup()
    return XDataCenter.DlcHuntChipManager.GetChipGroup(self:GetChipGroupId())
end

function XDlcHuntCharacter:IsDressChipGroup(chipGroupId)
    return self:GetChipGroupId() == chipGroupId
end

function XDlcHuntCharacter:GetCharacterId()
    return self._TemplateId
end

function XDlcHuntCharacter:IsCharacter(characterId)
    return self:GetCharacterId() == characterId
end

function XDlcHuntCharacter:GetNpcId()
    return XDlcHuntCharacterConfigs.GetCharacterNpcId(self:GetCharacterId())
end

function XDlcHuntCharacter:GetPlayerId()
    return XPlayer.Id
end

function XDlcHuntCharacter:GetIcon()
    return XDlcHuntCharacterConfigs.GetCharacterIcon(self:GetCharacterId())
end

function XDlcHuntCharacter:GetLevel()
    return self._Level
end

function XDlcHuntCharacter:GetName()
    return XDlcHuntCharacterConfigs.GetCharacterName(self:GetCharacterId())
end

function XDlcHuntCharacter:GetNameEn()
    return XDlcHuntCharacterConfigs.GetCharacterNameEn(self:GetCharacterId())
end

function XDlcHuntCharacter:GetElementIconList()
    return XDlcHuntCharacterConfigs.GetCharacterElementIconList(self:GetCharacterId())
end

function XDlcHuntCharacter:GetModelId()
    return XDlcHuntCharacterConfigs.GetCharacterModelId(self:GetCharacterId())
end

function XDlcHuntCharacter:GetDataModel()
    if not self._DataModel then
        self._DataModel = XDlcHuntModel.New()
    end
    self._DataModel:SetDataByMember(self)
    return self._DataModel
end

function XDlcHuntCharacter:GetFightingPower()
    local attrTable = self:GetAttrTable()
    return XDlcHuntAttrConfigs.GetFightingPower(attrTable)
end

-- 人物的属性
function XDlcHuntCharacter:GetBaseAttrTable()
    return XDlcHuntCharacterConfigs.GetCharacterAttrTable(self:GetCharacterId())
end

-- 人物 + 芯片的属性
function XDlcHuntCharacter:GetAttrTable()
    local characterAttr = self:GetBaseAttrTable()
    local chipGroup = self:GetChipGroup()
    if chipGroup then
        local chipAttr = chipGroup:GetAttrTable()
        local sumAttrTable = XUiDlcHuntUtil.GetSumAttrTable(characterAttr, chipAttr)
        return sumAttrTable
    end
    return characterAttr
end

function XDlcHuntCharacter:GetAttrTable4Display(justBaseAttr)
    local characterAttr = self:GetBaseAttrTable()
    local chipAttr
    local chipGroup = self:GetChipGroup()
    if chipGroup and not justBaseAttr then
        chipAttr = chipGroup:GetAttrTable()
    else
        chipAttr = {}
    end
    characterAttr = XUiDlcHuntUtil.SelectCharacterAttr(characterAttr)
    chipAttr = XUiDlcHuntUtil.SelectCharacterAttr(chipAttr)
    local mergeAttr = XUiDlcHuntUtil.GetAttrTableMerge4Display(characterAttr, chipAttr)
    return mergeAttr
end

function XDlcHuntCharacter:IsOnFight()
    return XDataCenter.DlcHuntCharacterManager.GetFightCharacterId() == self:GetCharacterId()
end

function XDlcHuntCharacter:GetMagicDesc()
    local chipGroup = self:GetChipGroup()
    if not chipGroup then
        return {}
    end
    return chipGroup:GetMagicDesc()
end

function XDlcHuntCharacter:GetCode()
    return XDlcHuntCharacterConfigs.GetCharacterCode(self:GetCharacterId())
end

function XDlcHuntCharacter:GetMagicEventIds()
    local chipGroup = self:GetChipGroup()
    if not chipGroup then
        return {}
    end
    return chipGroup:GetMagicEventIds()
end

function XDlcHuntCharacter:GetPriority()
    return XDlcHuntCharacterConfigs.GetCharacterPriority(self:GetCharacterId())
end

function XDlcHuntCharacter:IsCanEquipMoreChip()
    local chipGroup = self:GetChipGroup()
    if not chipGroup then
        return true
    end
    local mainChip = chipGroup:GetMainChip()
    if not mainChip then
        local amountMainOnBag = XDataCenter.DlcHuntChipManager.GetChipAmountMain()
        if amountMainOnBag > 0 then
            return true
        end
    end
    
    local amountSubChipEquip = chipGroup:GetAmountSubChip()
    if amountSubChipEquip < XDlcHuntChipConfigs.CHIP_SUB_AMOUNT then
        local amountSubOnBag = XDataCenter.DlcHuntChipManager.GetChipAmountSub()
        if amountSubChipEquip < amountSubOnBag then
            return true
        end
    end
    return false
end

return XDlcHuntCharacter