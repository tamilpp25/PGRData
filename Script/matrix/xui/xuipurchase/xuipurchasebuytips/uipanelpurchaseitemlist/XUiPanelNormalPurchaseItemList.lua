local XUiPanelPurchaseItemListBase = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiPanelPurchaseItemListBase')
local XUiPurchaseLBTipsListItem = require("XUi/XUiPurchase/XUiPurchaseLBTipsListItem")

---@class XUiPanelNormalPurchaseItemList: XUiPanelPurchaseItemListBase
local XUiPanelNormalPurchaseItemList = XClass(XUiPanelPurchaseItemListBase, 'XUiPanelNormalPurchaseItemList')

function XUiPanelNormalPurchaseItemList:InitGoodsShow(dataList, hasConsumeCount, noConvertSwitch)

    if self._ItemMap == nil then
        self._ItemMap = {}
    end

    if not XTool.IsTableEmpty(self._ItemMap) then
        for i, v in pairs(self._ItemMap) do
            v:Close()
        end
    end
    
    XUiHelper.RefreshCustomizedList(self.PanelReward, self.PanelPropItem, dataList and #dataList or 0, function(index, go)
        local itemGrid = self._ItemMap[go]

        if not itemGrid then
            itemGrid = XUiPurchaseLBTipsListItem.New(go, self)
            itemGrid:Init(self.Parent)
            self._ItemMap[go] = itemGrid
        end

        local data = dataList[index]
        itemGrid:Open()
        itemGrid:OnRefresh(data)

        -- v1.31-采购优化-涂装CG展示已拥有
        if (data.IsSubItem and data.IsHave) or (hasConsumeCount and noConvertSwitch) then
            itemGrid.GridItemUi.TxtHave.gameObject:SetActiveEx(true)
            itemGrid.GridItemUi.TxtCount.gameObject:SetActiveEx(false)
        end
    end)
end


return XUiPanelNormalPurchaseItemList