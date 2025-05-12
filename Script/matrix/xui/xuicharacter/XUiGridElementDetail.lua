local XUiGridElementDetail = XClass(XUiNode, "XUiGridElementDetail")

function XUiGridElementDetail:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridElementDetail:Refresh(character, elementId)
    local isActive = XMVCA.XCharacter:IsElementActive(character, math.abs(elementId))
    self.PanelCur.gameObject:SetActiveEx(isActive)
    elementId = elementId > 0 and elementId or -elementId
    local elementConfig = XMVCA.XCharacter:GetCharElement(elementId)
    self.TxtName.text = elementConfig.ElementName
    self.TxtContent.text = elementConfig.Description
    self.RImgIcon:SetRawImage(elementConfig.Icon)
end

return XUiGridElementDetail