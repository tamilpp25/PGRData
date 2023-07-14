
---@class XUiPanelRestaurantLevelUp
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
local XUiPanelRestaurantLevelUp = XClass(nil, "XUiPanelRestaurantLevelUp")

function XUiPanelRestaurantLevelUp:Ctor(ui, gridClass)
    XTool.InitUiObjectByUi(self, ui)
    self.GridClass = gridClass
    self:InitUi()
    self:InitCb()
end

function XUiPanelRestaurantLevelUp:InitUi()
    self.Grids = {}
    self.DataList = {}
    self.GridItem.gameObject:SetActiveEx(false)
end

function XUiPanelRestaurantLevelUp:InitCb()
end

function XUiPanelRestaurantLevelUp:Refresh(list, ...)
    self.DataList = list
    self.PanelNothing.gameObject:SetActiveEx(self:IsEmpty())
    if self:GetTxtTitle() then
        self.TxtTitle.text = self:GetTxtTitle()
    end
    if self:IsEmpty() and self:GetTxtEmpty() then
        self.TxtEmpty.text = self:GetTxtEmpty()
    end
    
    self:RefreshGrids()
end

function XUiPanelRestaurantLevelUp:IsEmpty()
    return XTool.IsTableEmpty(self.DataList)
end

function XUiPanelRestaurantLevelUp:GetTxtTitle()
end

function XUiPanelRestaurantLevelUp:GetTxtEmpty()
end

function XUiPanelRestaurantLevelUp:HideAllGrids()
    for _, grid in pairs(self.Grids) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelRestaurantLevelUp:RefreshGrids()
    self:HideAllGrids()
    if self:IsEmpty() then
        return
    end
    for idx, data in ipairs(self.DataList) do
        local grid = self.Grids[idx]
        if not grid then
            local ui = idx == 1 and self.GridItem or XUiHelper.Instantiate(self.GridItem, self.Container.transform)
            grid = self.GridClass.New(ui)
            self.Grids[idx] = grid
        end
        grid:Refresh(data)
    end
end

return XUiPanelRestaurantLevelUp