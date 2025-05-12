---@class XSkyGardenDormControl : XControl
---@field private _Model XSkyGardenDormModel
---@field private _ContainerDataDict table<number, XSgContainerFurnitureData>
local XSkyGardenDormControl = XClass(XControl, "XSkyGardenDormControl")

local SgDormAreaType = XMVCA.XSkyGardenDorm.XSgDormAreaType

function XSkyGardenDormControl:OnInit()
    --初始化内部变量
    self._LocalLayoutTex = {}
    
    self._ContainerDataDict = {}
end

function XSkyGardenDormControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XSkyGardenDormControl:RemoveAgencyEvent()

end

function XSkyGardenDormControl:OnRelease()
    for key, tex in pairs(self._LocalLayoutTex) do
        if not XTool.UObjIsNil(tex) then
            XUiHelper.Destroy(tex)
        end
        self._LocalLayoutTex[key] = nil
    end
end

function XSkyGardenDormControl:GetFurnitureTypeList(areaType)
    return self._Model:GetFurnitureTypeList(areaType)
end

function XSkyGardenDormControl:GetFurnitureTypeId(furnitureId)
    return self._Model:GetFurnitureTypeId(furnitureId)
end

function XSkyGardenDormControl:GetFurnitureMajorType(furnitureId)
    return self._Model:GetFurnitureMajorType(furnitureId)
end

function XSkyGardenDormControl:IsContainerFurniture(furnitureId)
    local typeId = self._Model:GetFurnitureTypeId(furnitureId)
    local t = self._Model:GetFurnitureTypeTemplate(typeId)
    return t and t.IsContainer or false
end

function XSkyGardenDormControl:GetFurnitureMajorName(typeId)
    local t = self._Model:GetFurnitureTypeTemplate(typeId)
    return t and t.MajorName or ""
end

function XSkyGardenDormControl:GetMajorType(typeId)
    local t = self._Model:GetFurnitureTypeTemplate(typeId)
    return t and t.MajorType or ""
end

function XSkyGardenDormControl:GetFurnitureMinorName(typeId)
    local t = self._Model:GetFurnitureTypeTemplate(typeId)
    return t and t.MinorName or ""
end

function XSkyGardenDormControl:GetFurnitureListByTypeId(typeId)
    return self._Model:GetFurnitureListByTypeId(typeId)
end

function XSkyGardenDormControl:GetTypeIdByMajorType(majorType)
    return self._Model:GetTypeIdByMajorType(majorType)
end

function XSkyGardenDormControl:GetFurnitureConfigIdById(id)
    local dict = self._Model:GetDormData():GetOwnFurnitureDict()
    local data = dict[id]
    if not data then
        XLog.Error("家具未拥有！！！")
        return
    end
    return data:GetCfgId()
end

function XSkyGardenDormControl:CheckFurnitureUnlockById(id)
    return self._Model:GetDormData():CheckFurnitureUnlockById(id)
end

function XSkyGardenDormControl:CheckFurnitureUnlockByConfigId(furnitureId)
    return self._Model:GetDormData():CheckFurnitureUnlockByConfigId(furnitureId)
end

function XSkyGardenDormControl:CheckContainFurnitureById(areaType, id)
    return self._Model:CheckContainFurnitureById(areaType, id)
end

function XSkyGardenDormControl:CheckContainFurnitureByConfigId(areaType, furnitureId)
    return self._Model:CheckContainFurnitureByConfigId(areaType, furnitureId)
end

function XSkyGardenDormControl:GetNotPutFurnitureIdList(cfgId, containerFurnitureData)
    return self._Model:GetDormData():GetNotPutFurnitureIdList(cfgId, containerFurnitureData)
end

function XSkyGardenDormControl:GetFurnitureIdListByConfigId(furnitureId)
    return self._Model:GetDormData():GetFurnitureIdListByConfigId(furnitureId)
end

function XSkyGardenDormControl:GetFurnitureName(furnitureId)
    local t = self._Model:GetFurnitureTemplate(furnitureId)
    return t and t.Name or ""
end

function XSkyGardenDormControl:GetFurnitureIcon(furnitureId)
    local t = self._Model:GetFurnitureTemplate(furnitureId)
    return t and t.Icon or ""
end

function XSkyGardenDormControl:GetFurniturePriority(furnitureId)
    local t = self._Model:GetFurnitureTemplate(furnitureId)
    return t and t.Priority or 0
end

function XSkyGardenDormControl:GetFurnitureMaxCount(furnitureId)
    local t = self._Model:GetFurnitureTemplate(furnitureId)
    return t and t.MaxCount or 0
end

