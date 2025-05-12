---场景动态列表中的元素控制器
local XDynamicFashionGrid = XClass(XUiNode, "XDynamicFashionGrid")

---更新元素的内容显示
function XDynamicFashionGrid:Refresh(fashionId)
    self.FashionId = fashionId
    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
    self.RImgIcon:SetRawImage(template.Icon)
    self.TxtName.text = template.Name
end

function XDynamicFashionGrid:SetSelect(bool)
    self.PanelSelect.gameObject:SetActiveEx(bool)
    self.IsSelected = bool
end

return XDynamicFashionGrid