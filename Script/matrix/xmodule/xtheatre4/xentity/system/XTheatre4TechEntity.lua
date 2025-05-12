local XTheatre4EntityBase = require("XModule/XTheatre4/XEntity/System/XTheatre4EntityBase")

---@class XTheatre4TechEntity : XTheatre4EntityBase
local XTheatre4TechEntity = XClass(XTheatre4EntityBase, "XTheatre4TechEntity")

function XTheatre4TechEntity:Ctor()
    ---@type XTheatre4TechEntity[]
    self._PreEntitys = {}
    ---@type table<number, XTheatre4TechEntity>
    self._PreEntitysMap = {}
end

---@param entity XTheatre4TechEntity
function XTheatre4TechEntity:AddPreEntity(entity)
    if not entity:IsEmpty() and entity then
        ---@type XTheatre4TechConfig
        local config = entity:GetConfig()

        table.insert(self._PreEntitys, entity)
        self._PreEntitysMap[config:GetId()] = entity
    end
end

---@return XTheatre4TechEntity[]
function XTheatre4TechEntity:GetPreEntitys()
    return self._PreEntitys
end

function XTheatre4TechEntity:IsActived()
    local activedTech = self._Model:GetActivedTechIdMap()
    local config = self:GetConfig()

    return activedTech[config:GetId()] or false
end

function XTheatre4TechEntity:IsUnlock()
    local preEntitys = self:GetPreEntitys()

    -- 先显示自己的条件
    ---@type XTheatre4TechConfig
    local config = self:GetConfig()
    local condition = config:GetCondition()

    if XTool.IsNumberValid(condition) then
        local isAllow, desc = XConditionManager.CheckCondition(condition)

        if not isAllow then
            return isAllow, desc
        end
    end

    -- 优先显示前序条件
    if not XTool.IsTableEmpty(preEntitys) then
        for _, entity in pairs(preEntitys) do
            local isUnlock, desc = entity:IsUnlock()

            if not isUnlock then
                --前序的desc，改成“未解锁”
                desc = XUiHelper.GetText("NotUnlock")
                
                return isUnlock, desc
            end
            if not entity:IsActived() then
                return false
            end
        end
    end

    return true
end

function XTheatre4TechEntity:IsShowRedPoint()
    if self:IsUnlock() and not self:IsActived() then
        local itemCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.Theatre4TechTreeCoin)
        ---@type XTheatre4TechConfig
        local config = self:GetConfig()

        return config:GetCost() <= itemCount
    end

    return false
end

return XTheatre4TechEntity