function XSkyGardenDormControl:GetFurnitureLockDesc(furnitureId)
    local t = self._Model:GetFurnitureTemplate(furnitureId)
    return t and t.LockDesc or ""
end

function XSkyGardenDormControl:GetFurnitureSceneObjId(furnitureId)
    return self._Model:GetFurnitureSceneObjId(furnitureId)
end


--region 照片墙

function XSkyGardenDormControl:GetContainerCapacity(areaType)
    local container = self._Model:GetLayoutContainer(areaType)
    if not container then
        return
    end
    return self._Model:GetFurniturePutInfo(container:GetCfgId())
end

---@return XSgContainerFurnitureData
function XSkyGardenDormControl:GetContainerFurnitureData(areaType)
    return self._Model:GetContainerFurnitureData(areaType)
end

---@return XSgContainerFurnitureData
function XSkyGardenDormControl:GetContainerFurnitureDataWithLayoutId(areaType, layoutId)
    return self._Model:GetDormData():GetContainerFurnitureData(areaType, layoutId)
end

---@return XSgContainerFurnitureData
function XSkyGardenDormControl:CloneContainerFurnitureData(areaType)
    if self._ContainerDataDict[areaType] then
        return self._ContainerDataDict[areaType]
    end
    self._ContainerDataDict[areaType] = self:GetContainerFurnitureData(areaType):Clone()
    
    return self._ContainerDataDict[areaType]
end

function XSkyGardenDormControl:ClearContainerDataList(areaType)
    self._ContainerDataDict[areaType] = nil
end

--- 根据MajorType获取放置的数量
---@param typeList number[]
---@param containerData XSgContainerFurnitureData
---@return 
function XSkyGardenDormControl:GetPutCountDictByMajorType(typeList, containerData)
    if XTool.IsTableEmpty(typeList) then
        return
    end
    local dict = {}
    for _, majorType in pairs(typeList) do
        dict[majorType] = dict[majorType] or 0
    end
    local fDict = containerData:GetFurnitureDict()
    for _, f in pairs(fDict) do
        local majorType = self._Model:GetFurnitureMajorType(f:GetCfgId())
        if dict[majorType] then
            dict[majorType] = dict[majorType] + 1
        end
    end
    return dict
end

---@return XDormitory.XDynamicContainer
function XSkyGardenDormControl:CreateDynamicContainer(transform, prefab)
    local manager = XMVCA.XSkyGardenDorm:GetManager()
    if not manager then
        return
    end
    local wall = self._Model:GetWallFightData()
    local sceneTransform = wall:GetTransform() or transform
    return manager:CreateDynamicContainer(transform, sceneTransform, prefab.gameObject)
end

---@return XDormitory.XStaticContainer
function XSkyGardenDormControl:CreateStaticContainer(transform, prefab)
    local manager = XMVCA.XSkyGardenDorm:GetManager()
    if not manager then
        return
    end
    local wall = self._Model:GetGiftShelfFightData()
    local sceneTransform = wall:GetTransform() or transform
    return manager:CreateStaticContainer(transform, sceneTransform, prefab.gameObject)
end

---@return XSgDormFightContainerData
function XSkyGardenDormControl:GetWallFightData()
    return self._Model:GetWallFightData()
end

---@return XSgDormFightContainerData
function XSkyGardenDormControl:GetGiftShelfFightData()
    return self._Model:GetGiftShelfFightData()
end

function XSkyGardenDormControl:AddFightFurnitureData(id, data)
    self._Model:AddFightFurnitureData(id, data)
end

function XSkyGardenDormControl:UpdateWallFightData(data)
    self._Model:GetWallFightData():UpdateData(data.Transform)
end

function XSkyGardenDormControl:UpdateGiftFightData(data)
    self._Model:GetGiftShelfFightData():UpdateData(data.Transform, data.FrameGridSizeList)
end

function XSkyGardenDormControl:RemoveFightFurnitureData(id)
    self._Model:RemoveFightFurnitureData(id)
end

---@return XSgDormFightFurnitureData
function XSkyGardenDormControl:GetFightFurnitureData(id)
    return self._Model:GetFightFurnitureData(id)
end

