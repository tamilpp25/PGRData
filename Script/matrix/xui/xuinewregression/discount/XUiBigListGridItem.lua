local XUiBigListGridItem = XClass(nil, "XUiBigListGridItem")

function XUiBigListGridItem:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.GridItemUi = XUiGridCommon.New(rootUi, self.Grid)
end

-- 更新数据
function XUiBigListGridItem:OnRefresh(itemData)
    if not itemData then
        return
    end

    self.ItemData = itemData
    self.GridItemUi:Refresh(itemData)
end

return XUiBigListGridItem