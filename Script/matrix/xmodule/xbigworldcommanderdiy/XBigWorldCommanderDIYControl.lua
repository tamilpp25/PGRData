local XBWCommanderDIYTypeEntity = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYTypeEntity")

---@class XBigWorldCommanderDIYControl : XEntityControl
---@field private _Model XBigWorldCommanderDIYModel
local XBigWorldCommanderDIYControl = XClass(XEntityControl, "XBigWorldCommanderDIYControl")

local Protocol = {
    BigWorldCommanderFashionUpdateRequest = "BigWorldCommanderFashionUpdateRequest",
}

function XBigWorldCommanderDIYControl:OnInit()
    -- 初始化内部变量
    ---@type XBWCommanderDIYTypeEntity[]
    self._TypeEntitys = false

    self._Gender = 0
    self._UsePartMap = false
    self._PartColorMap = false

    self._PrimitiveGender = 0
    self._PrimitiveUsePartMap = false
    self._PrimitivePartColorMap = false
end

function XBigWorldCommanderDIYControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldCommanderDIYControl:RemoveAgencyEvent()

end

function XBigWorldCommanderDIYControl:OnRelease()
    self._Gender = 0
    self._UsePartMap = false
    self._PartColorMap = false

    self._PrimitiveGender = 0
    self._PrimitiveUsePartMap = false
    self._PrimitivePartColorMap = false
end

-- region Entity

---@return XBWCommanderDIYTypeEntity[]
function XBigWorldCommanderDIYControl:GetTypeEntitys()
    if not self._TypeEntitys then
        local configs = self._Model:GetDlcPlayerFashionTypeConfigs()

        self._TypeEntitys = {}
        for typeId, _ in pairs(configs) do
            table.insert(self._TypeEntitys, self:AddEntity(XBWCommanderDIYTypeEntity, typeId))
        end
        table.sort(self._TypeEntitys, function(entityA, entityB)
            return entityA:GetPriority() > entityB:GetPriority()
        end)
    end

    return self._TypeEntitys
end

---@param entity XBWCommanderDIYPartEntity
function XBigWorldCommanderDIYControl:CheckPartEntityIsUse(entity)
    if entity and not entity:IsNil() then
        return self:GetTypeCurrentUsePart(entity:GetTypeId()) == entity:GetPartId()
    end

    return false
end

---@param entity XBWCommanderDIYEmptyPartEntity
function XBigWorldCommanderDIYControl:CheckEmptyPartEntityIsUse(entity)
    if entity then
        return not XTool.IsNumberValid(self:GetTypeCurrentUsePart(entity:GetTypeId()))
    end

    return false
end

---@param entity XBWCommanderDIYPartEntity
function XBigWorldCommanderDIYControl:CheckPartEntityIsNow(entity)
    if not XTool.IsTableEmpty(self._UsePartMap) then
        if entity and not entity:IsNil() then
            local typeId = entity:GetTypeId()
            local partId = self._UsePartMap[typeId]

            if not XTool.IsNumberValid(partId) then
                partId = self._Model:GetDlcPlayerFashionTypeDefaultPartIdByTypeId(typeId)
            end

            return partId == entity:GetPartId()
        end
    end

    return false
end

---@param entity XBWCommanderDIYEmptyPartEntity
function XBigWorldCommanderDIYControl:CheckEmptyPartEntityIsNow(entity)
    if not XTool.IsTableEmpty(self._UsePartMap) then
        if entity then
            local typeId = entity:GetTypeId()

            return not XTool.IsNumberValid(self._UsePartMap[typeId])
        end
    end

    return false
end

---@param entity XBWCommanderDIYColorEntity
function XBigWorldCommanderDIYControl:CheckColorEntityIsUse(entity, partId)
    if entity and not entity:IsNil() then
        return self:GetPartCurrentUseColor(partId) == entity:GetColorId()
    end

    return false
end

---@param entity XBWCommanderDIYColorEntity
function XBigWorldCommanderDIYControl:CheckColorEntityIsNow(entity, partId)
    if not XTool.IsTableEmpty(self._PartColorMap) then
        if entity and not entity:IsNil() then
            if XTool.IsNumberValid(self._PartColorMap[partId]) then
                local colorId = self._PartColorMap[partId]

                if self._Model:CheckAllowSelectColor(partId) then
                    return colorId == entity:GetColorId()
                end
            end

            local gender = self:GetCurrentValidGender()
            local resIds = self._Model:GetDlcPlayerFashionPartResIdById(partId)
            local resId = resIds[gender]
            local colorId = self._Model:GetDlcPlayerFashionResDefaultColorIdById(resId) or 0

            return colorId == entity:GetColorId()
        end
    end

    return false
end

---@param entity XBWCommanderDIYPartEntity
function XBigWorldCommanderDIYControl:SetUsePartEntity(entity)
    if entity and not entity:IsNil() then
        self:SetUsePart(entity:GetTypeId(), entity:GetPartId())
    end
end

