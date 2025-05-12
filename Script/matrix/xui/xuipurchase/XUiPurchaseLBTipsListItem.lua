local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPurchaseLBTipsListItem = XClass(XUiNode, "XUiPurchaseLBTipsListItem")

-- 更新数据
function XUiPurchaseLBTipsListItem:OnRefresh(itemData)
    if not itemData then
        return
    end

    self.ItemData = itemData
    self.GridItemUi:Refresh(itemData)
    -- 已拥有也要显示数量
    self.GridItemUi:ShowCount(true)
end

function XUiPurchaseLBTipsListItem:Init(root)
    self.GridItemUi = XUiGridCommon.New(root,self.GridItem)
end

return XUiPurchaseLBTipsListItem