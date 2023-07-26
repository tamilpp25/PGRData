
---@class XUiPanelSViewReform
---@field ScrollView UnityEngine.UI.ScrollRect
local XUiPanelSViewReform = XClass(nil, "XUiPanelSViewReform")

function XUiPanelSViewReform:Ctor(ui, rootUi, grid, ...)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    
    self.GridItem.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(grid, ...)
    self.ControlLimit = CS.XGame.ClientConfig:GetInt("UiGridFurnitureControlLimit")
    self.OnClickGrid = nil
end

function XUiPanelSViewReform:SetupDynamicTable(dataList, startIndex)
    self.DataList = dataList or {}
    if not XTool.UObjIsNil(self.PanelEmpty) then
        self.PanelEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.DataList))
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(startIndex)
end

function XUiPanelSViewReform:OnDynamicTableEvent(evt, index, grid)

    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index], self.CurRoomId, self.SelectId, self.RoomType, index)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, self.RootUi)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not XTool.IsNumberValid(self.SelectId) then
            return
        end
        local grids = self.DynamicTable:GetGrids()

        for _, tempGrid in pairs(grids) do
            if tempGrid.GetSelectId and tempGrid:GetSelectId() == self.SelectId then
                self.LastGrid = tempGrid
                break
            end
        end
    end
end

function XUiPanelSViewReform:OnGridClick(grid, index)
    if self.LastGrid then
        self.LastGrid:SetSelect(false)
    end
    self.SelectId = grid:GetSelectId()
    self.LastGrid = grid
    if self.OnClickGrid then self.OnClickGrid(self.DataList[index]) end
end

function XUiPanelSViewReform:Show(dataList, startIndex, curRoomId, roomType)
    self.GameObject:SetActiveEx(true)
    self.CurRoomId = curRoomId
    self.RoomType = roomType
    self:SetupDynamicTable(dataList, startIndex)
end

function XUiPanelSViewReform:GetGrid(selectId, getIdCb)
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        if grid:GetSelectId() == selectId then
            return grid
        end
    end

    local startIndex
    for index, data in pairs(self.DataList) do
        if getIdCb(data) == selectId then
            startIndex = index
            break
        end
    end

    if startIndex then
        self:SetupDynamicTable(self.DataList, startIndex)
        for _, grid in pairs(grids) do
            if grid:GetSelectId() == selectId then
                return grid
            end
        end
    end
end

function XUiPanelSViewReform:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelSViewReform:ClearCache()
    if self.LastGrid then
        self.LastGrid:SetSelect(false)
    end
    self.LastGrid = nil
    self.SelectId = nil
end

function XUiPanelSViewReform:RegisterClickGrid(clickCb)
    self.OnClickGrid = clickCb
end

function XUiPanelSViewReform:GetStartIndex()
    return self.DynamicTable:GetStartIndex()
end

--region   ------------------Drag start-------------------
function XUiPanelSViewReform:OnDrag(eventData)
    if not self.ScrollView then
        return
    end
    self.ScrollView:OnDrag(eventData)
end

function XUiPanelSViewReform:OnBeginDrag(eventData)
    if not self.ScrollView then
        return
    end
    self.ScrollView:OnBeginDrag(eventData)
end

function XUiPanelSViewReform:OnEndDrag(eventData)
    if not self.ScrollView then
        return
    end
    self.ScrollView:OnEndDrag(eventData)
end
--endregion------------------Drag finish------------------

return XUiPanelSViewReform