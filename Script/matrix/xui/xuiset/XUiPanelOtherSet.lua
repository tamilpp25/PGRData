---@class XUiPanelOtherSet : XUiNode
local XUiPanelOtherSet = XClass(XUiNode, "XUiPanelOtherSet")
local XUiSafeAreaAdapter = CS.XUiSafeAreaAdapter

function XUiPanelOtherSet:OnStart()
    self:InitUi()

    self.MaxOff = CS.XGame.ClientConfig:GetFloat("SpecialScreenOff")
    self.SetConfigs = XSetConfigs
    self._IsInitFocusTypeDlcHunt = false
end

function XUiPanelOtherSet:OnEnable()
    self:ShowPanel()
end

function XUiPanelOtherSet:OnDisable()
    self:HidePanel()
end

function XUiPanelOtherSet:InitUi()
    if CS.XFight.Instance or XUiManager.IsHideFunc then
        self.LoadingSet.gameObject:SetActiveEx(false)
    end

    local loadingTypes = {self.TogLoadingType1, self.TogLoadingType2}
    self.TGroupLoadingType:Init(loadingTypes, handler(self, self.OnLoadingTypeChanged))

    local damageNumSizeTypes = {self.TogGraphics_0, self.TogGraphics_1, self.TogGraphics_2, self.TogGraphics_3}
    self.TGroupResolution:Init(damageNumSizeTypes, handler(self, self.OnDamageNumSizeTypeChanged))

    --region focus
    local focusTypes = {self.TogFocusType1, self.TogFocusType2, self.TogFocusType3}
    self.TGroupFocusType:Init(focusTypes, handler(self, self.OnFocusTypeChanged))

    for _, focusType in pairs(XSetConfigs.FocusType) do
        local index = self:GetFocusIndex(focusType)
        if self["TxtFocusType"..index] then
            self["TxtFocusType"..index].text = CsXTextManagerGetText("FocusType" .. focusType)
        end
    end
    if self.TogFocusButton1 then
        self.TogFocusButton1.gameObject:SetActiveEx(false)
    end
    --endregion focus

    --region focus dlcHunt
    if self.TGroupFocusTypeDlcHunt then
        local focusTypesDlcHunt = {self.TogTypeDlcHunt1, self.TogTypeDlcHunt2, self.TogTypeDlcHunt3}
        self.TGroupFocusTypeDlcHunt:Init(focusTypesDlcHunt, handler(self, self.OnFocusTypeDlcHuntChanged))
        for _, focusType in pairs(XSetConfigs.FocusTypeDlcHunt) do
            local index = self:GetFocusIndex(focusType)
            if self["TxtFocusTypeDlcHunt"..index] then
                self["TxtFocusTypeDlcHunt"..index].text = CsXTextManagerGetText("FocusTypeDlcHunt" .. focusType)
            end
        end
        --self.TogFocusDlcHuntButton1.gameObject:SetActiveEx(false)
        if self.TogFocusDlcHuntButton3 then
            self.TogFocusDlcHuntButton3.gameObject:SetActiveEx(false)
        end
    end

    if not XDataCenter.DlcHuntManager.IsOpen() and self.DlcHuntFocus then
        self.DlcHuntFocus.gameObject:SetActiveEx(false)
    end
    --endregion focus dlcHunt
    
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
    --region focus
    if self.TogFocusButton2 then
        self.TogFocusButton2.onValueChanged:AddListener(handler(self, self.OnTogFocusButtonChanged2))
    end
    if self.TogFocusButton3 then
        self.TogFocusButton3.onValueChanged:AddListener(handler(self, self.OnTogFocusButtonChanged3))
    end
    --endregion focus
    
    --region focus dlcHunt
    if self.TogFocusDlcHuntButton1 then
        self.TogFocusDlcHuntButton1.onValueChanged:AddListener(handler(self, self.OnTogFocusDlcHuntButtonChanged1))
        self.TogFocusDlcHuntButton2.onValueChanged:AddListener(handler(self, self.OnTogFocusDlcHuntButtonChanged2))
        self.TogFocusDlcHuntButton3.onValueChanged:AddListener(handler(self, self.OnTogFocusDlcHuntButtonChanged3))
    end
    --endregion focus dlcHunt
    self.TogOnlineInvite.onValueChanged:AddListener(handler(self, self.OnTogOnlineButtonChanged))
    self.BtnLoadingSet.CallBack = function()
        XLuaUiManager.Open("UiLoadingSet")
    end