--- 恢复到服务器的数据
---@param areaType number 区域
---@param currentData XSgContainerFurnitureData 当前摆放的家具
---@param serverData XSgContainerFurnitureData 服务端记录的家具
function XSkyGardenDormControl:RevertDecoration(areaType, currentData, serverData)
    if areaType == SgDormAreaType.Wall then
        local photos, adorns = self._Model:GetPhotoWallFightInitData(serverData)
        local data = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DORMITORY_RESET_PHOTO_WALL, {
            PhotoWallId = self._Model:GetFurnitureSceneObjId(serverData:GetContainer():GetCfgId()),
            Photos = photos,
            PhotoAdorns = adorns,
        })
        self._Model:GetWallFightData():UpdateData(data.PhotoWallData.Transform)
        self._Model:UpdateFightFurnitureData(data.PhotosData)
        self._Model:UpdateFightFurnitureData(data.PhotoAdornsData)
    else
        local gifts = self._Model:GetGiftShelfFightInitData(serverData)
        local data = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DORMITORY_RESET_FRAME_WALL, {
            FrameWallId = self._Model:GetFurnitureSceneObjId(serverData:GetContainer():GetCfgId()),
            FrameGoods = gifts,
        })
        local giftData = data.FrameWallData
        self._Model:GetGiftShelfFightData():UpdateData(giftData.Transform, giftData.FrameGridSizeList)
        self._Model:UpdateFightFurnitureData(data.FrameGoodsData)
    end
    self._ContainerDataDict[areaType] = serverData:Clone()
end

--- 清空墙上的装饰
---@param areaType number 区域
function XSkyGardenDormControl:ClearDecoration(areaType)
    local containerFurnitureData = self:CloneContainerFurnitureData(areaType)
    if areaType == SgDormAreaType.Wall then
        local photos, adorns = self._Model:GetPhotoWallFightInitData(containerFurnitureData)
        for _, data in pairs(photos) do
            self:RemoveFightFurnitureData(data.Id)
        end
        for _, data in pairs(adorns) do
            self:RemoveFightFurnitureData(data.Id)
        end
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DORMITORY_RESET_PHOTO_WALL, {
            PhotoWallId = self._Model:GetFurnitureSceneObjId(containerFurnitureData:GetContainer():GetCfgId()),
            Photos = {},
            PhotoAdorns = {}
        })
    elseif areaType == SgDormAreaType.GiftShelf then
        local gifts = self._Model:GetGiftShelfFightInitData(containerFurnitureData)
        for _, data in pairs(gifts) do
            self:RemoveFightFurnitureData(data.Id)
        end
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DORMITORY_RESET_FRAME_WALL, {
            FrameWallId = self._Model:GetFurnitureSceneObjId(containerFurnitureData:GetContainer():GetCfgId()),
            FrameGoods = {},
        })
    end
    
    containerFurnitureData:ClearAllFurniture()
end

--endregion


--region 预设

function XSkyGardenDormControl:GetDormLayoutIdList(areaType)
    return self._Model:GetDormLayoutIdList(areaType)
end

function XSkyGardenDormControl:GetDormLayoutName(id)
    local t = self._Model:GetDormLayoutTemplate(id)
    return t and t.Name or ""
end

function XSkyGardenDormControl:GetDormLayoutDefaultIcon(id)
    local t = self._Model:GetDormLayoutTemplate(id)
    return t and t.DefaultIcon or ""
end

function XSkyGardenDormControl:GetLayoutIdByAreaType(areaType)
    return self._Model:GetLayoutIdByAreaType(areaType)
end

function XSkyGardenDormControl:GetLayoutIcon(areaType, id, func)
    local fileName = self._Model:GetDormLayoutIconFileName(areaType, id)
    local tex = self._LocalLayoutTex[fileName]
    if tex then
        func(tex)
        return
    end

    CS.XTool.LoadLocalCaptureImgWithoutSuffix(fileName, function(texture)
        if texture then
            self._LocalLayoutTex[fileName] = texture
        end
        func(texture)
    end)
end

function XSkyGardenDormControl:CaptureLayoutIcon(areaType, id)
    self:CaptureCamera(self._Model:GetDormLayoutIconFileName(areaType, id))
end

function XSkyGardenDormControl:CaptureCamera(fileName, func)
    if string.IsNilOrEmpty(fileName) then
        return
    end
    
    CS.XScreenCapture.ScreenCaptureWithCallBack(XMVCA.XBigWorldGamePlay:GetCamera(), function(tex)
        if tex then
            self._LocalLayoutTex[fileName] = tex
            CS.XTool.SaveCaptureImg(fileName, tex)
        end
        if func then func() end
    end)
end

function XSkyGardenDormControl:IsLayoutEmpty(areaType, id)
    return self._Model:GetDormData():IsLayoutEmpty(areaType, id)
end

function XSkyGardenDormControl:SetMaxLayer(layer)
    self._Model:SetMaxLayer(layer)
end

function XSkyGardenDormControl:AddLayer()
    return self._Model:AddLayer()
end

