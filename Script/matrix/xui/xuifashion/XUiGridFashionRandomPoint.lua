local XUiGridFashionRandomPoint = XClass(XUiNode, "XUiGridFashionRandomPoint")

function XUiGridFashionRandomPoint:Refresh(isSelect, index)
    self.Index = index
    self.Nomal.gameObject:SetActiveEx(not isSelect)
    self.Select.gameObject:SetActiveEx(isSelect)
end

return XUiGridFashionRandomPoint