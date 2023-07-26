---@class XUiDlcHuntChipDetailAttrCompare
local XUiDlcHuntChipDetailAttrCompare = XClass(nil, "XUiDlcHuntChipDetailAttrCompare")

function XUiDlcHuntChipDetailAttrCompare:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

---@param data DlcHuntAttrCompare
function XUiDlcHuntChipDetailAttrCompare:Update(data)
    self.TxtName.text = data.Name
    self.TxtCurAttr.text = data.StrValueBefore
    if data.ValueAfter == data.ValueBefore then
        self.TxtSelectAttr.gameObject:SetActiveEx(false)
        if self.ImgJiantou then
            self.ImgJiantou.gameObject:SetActiveEx(false)
        end
    else
        self.TxtSelectAttr.gameObject:SetActiveEx(true)
        if self.ImgJiantou then
            self.ImgJiantou.gameObject:SetActiveEx(true)
        end
    end
    self.TxtSelectAttr.text = data.StrValueAfter
end

return XUiDlcHuntChipDetailAttrCompare