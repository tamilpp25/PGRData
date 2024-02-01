local XUiTheatre3EquipmentCharacter = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCharacter")
local XUiTheatre3EquipmentSuit = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentSuit")

---@class XUiTheatre3SettlementMember : XUiNode 成员
---@field Parent XUiTheatre3Settlement
---@field _Control XTheatre3Control
local XUiTheatre3SettlementMember = XClass(XUiNode, "XUiTheatre3SettlementMember")

function XUiTheatre3SettlementMember:OnStart()
    ---@type table<number,table<number,XUiTheatre3EquipmentSuit>>
    self._Pool = {}
    ---@type XUiTheatre3EquipmentCharacter[]
    self._CharacterMap = {}
    self:Init()
end

function XUiTheatre3SettlementMember:Init()
    ---@type XUiTheatre3EquipmentCharacter
    self._CharacterMap[1] = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid1, self, 1)
    ---@type XUiTheatre3EquipmentCharacter
    self._CharacterMap[2] = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid2, self, 2)
    ---@type XUiTheatre3EquipmentCharacter
    self._CharacterMap[3] = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid3, self, 3)
end

function XUiTheatre3SettlementMember:UpdateSuitList()
    for SlotId = 1, 3 do
        local content = self["Content" .. SlotId]
        local datas = self._Control:GetSlotSuits(SlotId)
        if #datas == 0 then
            self["TxtEmpty" .. SlotId].gameObject:SetActiveEx(true)
        else
            for i = 1, #datas do
                if not self._Pool[SlotId] then
                    self._Pool[SlotId] = {}
                end
                local suit = self._Pool[SlotId][i]
                local isQuantum = self._Control:CheckAdventureSuitIsQuantum(datas[i])
                if not suit then
                    suit = XUiTheatre3EquipmentSuit.New(XUiHelper.Instantiate(isQuantum and self.QuantumSetGrid or self.BtnSet, content), self)
                    suit:Open()
                    self._Pool[SlotId][i] = suit
                end
                suit:SetSuitId(datas[i], SlotId)
                suit:IsShowTip(true)
            end
            self["TxtEmpty" .. SlotId].gameObject:SetActiveEx(false)
        end
    end
end

function XUiTheatre3SettlementMember:OnEnable()
    for _, v in pairs(self._CharacterMap) do
        v:Update()
        v:IsShowCapacity(false)
    end
    self:UpdateSuitList()
end

function XUiTheatre3SettlementMember:RefreshTemplateGrids(...)
    -- 给XUiTheatre3EquipmentSuit用
    self.Parent:RefreshTemplateGrids(...)
end

return XUiTheatre3SettlementMember