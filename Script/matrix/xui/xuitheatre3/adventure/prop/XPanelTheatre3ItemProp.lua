local XUiGridTheatre3Reward = require("XUi/XUiTheatre3/Adventure/Prop/XUiGridTheatre3Reward")

---@class XPanelTheatre3ItemProp : XUiNode
---@field _Control XTheatre3Control
local XPanelTheatre3ItemProp = XClass(XUiNode, "XPanelTheatre3ItemProp")

function XPanelTheatre3ItemProp:OnStart()
    ---@type XUiGridTheatre3Reward[]
    self._GridList = {}
end

---@param itemDataList XTheatre3Item[]
function XPanelTheatre3ItemProp:Refresh(itemDataList, selectCb)
    for i, item in ipairs(itemDataList) do
        local go = i == 1 and self.PropGrid or XUiHelper.Instantiate(self.PropGrid.gameObject, self.PropGrid.transform.parent)
        ---@type XUiGridTheatre3Reward
        local grid = XUiGridTheatre3Reward.New(go, self.Parent)
        grid:SetData(item.ItemId, XEnumConst.THEATRE3.EventStepItemType.InnerItem, selectCb)
        grid:SetItemData(item)
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