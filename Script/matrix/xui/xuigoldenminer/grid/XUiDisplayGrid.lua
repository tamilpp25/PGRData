local XUiDisplayGrid = XClass(nil, "XUiDisplayGrid")

---黄金矿工通用展示格子
---@class XUiGoldenMinerDisplayGrid
function XUiDisplayGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDisplayGrid:Refresh(iconUrl, desc)
    if self.RImgBuff and not string.IsNilOrEmpty(iconUrl) then
        self.RImgBuff:SetRawImage(iconUrl)
    end
    
    if self.Text then
        self.Text.text = desc
        self.Text.gameObject:SetActiveEx(true)
    end
end

return XUiDisplayGrid