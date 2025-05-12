local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiModelDisplayController = require("XUi/XUiCommon/XUiModelDisplay/XUiModelDisplayController")
local XUiBigWorldDIYGridPosition = require("XUi/XUiBigWorld/XCommanderDIY/XUiBigWorldDIYGridPosition")
local XUiBigWorldDIYGridColour = require("XUi/XUiBigWorld/XCommanderDIY/XUiBigWorldDIYGridColour")

---@class XUiBigWorldDIY : XBigWorldUi
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field PanelAsset UnityEngine.RectTransform
---@field BtnFashion XUiComponent.XUiButton
---@field BtnHeadPortrait XUiComponent.XUiButton
---@field PanelTabGroup XUiButtonGroup
---@field BtnResetting XUiComponent.XUiButton
---@field BtnSave XUiComponent.XUiButton
---@field BtnEyes XUiComponent.XUiButton
---@field BtnHand XUiComponent.XUiButton
---@field ListPosition UnityEngine.RectTransform
---@field GridPosition UnityEngine.RectTransform
---@field PanelColour UnityEngine.RectTransform
---@field ListColour UnityEngine.RectTransform
---@field GridColour UnityEngine.RectTransform
---@field PanelGender UnityEngine.RectTransform
---@field TxtName UnityEngine.UI.Text
---@field BtnSelectMan XUiComponent.XUiButton
---@field BtnSelectWoman XUiComponent.XUiButton
---@field PanelComponent UnityEngine.RectTransform
---@field BtnChange XUiComponent.XUiButton
---@field BtnLensIn XUiComponent.XUiButton
---@field BtnLensOut XUiComponent.XUiButton
---@field SliderCharacter UnityEngine.UI.Slider
---@field PanelDrag XDrag
---@field _Control XBigWorldCommanderDIYControl
local XUiBigWorldDIY = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldDIY")

-- region 生命周期

function XUiBigWorldDIY:OnAwake()
    ---@type XBWCommanderDIYTypeEntity[]
    self._TypeEntitys = self._Control:GetTypeEntitys()
    self._TabGroupList = {
        self.BtnFashion,
        self.BtnHeadPortrait,
        self.BtnEyes,
        self.BtnHand,
    }

    ---@type XUiModelDisplayController
    self._ModelContorller = XUiModelDisplayController.New(self.UiModelGo, true)
    self._PartDynamicTable = XDynamicTableNormal.New(self.ListPosition)
    self._CurrentSelectTypeIndex = 0
    self._CurrentSelectPartIndex = 0
    ---@type XBWCommanderDIYColorEntity[]
    self._CurrentColorEntitys = false

    ---@type XUiBigWorldDIYGridColour
    self._CurrentSelectColorGrid = false
    ---@type XUiBigWorldDIYGridColour[]
    self._ColorGridList = {}

    self._CurrentEntryAnimation = false

    self._MaleModelRoot = self.UiModelGo.transform:FindTransform("PanelRoleCommandantMan")
    self._FemaleModelRoot = self.UiModelGo.transform:FindTransform("PanelRoleCommandantWoman")
    self._NearMaleCamera = self.UiModelGo.transform:FindTransform("VCameraManNear")
    self._NearFemaleCamera = self.UiModelGo.transform:FindTransform("VCameraWomanNear")
    self.MaleChangeEffect = self.UiModelGo.transform:FindTransform("PanelRoleEffectMan")
    self.FemaleChangeEffect = self.UiModelGo.transform:FindTransform("PanelRoleEffectWoman")
    self._CameraControl = self.UiModelGo:GetComponent(typeof(CS.XUiComponent.XUiStateControl))

    self._IsInit = false
    self._IsFrist = false

    self._CameraMoveRange = self._Control:GetCameraMoveRange()
    self._OriginalMaleCameraPosY = self._NearMaleCamera.transform.localPosition.y
    self._OriginalFemaleCameraPosY = self._NearFemaleCamera.transform.localPosition.y

    self._TweenTimer = false

    self:_RegisterButtonClicks()
