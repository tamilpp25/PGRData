-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey = 
{
    Equip = { CacheType = XConfigUtil.CacheType.Normal },
    EquipText = { CacheType = XConfigUtil.CacheType.Normal },
    EquipBreakThrough = { TableDefindName = "XTableEquipBreakthrough", CacheType = XConfigUtil.CacheType.Normal }, -- XTable定义的大小写不一致
    EquipSuit = { CacheType = XConfigUtil.CacheType.Normal },
    EquipSuitEffect = { CacheType = XConfigUtil.CacheType.Normal },
    EquipDecompose = { ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key", CacheType = XConfigUtil.CacheType.Normal },
    EatEquipCost = { ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },
    EquipResonance = { CacheType = XConfigUtil.CacheType.Normal },
    EquipResonanceUseItem = {},
    WeaponSkill = { CacheType = XConfigUtil.CacheType.Normal },
    WeaponSkillPool = { CacheType = XConfigUtil.CacheType.Normal },
    EquipAwake = { CacheType = XConfigUtil.CacheType.Normal },
    WeaponOverrun = { CacheType = XConfigUtil.CacheType.Normal },
    CharacterSuitPriority = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "CharacterId"},
    EquipRes = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    EquipModel = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    EquipModelTransform = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    EquipSkipId = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    EquipAnim = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "ModelId", ReadFunc = XConfigUtil.ReadType.String, CacheType = XConfigUtil.CacheType.Normal },
    EquipModelShow = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, CacheType = XConfigUtil.CacheType.Normal },
    EquipResByFool = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    EquipSignboard = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    EquipAnimReset = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    WeaponDeregulateUI = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Lv", CacheType = XConfigUtil.CacheType.Normal },
    EquipConfig = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String, CacheType = XConfigUtil.CacheType.Normal },
    EquipResonanceEffect = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
}

local EquipGuideTableKey = 
{
    EquipRecommend = { CacheType = XConfigUtil.CacheType.Normal }
}

---@class XEquipModel : XModel
local XEquipModel = XClass(XModel, "XEquipModel")
function XEquipModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    self.EquipDic = {} --Equip实例对象列表
    self.CharacterEquipIdDic = {} -- 角色装备列表
    self.AwarenessRecycleInfo = { --意识回收设置
        --设置的回收星级（默认选中1-4星）
        StarCheckDic = {
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true
        },
        Days = 0 --设置回收天数, 0为不回收
    }
    self.OverLimitTexts = {}
    
    --config相关
    self:InitConfig()
end

function XEquipModel:ClearPrivate()
    self.WeaponOverrunDic = nil
    self._EquipResonance = nil

    --这里执行内部数据清理
    --XLog.Error("请对内部数据进行清理")
end

function XEquipModel:ResetAll()
    --这里执行重登数据清理
    --XLog.Error("重登数据清理")

    self:ReleaseEquipDic()
    self.CharacterEquipIdDic = {}
    self.TempList = nil
    self.ResonanceTokenDic = nil
end

--============================================================== #region 协议数据 ==============================================================

---------------------------------------- #region 装备 ----------------------------------------
-- 登陆初始化装备数据
function XEquipModel:InitEquipData(dataList)
    self:ReleaseEquipDic()
    local XEquip = require("XEntity/XEquip/XEquip")
    for _, protoData in pairs(dataList) do
        self.EquipDic[protoData.Id] = XEquip.New(protoData)
        self:SetCharacterEquipId(protoData.CharacterId, protoData.Id)
    end
end

-- 刷新装备列表
function XEquipModel:UpdateEquipData(dataList)
    local XEquip = require("XEntity/XEquip/XEquip")
    for _, protoData in pairs(dataList) do
        local equip = self.EquipDic[protoData.Id]
        if not equip then
            equip = XEquip.New(protoData)
            self.EquipDic[protoData.Id] = equip
            self:SetCharacterEquipId(protoData.CharacterId, protoData.Id)
        else
            equip:SyncData(protoData)
        end
    end
end

-- 释放所有装备
function XEquipModel:ReleaseEquipDic()
    for _, equip in pairs(self.EquipDic) do
        equip:Release()
    end
    self.EquipDic = {}
end

-- 获取装备的XEquip对象实例
function XEquipModel:GetEquip(equipId)
    local equip = self.EquipDic[equipId]
    if equip then 
        return equip
    else
        XLog.Error("XEquipModel:GetEquip error: 装备不存在, equipId: " .. tostring(equipId))
        return
    end
end

-- 根据装备的配置表Id获取装备列表
function XEquipModel:GetEquipsByTemplateId(templateId, isIgnoreWear)
    local equips = {}
    for _, equip in pairs(self.EquipDic) do
        if equip.TemplateId == templateId and (not isIgnoreWear or not equip:IsWearing()) then
            table.insert(equips, equip)
        end
    end
    return equips
end

--- 装备是否存在
function XEquipModel:IsEquipExit(equipId)
    return self.EquipDic[equipId] ~= nil
end

-- 获取所有装备的XEquip对象实例
function XEquipModel:GetEquipDic()
    return self.EquipDic
end

-- 删除装备列表
function XEquipModel:DeleteEquips(equipIds)
    if #equipIds == 0 then return end
    
    -- 删除装备
    local charIdDic = {}
    for _, equipId in ipairs(equipIds) do
        local equip = self:GetEquip(equipId)
        if equip:IsWearing() then
            charIdDic[tmpEquip.CharacterId] = true
        end
        self:DeleteEquip(equipId)
    end

    -- 更新角色数据
    if next(charIdDic) then
        XMVCA.XCharacter:OnSyncCharacterEquipChange(charIdDic)
    end
end

-- 删除装备
function XEquipModel:DeleteEquip(equipId)
    self.EquipDic[equipId] = nil
end

-- 获取装备的配置表Id
function XEquipModel:GetEquipTemplateId(equipId)
    local equip = self:GetEquip(equipId)
    return equip.TemplateId
end

function XEquipModel:GetEquipWearingCharacterId(equipId)
    local equip = self:GetEquip(equipId)
    return equip.CharacterId > 0 and equip.CharacterId or nil
end

function XEquipModel:IsWearing(equipId)
    if not equipId then
        return false
    end
    local equip = self:GetEquip(equipId)
    return equip:IsWearing()
end

function XEquipModel:IsEquipWearingByCharacterId(equipId, characterId)
    if not XTool.IsNumberValid(characterId) then
        return false
    end
    return self:GetEquipWearingCharacterId(equipId) == characterId
end

function XEquipModel:IsLock(equipId)
    if not equipId then
        return false
    end
    local equip = self:GetEquip(equipId)
    return equip and equip.IsLock
end

function XEquipModel:GetEquipLevel(equipId)
    local equip = self:GetEquip(equipId)
    return equip.Level
end

function XEquipModel:IsMaxLevel(equipId)
    local equip = self:GetEquip(equipId)
    return equip.Level >= self:GetEquipBreakthroughLevelLimitByEquipId(equipId)
end

function XEquipModel:IsMaxBreakthrough(equipId)
    if not self:IsEquipExit(equipId) then return false end
    local equip = self:GetEquip(equipId)
    local maxBreakthrough, maxLevel = self:GetEquipMaxBreakthrough(equip.TemplateId)
    return equip.Breakthrough >= maxBreakthrough
end

function XEquipModel:IsReachBreakthroughLevel(equipId)
    if not self:IsEquipExit(equipId) then return false end
    local equip = self:GetEquip(equipId)
    return equip.Level >= self:GetEquipBreakthroughLevelLimitByEquipId(equipId)
end

function XEquipModel:IsMaxLevelAndBreakthrough(equipId)
    if not self:IsEquipExit(equipId) then return false end
    return self:IsMaxBreakthrough(equipId) and self:IsReachBreakthroughLevel(equipId)
end

function XEquipModel:CanBreakThrough(equipId)
    return not self:IsMaxBreakthrough(equipId) and self:IsReachBreakthroughLevel(equipId)
end

-- 设置角色装备Id
function XEquipModel:SetCharacterEquipId(characterId, equipId)
    if characterId == 0 then
        return
    end

    local equipIdDic = self.CharacterEquipIdDic[characterId]
    if not equipIdDic then
        equipIdDic = {}
        self.CharacterEquipIdDic[characterId] = equipIdDic
    end

    local equip = self:GetEquip(equipId)
    local equipSite = self:GetEquipSite(equip.TemplateId)
    equipIdDic[equipSite] = equipId
end

-- 移除角色装备Id
function XEquipModel:RemoveCharacterEquipId(characterId, equipId)
    local equipIdDic = self.CharacterEquipIdDic[characterId]
    if not equipIdDic then
        XLog.Warning(string.format("XEquipModel:RemoveCharacterEquipId 缓存角色装备数据的 characterId:%s 没有equipId:%s", characterId, equipId))
        return
    end

    local equip = self:GetEquip(equipId)
    local equipSite = self:GetEquipSite(equip.TemplateId)
    equipIdDic[equipSite] = nil
end

--- 获取成员对应部位的装备Id
---@param characterId number 成员Id
---@param site number 装备部位
function XEquipModel:GetCharacterEquipId(characterId, site)
    local equipIdDic = self.CharacterEquipIdDic[characterId]
    return equipIdDic and equipIdDic[site] or nil
end

--- 获取成员对应部位的装备实例
---@param characterId number 成员Id
---@param site number 装备部位
function XEquipModel:GetCharacterEquip(characterId, site)
    local equipId = self:GetCharacterEquipId(characterId, site)
    if equipId then
        return self:GetEquip(equipId)
    end
end

--- 获取成员身上的所有装备Id列表
---@param characterId number 成员Id
---@param isUseTempList table 是否使用复用的临时列表
function XEquipModel:GetCharacterEquipIds(characterId, isUseTempList)
    if isUseTempList then
        self.TempList = {}
    end
    local equipIds = isUseTempList and self.TempList or {}
    local equipIdDic = self.CharacterEquipIdDic[characterId]
    if equipIdDic then
        for _, equipId in pairs(equipIdDic) do
            table.insert(equipIds, equipId)
        end
    end
    return equipIds
end

--- 获取成员身上的所有装备实例
---@param characterId number 成员Id
---@param isUseTempList table 是否使用复用的临时列表
function XEquipModel:GetCharacterEquips(characterId, isUseTempList)
    if isUseTempList then
        self.TempList = {}
    end
    local equips = isUseTempList and self.TempList or {}
    local equipIdDic = self.CharacterEquipIdDic[characterId]
    if equipIdDic then
        for _, equipId in pairs(equipIdDic) do
            local equip = self:GetEquip(equipId)
            table.insert(equips, equip)
        end
    end
    return equips
end

--- 获取成员的武器Id
---@param characterId number 成员Id
function XEquipModel:GetCharacterWeaponId(characterId)
    return self:GetCharacterEquipId(characterId, XEnumConst.EQUIP.EQUIP_SITE.WEAPON)
end

--- 获取成员的武器实例
---@param characterId number 成员Id
function XEquipModel:GetCharacterWeapon(characterId)
    local equipId = self:GetCharacterWeaponId(characterId)
    return self:GetEquip(equipId)
end

--- 获取成员的意识Id列表
---@param characterId number 成员Id
---@param isUseTempList table 是否使用复用的临时列表
function XEquipModel:GetCharacterAwarenessIds(characterId, isUseTempList)
    if isUseTempList then
        self.TempList = {}
    end
    local equipIds = isUseTempList and self.TempList or {}
    local equipIdDic = self.CharacterEquipIdDic[characterId]
    if equipIdDic then
        local awarenessOne = XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.ONE
        local awarenessSix = XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.SIX
        for site, equipId in pairs(equipIdDic) do
            if site >= awarenessOne and site <= awarenessSix then
                table.insert(equipIds, equipId)
            end
        end
    end
    return equipIds
end

--- 获取成员穿戴的意识数量
---@param characterId number 成员Id
function XEquipModel:GetCharacterAwarenessCnt(characterId)
    local count = 0
    local equipIdDic = self.CharacterEquipIdDic[characterId]
    if equipIdDic then
        local awarenessOne = XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.ONE
        local awarenessSix = XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.SIX
        for site, equipId in pairs(equipIdDic) do
            if site >= awarenessOne and site <= awarenessSix then
                count = count + 1
            end
        end
    end
    return count
end

--- 是否拥有这件装备
function XEquipModel:IsOwnEquip(templateId)
    for _, equip in pairs(self.EquipDic) do
        if equip.TemplateId == templateId then
            return true
        end
    end
    return  false
end

--- 根据套装Id获取已拥有装备Id列表
function XEquipModel:GetEquipIdsBySuitId(suitId, site)
    if suitId == XEnumConst.EQUIP.DEFAULT_SUIT_ID.NORMAL then
        return self:GetAwarenessIds(XEnumConst.CHARACTER.CharacterType.Normal)
    elseif suitId == XEnumConst.EQUIP.DEFAULT_SUIT_ID.ISOMER then
        return self:GetAwarenessIds(XEnumConst.CHARACTER.CharacterType.Isomer)
    end

    local equipIds = {}
    for _, equip in pairs(self.EquipDic) do
        if suitId == equip:GetSuitId() then
            if type(site) ~= "number" or equip:GetSite() == site then
                table.insert(equipIds, equip.Id)
            end
        end
    end
    return equipIds
end

function XEquipModel:GetEquipCountInSuit(suitId, site)
    return #self:GetEquipIdsBySuitId(suitId, site)
end

function XEquipModel:GetEquipCount(templateId)
    local count = 0
    for _, v in pairs(self.EquipDic) do
        if v.TemplateId == templateId then
            count = count + 1
        end
    end
    return count
end

function XEquipModel:GetFirstEquip(templateId)
    for _, v in pairs(self.EquipDic) do
        if v.TemplateId == templateId then
            return v
        end
    end
end

--- 获取装备的突破次数
function XEquipModel:GetEquipBreakthroughTimes(equipId)
    if self:IsEquipExit(equipId) then
        local equip = self:GetEquip(equipId)
        return equip.Breakthrough
    end
    return 0
end

--- 获取装备的共鸣次数
function XEquipModel:GetEquipResonanceCount(equipId)
    if self:IsEquipExit(equipId) then
        local equip = self:GetEquip(equipId)
        return equip:GetResonanceCount()
    end
    return 0
end

--- @desc 通过templateId获取背包中或目标角色身上的装备
function XEquipModel:GetEnableEquipIdsByTemplateId(templateId, targetCharacterId)
    local equipIds = {}
    for id, equip in pairs(self.EquipDic) do
        if equip.TemplateId == templateId and (equip.CharacterId <= 0 or equip.CharacterId == targetCharacterId) then
            table.insert(equipIds, id)
        end
    end
    return equipIds
end

--- @desc 目标装备是否可用（未被其他角色装备）
function XEquipModel:IsEquipActive(templateId, characterId)
    for id, equip in pairs(self.EquipDic) do
        if equip.TemplateId == templateId and (equip.CharacterId <= 0 or equip.CharacterId == characterId) then
            return true
        end
    end
    return false
end

--- @desc: 获取所有武器equipId
function XEquipModel:GetWeaponIds()
    local weaponIds = {}
    for equipId, equip in pairs(self.EquipDic) do
        if equip:IsWeapon() then
            table.insert(weaponIds, equipId)
        end
    end
    return weaponIds
end

function XEquipModel:GetWeaponCount()
    local weaponIds = self:GetWeaponIds()
    return weaponIds and #weaponIds or 0
end

--- @desc: 获取符合当前角色使用类型的所有武器equipId
function XEquipModel:GetCanUseWeaponIds(characterId)
    local weaponIds = {}
    local requireEquipType = XMVCA.XCharacter:GetCharacterEquipType(characterId)
    for k, v in pairs(self.EquipDic) do
        if self:IsClassifyEqualByEquipId(v.Id, XEnumConst.EQUIP.CLASSIFY.WEAPON) and self:IsTypeEqual(v.Id, requireEquipType) then
            table.insert(weaponIds, k)
        end
    end
    return weaponIds
end

--desc: 获取符合当前角色使用类型的所有武器templateId
function XEquipModel:GetCanUseWeaponTemplateIds(characterId)
    local weaponTemplateIds = {}
    local requireEquipType = XMVCA.XCharacter:GetCharacterEquipType(characterId)
    local equipTemplates = self:GetConfigEquip()
    for _, v in pairs(equipTemplates) do
        if self:IsClassifyEqualByTemplateId(v.Id, XEnumConst.EQUIP.CLASSIFY.WEAPON) and v.Type == requireEquipType then
            table.insert(weaponTemplateIds, v.Id)
        end
    end
    return weaponTemplateIds
