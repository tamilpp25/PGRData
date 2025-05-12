---@class XBigWorldCommanderDIYAgency : XAgency
---@field private _Model XBigWorldCommanderDIYModel
local XBigWorldCommanderDIYAgency = XClass(XAgency, "XBigWorldCommanderDIYAgency")

function XBigWorldCommanderDIYAgency:OnInit()
    -- 初始化一些变量
end

function XBigWorldCommanderDIYAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
end

function XBigWorldCommanderDIYAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XBigWorldCommanderDIYAgency:OpenMainUi()
    XMVCA.XBigWorldUI:Open("UiBigWorldDIY")
end

function XBigWorldCommanderDIYAgency:UpdateData(gender, fashionList, commanderFashionBags)
    self._Model:SetGender(gender)
    self._Model:UpdateFashion(fashionList)
    -- todo
end

---@param displayController XUiModelDisplayController
function XBigWorldCommanderDIYAgency:LoadCurrentModel(displayController, parent)
    if not displayController then
        return
    end

    local modelId, isExist = self:LoadFashionModel(displayController, parent)

    if not isExist then
        self:LoadAllPartModel(displayController, parent, modelId)
        self:LoadMaterials(displayController, parent, modelId)
    end

    return modelId
end

---@param displayController XUiModelDisplayController
function XBigWorldCommanderDIYAgency:LoadFashionModel(displayController, parent)
    if not displayController then
        return
    end

    local partMap = self._Model:GetUsePartMap()
    local typeConfigs = self._Model:GetDlcPlayerFashionTypeConfigs()
    local modelId = ""
    local isExist = false

    for typeId, config in pairs(typeConfigs) do
        local isFashion = self._Model:GetDlcPlayerFashionTypeIsFashionByTypeId(typeId)

        if isFashion then
            local partId = partMap[typeId] or config.DefaultPartId

            if XTool.IsNumberValid(partId) then
                local resId = self:GetCurrentResIdByPartId(partId)

                if XTool.IsNumberValid(resId) then
                    local fashionId = self._Model:GetDlcPlayerFashionResFashionIdById(resId)
                    modelId = XMVCA.XBigWorldCharacter:GetUiModelIdByFashionId(fashionId)

                    if not displayController:IsModelExist(modelId) then
                        local modelUrl = XMVCA.XBigWorldResource:GetModelUrl(modelId)
                        local controller = XMVCA.XBigWorldResource:GetModelControllerUrl(modelId)

                        displayController:AddMultiModel(modelId, typeId, modelUrl, controller, parent,
                            typeof(CS.XUiModelComponentMaterials))
                    else
                        displayController:SetModelActive(modelId, true)
                        isExist = true
                    end
                end
            end

            break
        end
    end

    return modelId, isExist
end

---@param displayController XUiModelDisplayController
function XBigWorldCommanderDIYAgency:LoadAllPartModel(displayController, parent, modelId)
    if not displayController then
        return
    end
    if not displayController:IsModelExist(modelId) then
        return
    end

    local model = displayController:GetModelObject(modelId, XEnumConst.PlayerFashion.PartType.Fashion)

    if XTool.UObjIsNil(model) then
        return
    end

    local partMap = self._Model:GetUsePartMap()
    local typeConfigs = self._Model:GetDlcPlayerFashionTypeConfigs()

    for typeId, config in pairs(typeConfigs) do
        if not displayController:IsModelComponentExist(modelId, typeId) then
            local isFashion = self._Model:GetDlcPlayerFashionTypeIsFashionByTypeId(typeId)

            if not isFashion then
                local partId = partMap[typeId] or config.DefaultPartId

                if XTool.IsNumberValid(partId) then
                    local partModelId = self:GetCurrentPartModelIdByPartId(partId)

                    if not string.IsNilOrEmpty(partModelId) then
                        local modelUrl = XMVCA.XBigWorldResource:GetPartModelUrlByPartId(partModelId)

                        displayController:AddModelComponent(modelId, typeId, modelUrl, "", model.transform,
                            typeof(CS.XUiModelComponentMaterials))

                        local partModel = displayController:GetModelObject(modelId, typeId)

                        if not XTool.UObjIsNil(partModel) then
                            local rigger = partModel:GetComponent(typeof(CS.XBoneMeshRigger))

                            if not XTool.UObjIsNil(rigger) then
                                rigger:SetTarget(model.transform)
                            end
                        end
                    end
                end
            end
        end
    end
end

