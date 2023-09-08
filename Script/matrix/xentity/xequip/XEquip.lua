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
    self:SetOverrunData(protoData.WeaponOverrunData)

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

function XEquip:SetBreakthrough(breakthrough)
    self.Breakthrough = breakthrough
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

function XEquip:GetEquipViewModel()
    local viewModelScript
    if self:IsWeapon() then
        viewModelScript = require("XEntity/XEquip/XWeaponViewModel")
    else
        viewModelScript = require("XEntity/XEquip/XEquipViewModel")
    end
    local viewModel = viewModelScript.New(self.TemplateId)
    local data = {}
    for key, _ in pairs(Default) do
        data[key] = self[key]
    end
    viewModel:UpdateWithData(data)
    return viewModel
end

-- 是否有穿戴在角色身上
function XEquip:IsWearing()
    return self.CharacterId and self.CharacterId > 0
end

-- 是否是装备
function XEquip:IsWeapon()
    local equipSite = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSite(self.TemplateId)
    local isWeapon = equipSite == XEnumConst.EQUIP.EQUIP_SITE.WEAPON
    return isWeapon
end

-- 是否是意识
-- 传site则判断是否是对应位置的意识
function XEquip:IsAwareness(site)
    local equipSite = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSite(self.TemplateId)
    if site then
        return equipSite == site
    else
        local isAwareness = equipSite >= XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.ONE and equipSite <= XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.SIX
        return isAwareness
    end
end

-- 获取品质横图
function XEquip:GetEquipQualityPath()
    if self.OverrunData and self.OverrunData.Level > 0 then
        local deregulateUICfg = XEquipConfig.GetWeaponDeregulateUICfg(self.OverrunData.Level)
        return deregulateUICfg.IconQuality
    end

    return XDataCenter.EquipManager.GetEquipQualityPath(self.TemplateId)
end

-- 获取品质横特效
function XEquip:GetEquipQualityEffectPath()
    if self.OverrunData and self.OverrunData.Level > 0 then
        local deregulateUICfg = XEquipConfig.GetWeaponDeregulateUICfg(self.OverrunData.Level)
        return deregulateUICfg.IconQualityEffect
    end

    return
end

-- 获取品质竖图
function XEquip:GetEquipBgPath()
    if self.OverrunData and self.OverrunData.Level > 0 then
        local deregulateUICfg = XEquipConfig.GetWeaponDeregulateUICfg(self.OverrunData.Level)
        return deregulateUICfg.ItemsQuality
    end

    return XDataCenter.EquipManager.GetEquipBgPath(self.TemplateId)
end

-- 获取品质竖特效
function XEquip:GetEquipBgEffectPath()
    if self.OverrunData and self.OverrunData.Level > 0 then
        local deregulateUICfg = XEquipConfig.GetWeaponDeregulateUICfg(self.OverrunData.Level)
        return deregulateUICfg.ItemsQualityEffect
    end

    return
end

--#region 共鸣
-- 获取共鸣数据表，key为Pos
function XEquip:GetResonanceInfoDic()
    return self.ResonanceInfo or {}
end

-- 获取对应位置的共鸣信息
function XEquip:GetResonanceInfo(pos)
    return self.ResonanceInfo and self.ResonanceInfo[pos] or nil
end

-- 是否共鸣过
function XEquip:IsResonance()
    return self.ResonanceInfo ~= nil and next(self.ResonanceInfo)
end

-- 获取共鸣的数量
function XEquip:GetResonanceCount()
    local count = 0
    if self.ResonanceInfo then
        for _, info in pairs(self.ResonanceInfo) do
            if info then
                count = count + 1
            end
        end
    end

    return count
end

-- 获取共鸣绑定的角色ID
function XEquip:GetResonanceBindCharacterId(pos)
    if self.ResonanceInfo and self.ResonanceInfo[pos] then
        return self.ResonanceInfo[pos].CharacterId
    else
        return 0
    end
end

-- 共鸣技能是否有绑定角色ID
function XEquip:IsResonanceBindCharacter(characterId)
    if not self.ResonanceInfo then
        return false
    end

    for _, info in pairs(self.ResonanceInfo) do
        if info.CharacterId == characterId then
            return true
        end
    end

    return false
end

--#endregion 共鸣

--#region 武器超限
-- 设置超限数据
function XEquip:SetOverrunData(overrunData)
    self.OverrunData = overrunData
    self.OverrunCanBlindSuit = self:CheckCanBlindSuit()
end

-- 获取超限等级
function XEquip:GetOverrunLevel()
    return self.OverrunData and self.OverrunData.Level or 0
end

-- 获取超限选择的意识套装
function XEquip:GetOverrunChoseSuit()
    return self.OverrunData and self.OverrunData.ChoseSuit or 0
end

-- 获取超限已激活意识列表
function XEquip:GetOverrunActiveSuits()
    return self.OverrunData and self.OverrunData.ActiveSuits or {}
end

-- 是否可以超限
function XEquip:CanOverrun()
    return XEquipConfig.CanOverrunByTemplateId(self.TemplateId)
end

-- 是否已经超限
function XEquip:IsOverrun()
    return self:GetOverrunLevel() > 0
end

-- 是否可绑定意识套装
function XEquip:IsOverrunCanBlindSuit()
    return self.OverrunCanBlindSuit
end

-- 武器超限是否可绑定套装
function XEquip:CheckCanBlindSuit()
    local cfg = XEquipConfig.GetWeaponOverrunSuitCfgByTemplateId(self.TemplateId)
    if not cfg then
        return false
    end
    
    return self:GetOverrunLevel() >= cfg.Level
end

-- 超限绑定的意识是否匹配角色类型
-- 可传characterId判断与当前绑定的意识是否匹配
function XEquip:IsOverrunBlindMatch(characterId)
    local choseSuit = self:GetOverrunChoseSuit()
    if choseSuit == 0 then
        return true
    end

    if not self:IsWearing() and not characterId then
        return true
    end
    
    characterId = characterId or self.CharacterId
    local charType = XMVCA.XCharacter:GetCharacterType(characterId)
    local suitCharType = XEquipConfig.GetSuitCharacterType(choseSuit)
    if suitCharType == XEquipConfig.UserType.All or suitCharType == charType then
        return true
    end

    return false
end

-- 超限增加的战力
function XEquip:GetOverrunAbility()
    local lv = self:GetOverrunLevel()
    if lv < 1 then
        return 0
    end

    local ability = 0
    local overrunCfgs = XEquipConfig.GetWeaponOverrunCfgsByTemplateId(self.TemplateId)
    for _, overrunCfg in ipairs(overrunCfgs) do
        if lv >= overrunCfg.Level then
            if overrunCfg.OverrunType == XEquipConfig.WeaponOverrunUnlockType.Suit then
                if self:GetOverrunChoseSuit() ~= 0 and self:IsOverrunBlindMatch() then 
                    ability = ability + overrunCfg.Ability
                end
            else
                ability = ability + overrunCfg.Ability
            end
        end
    end
    return ability
end

-- 是否显示超限红点
function XEquip:IsShowOverrunRed()
    return self:GetOverrunChoseSuit() == 0 and self:CheckCanBlindSuit()
end
--#endregion 武器超限

return XEquip