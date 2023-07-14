XUiPanelOtherSet = XClass(nil, "XUiPanelOtherSet")
local XUiSafeAreaAdapter = CS.XUiSafeAreaAdapter

function XUiPanelOtherSet:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent

    XTool.InitUiObject(self)
    self:InitUi()

    self.MaxOff = CS.XGame.ClientConfig:GetFloat("SpecialScreenOff")
    self.SetConfigs = XSetConfigs
end

function XUiPanelOtherSet:InitUi()
    if CS.XFight.Instance or XUiManager.IsHideFunc then
        self.LoadingSet.gameObject:SetActiveEx(false)
    end

    local loadingTypes = {self.TogLoadingType1, self.TogLoadingType2}
    self.TGroupLoadingType:Init(loadingTypes, handler(self, self.OnLoadingTypeChanged))

    local damageNumSizeTypes = {self.TogGraphics_0, self.TogGraphics_1, self.TogGraphics_2, self.TogGraphics_3}
    self.TGroupResolution:Init(damageNumSizeTypes, handler(self, self.OnDamageNumSizeTypeChanged))

    local focusTypes = {self.TogFocusType1, self.TogFocusType2}
    self.TGroupFocusType:Init(focusTypes, handler(self, self.OnFocusTypeChanged))

    self.TxtFocusType1.text = CsXTextManagerGetText("FocusType1")
    self.TxtFocusType2.text = CsXTextManagerGetText("FocusType2")

    local weaponTransTypes = {self.TogWeaponTransType1, self.TogWeaponTransType2}
    self.TGroupWeaponTransType:Init(weaponTransTypes, handler(self, self.OnWeaponTransTypeChanged))

    self.TxtWeaponTransType1.text = CsXTextManagerGetText("WeaponTransType1")
    self.TxtWeaponTransType2.text = CsXTextManagerGetText("WeaponTransType2")

    local rechargeTypes = {self.TogRechargeType1, self.TogRechargeType2}
    self.TGroupRechargeType:Init(rechargeTypes, handler(self, self.OnRechargeTypeChanged))

    self.TxtRechargeType1.text = CsXTextManagerGetText("RechargeType1")
    self.TxtRechargeType2.text = CsXTextManagerGetText("RechargeType2")

    self:AddListener()
    self:ShowAgreement()
end

function XUiPanelOtherSet:AddListener()
    self.Slider.onValueChanged:AddListener(handler(self, self.OnSliderValueChanged))
    self.TogFriEffects.onValueChanged:AddListener(handler(self, self.OnTogFriEffectsValueChanged))
    self.TogFriNum.onValueChanged:AddListener(handler(self, self.OnTogFriNumValueChanged))
    self.TogFocusButton.onValueChanged:AddListener(handler(self, self.OnTogFocusButtonChanged))
    self.TogOnlineInvite.onValueChanged:AddListener(handler(self, self.OnTogOnlineButtonChanged))
    self.BtnLoadingSet.CallBack = function()
        XLuaUiManager.Open("UiLoadingSet")
    end
end

function XUiPanelOtherSet:ShowAgreement()
    self.BtnUserAgreement.CallBack = function()
        XUiManager.OpenPopWebview(CS.XGame.ClientConfig:GetString("UserAgreementUrl"))
    end
    self.BtnPrivacyPolicy.CallBack = function()
        XUiManager.OpenPopWebview(CS.XGame.ClientConfig:GetString("PrivacyPolicyUrl"))
    end
end

