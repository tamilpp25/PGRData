
local default = {
    _Id = 0,
    _Unlock = false,
    _Name = "",
    _Desc = "",
    _Effects = nil,
    _UnlockInfo = nil,
    _EffectCharIdMap = nil,
    _EffectProductIdMap = nil
}

---@class XRestaurantBuff : XDataEntityBase Buff类
---@field _Id number
---@field _Unlock boolean
---@field _Name string
---@field _Desc string
---@field _AreaType number
---@field _Effects table
---@field _EffectCharIdMap table<number, number> 适用的角色
---@field _EffectProductIdMap table<number, number> 适用的产品
local XRestaurantBuff = XClass(XDataEntityBase, "XRestaurantBuff")

function XRestaurantBuff:Ctor(id)
    self:Init(default, id)
end

function XRestaurantBuff:InitData(id)
    self:SetProperty("_Id", id)
    self:SetProperty("_Name", XRestaurantConfigs.GetBuffName(id))
    self:SetProperty("_Desc", XRestaurantConfigs.GetBuffDesc(id))
    
    local effectIds, effectAdditions = XRestaurantConfigs.GetBuffEffectIds(id), XRestaurantConfigs.GetBuffEffectAdditions(id)
    local effects = {}
    for i, id in pairs(effectIds) do
        table.insert(effects, {
            Id = id,
            Addition = effectAdditions[i] or 0
        })
    end
    self:SetProperty("_Effects", effects)
end

function XRestaurantBuff:Unlock()
    self:SetProperty("_Unlock", true)
end

function XRestaurantBuff:IsReachLevel()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local level = viewModel:GetProperty("_Level")
    return level >= XRestaurantConfigs.GetBuffUnlockLv(self._Id)
end

function XRestaurantBuff:GetUnlockCost()
    if self._UnlockInfo then
        return self._UnlockInfo
    end
    local info = {}
    local itemId, itemCount = XRestaurantConfigs.GetBuffUnlockItems(self._Id), XRestaurantConfigs.GetBuffUnlockItemCounts(self._Id)
    for i, id in ipairs(itemId) do
        table.insert(info, {
            Id = id,
            Count = itemCount[i] or 0
        })
    end
    self._UnlockInfo = info
    
    return info
end

function XRestaurantBuff:GetEffectCharacterIdMap()
    if self._EffectCharIdMap then
        return self._EffectCharIdMap
    end
    local map = {}
    local characterIds = XRestaurantConfigs.GetBuffCharacterIds(self._Id)
    for _, characterId in ipairs(characterIds) do
        map[characterId] = characterId
    end
    self._EffectCharIdMap = map
    
    return map
end

--检查角色对当前Buff是否生效
function XRestaurantBuff:CheckCharacterEffect(characterId)
    local map = self:GetEffectCharacterIdMap()
    if self:IsAllStaff() then
        return true
    end
    if not XTool.IsNumberValid(characterId) then
        return false
    end
    return map[characterId] ~= nil
end

function XRestaurantBuff:IsAllStaff()
    local map = self:GetEffectCharacterIdMap()
    --策划未配置时，对所有角色均生效
    return XTool.IsTableEmpty(map)
end

--当前Buff对产品与角色加成效果
function XRestaurantBuff:GetEffectAddition(areaType, characterId, productId)
    if not self:CheckCharacterEffect(characterId) then 
        return 0
    end
    if self._EffectProductIdMap and self._EffectProductIdMap[areaType] then
        return self._EffectProductIdMap[areaType][productId] or 0
    end
    local map = {}
    for _, effect in ipairs(self._Effects) do
        local effectId = effect.Id
        local sectionType = XRestaurantConfigs.GetEffectAreaType(effectId)
        local productIds = XRestaurantConfigs.GetEffectProductIds(effectId)
        map[sectionType] = map[sectionType] or {}
        for _, productId in ipairs(productIds) do
            map[sectionType][productId] = effect.Addition
        end
    end
    self._EffectProductIdMap = map

    if not map[areaType] then
        return 0
    end

    if not map[areaType][productId] then
        return 0
    end

    return map[areaType][productId]
end

--当前Buff对产品加成效果（仅用于展示，实际计算需要考虑角色是否拥有此Buff）
function XRestaurantBuff:GetProductEffectAddition(areaType, productId)
    local characterId
    local map = self:GetEffectCharacterIdMap()
    for _, id in pairs(map) do
        characterId = id
        break
    end
    return self:GetEffectAddition(areaType, characterId, productId)
end

function XRestaurantBuff:GetEffectProductIds(areaType)
    local list = {}
    for _, effect in ipairs(self._Effects) do
        local effectId = effect.Id
        local sectionType = XRestaurantConfigs.GetEffectAreaType(effectId)
        if sectionType == areaType then
            list = XTool.MergeArray(list, XRestaurantConfigs.GetEffectProductIds(effectId))
        end
    end
    
    return list
end

function XRestaurantBuff:CheckBenchEffect(areaType, characterId, productId)
    local addition = self:GetEffectAddition(areaType, characterId, productId)
    return addition ~= 0
end

return XRestaurantBuff