end

function XUiPanelOtherSet:ShowAgreement()
    local protocolData = {}
    
    if not XDataCenter.UiPcManager.IsPc() then
        if self.BtnProtocolSetting then 
            self.BtnProtocolSetting.gameObject:SetActiveEx(false)
        end
        if XUserManager.IsHeroSdk() and CS.XHeroSdkAgent.GetProtocolData then
            protocolData = CS.XHeroSdkAgent.GetProtocolData() or {}
        end

        if protocolData.userAgrUrl and protocolData.userAgrName then
            self.BtnPrivacyPolicy:SetNameByGroup(0, protocolData.userAgrName)
            self.BtnUserAgreement.CallBack = function()
                XUiManager.OpenPopWebview(protocolData.userAgrUrl, protocolData.userAgrName)
            end
        else
            self.BtnUserAgreement.CallBack = function()
                XUiManager.OpenPopWebview(CS.XGame.ClientConfig:GetString("UserAgreementUrl"))
            end
        end
        
        if protocolData.priAgrUrl and protocolData.priAgrName then
            self.BtnPrivacyPolicy:SetNameByGroup(0, protocolData.priAgrName)
            self.BtnPrivacyPolicy.CallBack = function()
                XUiManager.OpenPopWebview(protocolData.priAgrUrl, protocolData.priAgrName)
            end
        else
            self.BtnPrivacyPolicy.CallBack = function()
                XUiManager.OpenPopWebview(CS.XGame.ClientConfig:GetString("PrivacyPolicyUrl"))
            end
        end
    
        if protocolData.childAgrUrl and protocolData.childAgrName then
            local prefab = CS.UnityEngine.Object.Instantiate(self.BtnUserAgreement.gameObject)
            prefab.transform:SetParent(self.PanelAgreement, false)
            local btn = prefab.transform:GetComponent("XUiButton")
    
            btn:SetNameByGroup(0, protocolData.childAgrName)
            btn.CallBack = function()
                XUiManager.OpenPopWebview(protocolData.childAgrUrl, protocolData.childAgrName)
            end
        end
    
        if protocolData.sdkAgrUrl and protocolData.sdkAgrName then
            local prefab = CS.UnityEngine.Object.Instantiate(self.BtnUserAgreement.gameObject)
            prefab.transform:SetParent(self.PanelAgreement, false)
            local btn = prefab.transform:GetComponent("XUiButton")
    
            btn:SetNameByGroup(0, protocolData.sdkAgrName)
            btn.CallBack = function()
                XUiManager.OpenPopWebview(protocolData.sdkAgrUrl, protocolData.sdkAgrName)
            end
        end
    end

    -- KuroSDK 隐私条款与设置
    if self.BtnProtocolSetting then
        self.BtnProtocolSetting.gameObject:SetActiveEx(true)
        self.BtnProtocolSetting:SetNameByGroup(0, CsXTextManagerGetText("UserAgreeSetting"))
        self.BtnProtocolSetting.CallBack = function()
            CS.XHeroSdkAgent.ShowProtocolSetting()
        end
    end

    -- KuroSDK 账号中心 PC暂时没有 判断函数是否存在是为了兼容线上平行包
    if self.BtnUserCenter then 
        local channelId = CS.XHeroSdkAgent.GetChannelId()
        --国服官服渠道18、56 只有安卓母包跟iOS开放
        if (channelId == 18 or channelId == 56) and not XDataCenter.UiPcManager.IsPc() and CS.XHeroSdkAgent.ShowUserCenter then          
            self.BtnUserCenter.gameObject:SetActiveEx(true)
            self.BtnUserCenter:SetNameByGroup(0, CsXTextManagerGetText("UserCenterSetting"))
            self.BtnUserCenter.CallBack = function()
                CS.XHeroSdkAgent.ShowUserCenter()
            end
        else 
            self.BtnUserCenter.gameObject:SetActiveEx(false)
        end
    end
    
    self.BtnPrivacyPolicy.gameObject:SetActiveEx(false)
    self.BtnUserAgreement.gameObject:SetActiveEx(false)
    
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
    --region focus
    self.FocusType = XDataCenter.SetManager.FocusType
    self.FocusButton = XTool.Clone(XDataCenter.SetManager.FocusButton)
    self.TGroupFocusType:SelectIndex(self:GetFocusIndex(self.FocusType))
    self:UpdateUiFocusButton()
    --endregion focus
    --region focus dlcHunt
    self.FocusTypeDlcHunt = XDataCenter.SetManager.FocusTypeDlcHunt
    self.FocusButtonDlcHunt = XTool.Clone(XDataCenter.SetManager.FocusButtonDlcHunt)
    self._IsInitFocusTypeDlcHunt = true
    if self.TGroupFocusTypeDlcHunt then
        self.TGroupFocusTypeDlcHunt:SelectIndex(self:GetFocusIndex(self.FocusTypeDlcHunt))
    end
    self._IsInitFocusTypeDlcHunt = false
    self:UpdateUiFocusButtonDlcHunt()
    --endregion focus dlcHunt
    self.InviteButton = XDataCenter.SetManager.InviteButton
    self.TogOnlineInvite.isOn = self.InviteButton == 1
    self.WeaponTransType = XDataCenter.SetManager.WeaponTransType
    if self.WeaponTransType <= self.TGroupWeaponTransType.TabBtnList.Count then
        self.TGroupWeaponTransType:SelectIndex(self.WeaponTransType)
    else
        self.TGroupWeaponTransType:SelectIndex(1)
    end
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
    --region focus
    self.FocusType = self.SetConfigs.DefaultFocusType
    self.TGroupFocusType:SelectIndex(self:GetFocusIndex(self.FocusType))
    self.FocusButton = {
        [XSetConfigs.FocusType.Manual] = self.SetConfigs.DefaultFocusButton,
        [XSetConfigs.FocusType.Auto] = self.SetConfigs.DefaultFocusButton,
        [XSetConfigs.FocusType.SemiAuto] = self.SetConfigs.DefaultFocusButton,
    }
    self:UpdateUiFocusButton()
    --endregion focus
    --region focus dlcHunt
    self.FocusTypeDlcHunt = self.SetConfigs.DefaultFocusTypeDlcHunt
    if self.TGroupFocusTypeDlcHunt then
        self.TGroupFocusTypeDlcHunt:SelectIndex(self:GetFocusIndexDlcHunt(self.FocusTypeDlcHunt))
        self.FocusButtonDlcHunt = {
            [XSetConfigs.FocusTypeDlcHunt.Manual] = self.SetConfigs.DefaultFocusButtonDlcHunt,
            [XSetConfigs.FocusTypeDlcHunt.Auto] = self.SetConfigs.DefaultFocusButtonDlcHunt,
            --[XSetConfigs.FocusTypeDlcHunt.SemiAuto] = self.SetConfigs.DefaultFocusButtonDlcHunt,
        }
        self:UpdateUiFocusButtonDlcHunt()
    end
    --endregion focus dlcHunt
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

    --region focus
    XDataCenter.SetManager.SetFocusType(self.FocusType)
    XDataCenter.SetManager.SetFocusButtonActive(XSetConfigs.FocusType.Manual, self.FocusButton[XSetConfigs.FocusType.Manual] == 1)
    XDataCenter.SetManager.SetFocusButtonActive(XSetConfigs.FocusType.SemiAuto, self.FocusButton[XSetConfigs.FocusType.SemiAuto] == 1)
    --endregion focus
    --region focus dlcHunt
    XDataCenter.SetManager.SetFocusTypeDlcHunt(self.FocusTypeDlcHunt)
    XDataCenter.SetManager.SetFocusButtonActiveDlcHunt(XSetConfigs.FocusTypeDlcHunt.Manual, self.FocusButtonDlcHunt[XSetConfigs.FocusTypeDlcHunt.Manual] == 1)
    XDataCenter.SetManager.SetFocusButtonActiveDlcHunt(XSetConfigs.FocusTypeDlcHunt.Auto, self.FocusButtonDlcHunt[XSetConfigs.FocusTypeDlcHunt.Auto] == 1)
    --endregion focus dlcHunt
    XDataCenter.SetManager.SetInviteButtonActive(self.InviteButton == 1)
    XDataCenter.SetManager.SetWeaponTransType(self.WeaponTransType)
    XDataCenter.SetManager.SetRechargeType(self.RechargeType)
    
    local dict = {}
    dict["screen_off_value"] = math.floor(self.ScreenOffValue * 100)
    dict["custom_load_state"] = self.CustomLoadState
    dict["damage_num_state"] = self.DamageNumState
    dict["friend_damage_state"] = self.FriendNumState == 2
    dict["friend_effect_state"] = self.FriendEffectEnumState == 2
    dict["focus_type"] = self.FocusType
    XDataCenter.SetManager.SystemSettingBuriedPoint(dict)