end

--- @desc: 获取符合当前武器使用角色的所有templateId
function XEquipModel:GetWeaponUserTemplateIds(weaponTemplateIds)
    local characters = XMVCA.XCharacter:GetCharacterTemplates()
    local canUesCharacters = {}
    for _, character in pairs(characters) do
        local weaponIds = self:GetCanUseWeaponTemplateIds(character.Id)
        for _, weaponId in pairs(weaponIds) do
            if weaponTemplateIds == weaponId then
                table.insert(canUesCharacters, character)
            end
        end
    end
    return canUesCharacters
end

--- @desc: 获取所有意识
function XEquipModel:GetAwarenessIds(characterType)
    local awarenessIds = {}
    for equipId, equip in pairs(self.EquipDic) do
        if equip:IsAwareness() and (not characterType or self:IsCharacterTypeFit(equipId, characterType)) then
            table.insert(awarenessIds, equipId)
        end
    end
    return awarenessIds
end

function XEquipModel:GetAwarenessCount(characterType)
    local awarenessIds = self:GetAwarenessIds(characterType)
    return awarenessIds and #awarenessIds or 0
end

function XEquipModel:GetCanDecomposeWeaponIds()
    local weaponIds = {}
    for k, v in pairs(self.EquipDic) do
        if v:IsWeapon() and not self:IsWearing(v.Id) and not self:IsLock(v.Id) then
            table.insert(weaponIds, k)
        end
    end
    return weaponIds
end

function XEquipModel:GetCanDecomposeAwarenessIdsBySuitId(suitId)
    local awarenessIds = {}
    local equipIds = self:GetEquipIdsBySuitId(suitId)
    for _, equipId in pairs(equipIds) do
        local templeteId = self:GetEquipTemplateId(equipId)
        if self:IsEquipAwareness(templeteId) and not self:IsWearing(equipId) and not self:IsInSuitPrefab(equipId) and not self:IsLock(equipId) then
            table.insert(awarenessIds, equipId)
        end
    end

    return awarenessIds
end

function XEquipModel:GetSuitIdsByStars(starCheckList)
    local suitIds = {}
    local doNotRepeatSuitIds = {}
    local equipIds = self:GetAwarenessIds()
    for _, equipId in pairs(equipIds) do
        local templateId = self:GetEquipTemplateId(equipId)
        local star = self:GetEquipStar(templateId)
        if starCheckList[star] then
            local suitId = self:GetEquipSuitIdByEquipId(equipId)
            if suitId > 0 then
                doNotRepeatSuitIds[suitId] = true
            end
        end
    end

    for suitId in pairs(doNotRepeatSuitIds) do
        table.insert(suitIds, suitId)
    end

    --展示排序:构造体〉感染体〉通用
    local UserTypeSortPriority = {
        [XEnumConst.EQUIP.USER_TYPE.ALL] = 1,
        [XEnumConst.EQUIP.USER_TYPE.ISOMER] = 2,
        [XEnumConst.EQUIP.USER_TYPE.NORMAL] = 3
    }
    table.sort(suitIds, function(lSuitID, rSuitID)
        local lStar = self:GetSuitStar(lSuitID)
        local rStar = self:GetSuitStar(rSuitID)
        if lStar ~= rStar then
            return lStar > rStar
        end

        local aCharacterType = self:GetSuitCharacterType(lSuitID)
        local bCharacterType = self:GetSuitCharacterType(rSuitID)
        if aCharacterType ~= bCharacterType then
            return UserTypeSortPriority[aCharacterType] > UserTypeSortPriority[bCharacterType]
        end
    end)

    table.insert(suitIds, 1, XEnumConst.EQUIP.DEFAULT_SUIT_ID.NORMAL)
    table.insert(suitIds, 2, XEnumConst.EQUIP.DEFAULT_SUIT_ID.ISOMER)

    return suitIds
end

