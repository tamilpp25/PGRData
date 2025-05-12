
---@class XUiPanelRestaurantLevelUp : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XRestaurantControl
local XUiPanelRestaurantLevelUp = XClass(XUiNode, "XUiPanelRestaurantLevelUp")

function XUiPanelRestaurantLevelUp:OnStart(gridClass)
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
            grid:Close()
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
            ui.gameObject:SetActiveEx(true)
            grid = self.GridClass.New(ui, self.Parent)
            self.Grids[idx] = grid
        end
        grid:Open()
        grid:Refresh(data)
    end
end

return XUiPanelRestaurantLevelUp