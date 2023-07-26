--肉鸽二期 通用道具详情
local XUiItemDetailPanel = XClass(nil, "XUiItemDetailPanel")

function XUiItemDetailPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Hide()
end

function XUiItemDetailPanel:Show(theatreItemId)
    --道具图标
    local itemIcon = XBiancaTheatreConfigs.GetItemIcon(theatreItemId)
    self.RImgIcon:SetRawImage(itemIcon)
    --道具品质
    local quality = XBiancaTheatreConfigs.GetTheatreItemQuality(theatreItemId)
    XUiHelper.SetQualityIcon(nil, self.ImgQuality, quality)
    --道具名
    self.TxtName.text = XBiancaTheatreConfigs.GetItemName(theatreItemId)
    --道具描述
    self.TxtEffectInfo.text = XBiancaTheatreConfigs.GetItemWorldDesc(theatreItemId)
    self.TxtAttrInfo.text = XBiancaTheatreConfigs.GetItemDescription(theatreItemId)
    --解锁描述
    if self.ImageLock and self.TxtlockInfo then
        local isUnlock = XDataCenter.BiancaTheatreManager.IsUnlockItem(theatreItemId)
        local conditionId = XBiancaTheatreConfigs.GetItemUnlockConditionId(theatreItemId)
        local showLock = not isUnlock and XTool.IsNumberValid(conditionId)
        self.ImageLock.gameObject:SetActiveEx(showLock)
        self.TxtlockInfo.gameObject:SetActiveEx(showLock)
        if showLock then
            local desc = XConditionManager.GetConditionDescById(conditionId)
            self.TxtlockInfo.text = desc
        end
    end

    self.GameObject:SetActiveEx(true)
end

function XUiItemDetailPanel:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiItemDetailPanel