local XUiGridHelpCourse = XClass(nil, "XUiGridHelpCourse")

function XUiGridHelpCourse:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridHelpCourse:Refresh(icon, index, length)
    local visible=index>1

    self.GridHelp:SetRawImage(icon)
    self.ImgArrowNext.gameObject:SetActive(length > index)

    if visible then
        self.TxtPages.text = tostring(length-1)
        self.TxtNumber.text = tostring(index-1)
    end
    
    self:SetPageCounterDisplay(visible)
end

function XUiGridHelpCourse:SetPageCounterDisplay(visible)
    self.TxtPages.gameObject:SetActiveEx(visible)
    self.TxtNumber.gameObject:SetActiveEx(visible)
    self.Txt.gameObject:SetActiveEx(visible)
end

return XUiGridHelpCourse