XUiPanelOtherSet = XClass(nil, "XUiPanelOtherSet")
local XUiSafeAreaAdapter = CS.XUiSafeAreaAdapter
local SetConfigs = XSetConfigs
local MaxOff

function XUiPanelOtherSet:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    MaxOff = CS.XGame.ClientConfig:GetFloat("SpecialScreenOff")
    XTool.InitUiObject(self)
    self:InitUi()
end

function XUiPanelOtherSet:InitUi()
    self.TabObs = {}
    self.TabObs[1] = self.TogGraphics_0
    self.TabObs[2] = self.TogGraphics_1
    self.TabObs[3] = self.TogGraphics_2
    self.TabObs[4] = self.TogGraphics_3
    self.TGroupResolution:Init(
        self.TabObs,
        function(tab)
            self:TabSkip(tab)
        end
    )

    local focusTypes = {}
    focusTypes[1] = self.TogFocusType1
    focusTypes[2] = self.TogFocusType2
    self.TGroupFocusType:Init(
        focusTypes,
        function(index)
            self:OnFocusTypeChanged(index)
        end
    )

    self.TxtFocusType1.text = CsXTextManagerGetText("FocusType1")
    self.TxtFocusType2.text = CsXTextManagerGetText("FocusType2")

    local weaponTransTypes = {}
    weaponTransTypes[1] = self.TogWeaponTransType1
    weaponTransTypes[2] = self.TogWeaponTransType2
    self.TGroupWeaponTransType:Init(
        weaponTransTypes,
        function(index)
            self:OnWeaponTransTypeChanged(index)
        end
    )

    self.TxtWeaponTransType1.text = CsXTextManagerGetText("WeaponTransType1")
    self.TxtWeaponTransType2.text = CsXTextManagerGetText("WeaponTransType2")

    local rechargeTypes = {}
    rechargeTypes[1] = self.TogRechargeType1
    rechargeTypes[2] = self.TogRechargeType2
    self.TGroupRechargeType:Init(
        rechargeTypes,
        function(index)
            self:OnRechargeTypeChanged(index)
        end
    )

    self.TxtRechargeType1.text = CsXTextManagerGetText("RechargeType1")
    self.TxtRechargeType2.text = CsXTextManagerGetText("RechargeType2")

    self:AddListener()
    self:ShowAgreement()
end

function XUiPanelOtherSet:AddListener()
    self.OnSliderValueCb = function(value)
        self:OnSliderValueChanged(value)
    end
    self.OnTogFriEffectsValueCb = function(value)
        self:OnTogFriEffectsValueChanged(value)
    end
    self.OnTogFriNumValueCb = function(value)
        self:OnTogFriNumValueChanged(value)
    end
    self.TogFocusButtonCb = function(value)
        self:OnTogFocusButtonChanged(value)
    end
    self.TogOnlineInviteCb = function(value)
        self:OnTogOnlineButtonChanged(value)
    end
    self.Slider.onValueChanged:AddListener(self.OnSliderValueCb)
    self.TogFriEffects.onValueChanged:AddListener(self.OnTogFriEffectsValueCb)
    self.TogFriNum.onValueChanged:AddListener(self.OnTogFriNumValueCb)
    self.TogFocusButton.onValueChanged:AddListener(self.TogFocusButtonCb)
    self.TogOnlineInvite.onValueChanged:AddListener(self.TogOnlineInviteCb)
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
    self.SelfNumState = XSaveTool.GetData(SetConfigs.SelfNum) or SetConfigs.SelfNumEnum.Middle
    self.FriendNumState = XSaveTool.GetData(SetConfigs.FriendNum) or SetConfigs.FriendNumEnum.Close
    self.FriendEffectEnumState = XSaveTool.GetData(SetConfigs.FriendEffect) or SetConfigs.FriendEffectEnum.Open
    self.ScreenOffValue = XSaveTool.GetData(XSetConfigs.ScreenOff) or 0
    self.TGroupResolution:SelectIndex(self.SelfNumState)
    self.TogFriEffects.isOn = self.FriendEffectEnumState == SetConfigs.FriendNumEnum.Open
    self.TogFriNum.isOn = self.FriendNumState == SetConfigs.FriendNumEnum.Open
    local v = tonumber(self.ScreenOffValue)
    self.IsFirstSlider = true
    self.Slider.value = v
    self.SaveSelfNumState = self.SelfNumState
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

function XUiPanelOtherSet:TabSkip(tab)
    self.CurSelfNumKey = SetConfigs.SelfNumKeyIndexConfig[tab]
    self.SelfNumState = tab
    if self.IsPassTab then
        self.IsPassTab = false
        return
    end
end

