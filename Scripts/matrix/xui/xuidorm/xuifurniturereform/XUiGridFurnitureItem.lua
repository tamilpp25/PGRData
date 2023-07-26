
local InitFurniturePosX, InitFurniturePosY = 15, 15

---@class XUiGridFurnitureItem
---@field ParentUi XUiPanelSViewReform
---@field RootUi XUiFurnitureReform
---@field BtnItem XUiWidget
---@field IsDragging boolean
---@field ScreenToRayV3 UnityEngine.Vector3
---@field DynamicGrid DynamicGrid
local XUiGridFurnitureItem = XClass(nil, "XUiGridFurnitureItem")

function XUiGridFurnitureItem:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self:InitCb()
    self.ScreenToRayV3 = CS.UnityEngine.Vector3.zero
    self.GridAttribute.gameObject:SetActiveEx(false)
    self.GridAttributePool = {}
end

function XUiGridFurnitureItem:InitCb()
    
    self.BtnItem:AddPointerDownListener(function(eventData) 
        self:OnBtnItemPointerDown(eventData)
    end)

    self.BtnItem:AddDragListener(function(eventData)
        self:OnBtnItemDrag(eventData)
    end)

    self.BtnItem:AddPointerClickListener(function(eventData) 
        self:OnBtnItemClick(eventData)
    end)

    self.BtnItem:AddBeginDragListener(function(eventData) 
        self:OnBtnItemBeginDrag(eventData)
    end)

    self.BtnItem:AddEndDragListener(function(eventData) 
        self:OnBtnItemEndDrag(eventData)
    end)
    
    self.BtnOpen.CallBack = function() 
        self:OnBtnOpenClick()
    end
end

function XUiGridFurnitureItem:Init(parentUi, rootUi)
    self.ParentUi = parentUi
    self.RootUi = rootUi
end

--- 
---@param furnitureDataList XHomeFurnitureData[]|XHomeFurnitureData
---@return
--------------------------
function XUiGridFurnitureItem:Refresh(furnitureDataList, curRoomId, selectId, roomType, index)
    self.Index = index
    local furnitureData
    local count = #furnitureDataList
    local isMulti = count > 0
    if isMulti then
        furnitureData = furnitureDataList[1]
    else
        furnitureData = furnitureDataList
    end
    if not furnitureData then
        self:SetSelect(false)
        return
    end
    self.FurnitureDataList = furnitureDataList
    self.FurnitureData = furnitureData
    self.RoomId = curRoomId
    local ownRoom = roomType == XDormConfig.DormDataType.Self
    self.PanelFurnitureScore.gameObject:SetActiveEx(ownRoom)
    if ownRoom then
        self:RefreshOwnRoom(isMulti, count)
    else
        self:RefreshOtherRoom()
    end
    self:SetSelect(false)
end

function XUiGridFurnitureItem:RefreshOwnRoom(isMulti, count)
    local furnitureData = self.FurnitureData
    local template = XFurnitureConfigs.GetFurnitureTemplateById(furnitureData.ConfigId)
    self.TxtName.text = template.Name
    
    self.ImgIcon:SetRawImage(XDataCenter.FurnitureManager.GetFurnitureIconById(furnitureData.Id, XDormConfig.DormDataType.Self))
    self:UpdateAttributeItems()
    self.TxtCount.gameObject:SetActiveEx(isMulti)
    self.BtnOpen.gameObject:SetActiveEx(isMulti and count > 1)
    if isMulti then
        self.TxtCount.text = count
    end
    self:RefreshRedPoint()
end

function XUiGridFurnitureItem:RefreshOtherRoom()
    local configId = self.FurnitureData.ConfigId
    local template = XFurnitureConfigs.GetFurnitureTemplateById(configId)
    self.ImgIcon:SetRawImage(template.Icon)
    self.TxtName.text = template.Name
    self.TxtCount.gameObject:SetActiveEx(false)
    self.BtnOpen.gameObject:SetActiveEx(false)
    self.RedPoint.gameObject:SetActiveEx(false)
end

function XUiGridFurnitureItem:SetSelect(select)
    if self.IsSelect == select then
        return
    end
    self.IsSelect = select
    self.Select.gameObject:SetActiveEx(select)
end

function XUiGridFurnitureItem:UpdateAttributeItems()
    local attributes = {}
    for k, v in pairs(self.FurnitureData.AttrList) do
        attributes[k] = {
            Id = k,
            Val = v,
            FurnitureId = self.FurnitureData.Id
        }
    end

    XUiHelper.CreateTemplates(self.RootUi, self.GridAttributePool, attributes, XUiGridAttribute.New, self.GridAttribute, self.PanelFurnitureScore, XUiGridAttribute.Init)
    for i = 1, #attributes do
        self.GridAttributePool[i].GameObject:SetActiveEx(true)
    end
end

function XUiGridFurnitureItem:GetSelectId()
    return self.FurnitureData and self.FurnitureData.ConfigId or -1
end

function XUiGridFurnitureItem:RefreshRedPoint()
    local id = self:GetSelectId()
    if id <= 0 then
        self.RedPoint.gameObject:SetActiveEx(false)
        return
    end
    
    local show = XDataCenter.FurnitureManager.CheckIsMaxScore(id)
    self.RedPoint.gameObject:SetActiveEx(show)
    if show then
        XDataCenter.FurnitureManager.RemoveMaxRecord(id)
    end
