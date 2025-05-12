local XUiGridSGFurnitureOp = require("XUi/XUiSkyGarden/XDorm/Grid/XUiGridSGFurnitureOp")

---@class XUiGridSGFurniturePhotoOp : XUiGridSGFurnitureOp
---@field Parent XUiPanelSGPhotoWallOp
local XUiGridSGFurniturePhotoOp = XClass(XUiGridSGFurnitureOp, "XUiGridSGFurniturePhotoOp")

function XUiGridSGFurniturePhotoOp:InitUi()
    self.GridName.gameObject:SetActiveEx(false)
    self.BtnPackUp.gameObject:SetActiveEx(true)
    self.BtnRotate.gameObject:SetActiveEx(true)
    self.BtnCancel.gameObject:SetActiveEx(true)
    self._IsSafe = true
end

function XUiGridSGFurniturePhotoOp:OnDestroy()
    self._IsSafe = true
end

function XUiGridSGFurniturePhotoOp:InitCb()
    self.BtnPackUp.CallBack = function()
        self:OnBtnPackUpClick()
    end
    self.BtnCancel.CallBack = function()
        self:OnBtnCancelClick()
    end
    self.BtnRotate:AddPointerDownListener(function(eventData)
        self:OnRotateDown(eventData)
    end)
end

function XUiGridSGFurniturePhotoOp:Refresh(index, id, visible)
    self._Id = id
    self._Index = index
    self:UpdateSafe(self._IsSafe)
    self:SetVisible(visible)
end

function XUiGridSGFurniturePhotoOp:OnBtnPackUpClick()
    if not self:IsVisible() then
        return
    end
    self.Parent:RemoveFurniture(self._Index, self._Id)
    self.Parent:ExitEditMode()
end

function XUiGridSGFurniturePhotoOp:OnBtnCancelClick()
    if not self:IsVisible() then
        return
    end
    self.Parent:RevertSingle(self._Index, self._Id)
    self.Parent:ExitEditMode()
end

function XUiGridSGFurniturePhotoOp:OnRotateDown(eventData)
    if not self:IsVisible() then
        return
    end
    self.Parent:OnRotateDown(self._Index, self._Id, eventData)
    self:SetRotateState(true)
end

function XUiGridSGFurniturePhotoOp:OnRotateUp(eventData)
    self.Parent:OnRotateUp(self._Index, self._Id, eventData)
    self:SetRotateState(false)
end

function XUiGridSGFurniturePhotoOp:SetRotateState(value)
    local state = value and "Press" or "Normal"
    self.BtnRotateState:ChangeState(state)
end

function XUiGridSGFurniturePhotoOp:UpdateSafe(safe)
    self._IsSafe = safe
    self.Select.gameObject:SetActiveEx(safe)
    self.Disable.gameObject:SetActiveEx(not safe)
end

function XUiGridSGFurniturePhotoOp:IsSafe()
    if not self._Slot or not self._Slot.gameObject.activeInHierarchy then
        self._IsSafe = true
        return true
    end
    return self._IsSafe 
end

local XUiPanelSGWallOp = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGWallOp")
---@class XUiPanelSGPhotoWallOp : XUiPanelSGWallOp
---@field _Control XSkyGardenDormControl
---@field Parent XUiPanelSGPhotoWall
---@field _Container XDormitory.XDynamicContainer
---@field _OpDict table<number, XUiGridSGFurniturePhotoOp>
local XUiPanelSGPhotoWallOp = XClass(XUiPanelSGWallOp, "XUiPanelSGPhotoWallOp")

local SgFurnitureType = XMVCA.XSkyGardenDorm.XSgFurnitureType
---@type X3CCommand
local X3C_CMD = CS.X3CCommand

---@type XDormitory.XFurnitureSlotState
local CsFurnitureSlotState = CS.XDormitory.XFurnitureSlotState
local RotatingState = CsFurnitureSlotState.Rotating:GetHashCode()
local UnSafeAreaState = CsFurnitureSlotState.UnSafeArea:GetHashCode()
local SelectState = CsFurnitureSlotState.Select:GetHashCode()

function XUiPanelSGPhotoWallOp:OnStart(areaType)
    self._AreaType = areaType
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGPhotoWallOp:Refresh()
end

