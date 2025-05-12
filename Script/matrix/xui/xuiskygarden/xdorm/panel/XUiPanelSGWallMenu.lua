local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelSGWallMenu : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiPanelSGWall
local XUiPanelSGWallMenu = XClass(XUiNode, "XUiPanelSGWallMenu")

function XUiPanelSGWallMenu:OnStart(areaType)
    self._AreaType = areaType
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGWallMenu:Refresh()
end

function XUiPanelSGWallMenu:InitUi()
    self.BtnSkipClick.gameObject:SetActiveEx(false)
    self.GridItem.gameObject:SetActiveEx(false)
    self._DynamicTable = XDynamicTableNormal.New(self.List)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(require("XUi/XUiSkyGarden/XDorm/Grid/XUiGridSGFurniture"), self, self._AreaType)
    self._TypeId2List = {}
end

function XUiPanelSGWallMenu:InitCb()
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_DORM_FURNITURE_REFRESH, self.ClearListCache, self)
end

function XUiPanelSGWallMenu:OnDestroy()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_DORM_FURNITURE_REFRESH, self.ClearListCache, self)
end

function XUiPanelSGWallMenu:OnTypeIdChanged(typeId, selectId)
    if self._TypeId2List[typeId] then
        self:SetupDynamicTable(self._TypeId2List[typeId], selectId)
        return 
    end
    local list = self._Control:GetFurnitureListByTypeId(typeId)
    
    if not XTool.IsTableEmpty(list) then
        local temp
        --需求：未解锁 && 未配置解锁文案
        for i, configId in pairs(list) do
            if not self._Control:CheckFurnitureUnlockByConfigId(configId)
                    and string.IsNilOrEmpty(self._Control:GetFurnitureLockDesc(configId)) then
                if not temp then temp = {} end
                temp[#temp + 1] = i
            end
        end

        if temp then
            for i = #temp, 1, -1 do
                local index = temp[i]
                table.remove(list, index)
            end
        end

        self._TypeId2List[typeId] = list
    end

    self:SetupDynamicTable(list)
end

function XUiPanelSGWallMenu:ClearListCache()
    self._TypeId2List = {}
end

function XUiPanelSGWallMenu:SetupDynamicTable(list, selectId)
    if self._LastGrid then
        self._LastGrid:SetSelect(false)
    end
    self._LastGrid = nil
    --self._SelectCfgId = nil
    
    self._DataList = self:SortDataList(list)
    self._SelectCfgId = selectId
    local startIndex
    if selectId then
        for i, cfgId in pairs(self._DataList) do
            if cfgId == selectId then
                startIndex = i
                break
            end
        end
    end
    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync(startIndex)
end

function XUiPanelSGWallMenu:RefreshDynamicTable(selectId)
    if XTool.IsTableEmpty(self._DataList) then
        return
    end
    self:SetupDynamicTable(self._DataList, selectId)
end

---@param grid XUiGridSGFurniture
function XUiPanelSGWallMenu:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local configId = self._DataList[index]
        grid:Refresh(configId, self._SelectCfgId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if self._SelectCfgId then
            local grids = self._DynamicTable:GetGrids()
            ---@type XUiGridSGFurniture
            local temp
            for _, g in pairs(grids) do
                if g:GetConfigId() == self._SelectCfgId then
                    temp = g
                    break
                end
            end
            if temp then
                temp:SetSelect(true)
            end
            --self._SelectCfgId = nil
        end
    end
end

function XUiPanelSGWallMenu:SortDataList(list)
    if XTool.IsTableEmpty(list) then
        return {}
    end
   
    local control = self._Control
    table.sort(list, function(a, b) 
        local unlockA = control:CheckFurnitureUnlockByConfigId(a)
        local unlockB = control:CheckFurnitureUnlockByConfigId(b)
        if unlockA ~= unlockB then
            return unlockA
        end
        local pA = control:GetFurniturePriority(a)
        local pB = control:GetFurniturePriority(b)
        if pA ~= pB then
            return pA > pB
        end
        return a < b
    end)
    
    return list
end

---@param grid XUiGridSGFurniture
function XUiPanelSGWallMenu:OnSelectFurniture(id, cfgId, grid, isCreate)
    self._SelectCfgId = cfgId
    if self._LastGrid then
        self._LastGrid:SetSelect(false)
    end
    
    self._LastGrid = grid
    
    self.Parent:OnSelectFurniture(id, cfgId, isCreate)
end

return XUiPanelSGWallMenu