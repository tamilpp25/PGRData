
local TargetCameraDistance = 13

local XUiGridResetFurniture = XClass(nil, "XUiGridResetFurniture")

function XUiGridResetFurniture:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.GridAttributePool = {}
    self.BtnOpen.gameObject:SetActiveEx(false)
    self.TxtCount.gameObject:SetActiveEx(false)
    self.GridAttribute.gameObject:SetActiveEx(false)
    self.DynamicGrid = self.Transform:GetComponent("DynamicGrid")
    self.BtnItem.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiGridResetFurniture:OnBtnClick()

    self.ParentUi:OnGridClick(self, self.DynamicGrid.Index)
    local grid = XHomeDormManager.GetFurnitureObj(self.RoomId, self.FurnitureData.Id)
    if grid then
        XEventManager.DispatchEvent(XEventId.EVENT_DORM_RESET_HUD_SHOW, self.FurnitureData.Id, 0, grid.Transform, self.RoomId)
    end
    self.FurnitureObj = grid
    self:SetSelect(true)
end

function XUiGridResetFurniture:GetSelectId()
    return self.FurnitureData and self.FurnitureData.Id or -1
end

function XUiGridResetFurniture:SetSelect(value)
    if self.IsSelect == value then
        return
    end
    self.Select.gameObject:SetActiveEx(value)
    if self.FurnitureObj then
        self.FurnitureObj:RayCastSelected(value)
    end
    self.IsSelect = value
end

function XUiGridResetFurniture:Init(parentUi, rootUi)
    self.ParentUi = parentUi
    self.RootUi = rootUi
end

---
---@param furniture XHomeFurnitureData
---@return
--------------------------
function XUiGridResetFurniture:Refresh(furniture, curRoomId, selectId, roomType)
    if not furniture then
        self:SetSelect(false)
        return
    end
    self.FurnitureData = furniture
    self.RoomId = curRoomId
    local ownRoom = roomType == XDormConfig.DormDataType.Self
    self.PanelFurnitureScore.gameObject:SetActiveEx(ownRoom)
    local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture.ConfigId)
    self.TxtName.text = template.Name
    if ownRoom then
        self.ImgIcon:SetRawImage(XDataCenter.FurnitureManager.GetFurnitureIconById(furniture.Id, XDormConfig.DormDataType.Self))
        self:UpdateAttributeItems()
    else
        self.ImgIcon:SetRawImage(template.Icon)
    end
    self:SetSelect(selectId == self:GetSelectId())
end

function XUiGridResetFurniture:UpdateAttributeItems()
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


---@class XUiDormReset : XLuaUi
---@field BtnDrdSort UnityEngine.UI.Dropdown
local XUiDormReset = XLuaUiManager.Register(XLuaUi, "UiDormReset")

local XUiGridFurnitureScore = require("XUi/XUiDorm/XUiFurnitureReform/XUiGridFurnitureScore")
local XUiPanelSViewReform = require("XUi/XUiDorm/XUiFurnitureReform/XUiPanelSViewReform")

function XUiDormReset:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiDormReset:OnStart(roomId, roomType)
    self.RoomId = roomId
    self.RoomType = roomType
    self.IsOwnRoom = roomType == XDormConfig.DormDataType.Self

    XHomeCharManager.HideAllCharacter()
    XHomeCharManager.ReleaseAllCharLongPressTrigger()

    XHomeDormManager.SetClickFurnitureCallback(function(furnitureObj)
        self:OnClickFurniture(furnitureObj)
    end)

    --分数显示
    self.PanelTool.gameObject:SetActiveEx(self.IsOwnRoom)
    self:InitCamera()

    self:RefreshRoomScore()

    self:SetupDynamicTable()

    XEventManager.AddEventListener(XEventId.EVENT_FURNITURE_ON_MODIFY, self.OnModify, self)
end

function XUiDormReset:OnEnable()
end

function XUiDormReset:OnDisable()
    self.SViewFurniturePanel:ClearCache()
    XEventManager.DispatchEvent(XEventId.EVENT_DORM_RESET_HUD_HIDE)
end