function XSkyGardenDormControl:GetLayer()
    return self._Model:GetLayer()
end

--- 保存并应用预设
---@param areaType number 
---@param saveId number 
---@param applyId number 
---@param containerDataList XSgContainerFurnitureData[] 
function XSkyGardenDormControl:RequestSaveAndApplyLayout(areaType, saveId, applyId, containerDataList, func)
    local saveInfos = {}
    local isSave = saveId and saveId > 0
    if isSave then
        self:CaptureLayoutIcon(areaType, saveId)
        if not XTool.IsTableEmpty(containerDataList) then
            for _, data in pairs(containerDataList) do
                saveInfos[#saveInfos + 1] = data:ToServerData()
            end
        end
    end
    local req = {
        AreaType = areaType,
        SaveLayoutId = saveId,
        ApplyLayoutId = applyId,
        SaveFurnitureInfos = saveInfos
    }
    self:ClearContainerDataList(areaType)
    XNetwork.Call("SgDormSaveAndApplyLayoutRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if isSave then
            local containerFurnitureData = self._Model:GetDormData():GetLayoutData(areaType, saveId):GetContainerFurnitureData()
            containerFurnitureData:UpdateData(saveInfos[1])
        end
        
        local applyNew = applyId and applyId > 0
        if applyNew then
            self._Model:SetLayoutIdWithAreaType(areaType, applyId)
        end
        if func then  func(true) end
        
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_DORM_LAYOUT_REFRESH)

        if applyNew then
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_DORM_APPLY_NEW_LAYOUT)
        end
    end)
end

--endregion


--region 涂装

function XSkyGardenDormControl:GetAllFashionIds()
    return self._Model:GetAllFashionIds()
end

function XSkyGardenDormControl:IsCurrentFashionId(fashionId)
    if not fashionId or fashionId < 0 then
        return
    end
    return self._Model:GetDormData():GetCurFashionId() == fashionId
end

function XSkyGardenDormControl:GetCurFashionId()
    return self._Model:GetDormData():GetCurFashionId()
end

function XSkyGardenDormControl:IsFashionUnlock(fashionId)
    return self._Model:IsFashionUnlock(fashionId)
end

function XSkyGardenDormControl:GetFashionName(id)
    local t = self._Model:GetFashionTemplate(id)
    return t and t.Name or ""
end

function XSkyGardenDormControl:GetFashionPriority(id)
    local t = self._Model:GetFashionTemplate(id)
    return t and t.Priority or 0
end

function XSkyGardenDormControl:GetFashionIcon(id)
    local t = self._Model:GetFashionTemplate(id)
    return t and t.Icon or 0
end

function XSkyGardenDormControl:GetFashionLockDesc(id)
    local t = self._Model:GetFashionTemplate(id)
    return t and t.LockDesc or ""
end

function XSkyGardenDormControl:GetFashionSkinId(id)
    return self._Model:GetFashionSkinId(id)
end

function XSkyGardenDormControl:RequestSetFashion(fashionId, func)
    XNetwork.Call("SgDormSetFashionRequest", { FashionId = fashionId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:GetDormData():UpdateCurFashionId(fashionId)

        if func then  func() end
    end)
end

--endregion



--region 本地配置

function XSkyGardenDormControl:GetBtnFashionSaveText(isCur)
    local index = isCur and 2 or 1
    return self._Model:GetConfigValue("BtnFashionSaveText", index)
end

function XSkyGardenDormControl:GetSwitchNewLayoutText(isEqual)
    local index = isEqual and 2 or 1
    return self._Model:GetConfigValue("SwitchNewLayoutText", index)
end

function XSkyGardenDormControl:GetFurnitureChangedText()
    return self._Model:GetConfigValue("FurnitureChangedText", 1)
end

function XSkyGardenDormControl:GetLayoutChangeText(index)
    return self._Model:GetConfigValue("LayoutChangeText", index)
end

function XSkyGardenDormControl:GetSelectSlotFirstText()
    return self._Model:GetConfigValue("SelectSlotFirstText", 1)
end

function XSkyGardenDormControl:GetSameTypeFullCountText()
    return self._Model:GetConfigValue("SameTypeFullCountText", 1)
end

function XSkyGardenDormControl:GetOperateText(index)
    return self._Model:GetConfigValue("OperateText", index)
end

function XSkyGardenDormControl:GetInvalidPutText()
    return self._Model:GetConfigValue("InvalidPutText", 1)
end

function XSkyGardenDormControl:GetGiftHasBeenPutText()
    return self._Model:GetConfigValue("GiftHasBeenPutText", 1)
end

--endregion



return XSkyGardenDormControl