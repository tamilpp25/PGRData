local next = next
local tableInsert = table.insert

local XEquip = XClass(nil, "XEquip")

local Default = {
    Id = 0,
    TemplateId = 0,
    CharacterId = 0,
    Level = 1,
    Exp = 0,
    Breakthrough = 0,
    CreateTime = 0,
    IsLock = false,
    IsRecycle = false,
    AwakeSlotList = {},
    AwakeSlotListCheck = {},
}

function XEquip.GetDefaultFields()
    return Default
end

--[[装备共鸣表结构
ResonanceInfo = {
    Slot = slot,
    Type = XEquipConfig.EquipResonanceType.Attrib,
    CharacterId = 0,
    TemplateId = 0,
}
]]
--[[/// 意识自动回收设置
[MessagePackObject(keyAsPropertyName: true)]
public class XChipRecycleSite
{
    // 设置的回收星级
    public List<int> RecycleStar = new List<int>();
    // 设置回收天数, 0为不回收
    public int Days;
}
]]
function XEquip:Ctor(protoData)
    for key, v in pairs(Default) do
        self[key] = v
    end
    self:SyncData(protoData)
end

function XEquip:SyncData(protoData)
    self.Id = protoData.Id
    self.TemplateId = protoData.TemplateId
    self.CharacterId = protoData.CharacterId
    self.Level = protoData.Level
    self.Exp = protoData.Exp
    self.Breakthrough = protoData.Breakthrough
    self.CreateTime = protoData.CreateTime
    self.IsLock = protoData.IsLock
    self.IsRecycle = protoData.IsRecycle

    if protoData.ResonanceInfo and next(protoData.ResonanceInfo) then
        self.ResonanceInfo = {}

        for _, info in pairs(protoData.ResonanceInfo) do
            self.ResonanceInfo[info.Slot] = info
        end
    else
        self.ResonanceInfo = nil
    end

    if protoData.UnconfirmedResonanceInfo and next(protoData.UnconfirmedResonanceInfo) then
        self.UnconfirmedResonanceInfo = {}
        for _, info in pairs(protoData.UnconfirmedResonanceInfo) do
            self.UnconfirmedResonanceInfo[info.Slot] = info
        end
    else
        self.UnconfirmedResonanceInfo = nil
    end

    self.AwakeSlotListCheck = {}
    if protoData.AwakeSlotList and next(protoData.AwakeSlotList) then
        self.AwakeSlotList = protoData.AwakeSlotList
        for _, slot in pairs(self.AwakeSlotList) do
            self.AwakeSlotListCheck[slot] = true
        end
    end
end

--@isSelect: 是否自选的技能
function XEquip:Resonance(resonanceInfo, isSelect)
    local slot = resonanceInfo.Slot
    local info = self.ResonanceInfo and self.ResonanceInfo[slot]

    if not info then
        self.ResonanceInfo = self.ResonanceInfo and self.ResonanceInfo or {}
        self.ResonanceInfo[slot] = resonanceInfo
    else
        if not isSelect then
            self.UnconfirmedResonanceInfo = self.UnconfirmedResonanceInfo and self.UnconfirmedResonanceInfo or {}
            if resonanceInfo and next(resonanceInfo) then
                self.UnconfirmedResonanceInfo[slot] = resonanceInfo
            end
        else
            self.ResonanceInfo[slot] = resonanceInfo
        end
    end
    self:SetRecycle(false)
end

function XEquip:ResonanceConfirm(slot, isUse)
    local info = self.UnconfirmedResonanceInfo and self.UnconfirmedResonanceInfo[slot]
    if not info then return end
    self.ResonanceInfo[slot] = isUse and info or self.ResonanceInfo[slot]
    if self.UnconfirmedResonanceInfo then
        self.UnconfirmedResonanceInfo[slot] = nil
        self.UnconfirmedResonanceInfo = next(self.UnconfirmedResonanceInfo) and self.UnconfirmedResonanceInfo or nil
    end
    self:SetRecycle(false)
end

function XEquip:SetAwake(slot)
    local awakeSlotList = {}
    self.AwakeSlotListCheck[slot] = true
    for tmpSlot in pairs(self.AwakeSlotListCheck) do
        tableInsert(awakeSlotList, tmpSlot)
    end
    self.AwakeSlotList = awakeSlotList
    self:SetRecycle(false)
end

function XEquip:PutOn(characterId)
    characterId = characterId or 0
    self.CharacterId = characterId
    self:SetRecycle(false)
end

function XEquip:TakeOff()
    self.CharacterId = 0
end

function XEquip:SetLock(isLock)
    self.IsLock = isLock and true or false
    self:SetRecycle(false)
end

function XEquip:SetRecycle(isRecycle)
    self.IsRecycle = isRecycle and true or false
end

function XEquip:BreakthroughOneTime()
    self.Breakthrough = self.Breakthrough + 1
    self.Level = 1
    self.Exp = 0
    self:SetRecycle(false)
end

function XEquip:SetLevel(level)
    self.Level = level
    self:SetRecycle(false)
end

function XEquip:SetExp(exp)
    self.Exp = exp
end

function XEquip:IsEquipPosAwaken(slot)
    return self.AwakeSlotListCheck[slot] and true or false
end


return XEquip