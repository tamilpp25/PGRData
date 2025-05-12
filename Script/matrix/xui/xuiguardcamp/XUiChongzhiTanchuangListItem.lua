local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiChongzhiTanchuangListItem = XClass(nil, "XUiChongzhiTanchuangListItem")

function XUiChongzhiTanchuangListItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- 更新数据
function XUiChongzhiTanchuangListItem:OnRefresh(itemdata)
    if not itemdata then
        return
    end

    self.ItemData = itemdata
    self.GridItemUI:Refresh(itemdata)
end

function XUiChongzhiTanchuangListItem:Init(root)
    self.GridItemUI = XUiGridCommon.New(root,self.GridItem)
end

return XUiChongzhiTanchuangListItem