end

function XUiBigWorldDIY:OnStart()
    self._Control:TemporaryFashionInfo()
    self._Control:TemporaryPrimitiveFashionInfo()
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self:_InitFirstPanel()
    self:_ShowPanel()
end

function XUiBigWorldDIY:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldDIY:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldDIY:OnDestroy()

end

-- endregion

function XUiBigWorldDIY:ChangeSelect(index)
    if self._CurrentSelectPartIndex then
        ---@type XUiBigWorldDIYGridPosition
        local selectGrid = self._PartDynamicTable:GetGridByIndex(self._CurrentSelectPartIndex)

        if selectGrid then
            selectGrid:SetSelect(false)
        end
    end

    self:ChangeSelectPart(index)
end

function XUiBigWorldDIY:ChangeSelectPart(index)
    if index ~= self._CurrentSelectPartIndex then
        self:_ChangeSelectPart(index, self._CurrentSelectPartIndex)
        self._CurrentSelectPartIndex = index
        self:_PlayCurrentEffect()
    end
end

---@param entity XBWCommanderDIYColorEntity
function XUiBigWorldDIY:ChangeSelectColor(grid, entity)
    if self._CurrentSelectColorGrid then
        self._CurrentSelectColorGrid:SetSelect(false)
    end

    self._CurrentSelectColorGrid = grid

    local materials = entity:GetMaterialConfigs()
    local fashionEntity = self._Control:GetUseFashionPartEntity()

    if fashionEntity and not fashionEntity:IsNil() then
        local partEntity = entity:GetPartEntity()

        if partEntity and not partEntity:IsNil() then
            for _, material in pairs(materials) do

                self._ModelContorller:SetModelComponentMaterials(fashionEntity:GetFashionModelId(),
                    partEntity:GetTypeId(), material.PartNodeName, material.MaterialPathList)
            end
        end
    end
end

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIY:ShowColor(entity)
    local isShowColor = entity:IsAllowSelectColor()

    if isShowColor then
        self._CurrentColorEntitys = entity:GetColorEntitys()
        self.PanelColour.gameObject:SetActiveEx(true)
        self:_RefreshColorList()
    else
        self:_HideColorPanel()
    end
end

function XUiBigWorldDIY:Close()
    self._Control:SyncCharacter()
    XMVCA.XBigWorldUI:Close(self.Name)
end

-- region 按钮事件

function XUiBigWorldDIY:OnBtnBackClick()
    if self._Control:CheckNeedSyncInfo() then
        local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

        confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("DIYConfirmTips"))
        confirmData:InitToggleActive(false)
        confirmData:InitCancelClick(nil, function()
            self._Control:ResetCommanderFashion()
            self:Close()
        end)
        confirmData:InitSureClick(nil, function()
            self._Control:SaveFashionInfo(Handler(self, self.Close))
        end)
        XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
    else
        self:Close()
    end
end

function XUiBigWorldDIY:OnBtnResettingClick()
    local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

    confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("DIYResettingTips"))
    confirmData:InitToggleActive(false)
    confirmData:InitSureClick(nil, function()
        self._Control:ResetCommanderFashion()
        self._ModelContorller:DestroyAllModel()
        self:_ResetDragRotation()
        self:_LoadCurrentModel()
        self:_RefreshTabGroup()
        self:_SetDragTarget()
        self:_PlayResettingAction()
    end)

    XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
end

function XUiBigWorldDIY:OnBtnSaveClick()
    if self._IsFrist then
        local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

        confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("DIYConfirmTips"))
        confirmData:InitToggleActive(false)
        confirmData:InitSureClick(nil, function()
            self._Control:SaveFashionInfo(Handler(self, self.Close))
        end)
        XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
    else
        self._Control:SaveFashionInfo(Handler(self, self._RefreshTabGroup))
    end
end

