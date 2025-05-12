local PresentSuitEquipsCount = 4    -- 已装备的意识中同一套的装备数量代表值

local XEquipSuitPrefab = XClass(nil, "XEquipSuitPrefab")

local Default = {
    EquipCount = 0,
    PresentSuitId = nil,
    SiteToEquipIdDic = {},
    EquipIdCheckTable = {},
    --Original Data
    GroupId = 0,
    Name = "",
    ChipIdList = {},
    CharacterId = 0,
}
--[[
public class XChipGroupData
{
    // 组合id
    public int GroupId;
    // 组合名字
    public string Name;
    // 意识id列表
    public List<int> ChipIdList;
    // 专属组合角色Id，通用组合为0
    public int CharacterId;
}
]]
function XEquipSuitPrefab:Ctor(equipGroupData)
    for key, v in pairs(Default) do
        self[key] = v
    end

    self:UpdateData(equipGroupData)
end

function XEquipSuitPrefab:UpdateData(equipGroupData)
    self.GroupId = equipGroupData.GroupId or self.GroupId
    self.Name = equipGroupData.Name or self.Name
    self.CharacterId = equipGroupData.CharacterId or self.CharacterId
    self.ChipIdList = equipGroupData.ChipIdList

    self.SiteToEquipIdDic = {}
    self.EquipIdCheckTable = {}
    for _, equipId in pairs(self.ChipIdList) do
        local equipSite = XMVCA.XEquip:GetEquipSiteByEquipId(equipId)
        self.SiteToEquipIdDic[equipSite] = equipId
        self.EquipIdCheckTable[equipId] = true
    end

    local count = 0
    for _, _ in pairs(self.SiteToEquipIdDic) do
        count = count + 1
    end
    self.EquipCount = count

    local presentEquipId = nil
    local suitIdCountDic = {}
    for site = XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.ONE, XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.SIX do
        local equipId = self.SiteToEquipIdDic[site]
        if equipId then
            presentEquipId = presentEquipId or equipId

            local suitId = XMVCA.XEquip:GetEquipSuitIdByEquipId(equipId)
            local tmpCount = suitIdCountDic[suitId] or 0
            tmpCount = tmpCount + 1
            if tmpCount == PresentSuitEquipsCount then
                presentEquipId = equipId
                break
            end
            suitIdCountDic[suitId] = tmpCount
        end
    end
    self.PresentSuitId = presentEquipId and XMVCA.XEquip:GetEquipSuitIdByEquipId(presentEquipId)
end

function XEquipSuitPrefab:GetGroupId()
    return self.GroupId
end

function XEquipSuitPrefab:GetName()
    return self.Name
end

function XEquipSuitPrefab:SetName(newName)
    self.Name = newName
end

function XEquipSuitPrefab:GetEquipCount()
    return self.EquipCount
end

function XEquipSuitPrefab:GetPresentSuitId()
    return self.PresentSuitId
end

function XEquipSuitPrefab:GetEquipId(site)
    return self.SiteToEquipIdDic[site]
end

function XEquipSuitPrefab:GetEquipIds()
    return self.ChipIdList
end

-- 专属组合角色Id，通用组合为0
function XEquipSuitPrefab:GetCharacterId()
    return self.CharacterId
end

function XEquipSuitPrefab:IsEquipIn(equipId)
    return self.EquipIdCheckTable[equipId]
end

function XEquipSuitPrefab:GetCharacterType()
    for _, equipId in pairs(self.ChipIdList) do
        local templateId = XMVCA.XEquip:GetEquipTemplateId(equipId)
        return XMVCA.XEquip:GetEquipCharacterType(templateId)
    end
    return XEnumConst.EQUIP.USER_TYPE.ALL
end

return XEquipSuitPrefab