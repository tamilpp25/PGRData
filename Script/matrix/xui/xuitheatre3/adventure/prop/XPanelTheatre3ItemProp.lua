local XUiGridTheatre3Reward = require("XUi/XUiTheatre3/Adventure/Prop/XUiGridTheatre3Reward")

---@class XPanelTheatre3ItemProp : XUiNode
---@field _Control XTheatre3Control
local XPanelTheatre3ItemProp = XClass(XUiNode, "XPanelTheatre3ItemProp")

function XPanelTheatre3ItemProp:OnStart()
    ---@type XUiGridTheatre3Reward[]
    self._GridList = {}
end

function XPanelTheatre3ItemProp:Refresh(itemIdList, selectCb)
    for i, itemId in ipairs(itemIdList) do
        local go = i == 1 and self.PropGrid or XUiHelper.Instantiate(self.PropGrid.gameObject, self.PropGrid.transform.parent)
        ---@type XUiGridTheatre3Reward
        local grid = XUiGridTheatre3Reward.New(go, self.Parent)
        grid:SetData(itemId, XEnumConst.THEATRE3.EventStepItemType.InnerItem, selectCb)
        grid:ShowRed(false)
        self._GridList[#self._GridList + 1] = grid
    end
end

--region Ui - ItemRefresh
---@param grid XUiGridTheatre3Reward
function XPanelTheatre3ItemProp:RefreshSelect(grid)
    for _, itemGrid in pairs(self._GridList) do
        itemGrid:ShowSelect(itemGrid == grid)
    end
end

---@return XUiGridTheatre3Reward
function XPanelTheatre3ItemProp:GetItemGrid(index)
    return self._GridList[index]
end
--endregion

return XPanelTheatre3ItemProp