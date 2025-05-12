---@class XUiRiftPopupAffix : XLuaUi 插件随机词缀弹框
---@field _Control XRiftControl
local XUiRiftPopupAffix = XLuaUiManager.Register(XLuaUi, "UiRiftPopupAffix")

function XUiRiftPopupAffix:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self.BtnSave.CallBack = handler(self, self.OnBtnSaveClick)
    self.BtnResetting.CallBack = handler(self, self.OnBtnResettingClick)
    self.BtnUnlockAll.CallBack = handler(self, self.OnBtnUnlockAllClick)
    self.BtnUnlock.CallBack = handler(self, self.OnBtnUnlockClick)
    self.BtnUnlockAllCost.CallBack = handler(self, self.OnClickItem)
    self.BtnUnlockCost.CallBack = handler(self, self.OnClickItem)
    self.BtnResettingCost.CallBack = handler(self, self.OnClickItem)
end

function XUiRiftPopupAffix:OnStart(pluginId, index, unlockCallBack)
    local endTimeSecond = self._Control:GetTime()
    self:SetAutoCloseInfo(endTimeSecond, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self._Index = index
    self._PluginId = pluginId
    self._UnlockCallBack = unlockCallBack
    self._Plugin = self._Control:GetPlugin(pluginId)
    self._ItemCount = XDataCenter.ItemManager.GetCount(XEnumConst.Rift.Currency)
    self._ItemIcon = XDataCenter.ItemManager.GetItemIcon(XEnumConst.Rift.Currency)

    if self._Control:IsPluginRandomAffixUnlock(pluginId, index) then
        self:ShowResetAffix()
    else
        self:ShowUnlockAffix()
    end
end

function XUiRiftPopupAffix:OnDestroy()

end

function XUiRiftPopupAffix:GetAffixConfig()
    local affix = self._Control:GetPluginRandomAffixByIdx(self._PluginId, self._Index)
    if affix then
        return self._Control:GetRandomAffixById(affix)
    end
    return nil
end

function XUiRiftPopupAffix:ShowUnlockAffix()
    local lock = self._Control:GetLockRandomAffixCount(self._PluginId)
    self._OneUnlockCost = self._Plugin.AffixUnlockCost
    self._AllUnlockCost = lock * self._Plugin.AffixUnlockCost

    self.PanelUnlock.gameObject:SetActiveEx(true)
    self.PanelResetting.gameObject:SetActiveEx(false)
    self.GridAffix.gameObject:SetActiveEx(false)
    self.GridNewAffix.gameObject:SetActiveEx(false)
    self.ImgIconJianTou.gameObject:SetActiveEx(false)
    self.BtnUnlockAllCost:SetRawImage(self._ItemIcon)
    self.BtnUnlockAllCost:SetNameByGroup(0, self._AllUnlockCost)
    self.BtnUnlockAllCost:SetButtonState(self._ItemCount >= self._AllUnlockCost and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnUnlockCost:SetRawImage(self._ItemIcon)
    self.BtnUnlockCost:SetNameByGroup(0, self._OneUnlockCost)
    self.BtnUnlockCost:SetButtonState(self._ItemCount >= self._OneUnlockCost and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiRiftPopupAffix:ShowResetAffix()
    self._OneResetCost = self._Plugin.AffixResetCost

    self.PanelUnlock.gameObject:SetActiveEx(false)
    self.PanelResetting.gameObject:SetActiveEx(true)
    self.GridAffix.gameObject:SetActiveEx(true)
    self.GridNewAffix.gameObject:SetActiveEx(false)
    self.BtnSave.gameObject:SetActiveEx(false)
    self.ImgIconJianTou.gameObject:SetActiveEx(true)
    self.BtnResettingCost:SetRawImage(self._ItemIcon)
    self.BtnResettingCost:SetNameByGroup(0, self._OneResetCost)
    self.BtnResettingCost:SetButtonState(self._ItemCount >= self._OneResetCost and CS.UiButtonState.Normal or CS.UiButtonState.Disable)

    local isMax = self._Control:IsRandomAffixMaxLevel(self._PluginId, self._Index)
    self.TxtMax.gameObject:SetActiveEx(isMax)

    local cfg = self:GetAffixConfig()
    self:SetUiSprite(self.ImgAffix, cfg.Icon)
    self.TxtAffixName.text = cfg.Desc[1]

    if isMax then
        local color = self._Control:GetMaxLevelPluginAffixColor()
        self.TxtAffixNum.text = string.format("<color=%s>+%s</color>", color, cfg.Desc[2])
    else
        self.TxtAffixNum.text = string.format("+%s", cfg.Desc[2])
    end
end

function XUiRiftPopupAffix:ShowSureResetAffix(newAffixId)
    self.GridNewAffix.gameObject:SetActiveEx(true)
    self.BtnSave.gameObject:SetActiveEx(true)

    local isMax = self._Control:IsRandomAffixMaxLevelById(newAffixId)
    self.TxtNewMax.gameObject:SetActiveEx(isMax)

    local cfg = self._Control:GetRandomAffixById(newAffixId)
    self:SetUiSprite(self.ImgNewAffix, cfg.Icon)
    self.TxtNewAffixName.text = cfg.Desc[1]

    if isMax then
        local color = self._Control:GetMaxLevelPluginAffixColor()
        self.TxtNewAffixNum.text = string.format("<color=%s>+%s</color>", color, cfg.Desc[2])
    else
        self.TxtNewAffixNum.text = string.format("+%s", cfg.Desc[2])
    end
end

function XUiRiftPopupAffix:OnBtnResettingClick()
    if self._ItemCount < self._OneResetCost then
        XUiManager.TipError(XUiHelper.GetText("RiftPluginAttrReset"))
        return
    end
    self._Control:RequestRiftResetAffix(self._PluginId, self._Index, function(newAffixId)
        self:ShowSureResetAffix(newAffixId)
    end)
end

function XUiRiftPopupAffix:OnBtnSaveClick()
    self._Control:RequestRiftConfirmResetAffix()
    self:Close()
end

function XUiRiftPopupAffix:OnBtnUnlockAllClick()
    if self._ItemCount < self._AllUnlockCost then
        XUiManager.TipError(XUiHelper.GetText("RiftPluginAttrUnlock"))
        return
    end
    self._Control:RequestRiftActiveAffix(2, self._PluginId, nil, function()
        if self._UnlockCallBack then
            self._UnlockCallBack(2)
        end
    end)
    self:Close()
end

function XUiRiftPopupAffix:OnBtnUnlockClick()
    if self._ItemCount < self._OneUnlockCost then
        XUiManager.TipError(XUiHelper.GetText("RiftPluginAttrUnlock"))
        return
    end
    -- 按顺序解锁
    local unlockCount = self._Control:GetUnlockRandomAffixCount(self._PluginId)
    self._Control:RequestRiftActiveAffix(1, self._PluginId, unlockCount + 1, function()
        if self._UnlockCallBack then
            self._UnlockCallBack(1, unlockCount + 1)
        end
    end)
    self:Close()
end

function XUiRiftPopupAffix:OnClickItem()
    XLuaUiManager.Open("UiTip", { TemplateId = XEnumConst.Rift.Currency, Count = self._ItemCount })
end

return XUiRiftPopupAffix