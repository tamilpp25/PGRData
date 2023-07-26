local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
local XUiGridResonanceSkillOther = require("XUi/XUiPlayerInfo/XUiGridResonanceSkillOther")

local XUiEquipResonanceSkillDetailInfo = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSkillDetailInfo")

function XUiEquipResonanceSkillDetailInfo:OnAwake()
    self:RegisterClickEvent(self.BtnHideCurResonance, function()
        self:Close()
    end)
end

--fromeOther：是否在查看其他玩家信息
--fromTip：是否点击其他玩家的超频详情，然后弹出tip
function XUiEquipResonanceSkillDetailInfo:OnStart(equipId, pos, characterId, isAwakeDes, forceShowBindCharacter, fromeOther, fromTip, character, equip)
    self.EquipId = equipId
    self.Pos = pos
    self.CharacterId = characterId
    self.IsAwakeDes = isAwakeDes
    self.ForceShowBindCharacter = forceShowBindCharacter

    if fromeOther then
        self:RefreshOther(fromTip,character,equip)
    else
        self:Refresh()
    end
end

function XUiEquipResonanceSkillDetailInfo:Refresh()
    local equipId = self.EquipId
    local pos = self.Pos
    local characterId = self.CharacterId
    local isAwakeDes = self.IsAwakeDes
    local forceShowBindCharacter = self.ForceShowBindCharacter
    self.CurResonanceSkillGrid = self.CurResonanceSkillGrid or XUiGridResonanceSkill.New(self.GridCurResonanceSkill, equipId, pos, characterId, nil, nil, forceShowBindCharacter)
    self.CurResonanceSkillGrid:SetEquipIdAndPos(equipId, pos, isAwakeDes)
    self.CurResonanceSkillGrid:Refresh()
end

function XUiEquipResonanceSkillDetailInfo:RefreshOther(fromTip,character,equip)
    local pos = self.Pos
    self.CurResonanceSkillGrid = self.CurResonanceSkillGrid or XUiGridResonanceSkillOther.New(self.GridCurResonanceSkill, equip, pos, fromTip, character)
    self.CurResonanceSkillGrid:Refresh()
end