end

function XUiGridFurnitureItem:OnBtnItemPointerDown(eventData)
    self.PointerPosY = eventData.position.y
    XHomeDormManager.AttachSurfaceToRoom(self.RoomId)

    if not self.FurnitureData then
        return
    end
    
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.FurnitureData.ConfigId)
    if not template then
        return
    end
    
    
    XHomeDormManager.ShowSurface(XFurnitureConfigs.LocateTypeToXHomePlatType(template.LocateType))
end

function XUiGridFurnitureItem:OnBtnItemClick(eventData)
    if self.IsDragging or self.IsSelect then
        return
    end
    if not self:CheckTouch(eventData) then
        return
    end
    local template = self.Template
    -- 墙上的，初始化墙上位置数据
    local pos = {
        x = InitFurniturePosX,
        y = InitFurniturePosY
    }
    local rotate = 0
    if template.LocateType == XFurnitureConfigs.HomeLocateType.LocateWall then
        rotate = XHomeDormManager.DormistoryGetFarestWall(self.RoomId) - 1
        local wallWidth, wallHeight = self:GetWallWidthAndHeightByRotate(rotate)
        pos.x = math.floor(wallWidth / 2 - template.Width / 2)
        pos.y = math.floor(wallHeight / 2 - template.Height / 2)
    end

    self.Furniture = XHomeDormManager.CreateFurniture(self.RoomId, self.FurnitureData, pos, rotate)
    if not self.Furniture then
        return
    end

    self.Furniture:SetInteractInfoGo()
    if template.LocateType == XFurnitureConfigs.HomeLocateType.Replace then
        -- 改造
        XHomeDormManager.ReplaceSurface(self.RoomId, self.Furniture)
    else
        -- 家具
        self.RootUi:ShowFurnitureMenu(self.Furniture, false, true)
        self.Furniture:ShowSelectGrid()
    end
    self:SetSelect(true)
    self.ParentUi:OnGridClick(self, self.Index)
    self.RedPoint.gameObject:SetActiveEx(false)
end

function XUiGridFurnitureItem:OnBtnItemDrag(eventData)
    if not self:CheckTouch(eventData) then
        return
    end

    if not self.PointerPosY then
        return
    end
    self.ParentUi:OnDrag(eventData)
    if eventData.position.y - self.PointerPosY < self.ParentUi.ControlLimit then
        return
    end

    local template = self.Template
    if template.LocateType ~= XFurnitureConfigs.HomeLocateType.Replace then
        --家具
        local camera = XHomeSceneManager.GetSceneCamera()
        if not XTool.UObjIsNil(camera) then
            self.ScreenToRayV3.x = eventData.position.x
            self.ScreenToRayV3.y = eventData.position.y
            self.ScreenToRayV3.z = 0
            local ray = camera:ScreenPointToRay(self.ScreenToRayV3)
            local mask = CS.UnityEngine.LayerMask.GetMask("HomeSurface")
            if mask then
                local ret, hit = ray:RayCast(mask)
                if ret then
                    self.PointerPosY = nil
                    local gridPos, rotate = XHomeDormManager.GetGridPosByWorldPos(hit.point, hit.transform, 
                            template.Width, template.Height)
                    self.Furniture = XHomeDormManager.CreateFurniture(self.RoomId, self.FurnitureData, gridPos, rotate)
                    if not self.Furniture then
                        return
                    end
                    self.RootUi:ShowFurnitureMenu(self.Furniture, true, true)
                end
            end
        end
    end
end

function XUiGridFurnitureItem:OnBtnItemBeginDrag(eventData)
    self.IsDragging = true
    self.ParentUi:OnBeginDrag(eventData)
end

function XUiGridFurnitureItem:OnBtnItemEndDrag(eventData)
    self.IsDragging = false
    self.ParentUi:OnEndDrag(eventData)
end

function XUiGridFurnitureItem:CheckTouch(eventData)
    if not self.FurnitureData or not eventData then
        return false
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.FurnitureData.ConfigId)
    if not template then
        return false
    end

    if XHomeDormManager.CheckFurnitureCountReachLimitByPutNumType(self.RoomId, template.PutNumType)
            and template.LocateType ~= XFurnitureConfigs.HomeLocateType.Replace then
        XUiManager.TipText("FurnitureOutOfLimit")
        return false
    end

    local homeObj = XHomeDormManager.GetRoom(self.RoomId)
    local furnitureList = homeObj:GetAllFurnitureConfig()
    if #furnitureList >= XFurnitureConfigs.MaxTotalFurnitureCount
            and template.LocateType ~= XFurnitureConfigs.HomeLocateType.Replace then
        XUiManager.TipText("DormMaxPutFurnitureCountHit")
        return false
    end
    
    self.Template = template
    
    return true
end

function XUiGridFurnitureItem:GetWallWidthAndHeightByRotate(rotate)
    local width, height

    if rotate % 2 == 0 then
        width = XHomeDormManager.GetMapWidth()
        height = XHomeDormManager.GetMapTall()
    else
        width = XHomeDormManager.GetMapHeight()
        height = XHomeDormManager.GetMapTall()
    end
    
    return width, height
end

function XUiGridFurnitureItem:OnBtnOpenClick()
    if not self.FurnitureData or not self.FurnitureDataList then
        return
    end
    self.RootUi:ExpandFurniture(self.FurnitureDataList)
end

return XUiGridFurnitureItem