function XUiPanelSGPhotoWallOp:InitUi()
    XUiPanelSGWallOp.InitUi(self)
    self.BtnCancelAll.gameObject:SetActiveEx(false)
end

function XUiPanelSGPhotoWallOp:InitCb()
    XUiPanelSGWallOp.InitCb(self)
    self._RemoveFunc = {
        [SgFurnitureType.Photo] = function(id, cfgId) self:OnRemovePhoto(id, cfgId) end,
        [SgFurnitureType.Decoration] = function(id, cfgId) self:OnRemoveDecoration(id, cfgId) end,
        [SgFurnitureType.DecorationBoard] = function(id, cfgId) self:OnRemoveDecorationBoard(id, cfgId) end,
    }
    
    self.BtnCancelAll.CallBack = function() 
        self:BtnCancelAllClick()
    end
end

function XUiPanelSGPhotoWallOp:CreateContainer()
    self._Container = self._Control:CreateDynamicContainer(self.PanelMaterial, self.GridItem)
    self._Container:SetOpFurniture(handler(self, self.OnOpFurniture))
end

function XUiPanelSGPhotoWallOp:CreateFurniture(index, id, visible, ignoreUpdate)
    local fightData = self._Control:GetFightFurnitureData(id)
    if not fightData then
        XLog.Error("【照片墙】不存在家具：" .. id)
        return
    end
    if id and id > 0 then
        local data = self:GetPutWallContainerData()
        local f = data:GetFurniture(id)
        if not f then
            data:AddFurniture(id, self._Control:GetFurnitureConfigIdById(id), 0, self._Control:AddLayer())
        end
    end
    local min, max = fightData:GetSize()
    local slot = self._Container:CreateFurniture(id, min, max, fightData:GetComponent())
    self:RefreshGridOp(slot, slot.Index, id, visible, ignoreUpdate)
end

function XUiPanelSGPhotoWallOp:RemoveFurniture(index, id)
    if not id or id <= 0 then
        return
    end
    local cfgId = self._Control:GetFurnitureConfigIdById(id)
    local majorType = self._Control:GetFurnitureMajorType(cfgId)
    local func = self._RemoveFunc[majorType]
    if not func then
        XLog.Error(string.format("【照片墙】不支持类型：%s的家具移除!", majorType))
    else
        func(id, cfgId)
    end
    self._Container:DespawnSlotByIndex(index)
    self:GetPutWallContainerData():RemoveFurniture(id)
    
    self:RefreshAllGridOp()
    self:FullUpdateView()
end

function XUiPanelSGPhotoWallOp:RevertSingle(index, id)
    if not id or id <= 0 then
        return
    end
    ---@type XSgContainerFurnitureData 服务器记录的区域摆放的家具
    local layoutContainerData = self._Control:GetContainerFurnitureData(self._AreaType)
    local f = layoutContainerData:GetFurniture(id)
    local x, y = 0, 0
    local angle = 0
    local isDefault = true
    if f ~= nil then
        local ratio = XMVCA.XSkyGardenDorm.Ratio
        x, y = f:GetPos()
        x = x / ratio
        y = y / ratio
        angle = f:GetAngle()
        isDefault = false
    end
    local cfgId = self._Control:GetFurnitureConfigIdById(id)
    local majorType = self._Control:GetFurnitureMajorType(cfgId)
    
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DORMITORY_SET_PHOTO_OR_ADORN_TRANSFORM, {
        Id = id,
        IsPhoto = majorType == XMVCA.XSkyGardenDorm.XSgFurnitureType.Photo,
        IsDefault = isDefault,
        X = x,
        Y = y,
        Angle = angle
    })
    ---@type XDormitory.XFurnitureSlot
    local slot = self._Container:GetSlot(index)
    local isSafe = true
    if slot then
        slot:Update2DTransform()
        isSafe = not slot:HasState(CsFurnitureSlotState.UnSafeArea)
    end
    local gridOp = self:GetOrCreateGridOp(slot)
    if gridOp then
        gridOp:SetVisible(not isSafe)
    end
    self._Container:ClearLastSelect()
end

