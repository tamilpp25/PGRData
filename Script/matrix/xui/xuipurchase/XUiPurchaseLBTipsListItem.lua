local XUiPurchaseLBTipsListItem = XClass(nil, "XUiPurchaseLBTipsListItem")

function XUiPurchaseLBTipsListItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- 更新数据
function XUiPurchaseLBTipsListItem:OnRefresh(itemData)
    if not itemData then
        return
    end

    self.ItemData = itemData
    self.GridItemUi:Refresh(itemData)
end

function XUiPurchaseLBTipsListItem:Init(root)
    self.GridItemUi = XUiGridCommon.New(root,self.GridItem)
end

return XUiPurchaseLBTipsListItem