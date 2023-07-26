---@class XUiDlcHuntChipGridAttr
local XUiDlcHuntChipGridAttr = XClass(nil, "XUiDlcHuntChipGridAttr")

function XUiDlcHuntChipGridAttr:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntChipGridAttr:Update(data)
    self.TxtName1.text = data.Name
    self.TxtAttr1.text = data.Value
    if self.ImgDown then
        self.ImgDown.gameObject:SetActiveEx(data.IsRed)
    end
    if self.ImgUp then
        self.ImgUp.gameObject:SetActiveEx(data.IsGreen)
    end
    if self.Text2 then
        self.Text2.text = data.NameEn
    end
end

return XUiDlcHuntChipGridAttr