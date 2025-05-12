local XUiPanelNoSelectInfo = XClass(XUiNode, 'XUiPanelNoSelectInfo')

function XUiPanelNoSelectInfo:RefreshData(title, desc)
    self.TxtHeadName.text = title
    self.TxtDecs.text = desc
end

return XUiPanelNoSelectInfo