--- 清空摆放家具
function XUiPanelSGPhotoWallOp:ClearDecoration()
    for _, grid in pairs(self._OpDict) do
        grid:SetVisible(false)
    end
    self._Control:ClearDecoration(self._AreaType)
    self._Container:DisposeAllSlot()
    
    self:ExitEditMode()
end

--- 重置装饰
function XUiPanelSGPhotoWallOp:RevertDecoration()
    for _, grid in pairs(self._OpDict) do
        grid:SetVisible(false)
    end
    self._Container:DisposeAllSlot()
    local currentData = self._Control:CloneContainerFurnitureData(self._AreaType)
    local serverData = self._Control:GetContainerFurnitureData(self._AreaType)
    self._Control:RevertDecoration(self._AreaType, currentData, serverData)
    self:SwitchContainer()
    self.Parent:InitFurniture()
    
    self:ExitEditMode()
end

function XUiPanelSGPhotoWallOp:SwitchContainer()
    for _, grid in pairs(self._OpDict) do
        grid:SetVisible(false)
    end
    local wall = self._Control:GetWallFightData()
    self._Container:ChangeContainer(wall:GetTransform())
end

function XUiPanelSGPhotoWallOp:OnRotateDown(index, id, eventData)
    ---@type XDormitory.XFurnitureSlot
    local slot = self._Container:GetSlot(index)
    if not slot then
        return
    end
    slot:EnterRotate(eventData)
end

function XUiPanelSGPhotoWallOp:OnRotateUp(index, id, eventData)
    ---@type XDormitory.XFurnitureSlot
    local slot = self._Container:GetSlot(index)
    if not slot then
        return
    end
    slot:ExitRotate(eventData)
end

function XUiPanelSGPhotoWallOp:OnRemovePhoto(id, cfgId)
    XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_DESTROY_PHOTO, {
        Id = id
    })
    self._Control:RemoveFightFurnitureData(id)
end

function XUiPanelSGPhotoWallOp:OnRemoveDecoration(id, cfgId)
    XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_DESTROY_PHOTO_ADORN, {
        Id = id
    })
    self._Control:RemoveFightFurnitureData(id)
end

function XUiPanelSGPhotoWallOp:OnRemoveDecorationBoard(id, cfgId)
end

function XUiPanelSGPhotoWallOp:OnFurnitureSlotStateChange(index, id, state, addParam)
    if state == RotatingState then
        self:OnFurnitureRotateStateChange(index, addParam > 0)
    elseif state == UnSafeAreaState then
        self:OnFurnitureSafeStateChange(index, id, addParam < 1)
    elseif state == SelectState then
        self:OnFurnitureSelectStateChange(index, id, addParam > 0)
    end
end

function XUiPanelSGPhotoWallOp:OnFurnitureRotateStateChange(index, isRotate)
    local grid = self:TryGetGridPhotoOpByIndex(index)
    if not grid then
        XLog.Error("【照片墙】家具旋转状态改变失败！ Index = ", index)
        return
    end
    grid:SetRotateState(isRotate)
end

function XUiPanelSGPhotoWallOp:OnFurnitureSafeStateChange(index, id, isSafe)
    local grid = self:TryGetGridPhotoOpByIndex(index)
    if grid then
        if not isSafe then
            grid:Refresh(index, id, true)
        end
        grid:UpdateSafe(isSafe)
    end
    if not self._IsEditMode then
        self:EnterEditMode()
    end
    self:SetSafe(isSafe)
end

function XUiPanelSGPhotoWallOp:OnFurnitureSelectStateChange(index, id, isSelect)
    local grid = self:TryGetGridPhotoOpByIndex(index)
    if grid then
        grid:SetVisible(isSelect)
    end
    if isSelect then
        self:EnterEditMode()
    else
        self:ExitEditMode()
    end
end

function XUiPanelSGPhotoWallOp:OnFurnitureSlotClick(index, id, selectParam, _)
    local isSelect = selectParam > 0
    if isSelect then
        self:SetTopLayer(index, id)
    end
end

function XUiPanelSGPhotoWallOp:SetSafe(isSafe)
    local isAllSafe = true
    if not isSafe then
        isAllSafe = false
        for _, g in pairs(self._OpDict) do
            g:SetRaycast(not g:IsSafe())
        end
    else
        for _, g in pairs(self._OpDict) do
            if not g:IsSafe() then
                return self:SetSafe(false)
            end
            g:SetRaycast(true)
        end
    end
    self.PanelWarning.gameObject:SetActiveEx(not isAllSafe)
