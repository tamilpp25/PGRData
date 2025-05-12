local XBWCommanderDIYEntityBase = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYEntityBase")
local XBWCommanderDIYPartEntity = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYPartEntity")
local XBWCommanderDIYEmptyPartEntity = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYEmptyPartEntity")

---@class XBWCommanderDIYTypeEntity : XBWCommanderDIYEntityBase
local XBWCommanderDIYTypeEntity = XClass(XBWCommanderDIYEntityBase, "XBWCommanderDIYTypeEntity")

function XBWCommanderDIYTypeEntity:Ctor()
    self._TypeId = 0
    ---@type XBWCommanderDIYPartEntity[]
    self._PartEntitys = false
    
    ---@type XBWCommanderDIYEmptyPartEntity
    self._TemporaryEntity = false
end

function XBWCommanderDIYTypeEntity:SetData(typeId)
    self:SetTypeId(typeId)
    self:_InitPart()
end

function XBWCommanderDIYTypeEntity:IsEmpty()
    return not XTool.IsNumberValid(self:GetTypeId())
end

function XBWCommanderDIYTypeEntity:SetTypeId(typeId)
    self._TypeId = typeId
end

function XBWCommanderDIYTypeEntity:GetTypeId()
    return self._TypeId
end

function XBWCommanderDIYTypeEntity:GetName()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionTypeNameByTypeId(self:GetTypeId())
    end

    return ""
end

function XBWCommanderDIYTypeEntity:GetPriority()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionTypePriorityByTypeId(self:GetTypeId())
    end

    return 0
end

function XBWCommanderDIYTypeEntity:IsRequired()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionTypeIsRequiredByTypeId(self:GetTypeId())
    end

    return false
end

function XBWCommanderDIYTypeEntity:IsFashion()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionTypeIsFashionByTypeId(self:GetTypeId())
    end

    return false
end

---@return XBWCommanderDIYPartEntity[]
function XBWCommanderDIYTypeEntity:GetPartEntitysWithTemporary()
    if self:IsRequired() then
        return self:GetPartEntitys()
    end

    local result = {}
    local entitys = self:GetPartEntitys()

    if not self._TemporaryEntity then
        self._TemporaryEntity = self:AddChildEntity(XBWCommanderDIYEmptyPartEntity, 0)
        self._TemporaryEntity:SetTypeId(self:GetTypeId())
    end

    table.insert(result, self._TemporaryEntity)
    if not XTool.IsTableEmpty(entitys) then
        for _, partEntity in pairs(entitys) do
            table.insert(result, partEntity)
        end
    end

    return result
end

---@return XBWCommanderDIYPartEntity[]
function XBWCommanderDIYTypeEntity:GetPartEntitys()
    return self._PartEntitys or {}
end

---@return XBWCommanderDIYPartEntity
function XBWCommanderDIYTypeEntity:GetPartEntityByIndex(index)
    return self._PartEntitys[index]
end

function XBWCommanderDIYTypeEntity:OnRelease()
    self._TypeId = 0
    self._PartEntitys = false
end

function XBWCommanderDIYTypeEntity:_InitPart()
    if not self:IsNil() then
        local partIds = self._Model:GetDlcPlayerFashionPartGroupPartIdByTypeId(self:GetTypeId())

        self._PartEntitys = {}
        if not XTool.IsTableEmpty(partIds) then
            for _, partId in pairs(partIds) do
                self:_AddPart(partId)
            end

            table.sort(self._PartEntitys, function(entityA, entityB)
                if entityA:GetPriority() == entityB:GetPriority() then
                    return entityA:GetPartId() < entityB:GetPartId()
                end

                return entityA:GetPriority() > entityB:GetPriority()
            end)
        end
    end
end

function XBWCommanderDIYTypeEntity:_AddPart(partId)
    table.insert(self._PartEntitys, self:AddChildEntity(XBWCommanderDIYPartEntity, partId))
end

return XBWCommanderDIYTypeEntity
