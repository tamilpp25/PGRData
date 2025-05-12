local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")
---@class XUiGridTheatre4BagProp : XUiNode
---@field private _Control XTheatre4Control
---@field Parent XUiTheatre4BagProp
local XUiGridTheatre4BagProp = XClass(XUiNode, "XUiGridTheatre4BagProp")

function XUiGridTheatre4BagProp:OnStart()
    self.GridProp.gameObject:SetActiveEx(false)
    ---@type XUiGridTheatre4Prop[]
    self.GridPropList = {}
end

function XUiGridTheatre4BagProp:Refresh(itemType, propList)
    self.PropDataList = propList
    --self.TxtTitle.text = self._Control:GetClientConfig("ArchieveTypeText", itemType)
    self:RefreshPropGrid()
end

function XUiGridTheatre4BagProp:RefreshPropGrid()
    if XTool.IsTableEmpty(self.PropDataList) then
        return
    end
    for index, data in pairs(self.PropDataList) do
        local grid = self.GridPropList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridProp, self.PanelGroup)
            grid = XUiGridTheatre4Prop.New(go, self, Handler(self, self.OnPropGridClick))
            self.GridPropList[index] = grid
        end
        grid:Open()
        grid:Refresh(data)
    end
    for i = #self.PropDataList + 1, #self.GridPropList do
        self.GridPropList[i]:Close()
    end
end

---@param grid XUiGridTheatre4Prop
function XUiGridTheatre4BagProp:OnPropGridClick(grid)
    self.Parent:OnPropGridClick(grid)
end

return XUiGridTheatre4BagProp