function XUiBigWorldDIY:OnBtnSelectManClick()
    local maleEnum = XEnumConst.PlayerFashion.Gender.Male
    
    self._Control:SetGender(maleEnum)
    self:_ShowPanel()
    self:_ChangeModel(maleEnum)
    self:_PlayChangeSexAction()
end

function XUiBigWorldDIY:OnBtnSelectWomanClick()
    local femaleEnum = XEnumConst.PlayerFashion.Gender.Female

    self._Control:SetGender(femaleEnum)
    self:_ShowPanel()
    self:_ChangeModel(femaleEnum)
    self:_PlayChangeSexAction()
end

function XUiBigWorldDIY:OnBtnChangeClick()
    local gender = self._Control:GetCurrentValidGender()

    if gender == XEnumConst.PlayerFashion.Gender.Male then
        self:_ChangeSex(XEnumConst.PlayerFashion.Gender.Female)
    else
        self:_ChangeSex(XEnumConst.PlayerFashion.Gender.Male)
    end
    self:_PlayChangeSexAction()
end

function XUiBigWorldDIY:OnBtnLensInClick()
    self:_ChangeBodyCamera(false)
end

function XUiBigWorldDIY:OnBtnLensOutClick()
    self:_ChangeBodyCamera(true)
end

function XUiBigWorldDIY:OnSliderCharacterChange(value)
    local offset = value * self._CameraMoveRange

    self:_MoveNearCamera(offset)
end

function XUiBigWorldDIY:OnTabGroupClick(index)
    self:_RefreshPartList(index)
    self:_ChangeTypeCamera(index)
end

---@param grid XUiBigWorldDIYGridPosition
function XUiBigWorldDIY:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local entity = self._PartDynamicTable:GetData(index)

        grid:Refresh(entity, index)
        if self._Control:CheckPartEntityIsUse(entity) then
            self._CurrentSelectPartIndex = index
        end
    end
end

-- endregion

-- region 私有方法

function XUiBigWorldDIY:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
    self:RegisterClickEvent(self.BtnResetting, self.OnBtnResettingClick, true)
    self:RegisterClickEvent(self.BtnSave, self.OnBtnSaveClick, true)
    self:RegisterClickEvent(self.BtnSelectMan, self.OnBtnSelectManClick, true)
    self:RegisterClickEvent(self.BtnSelectWoman, self.OnBtnSelectWomanClick, true)
    self:RegisterClickEvent(self.BtnChange, self.OnBtnChangeClick, true)
    self:RegisterClickEvent(self.BtnLensIn, self.OnBtnLensInClick, true)
    self:RegisterClickEvent(self.BtnLensOut, self.OnBtnLensOutClick, true)
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderCharacter, self.OnSliderCharacterChange, true)
    self.PanelTabGroup:Init(self._TabGroupList, Handler(self, self.OnTabGroupClick))
end

function XUiBigWorldDIY:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldDIY:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldDIY:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldDIY:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldDIY:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldDIY:_InitTypeTab()
    if not XTool.IsTableEmpty(self._TypeEntitys) then
        for i, tab in pairs(self._TabGroupList) do
            local entity = self._TypeEntitys[i]

            if entity and not entity:IsNil() then
                tab:SetNameByGroup(0, entity:GetName())
            end
        end
    end

    self.PanelTabGroup:SelectIndex(1)
end

function XUiBigWorldDIY:_InitSexGroup()
    local gender = self._Control:GetCurrentValidGender()

    self:_ChangeSex(gender)
end

function XUiBigWorldDIY:_InitDynamicTable()
    self._PartDynamicTable:SetDelegate(self)
    self._PartDynamicTable:SetProxy(XUiBigWorldDIYGridPosition, self)
end

function XUiBigWorldDIY:_InitComponent()
    self:_InitTypeTab()
    self:_InitSexGroup()
    self:_InitDynamicTable()
    self._IsInit = true
end