---@param entity XBWCommanderDIYEmptyPartEntity
function XBigWorldCommanderDIYControl:ClearUsePartEntity(entity)
    if entity then
        self:SetUsePart(entity:GetTypeId())
    end
end

---@param entity XBWCommanderDIYColorEntity
function XBigWorldCommanderDIYControl:SetUsePartColorEntity(entity, partId)
    if entity and not entity:IsNil() then
        self:SetUsePartColor(partId, entity:GetColorId())
    end
end

---@return XBWCommanderDIYPartEntity[]
function XBigWorldCommanderDIYControl:GetUsePartEntitys()
    local typeEntitys = self:GetTypeEntitys()
    local result = {}

    if not XTool.IsTableEmpty(typeEntitys) then
        for _, entity in pairs(typeEntitys) do
            local partEntitys = entity:GetPartEntitys()

            if not XTool.IsTableEmpty(partEntitys) then
                for _, partEntity in pairs(partEntitys) do
                    if self:CheckPartEntityIsUse(partEntity) then
                        table.insert(result, partEntity)
                        break
                    end
                end
            end
        end
    end

    return result
end

---@return XBWCommanderDIYPartEntity
function XBigWorldCommanderDIYControl:GetUseFashionPartEntity()
    local entitys = self:GetUsePartEntitys()

    for _, entity in pairs(entitys) do
        if not entity:IsNil() and entity:IsFashion() then
            return entity
        end
    end

    return nil
end

-- endregion

-- region Data

function XBigWorldCommanderDIYControl:SetUsePart(typeId, partId)
    self._Model:SetUsePart(typeId, partId)
end

function XBigWorldCommanderDIYControl:GetTypeCurrentUsePart(typeId)
    return self._Model:GetUsePart(typeId)
end

function XBigWorldCommanderDIYControl:ResetUsePart(typeId)
    local partId = self:GetTypeCurrentUsePart(typeId)

    self:SetUsePart(typeId)
    self:SetUsePartColor(partId)
end

function XBigWorldCommanderDIYControl:GetPartCurrentUseColor(partId)
    return self:GetPartUseColorByGender(partId)
end

function XBigWorldCommanderDIYControl:GetPartUseColorByGender(partId, gender)
    return self._Model:GetUsePartColor(partId, gender)
end

function XBigWorldCommanderDIYControl:SetUsePartColor(partId, colorId)
    self._Model:SetUsePartColor(partId, colorId)
end

function XBigWorldCommanderDIYControl:GetCurrentCharacterId()
    return self._Model:GetCurrentCharacterId()
end

function XBigWorldCommanderDIYControl:GetCurrentNpcId()
    return self._Model:GetCurrentNpcId()
end

function XBigWorldCommanderDIYControl:GetCurrentGender()
    return self._Model:GetGender()
end

function XBigWorldCommanderDIYControl:GetCurrentValidGender()
    return self._Model:GetValidGender()
end

function XBigWorldCommanderDIYControl:SetGender(value)
    self._Model:SetGender(value)
end

-- endregion

-- region Config

function XBigWorldCommanderDIYControl:GetCurrentPartModelIdByPartId(partId)
    ---@type XBigWorldCommanderDIYAgency
    local agency = self:GetAgency()

    return agency:GetCurrentPartModelIdByPartId(partId)
end

function XBigWorldCommanderDIYControl:GetEntryAnimationNameByType(typeId)
    return self._Model:GetDlcPlayerFashionTypeEntryAnimationNameByTypeId(typeId)
end

function XBigWorldCommanderDIYControl:GetDefaultAnimationParamByType(typeId)
    return self._Model:GetDlcPlayerFashionTypeDefaultAnimationParamByTypeId(typeId)
end

-- endregion

-- region Other

function XBigWorldCommanderDIYControl:GetCameraMoveRange()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetFloat("DIYCameraMoveRange")
end

function XBigWorldCommanderDIYControl:ResetCommanderFashion()
    if not XTool.IsTableEmpty(self._UsePartMap) then
        for typeId, partId in pairs(self._UsePartMap) do
            self:SetUsePart(typeId, partId)
        end
    end
    if not XTool.IsTableEmpty(self._PartColorMap) then
        for partId, colorId in pairs(self._PartColorMap) do
            self:SetUsePartColor(partId, colorId)
        end
    end
    if XTool.IsNumberValid(self._Gender) then
        self._Model:SetGender(self._Gender)
    end
end

function XBigWorldCommanderDIYControl:TemporaryFashionInfo()
    local usePartMap = self._Model:GetUsePartMap()
    local partColorMap = self._Model:GetPartColorMap()

    self._UsePartMap = {}
    self._PartColorMap = {}
    self._Gender = self._Model:GetValidGender()
    if not XTool.IsTableEmpty(usePartMap) then
        for typeId, partId in pairs(usePartMap) do
            self._UsePartMap[typeId] = partId
        end
    end
    if not XTool.IsTableEmpty(partColorMap) then
        for partId, colorId in pairs(partColorMap) do
            self._PartColorMap[partId] = colorId
        end
    end