function XUiDormReset:OnDestroy()
    self:RestoreCamera()

    --显示角色
    XHomeCharManager.ShowAllCharacter(true)
    --清除选中
    XHomeDormManager.CancelSelectRayCast(self.RoomId)

    XHomeDormManager.SetClickFurnitureCallback(nil)

    XEventManager.RemoveEventListener(XEventId.EVENT_FURNITURE_ON_MODIFY, self.OnModify, self)

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_FURNITURE_HIDE_ALL_ATTR_TAG_DETAIL)

    CS.XCameraController.IsCheckOnPointOver = false
end

function XUiDormReset:OnGetEvents()
    return {
        XEventId.EVENT_FURNITURE_ONDRAG_ITEM_CHANGED,
        XEventId.EVENT_FURNITURE_CLEAN_ROOM,
        XEventId.EVENT_FURNITURE_REFRESH,
    }
end

function XUiDormReset:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FURNITURE_ONDRAG_ITEM_CHANGED
            or evt == XEventId.EVENT_FURNITURE_CLEAN_ROOM
            or evt == XEventId.EVENT_FURNITURE_REFRESH then
        self:RefreshRoomScore()
    end
end

function XUiDormReset:InitUi()
    --下拉选项
    local scoreTag = XFurnitureConfigs.GetFurnitureTagTypeTemplates() or {}
    self.ScoreIndex2TagId = {}
    local index = 0
    self.BtnDrdSort:ClearOptions()
    for id, template in pairs(scoreTag) do
        local dOp = CS.UnityEngine.UI.Dropdown.OptionData()
        dOp.text = template.TagName
        self.BtnDrdSort.options:Add(dOp)
        self.ScoreIndex2TagId[index] = id
        index = index + 1
    end
    self.BtnDrdSort.value = 0 --默认选中[隐藏数值]选项
    --分数面板
    self.ScorePanels = {}
    --动态列表
    self.GridFurnitureItem.gameObject:SetActiveEx(false)
    self.SViewFurniturePanel = XUiPanelSViewReform.New(self.PanelSViewFurniture, self, XUiGridResetFurniture)
    self.SViewFurniturePanel:RegisterClickGrid(handler(self, self.OnSelectGrid))
    --
    self.SortFurnitureCb = handler(self, self.SortFurniture)
    self.GetItemIdCb = handler(self, self.GetItemId)

    CS.XCameraController.IsCheckOnPointOver = true
end

---@param furnitureObj XHomeFurnitureObj
function XUiDormReset:OnClickFurniture(furnitureObj)
    local grid = self.SViewFurniturePanel:GetGrid(furnitureObj.Data.Id, self.GetItemIdCb)
    if grid then
        grid:OnBtnClick()
    end
end

function XUiDormReset:InitCb()
    self.BtnBack.CallBack = function() self:Close() end

    --下拉框
    self.BtnDrdSort.onValueChanged:AddListener(function(index)
        self:OnBtnDrdSortChanged(index)
    end)
end

function XUiDormReset:InitCamera()
    self.CameraCtrl = XHomeSceneManager.GetSceneCameraController()
    if XTool.UObjIsNil(self.CameraCtrl) then
        return
    end
    self.LastDistance = self.CameraCtrl.Distance
    self.LastTarget = self.CameraCtrl.TargetObj
    self.TargetAngleX = self.CameraCtrl.TargetAngleX
    self.TargetAngleY = self.CameraCtrl.TargetAngleY

    XCameraHelper.SetCameraTarget(self.CameraCtrl, self.LastTarget, TargetCameraDistance)
end

function XUiDormReset:RestoreCamera()
    if XTool.UObjIsNil(self.CameraCtrl) then
        return
    end

    self.CameraCtrl:SetTartAngle(CS.UnityEngine.Vector2(self.TargetAngleX, self.TargetAngleY))
    XCameraHelper.SetCameraTarget(self.CameraCtrl, self.LastTarget, self.LastDistance)
    self.CameraCtrl = nil
end

function XUiDormReset:OnBtnDrdSortChanged(index)
    if self.ScoreTagIndex == index then
        return
    end
    self.ScoreTagIndex = index
    local scoreTag = XFurnitureConfigs.GetFurnitureTagTypeTemplates() or {}
    local template = scoreTag[self.ScoreIndex2TagId[index]]
    if template then
        XHomeDormManager.FurnitureShowAttrType = template.AttrIndex
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_FURNITURE_ATTR_TAG, template.AttrIndex)
    end