function XUiBigWorldDIY:_InitFirstPanel()
    if not self._Control:CheckIsSelectGender() then
        self._IsFrist = true
        self.BtnBack.gameObject:SetActiveEx(false)
        self.BtnResetting.gameObject:SetActiveEx(false)
        self.BtnSave:SetNameByGroup(0, XMVCA.XBigWorldService:GetText("DIYFirstConfirmText"))
    else
        self._IsFrist = false
        self.BtnBack.gameObject:SetActiveEx(true)
        self.BtnResetting.gameObject:SetActiveEx(true)
    end
end

function XUiBigWorldDIY:_MoveNearCamera(offset)
    if self._Control:CheckCurrentMaleGender() then
        local pos = self._NearMaleCamera.transform.localPosition

        offset = self._OriginalMaleCameraPosY - offset
        self._NearMaleCamera.transform.localPosition = Vector3(pos.x, offset, pos.z)
    else
        local pos = self._NearFemaleCamera.transform.localPosition

        offset = self._OriginalFemaleCameraPosY - offset
        self._NearFemaleCamera.transform.localPosition = Vector3(pos.x, offset, pos.z)
    end
end

function XUiBigWorldDIY:_ShowPanel()
    if self._Control:CheckIsSelectGender() then
        self:_ShowComponentPanel()
        self:_LoadCurrentModel()
    else
        self:_ShowGenderPanel()
        self:_LoadAllModel()
    end
end

function XUiBigWorldDIY:_ShowGenderPanel()
    self.PanelComponent.gameObject:SetActiveEx(false)
    self.PanelGender.gameObject:SetActiveEx(true)
    self:_ChangeCamera("Main")
end

function XUiBigWorldDIY:_ShowComponentPanel()
    self.PanelComponent.gameObject:SetActiveEx(true)
    self.PanelGender.gameObject:SetActiveEx(false)
    self:_InitComponent()
end

function XUiBigWorldDIY:_HideColorPanel()
    self._CurrentColorEntitys = false
    self:_RefreshColorList()
    self.PanelColour.gameObject:SetActiveEx(false)
end

function XUiBigWorldDIY:_ChangeSex(index)
    self._Control:SetGender(index)
    self:_ResetDragRotation()
    self:_ChangeTypeCamera(self._CurrentSelectTypeIndex)
    if index == XEnumConst.PlayerFashion.Gender.Male then
        self:_ChangeModel(XEnumConst.PlayerFashion.Gender.Male)
    else
        self:_ChangeModel(XEnumConst.PlayerFashion.Gender.Female)
    end
    self:_RefreshComponentPanel()
    self:_SetDragTarget()
    self:_PlayCurrentEffect()
end

function XUiBigWorldDIY:_RefreshTabGroup()
    local currentIndex = self._CurrentSelectTypeIndex or 1

    self._CurrentSelectTypeIndex = 0
    self.PanelTabGroup:SelectIndex(currentIndex)
end

function XUiBigWorldDIY:_RefreshComponentPanel()
    if self._IsInit then
        self:_RefreshTabGroup()
    end
end

function XUiBigWorldDIY:_RefreshPartList(index)
    if self._CurrentSelectTypeIndex ~= index then
        local entity = self._TypeEntitys[index]

        self:_RefreshAnimation(index)
        self:_PlayDragRotationTween()
        if entity and not entity:IsNil() then
            local entitys = entity:GetPartEntitysWithTemporary()

            if XTool.IsTableEmpty(entitys) then
                self:_HideColorPanel()
            end
            self._CurrentSelectTypeIndex = index
            self._PartDynamicTable:SetDataSource(entitys)
            self._PartDynamicTable:ReloadDataSync()
        end
    end
end

