---@class XUiGridSGNumber : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiPanelSGNumber
local XUiGridSGNumber = XClass(XUiNode, "XUiGridSGNumber")

function XUiGridSGNumber:Refresh(icon, cur, max, name)
    if not string.IsNilOrEmpty(icon) then
        self.ImgIcon:SetSprite(icon)
    end
    
    if not string.IsNilOrEmpty(name) then
        self.Txt.text = name
    end
    self.TxtNumber.text = string.format("%s/%s", cur, max)
    self:Open()
end


---@class XUiPanelSGNumber : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiSkyGardenDormPhotoWall
---@field _GridNum1 XUiGridSGNumber
---@field _GridNum2 XUiGridSGNumber
local XUiPanelSGNumber = XClass(XUiNode, "XUiPanelSGNumber")

function XUiPanelSGNumber:OnStart(areaType)
    self._AreaType = areaType
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGNumber:Refresh()
end

function XUiPanelSGNumber:InitUi()
    self._GridNum1 = XUiGridSGNumber.New(self.GridNumber1, self)
    self._GridNum2 = XUiGridSGNumber.New(self.GridNumber2, self)
end

function XUiPanelSGNumber:InitCb()
end

function XUiPanelSGNumber:Refresh()
    local control = self._Control
    local typeList, capacityList = control:GetContainerCapacity(self._AreaType)
    self._GridNum1:Close()
    self._GridNum2:Close()
    if XTool.IsTableEmpty(typeList) or XTool.IsTableEmpty(capacityList) then
        return
    end
    local dict = control:GetPutCountDictByMajorType(typeList, self.Parent:GetContainerData())
    for i, majorType in pairs(typeList) do
        local grid = self["_GridNum"..i]
        if grid then
            local capacity = capacityList[i]
            local typeId = control:GetTypeIdByMajorType(majorType)
            local name = control:GetFurnitureMajorName(typeId)
            grid:Refresh(nil, dict[majorType], capacity, name)
        end
    end
end

function XUiPanelSGNumber:IsFull(majorType)
    local control = self._Control
    local typeList, capacityList = control:GetContainerCapacity(self._AreaType)
    if XTool.IsTableEmpty(typeList) or XTool.IsTableEmpty(capacityList) then
        return true
    end
    local dict = control:GetPutCountDictByMajorType(typeList, self.Parent:GetContainerData())
    for i, mType in pairs(typeList) do
        if mType == majorType then
            local capacity = capacityList[i]
            return dict[mType] >= capacity
        end
    end
    return true
end

return XUiPanelSGNumber