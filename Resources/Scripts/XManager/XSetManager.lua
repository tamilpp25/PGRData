XSetManagerCreator = function()
    local XSetManager = {}
    local SelfNumDefaultSize
    local MaxScreenOff
    local GlobalIllumination
    local SceneType
    XSetManager.DynamicJoystick = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.DynamicJoystick, XSetConfigs.DefaultDynamicJoystick)
    XSetManager.FocusType = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.FocusType, XSetConfigs.DefaultFocusType)
    XSetManager.FocusButton = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.FocusButton, XSetConfigs.DefaultFocusButton)
    XSetManager.InviteButton = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.InviteButton, XSetConfigs.DefaultInviteButton)
    XSetManager.WeaponTransType = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.WeaponTransType, XSetConfigs.DefaultWeaponTransType)
    XSetManager.RechargeType = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.RechargeType, XSetConfigs.DefaultRechargeType)
    
    function XSetManager.Init()
        GlobalIllumination = CS.XGlobalIllumination
        SceneType = CS.XSceneType
        SelfNumDefaultSize = CS.XGame.ClientConfig:GetInt("SelfNumDefault") or 0
        MaxScreenOff = CS.XGame.ClientConfig:GetFloat("SpecialScreenOff") or 0
        XSetManager.SetDynamicJoystick(XSetManager.DynamicJoystick)
        XSetManager.SetFocusType(XSetManager.FocusType)
        XSetManager.SetFocusButtonActive(XSetManager.FocusButton == 1)
        XSetManager.SetInviteButtonActive(XSetManager.InviteButton == 1)
        XSetManager.SetWeaponTransType(XSetManager.WeaponTransType)
        XSetManager.SetRechargeType(XSetManager.RechargeType)
        XEventManager.AddEventListener(XEventId.EVNET_FAIL_PAY, XSetManager.SetSceneUIType)
    end

    function XSetManager.SetDynamicJoystick(value)
        CS.XRLFightSettings.SetDynamicJoystick(value == 1)
        XSetManager.DynamicJoystick = value
    end

    function XSetManager.SetFocusType(type)
        if type == 0 then
            return
        end
        XSetManager.FocusType = type
        CS.XRLFightSettings.SetFocusType(type)
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.FocusType, type)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    function XSetManager.SetFocusButtonActive(value)
        CS.XRLFightSettings.SetFocusButtonActive(value)
        XSetManager.FocusButton = value and 1 or 0
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.FocusButton, XSetManager.FocusButton)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    function XSetManager.SetInviteButtonActive(value)
        XSetManager.InviteButton = value and 1 or 0
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.InviteButton, XSetManager.InviteButton)
        CS.UnityEngine.PlayerPrefs.Save()
        
        if not value and XLuaUiManager.IsUiShow("UiArenaOnlineInvitation") then
            XDataCenter.ArenaOnlineManager.ClearPrivateChatData()
            XLuaUiManager.Close("UiArenaOnlineInvitation")
        end
    end

    function XSetManager.SetWeaponTransType(type)
        if type == 0 then
            return
        end
        XSetManager.WeaponTransType = type
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.WeaponTransType, type)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    function XSetManager.SetRechargeType(type)
        if type == 0 then
            return
        end
        XSetManager.RechargeType = type
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.RechargeType, type)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    function XSetManager.SetOwnFontSize(size)
        CS.XRLFightSettings.SetOwnFontSize(size)
    end

    function XSetManager.SetAllyDamage(value)
        CS.XRLFightSettings.SetAllyDamage(value)
    end

    function XSetManager.SetAllyEffect(value)
        CS.XRLFightSettings.SetAllyEffect(value)
    end

    function XSetManager.SetDefaultFontSize()
        local size = SelfNumDefaultSize
        CS.XRLFightSettings.SetDefaultFontSize(size)
    end

    function XSetManager.SetOwnFontSizeByKey(key)
        local size = XSetConfigs.SelfNumSizes[key] or 0
        XSetManager.SetOwnFontSize(size)
    end

    function XSetManager.SetOwnFontSizeByCache()
        local tab = XSetManager.GetOwnFontSizeByCache()
        XSetManager.SetOwnFontSizeByTab(tab)
    end

    function XSetManager.GetOwnFontSizeByCache()
        local tab = XSaveTool.GetData(XSetConfigs.SelfNum)
        if tab == nil or tab == "" then
            tab = XSetConfigs.SelfNumEnum.Middle
        end
        return tab
    end

    function XSetManager.SetAllyDamageByCache()
        local v = XSetManager.GetAllyDamageByCache()
        XSetManager.SetAllyDamage(v == XSetConfigs.FriendNumEnum.Open)
    end

    function XSetManager.GetAllyDamageByCache()
        local v = XSaveTool.GetData(XSetConfigs.FriendNum)
        if v == nil or v == "" then
            v = XSetConfigs.FriendNumEnum.Close
        end

        return v
    end

    function XSetManager.SetAllyEffectByCache()
        local v = XSetManager.GetAllyEffectByCache()
        XSetManager.SetAllyEffect(v == XSetConfigs.FriendEffectEnum.Open)
    end

    function XSetManager.GetAllyEffectByCache()
        local v = XSaveTool.GetData(XSetConfigs.FriendEffect)
        if v == nil or v == "" then
            v = XSetConfigs.FriendEffectEnum.Open
        end

        return v
    end

    function XSetManager.SetOwnFontSizeByTab(tab)
        local k = XSetConfigs.SelfNumKeyIndexConfig[tab]
        if k == 0 then
            XSetManager.SetOwnFontSize(0)
        else
            XSetManager.SetOwnFontSizeByKey(k)
        end
    end

    function XSetManager.SetCurSeleButton(tab)
        XSetManager.CurSeleBtn = tab
    end

    function XSetManager.GetCurSeleButton()
        return XSetManager.CurSeleBtn or 0
    end

    function XSetManager.SaveSelfNum(value)
        XSaveTool.SaveData(XSetConfigs.SelfNum, value)
    end

    function XSetManager.SaveFriendNum(value)
        XSaveTool.SaveData(XSetConfigs.FriendNum, value)
    end

    function XSetManager.SaveFriendEffect(value)
        XSaveTool.SaveData(XSetConfigs.FriendEffect, value)
    end

    function XSetManager.SaveScreenOff(value)
        XSaveTool.SaveData(XSetConfigs.ScreenOff, value)
    end

    function XSetManager.GetScreenOff()
        return XSaveTool.GetData(XSetConfigs.ScreenOff) or 0
    end

    function XSetManager.SetScreenOff()
        local d = XSetManager.GetScreenOff()
        CS.XUiSafeAreaAdapter.SetSpecialScreenOff(d * MaxScreenOff)
    end

    function XSetManager.SetUiResolutionEventFlag(flag)
        CS.XUiSafeAreaAdapter.SetUiResolutionEventFlag(flag)
    end

    function XSetManager.SetSceneUIType()
        -- if GlobalIllumination.SceneType ~= SceneType.Ui then
        XSetManager.SetUiResolutionEventFlag(true)
        GlobalIllumination.SetSceneType(SceneType.Ui, true)
        -- end
    end

    function XSetManager.IsAdaptorScreen()
        if XSetManager.IsChange then
            XSetManager.IsChange = false
            return true
        end
        return false
    end

    function XSetManager.SetAdaptorScreenChange()
        XSetManager.IsChange = true
    end

    XSetManager.Init()
    return XSetManager
end