function XUiBigWorldDIY:_RefreshAnimation(index)
    local modelId = self:_GetCurrentModelId()
    local animator = self._ModelContorller:GetModelAnimator(modelId, XEnumConst.PlayerFashion.PartType.Fashion)

    if not XTool.UObjIsNil(animator) then
        local entryAnimation = self._Control:GetEntryAnimationNameByType(index)

        if self._CurrentEntryAnimation then
            if string.IsNilOrEmpty(entryAnimation) then
                self._ModelContorller:PlayAnimation(modelId, self._CurrentEntryAnimation .. "_End")
                animator:SetInteger("ChangeParam", 0)
                self._CurrentEntryAnimation = false
            else
                if entryAnimation ~= self._CurrentEntryAnimation then
                    self._ModelContorller:PlayAnimation(modelId, self._CurrentEntryAnimation .. "_End")
                    self._CurrentEntryAnimation = entryAnimation
                    animator:SetInteger("ChangeParam", index)
                end
            end
        else
            if not string.IsNilOrEmpty(entryAnimation) then
                self._ModelContorller:PlayAnimation(modelId, entryAnimation .. "_Start")
                self._CurrentEntryAnimation = entryAnimation
            end
        end
    end
end

function XUiBigWorldDIY:_RefreshColorList()
    if not XTool.IsTableEmpty(self._CurrentColorEntitys) then
        ---@type XBWCommanderDIYPartEntity
        local partEntity = self._PartDynamicTable:GetData(self._CurrentSelectPartIndex)

        for i, entity in pairs(self._CurrentColorEntitys) do
            local grid = self._ColorGridList[i]

            if not grid then
                local gridObject = XUiHelper.Instantiate(self.GridColour, self.ListColour)

                grid = XUiBigWorldDIYGridColour.New(gridObject, self)
                self._ColorGridList[i] = grid
            end

            if self._Control:CheckColorEntityIsUse(entity, partEntity:GetPartId()) then
                self._CurrentSelectColorGrid = grid
            end

            grid:Open()
            grid:Refresh(entity, partEntity:GetPartId())
        end
        for i = table.nums(self._CurrentColorEntitys) + 1, table.nums(self._ColorGridList) do
            self._ColorGridList[i]:Close()
        end
    else
        for _, grid in pairs(self._ColorGridList) do
            grid:Close()
        end
    end
end

function XUiBigWorldDIY:_ChangeModel(gender)
    local maleEnum = XEnumConst.PlayerFashion.Gender.Male
    local femaleEnum = XEnumConst.PlayerFashion.Gender.Female

    self:_TryLoadModel(maleEnum)
    self:_TryLoadModel(femaleEnum)
    self:_SetModelActive(maleEnum, gender == maleEnum)
    self:_SetModelActive(femaleEnum, gender == femaleEnum)
end

function XUiBigWorldDIY:_ChangeCamera(key)
    self._CameraControl:ChangeState(key)
end

function XUiBigWorldDIY:_ChangeTypeCamera(typeId)
    if typeId == XEnumConst.PlayerFashion.PartType.Fashion then
        self:_ChangeBodyCamera(false)
    elseif typeId == XEnumConst.PlayerFashion.PartType.Eyes then
        self:_ChangeCamera(self:_GetCurrentEyesCameraKey())
        self:_ChangeLensActive(false)
    elseif typeId == XEnumConst.PlayerFashion.PartType.Hair then
        self:_ChangeCamera(self:_GetCurrentHairCameraKey())
        self:_ChangeLensActive(false)
    elseif typeId == XEnumConst.PlayerFashion.PartType.Hand then
        self:_ChangeCamera(self:_GetCurrentHandCameraKey())
        self:_ChangeLensActive(false)
    end
end

function XUiBigWorldDIY:_ChangeBodyCamera(isIn)
    if isIn then
        self:_ChangeCamera(self:_GetCurrentNearBodyCameraKey())
        self:_ChangeCameraLens(true)
    else
        self:_ChangeCamera(self:_GetCurrentBodyCameraKey())
        self:_ChangeCameraLens(false)
    end
end

function XUiBigWorldDIY:_ChangeCameraLens(isIn)
    self.BtnLensOut.gameObject:SetActiveEx(not isIn)
    self.BtnLensIn.gameObject:SetActiveEx(isIn)

    if isIn then
        self.SliderCharacter.value = 0
    end