end

function XUiPanelOtherSet:CheckDataIsChange()
    return
            self.SaveCustomLoadState ~= self.CustomLoadState or
            self.SaveDamageNumState ~= self.DamageNumState or
            self.SaveFriendNumState ~= self.FriendNumState or
            self.SaveFriendEffectEnumState ~= self.FriendEffectEnumState or
            self.SaveScreenOffValue ~= self.ScreenOffValue or
            --region focus
            self.FocusType ~= XDataCenter.SetManager.FocusType or
            self:IsFocusButtonChanged() or
            --endregion focus
            --region focus dlcHunt
            self.FocusTypeDlcHunt ~= XDataCenter.SetManager.FocusTypeDlcHunt or
            self:IsFocusButtonChangedDlcHunt() or
            --endregion focus dlcHunt
            self.InviteButton ~=XDataCenter.SetManager.InviteButton or
            self.WeaponTransType ~= XDataCenter.SetManager.WeaponTransType
end

function XUiPanelOtherSet:IsFocusButtonChanged()
    return self.FocusButton[XSetConfigs.FocusType.Manual] ~=XDataCenter.SetManager.FocusButton[XSetConfigs.FocusType.Manual] or
            self.FocusButton[XSetConfigs.FocusType.SemiAuto] ~=XDataCenter.SetManager.FocusButton[XSetConfigs.FocusType.SemiAuto]
