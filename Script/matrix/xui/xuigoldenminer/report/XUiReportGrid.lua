local XUiReportGrid = XClass(nil, "XUiReportGrid")

function XUiReportGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GameObject:SetActiveEx(true)
end

function XUiReportGrid:Refresh(data)
    local icon = data.Icon
    local txtScore = data.TxtScore
    if self.RImgTool then
        self.RImgTool:SetRawImage(icon)
    end
    if self.TxtTool then
        self.TxtTool.text = txtScore
    end
end

return XUiReportGrid