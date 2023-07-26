local FavorCoin = XTheatreConfigs.TheatreFavorCoin

--肉鸽玩法势力总览格子
local XUiGridFavorList = XClass(nil, "XUiGridFavorList")

function XUiGridFavorList:Ctor(ui, clickGridCallback)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitUi()

    self.ClickGridCallback = clickGridCallback
    self.TheatrePowerManager = XDataCenter.TheatreManager.GetPowerManager()
    self.PanelBtn.CallBack = handler(self, self.OnPanelBtnClick)
end

function XUiGridFavorList:InitUi()
    self.PanelBtn = XUiHelper.TryGetComponent(self.Transform, "PanelBtn", "XUiButton")
    self.PanelPriceNormal = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnNormal/PanelPrice")
    self.RImgPriceNormal = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnNormal/PanelPrice/RImgPrice", "RawImage")
    self.TxtNewPriceNormal = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnNormal/PanelPrice/TxtNewPrice", "Text")
    self.RImgIconNormal = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnNormal/RImgIcon", "RawImage")
    self.TxtNameNormal = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnNormal/TxtName", "Text")
    self.TxtLvNormal = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnNormal/TxtLv", "Text")

    self.PanelPricePress = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnPress/PanelPrice")
    self.RImgPricePress = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnPress/PanelPrice/RImgPrice", "RawImage")
    self.TxtNewPricePress = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnPress/PanelPrice/TxtNewPrice", "Text")
    self.RImgIconPress = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnPress/RImgIcon", "RawImage")
    self.TxtNamePress = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnPress/TxtName", "Text")
    self.TxtLvPress = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnPress/TxtLv", "Text")
    
    self.PanelPriceDisable = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnDisable/PanelPrice")
    self.RImgPriceDisable = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnDisable/PanelPrice/RImgPrice", "RawImage")
    self.TxtNewPriceDisable = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnDisable/PanelPrice/TxtNewPrice", "Text")
    self.RImgIconDisable = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnDisable/RImgIcon", "RawImage")
    self.TxtNameDisable = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnDisable/TxtName", "Text")
    self.TxtLvDisable = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnDisable/TxtLv", "Text")
    self.TxtLock = XUiHelper.TryGetComponent(self.PanelBtn.transform, "BtnDisable/Text", "Text")
end

function XUiGridFavorList:Refresh(theatrePowerConditionId)
    self.TheatrePowerConditionId = theatrePowerConditionId

    local icon = XTheatreConfigs.GetPowerConditionIcon(theatrePowerConditionId)
    self.RImgIconNormal:SetRawImage(icon)
    self.RImgIconPress:SetRawImage(icon)
    self.RImgIconDisable:SetRawImage(icon)

    local name = XTheatreConfigs.GetPowerConditionName(theatrePowerConditionId)
    self.TxtNameNormal.text = name
    self.TxtNamePress.text = name
    self.TxtNameDisable.text = name

    --等级
    local curLv = self.TheatrePowerManager:GetPowerCurLv(theatrePowerConditionId)
    local textLv = XUiHelper.GetText("TheatreDecorationTipsLevel", curLv)
    self.TxtLvNormal.text = textLv
    self.TxtLvPress.text = textLv
    self.TxtLvDisable.text = textLv
    
    --好感度道具图标
    local itemIcon = XItemConfigs.GetItemIconById(FavorCoin)
    self.RImgPriceNormal:SetRawImage(itemIcon)
    self.RImgPricePress:SetRawImage(itemIcon)
    self.RImgPriceDisable:SetRawImage(itemIcon)

    --升到下一级所需好感度道具量/当前好感度道具数量
    local powerFavorId = XTheatreConfigs.GetTheatrePowerIdAndLvToId(theatrePowerConditionId, curLv)
    local isMaxLv = self.TheatrePowerManager:IsPowerMaxLv(theatrePowerConditionId)
    local upgradeCostConfig = powerFavorId and XTheatreConfigs.GetPowerFavorUpgradeCost(powerFavorId)
    local upgradeCost = XDataCenter.ItemManager.GetCount(FavorCoin)
    local textPrice = string.format("%s/%s", upgradeCost, upgradeCostConfig)
    self.TxtNewPriceNormal.text = textPrice
    self.TxtNewPricePress.text = textPrice
    self.TxtNewPriceDisable.text = textPrice

    local isLevelUp = (not isMaxLv and upgradeCostConfig) and true or false
    self.PanelPriceNormal.gameObject:SetActiveEx(isLevelUp)
    self.PanelPricePress.gameObject:SetActiveEx(isLevelUp)
    self.PanelPriceDisable.gameObject:SetActiveEx(isLevelUp)

    --未解锁显示
    local isUnlockPower, lockDesc = self.TheatrePowerManager:IsUnlockPower(theatrePowerConditionId)
    self.TxtLock.text = lockDesc
    self.PanelBtn:SetDisable(not isUnlockPower, isUnlockPower)
end

function XUiGridFavorList:OnPanelBtnClick()
    self.ClickGridCallback(self.TheatrePowerConditionId)
end

return XUiGridFavorList