end

function XBigWorldCommanderDIYControl:TemporaryPrimitiveFashionInfo()
    local usePartMap = self._Model:GetUsePartMap()
    local partColorMap = self._Model:GetPartColorMap()

    self._PrimitiveUsePartMap = {}
    self._PrimitivePartColorMap = {}
    self._PrimitiveGender = self._Model:GetValidGender()
    if not XTool.IsTableEmpty(usePartMap) then
        for typeId, partId in pairs(usePartMap) do
            self._PrimitiveUsePartMap[typeId] = partId
        end
    end
    if not XTool.IsTableEmpty(partColorMap) then
        for partId, colorId in pairs(partColorMap) do
            self._PrimitivePartColorMap[partId] = colorId
        end
    end
end

function XBigWorldCommanderDIYControl:SaveFashionInfo(callback)
    local usePartMap = self._Model:GetUsePartMap()
    local partColorMap = self._Model:GetPartColorMap()
    local info = {}

    for typeId, partId in pairs(usePartMap) do
        info[typeId] = {
            PartId = partId,
            ColourId = partColorMap[partId] or 0,
        }
    end

    self:RequestUpdate(self:GetCurrentGender(), info, callback)
end

function XBigWorldCommanderDIYControl:CheckIsSelectGender()
    local gender = self:GetCurrentGender()

    return XTool.IsNumberValid(gender)
end

function XBigWorldCommanderDIYControl:CheckCurrentMaleGender()
    return self:GetCurrentGender() == XEnumConst.PlayerFashion.Gender.Male
end

function XBigWorldCommanderDIYControl:GetNpcPartData()
    ---@type XBigWorldCommanderDIYAgency
    local agency = self:GetAgency()

    return agency:GetNpcPartData()
end

function XBigWorldCommanderDIYControl:CheckNeedSyncCharacter()
    if self._PrimitiveGender ~= self:GetCurrentGender() then
        return true
    end

    local usePartMap = self._Model:GetUsePartMap()
    local partColorMap = self._Model:GetPartColorMap()

    if not XTool.IsTableEmpty(usePartMap) then
        for typeId, partId in pairs(usePartMap) do
            if self._PrimitiveUsePartMap[typeId] ~= partId then
                return true
            end
        end
    end
    if not XTool.IsTableEmpty(partColorMap) then
        for partId, colorId in pairs(partColorMap) do
            if self._PrimitivePartColorMap[partId] ~= colorId then
                return true
            end
        end
    end

    return false
end

function XBigWorldCommanderDIYControl:CheckNeedSyncInfo()
    if self._Gender ~= self:GetCurrentGender() then
        return true
    end

    local usePartMap = self._Model:GetUsePartMap()
    local partColorMap = self._Model:GetPartColorMap()

    if not XTool.IsTableEmpty(usePartMap) then
        for typeId, partId in pairs(usePartMap) do
            if self._UsePartMap[typeId] ~= partId then
                return true
            end
        end
    end
    if not XTool.IsTableEmpty(partColorMap) then
        for partId, colorId in pairs(partColorMap) do
            if self._PartColorMap[partId] ~= colorId then
                return true
            end
        end
    end

    return false
end

function XBigWorldCommanderDIYControl:SyncCharacter()
    if not self:CheckNeedSyncCharacter() then
        return
    end

    local characterId = self._Model:GetCurrentCharacterId()
    local fashionEntity = self:GetUseFashionPartEntity()
    local partData = self:GetNpcPartData()
    local npcId = self:GetCurrentNpcId()
    local fashionId = 0

    if fashionEntity then
        fashionId = fashionEntity:GetFashionId()
    end

    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SYNC_PLAYER_DIY_DATA, {
        NewCharacterId = characterId,
        NewNpcId = npcId,
        PartData = partData,
        FashionId = fashionId,
    })
    XMVCA.XBigWorldCharacter:TryUpdateTeamAfterDIY()
end

function XBigWorldCommanderDIYControl:GetMaterialConfigs(partModelId, colorId)
    if not XTool.IsNumberValid(colorId) then
        return {}
    end

    local colorName = self._Model:GetDlcPlayerFashionColorMaterialNameById(colorId)

    if string.IsNilOrEmpty(colorName) then
        return {}
    end

    local result = XMVCA.XBigWorldResource:GetPartModelMaterials(partModelId, colorName)

    if not result then
        return {}
    end

    return XTool.CsList2LuaTable(result)
end

-- endregion

-- region Protocol

function XBigWorldCommanderDIYControl:RequestUpdate(gender, fashionList, callback)
    XMessagePack.MarkAsTable(fashionList)
    XNetwork.Call(Protocol.BigWorldCommanderFashionUpdateRequest, {
        Gender = gender,
        CommanderFashionList = fashionList,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end
        self:TemporaryFashionInfo()
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("DIYSaveSuccessTip"))
        if callback then
            callback()
        end
    end)
end

-- endregion

return XBigWorldCommanderDIYControl