end

function XUiBigWorldDIY:_ChangeLensActive(isActive)
    self.BtnLensOut.gameObject:SetActiveEx(isActive)
    self.BtnLensIn.gameObject:SetActiveEx(isActive)
end

function XUiBigWorldDIY:_GetCurrentBodyCameraKey()
    if self._Control:CheckCurrentMaleGender() then
        return "ManBody"
    end

    return "WomanBody"
end

function XUiBigWorldDIY:_GetCurrentHairCameraKey()
    if self._Control:CheckCurrentMaleGender() then
        return "ManHair"
    end

    return "WomanHair"
end

function XUiBigWorldDIY:_GetCurrentEyesCameraKey()
    if self._Control:CheckCurrentMaleGender() then
        return "ManEyes"
    end

    return "WomanEyes"
end

function XUiBigWorldDIY:_GetCurrentHandCameraKey()
    if self._Control:CheckCurrentMaleGender() then
        return "ManHand"
    end

    return "WomanHand"
end

function XUiBigWorldDIY:_GetCurrentNearBodyCameraKey()
    if self._Control:CheckCurrentMaleGender() then
        return "ManNearBody"
    end

    return "WomanNearBody"
end

function XUiBigWorldDIY:_LoadCurrentModel()
    self:_TryLoadModel(self._Control:GetCurrentGender())
end

function XUiBigWorldDIY:_LoadModel(modelId, gender)
    if not self._ModelContorller:IsModelExist(modelId) then
        local modelUrl = XMVCA.XBigWorldResource:GetModelUrl(modelId)
        local controllerUrl = XMVCA.XBigWorldResource:GetModelControllerUrl(modelId)
        local parent = gender == XEnumConst.PlayerFashion.Gender.Female and self._FemaleModelRoot or self._MaleModelRoot

        self._ModelContorller:AddMultiModel(modelId, 1, modelUrl, controllerUrl, parent,
            typeof(CS.XUiModelComponentMaterials))
    end
end

function XUiBigWorldDIY:_LoadAllModel()
    local entitys = self._Control:GetUsePartEntitys()

    self:_TryLoadModel(XEnumConst.PlayerFashion.Gender.Male, entitys)
    self:_TryLoadModel(XEnumConst.PlayerFashion.Gender.Female, entitys)
end

---@param entitys XBWCommanderDIYPartEntity[]
function XUiBigWorldDIY:_LoadAllPartModel(modelId, entitys, gender)
    local parent = gender == XEnumConst.PlayerFashion.Gender.Female and self._FemaleModelRoot or self._MaleModelRoot

    for _, entity in pairs(entitys) do
        if not entity:IsNil() and not entity:IsFashion() then
            local partModelId = entity:GetPartModelIdByGender(gender)
            local partType = entity:GetTypeId()

            self:_LoadPart(modelId, partModelId, partType, parent)
            self:_SetPartMaterials(modelId, entity:GetPartId(), partModelId, partType, gender)
        end
    end
end

function XUiBigWorldDIY:_LoadPart(modelId, partModelId, partType, parent)
    if string.IsNilOrEmpty(modelId) or string.IsNilOrEmpty(partModelId) or not XTool.IsNumberValid(partType) then
        return
    end

    if self._ModelContorller:IsModelExist(modelId) and not self._ModelContorller:IsModelComponentExist(modelId, partType) then
        local partUrl = XMVCA.XBigWorldResource:GetPartModelUrlByPartId(partModelId)
        local modelBone = self._ModelContorller:GetModelObject(modelId, XEnumConst.PlayerFashion.PartType.Fashion)

        self._ModelContorller:AddModelComponent(modelId, partType, partUrl, "", parent,
            typeof(CS.XUiModelComponentMaterials))

        local model = self._ModelContorller:GetModelObject(modelId, partType)

        if not XTool.UObjIsNil(model) and not XTool.UObjIsNil(modelBone) then
            local rigger = model:GetComponent(typeof(CS.XBoneMeshRigger))

            if not XTool.UObjIsNil(rigger) then
                rigger:SetTarget(modelBone.transform)
            end
        end
    end
