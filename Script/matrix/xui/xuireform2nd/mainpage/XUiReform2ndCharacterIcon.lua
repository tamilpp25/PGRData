---@class XUiReform2ndCharacterIcon
local XUiReform2ndCharacterIcon = XClass(nil, "XUiReform2ndCharacterIcon")

function XUiReform2ndCharacterIcon:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiReform2ndCharacterIcon:SetIcon(icon)
    self.RImgIcon:SetRawImage(icon)
end

return XUiReform2ndCharacterIcon