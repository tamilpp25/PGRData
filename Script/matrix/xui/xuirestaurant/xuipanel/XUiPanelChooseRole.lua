
local XUiPanelWorkBase = require("XUi/XUiRestaurant/XUiPanel/XUiPanelWorkBase")
local XUiGridBenchStaff = require("XUi/XUiRestaurant/XUiGrid/XUiGridBenchStaff")

---@class XUiPanelChooseRole : XUiPanelWorkBase
local XUiPanelChooseRole = XClass(XUiPanelWorkBase, "XUiPanelChooseRole")

function XUiPanelChooseRole:InitUi()
    self:InitDynamicTable()
end

function XUiPanelChooseRole:InitDynamicTable()
    if XTool.UObjIsNil(self.PanelRoleList) then
        return
    end
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRoleList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridBenchStaff, handler(self, self.OnSelect))
    self.GridRole.gameObject:SetActiveEx(false)
end

function XUiPanelChooseRole:InitCb()
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
end

function XUiPanelChooseRole:RefreshView()
    self:SetupDynamicTable()
    self:RefreshChoose()
end

function XUiPanelChooseRole:ClearCache()
    self.LastGrid = nil
end

function XUiPanelChooseRole:SetupDynamicTable()
    if not self.DynamicTable then
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local benchModel = viewModel:GetWorkBenchViewModel(self.AreaType, self.Index)
    local productId = benchModel:GetProperty("_ProductId")
    local list = viewModel:GetSortRecruitStaffList(self.AreaType, productId)
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(list))
    self.DataList = list
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelChooseRole:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local selectId = self.Staff and self.Staff:GetProperty("_Id") or 0
        grid:Refresh(self.DataList[index], self.AreaType, self.Index, selectId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self.Staff then
            return
        end
        local grids = self.DynamicTable:GetGrids()
        for _, item in pairs(grids or {}) do
            if item and item.Staff 
                    and self.Staff:Equal(item.Staff) then
                item:SetSelect(false)
                item:OnBtnClick()
                break
            end
        end
    end
end

function XUiPanelChooseRole:OnBtnConfirmClick()
    if not self.Staff then
        local desc = XRestaurantConfigs.GetClientConfig("ProduceDesc", 4)
        XUiManager.TipMsg(desc)
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local characterId = self.Staff:GetProperty("_Id")
    if not XTool.IsNumberValid(characterId) then
        return
    end
    if self.Staff and self.Staff:IsWorking() then
        local tip = XRestaurantConfigs.GetClientConfig("StaffWorkTip", 1)
        XUiManager.TipMsg(string.format(tip, self.Staff:GetName()))
        return
    end
    
    local benchModel = viewModel:GetWorkBenchViewModel(self.AreaType, self.Index)
    benchModel:AddStaff(characterId)
end

--- 点选回调
---@param grid XUiGridBenchStaff
--------------------------
function XUiPanelChooseRole:OnSelect(grid)
    if self.LastGrid then
        self.LastGrid:SetSelect(false)
    end
    self.LastGrid = grid
    self.Staff = grid.Staff
    
    self:RefreshChoose()
end

function XUiPanelChooseRole:RefreshChoose()
    local select = self.Staff and true or false
    self.BtnConfirm:SetDisable(not select, select)
end

return XUiPanelChooseRole