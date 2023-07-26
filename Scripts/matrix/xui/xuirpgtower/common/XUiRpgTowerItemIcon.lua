-- 兵法蓝图道具图标控件
local XUiRpgTowerItemIcon = XClass(nil, "XUiRpgTowerItemIcon")

function XUiRpgTowerItemIcon:Ctor(rawImg, rItem)
    XTool.InitUiObjectByUi(self, rawImg)
    self.RawImage = rawImg
    if rItem then self:InitIcon(rItem) end
end
--===============
--初始化图标
--===============
function XUiRpgTowerItemIcon:InitIcon(rItem)
    self.RItem = rItem
    self.RawImage:SetRawImage(rItem:GetIcon())
    CsXUiHelper.RegisterClickEvent(self.RawImage, function() self:OnClick() end)
end
--===============
--点击事件
--===============
function XUiRpgTowerItemIcon:OnClick()
    XLuaUiManager.Open("UiTip", self.RItem:GetTempItemData())
end

return XUiRpgTowerItemIcon