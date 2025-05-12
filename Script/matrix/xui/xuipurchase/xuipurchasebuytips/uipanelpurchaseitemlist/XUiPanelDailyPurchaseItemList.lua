local XUiPanelDaily = require("XUi/XUiSocial/XUiPanelDaily")
local XUiPanelPurchaseItemListBase = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiPanelPurchaseItemListBase')
local XUiPurchaseLBTipsListItem = require("XUi/XUiPurchase/XUiPurchaseLBTipsListItem")

---@class XUiPanelDailyPurchaseItemList: XUiPanelPurchaseItemListBase
local XUiPanelDailyPurchaseItemList = XClass(XUiPanelPurchaseItemListBase, 'XUiPanelDailyPurchaseItemList')

function XUiPanelDailyPurchaseItemList:InitGoodsShow(dataList, titleDesc)
    self.TxtTitle.text = titleDesc
    
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
    end)
end

return XUiPanelDailyPurchaseItemList