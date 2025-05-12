---@class XGuideCharacterEquipQualityCompareNode : XLuaBehaviorNode 比较角色装备星级
---@field CharacterId number 构造体ID
---@field CompareEquipId number 对比的装备Id
local XGuideCharacterEquipQualityCompareNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "CharacterEquipQualityCompare", CsBehaviorNodeType.Action, true, false)

function XGuideCharacterEquipQualityCompareNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["CharacterId"] == nil or self.Fields["CompareEquipId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.CharacterId = self.Fields["CharacterId"]
    self.CompareEquipId = self.Fields["CompareEquipId"]
end

function XGuideCharacterEquipQualityCompareNode:OnEnter()
    if not XMVCA.XCharacter:IsOwnCharacter(self.CharacterId) then
        self.Node.Status = CsNodeStatus.FAILED
        return
    end

    local temp = XMVCA.XEquip:GetConfigEquip(self.CompareEquipId)
    if not temp then
        self.Node.Status = CsNodeStatus.FAILED
        return
    end


    local equipId = XMVCA.XEquip:GetCharacterWeaponId(self.CharacterId)  --初始为角色身上的装备
    local equip = XMVCA.XEquip:GetEquip(equipId)
    if not equipId or not equip then
        self.Node.Status = CsNodeStatus.FAILED
        return
    end

    local wearEquip = XMVCA.XEquip:GetConfigEquip(equip.TemplateId)
    if wearEquip.Star <= temp.Star then
        self.Node.Status = CsNodeStatus.FAILED
        return
    end

    self.Node.Status = CsNodeStatus.SUCCESS
end