---@class XGuideCharacterEquipWithPosExistNode : XLuaBehaviorNode 查找部位意识
---@field CharacterId number 构造体Id
---@field Site number 意识插槽位置
local XGuideCharacterEquipWithPosExistNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "CheckCharacterEquipWithSiteExist", CsBehaviorNodeType.Action, true, false)

function XGuideCharacterEquipWithPosExistNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["CharacterId"] == nil or self.Fields["Site"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.CharacterId = self.Fields["CharacterId"]
    self.Site = self.Fields["Site"]
end

function XGuideCharacterEquipWithPosExistNode:OnEnter()
    local equipId = XMVCA.XEquip:GetCharacterEquipId(self.CharacterId, self.Site)
    if not equipId then
        self.Node.Status = CsNodeStatus.FAILED
    else
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end