
local XRestaurantViewModel = require("XModule/XRestaurant/XViewModel/XRestaurantViewModel")

---@class XRestaurantBuffVM : XRestaurantViewModel buff视图数据
---@field Data XRestaurantBuffData
---@field _Model XRestaurantModel
---@field _OwnControl XRestaurantControl
local XRestaurantBuffVM = XClass(XRestaurantViewModel, "XRestaurantBuffVM")

function XRestaurantBuffVM:InitData()
end

function XRestaurantBuffVM:OnRelease()
    self.Effects = nil
    self.UnlockInfo = nil
    self.CharDict = nil
    self.ProductDict = nil
    self.ProductList = nil
    self.CharList = nil
    XRestaurantViewModel.OnRelease(self)
end

function XRestaurantBuffVM:GetEffects()
    if self.Effects then
        return self.Effects
    end
    
    local template = self._Model:GetSectionBuffTemplate(self:GetBuffId())
    local effectIds, effectAdditions = template.EffectIds, template.EffectAdditions
    local effects = {}
    if not XTool.IsTableEmpty(effectIds) then
        for index, effectId in ipairs(effectIds) do
            table.insert(effects, {
                Id = effectId,
                Addition = effectAdditions[index] or 0
            })
        end
    end

    self.Effects = effects
    
    return self.Effects
end

function XRestaurantBuffVM:GetUnlockCost()
    if self.UnlockInfo then
        return self.UnlockInfo
    end
    local template = self._Model:GetSectionBuffTemplate(self:GetBuffId())
    local itemIds, itemCounts = template.UnlockItemIds, template.UnlockItemCounts
    local info = {}
    if not XTool.IsTableEmpty(itemIds) then
        for index, itemId in ipairs(itemIds) do
            table.insert(info, {
                Id = itemId,
                Count = itemCounts[index] or 0
            })
        end
    end
    self.UnlockInfo = info

    return self.UnlockInfo
end

function XRestaurantBuffVM:GetCharacterDict()
    if self.CharDict then
        return self.CharDict
    end
    local dict = {}
    local template = self._Model:GetSectionBuffTemplate(self:GetBuffId())
    local characterIds = template.CharacterIds
    if not XTool.IsTableEmpty(characterIds) then
        for _, charId in ipairs(characterIds) do
            dict[charId] = charId
        end
    end
    self.CharDict = dict

    return dict
end

function XRestaurantBuffVM:GetProductDict()
    local effects = self:GetEffects()
    local dict = {}
    for _, effect in ipairs(effects) do
        local effectId = effect.Id
        local template = self._Model:GetBuffEffectTemplate(effectId)
        local areaType, productIds = template.SectionType, template.ProductIds
        if not XTool.IsTableEmpty(productIds) then
            if not dict[areaType] then
                dict[areaType] = {}
            end
            for _, productId in ipairs(productIds) do
                dict[areaType][productId] = effect.Addition
            end
        end
    end
    self.ProductDict = dict
    
    return dict
end

function XRestaurantBuffVM:GetEffectProductIds(areaType)
    if self.ProductList then
        return self.ProductList
    end
    
    local list = {}
    local effects = self:GetEffects()
    for _, effect in ipairs(effects) do
        local effectId = effect.Id
        local template = self._Model:GetBuffEffectTemplate(effectId)
        if template.SectionType == areaType then
            list = XTool.MergeArray(list, template.ProductIds)
        end
    end
    self.ProductList = list
    
    return list
end

function XRestaurantBuffVM:GetEffectCharacterIds()
    local list
    if self:IsAllApplicable() then
        list = self._OwnControl:GetRecruitCharacterIds()
    else
        local template = self._Model:GetSectionBuffTemplate(self:GetBuffId())
        list = self.CharList or XTool.Clone(template.CharacterIds)
    end
    
    
    return list
end

--- 检查员工是否对Buff生效
---@param charId number 员工Id
---@return boolean
--------------------------
function XRestaurantBuffVM:CheckCharacterEffect(charId)
    if self:IsAllApplicable() then
        return true
    end

    if not XTool.IsNumberValid(charId) then
        return false
    end
    local dict = self:GetCharacterDict()
    return dict[charId] ~= nil
end

--- 是否是全体员工适用, 策划未配置时，对所有员工均生效
---@return boolean
--------------------------
function XRestaurantBuffVM:IsAllApplicable()
    local dict = self:GetCharacterDict()
    return XTool.IsTableEmpty(dict)
end

--- buff增益量
---@param areaType number
---@param characterId number
---@param productId number
---@return number
--------------------------
function XRestaurantBuffVM:GetEffectAddition(areaType, characterId, productId)
    if not self:CheckCharacterEffect(characterId) then
        return 0
    end
    return self:GetProductEffectAddition(areaType, productId)
end

--- buff增益量, 仅用于展示，实际计算需要考虑角色是否拥有此Buff
---@param areaType number
---@param productId number
---@return number
--------------------------
function XRestaurantBuffVM:GetProductEffectAddition(areaType, productId)
    local dict = self:GetProductDict()

    if not dict[areaType] then
        return 0
    end

    if not dict[areaType][productId] then
        return 0
    end

    return dict[areaType][productId]
end


function XRestaurantBuffVM:Unlock()
    self.Data:UpdateUnlock(true)
    --解锁成功时，删除解锁信息，释放内存
    self.UnlockInfo = nil
end

function XRestaurantBuffVM:IsMeetLevel()
    local minLevel = self._Model:GetMinLevelAreaTypeBuff(self:GetAreaType())
    return self._Model:GetRestaurantLv() >= minLevel
end

function XRestaurantBuffVM:IsUnlock()
    return self.Data:IsUnlock()
end

function XRestaurantBuffVM:GetBuffId()
    return self.Data:GetBuffId()
end

function XRestaurantBuffVM:GetAreaType()
    local template = self._Model:GetSectionBuffTemplate(self:GetBuffId())
    return template and template.SectionType or XMVCA.XRestaurant.AreaType.None
end

function XRestaurantBuffVM:IsDefault()
    local template = self._Model:GetSectionBuffTemplate(self:GetBuffId())
    return  template and template.IsDefault or false
end

function XRestaurantBuffVM:GetUnlockLv()
    local template = self._Model:GetSectionBuffTemplate(self:GetBuffId())
    return template and template.UnlockLv or XMVCA.XRestaurant.RestLevelRange.Max
end

function XRestaurantBuffVM:GetName()
    local template = self._Model:GetSectionBuffTemplate(self:GetBuffId())
    return template and template.Name or ""
end

function XRestaurantBuffVM:GetDescription()
    local template = self._Model:GetSectionBuffTemplate(self:GetBuffId())
    return template and template.Desc or ""
end

function XRestaurantBuffVM:IsReachLevel()
    return self._Model:GetRestaurantLv() >= self:GetUnlockLv()
end

function XRestaurantBuffVM:CheckBenchEffect(areaType, characterId, productId)
    return self:GetEffectAddition(areaType, characterId, productId) ~= 0
end

return XRestaurantBuffVM