end

--- 获取或者创建家具操作框
---@param slot XDormitory.XFurnitureSlot
---@return XUiGridSGFurniturePhotoOp
function XUiPanelSGPhotoWallOp:GetOrCreateGridOp(slot)
    if not slot then
        XLog.Error("【照片墙】创建家具操作框失败: 家具节点无效！")
        return
    end
    local insId = slot:GetInstanceID()
    local grid = self._OpDict[insId]
    if not grid then
        grid = XUiGridSGFurniturePhotoOp.New(slot, self, slot)
        self._OpDict[insId] = grid
    end
    return grid
end

--- 获取家具操作框
---@param index number
---@return XUiGridSGFurniturePhotoOp
function XUiPanelSGPhotoWallOp:TryGetGridPhotoOpByIndex(index)
    local slot = self._Container:GetSlot(index)
    if not slot then
        return
    end
    return self:GetOrCreateGridOp(slot)
end

---@param slot XDormitory.XFurnitureSlot
function XUiPanelSGPhotoWallOp:RefreshGridOp(slot, index, id, visible, ignoreUpdate)
    local grid = self:GetOrCreateGridOp(slot)
    if grid then
        grid:Refresh(index, id, visible)
    end

    if visible then
        slot:OnPointerClick(nil)
    end

    if not ignoreUpdate then
        self:FullUpdateView()
    end
end

function XUiPanelSGPhotoWallOp:EnterEditMode()
    local visible = false
    for _, girdOp in pairs(self._OpDict) do
        if girdOp:IsVisible() then
            visible = true
            break
        end
    end
    if not visible then
        return
    end
    
    XUiPanelSGWallOp.EnterEditMode(self)
    self.Parent:EnterEditMode()

    self.BtnCancelAll.gameObject:SetActiveEx(true)
end

function XUiPanelSGPhotoWallOp:ExitEditMode()
    for _, girdOp in pairs(self._OpDict) do
        if girdOp:IsVisible() then
            return
        end
        if not girdOp:IsSafe() then
            local slot = girdOp:GetSlot()
            slot:OnPointerClick(nil)
            return
        end
    end
    XUiPanelSGWallOp.ExitEditMode(self)
    self:SetSafe(true)
    self.Parent:ExitEditMode()
    
    self.BtnCancelAll.gameObject:SetActiveEx(false)
end

function XUiPanelSGPhotoWallOp:SetTopLayer(index, id)
    if not id or id <= 0 then
        return
    end
    local cfgId = self._Control:GetFurnitureConfigIdById(id)
    local majorType = self._Control:GetFurnitureMajorType(cfgId)
    local cmd
    if majorType == SgFurnitureType.Photo then
        cmd = X3C_CMD.CMD_DORMITORY_TAKE_PHOTO_TOP
    elseif majorType == SgFurnitureType.Decoration then
        cmd = X3C_CMD.CMD_DORMITORY_TAKE_PHOTO_ADORN_TOP
    end
    if cmd then
        XMVCA.X3CProxy:Send(cmd, {
            Id = id
        })
        local f = self:GetPutWallContainerData():GetFurniture(id)
        f:SetLayer(self._Control:AddLayer())
    end
    local slot = self._Container:GetSlot(index)
    if slot then
        slot.transform:SetSiblingIndex(slot.transform.parent.childCount - 1)
    end
end

function XUiPanelSGPhotoWallOp:IsSafe()
    for _, girdOp in pairs(self._OpDict) do
        if not girdOp:IsSafe() then
            return false
        end
    end
    return true
end

function XUiPanelSGPhotoWallOp:BtnCancelAllClick()
    if not self:TryCheckOpIsSafe(true) then
        return
    end
    local count = self._Container:GetSlotCount()
    for i = 0, count - 1 do
        ---@type XDormitory.XFurnitureSlot
        local slot = self._Container:GetSlot(i)
        slot:RemoveState(CsFurnitureSlotState.Select)
    end
    self._Container:ClearLastSelect()
end

return XUiPanelSGPhotoWallOp