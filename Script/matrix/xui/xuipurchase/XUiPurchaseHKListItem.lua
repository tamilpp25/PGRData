local XUiPurchaseHKListItem = XClass(nil, "XUiPurchaseHKListItem")

function XUiPurchaseHKListItem:Ctor(ui,uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
end

-- 更新数据
function XUiPurchaseHKListItem:OnRefresh(itemData)
    if not itemData then
        return
    end
    self.ItemData = itemData
end

function XUiPurchaseHKListItem:Init(uiRoot,parent)
    self.UiRoot = uiRoot
    self.Parent = parent
end

return XUiPurchaseHKListItem