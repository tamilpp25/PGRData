local XUiPlayerInfoClothGrid = XClass(nil, "XUiPlayerInfoClothGrid")

function XUiPlayerInfoClothGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiPlayerInfoClothGrid:AutoAddListener()
    self.BtnFashion.CallBack = function() self:OnBtnFashion() end
end

function XUiPlayerInfoClothGrid:OnBtnFashion()
    local IsWeaponFashion = self.FashionType == XPlayerInfoConfigs.FashionType.Weapon
    XLuaUiManager.Open("UiFashionDetail", self.Fashion.Id, IsWeaponFashion)
end

function XUiPlayerInfoClothGrid:UpdateGrid(fashion, fashionType)
    if not fashion then
        XLog.Error("XUiPlayerInfoClothGrid:UpdateGrid函数参数错误：参数fashion不能为空")
        return
    end
    local isLocked = fashion.IsLocked

    self.Fashion = fashion.Data
    self.FashionType = fashionType
    self.TxtFashionName.text = fashion.Data.Name

    self.ImgFashion:SetRawImage(fashion.Data.BigIcon)
    self.PanelLock.gameObject:SetActiveEx(isLocked)
    self.BtnFashion.gameObject:SetActiveEx(not isLocked)
end

return XUiPlayerInfoClothGrid