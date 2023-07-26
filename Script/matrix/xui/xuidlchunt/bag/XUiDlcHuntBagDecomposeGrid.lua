---@class XUiDlcHuntBagDecomposeGrid
local XUiDlcHuntBagDecomposeGrid = XClass(nil, "XUiDlcHuntBagDecomposeGrid")

function XUiDlcHuntBagDecomposeGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.ImgQuality = XUiHelper.TryGetComponent(self.Transform, "ImgQuality", "Image")
end

---@param data XDlcHuntItem
function XUiDlcHuntBagDecomposeGrid:Update(data)
    self.RImgIcon:SetRawImage(data:GetIcon())
    self.TxtCount.text = XUiHelper.GetText("STBagDecomposionNum", data:GetAmount())
    self.ImgQuality.color = data:GetQualityColor()
end

return XUiDlcHuntBagDecomposeGrid