function XUiPanelOtherSet:GetCache()
    self.CustomLoadState = XDataCenter.LoadingManager.GetCustomLoadingState()
    self.DamageNumState = XSaveTool.GetData(self.SetConfigs.SelfNum) or self.SetConfigs.DamageNumSize.Middle
    self.FriendNumState = XSaveTool.GetData(self.SetConfigs.FriendNum) or self.SetConfigs.FriendNumEnum.Close
    self.FriendEffectEnumState = XSaveTool.GetData(self.SetConfigs.FriendEffect) or self.SetConfigs.FriendEffectEnum.Open
    self.ScreenOffValue = XSaveTool.GetData(self.SetConfigs.ScreenOff) or 0

    self.TGroupLoadingType:SelectIndex(self.CustomLoadState, true)
    self.TGroupResolution:SelectIndex(self.DamageNumState)
    self.TogFriEffects.isOn = self.FriendEffectEnumState == self.SetConfigs.FriendNumEnum.Open
    self.TogFriNum.isOn = self.FriendNumState == self.SetConfigs.FriendNumEnum.Open
    self.IsFirstSlider = true
    self.Slider.value = tonumber(self.ScreenOffValue)
    self.SaveCustomLoadState = self.CustomLoadState
    self.SaveDamageNumState = self.DamageNumState
    self.SaveFriendNumState = self.FriendNumState
    self.SaveFriendEffectEnumState = self.FriendEffectEnumState
    self.SaveScreenOffValue = self.ScreenOffValue
    self.FocusType = XDataCenter.SetManager.FocusType
    self.TGroupFocusType:SelectIndex(self.FocusType)
    self.FocusButton = XDataCenter.SetManager.FocusButton
    self.InviteButton = XDataCenter.SetManager.InviteButton
    self.TogFocusButton.isOn = self.FocusButton == 1
    self.TogOnlineInvite.isOn = self.InviteButton == 1
    self.WeaponTransType = XDataCenter.SetManager.WeaponTransType
    self.TGroupWeaponTransType:SelectIndex(self.WeaponTransType)
    self.RechargeType = XDataCenter.SetManager.RechargeType
    self.TGroupRechargeType:SelectIndex(self.RechargeType)
end

function XUiPanelOtherSet:ResetToDefault()
    self.CustomLoadState = XSetConfigs.LoadingType.Default
    self.DamageNumState = self.SetConfigs.DamageNumSize.Middle
    self.FriendNumState = self.SetConfigs.FriendNumEnum.Close
    self.FriendEffectEnumState = self.SetConfigs.FriendEffectEnum.Open
    self.TogFriEffects.isOn = self.FriendEffectEnumState == self.SetConfigs.FriendNumEnum.Open
    self.TogFriNum.isOn = self.FriendNumState == self.SetConfigs.FriendNumEnum.Open

    self.TGroupLoadingType:SelectIndex(self.CustomLoadState, true)
    self.TGroupResolution:SelectIndex(self.DamageNumState)
    self.ScreenOffValue = 0
    self.Slider.value = 0
    self.FocusType = self.SetConfigs.DefaultFocusType
    self.TGroupFocusType:SelectIndex(self.FocusType)
    self.FocusButton = self.SetConfigs.DefaultFocusButton
    self.TogFocusButton.isOn = self.FocusButton == 1
    self.InviteButton = self.SetConfigs.DefaultInviteButton
    self.TogOnlineInvite.isOn = self.InviteButton == 1
    self.WeaponTransType = self.SetConfigs.DefaultWeaponTransType
    self.TGroupWeaponTransType:SelectIndex(self.WeaponTransType)
end

function XUiPanelOtherSet:SaveChange()
    self.SaveCustomLoadState = self.CustomLoadState
    self.SaveDamageNumState = self.DamageNumState
    self.SaveFriendNumState = self.FriendNumState
    self.SaveFriendEffectEnumState = self.FriendEffectEnumState
    self.SaveScreenOffValue = self.ScreenOffValue

    XDataCenter.LoadingManager.SetCustomLoadingState(self.CustomLoadState)
    XDataCenter.SetManager.SaveSelfNum(self.DamageNumState)
    XDataCenter.SetManager.SaveFriendNum(self.FriendNumState)
    XDataCenter.SetManager.SaveFriendEffect(self.FriendEffectEnumState)
    XDataCenter.SetManager.SaveScreenOff(self.ScreenOffValue)

    XDataCenter.SetManager.SetOwnFontSizeByTab(self.DamageNumState)
    XDataCenter.SetManager.SetAllyDamage(self.FriendNumState == self.SetConfigs.FriendNumEnum.Open)
    XDataCenter.SetManager.SetAllyEffect(self.FriendEffectEnumState == self.SetConfigs.FriendEffectEnum.Open)

    XDataCenter.SetManager.SetFocusType(self.FocusType)
    XDataCenter.SetManager.SetFocusButtonActive(self.FocusButton == 1)
    XDataCenter.SetManager.SetInviteButtonActive(self.InviteButton == 1)
    XDataCenter.SetManager.SetWeaponTransType(self.WeaponTransType)
    XDataCenter.SetManager.SetRechargeType(self.RechargeType)
end

