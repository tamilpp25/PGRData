---@class XUiGridSGFurniture : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiPanelSGWallMenu
local XUiGridSGFurniture = XClass(XUiNode, "XUiGridSGFurniture")

function XUiGridSGFurniture:OnStart(areaType)
    self._AreaType = areaType
    self:InitUi()
    self:InitCb()
end

function XUiGridSGFurniture:OnDisable()
    self._ConfigId = -1
end

function XUiGridSGFurniture:Refresh(configId, selectId)
    if not configId or configId <= 0 then
        self:Close()
        return
    end
    self._ConfigId = configId
    local maxCount = self._Control:GetFurnitureMaxCount(configId)
    local onlyOne = maxCount == 1
    self.RImgIcon:SetRawImage(self._Control:GetFurnitureIcon(configId))
    self.TxtName.text = self._Control:GetFurnitureName(configId)
    self._IsUnlock = self._Control:CheckFurnitureUnlockByConfigId(configId)
    self.PanelDisable.gameObject:SetActiveEx(not self._IsUnlock)
    self.PanelNow.gameObject:SetActiveEx(false)
    self.PanelNumber.gameObject:SetActiveEx(not onlyOne)
    local ids
    local containerFurnitureData = self._Control:CloneContainerFurnitureData(self._AreaType)
    self._IsCurrent = false
    if onlyOne then
        ids = self._Control:GetFurnitureIdListByConfigId(configId)
        local id = ids and ids[1] or 0
        local f = containerFurnitureData:GetFurniture(id)
        self._IsCurrent = f ~= nil or containerFurnitureData:GetContainer():GetId() == id
        self.PanelNow.gameObject:SetActiveEx(self._IsCurrent)
    else
        ids = self._Control:GetNotPutFurnitureIdList(configId, containerFurnitureData)
        self.TxtNumber.text = ids and #ids or 0
    end
    self._IdList = ids
    self:SetSelect(configId == selectId)
end

function XUiGridSGFurniture:InitUi()
    self.UiBigWorldRed.gameObject:SetActiveEx(false)
end

function XUiGridSGFurniture:InitCb()
end

function XUiGridSGFurniture:SetSelect(value, lockTips)
    --未解锁
    if not self:CheckUnlock(lockTips) then
        self.PanelSelect.gameObject:SetActiveEx(false)
        
        return 0
    end
    --当前已经摆放
    if self._IsCurrent then
        self.PanelSelect.gameObject:SetActiveEx(value)
        return 1
    end
    --没有家具可以摆放了
    if XTool.IsTableEmpty(self._IdList) then
        self.PanelSelect.gameObject:SetActiveEx(false)
        return 0
    end
    self._IsSelect = value
    self.PanelSelect.gameObject:SetActiveEx(value)
    return 2
end

function XUiGridSGFurniture:OnClick()
    local code = self:SetSelect(true, true)
    if code == 0 then
        return
    end
    self.Parent:OnSelectFurniture(self._IdList[1], self._ConfigId, self, code == 2)
end

function XUiGridSGFurniture:CheckUnlock(tips)
    if self._IsUnlock then
        return true
    end
    self._IsSelect = false
    self.PanelSelect.gameObject:SetActiveEx(false)
    if tips then
        local desc = self._Control:GetFurnitureLockDesc(self._ConfigId)
        if not string.IsNilOrEmpty(desc) then
            XUiManager.TipMsg(desc)
        end
    end
    return false
end

function XUiGridSGFurniture:GetConfigId()
    return self._ConfigId
end

return XUiGridSGFurniture