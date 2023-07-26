local XRightTagItem=XClass(nil,"XRightTagItem")

function XRightTagItem:Ctor(ui)
    self.Text=ui.transform:Find('Image/Text'):GetComponent(typeof(CS.UnityEngine.UI.Text))
    XTool.InitUiObjectByUi(self,ui)
end

function XRightTagItem:SetContent(content)
    self.Text.text=content
end

return XRightTagItem