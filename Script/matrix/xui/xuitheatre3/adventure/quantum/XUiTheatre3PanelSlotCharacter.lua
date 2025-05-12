---@class XUiTheatre3PanelSlotCharacter : XUiNode
---@field _Control XTheatre3Control
---@field CharacterTab XUiButtonGroup
local XUiTheatre3PanelSlotCharacter = XClass(XUiNode, "XUiTheatre3PanelSlotCharacter")

function XUiTheatre3PanelSlotCharacter:OnStart()
    self:_InitCharacter()
    self:AddBtnListener()
end

function XUiTheatre3PanelSlotCharacter:OnEnable()

end

function XUiTheatre3PanelSlotCharacter:OnDisable()

end

function XUiTheatre3PanelSlotCharacter:Refresh(equipId)
    self:_UpdateCharacter(equipId)
    self.CharacterTab:SelectIndex(self:_GetFirstCanWearSlot())
end

--region Ui - Character
function XUiTheatre3PanelSlotCharacter:_InitCharacter()
    local XUiTheatre3EquipmentCharacter = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCharacter")
    local tabs = {
        self.CharacterGrid1,
        self.CharacterGrid2,
        self.CharacterGrid3,
    }
    self._CurSelectCharacterIndex = nil
    ---@type XUiTheatre3EquipmentCharacter[]
    self._GridCharacterList = {
        XUiTheatre3EquipmentCharacter.New(tabs[1], self, 1),
        XUiTheatre3EquipmentCharacter.New(tabs[2], self, 2),
        XUiTheatre3EquipmentCharacter.New(tabs[3], self, 3),
    }
    self.CharacterTab:Init(tabs, function(index)
        self:_OnSelectCharacter(index)
    end)
end

function XUiTheatre3PanelSlotCharacter:_UpdateCharacter(equipId)
    for _, grid in ipairs(self._GridCharacterList) do
        grid:UpdateByEquip(equipId)
    end
end

function XUiTheatre3PanelSlotCharacter:_GetFirstCanWearSlot()
    local isForbid = false
    local belong = nil
    for i, v in ipairs(self._GridCharacterList) do
        if v:IsForbidEquip() or not v:HasEnoughCapcity() then
            isForbid = true
        elseif not belong then
            belong = i
        end
    end
    return isForbid and belong or 1
end

function XUiTheatre3PanelSlotCharacter:GetCurSelectCharacterIndex()
    return self._CurSelectCharacterIndex
end

function XUiTheatre3PanelSlotCharacter:_OnSelectCharacter(index)
    self._CurSelectCharacterIndex = index
end
--endregion

--region Ui - BtnListener
function XUiTheatre3PanelSlotCharacter:AddBtnListener()

end
--endregion

return XUiTheatre3PanelSlotCharacter