end

function XUiBigWorldDIY:_ChangePart(modelId, partModelId, partType, parent, partId)
    if string.IsNilOrEmpty(modelId) or string.IsNilOrEmpty(partModelId) or not XTool.IsNumberValid(partType) then
        return
    end

    local modelBone = self._ModelContorller:GetModelObject(modelId, 1)
    local partUrl = XMVCA.XBigWorldResource:GetPartModelUrlByPartId(partModelId)

    self._ModelContorller:ChangeModelComponent(modelId, partType, partUrl, "", parent)

    local model = self._ModelContorller:GetModelObject(modelId, partType)

    if not XTool.UObjIsNil(model) and not XTool.UObjIsNil(modelBone) then
        local rigger = model:GetComponent(typeof(CS.XBoneMeshRigger))

        if not XTool.UObjIsNil(rigger) then
            rigger:SetTarget(modelBone.transform)
        end
    end
    self:_SetPartMaterials(modelId, partId, partModelId, partType)
end

function XUiBigWorldDIY:_ChangeFashion(modelId, oldModelId)
    if string.IsNilOrEmpty(modelId) or string.IsNilOrEmpty(oldModelId) then
        return
    end

    if self._ModelContorller:IsModelExist(oldModelId) then
        self._ModelContorller:SetModelActive(oldModelId, false)
    end
    if self._ModelContorller:IsModelExist(modelId) then
        local entitys = self._Control:GetUsePartEntitys()
        local parent = self._Control:CheckCurrentMaleGender() and self._MaleModelRoot or self._FemaleModelRoot

        self._ModelContorller:SetModelActive(modelId, true)
        for _, entity in pairs(entitys) do
            if not entity:IsFashion() then
                self:_ChangePart(modelId, entity:GetPartModelId(), entity:GetTypeId(), parent, entity:GetPartId())
            end
        end
    else
        self:_LoadCurrentModel()
    end
end

function XUiBigWorldDIY:_ChangeSelectPart(selectIndex, oldSelectIndex)
    ---@type XBWCommanderDIYPartEntity
    local entity = self._PartDynamicTable:GetData(selectIndex)

    if entity then
        if entity:IsTemporary() then
            self:_SetPartActive(entity:GetCurrentGender(), entity:GetTypeId(), false)
        elseif not entity:IsNil() then
            if entity:IsFashion() then
                if oldSelectIndex then
                    local oldEntity = self._PartDynamicTable:GetData(oldSelectIndex)

                    if oldEntity and not oldEntity:IsNil() then
                        self:_ChangeFashion(entity:GetFashionModelId(), oldEntity:GetFashionModelId())
                    end
                end
            else
                local fashionEntity = self._Control:GetUseFashionPartEntity()

                if fashionEntity then
                    local modelId = fashionEntity:GetFashionModelId()
                    local parent = self._Control:CheckCurrentMaleGender() and self._MaleModelRoot
                                       or self._FemaleModelRoot

                    self:_ChangePart(modelId, entity:GetPartModelId(), entity:GetTypeId(), parent, entity:GetPartId())
                end
            end
        end
    end
end

---@param entitys XBWCommanderDIYPartEntity[]
function XUiBigWorldDIY:_TryLoadModel(gender, entitys)
    local modelId = nil

    entitys = entitys or self._Control:GetUsePartEntitys()

    if not XTool.IsTableEmpty(entitys) then
        for _, entity in pairs(entitys) do
            if not entity:IsNil() and entity:IsFashion() then
                modelId = entity:GetFashionModelIdByGender(gender)
                self:_LoadModel(modelId, gender)
                break
            end
        end
        if not string.IsNilOrEmpty(modelId) then
            self:_LoadAllPartModel(modelId, entitys, gender)
        end

        self._ModelContorller:PlayAnimation(modelId, "UIAppear01", 0)
    end