end

function XUiPanelOtherSet:IsFocusButtonChangedDlcHunt()
    return self.FocusButtonDlcHunt[XSetConfigs.FocusTypeDlcHunt.Manual] ~=XDataCenter.SetManager.FocusButtonDlcHunt[XSetConfigs.FocusTypeDlcHunt.Manual] or
            self.FocusButtonDlcHunt[XSetConfigs.FocusTypeDlcHunt.Auto] ~=XDataCenter.SetManager.FocusButtonDlcHunt[XSetConfigs.FocusTypeDlcHunt.Auto]
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

function XUiPanelOtherSet:OnTogFocusButtonChanged2(value)
    self.FocusButton[self:GetFocusType(2)] = value and 1 or 0
end

function XUiPanelOtherSet:OnTogFocusButtonChanged3(value)
    self.FocusButton[self:GetFocusType(3)] = value and 1 or 0
end

function XUiPanelOtherSet:OnTogFocusDlcHuntButtonChanged1(value)
    self.FocusButtonDlcHunt[self:GetFocusTypeDlcHunt(1)] = value and 1 or 0
end

function XUiPanelOtherSet:OnTogFocusDlcHuntButtonChanged2(value)
    self.FocusButtonDlcHunt[self:GetFocusTypeDlcHunt(2)] = value and 1 or 0
end

function XUiPanelOtherSet:OnTogFocusDlcHuntButtonChanged3(value)
    self.FocusButtonDlcHunt[self:GetFocusTypeDlcHunt(3)] = value and 1 or 0
end

function XUiPanelOtherSet:OnTogOnlineButtonChanged(value)
    self.InviteButton = value and 1 or 0
end