function XUiPanelOtherSet:ResetToDefault()
    self.SelfNumState = SetConfigs.SelfNumEnum.Middle
    self.FriendNumState = SetConfigs.FriendNumEnum.Close
    self.FriendEffectEnumState = SetConfigs.FriendEffectEnum.Open
    self.TogFriEffects.isOn = self.FriendEffectEnumState == SetConfigs.FriendNumEnum.Open
    self.TogFriNum.isOn = self.FriendNumState == SetConfigs.FriendNumEnum.Open
    self.IsPassTab = true
    self.TGroupResolution:SelectIndex(self.SelfNumState)
    self.ScreenOffValue = 0
    self.Slider.value = 0
    self.FocusType = SetConfigs.DefaultFocusType
    self.TGroupFocusType:SelectIndex(self.FocusType)
    self.FocusButton = SetConfigs.DefaultFocusButton
    self.TogFocusButton.isOn = self.FocusButton == 1
    self.InviteButton = SetConfigs.DefaultInviteButton
    self.TogOnlineInvite.isOn = self.InviteButton == 1
    self.WeaponTransType = SetConfigs.DefaultWeaponTransType
    self.TGroupWeaponTransType:SelectIndex(self.WeaponTransType)
end

function XUiPanelOtherSet:SaveChange()
    self.SaveSelfNumState = self.SelfNumState
    self.SaveFriendNumState = self.FriendNumState
    self.SaveFriendEffectEnumState = self.FriendEffectEnumState
    self.SaveScreenOffValue = self.ScreenOffValue

    XDataCenter.SetManager.SaveSelfNum(self.SelfNumState)
    XDataCenter.SetManager.SaveFriendNum(self.FriendNumState)
    XDataCenter.SetManager.SaveFriendEffect(self.FriendEffectEnumState)
    XDataCenter.SetManager.SaveScreenOff(self.ScreenOffValue)

    XDataCenter.SetManager.SetOwnFontSizeByTab(self.SelfNumState)
    XDataCenter.SetManager.SetAllyDamage(self.FriendNumState == SetConfigs.FriendNumEnum.Open)
    XDataCenter.SetManager.SetAllyEffect(self.FriendEffectEnumState == SetConfigs.FriendEffectEnum.Open)

    XDataCenter.SetManager.SetFocusType(self.FocusType)
    XDataCenter.SetManager.SetFocusButtonActive(self.FocusButton == 1)
    XDataCenter.SetManager.SetInviteButtonActive(self.InviteButton == 1)
    XDataCenter.SetManager.SetWeaponTransType(self.WeaponTransType)
    XDataCenter.SetManager.SetRechargeType(self.RechargeType)
end

function XUiPanelOtherSet:CheckDataIsChange()
    return self.SaveSelfNumState ~= self.SelfNumState or self.SaveFriendNumState ~= self.FriendNumState or
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
    if value < 0 then
        return
    end

    if self.IsFirstSlider then
        self.IsFirstSlider = false
        return
    end
    self.ScreenOffValue = value
    self:SetSliderValueChanged(value)
    XDataCenter.SetManager.SetAdaptorScreenChange()
end

function XUiPanelOtherSet:SetSliderValueChanged(value)
    local v = tonumber(value)
    XUiSafeAreaAdapter.SetSpecialScreenOff(v * MaxOff)
    if self.Parent then
        self.Parent:UpdateSpecialScreenOff()
    end
end

function XUiPanelOtherSet:OnTogFriEffectsValueChanged(value)
    local v = SetConfigs.FriendEffectEnum.Close
    if value then
        v = SetConfigs.FriendEffectEnum.Open
    end
    self.FriendEffectEnumState = v
end

function XUiPanelOtherSet:OnTogFriNumValueChanged(value)
    local v = SetConfigs.FriendNumEnum.Close
    if value then
        v = SetConfigs.FriendNumEnum.Open
    end
    self.FriendNumState = v
end

function XUiPanelOtherSet:OnTogFocusButtonChanged(value)
    self.FocusButton = value and 1 or 0
end

function XUiPanelOtherSet:OnTogOnlineButtonChanged(value)
    self.InviteButton = value and 1 or 0
end

function XUiPanelOtherSet:OnFocusTypeChanged(index)
    if index == 0 then
        return
    end
    self.FocusType = index
    self.DescriptionFocusType1.gameObject:SetActiveEx(index == 1)
    self.DescriptionFocusType2.gameObject:SetActiveEx(index == 2)
    self.TogFocusButton.gameObject:SetActiveEx(index == 2)
end

function XUiPanelOtherSet:OnWeaponTransTypeChanged(index)
    if index == 0 then
        return
    end
    self.WeaponTransType = index
    self.DescriptionWeaponTransType1.gameObject:SetActiveEx(index == 1)
    self.DescriptionWeaponTransType2.gameObject:SetActiveEx(index == 2)
end

function XUiPanelOtherSet:OnRechargeTypeChanged(index)
    if index == 0 then
        return
    end
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