---@param displayController XUiModelDisplayController
function XBigWorldCommanderDIYAgency:LoadMaterials(displayController, parent, modelId)
    if not displayController then
        return
    end
    if not displayController:IsModelExist(modelId) then
        return
    end

    local colorMap = self._Model:GetPartColorMap()

    for partId, _ in pairs(colorMap) do
        if self._Model:CheckAllowSelectColor(partId) then
            local colorId = self._Model:GetUsePartColor(partId)

            if XTool.IsNumberValid(colorId) then
                local partModelId = self:GetCurrentPartModelIdByPartId(partId)
                local colorName = self._Model:GetDlcPlayerFashionColorMaterialNameById(colorId)

                if not string.IsNilOrEmpty(partModelId) and not string.IsNilOrEmpty(colorName) then
                    local materials = XMVCA.XBigWorldResource:GetPartModelMaterials(partModelId, colorName)

                    if materials then
                        local typeId = self._Model:GetDlcPlayerFashionPartTypeIdById(partId)

                        for i = 0, materials.Count - 1 do
                            displayController:SetModelComponentMaterials(modelId, typeId, materials[i].PartNodeName,
                                materials[i].MaterialPathList)
                        end
                    end
                end
            end
        end
    end
end

function XBigWorldCommanderDIYAgency:GetNpcPartModelData(partList)
    local result = {}

    if not XTool.IsTableEmpty(partList) then
        for _, part in ipairs(partList) do
            local partId = part.PartId
            local colorId = part.ColourId
            local partModelId = self:GetCurrentPartModelIdByPartId(partId)

            if not string.IsNilOrEmpty(partModelId) then
                if self._Model:CheckAllowSelectColor(partId) and XTool.IsNumberValid(colorId) then
                    local colorName = self._Model:GetDlcPlayerFashionColorMaterialNameById(colorId)
                    
                    result[partModelId] = colorName or ""
                else
                    result[partModelId] = ""
                end
            end
        end
    end

    return result
end

function XBigWorldCommanderDIYAgency:GetColorNameByPartId(partId)
    local colorName = ""

    if self._Model:CheckAllowSelectColor(partId) then
        local colorId = self._Model:GetUsePartColor(partId)

        if XTool.IsNumberValid(colorId) then
            colorName = self._Model:GetDlcPlayerFashionColorMaterialNameById(colorId)
        end
    end

    return colorName
end

function XBigWorldCommanderDIYAgency:GetPartListByGender(gender)
    local partMap = self._Model:GetUsePartMap()
    local typeConfigs = self._Model:GetDlcPlayerFashionTypeConfigs()
    local result = {}

    for typeId, config in pairs(typeConfigs) do
        local isFashion = self._Model:GetDlcPlayerFashionTypeIsFashionByTypeId(typeId)

        if not isFashion then
            local partId = partMap[typeId] or config.DefaultPartId

            if XTool.IsNumberValid(partId) then
                local colorId = self._Model:GetUsePartColor(partId)

                table.insert(result, {
                    PartId = partId,
                    ColourId = colorId or 0,
                })
            end
        end
    end

    return result
end

function XBigWorldCommanderDIYAgency:GetNpcPartDataByGender(gender)
    local partList = self:GetPartListByGender(gender)

    return {
        PartList  = partList
    }
end

function XBigWorldCommanderDIYAgency:GetNpcPartData()
    return self:GetNpcPartDataByGender(self._Model:GetGender())
end

function XBigWorldCommanderDIYAgency:GetCurrentPartModelIdByPartId(partId)
    local resId = self:GetCurrentResIdByPartId(partId)

    return self._Model:GetDlcPlayerFashionResPartModelIdById(resId)
end

function XBigWorldCommanderDIYAgency:GetPartModelIdByPartId(partId, gender)
    local resId = self:GetResIdByPartId(partId, gender)

    return self._Model:GetDlcPlayerFashionResPartModelIdById(resId)
end

function XBigWorldCommanderDIYAgency:GetCurrentDefaultColorIdByPartId(partId)
    local resId = self:GetCurrentResIdByPartId(partId)

    return self._Model:GetDlcPlayerFashionResDefaultColorIdById(resId)
end

function XBigWorldCommanderDIYAgency:GetCurrentResIdByPartId(partId)
    return self:GetResIdByPartId(partId)
end

function XBigWorldCommanderDIYAgency:GetResIdByPartId(partId, gender)
    return self._Model:GetResIdByPartId(partId, gender)
end

function XBigWorldCommanderDIYAgency:GetCurrentCommandantId()
    return self._Model:GetCurrentCharacterId()
end

function XBigWorldCommanderDIYAgency:GetCurrentFashionId()
    local partId = self._Model:GetUsePart(XEnumConst.PlayerFashion.PartType.Fashion)
    local resId = self:GetCurrentResIdByPartId(partId)

    return self._Model:GetDlcPlayerFashionResFashionIdById(resId)
end

return XBigWorldCommanderDIYAgency