end

---@param furniture XHomeFurnitureData
function XUiDormReset:OnSelectGrid(furniture)
end

function XUiDormReset:SwitchViewAngle(minorType, target)
    local viewAngle = XFurnitureConfigs.GetFurnitureViewAngleByMinor(minorType)
    if not viewAngle then
        return
    end

    if self.LastMinorType then
        local lastViewAngle = XFurnitureConfigs.GetFurnitureViewAngleByMinor(self.LastMinorType)
        if lastViewAngle and lastViewAngle.GroupId == viewAngle.GroupId then
            return
        end
    end

    XHomeSceneManager.ChangeAngleYAndYAxis(viewAngle.TargetAngleY, viewAngle.AllowYAxis == 1)
    self.LastMinorType = minorType
end

function XUiDormReset:RefreshRoomScore()
    if not XTool.IsNumberValid(self.RoomId) then
        return
    end
    local newAttrs = XHomeDormManager.GetFurnitureScoresByRoomId(self.RoomId)
    local oldAttrs = XHomeDormManager.GetFurnitureScoresByUnSaveRoom(self.RoomId)
    self.ScoreTotalPanel = self.ScoreTotalPanel or XUiGridFurnitureScore.New(self.PanelTotal)
    self.ScoreTotalPanel:RefreshTotal(newAttrs, oldAttrs)
    for i = 1, #newAttrs.AttrList do
        local panel = self.ScorePanels[i]
        if not panel then
            panel = XUiGridFurnitureScore.New(self["PanelTool"..i])
            self.ScorePanels[i] = panel
        end
        local typeData = XFurnitureConfigs.GetDormFurnitureType(i)
        panel:Refresh(newAttrs.AttrList[i], oldAttrs.AttrList[i], typeData.TypeIcon, i)
    end
end

function XUiDormReset:SetupDynamicTable()
    local homeData = XDataCenter.DormManager.GetRoomDataByRoomId(self.RoomId, self.RoomType)
    if not homeData then
        self.SViewFurniturePanel:Show({}, nil, self.RoomId, self.RoomType)
        return
    end
    local furnitureDict = homeData:GetFurnitureDic()
    local list = {}
    for _, furniture in pairs(furnitureDict) do
        local data = XDataCenter.FurnitureManager.GetFurnitureById(furniture.Id)
        table.insert(list, data)
    end
    table.sort(list, self.SortFurnitureCb)

    self.SViewFurniturePanel:Show(list, nil, self.RoomId, self.RoomType)
end

function XUiDormReset:SortFurniture(furnitureA, furnitureB)
    local templateA = XFurnitureConfigs.GetFurnitureTemplateById(furnitureA.ConfigId)
    local templateB = XFurnitureConfigs.GetFurnitureTemplateById(furnitureB.ConfigId)

    local typeIdA = templateA.TypeId
    local typeIdB = templateB.TypeId

    if typeIdA ~= typeIdB then
        return typeIdA < typeIdB
    end

    if furnitureA.ConfigId ~= furnitureB.ConfigId then
        return furnitureA.ConfigId < furnitureB.ConfigId
    end

    local scoreA = furnitureA:GetScore()
    local scoreB = furnitureB:GetScore()

    if scoreA ~= scoreB then
        return scoreA > scoreB
    end

    local scoreRA, scoreYA, scoreBA = furnitureA:GetRedScore(), furnitureA:GetYellowScore(), furnitureA:GetBlueScore()
    local scoreRB, scoreYB, scoreBB = furnitureB:GetRedScore(), furnitureB:GetYellowScore(), furnitureB:GetBlueScore()

    if scoreRA ~= scoreRB then
        return scoreRA > scoreRB
    end

    if scoreYA ~= scoreYB then
        return scoreYA > scoreYB
    end

    if scoreBA ~= scoreBB then
        return scoreBA > scoreBB
    end

    return furnitureA.Id < furnitureB.Id
end

---@param data XHomeFurnitureData
function XUiDormReset:GetItemId(data)
    if not data then
        return
    end
    return data.Id
end

function XUiDormReset:OnModify()
    self:RefreshRoomScore()
    self:SetupDynamicTable()
end