--- 是否能作为师徒系统的礼物
function XEquipModel:IsCanBeGift(equipId)
    local IsNotWearing = not self:IsWearing(equipId)
    local IsNotInSuit = not self:IsInSuitPrefab(equipId)
    local IsUnLock = not self:IsLock(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    local IsCanGive = not XMentorSystemConfigs.IsCanNotGiveWafer(templateId)
    local equip = self:GetEquip(equipId)
    local resonanCecount = self:GetEquipResonanceCount(equipId)
    local breakthrough = equip and equip.Breakthrough or 0
    local level = equip and equip.Level or 1
    return IsNotWearing and IsNotInSuit and IsUnLock and IsCanGive and resonanCecount == 0 and level == 1 and breakthrough == 0
end

function XEquipModel:ConstructAwarenessStarToSiteToSuitIdsDic(characterType, IsGift)
    local starToSuitIdsDic = {}
    local doNotRepeatSuitIds = {}
    local equipIds = self:GetAwarenessIds(characterType)
    for _, equipId in pairs(equipIds) do
        local templateId = self:GetEquipTemplateId(equipId)
        local star = self:GetEquipStar(templateId)
        doNotRepeatSuitIds[star] = doNotRepeatSuitIds[star] or {}

        local site = self:GetEquipSiteByEquipId(equipId)
        doNotRepeatSuitIds[star][site] = doNotRepeatSuitIds[star][site] or {}
        doNotRepeatSuitIds[star].Total = doNotRepeatSuitIds[star].Total or {}

        local suitId = self:GetEquipSuitIdByEquipId(equipId)
        if suitId > 0 then
            local IsCanBeGift = self:IsCanBeGift(equipId)
            if not IsGift or IsCanBeGift then
                doNotRepeatSuitIds[star][site][suitId] = true
                doNotRepeatSuitIds[star]["Total"][suitId] = true
            end
        end
    end

    for star = 1, XEnumConst.EQUIP.MAX_STAR_COUNT do
        starToSuitIdsDic[star] = {}
        for _, site in pairs(XEnumConst.EQUIP.EQUIP_SITE.AWARENESS) do
            starToSuitIdsDic[star][site] = {}

            if doNotRepeatSuitIds[star] and doNotRepeatSuitIds[star][site] then
                for suitId in pairs(doNotRepeatSuitIds[star][site]) do
                    table.insert(starToSuitIdsDic[star][site], suitId)
                end
            end
        end

        starToSuitIdsDic[star].Total = {}
        if doNotRepeatSuitIds[star] then
            for suitId in pairs(doNotRepeatSuitIds[star]["Total"]) do
                table.insert(starToSuitIdsDic[star]["Total"], suitId)
            end
        end
    end

    return starToSuitIdsDic
end

function XEquipModel:ConstructAwarenessSiteToEquipIdsDic(characterType, IsGift)
    local siteToEquipIdsDic = {}
    for _, site in pairs(XEnumConst.EQUIP.EQUIP_SITE.AWARENESS) do
        siteToEquipIdsDic[site] = {}
    end

    local equipIds = self:GetAwarenessIds(characterType)
    for _, equipId in pairs(equipIds) do
        local IsCanBeGift = self:IsCanBeGift(equipId)
        if not IsGift or IsCanBeGift then
            local site = self:GetEquipSiteByEquipId(equipId)
            table.insert(siteToEquipIdsDic[site], equipId)
        end
    end

    return siteToEquipIdsDic
end

function XEquipModel:ConstructAwarenessSuitIdToEquipIdsDic(characterType, IsGift)
    local suitIdToEquipIdsDic = {}

    local equipIds = self:GetAwarenessIds(characterType)
    for _, equipId in pairs(equipIds) do
        local suitId = self:GetEquipSuitIdByEquipId(equipId)
        suitIdToEquipIdsDic[suitId] = suitIdToEquipIdsDic[suitId] or {}

        if suitId > 0 then
            local site = self:GetEquipSiteByEquipId(equipId)
            suitIdToEquipIdsDic[suitId]["Total"] = suitIdToEquipIdsDic[suitId]["Total"] or {}
            suitIdToEquipIdsDic[suitId][site] = suitIdToEquipIdsDic[suitId][site] or {}

            local IsCanBeGift = self:IsCanBeGift(equipId)
            if not IsGift or IsCanBeGift then
                table.insert(suitIdToEquipIdsDic[suitId][site], equipId)
                table.insert(suitIdToEquipIdsDic[suitId]["Total"], equipId)
            end
        end
    end

    return suitIdToEquipIdsDic
end

function XEquipModel:CanEatEquipSort(lEquipId, rEquipId)
    local ltemplateId = self:GetEquipTemplateId(lEquipId)
    local rtemplateId = self:GetEquipTemplateId(rEquipId)
    local lEquip = self:GetEquip(lEquipId)
    local rEquip = self:GetEquip(rEquipId)

    local lStar = self:GetEquipStar(ltemplateId)
    local rStar = self:GetEquipStar(rtemplateId)
    if lStar ~= rStar then
        return lStar < rStar
    end

    local lIsFood = lEquip:IsFood()
    local rIsFood = rEquip:IsFood()
    if lIsFood ~= rIsFood then
        return lIsFood
    end

    if lEquip.Breakthrough ~= rEquip.Breakthrough then
        return lEquip.Breakthrough < rEquip.Breakthrough
    end

    if lEquip.Level ~= rEquip.Level then
        return lEquip.Level < rEquip.Level
    end

    return self:GetEquipPriority(ltemplateId) < self:GetEquipPriority(rtemplateId)
end

function XEquipModel:GetCanEatWeaponIds(equipId)
    local weaponIds = {}
    for k, v in pairs(self.EquipDic) do
        if v.Id ~= equipId and self:IsClassifyEqualByEquipId(v.Id, XEnumConst.EQUIP.CLASSIFY.WEAPON) and
        not self:IsWearing(v.Id) and
        not self:IsLock(v.Id) then
            table.insert(weaponIds, k)
        end
    end
    table.sort(weaponIds, function(a, b)
        return self:CanEatEquipSort(a, b)
    end)
    return weaponIds
end

function XEquipModel:GetCanEatAwarenessIds(equipId)
    local awarenessIds = {}
    for k, v in pairs(self.EquipDic) do
        if v.Id ~= equipId and self:IsClassifyEqualByEquipId(v.Id, XEnumConst.EQUIP.CLASSIFY.AWARENESS) and
        not self:IsWearing(v.Id) and
        not self:IsInSuitPrefab(v.Id) and
        not self:IsLock(v.Id) then
            table.insert(awarenessIds, k)
        end
    end
    table.sort(awarenessIds, function(a, b)
        return self:CanEatEquipSort(a, b)
    end)
    return awarenessIds
end

function XEquipModel:GetCanEatEquipIds(equipId)
    local equipIds = {}
    local equip = self:GetEquip(equipId)
    if equip:IsAwareness() then
        equipIds = self:GetCanEatAwarenessIds(equipId)
    elseif equip:IsWeapon() then
        equipIds = self:GetCanEatWeaponIds(equipId)
    end
    return equipIds
end

function XEquipModel:GetCanEatItemIds(equipId)
    local itemIds = {}

    local equipClassify = self:GetEquipClassifyByEquipId(equipId)
    local items = XDataCenter.ItemManager.GetEquipExpItems(equipClassify)
    for _, item in pairs(items) do
        table.insert(itemIds, item.Id)
    end

    return itemIds
end

function XEquipModel:GetResonanceSkillNum(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    return self:GetResonanceSkillNumByTemplateId(templateId)
end

function XEquipModel:GetResonanceSkillNumByTemplateId(templateId)
    local count = 0
    local equipResonanceCfg = self:GetConfigEquipResonance(templateId)
    if not equipResonanceCfg then
        return count
    end

    for pos = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
        if equipResonanceCfg.WeaponSkillPoolId and equipResonanceCfg.WeaponSkillPoolId[pos] and equipResonanceCfg.WeaponSkillPoolId[pos] > 0 then
            count = count + 1
        elseif equipResonanceCfg.AttribPoolId and equipResonanceCfg.AttribPoolId[pos] and equipResonanceCfg.AttribPoolId[pos] > 0 then
            count = count + 1
        elseif equipResonanceCfg.CharacterSkillPoolId and equipResonanceCfg.CharacterSkillPoolId[pos] and equipResonanceCfg.CharacterSkillPoolId[pos] > 0 then
            count = count + 1
        end
    end

    return count
end

function XEquipModel:GetResonanceSkillInfo(equipId, pos)
    local skillInfo = {}
    local equip = self:GetEquip(equipId)
    if equip.ResonanceInfo and equip.ResonanceInfo[pos] then
        local XSkillInfoObj = require("XEntity/XEquip/XSkillInfoObj")
        skillInfo = XSkillInfoObj.New(equip.ResonanceInfo[pos].Type, equip.ResonanceInfo[pos].TemplateId)
    end

    return skillInfo
end

function XEquipModel:GetResonanceSkillInfoByEquipData(equip, pos)
    local skillInfo = {}
    if equip.ResonanceInfo and equip.ResonanceInfo[pos] then
        local XSkillInfoObj = require("XEntity/XEquip/XSkillInfoObj")
        skillInfo = XSkillInfoObj.New(equip.ResonanceInfo[pos].Type, equip.ResonanceInfo[pos].TemplateId)
    end

    return skillInfo
end

function XEquipModel:GetResonanceBindCharacterId(equipId, pos)
    local equip = self:GetEquip(equipId)
    return equip.ResonanceInfo and equip.ResonanceInfo[pos] and equip.ResonanceInfo[pos].CharacterId or 0
end

function XEquipModel:GetResonanceBindCharacterIdByEquipData(equip, pos)
    return equip.ResonanceInfo and equip.ResonanceInfo[pos] and equip.ResonanceInfo[pos].CharacterId or 0
end

function XEquipModel:GetEquipAddExp(equipId, count)
    count = count or 1
    local exp

    local equip = self:GetEquip(equipId)
    local levelUpCfg = self:GetLevelUpCfg(equip.TemplateId, equip.Breakthrough, equip.Level)
    local offerExp = self:GetEquipBreakthroughExp(equipId)

    --- 获得经验 = 装备已培养经验 * 继承比例 + 突破提供的经验
    exp = equip.Exp + levelUpCfg.AllExp
    exp = exp * self:GetEquipExpInheritPercent() / 100
    exp = exp + offerExp

    return exp * count
end

--- 根据意识id 获得对应的公约加成描述字符串
function XEquipModel:GetEquipAwarenessOccupyHarmDesc(equipId, forceNum)
    local str = ""
    if XTool.IsNumberValid(equipId) then
        local curr = 0
        for i = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
            local awaken = self:IsEquipPosAwaken(equipId, i)
            if awaken then
                curr = curr + 1
            end
        end
        
        local equipData = self:GetEquip(equipId)
        if curr > 0 then
            local awakeCfg = self:GetConfigEquipAwake(equipData.TemplateId)
            str = awakeCfg.AwarenessAttrDesc..((forceNum or curr) * awakeCfg.AwarenessAttrValue).."%"
        end
    end
    return str
end

--- 狗粮
function XEquipModel:IsEquipRecomendedToBeEat(strengthenEquipId, equipId, doNotLimitStar)
    if not equipId then
        return false
    end
    local equip = self:GetEquip(equipId)
    local equipClassify = self:GetEquipClassifyByEquipId(strengthenEquipId)
    local canNotAutoEatStar = not doNotLimitStar and XEnumConst.EQUIP.CAN_NOT_AUTO_EAT_STAR

    if self:GetEquipClassifyByEquipId(equipId) == equipClassify and --武器吃武器，意识吃意识
            not self:IsWearing(equipId) and --不能吃穿戴中
            not self:IsInSuitPrefab(equipId) and --不能吃预设中
            not self:IsLock(equipId) and --不能吃上锁中
            (not canNotAutoEatStar or self:GetEquipStar(equip.TemplateId) < canNotAutoEatStar) and --不自动吃大于该星级的装备
            equip.Breakthrough == 0 and --不吃突破过的
            equip.Level == 1 and
            equip.Exp == 0 and --不吃强化过的
            not equip.ResonanceInfo and
            not equip.UnconfirmedResonanceInfo
     then --不吃共鸣过的
        return true
    end

    return false
end

function XEquipModel:CanResonance(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    local star = self:GetEquipStar(templateId)
    return star >= XEnumConst.EQUIP.MIN_RESONANCE_EQUIP_STAR_COUNT
end

function XEquipModel:CanResonanceByTemplateId(templateId)
    local resonanceSkillNum = self:GetResonanceSkillNumByTemplateId(templateId)
    return resonanceSkillNum > 0
end

function XEquipModel:CanResonanceBindCharacter(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    local star = self:GetEquipStar(templateId)
    return star >= self:GetMinResonanceBindStar()
end

function XEquipModel:CheckEquipPosResonanced(equipId, pos)
    local equip = self:GetEquip(equipId)
    return equip.ResonanceInfo and equip.ResonanceInfo[pos]
end

--装备是否共鸣过
function XEquipModel:IsEquipResonanced(equipId)
    local equip = self:GetEquip(equipId)
    return equip and not XTool.IsTableEmpty(equip.ResonanceInfo) or
        not XTool.IsTableEmpty(equip.UnconfirmedResonanceInfo)
end

function XEquipModel:CheckEquipStarCanAwake(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    local star = self:GetEquipStar(templateId)
    if star < self:GetMinAwakeStar() then
        return false
    end
    return true
end

function XEquipModel:CheckEquipCanAwake(equipId, pos)
    if not self:CheckEquipStarCanAwake(equipId) then
        return false
    end

    local templateId = self:GetEquipTemplateId(equipId)
    local maxBreakthrough, maxLevel = self:GetEquipMaxBreakthrough(templateId)
    local equip = self:GetEquip(equipId)
    if equip.Level ~= maxLevel then
        return false
    end

    if not self:CheckEquipPosResonanced(equipId, pos) then
        return false
    end

    return true
end

function XEquipModel:IsEquipAwaken(equipId)
    for pos = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
        if self:IsEquipPosAwaken(equipId, pos) then
            return true
        end
    end
    return false
end

function XEquipModel:GetEquipAwakeNum(equipId)
    local num = 0
    for pos = 1, XEnumConst.EQUIP.MAX_AWAKE_COUNT  do
        if self:IsEquipPosAwaken(equipId, pos) then
            num = num + 1
        end
    end
    return num
end

function XEquipModel:IsEquipPosAwaken(equipId, pos)
    local equip = self:GetEquip(equipId)
    return equip:IsEquipPosAwaken(pos)
end

function XEquipModel:IsFiveStar(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    local quality = self:GetEquipQuality(templateId)
    return quality == XEnumConst.EQUIP.MIN_RESONANCE_EQUIP_STAR_COUNT
end

function XEquipModel:IsCharacterTypeFit(equipId, characterType)
    local templateId = self:GetEquipTemplateId(equipId)
    return self:IsCharacterTypeFitByTemplateId(templateId, characterType)
end

function XEquipModel:IsCharacterTypeFitByTemplateId(templateId, characterType)
    local configCharacterType = self:GetEquipCharacterType(templateId)
    return configCharacterType == XEnumConst.EQUIP.USER_TYPE.ALL or configCharacterType == characterType
end

function XEquipModel:IsTypeEqual(equipId, equipType)
    local equip = self:GetEquip(equipId)
    return equip:GetType() == XEnumConst.EQUIP.EQUIP_TYPE.UNIVERSAL or equipType and equipType == equip:GetType()
end
---------------------------------------- #endregion 装备 ----------------------------------------


---------------------------------------- #region 意识组合 ----------------------------------------
--- 初始化意识组合预设
function XEquipModel:InitEquipChipGroupList(data)
    self.AwarenessSuitPrefabInfoList = {}
    local XEquipSuitPrefab = require("XEntity/XEquip/XEquipSuitPrefab")
    for _, chipGroupData in ipairs(data.ChipGroupDataList) do
        table.insert(self.AwarenessSuitPrefabInfoList, XEquipSuitPrefab.New(chipGroupData))
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
end

function XEquipModel:GetSuitPrefabIndexList(characterType)
    local prefabIndexList = {}
    for index, suitPrefab in pairs(self.AwarenessSuitPrefabInfoList) do
        if not characterType or suitPrefab:GetCharacterType() == characterType then
            table.insert(prefabIndexList, index)
        end
    end
    return prefabIndexList
end

function XEquipModel:GetSuitPrefabInfo(index)
    return index and self.AwarenessSuitPrefabInfoList[index]
end

function XEquipModel:SaveSuitPrefabInfo(equipGroupData)
    local XEquipSuitPrefab = require("XEntity/XEquip/XEquipSuitPrefab")
    table.insert(self.AwarenessSuitPrefabInfoList, XEquipSuitPrefab.New(equipGroupData))
end

function XEquipModel:DeleteSuitPrefabInfo(index)
    if not index then
        return
    end
    table.remove(self.AwarenessSuitPrefabInfoList, index)
end

function XEquipModel:GetUnSavedSuitPrefabInfo(characterId)
    local equipGroupData = {
        Name = "",
        ChipIdList = self:GetCharacterAwarenessIds(characterId)
    }
    local XEquipSuitPrefab = require("XEntity/XEquip/XEquipSuitPrefab")
    return XEquipSuitPrefab.New(equipGroupData)
end

function XEquipModel:IsInSuitPrefab(equipId)
    if not equipId then
        return false
    end
    for _, suitPrefabInfo in pairs(self.AwarenessSuitPrefabInfoList) do
        if suitPrefabInfo:IsEquipIn(equipId) then
            return true
        end
    end
    return false
end
---------------------------------------- #endregion 意识组合 ----------------------------------------


---------------------------------------- #region 装备回收 ----------------------------------------

function XEquipModel:UpdateAwarenessRecycleInfo(recycleInfo)
    if XTool.IsTableEmpty(recycleInfo) then
        return
    end

    local starDic = {}
    for _, star in pairs(recycleInfo.RecycleStar or {}) do
        starDic[star] = true
    end
    self.AwarenessRecycleInfo.StarCheckDic = starDic
    self.AwarenessRecycleInfo.Days = recycleInfo.Days or 0
end

function XEquipModel:GetRecycleStarCheckDic()
    return XTool.Clone(self.AwarenessRecycleInfo.StarCheckDic)
end

function XEquipModel:GetRecycleSettingDays()
    return self.AwarenessRecycleInfo.Days or 0
end

function XEquipModel:CheckRecycleInfoDifferent(starCheckDic, days)
    if days ~= self.AwarenessRecycleInfo.Days then
        return true
    end

    for star, value in pairs(starCheckDic) do
        if value and not self.AwarenessRecycleInfo.StarCheckDic[star] then
            return true
        end
    end

    for star, value in pairs(self.AwarenessRecycleInfo.StarCheckDic) do
        if value and not starCheckDic[star] then
            return true
        end
    end

    return false
end

function XEquipModel:IsSetRecycleNeedConfirm(equipId)
    if self:IsHaveRecycleCookie() then
        return false
    end
    local equip = self:GetEquip(equipId)
    return equip and self:GetEquipStar(equip.TemplateId) == XEnumConst.EQUIP.CAN_NOT_AUTO_EAT_STAR
end

function XEquipModel:GetRecycleCookieKey()
    return XPlayer.Id .. "IsHaveRecycleCookie"
end

function XEquipModel:IsHaveRecycleCookie()
    local key = self:GetRecycleCookieKey()
    local updateTime = XSaveTool.GetData(key)
    if not updateTime then
        return false
    end
    return XTime.GetServerNowTimestamp() < updateTime
end

function XEquipModel:SetRecycleCookie(isSelect)
    local key = self:GetRecycleCookieKey()
    if not isSelect then
        XSaveTool.RemoveData(key)
    else
        if self:IsHaveRecycleCookie() then
            return
        end
        local updateTime = XTime.GetSeverTomorrowFreshTime()
        XSaveTool.SaveData(key, updateTime)
    end
end

--- 装备是否待回收
function XEquipModel:IsRecycle(equipId)
    if not equipId then
        return false
    end
    local equip = self:GetEquip(equipId)
    if not equip then
        return false
    end
    return equip.IsRecycle
end

--- 装备是否可回收
function XEquipModel:IsEquipCanRecycle(equipId)
    if not equipId then
        return false
    end
    local equip = self:GetEquip(equipId)
    if not equip then
        return false
    end

    local equipId = equip.Id
    return self:IsClassifyEqualByEquipId(equipId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) and --是意识（后续开放武器回收）
        self:GetEquipStar(equip.TemplateId) <= XEnumConst.EQUIP.CAN_NOT_AUTO_EAT_STAR and --星级≤5
        equip.Breakthrough == 0 and --无突破
        equip.Level == 1 and
        equip.Exp == 0 and --无强化
        not equip.ResonanceInfo and
        not equip.UnconfirmedResonanceInfo and --无共鸣
        not self:IsEquipAwaken(equipId) and --无觉醒
        not self:IsWearing(equipId) and --未被穿戴
        not self:IsInSuitPrefab(equipId) and --未被预设在意识组合中
        not self:IsLock(equipId) --未上锁
end

function XEquipModel:GetCanRecycleWeaponIds()
    local weaponIds = {}
    for k, v in pairs(self.EquipDic) do
        local equipId = v.Id
        if self:IsClassifyEqualByEquipId(equipId, XEnumConst.EQUIP.CLASSIFY.WEAPON) and self:IsEquipCanRecycle(equipId) then
            table.insert(weaponIds, k)
        end
    end
    return weaponIds
end

function XEquipModel:GetCanRecycleAwarenessIds(suitId)
    local awarenessIds = {}
    local equipIds = self:GetEquipIdsBySuitId(suitId)
    for _, equipId in pairs(equipIds) do
        if self:IsClassifyEqualByEquipId(equipId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) and self:IsEquipCanRecycle(equipId) then
            table.insert(awarenessIds, equipId)
        end
    end

    return awarenessIds
end

function XEquipModel:GetRecycleRewards(equipIds)
    local itemInfoList = {}
    local totalExp = 0
    for _, equipId in pairs(equipIds) do
        local addExp = self:GetEquipAddExp(equipId)
        totalExp = totalExp + addExp
    end
    if totalExp == 0 then
        return itemInfoList
    end

    local precent = self:GetEquipRecycleItemPercent()
    local itemInfo = {
        TemplateId = XDataCenter.ItemManager.ItemId.EquipRecycleItemId,
        Count = math.floor(precent * totalExp)
    }
    table.insert(itemInfoList, itemInfo)

    return itemInfoList
end
---------------------------------------- #endregion 装备回收 ----------------------------------------

--============================================================== #endregion 协议数据 ==============================================================




--============================================================== #region 配置表 ==============================================================

function XEquipModel:InitConfig()
    self._ConfigUtil:InitConfigByTableKey("Equip", TableKey)
    self._ConfigUtil:InitConfigByTableKey("Equip/EquipGuide", EquipGuideTableKey)

    self:InitEquipLevelUpConfig()
    self:InitWeaponSkillPoolConfig()
    self:InitEquipModelTransformConfig()
    self:InitEquipAnimResetConfig()
end

---------------------------------------- #region Equip ----------------------------------------
function XEquipModel:GetConfigEquip(templateId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.Equip)
    if templateId then
        if cfgs[templateId] then
            return cfgs[templateId]
        else
            XLog.Error("请检查配置表Share/Equip/Equip.tab，未配置行Id = " .. tostring(templateId))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipText(id)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.EquipText, id)
    return cfg and cfg.Text or ""
end

function XEquipModel:CheckTemplateIdIsEquip(templateId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.Equip)
    return cfgs[templateId] ~= nil
end

function XEquipModel:GetEquipName(templateId)
    local config = self:GetConfigEquip(templateId)
    if config then
        return self:GetConfigEquipText(config.Name)
    else
        return ""    
    end
end

function XEquipModel:GetEquipSite(templateId)
    local config = self:GetConfigEquip(templateId)
    return config and config.Site or 0
end

function XEquipModel:GetEquipSiteByEquipId(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    return self:GetEquipSite(templateId)
end

function XEquipModel:GetEquipSiteByEquip(equip)
    return self:GetEquipSite(equip.TemplateId)
end

function XEquipModel:GetEquipType(templateId)
    local config = self:GetConfigEquip(templateId)
    return config and config.Type or 0
end

function XEquipModel:GetEquipQuality(templateId)
    local config = self:GetConfigEquip(templateId)
    return config and config.Quality or 0
end

function XEquipModel:GetEquipStar(templateId)
    local config = self:GetConfigEquip(templateId)
    return config and config.Star or 0
end

function XEquipModel:GetEquipWeaponSkillId(templateId)
    local config = self:GetConfigEquip(templateId)
    return config and config.WeaponSkillId or 0
end

function XEquipModel:GetEquipWeaponSkillInfo(templateId)
    local weaponSkillId = self:GetEquipWeaponSkillId(templateId)
    if not weaponSkillId then
        XLog.ErrorTableDataNotFound("XEquipModel:GetEquipWeaponSkillInfo", "weaponSkillId", "Share/Equip/Equip.tab", "templateId", tostring(templateId))
        return
    end

    local XSkillInfoObj = require("XEntity/XEquip/XSkillInfoObj")
    return XSkillInfoObj.New(XEnumConst.EQUIP.RESONANCE_TYPE.WEAPON_SKILL, weaponSkillId)
end

function XEquipModel:GetEquipPriority(templateId)
    local config = self:GetConfigEquip(templateId)
    return config and config.Priority or 0
end

--专属角色Id
function XEquipModel:GetEquipSpecialCharacterIdByEquipId(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    return self:GetEquipSpecialCharacterId(templateId)
end

function XEquipModel:GetEquipSpecialCharacterId(templateId)
    local config = self:GetConfigEquip(templateId)
    if config and config.CharacterId > 0 then
        return config.CharacterId
    end
end

function XEquipModel:GetEquipSuitIdByEquipId(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    return self:GetEquipSuitId(templateId)
end

function XEquipModel:GetEquipSuitId(templateId)
    local config = self:GetConfigEquip(templateId)
    return config and config.SuitId or 0
end

function XEquipModel:GetEquipCharacterType(templateId)
    local config = self:GetConfigEquip(templateId)
    return config and config.CharacterType or 0
end

function XEquipModel:GetEquipDescription(templateId)
    local config = self:GetConfigEquip(templateId)
    if config then
        return self:GetConfigEquipText(config.Description)
    else
        return ""
    end
end

function XEquipModel:GetEquipNeedFirstShow(templateId)
    local config = self:GetConfigEquip(templateId)
    return config and config.NeedFirstShow or 0
end

--- 装备是否是武器
function XEquipModel:IsEquipWeapon(templateId)
    local equipSite = self:GetEquipSite(templateId)
    local isWeapon = equipSite == XEnumConst.EQUIP.EQUIP_SITE.WEAPON
    return isWeapon
end

--- 装备是否是意识
function XEquipModel:IsEquipAwareness(templateId, site)
    local equipSite = self:GetEquipSite(templateId)
    if site then
        return equipSite == site
    else
        local isAwareness = equipSite >= XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.ONE and equipSite <= XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.SIX
        return isAwareness
    end
end

--- 获取装备的品质图
function XEquipModel:GetEquipQualityPath(templateId)
    local quality = self:GetEquipQuality(templateId)
    return XArrangeConfigs.GeQualityPath(quality)
end

--- 获取装备的背景图
function XEquipModel:GetEquipBgPath(templateId)
    if not self:CheckTemplateIdIsEquip(templateId) then return end
    local quality = self:GetEquipQuality(templateId)
    return XArrangeConfigs.GeQualityBgPath(quality)
end

function XEquipModel:GetEquipClassifyByTemplateId(templateId)
    if not self:CheckTemplateIdIsEquip(templateId) then
        return
    end
    local equipSite = self:GetEquipSite(templateId)
    if equipSite == XEnumConst.EQUIP.EQUIP_SITE.WEAPON then
        return XEnumConst.EQUIP.CLASSIFY.WEAPON
    else
        return XEnumConst.EQUIP.CLASSIFY.AWARENESS
    end
end

function XEquipModel:GetEquipClassifyByEquipId(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    return self:GetEquipClassifyByTemplateId(templateId)
end

function XEquipModel:IsClassifyEqualByTemplateId(templateId, classify)
    local equipClassify = self:GetEquipClassifyByTemplateId(templateId)
    return classify and equipClassify and classify == equipClassify
end

function XEquipModel:IsClassifyEqualByEquipId(equipId, classify)
    local templateId = self:GetEquipTemplateId(equipId)
    return self:IsClassifyEqualByTemplateId(templateId, classify)
end
---------------------------------------- #endregion Equip ----------------------------------------


---------------------------------------- #region EquipBreakthrough ----------------------------------------
-- 初始化突破表
function XEquipModel:InitEquipBreakthroughConfig()
    self.EquipBreakthroughTemplate = {}
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipBreakThrough)
    for _, config in pairs(cfgs) do
        if not self.EquipBreakthroughTemplate[config.EquipId] then
            self.EquipBreakthroughTemplate[config.EquipId] = {}
        end

        if config.AttribPromotedId == 0 then
            XLog.ErrorTableDataNotFound("XEquipModel:InitEquipBreakthroughConfig", "self.EquipBreakthroughTemplate", "Share/Equip/EquipBreakThrough.tab = ",
                    "config.EquipId", tostring(config.EquipId))
        end

        self.EquipBreakthroughTemplate[config.EquipId][config.Times] = config
    end
end

-- 获取装备的突破配置表列表
function XEquipModel:GetEquipBreakthroughCfgs(templateId)
    if not self.EquipBreakthroughTemplate then 
        self:InitEquipBreakthroughConfig()
    end

    local cfgs = self.EquipBreakthroughTemplate[templateId]
    if not cfgs then
        XLog.ErrorTableDataNotFound("XEquipModel:GetEquipBreakthroughCfg", "cfgs", "Share/Equip/EquipBreakThrough.tab", "templateId", tostring(templateId))
    end
    return cfgs
end

-- 获取装备突破次数对应的配置表
function XEquipModel:GetEquipBreakthroughCfg(templateId, times)
    times = times or 0
    local cfgs = self:GetEquipBreakthroughCfgs(templateId)
    local config = cfgs[times]
    if not config then
        XLog.ErrorTableDataNotFound("XEquipModel:GetEquipBreakthroughCfg", "config", "Share/Equip/EquipBreakThrough.tab", "templateId : times", 
            tostring(templateId) .. " : " .. tostring(times))
        return
    end

    return config
end

--- 获取装备当前突破等级对应配置表
function XEquipModel:GetEquipBreakthroughCfgByEquipId(equipId)
    local equip = self:GetEquip(equipId)
    return self:GetEquipBreakthroughCfg(equip.TemplateId, equip.Breakthrough)
end

--- 获取装备下一突破等级对应配置表
function XEquipModel:GetEquipNextBreakthroughCfgByEquipId(equipId)
    local equip = self:GetEquip(equipId)
    return self:GetEquipBreakthroughCfg(equip.TemplateId, equip.Breakthrough + 1)
end

--- 获取指定突破次数下最大等级限制
function XEquipModel:GetEquipBreakthroughLevelLimit(templateId, times)
    local equipBreakthroughCfg = self:GetEquipBreakthroughCfg(templateId, times)
    return equipBreakthroughCfg.LevelLimit
end

function XEquipModel:GetEquipBreakthroughLevelLimitByEquipId(equipId)
    local equip = self:GetEquip(equipId)
    return self:GetEquipBreakthroughLevelLimit(equip.TemplateId, equip.Breakthrough)
end

function XEquipModel:GetBreakthroughUseMoney(equipId)
    local equipBreakthroughCfg = self:GetEquipBreakthroughCfgByEquipId(equipId)
    return equipBreakthroughCfg.UseMoney
end

function XEquipModel:GetBreakthroughUseItemId(equipId)
    local equipBreakthroughCfg = self:GetEquipBreakthroughCfgByEquipId(equipId)
    return equipBreakthroughCfg.UseItemId
end

function XEquipModel:GetBreakthroughConsumeItems(equipId)
    local consumeItems = {}
    local equipBreakthroughCfg = self:GetEquipBreakthroughCfgByEquipId(equipId)
    for i = 1, #equipBreakthroughCfg.ItemId do
        local item = {
            Id = equipBreakthroughCfg.ItemId[i], 
            Count = equipBreakthroughCfg.ItemCount[i]
        }
        table.insert(consumeItems, item)
    end

    return consumeItems
end

function XEquipModel:GetEquipBreakthroughExp(equipId)
    local equipBreakthroughCfg = self:GetEquipBreakthroughCfgByEquipId(equipId)
    return equipBreakthroughCfg.Exp
end

-- 获取装备的最高突破次数
--- @return number times 最高突破数
--- @return number levelLimit 最高等级
function XEquipModel:GetEquipMaxBreakthrough(templateId)
    local cfgs = self:GetEquipBreakthroughCfgs(templateId)
    if not cfgs then
        return XEnumConst.EQUIP.MIN_BREAKTHROUGH, XEnumConst.EQUIP.MIN_LEVEL
    end

    local times = 0
    local levelLimit = 0
    for _, config in pairs(cfgs) do
        if config.Times >= times then
            times = config.Times
            levelLimit = config.LevelLimit
        end
    end
    return times, levelLimit
end

--- 获取装备突破次数对应图片
function XEquipModel:GetEquipBreakThroughIcon(breakthroughTimes)
    local key = "EquipBreakThrough" .. breakthroughTimes
    return CS.XGame.ClientConfig:GetString(key)
end

function XEquipModel:GetEquipBreakThroughSmallIcon(breakthroughTimes)
    local key = "EquipBreakThroughSmall" .. tostring(breakthroughTimes)
    local icon = CS.XGame.ClientConfig:GetString(key)
    if not icon then
        XLog.Error("XEquipModel:GetEquipBreakThroughSmallIcon调用错误，得到的icon为空，原因：检查breakthroughTimes：" .. breakthroughTimes .. "和Text.tab的" .. key)
        return
    end
    return icon
end

function XEquipModel:GetEquipBreakThroughSmallIconByEquipId(equipId)
    local equip = self:GetEquip(equipId)
    if equip.Breakthrough == 0 then
        return
    end
    return self:GetEquipBreakThroughSmallIcon(equip.Breakthrough)
end

function XEquipModel:GetEquipBreakThroughBigIcon(breakthroughTimes)
    local key = "EquipBreakThroughBig" .. tostring(breakthroughTimes)
    local icon = CS.XGame.ClientConfig:GetString(key)
    if not icon then
        XLog.Error("XEquipModel:GetEquipBreakThroughBigIcon调用错误，得到的icon为空，原因：检查breakthroughTimes：" .. breakthroughTimes .. "和Text.tab的" .. key)
        return
    end
    return icon
end

--- 升级单位转换为突破次数，等级
function XEquipModel:ConvertToBreakThroughAndLevel(templateId, levelUnit)
    local breakthrough, level = 0, 0
    local maxBreakthrough, maxLevel = self:GetEquipMaxBreakthrough(templateId)
    for i = 0, maxBreakthrough do
        local levelLimit = self:GetEquipBreakthroughLevelLimit(templateId, i)
        if levelUnit <= levelLimit then
            level = levelUnit
            break
        end
        breakthrough = breakthrough + 1
        levelUnit = levelUnit - levelLimit
    end
    return breakthrough, level
end

--- 突破次数，等级转换为升级单位
function XEquipModel:ConvertToLevelUnit(templateId, breakthrough, level)
    breakthrough = breakthrough or 0
    level = level or 1
    local levelUnit = 0
    for i = 0, breakthrough - 1 do
        levelUnit = levelUnit + self:GetEquipBreakthroughLevelLimit(templateId, i)
    end
    levelUnit = levelUnit + level
    return levelUnit
end

--- 获取装备最大升级单位（全突破）
function XEquipModel:GetEquipMaxLevelUnit(templateId)
    local breakthrough, level = self:GetEquipMaxBreakthrough(templateId)
    return self:ConvertToLevelUnit(templateId, breakthrough, level)
end

--- 获取装备当前升级单位（当前突破次数等级之和+当前等级）
function XEquipModel:GetEquipLevelUnit(equipId)
    local equip = self:GetEquip(equipId)
    return self:ConvertToLevelUnit(equip.TemplateId, equip.Breakthrough, equip.Level)
end

--获取装备从当前到目标突破次数总消耗道具
function XEquipModel:GetMutiBreakthroughConsumeItems(equipId, targetBreakthrough)
    local itemDic, canBreakThrough = {}, true

    local equip = self:GetEquip(equipId)
    local templateId = equip.TemplateId

    --根据最后一次突破取所有消耗物品种类
    local consumeItems = {}
    local maxBreakthrough, maxLevel = self:GetEquipMaxBreakthrough(templateId)
    local lastBreakthrough = maxBreakthrough - 1
    if lastBreakthrough < 0 then
        --没有突破配置
        return itemDic, canBreakThrough
    end
    local equipBreakthroughCfg = self:GetEquipBreakthroughCfg(templateId, lastBreakthrough)
    for index, itemId in ipairs(equipBreakthroughCfg.ItemId) do
        table.insert(consumeItems, {
            Id = itemId,
            Count = 0
        })
    end

    --取到达目标突破次数时消耗物品数量
    local originBreakthrough = equip.Breakthrough
    for i = equip.Breakthrough, targetBreakthrough - 1 do
        local equipBreakthroughCfg = self:GetEquipBreakthroughCfg(templateId, i)
        for index, itemId in pairs(equipBreakthroughCfg.ItemId) do
            if not itemDic[itemId] then
                itemDic[itemId] = 0
            end
            itemDic[itemId] = itemDic[itemId] + equipBreakthroughCfg.ItemCount[index]
        end
    end

    for itemId, itemCount in pairs(itemDic) do
        if not XDataCenter.ItemManager.CheckItemCountById(itemId, itemCount) then
            canBreakThrough = false
        end
        for _, item in pairs(consumeItems) do
            if item.Id == itemId then
                item.Count = itemCount
            end
        end
    end
    return consumeItems, canBreakThrough
end

--获取装备从当前到目标突破次数总消耗货币
function XEquipModel:GetMutiBreakthroughUseMoney(equipId, targetBreakthrough)
    local costMoney = 0
    local equip = self:GetEquip(equipId)
    for i = equip.Breakthrough, targetBreakthrough - 1 do
        costMoney = costMoney + self:GetEquipBreakthroughCfg(equip.TemplateId, i).UseMoney
    end
    return costMoney
end
---------------------------------------- #endregion EquipBreakthrough ----------------------------------------

---------------------------------------- #region EquipSuit ----------------------------------------
function XEquipModel:GetConfigEquipSuit(suitId, isIgnoreError)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipSuit)
    if suitId then
        if cfgs[suitId] then
            return cfgs[suitId]
        else
            if not isIgnoreError then
                XLog.Error("请检查配置表Share/Equip/EquipSuit.tab，未配置行Id = " .. tostring(suitId))
            end
        end
    else
        return cfgs
    end
end

--- 获取套装图标
function XEquipModel:GetSuitIconPath(suitId)
    local suitCfg = self:GetConfigEquipSuit(suitId)
    return suitCfg and suitCfg.IconPath or ""
end

--- 获取套装大图标
function XEquipModel:GetSuitBigIconPath(suitId)
    local suitCfg = self:GetConfigEquipSuit(suitId)
    return suitCfg and suitCfg.BigIconPath or ""
end

function XEquipModel:GetSuitName(suitId)
    if self:IsDefaultSuitId(suitId) then
        return ""
    end
    local config = self:GetConfigEquipSuit(suitId)
    return config and config.Name or ""
end

function XEquipModel:GetSuitDescription(suitId)
    if self:IsDefaultSuitId(suitId) then
        return ""
    end
    local config = self:GetConfigEquipSuit(suitId)
    return config and config.Description or ""
end

function XEquipModel:GetEquipSuitSkillDescription(suitId, isIgnoreError)
    local config = self:GetConfigEquipSuit(suitId, isIgnoreError)
    return config and config.SkillDescription or {}
end

--- 获取套装对应装备id字典，key是装备的site位置
function XEquipModel:GetSuitEquipIds(suitId)
    local config = self:GetConfigEquipSuit(suitId)
    return config and config.EquipIds or {}
end

--- 获取套装对应装备id数组
function XEquipModel:GetSuitEquipIdList(suitId)
    local equipIdDic = self:GetSuitEquipIds(suitId)
    local equipIdList = {}
    for _, equipId in pairs(equipIdDic) do
        table.insert(equipIdList, equipId)
    end
    return equipIdList
end

--- 获取套装内一件装备的配置表Id
function XEquipModel:GetSuitOneEquipId(suitId)
    local equipIds = self:GetSuitEquipIds(suitId)
    local site = XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.ONE
    if equipIds[site] then
        return equipIds[site]
    else
        for _, equipId in pairs(equipIds) do
            if equipId ~= 0 then
                return equipId
            end
        end
    end
end

function XEquipModel:GetSuitEquipCount(suitId)
    local equipIds = self:GetSuitEquipIds(suitId)
    local cnt = 0
    for _, equipId in pairs(equipIds) do
        if equipId ~= 0 then 
            cnt = cnt + 1    
        end
    end
    return cnt
end

--- 获取意识套装列表
--- @param isFilterType0 boolean 是否筛选类型为0的套装，即不包括意识强化素材
--- @param isOverrun boolean 是否筛选超限套装
function XEquipModel:GetSuitIdsByCharacterType(charType, minQuality, isFilterType0, isOverrun)
    minQuality = minQuality or 0
    local suitIdList = {}
    local suitCfgs = self:GetConfigEquipSuit()
    for _, suitCfg in pairs(suitCfgs) do
        local templateId = self:GetSuitOneEquipId(suitCfg.Id)
        if templateId then
            local equipCfg = self:GetConfigEquip(templateId)
            local isShow = equipCfg.Quality >= minQuality
                       and (charType == XEnumConst.EQUIP.USERTYPE.ALL or equipCfg.CharacterType == charType) 
                       and ((isFilterType0 and equipCfg.Type == 0) or not isFilterType0)
                       and ((isOverrun and equipCfg.OverrunNoShow ~= 1) or not isOverrun)
            if isShow then
                table.insert(suitIdList, suitCfg.Id)
            end
        end
    end

    return suitIdList
end

--- 获取套装对应星级
function XEquipModel:GetSuitStar(suitId)
    if self:IsDefaultSuitId(suitId) then
        return 0
    end

    local templateId = self:GetSuitOneEquipId(suitId)
    return self:GetEquipStar(templateId)
end

--- 获取套装的品质图
function XEquipModel:GetSuitQualityIcon(suitId)
    if self:IsDefaultSuitId(suitId) then
        return
    end
    local templateId = self:GetSuitOneEquipId(suitId)
    return self:GetEquipBgPath(templateId)
end

--- 获取意识套装的品质
function XEquipModel:GetSuitQuality(suitId)
    local templateId = self:GetSuitOneEquipId(suitId)
    if templateId then
        local equipCfg = self:GetConfigEquip(templateId)
        return equipCfg.Quality
    end
    return 0
end

--- 获取意识套装的适配角色类型
function XEquipModel:GetSuitCharacterType(suitId)
    if suitId == XEnumConst.EQUIP.DEFAULT_SUIT_ID.NORMAL then
        return XEnumConst.EQUIP.USER_TYPE.NORMAL
    elseif suitId == XEnumConst.EQUIP.DEFAULT_SUIT_ID.ISOMER then
        return XEnumConst.EQUIP.USER_TYPE.ISOMER
    end

    local templateId = self:GetSuitOneEquipId(suitId)
    if templateId then
        local equipCfg = self:GetConfigEquip(templateId)
        return equipCfg.CharacterType
    end
    return 0
end

--- 获取最大套装数量
function XEquipModel:GetMaxSuitCount()
    local count = 0
    local suitIdDic = {}
    local cfgs = self:GetConfigEquip()
    for _, cfg in pairs(cfgs) do
        local suitId = cfg.SuitId
        if suitId > 0 and not suitIdDic[suitId] then
            suitIdDic[suitId] = true
            count = count + 1
        end
    end
    return count
end

function XEquipModel:IsDefaultSuitId(suitId)
    return suitId == XEnumConst.EQUIP.DEFAULT_SUIT_ID.NORMAL or suitId == XEnumConst.EQUIP.DEFAULT_SUIT_ID.ISOMER
end

function XEquipModel:GetDefaultSuitIdCount()
    local count = 0
    for _, _ in pairs(XEnumConst.EQUIP.DEFAULT_SUIT_ID) do
        count = count + 1
    end
    return count
end
---------------------------------------- #endregion EquipSuit ----------------------------------------


function XEquipModel:GetConfigEquipSuitEffect(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipSuitEffect)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/EquipSuitEffect.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end


---------------------------------------- #region EquipDecompose ----------------------------------------
function XEquipModel:GetConfigEquipDecompose(key)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipDecompose)
    if key then
        if cfgs[key] then
            return cfgs[key]
        else
            XLog.Error("请检查配置表Share/Equip/EquipDecompose.tab，未配置行Key = " .. tostring(key))
        end
    else
        return cfgs
    end
end

--- 获取装备分解配置表
function XEquipModel:GetEquipDecomposeCfg(templateId, breakthroughTimes)
    if not self:CheckTemplateIdIsEquip(templateId) then 
        return 
    end
    
    local template = self:GetConfigEquip(templateId)
    local site = template.Site
    local star = template.Star
    breakthroughTimes = breakthroughTimes or 0
    local key = "key" .. tostring(site) .. tostring(star) .. tostring(breakthroughTimes)
    return self:GetConfigEquipDecompose(key)
end

function XEquipModel:GetDecomposeRewardEquipCount(equipId)
    local weaponCount, awarenessCount = 0, 0
    local rewards = self:GetDecomposeRewards({equipId})
    for _, v in pairs(rewards) do
        if XArrangeConfigs.GetType(v.TemplateId) == XArrangeConfigs.Types.Weapon then
            weaponCount = weaponCount + v.Count
        elseif XArrangeConfigs.GetType(v.TemplateId) == XArrangeConfigs.Types.Wafer then
            awarenessCount = awarenessCount + v.Count
        end
    end

    return weaponCount, awarenessCount
end

function XEquipModel:GetDecomposeRewards(equipIds)
    local EQUIP_DECOMPOSE_RETURN_RATE = CS.XGame.Config:GetInt("EquipDecomposeReturnRate") / 10000
    local itemInfoList = {}

    local rewards = {}
    local coinId = XDataCenter.ItemManager.ItemId.Coin
    XTool.LoopCollection(equipIds, function(equipId)
        local equip = self:GetEquip(equipId)
        local decomposeconfig = self:GetEquipDecomposeCfg(equip.TemplateId, equip.Breakthrough)
        local levelUpCfg = self:GetLevelUpCfg(equip.TemplateId, equip.Breakthrough, equip.Level)
        local equipBreakthroughCfg = self:GetEquipBreakthroughCfgByEquipId(equipId)
        local exp = (equip.Exp + levelUpCfg.AllExp + equipBreakthroughCfg.Exp)

        local expToCoin = math.floor(exp / decomposeconfig.ExpToOneCoin)
        if expToCoin > 0 then
            local coinReward = rewards[coinId]
            if coinReward then
                coinReward.Count = coinReward.Count + expToCoin
            else
                rewards[coinId] = XRewardManager.CreateRewardGoods(coinId, expToCoin)
            end
        end

        local ratedExp = exp * EQUIP_DECOMPOSE_RETURN_RATE
        local expToFoodId = decomposeconfig.ExpToItemId
        local singleExp = XDataCenter.ItemManager.GetItemsAddEquipExp(expToFoodId)
        local expToFoodCount = math.floor(ratedExp / (singleExp))
        if expToFoodCount > 0 then
            local foodReward = rewards[expToFoodId]
            if foodReward then
                foodReward.Count = foodReward.Count + expToFoodCount
            else
                rewards[expToFoodId] = XRewardManager.CreateRewardGoods(expToFoodId, expToFoodCount)
            end
        end

        if decomposeconfig.RewardId > 0 then
            local rewardList = XRewardManager.GetRewardList(decomposeconfig.RewardId)
            for _, item in pairs(rewardList) do
                if rewards[item.TemplateId] then
                    rewards[item.TemplateId].Count = rewards[item.TemplateId].Count + item.Count
                else
                    rewards[item.TemplateId] = XRewardManager.CreateRewardGoodsByTemplate(item)
                end
            end
        end
    end)

    for _, reward in pairs(rewards) do
        table.insert(itemInfoList, reward)
    end
    itemInfoList = XRewardManager.SortRewardGoodsList(itemInfoList)

    return itemInfoList
end
---------------------------------------- #endregion EquipDecompose ----------------------------------------


---------------------------------------- #region EatEquipCost ----------------------------------------
function XEquipModel:GetConfigEatEquipCost(key)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EatEquipCost)
    if key then
        if cfgs[key] then
            return cfgs[key]
        else
            XLog.Error("请检查配置表Share/Equip/EatEquipCost.tab，未配置行Key = " .. tostring(key))
        end
    else
        return cfgs
    end
end

-- 获取强化吃装备消耗螺母
function XEquipModel:GetEatEquipCostMoney(site, star)
    local key = "key" .. tostring(site) .. tostring(star)
    local config = self:GetConfigEatEquipCost(key)
    return config.UseMoney
end

function XEquipModel:GetEatEquipsCostMoney(equipIdKeys)
    local costMoney = 0
    for equipId in pairs(equipIdKeys) do
        local equip = self:GetEquip(equipId)
        costMoney = costMoney + self:GetEatEquipCostMoney(equip:GetSite(), equip:GetStar())
    end

    return costMoney
end

function XEquipModel:GetEatItemsCostMoney(itemIdDic)
    local costMoney = 0
    for itemId, count in pairs(itemIdDic) do
        costMoney = costMoney + XDataCenter.ItemManager.GetItemsAddEquipCost(itemId, count)
    end

    return costMoney
end
---------------------------------------- #endregion EatEquipCost ----------------------------------------


function XEquipModel:GetConfigEquipResonance(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipResonance)
    if id then
        return cfgs[id]
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipResonanceUseItem(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipResonanceUseItem)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/EquipResonanceUseItem.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 共鸣道具是否显示在代币页签
function XEquipModel:IsResonanceItemShowInTokenTab(itemId)
    if self.ResonanceTokenDic then
        return self.ResonanceTokenDic[itemId] == true
    end

    self.ResonanceTokenDic = {}
    local str = CS.XGame.ClientConfig:GetString('EquipResonanceTokenIds')
    local tokenIds = string.Split(str, '|')
    for _, tokenId in ipairs(tokenIds) do
        self.ResonanceTokenDic[tonumber(tokenId)] = true
    end
    return self.ResonanceTokenDic[itemId] == true
end

function XEquipModel:GetResoanceIconPath(isAwaken)
    local key = isAwaken and "EquipAwakenIcon" or "EquipResonanceIcon"
    return CS.XGame.ClientConfig:GetString(key)
end


---------------------------------------- #region WeaponSkill ----------------------------------------
function XEquipModel:GetConfigWeaponSkill(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.WeaponSkill)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/WeaponSkill.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetWeaponSkillAbility(id)
    local config = self:GetConfigWeaponSkill(id)
    return config and config.Ability or 0
end
---------------------------------------- #endregion WeaponSkill ----------------------------------------


---------------------------------------- #region WeaponSkillPool ----------------------------------------
-- 缓存武器共鸣技能池子
function XEquipModel:InitWeaponSkillPoolConfig()
    self.WeaponSkillPoolTemplate = {}
    local skillPoolCfgs = self:GetConfigWeaponSkillPool()
    for _, config in pairs(skillPoolCfgs) do
        local poolId = config.PoolId
        local characterId = config.CharacterId
        self.WeaponSkillPoolTemplate[poolId] = self.WeaponSkillPoolTemplate[poolId] or {}
        self.WeaponSkillPoolTemplate[poolId][characterId] = self.WeaponSkillPoolTemplate[poolId][characterId] or {}
        for _, skillId in ipairs(config.SkillId) do
            table.insert(self.WeaponSkillPoolTemplate[poolId][characterId], skillId)
        end
    end
end

function XEquipModel:GetConfigWeaponSkillPool(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.WeaponSkillPool)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/WeaponSkillPool.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetWeaponSkillPoolSkillIds(poolId, characterId)
    local template = self.WeaponSkillPoolTemplate[poolId]
    if not template then
        XLog.ErrorTableDataNotFound("XEquipModel:GetWeaponSkillPoolSkillIds", "template", "Share/Equip/WeaponSkillPool.tab", "poolId", tostring(poolId))
        return
    end

    local skillIds = template[characterId]
    if not skillIds then
        XLog.ErrorTableDataNotFound("XEquipModel:GetWeaponSkillPoolSkillIds", "characterId", "Share/Equip/WeaponSkillPool.tab", "poolId", tostring(poolId))
        return
    end
    return skillIds
end
---------------------------------------- #endregion WeaponSkillPool ----------------------------------------


---------------------------------------- #region EquipAwake ----------------------------------------
function XEquipModel:GetConfigEquipAwake(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipAwake)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/EquipAwake.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetEquipAwakeCfgByEquipId(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    return self:GetConfigEquipAwake(templateId)
end

function XEquipModel:GetEquipAwakeSkillDesList(templateId, pos)
    local equipAwakeCfg = self:GetConfigEquipAwake(templateId)
    local desList = equipAwakeCfg["AttribDes" .. pos]
    if not desList then
        local tempStr = "AttribDes" .. pos
        XLog.ErrorTableDataNotFound("XEquipModel:GetEquipAwakeSkillDesList", tempStr, "Share/Equip/EquipAwake.tab", "templateId", tostring(templateId))
        return
    end
    return desList
end

function XEquipModel:InitAwakeItemTypeDic()
    self.AwakeItemTypeDic = {}
    local equipAwakeCfgs = self:GetConfigEquipAwake()
    for _, equipAwakeCfg in pairs(equipAwakeCfgs) do
        local itemIds = equipAwakeCfg.ItemId
        if itemIds then
            for _, itemId in pairs(itemIds) do
                local awakeItemType = self.AwakeItemTypeDic[itemId]
                if not awakeItemType then
                    awakeItemType = {}
                    self.AwakeItemTypeDic[itemId] = awakeItemType
                end
                local equipCfg = self:GetConfigEquip(equipAwakeCfg.Id)
                if not awakeItemType[equipCfg.SuitId] then
                    awakeItemType[equipCfg.SuitId] = equipCfg.SuitId
                end
            end
        end
    end
end

-- 获取觉醒道具能够生效的意识列表
function XEquipModel:GetAwakeItemApplicationScope(itemId)
    if not self.AwakeItemTypeDic then
        self:InitAwakeItemTypeDic()
    end
    return self.AwakeItemTypeDic[itemId]
end

function XEquipModel:GetAwakeConsumeItemCrystalList(equipId, awakeCnt)
    awakeCnt = awakeCnt or 1
    local consumeItems = {}
    local coinId = XDataCenter.ItemManager.ItemId.Coin
    local config = self:GetEquipAwakeCfgByEquipId(equipId)
    for i = 1, #config.ItemCrystalId do
        local itemId = config.ItemCrystalId[i]
        if itemId ~= coinId then
            table.insert(consumeItems, {
                ItemId = itemId,
                Count = config.ItemCrystalCount[i] * awakeCnt,
            })
        end
    end

    return consumeItems
end

function XEquipModel:GetAwakeConsumeCrystalCoin(equipId, awakeCnt)
    awakeCnt = awakeCnt or 1
    local consumeCoin = 0
    local config = self:GetEquipAwakeCfgByEquipId(equipId)
    for i = 1, #config.ItemCrystalId do
        local itemId = config.ItemCrystalId[i]
        if itemId == XDataCenter.ItemManager.ItemId.Coin then
            consumeCoin = config.ItemCrystalCount[i] * awakeCnt
            break
        end
    end

    return consumeCoin
end

function XEquipModel:GetAwakeSkillDesList(equipId, pos)
    local templateId = self:GetEquipTemplateId(equipId)
    return self:GetEquipAwakeSkillDesList(templateId, pos)
end

function XEquipModel:GetAwakeSkillDesListByEquipData(equip, pos)
    local templateId = equip.TemplateId
    return self:GetEquipAwakeSkillDesList(templateId, pos)
end
---------------------------------------- #endregion EquipAwake ----------------------------------------


function XEquipModel:GetConfigCharacterSuitPriority(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.CharacterSuitPriority)
    if id then
        return cfgs[id]
    else
        return cfgs
    end
end


---------------------------------------- #region EquipRes ----------------------------------------
function XEquipModel:GetConfigEquipRes(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipRes)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipRes.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 获取装备的资源配置
function XEquipModel:GetEquipResConfig(templateId, breakthroughTimes)
    breakthroughTimes = breakthroughTimes or 0
    local breakthroughCfg = self:GetEquipBreakthroughCfg(templateId, breakthroughTimes)
    local resId = breakthroughCfg.ResId
    if not resId then
        XLog.ErrorTableDataNotFound("XEquipModel:GetEquipResConfig", "resId",
                "Share/Equip/EquipBreakThrough.tab", "templateId : times", tostring(templateId) .. " : " .. tostring(breakthroughTimes))
        return
    end
    return self:GetConfigEquipRes(resId)
end

--- 获取立绘
function XEquipModel:GetEquipLiHuiPath(templateId, breakthroughTimes)
    local equipResCfg = self:GetEquipResConfig(templateId, breakthroughTimes)
    return equipResCfg and equipResCfg.LiHuiPath or ""
end

--- 获取绘画者名称
function XEquipModel:GetEquipPainterName(templateId, breakthroughTimes)
    local equipResCfg = self:GetEquipResConfig(templateId, breakthroughTimes)
    return equipResCfg and equipResCfg.PainterName or ""
end

--- 获取装备大图标
function XEquipModel:GetEquipBigIconPath(templateId)
    local equipResCfg = self:GetEquipResConfig(templateId)
    return equipResCfg and equipResCfg.BigIconPath or ""
end

--- 获取装备在背包中显示图标
function XEquipModel:GetEquipIconPath(templateId, breakthroughTimes)
    local equipResCfg = self:GetEquipResConfig(templateId, breakthroughTimes)
    return equipResCfg and equipResCfg.IconPath or ""
end

--- 获取武器模型Id
function XEquipModel:GetWeaponResonanceModelId(case, templateId, resonanceCount)
    local modelId
    local template = self:GetConfigEquipRes(templateId)
    if not template then
        return
    end
    if resonanceCount == 1 then
        modelId = template.ResonanceModelTransId1[case]
    elseif resonanceCount == 2 then
        modelId = template.ResonanceModelTransId2[case]
    elseif resonanceCount == 3 then
        modelId = template.ResonanceModelTransId3[case]
    end
    return modelId or template.ModelTransId[case]
end

--- 获取武器模型Id列表
function XEquipModel:GetWeaponResonanceModelIds(templateId, breakthroughTimes, resonanceCount)
    local resConfig = self:GetEquipResConfig(templateId, breakthroughTimes)

    resonanceCount = resonanceCount or 0
    local resonanceModelIds = resConfig["ResonanceModelTransId"..resonanceCount]
    if resonanceModelIds and #resonanceModelIds > 0 then
        return resonanceModelIds
    end
    return resConfig.ModelTransId
end

function XEquipModel:GetWeaponModelCfgByEquipId(equipId, uiName)
    local templateId = self:GetEquipTemplateId(equipId)
    local breakthroughTimes = self:GetEquipBreakthroughTimes(equipId)
    local resonanceCount = self:GetEquipResonanceCount(equipId)
    return self:GetWeaponModelCfg(templateId, uiName, breakthroughTimes, resonanceCount)
end

--- @desc: 获取装备模型配置列表
function XEquipModel:GetWeaponModelCfg(templateId, uiName, breakthroughTimes, resonanceCount)
    local modelCfg = {}
    if not templateId then
        XLog.Error("XEquipModel:GetWeaponModelCfg: 参数templateId不能为空")
        return modelCfg
    end

    local template = self:GetEquipResConfig(templateId, breakthroughTimes)
    local modelId = self:GetWeaponResonanceModelId(XEnumConst.EQUIP.WEAPON_CASE.CASE1, template.Id, resonanceCount)
    modelCfg.ModelId = modelId
    modelCfg.TransformConfig = self:GetEquipModelTransformCfg(templateId, uiName, resonanceCount)
    return modelCfg
end

--- @desc: 获取武器模型id列表
function XEquipModel:GetEquipModelIdListByFight(fightNpcData)
    local idList = {}
    local characterId = fightNpcData.Character.Id
    local weaponFashionId = fightNpcData.WeaponFashionId or
        XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    for _, equip in pairs(fightNpcData.Equips) do
        if self:IsEquipWeapon(equip.TemplateId) then
            idList = self:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
            break
        end
    end
    return idList
end

--- @desc: 通过角色id获取武器模型名字列表
function XEquipModel:GetEquipModelIdListByCharacterId(characterId, isDefault, weaponFashionId)
    local isOwnCharacter = XMVCA.XCharacter:IsOwnCharacter(characterId)

    -- 武器时装预览
    if weaponFashionId then
        if isOwnCharacter then
            local equipId = self:GetCharacterWeaponId(characterId)
            local equip = self:GetEquip(equipId)
            return self:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
        else
            local templateId = XMVCA.XCharacter:GetCharacterDefaultEquipId(characterId)
            local equip = {TemplateId = templateId}
            return self:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
        end
    end

    -- 默认武器预览
    if isDefault or not isOwnCharacter then
        local idList = {}
        local templateId = XMVCA.XCharacter:GetCharacterDefaultEquipId(characterId)
        local template = self:GetEquipResConfig(templateId)
        for _, id in pairs(template.ModelTransId) do
            table.insert(idList, id)
        end
        return idList
    end

    -- 主角获取武器逻辑
    local equipId = self:GetCharacterWeaponId(characterId)
    local equip = self:GetEquip(equipId)
    weaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    return self:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
end
---------------------------------------- #endregion EquipRes ----------------------------------------


---------------------------------------- #region EquipModel ----------------------------------------
function XEquipModel:GetConfigEquipModel(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipModel)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipModel.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetEquipModelName(modelTransId, usage)
    -- 修正V2.7 黑岩武器挂点，模型资源未按规范制作
    if modelTransId == 0 then
        return ""
    end

    local template = self:GetConfigEquipModel(modelTransId)
    if not template then
        return
    end

    usage = usage or XEnumConst.EQUIP.WEAPON_USAGE.ROLE
    return template.ModelName[usage] or template.ModelName[XEnumConst.EQUIP.WEAPON_USAGE.ROLE]
end

function XEquipModel:GetEquipLowModelName(modelTransId, usage)
    -- 修正V2.7 黑岩武器挂点，模型资源未按规范制作
    if modelTransId == 0 then
        return ""
    end

    local template = self:GetConfigEquipModel(modelTransId)
    if not template then
        return
    end

    usage = usage or XEnumConst.EQUIP.WEAPON_USAGE.ROLE
    return template.LowModelName[usage] or template.LowModelName[XEnumConst.EQUIP.WEAPON_USAGE.ROLE]
end

function XEquipModel:GetEquipAnimController(modelTransId, usage)
    -- 修正V2.7 黑岩武器挂点，模型资源未按规范制作
    if modelTransId == 0 then
        return ""
    end
    
    local template = self:GetConfigEquipModel(modelTransId)
    if not template then
        return
    end

    usage = usage or XEnumConst.EQUIP.WEAPON_USAGE.ROLE
    local controller = template.AnimController[usage]
    if not controller and usage ~= XEnumConst.EQUIP.WEAPON_USAGE.SHOW then -- 单独展示不需默认值
        controller = template.AnimController[XEnumConst.EQUIP.WEAPON_USAGE.ROLE]
    end
    return controller
end

function XEquipModel:GetEquipUiAnimStateName(modelTransId, usage)
    local template = self:GetConfigEquipModel(modelTransId)
    if not template then
        return
    end

    usage = usage or XEnumConst.EQUIP.WEAPON_USAGE.ROLE
    return template.UiAnimStateName[usage] or template.UiAnimStateName[XEnumConst.EQUIP.WEAPON_USAGE.ROLE]
end

function XEquipModel:GetEquipUiAnimCueId(modelTransId, usage)
    local template = self:GetConfigEquipModel(modelTransId)
    if not template then
        return
    end

    usage = usage or XEnumConst.EQUIP.WEAPON_USAGE.ROLE
    return template.UiAnimCueId[usage] or template.UiAnimCueId[XEnumConst.EQUIP.WEAPON_USAGE.ROLE]
end

function XEquipModel:GetEquipUiAnimDelay(modelTransId, usage)
    local template = self:GetConfigEquipModel(modelTransId)
    if not template then
        return
    end

    usage = usage or XEnumConst.EQUIP.WEAPON_USAGE.ROLE
    return template.UiAnimDelay[usage] or template.UiAnimDelay[XEnumConst.EQUIP.WEAPON_USAGE.ROLE]
end

function XEquipModel:GetEquipUiAutoRotateDelay(modelTransId, usage)
    local template = self:GetConfigEquipModel(modelTransId)
    if not template then
        return
    end

    usage = usage or XEnumConst.EQUIP.WEAPON_USAGE.SHOW -- 默认ui展示
    return template.UiAutoRotateDelay[usage] or template.UiAutoRotateDelay[XEnumConst.EQUIP.WEAPON_USAGE.ROLE]
end

function XEquipModel:GetWeaponResonanceEffectDelay(modelTransId)
    local template = self:GetConfigEquipModel(modelTransId)
    if not template then
        return
    end
    -- v2.17 ResonanceEffectShowDelay字段已无用 延迟逻辑删掉了
    return 0
end

-- 获取武器共鸣成功的特效显示时间
function XEquipModel:GetWeaponResonanceEffectDelayByEquipId(equipId, resonanceCount)
    if not equipId then
        return
    end
    local equip = self:GetEquip(equipId)
    local modelId = self:GetWeaponResonanceModelId(XEnumConst.EQUIP.WEAPON_CASE.CASE1, equip.TemplateId, resonanceCount)
    return self:GetWeaponResonanceEffectDelay(modelId)
end

-- 获取一个武器所有的不同的模型列表
function XEquipModel:GetWeaponModelCfgList(templateId, uiName, breakthroughTimes)
    local modelCfgList = {}
    if not templateId then
        XLog.Error("XEquipModel:GetWeaponModelCfgList函数参数错误, templateId不能为空")
        return modelCfgList
    end

    local template = self:GetEquipResConfig(templateId, breakthroughTimes)
    -- 目前只有共鸣改变形态，有可能有相同的模型，所以需要区别是否有相同的id，以左手id为准
    local resonanceCountList = {}
    local resonanceDic = {}
    local modelId
    for i = 0, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
        modelId = self:GetWeaponResonanceModelId(XEnumConst.EQUIP.WEAPON_CASE.CASE1, template.Id, i)
        if modelId and not resonanceDic[modelId] then
            resonanceDic[modelId] = true
            table.insert(resonanceCountList, i)
        end
    end

    local modelCfg
    for _, resonanceCount in ipairs(resonanceCountList) do
        modelCfg = {}
        modelCfg.ModelId = self:GetWeaponResonanceModelId(XEnumConst.EQUIP.WEAPON_CASE.CASE1, template.Id, resonanceCount)
        modelCfg.TransformConfig = self:GetEquipModelTransformCfg(templateId, uiName, resonanceCount)
        table.insert(modelCfgList, modelCfg)
    end

    return modelCfgList
end

--- 获取装备模型id列表
function XEquipModel:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
    local resonanceCount = 0
    if equip and equip.GetResonanceCount then
        resonanceCount = equip:GetResonanceCount()
    end
    return self:GetWeaponEquipModelIdListByTemplateId(equip.TemplateId, weaponFashionId, resonanceCount, equip.Breakthrough)
end

--- 获取装备模型id列表
function XEquipModel:GetWeaponEquipModelIdListByTemplateId(templateId, weaponFashionId, resonanceCount, breakthroughTimes)
    if (not templateId or templateId == 0) and (not weaponFashionId or weaponFashionId == 0) then 
        return {}
    end
    
    resonanceCount = resonanceCount or 0
    breakthroughTimes = breakthroughTimes or 0
    -- local isAprilFoolDay = XMVCA.XAprilFoolDay:IsInTitleTime()
    local isAprilFoolDay = false -- 关闭愚人节的装备随机功能
   
    -- 愚人节模型
    if isAprilFoolDay then
        local idList = self:GetFoolWeaponModelIds(templateId, resonanceCount)
        if idList and #idList > 0 then
            return idList
        end
    end
    
    -- 使用fashionId对应模型
    if weaponFashionId and not XWeaponFashionConfigs.IsDefaultId(weaponFashionId) then
        local idList = XWeaponFashionConfigs.GetWeaponResonanceModelIds(weaponFashionId, resonanceCount)
        if idList and #idList > 0 then
            return idList
        end
    end
    
    -- 默认模型
    local idList = self:GetWeaponResonanceModelIds(templateId, breakthroughTimes, resonanceCount)
    return idList or {}
end

function XEquipModel:GetEquipModelHash(modelTransId, usage)
    -- 修正V2.7 黑岩武器挂点，模型资源未按规范制作
    if modelTransId == 0 then
        return ""
    end

    local template = self:GetConfigEquipModel(modelTransId)
    if not template then
        return
    end

    usage = usage or XEnumConst.EQUIP.WEAPON_USAGE.ROLE
    return template.WeaponModelHash
end


---------------------------------------- #endregion EquipModel ----------------------------------------


---------------------------------------- #region EquipModelTransform ----------------------------------------
-- 缓存装备模型Transform配置
function XEquipModel:InitEquipModelTransformConfig()
    self.EquipModelTransformTemplates = {}
    local modelTranCfgs = self:GetConfigEquipModelTransform()
    for _, config in pairs(modelTranCfgs) do
        local indexId = config.IndexId
        local uiName = config.UiName
        self.EquipModelTransformTemplates[indexId] = self.EquipModelTransformTemplates[indexId] or {}
        self.EquipModelTransformTemplates[indexId][uiName] = config
    end
end

function XEquipModel:GetConfigEquipModelTransform(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipModelTransform)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipModelTransform.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 返回武器模型和位置配置（双枪只返回一把）
function XEquipModel:GetEquipModelTransformCfg(templateId, uiName, resonanceCount, modelTransId, equipType)
    local modelCfg, template

    --尝试用ModelTransId索引
    if not modelTransId then
        modelTransId = self:GetWeaponResonanceModelId(XEnumConst.EQUIP.WEAPON_CASE.CASE1, templateId, resonanceCount)
        if not modelTransId then
            return
        end
    end

    template = self.EquipModelTransformTemplates[modelTransId]
    if template then
        modelCfg = template[uiName]
    end

    --读不到配置时用equipType索引
    if not modelCfg then
        if not equipType then
            local equipCfg = self:GetConfigEquip(templateId)
            equipType = equipCfg.Type
        end

        template = self.EquipModelTransformTemplates[equipType]
        if not template then
            XLog.ErrorTableDataNotFound("XEquipModel:GetEquipModelTransformCfg",
                    "template", "Client/Equip/EquipModelTransform.tab", "equipType", tostring(equipType))
            return
        end

        modelCfg = template[uiName]
        if not modelCfg then
            XLog.ErrorTableDataNotFound("XEquipModel:GetEquipModelTransformCfg",
                    "uiName", "Client/Equip/EquipModelTransform.tab", "equipType", tostring(equipType))
            return
        end
    end

    return modelCfg
end
---------------------------------------- #endregion EquipModelTransform ----------------------------------------


---------------------------------------- #region EquipSkipId ----------------------------------------
function XEquipModel:GetConfigEquipSkipId(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipSkipId)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipSkipId.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 获取狗粮跳转id列表
function XEquipModel:GetEquipEatSkipIds(eatType, site)
    local cfgs = self:GetConfigEquipSkipId()
    for _, config in pairs(cfgs) do
        if config.EatType == eatType and config.Site == site then
            return config.SkipIdParams
        end
    end
end

--- 获取装备来源跳转id列表
function XEquipModel:GetEquipSkipIds(equipType)
    local cfgs = self:GetConfigEquipSkipId()
    for _, config in pairs(cfgs) do
        if config.EquipType == equipType then
            return config.SkipIdParams
        end
    end
end
---------------------------------------- #endregion EquipSkipId ----------------------------------------


---------------------------------------- #region EquipAnim ----------------------------------------
function XEquipModel:GetConfigEquipAnim(id, ignoreTips)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipAnim)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            if not ignoreTips then
                XLog.Error("请检查配置表Client/Equip/EquipAnim.tab，未配置行Id = " .. tostring(id))
            end
        end
    else
        return cfgs
    end
end

function XEquipModel:GetEquipAnimParams(id)
    local config = self:GetConfigEquipAnim(id, true)
    return config and config.Params or 0
end
---------------------------------------- #endregion EquipAnim ----------------------------------------


---------------------------------------- #region EquipModelShow ----------------------------------------
function XEquipModel:GetConfigEquipModelShow(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipModelShow)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipModelShow.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetEquipModelShowHideNodeName(modelId, UiName)
    local configs = self:GetConfigEquipModelShow()
    for _, cfg in pairs(configs) do
        if cfg.ModelId == modelId and cfg.UiName == UiName then
            return cfg.HideNodeName or {}
        end
    end
    return {}
end
---------------------------------------- #endregion EquipModelShow ----------------------------------------


---------------------------------------- #region EquipResByFool ----------------------------------------
function XEquipModel:GetConfigEquipResByFool(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipResByFool)
    if id then
        return cfgs[id]
    else
        return cfgs
    end
end

-- 获取愚人节模型Id列表
function XEquipModel:GetFoolWeaponModelIds(templateId, resonanceCount)
    local template = self:GetConfigEquipResByFool(templateId)
    if not template then
        return
    end

    resonanceCount = resonanceCount or 0
    local resonanceModelIds = template["ResonanceModelTransId"..resonanceCount]
    if resonanceModelIds and #resonanceModelIds > 0 then 
        return resonanceModelIds
    end
    return template.ModelTransId
end

function XEquipModel:GetFoolWeaponResonanceModelId(case, templateId, resonanceCount)
    local modelId
    local template = self:GetConfigEquipResByFool(templateId)
    if not template then
        return
    end
    if resonanceCount == 1 then
        modelId = template.ResonanceModelTransId1[case]
    elseif resonanceCount == 2 then
        modelId = template.ResonanceModelTransId2[case]
    elseif resonanceCount == 3 then
        modelId = template.ResonanceModelTransId3[case]
    end
    return modelId or template.ModelTransId[case]
end
---------------------------------------- #region EquipResByFool ----------------------------------------


function XEquipModel:GetEquipRecommend(id)
    local cfgs = self._ConfigUtil:GetByTableKey(EquipGuideTableKey.EquipRecommend)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipGuide/EquipRecommend.tab，未配置行Lv = " .. tostring(id))
        end
    else
        return cfgs
    end
end


---------------------------------------- #region WeaponOverrun ----------------------------------------
-- 初始化武器超限表
function XEquipModel:InitWeaponOverrunCfgs()
    self.WeaponOverrunDic = {}
    local overrunTemplates = self._ConfigUtil:GetByTableKey(TableKey.WeaponOverrun)
    for _, cfg in pairs(overrunTemplates) do
        local weaponId = cfg.WeaponId
        local cfgs = self.WeaponOverrunDic[weaponId]
        if not cfgs then
            cfgs = {}
            self.WeaponOverrunDic[weaponId] = cfgs
        end
        table.insert(cfgs, cfg)
    end
end

-- 获取武器对应所有超限配置
function XEquipModel:GetWeaponOverrunCfgsByTemplateId(templateId)
    if not self.WeaponOverrunDic then
        self:InitWeaponOverrunCfgs()
    end

    local cfgs = self.WeaponOverrunDic[templateId]
    return cfgs
end

-- 通过配置表Id判断能否超限
function XEquipModel:CanOverrunByTemplateId(templateId)
    local cfgs = self:GetWeaponOverrunCfgsByTemplateId(templateId)
    local canDeregulate = cfgs and #cfgs > 0
    return canDeregulate
end

-- 获取武器超限意识绑定的配置表
function XEquipModel:GetWeaponOverrunSuitCfgByTemplateId(templateId)
    local cfgs = self:GetWeaponOverrunCfgsByTemplateId(templateId)
    if cfgs then
        for _, cfg in ipairs(cfgs) do
            if cfg.OverrunType == XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.SUIT then
                return cfg
            end
        end
    end
    return nil
end

function XEquipModel:GetConfigWeaponDeregulateUI(lv)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.WeaponDeregulateUI)
    if lv then
        if cfgs[lv] then
            return cfgs[lv]
        else
            XLog.Error("请检查配置表Client/Equip/WeaponDeregulateUI.tab，未配置行Lv = " .. tostring(lv))
        end
    else
        return cfgs
    end
end

--- 检测超限引导
function XEquipModel:CheckOverrunGuide(weaponId)
    -- debug模式下，禁用引导时不播放
    if XMain.IsDebug then
        local isGuideDisable = XDataCenter.GuideManager.CheckFuncDisable()
        if isGuideDisable then
            return
        end
    end

    -- 功能未开启
    local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun)
    if not isOpen then
        return
    end

    -- 装备不可超限
    local equip = self:GetEquip(weaponId)
    local canOverrun = self:CanOverrunByTemplateId(equip.TemplateId)
    if not canOverrun then
        return
    end

    -- 播放引导，已播过会跳过
    local guideId = CS.XGame.ClientConfig:GetInt("EquipOverrunGuideId")
    if guideId ~= 0 then
        local guide = XGuideConfig.GetGuideGroupTemplatesById(guideId)
        local isFinish = XDataCenter.GuideManager.CheckIsGuide(guideId)
        local isGuiding = XDataCenter.GuideManager.CheckIsInGuide()
        if not isFinish and not isGuiding then
            XDataCenter.GuideManager.TryActiveGuide(guide)
        end
    end
end
---------------------------------------- #endregion WeaponOverrun ----------------------------------------


---------------------------------------- #region LevelUpTemplate -----------------------------------------
-- 初始化升级文件夹内的配置表
function XEquipModel:InitEquipLevelUpConfig()
    self.LevelUpTableKey = {}
    local paths = CS.XTableManager.GetPaths("Share/Equip/LevelUpTemplate/")
    XTool.LoopCollection(paths, function(path)
        local key = tonumber(XTool.GetFileNameWithoutExtension(path))
        self.LevelUpTableKey[key] = { Identifier = "Level", TableDefindName = "XTableEquipLevelUp", CacheType = XConfigUtil.CacheType.Normal }
    end)
    self._ConfigUtil:InitConfigByTableKey("Equip/LevelUpTemplate", self.LevelUpTableKey)
end

-- 获取等级配置表
function XEquipModel:GetLevelUpCfg(templateId, times, level)
    local breakthroughCfg = self:GetEquipBreakthroughCfg(templateId, times)
    if not breakthroughCfg then
        return
    end

    local key = self.LevelUpTableKey[breakthroughCfg.LevelUpTemplateId]
    local cfgs = self._ConfigUtil:GetByTableKey(key)
    if not cfgs then
        XLog.ErrorTableDataNotFound("XEquipModel:GetLevelUpCfg", "template", "Share/Equip/LevelUpTemplate/", "levelUpTemplateId", tostring(breakthroughCfg.LevelUpTemplateId))
        return
    end

    local config = cfgs[level]
    if not config then
        XLog.ErrorTableDataNotFound("XEquipModel:GetLevelUpCfg", "level", "Share/Equip/LevelUpTemplate/"..tostring(breakthroughCfg.LevelUpTemplateId)..".tab", 
            "level", tostring(level))
        return
    end

    return config
end
---------------------------------------- #endregion LevelUpTemplate ----------------------------------------


---------------------------------------- #region EquipSignboard -----------------------------------------

function XEquipModel:GetEquipSignboardDic()
    if self.EquipSignboardDic then 
        return self.EquipSignboardDic
    end

    self.EquipSignboardDic = {}
    local configs = self:GetConfigEquipSignboard()
    for id, config in pairs(configs) do
        local equipModelIndex = config.EquipModelIndex
        local characterId = config.CharacterId
        local fashionId = config.FashionId
        local actionId = config.ActionId

        if not equipModelIndex then
            XLog.Error(string.format("EquipSignboard表的EquipModelIndex字段为空！Id:%d, 路径:%s", id, "Client/Equip/EquipSignboard.tab"))
            self.EquipSignboardDic = {}
            return self.EquipSignboardDic
        end
        self.EquipSignboardDic[characterId] = self.EquipSignboardDic[characterId] or {}

        if config.ChaIsAllActive and config.ChaIsAllActive == XEnumConst.EQUIP.SIGNBOARD_ACTIVE_TYPE.CHARACTER then
            if not characterId then
                XLog.Error(string.format("EquipSignboard表CharacterId为空！Id:%d, 路径:%s", id, "Client/Equip/EquipSignboard.tab"))
                self.EquipSignboardDic = {}
                return self.EquipSignboardDic
            end

            self.EquipSignboardDic[characterId].ChaIsAllActive = true
            self.EquipSignboardDic[characterId].EquipModelIndex = equipModelIndex
        else
            self.EquipSignboardDic[characterId].ChaIsAllActive = false

            if not fashionId or fashionId == 0 then
                self.EquipSignboardDic[characterId].AllFashion = true

                if self.EquipSignboardDic[characterId].FashionIdDic then
                    self.EquipSignboardDic[characterId].FashionIdDic = nil
                    XLog.Error(string.format("EquipSignboard表CharacterId(%d)配置全部涂装开启武器，会覆盖当前CharacterId的其它涂装配置！Id:%d, 路径:%s", characterId, id, "Client/Equip/EquipSignboard.tab"))
                end

                if config.FashIsAllActive and config.FashIsAllActive == XEnumConst.EQUIP.SIGNBOARD_ACTIVE_TYPE.FASHION then
                    self.EquipSignboardDic[characterId].FashIsAllActive = true
                    self.EquipSignboardDic[characterId].EquipModelIndex = equipModelIndex
                else
                    self.EquipSignboardDic[characterId].FashIsAllActive = false

                    if not actionId or actionId == 0 then
                        self.EquipSignboardDic[characterId].AllAction = true
                        self.EquipSignboardDic[characterId].EquipModelIndex = equipModelIndex
                    else
                        self.EquipSignboardDic[characterId].ActionIdDic = self.EquipSignboardDic[characterId].ActionIdDic or {}
                        self.EquipSignboardDic[characterId].ActionIdDic[actionId] = equipModelIndex
                    end
                end
            else
                self.EquipSignboardDic[characterId].AllFashion = false
                self.EquipSignboardDic[characterId].FashionIdDic = self.self.EquipSignboardDic[characterId].FashionIdDic or {}
                self.EquipSignboardDic[characterId].FashionIdDic[fashionId] = self.EquipSignboardDic[characterId].FashionIdDic[fashionId] or {}

                if config.FashIsAllActive and config.FashIsAllActive == XEnumConst.EQUIP.SIGNBOARD_ACTIVE_TYPE.FASHION then
                    self.EquipSignboardDic[characterId].FashionIdDic[fashionId].FashIsAllActive = true
                    self.EquipSignboardDic[characterId].FashionIdDic[fashionId].EquipModelIndex = equipModelIndex
                else
                    self.EquipSignboardDic[characterId].FashionIdDic[fashionId].FashIsAllActive = false

                    if not actionId or actionId == 0 then
                        self.EquipSignboardDic[characterId].FashionIdDic[fashionId].AllAction = true
                        self.EquipSignboardDic[characterId].FashionIdDic[fashionId].EquipModelIndex = equipModelIndex

                        if self.EquipSignboardDic[characterId].FashionIdDic[fashionId].ActionIdDic then
                            self.EquipSignboardDic[characterId].FashionIdDic[fashionId].ActionIdDic = nil
                            XLog.Error(string.format("EquipSignboard表CharacterId(%d)配置全部动作开启武器，会覆盖当前CharacterId的其它动作配置！Id:%d, 路径:%s", characterId, id, "Client/Equip/EquipSignboard.tab"))
                        end
                    else
                        self.EquipSignboardDic[characterId].FashionIdDic[fashionId].AllAction = false
                        self.EquipSignboardDic[characterId].FashionIdDic[fashionId].ActionIdDic = self.EquipSignboardDic[characterId].FashionIdDic[fashionId].ActionIdDic or {}
                        self.EquipSignboardDic[characterId].FashionIdDic[fashionId].ActionIdDic[actionId] = equipModelIndex
                    end
                end
            end
        end
    end

    return self.EquipSignboardDic
end

function XEquipModel:GetConfigEquipSignboard(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipSignboard)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipSignboard.tab，未配置行Lv = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetEquipAnimControllerBySignboard(characterId, fashionId, actionId)
    if not characterId then
        return
    end

    local equipSignboardDic = self:GetEquipSignboardDic()
    local equipCharacterSignboard = equipSignboardDic[characterId]
    if not equipCharacterSignboard then
        return
    end

    if equipCharacterSignboard.ChaIsAllActive then
        return equipCharacterSignboard.EquipModelIndex
    end

    if equipCharacterSignboard.AllFashion then
        if equipCharacterSignboard.FashIsAllActive then
            return equipSignboardDic[characterId].EquipModelIndex
        else
            if equipCharacterSignboard.AllAction then
                return equipSignboardDic[characterId].EquipModelIndex
            else
                if not actionId then
                    return
                end

                return equipSignboardDic[characterId].ActionIdDic[actionId]
            end
        end
    end

    if not fashionId then
        return
    end

    local equipFashionSignboard = equipCharacterSignboard.FashionIdDic[fashionId]
    if not equipFashionSignboard then
        return
    end

    if equipFashionSignboard.FashIsAllActive then
        return equipFashionSignboard.EquipModelIndex
    end

    if equipFashionSignboard.AllAction then
        return equipFashionSignboard.EquipModelIndex
    end

    if not actionId then
        return
    end

    local equipActionSignboard = equipFashionSignboard.ActionIdDic[actionId]
    if not equipActionSignboard then
        return
    end

    return equipActionSignboard
end

function XEquipModel:CheckHasLoadEquipBySignboard(characterId, fashionId, actionId)
    return self:GetEquipAnimControllerBySignboard(characterId, fashionId, actionId) ~= nil
end
---------------------------------------- #endregion EquipSignboard ----------------------------------------


---------------------------------------- #region EquipAnimReset -----------------------------------------
-- 缓存装备动画是否重置
function XEquipModel:InitEquipAnimResetConfig()
    self.EquipAnimResetDic = {}
    local animResetCfgs = self:GetConfigEquipAnimReset()
    for _, v in pairs(animResetCfgs) do
        self.EquipAnimResetDic[v.CharacterModel] = true
    end
end

function XEquipModel:GetConfigEquipAnimReset(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipAnimReset)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipAnimReset.tab，未配置行Lv = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetEquipAnimIsReset(modelId)
    return self.EquipAnimResetDic[modelId] or false
end
---------------------------------------- #endregion EquipAnimReset ----------------------------------------


---------------------------------------- #region EquipConfig -----------------------------------------
function XEquipModel:GetEquipConfig()
    return self._ConfigUtil:GetByTableKey(TableKey.EquipConfig)
end

function XEquipModel:GetEquipConfigValuesByKey(key)
    local cfgs = self:GetEquipConfig()
    local cfg = cfgs[key]
    if cfg then
        return cfg.Values
    else
        XLog.ErrorTableDataNotFound("XEquipModel:GetEquipConfigValuesByKey", "key", "Share/Equip/EquipConfig.tab/", "level", tostring(key))
        return {}
    end
end
---------------------------------------- #endregion EquipConfig ----------------------------------------


function XEquipModel:GetWeaponTypeIconPath(templateId)
    return XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId).Icon
end

function XEquipModel:GetMaxWeaponCount()
    return CS.XGame.Config:GetInt("EquipWeaponMaxCount")
end

function XEquipModel:GetMaxAwarenessCount()
    return CS.XGame.Config:GetInt("EquipChipMaxCount")
end

function XEquipModel:GetEquipExpInheritPercent()
    return CS.XGame.Config:GetInt("EquipExpInheritPercent")
end

function XEquipModel:GetEquipRecycleItemPercent()
    return CS.XGame.Config:GetInt("EquipRecycleItemPercent") / 100
end

function XEquipModel:GetMinResonanceBindStar()
    return CS.XGame.Config:GetInt("MinResonanceBindStar")
end

function XEquipModel:GetMinAwakeStar()
    return CS.XGame.Config:GetInt("MinEquipAwakeStar")
end

function XEquipModel:GetSuitPrefabNumMax()
    return CS.XGame.Config:GetInt("EquipSuitPrefabMaxNum")
end

function XEquipModel:GetEquipSuitCharacterPrefabMaxNum()
    return CS.XGame.Config:GetInt("EquipSuitCharacterPrefabMaxNum")
end

--============================================================== #endregion 配置表 ==============================================================




--============================================================== #region 其他 ==============================================================
---------------------------------------- #region 超上限拦截检测 ----------------------------------------
--- 武器意识拦截检测
function XEquipModel:CheckBoxOverLimitOfDraw()
    self.OverLimitTexts["Weapon"] = nil
    self.OverLimitTexts["Wafer"] = nil

    local max = self:GetMaxWeaponCount()
    local cur = self:GetWeaponCount()
    if (max - cur) < 1 then
        self.OverLimitTexts["Weapon"] = CS.XTextManager.GetText("WeaponBoxIsFull")
    end

    max = self:GetMaxAwarenessCount()
    cur = self:GetAwarenessCount()
    if (max - cur) < 1 then
        self.OverLimitTexts["Wafer"] = CS.XTextManager.GetText("WaferBoxIsFull")
    end

    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    if mailAgency:CheckMailIsOverLimit(true) then
        return true
    end

    if self.OverLimitTexts["Weapon"] then
        XUiManager.TipMsg(self.OverLimitTexts["Weapon"])
        return true
    end
    if self.OverLimitTexts["Wafer"] then
        XUiManager.TipMsg(self.OverLimitTexts["Wafer"])
        return true
    end
    return false
end

--- 意识拦截检测
function XEquipModel:CheckBoxOverLimitOfGetAwareness()
    self.OverLimitTexts["Wafer"] = nil

    local max = self:GetMaxAwarenessCount()
    local cur = self:GetAwarenessCount()
    if (max - cur) < 1 then
        self.OverLimitTexts["Wafer"] = CS.XTextManager.GetText("WaferBoxIsFull")
    end

    max = CS.XGame.Config:GetInt("MailCountLimit")
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    cur = mailAgency:GetMailListCount()
    if (max - cur) < 1 then
        XUiManager.TipMsg(CS.XTextManager.GetText("MailBoxIsFull"))
        return true
    end

    if self.OverLimitTexts["Wafer"] then
        XUiManager.TipMsg(self.OverLimitTexts["Wafer"])
        return true
    end
    return false
end

--- 武器意识拦截检测
function XEquipModel:GetMaxCountOfBoxOverLimit(EquipId, MaxCount, Count)
    local maxCount = MaxCount
    self.OverLimitTexts["Weapon"] = nil
    self.OverLimitTexts["Wafer"] = nil
    self.OverLimitTexts["Item"] = nil

    if XArrangeConfigs.GetType(EquipId) == XArrangeConfigs.Types.Weapon then
        local max = self:GetMaxWeaponCount()
        local cur = self:GetWeaponCount()
        if (max - cur) // Count < maxCount then
            maxCount = math.max(0, (max - cur) // Count)
            self.OverLimitTexts["Weapon"] = CS.XTextManager.GetText("WeaponBoxWillBeFull")
        end
    elseif XArrangeConfigs.GetType(EquipId) == XArrangeConfigs.Types.Wafer then
        local max = self:GetMaxAwarenessCount()
        local cur = self:GetAwarenessCount()
        if (max - cur) // Count < maxCount then
            maxCount = math.max(0, (max - cur) // Count)
            self.OverLimitTexts["Wafer"] = CS.XTextManager.GetText("WaferBoxWillBeFull")
        end
    elseif XArrangeConfigs.GetType(EquipId) == XArrangeConfigs.Types.Item then
        local item = XDataCenter.ItemManager.GetItem(EquipId)
        local max = item.Template.MaxCount
        local cur = item:GetCount()
        if max > 0 then
            if (max - cur) // Count < maxCount then
                maxCount = math.max(0, (max - cur) // Count)
                self.OverLimitTexts["Item"] = CS.XTextManager.GetText("ItemBoxWillBeFull")
            end
        end
    end

    return maxCount
end

--- 武器意识拦截检测
function XEquipModel:ShowBoxOverLimitText()
    if self.OverLimitTexts["Weapon"] then
        XUiManager.TipMsg(self.OverLimitTexts["Weapon"])
        return true
    end
    if self.OverLimitTexts["Wafer"] then
        XUiManager.TipMsg(self.OverLimitTexts["Wafer"])
        return true
    end
    if self.OverLimitTexts["Item"] then
        XUiManager.TipMsg(self.OverLimitTexts["Item"])
        return true
    end
    return false
end
---------------------------------------- #endregion 超上限拦截检测 ----------------------------------------


---------------------------------------- #region 排序 ----------------------------------------
function XEquipModel:DefaultSort(a, b, exclude)
    if not exclude or exclude ~= XEnumConst.EQUIP.PRIOR_SORT_TYPE.STAR then
        local aStar = self:GetEquipStar(a.TemplateId)
        local bStar = self:GetEquipStar(b.TemplateId)
        if aStar ~= bStar then
            return aStar > bStar
        end
    end

    -- 是否超限
    local isOverrunA = a:IsOverrun() and 1 or 0
    local isOverrunB = b:IsOverrun() and 1 or 0
    if isOverrunA ~= isOverrunB then
        return isOverrunA > isOverrunB
    end

    if not exclude or exclude ~= XEnumConst.EQUIP.PRIOR_SORT_TYPE.BREAKTHROUGH then
        if a.Breakthrough ~= b.Breakthrough then
            return a.Breakthrough > b.Breakthrough
        end
    end

    if not exclude or exclude ~= XEnumConst.EQUIP.PRIOR_SORT_TYPE.LEVEL then
        if a.Level ~= b.Level then
            return a.Level > b.Level
        end
    end

    if a.IsRecycle ~= b.IsRecycle then
        return a.IsRecycle == false
    end

    return self:GetEquipPriority(a.TemplateId) > self:GetEquipPriority(b.TemplateId)
end

function XEquipModel:SortEquipIdListByPriorType(equipIdList, priorSortType)
    local sortFunc
    if priorSortType == XEnumConst.EQUIP.PRIOR_SORT_TYPE.LEVEL then
        sortFunc = function(aId, bId)
            local a = self:GetEquip(aId)
            local b = self:GetEquip(bId)
            if a.Level ~= b.Level then
                return a.Level > b.Level
            end
            return self:DefaultSort(a, b, priorSortType)
        end
    elseif priorSortType == XEnumConst.EQUIP.PRIOR_SORT_TYPE.BREAKTHROUGH then
        sortFunc = function(aId, bId)
            local a = self:GetEquip(aId)
            local b = self:GetEquip(bId)
            if a.Breakthrough ~= b.Breakthrough then
                return a.Breakthrough > b.Breakthrough
            end
            return self:DefaultSort(a, b, priorSortType)
        end
    elseif priorSortType == XEnumConst.EQUIP.PRIOR_SORT_TYPE.STAR then
        sortFunc = function(aId, bId)
            local a = self:GetEquip(aId)
            local b = self:GetEquip(bId)
            local aStar = self:GetEquipStar(a.TemplateId)
            local bStar = self:GetEquipStar(b.TemplateId)
            if aStar ~= bStar then
                return aStar > bStar
            end
            return self:DefaultSort(a, b, priorSortType)
        end
    elseif priorSortType == XEnumConst.EQUIP.PRIOR_SORT_TYPE.PROCEED then
        sortFunc = function(aId, bId)
            local a = self:GetEquip(aId)
            local b = self:GetEquip(bId)
            if a.CreateTime ~= b.CreateTime then
                return a.CreateTime < b.CreateTime
            end
            return self:DefaultSort(a, b, priorSortType)
        end
    else
        sortFunc = function(aId, bId)
            local a = self:GetEquip(aId)
            local b = self:GetEquip(bId)
            return self:DefaultSort(a, b)
        end
    end

    table.sort(equipIdList, function(aId, bId)
        --强制优先插入装备中排序
        local aWearing = self:IsWearing(aId) and 1 or 0
        local bWearing = self:IsWearing(bId) and 1 or 0
        if aWearing ~= bWearing then
            return aWearing < bWearing
        end

        return sortFunc(aId, bId)
    end)
end

function XEquipModel:CheckMaxCount(equipType, count)
    if equipType == XEnumConst.EQUIP.CLASSIFY.WEAPON then
        local maxWeaponCount = self:GetMaxWeaponCount()
        if count and count > 0 then
            return self:GetWeaponCount() + count > maxWeaponCount
        else
            return self:GetWeaponCount() >= maxWeaponCount
        end
    elseif equipType == XEnumConst.EQUIP.CLASSIFY.AWARENESS then
        local maxAwarenessCount = self:GetMaxAwarenessCount()
        if count and count > 0 then
            return self:GetAwarenessCount() + count > maxAwarenessCount
        else
            return self:GetAwarenessCount() >= maxAwarenessCount
        end
    end
end

function XEquipModel:CheckBagCount(count, equipType)
    if self:CheckMaxCount(equipType, count) then
        local messageTips
        if equipType == XEnumConst.EQUIP.CLASSIFY.WEAPON then
            messageTips = XUiHelper.GetText("WeaponBagFull")
        elseif equipType == XEnumConst.EQUIP.CLASSIFY.AWARENESS then
            messageTips = XUiHelper.GetText("ChipBagFull")
        end

        XUiManager.TipMsg(messageTips, XUiManager.UiTipType.Tip)
        return false
    end

    return true
end
---------------------------------------- #endregion 超上限拦截检测 ----------------------------------------


---------------------------------------- #region 战斗力 ----------------------------------------
--- 获取武器技能战力
function XEquipModel:GetWeaponSkillAbilityByEquip(equip, characterId)
    local template = self:GetConfigEquip(equip.TemplateId)
    if not template then
        return
    end

    if template.Site ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON then
        XLog.Error("XEquipModel:GetWeaponSkillAbilityByEquip 错误: 参数equip不是武器, equip的Site是: " .. template.site)
        return
    end

    local ability = 0
    if template.WeaponSkillId > 0 then
        local weaponAbility = self:GetWeaponSkillAbility(template.WeaponSkillId)
        ability = ability + weaponAbility
    end
    if equip.ResonanceInfo then
        for _, resonanceData in pairs(equip.ResonanceInfo) do
            if resonanceData.Type == XEnumConst.EQUIP.RESONANCE_TYPE.WEAPON_SKILL then
                if resonanceData.CharacterId == 0 or resonanceData.CharacterId == characterId then
                    local weaponAbility = self:GetWeaponSkillAbility(resonanceData.TemplateId)
                    ability = ability + weaponAbility
                end
            end
        end
    end

    return ability
end

--- 获取装备列表技能战力
function XEquipModel:GetEquipsSkillAbility(equipList, characterId)
    if not equipList or #equipList <= 0 then
        return 0
    end

    local suitCount = {}
    local ability = 0
    for _, equip in pairs(equipList) do
        local template = self:GetConfigEquip(equip.TemplateId)
        if not template then
            return 0
        end

        if template.Site == XEnumConst.EQUIP.EQUIP_SITE.WEAPON then
            local weaponAbility = self:GetWeaponSkillAbilityByEquip(equip, characterId)
            ability = ability + weaponAbility
        end

        if template.SuitId > 0 then
            if not suitCount[template.SuitId] then
                suitCount[template.SuitId] = 1
            else
                suitCount[template.SuitId] = suitCount[template.SuitId] + 1
            end
        end
    end

    for suitId, count in pairs(suitCount) do
        local template = self:GetConfigEquipSuit(suitId)
        if not template then
            return 0
        end

        for i = 1, math.min(count, XEnumConst.EQUIP.MAX_SUIT_COUNT) do
            local effectId = template.SkillEffect[i]
            if effectId and effectId > 0 then
                local effectTemplate = self:GetConfigEquipSuitEffect(effectId)
                if not effectTemplate then
                    return 0
                end

                ability = ability + effectTemplate.Ability
            end
        end
    end

    return ability
end

function XEquipModel:GetCharacterEquipsSkillAbility(characterId)
    local equipList = self:GetCharacterEquips(characterId)
    return self:GetEquipsSkillAbility(equipList, characterId)
end

function XEquipModel:GetEquipSkillAbilityOther(character, equipList)
    return self:GetEquipsSkillAbility(equipList, character.Id)
end

--- 计算装备战斗力（不包含角色共鸣相关）
function XEquipModel:GetEquipAbility(characterId)
    local equipList = self:GetCharacterEquips(characterId)
    if not equipList or #equipList <= 0 then
        return 0
    end

    local skillAbility = self:GetEquipsSkillAbility(equipList, 0)
    local equipListAttribs = XFightEquipManager.GetEquipListAttribs(equipList)
    local equipListAbility = XAttribManager.GetAttribAbility(equipListAttribs)
    return equipListAbility + skillAbility
end
---------------------------------------- #endregion 战斗力 ----------------------------------------

---------------------------------------- #region 属性 ----------------------------------------
function XEquipModel:ConstructEquipAttrMap(attrs, isIncludeZero, remainDigitTwo)
    local equipAttrMap = {}

    for _, attrIndex in ipairs(XEnumConst.EQUIP.ATTR_SORT_TYPE) do
        local value = attrs and attrs[attrIndex]

        --默认保留两位小数
        if not remainDigitTwo then
            value = value and FixToInt(value)
        else
            value = value and tonumber(string.format("%0.2f", FixToDouble(value)))
        end

        if isIncludeZero or value and value > 0 then
            table.insert(equipAttrMap, {
                AttrIndex = attrIndex,
                Name = XAttribManager.GetAttribNameByIndex(attrIndex),
                Value = value or 0
            })
        end
    end

    return equipAttrMap
end

function XEquipModel:GetEquipAttrMapByEquipData(equip)
    local attrMap = {}
    if not equip then
        return attrMap
    end
    local attrs = XFightEquipManager.GetEquipAttribs(equip)
    attrMap = self:ConstructEquipAttrMap(attrs)

    return attrMap
end

function XEquipModel:GetTemplateEquipAttrMap(templateId, preLevel)
    local equipData = {
        TemplateId = templateId,
        Breakthrough = 0,
        Level = 1
    }
    local attrs = XFightEquipManager.GetEquipAttribs(equipData, nil, preLevel)
    return self:ConstructEquipAttrMap(attrs)
end

--构造装备属性字典
function XEquipModel:ConstructTemplateEquipAttrMap(templateId, breakthroughTimes, level)
    local equipData = {
        TemplateId = templateId,
        Breakthrough = breakthroughTimes,
        Level = level
    }
    local attrs = XFightEquipManager.GetEquipAttribs(equipData)
    return self:ConstructEquipAttrMap(attrs)
end

--构造装备提升属性字典
function XEquipModel:ConstructTemplateEquipPromotedAttrMap(templateId, breakthroughTimes)
    local equipBreakthroughCfg = self:GetEquipBreakthroughCfg(templateId, breakthroughTimes)
    local map = XAttribManager.GetPromotedAttribs(equipBreakthroughCfg.AttribPromotedId)
    return self:ConstructEquipAttrMap(map, false, true)
end

function XEquipModel:GetAwarenessMergeAttrMap(equipIds)
    local equipList = {}
    for _, equipId in pairs(equipIds) do
        table.insert(equipList, self:GetEquip(equipId))
    end
    local attrs = XFightEquipManager.GetEquipListAttribs(equipList)
    return self:ConstructEquipAttrMap(attrs, true)
end


function XEquipModel:GetEquipModeHashListByFight(fightNpcData)
    local idList = {}
    local characterId = fightNpcData.Character.Id
    local weaponFashionId = fightNpcData.WeaponFashionId or
            XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    for _, equip in pairs(fightNpcData.Equips) do
        if self:IsEquipWeapon(equip.TemplateId) then
            idList = self:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
            break
        end
    end
    return idList
end

---------------------------------------- #endregion 属性 ----------------------------------------


---------------------------------------- #region 意识套装 ----------------------------------------

function XEquipModel:GetSuitActiveSkillDescInfoList(wearingAwarenessIds, characterId)
    local skillDesInfoList = {}
    local overrunSuitId = 0 -- 超限绑定的套装id
    local isAddOverrun = false
    if characterId then
        local usingWeaponId = self:GetCharacterWeaponId(characterId)
        if usingWeaponId ~= 0 then
            local equip = self:GetEquip(usingWeaponId)
            if equip:CanOverrun() and equip:IsOverrunBlindMatch() then
                overrunSuitId = equip:GetOverrunChoseSuit()
            end
        end
    end

    local suitIdSet = {}
    for _, equipId in pairs(wearingAwarenessIds) do
        local suitId = self:GetEquipSuitIdByEquipId(equipId)
        if suitId > 0 then
            local count = suitIdSet[suitId]
            suitIdSet[suitId] = count and count + 1 or 1
        end
    end
    if overrunSuitId ~= 0 and not suitIdSet[overrunSuitId] then
        suitIdSet[overrunSuitId] = 0
    end

    for suitId, count in pairs(suitIdSet) do
        local isOverrun = suitId == overrunSuitId
        isAddOverrun = isAddOverrun or isOverrun
        local activeskillDesList = self:GetSuitActiveSkillDesList(suitId, count, isOverrun, isOverrun)
        for _, info in pairs(activeskillDesList) do
            if info.IsActive then
                table.insert(skillDesInfoList, info)
            end
        end
    end

    return skillDesInfoList
end

function XEquipModel:GetActiveSuitEquipsCount(characterId, suitId)
    local count = 0
    local siteCheckDic = {}

    local wearingAwarenessIds = self:GetCharacterAwarenessIds(characterId)
    for _, equipId in pairs(wearingAwarenessIds) do
        local wearingSuitId = self:GetEquipSuitIdByEquipId(equipId)
        if suitId > 0 and suitId == wearingSuitId then
            count = count + 1
            local site = self:GetEquipSiteByEquipId(equipId)
            siteCheckDic[site] = true
        end
    end

    return count, siteCheckDic
end

-- 获取意识激活详情列表
function XEquipModel:GetSuitActiveSkillDesList(suitId, count, isOverrun, isAddOverrunTips)
    count = count or 0
    local skillInfoList = {}
    local skillDesList = self:GetEquipSuitSkillDescription(suitId, true)
    local maxDescCnt = XEnumConst.EQUIP.WEAR_AWARENESS_COUNT

    for i = 1, maxDescCnt do
        local skillDesc = skillDesList[i]
        if skillDesc then
            local isActive = count >= i -- 意识装备数量激活
            local isActiveWithOverrun = isOverrun and (count + XEnumConst.EQUIP.OVERRUN_ADD_SUIT_CNT) >= i -- 算上超限能否激活

            local skillInfo = {}
            skillInfo.Pos = i
            skillInfo.PosDes = XUiHelper.GetText("EquipSuitSkillPrefix" .. i)
            skillInfo.IsActive = isActive or isActiveWithOverrun
            skillInfo.IsActiveByOverrun = not isActive and isActiveWithOverrun
            skillInfo.SkillDes = skillDesc or ""
            if skillInfo.IsActiveByOverrun then
                skillInfo.OverrunTips = XUiHelper.GetText("EquipOverrunActive" .. i)
                if isAddOverrunTips then
                    skillInfo.SkillDes = skillInfo.SkillDes .. XUiHelper.GetText("EquipOverrunActiveTips")
                end
            end
            table.insert(skillInfoList, skillInfo)
        end
    end
    return skillInfoList
end
---------------------------------------- #endregion 意识套装 ----------------------------------------

---------------------------------------- #region 武器特效 ----------------------------------------

---@return XTableEquipResonanceEffect[]
function XEquipModel:GetEquipResonanceEffectConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.EquipResonanceEffect)
end

---@return XTableEquipResonanceEffect[]
function XEquipModel:GetWeaponEffectsByModelId(modelId)
    if not self._EquipResonance then
        local datas = {}
        local configs = self:GetEquipResonanceEffectConfigs()
        for _, v in pairs(configs) do
            if not datas[v.ModelId] then
                datas[v.ModelId] = {}
            end
            table.insert(datas[v.ModelId], v)
        end
        self._EquipResonance = datas
    end
    return self._EquipResonance[modelId]
end

---------------------------------------- #endregion 武器特效 ----------------------------------------


--============================================================== #endregion 其他 ==============================================================

return XEquipModel
