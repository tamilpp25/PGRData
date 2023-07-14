---@class XUiDlcHuntBagGridOthers
local XUiDlcHuntBagGridOthers = XClass(nil, "XUiDlcHuntBagGridOthers")

function XUiDlcHuntBagGridOthers:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.ImgSelected.gameObject:SetActiveEx(false)
    self._Item = false
end

---@param item XItem
function XUiDlcHuntBagGridOthers:Update(item)
    self._Item = item
    local quality = item.Template.Quality
    local icon = item.Template.Icon
    local count = item:GetCount()
    self.RImgIcon:SetRawImage(icon)
    self.TxtNum.text = count
    self.ImgQuality.color = XDlcHuntChipConfigs.GetQualityColor(quality)
    self:UpdateSelected()
end

function XUiDlcHuntBagGridOthers:UpdateSelected()
    self.ImgSelected.gameObject:SetActiveEx(false)
end

function XUiDlcHuntBagGridOthers:SetViewModel()
    
end

function XUiDlcHuntBagGridOthers:OnClick()
    if self._Item then
        XLuaUiManager.Open("UiDlcHuntTip", self._Item)
    end
end

return XUiDlcHuntBagGridOthers