function XUiPanelOtherSet:OnLoadingTypeChanged(index)
    if index == self.SetConfigs.LoadingType.Custom
            and (not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Archive, nil, true) 
            or not XMVCA.XSubPackage:CheckSubpackage()) then
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
    self.FocusType = self:GetFocusType(index)
    self.DescriptionFocusType1.gameObject:SetActiveEx(index == 1)
    self.DescriptionFocusType2.gameObject:SetActiveEx(index == 2)
    if self.DescriptionFocusType3 then
        self.DescriptionFocusType3.gameObject:SetActiveEx(index == 3)
    end
    if self.TogFocusButton2 then
        self.TogFocusButton2.gameObject:SetActiveEx(index == 2)
    end
    if self.TogFocusButton3 then
        self.TogFocusButton3.gameObject:SetActiveEx(index == 3)
    end
    self:UpdateUiFocusButton()
end

function XUiPanelOtherSet:OnFocusTypeDlcHuntChanged(index)
    if XDataCenter.DlcRoomManager.IsInTutorialWorld() then
        local teachingIndex = self:GetFocusIndexDlcHunt(XSetConfigs.FocusTypeDlcHunt.Auto)
        if teachingIndex ~= index then
            self.TGroupFocusTypeDlcHunt:SelectIndex(teachingIndex)
            if not self._IsInitFocusTypeDlcHunt then
                XUiManager.TipText("FocusTypeDlcHuntTeaching")
            end
        end
        return
    end
    if index == 0 then return end
    self.FocusTypeDlcHunt = self:GetFocusTypeDlcHunt(index)
    self.DescriptionFocusDlcHuntType1.gameObject:SetActiveEx(index == 1)
    self.DescriptionFocusDlcHuntType2.gameObject:SetActiveEx(index == 2)
    self.DescriptionFocusDlcHuntType3.gameObject:SetActiveEx(index == 3)
    self.TogFocusDlcHuntButton1.gameObject:SetActiveEx(false)--index == 1)
    self.TogFocusDlcHuntButton2.gameObject:SetActiveEx(index == 2)
    --self.TogFocusDlcHuntButton3.gameObject:SetActiveEx(index == 3)
    self:UpdateUiFocusButtonDlcHunt()
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
    if self.Parent then
        self.Adaptation.gameObject:SetActiveEx(not self.Parent.IsFight)
    end
    self:GetCache()
    self.IsShow = true
end

function XUiPanelOtherSet:HidePanel()
    self.IsShow = false
end

-- 由于ui位置上, 新增的半自动锁定插到了中间, 所以type2和type3的index是反的
function XUiPanelOtherSet:GetFocusType(focusIndex)
    if focusIndex == 2 then
        return 3
    end
    if focusIndex == 3 then
        return 2
    end
    return focusIndex
end

function XUiPanelOtherSet:GetFocusIndex(focusType)
    if focusType == 2 then
        return 3
    end
    if focusType == 3 then
        return 2
    end
    return focusType
end

function XUiPanelOtherSet:UpdateUiFocusButton()
    for _, focusType in pairs(XSetConfigs.FocusType) do
        local index = self:GetFocusIndex(focusType)
        if self["TogFocusButton"..index] then
            self["TogFocusButton"..index].isOn = self.FocusButton[focusType] == 1
        end
    end
end

-- 2不存在，dlc没有进阶锁定
function XUiPanelOtherSet:GetFocusTypeDlcHunt(focusIndex)
    if focusIndex == 2 then
        return 3
    end
    if focusIndex == 3 then
        return 2
    end
    return focusIndex
end

function XUiPanelOtherSet:GetFocusIndexDlcHunt(focusType)
    if focusType == 2 then
        return 3
    end
    if focusType == 3 then
        return 2
    end
    return focusType
end

function XUiPanelOtherSet:UpdateUiFocusButtonDlcHunt()
    for _, focusType in pairs(XSetConfigs.FocusTypeDlcHunt) do
        local index = self:GetFocusIndexDlcHunt(focusType)
        if self["TogFocusDlcHuntButton"..index] then
            self["TogFocusDlcHuntButton"..index].isOn = self.FocusButtonDlcHunt[focusType] == 1
        end
    end
end

return XUiPanelOtherSet