end

function XUiBigWorldDIY:_SetPartMaterials(modelId, partId, partModelId, partType, gender)
    local colorId = self._Control:GetPartUseColorByGender(partId, gender)
    local materials = self._Control:GetMaterialConfigs(partModelId, colorId)

    if not XTool.IsTableEmpty(materials) then
        for _, material in pairs(materials) do
            self._ModelContorller:SetModelComponentMaterials(modelId, partType, material.PartNodeName,
                material.MaterialPathList)
        end
    end
end

function XUiBigWorldDIY:_SetModelActive(gender, isActive)
    local entity = self._Control:GetUseFashionPartEntity()

    if entity then
        local modelId = entity:GetFashionModelIdByGender(gender)

        self._ModelContorller:SetModelActive(modelId, isActive)
    end
end

function XUiBigWorldDIY:_SetPartActive(gender, partType, isActive)
    local entity = self._Control:GetUseFashionPartEntity()

    if entity then
        local modelId = entity:GetFashionModelIdByGender(gender)

        self._ModelContorller:SetModelComponentActive(modelId, partType, isActive)
    end
end

function XUiBigWorldDIY:_SetDragTarget()
    local target = self._Control:CheckCurrentMaleGender() and self._MaleModelRoot or self._FemaleModelRoot

    if not XTool.UObjIsNil(target) then
        self.PanelDrag.Target = target.transform
    end
end


function XUiBigWorldDIY:_GetCurrentModelId()
    local entity = self._Control:GetUseFashionPartEntity()

    if entity then
        return entity:GetFashionModelId()
    end

    return ""
end

function XUiBigWorldDIY:_ResetDragRotation()
    self._MaleModelRoot.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, 180, 0)
    self._FemaleModelRoot.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, 180, 0)
end

function XUiBigWorldDIY:_PlayCurrentEffect()
    local isCurrentMale = self._Control:CheckCurrentMaleGender()

    if self.MaleChangeEffect then
        self.MaleChangeEffect.gameObject:SetActiveEx(not isCurrentMale)
        self.MaleChangeEffect.gameObject:SetActiveEx(isCurrentMale)
    end
    if self.FemaleChangeEffect then
        self.FemaleChangeEffect.gameObject:SetActiveEx(isCurrentMale)
        self.FemaleChangeEffect.gameObject:SetActiveEx(not isCurrentMale)
    end
end

function XUiBigWorldDIY:_PlayResettingAction()
    local modelId = self:_GetCurrentModelId()

    if self._CurrentEntryAnimation then
        self._ModelContorller:PlayAnimation(modelId, self._CurrentEntryAnimation .. "_Start", 1)
    else
        self._ModelContorller:PlayAnimation(modelId, "UIStand01")
    end
end

function XUiBigWorldDIY:_PlayChangeSexAction()
    local modelId = self:_GetCurrentModelId()

    if self._CurrentEntryAnimation then
        self._ModelContorller:PlayAnimation(modelId, self._CurrentEntryAnimation .. "_Start", 1)
    else
        self._ModelContorller:PlayAnimation(modelId, "UIStand01")
    end
end

function XUiBigWorldDIY:_PlayDragRotationTween()
    local target = self._Control:CheckCurrentMaleGender() and self._MaleModelRoot or self._FemaleModelRoot

    if self._TweenTimer then
        self:StopTweener(self._TweenTimer)
        self._TweenTimer = false
    end
    if not XTool.UObjIsNil(target) then
        local eulerAnglesY = target.transform.eulerAngles.y
        local offset = eulerAnglesY - 180

        self._TweenTimer = self:Tween(0.3, function(time)
            target.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, eulerAnglesY - offset * time, 0)
        end, function()
            self._TweenTimer = false
            target.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, 180, 0)
        end, function(time)
            return XUiHelper.Evaluate(XUiHelper.EaseType.Increase, time)
        end)
    end
end

-- endregion

return XUiBigWorldDIY
