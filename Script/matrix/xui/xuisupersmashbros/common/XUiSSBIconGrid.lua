--===========================
--超限乱斗道具图标
--===========================
local XUiSSBIconGrid = XClass(nil, "XUiSSBIconGrid")

function XUiSSBIconGrid:Ctor(iconPrefab, onClickEvent)
    XTool.InitUiObjectByUi(self, iconPrefab)
    self.OnClickEvent = onClickEvent
    XUiHelper.RegisterClickEvent(self, self.BtnClick or self.RImgIcon, function() self:OnClick() end)
end
--=============
--使用道具Id刷新(itemId : Item表Id)
--=============
function XUiSSBIconGrid:Refresh(itemId)
    self.ItemId = itemId
    if not self.ItemId or self.ItemId == 0 then return end
    if self.RImgIcon then
        local itemIcon = XDataCenter.ItemManager.GetItemIcon(self.ItemId)
        self.RImgIcon:SetRawImage(itemIcon)
    end
    if self.ImgQuality then
        local itemQuality = XDataCenter.ItemManager.GetItemQuality(self.ItemId)
        self.ImgQuality:SetSprite(XArrangeConfigs.GeQualityPath(itemQuality))
    end
end
--=============
--点击时
--=============
function XUiSSBIconGrid:OnClick()
    if not self.ItemId or self.ItemId == 0 then return end
    if self.OnClickEvent then
        self.OnClickEvent()
        return
    end
    XLuaUiManager.Open("UiTip", self.ItemId)
end

return XUiSSBIconGrid