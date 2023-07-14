local XUiDecorationGrid = require("XUi/XUiTheatre/Decoration/XUiDecorationGrid")

local MAX_GRID_COUNT = 9

--装修组
local XUiDecorationGroup = XClass(nil, "XUiDecorationGroup")

function XUiDecorationGroup:Ctor(ui, decorationIdList, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self.ClickCallback = clickCb
    self:InitData(decorationIdList)
end

function XUiDecorationGroup:InitData(decorationIdList)
    self.GridList = {}
    self.DecorationIdList = decorationIdList
    table.sort(self.DecorationIdList, function(idA, idB)
        local gridIndexA = XTheatreConfigs.GetTheatreDecorationIdToGridIndex(idA)
        local gridIndexB = XTheatreConfigs.GetTheatreDecorationIdToGridIndex(idB)
        return gridIndexA < gridIndexB
    end)

    for i, decorationId in ipairs(self.DecorationIdList) do
        local grid = self["Grid" .. i]
        if grid then
            grid.gameObject:SetActiveEx(true)
            table.insert(self.GridList, XUiDecorationGrid.New(grid, decorationId, handler(self, self.ClickGridCallback)))
        end
    end

    for i = #self.GridList + 1, MAX_GRID_COUNT do
        if self["Grid" .. i] then
            self["Grid" .. i].gameObject:SetActiveEx(false)
        end
    end

    self.RawImage.gameObject:SetActiveEx(#self.GridList ~= 0)
end

function XUiDecorationGroup:Refresh()
    for _, v in ipairs(self.GridList) do
        v:Refresh()
    end
end

function XUiDecorationGroup:ClickGridCallback(grid)
    self.ClickCallback(grid)
end

return XUiDecorationGroup