function XUiPanelOtherSet:CheckDataIsChange()
    return
            self.SaveCustomLoadState ~= self.CustomLoadState or
            self.SaveDamageNumState ~= self.DamageNumState or
            self.SaveFriendNumState ~= self.FriendNumState or
            self.SaveFriendEffectEnumState ~= self.FriendEffectEnumState or
            self.SaveScreenOffValue ~= self.ScreenOffValue or
            self.FocusType ~= XDataCenter.SetManager.FocusType or
            self.FocusButton ~=XDataCenter.SetManager.FocusButton or
            self.InviteButton ~=XDataCenter.SetManager.InviteButton or
            self.WeaponTransType ~= XDataCenter.SetManager.WeaponTransType
end

function XUiPanelOtherSet:CancelChange()
    self.ScreenOffValue = self.SaveScreenOffValue
    self:SetSliderValueChanged(self.SaveScreenOffValue)
end

function XUiPanelOtherSet:OnSliderValueChanged(value)
    if value < 0 then return end
    if self.IsFirstSlider then
        self.IsFirstSlider = false
        return
    end
    self.ScreenOffValue = value
    self:SetSliderValueChanged(value)
    XDataCenter.SetManager.SetAdaptorScreenChange()
end

function XUiPanelOtherSet:SetSliderValueChanged(value)
    XUiSafeAreaAdapter.SetSpecialScreenOff(tonumber(value) * self.MaxOff)
    if self.Parent then
        self.Parent:UpdateSpecialScreenOff()
    end
end

function XUiPanelOtherSet:OnTogFriEffectsValueChanged(value)
    local enum = self.SetConfigs.FriendEffectEnum
    self.FriendEffectEnumState = value and enum.Open or enum.Close
end

function XUiPanelOtherSet:OnTogFriNumValueChanged(value)
    local enum = self.SetConfigs.FriendNumEnum
    self.FriendNumState = value and enum.Open or enum.Close
end

function XUiPanelOtherSet:OnTogFocusButtonChanged(value)
    self.FocusButton = value and 1 or 0
end

function XUiPanelOtherSet:OnTogOnlineButtonChanged(value)
    self.InviteButton = value and 1 or 0
end

function XUiPanelOtherSet:OnLoadingTypeChanged(index)
    if index == self.SetConfigs.LoadingType.Custom
            and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Archive) then
        self.TGroupLoadingType:SelectIndex(self.SetConfigs.LoadingType.Default)
        return
    end
    self.CustomLoadState = index
    self.DescriptionLoadingType1.gameObject:SetActiveEx(index == 1)
    self.DescriptionLoadingType2.gameObject:SetActiveEx(index == 2)
    self.BtnLoadingSet.gameObject:SetActiveEx(index == 2)
end

function XUiPanelOtherSet:OnDamageNumSizeTypeChanged(index)
    self.CurSelfNumKey = self.SetConfigs.SelfNumKeyIndexConfig[index]
    self.DamageNumState = index
end

function XUiPanelOtherSet:OnFocusTypeChanged(index)
    if index == 0 then return end
    self.FocusType = index
    self.DescriptionFocusType1.gameObject:SetActiveEx(index == 1)
    self.DescriptionFocusType2.gameObject:SetActiveEx(index == 2)
    self.TogFocusButton.gameObject:SetActiveEx(index == 2)
end

function XUiPanelOtherSet:OnWeaponTransTypeChanged(index)
    if index == 0 then return end
    self.WeaponTransType = index
    self.DescriptionWeaponTransType1.gameObject:SetActiveEx(index == 1)
    self.DescriptionWeaponTransType2.gameObject:SetActiveEx(index == 2)
end

function XUiPanelOtherSet:OnRechargeTypeChanged(index)
    if index == 0 then return end
    self.RechargeType = index
    self.DescriptionRechargeType1.gameObject:SetActiveEx(index == 1)
    self.DescriptionRechargeType2.gameObject:SetActiveEx(index == 2)
end

function XUiPanelOtherSet:ShowPanel()
    self.GameObject:SetActive(true)
    if self.Parent then
        self.Adaptation.gameObject:SetActiveEx(not self.Parent.IsFight)
    end
    self:GetCache()
    self.IsShow = true
end

function XUiPanelOtherSet:HidePanel()
    self.IsShow = false
    self.GameObject:SetActive(false)
end

return XUiPanelOtherSet