XSetManagerCreator = function()
    ---@class XSetManager
    local XSetManager = {}
    local SelfNumDefaultSize
    local NumStyle
    local MaxScreenOff
    local GlobalIllumination
    local SceneType
    XSetManager.DynamicJoystick = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.DynamicJoystick, XSetConfigs.DefaultDynamicJoystick)
    --region focus
    XSetManager.FocusType = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.FocusType, XSetConfigs.DefaultFocusType)
    XSetManager.FocusButton =
    {
        [XSetConfigs.FocusType.Auto] = 0,
        [XSetConfigs.FocusType.Manual] = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.FocusButton[XSetConfigs.FocusType.Manual], XSetConfigs.DefaultFocusButton),
        [XSetConfigs.FocusType.SemiAuto] = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.FocusButton[XSetConfigs.FocusType.SemiAuto], XSetConfigs.DefaultFocusButton)
    }
    -- focusButton有改动, 取回玩家历史设置，-1代表新号
    local focusBtnNoRecord = -1
    local focusBtnHistory = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.FocusButton.History, focusBtnNoRecord)
    if focusBtnHistory ~= focusBtnNoRecord then
        XSetManager.FocusButton[XSetConfigs.FocusType.Manual] = focusBtnHistory
        XSetManager.FocusButton[XSetConfigs.FocusType.SemiAuto] = focusBtnHistory
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.FocusButton.History, focusBtnNoRecord)
    end
    --endregion focus
    
    --region focus dlcHunt
    XSetManager.FocusTypeDlcHunt = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.FocusTypeDlcHunt, XSetConfigs.DefaultFocusTypeDlcHunt)
    XSetManager.FocusButtonDlcHunt =
    {
        [XSetConfigs.FocusTypeDlcHunt.Auto] = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.FocusButtonDlcHunt[XSetConfigs.FocusTypeDlcHunt.Auto], XSetConfigs.DefaultFocusButtonDlcHunt),
        [XSetConfigs.FocusTypeDlcHunt.Manual] = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.FocusButtonDlcHunt[XSetConfigs.FocusTypeDlcHunt.Manual], XSetConfigs.DefaultFocusButtonDlcHunt),
        --[XSetConfigs.FocusTypeDlcHunt.SemiAuto] = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.FocusButtonDlcHunt[XSetConfigs.FocusTypeDlcHunt.SemiAuto], XSetConfigs.DefaultFocusButtonDlcHunt)
    }
    --endregion focus dlcHunt

    XSetManager.InviteButton = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.InviteButton, XSetConfigs.DefaultInviteButton)
    XSetManager.WeaponTransType = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.WeaponTransType, XSetConfigs.DefaultWeaponTransType)
    XSetManager.RechargeType = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.RechargeType, XSetConfigs.DefaultRechargeType)
    XSetManager.CaptionType = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.CaptionType, XSetConfigs.DefaultCaptionType)
    XSetManager.FightCameraVibration = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.FightCameraVibration, XSetConfigs.DefaultFightCameraVibration)
    
    function XSetManager.Init()
        GlobalIllumination = CS.XGlobalIllumination
        SceneType = CS.XSceneType
        SelfNumDefaultSize = CS.XGame.ClientConfig:GetInt("SelfNumDefault") or 0
        MaxScreenOff = CS.XGame.ClientConfig:GetFloat("SpecialScreenOff") or 0
        NumStyle = CS.XGame.ClientConfig:GetInt("NumStyle") or 1
        --region focus
        XSetManager.SetFocusType(XSetManager.FocusType)
        for _, focusType in pairs(XSetConfigs.FocusType) do
            XSetManager.SetFocusButtonActive(focusType, XSetManager.FocusButton[focusType] == 1)
        end
        --region focus
        --region focus dlcHunt
        XSetManager.SetFocusTypeDlcHunt(XSetManager.FocusTypeDlcHunt)
        for _, focusType in pairs(XSetConfigs.FocusTypeDlcHunt) do
            XSetManager.SetFocusButtonActiveDlcHunt(focusType, XSetManager.FocusButtonDlcHunt[focusType] == 1)
        end
        --region focus dlcHunt
        XSetManager.SetInviteButtonActive(XSetManager.InviteButton == 1)
        XSetManager.SetWeaponTransType(XSetManager.WeaponTransType)
        XSetManager.SetRechargeType(XSetManager.RechargeType)
        XSetManager.SetCaptionType(XSetManager.CaptionType)
        XSetManager.SetFightCameraVibration(XSetManager.FightCameraVibration)
        XEventManager.AddEventListener(XEventId.EVNET_FAIL_PAY, XSetManager.SetSceneUIType)
    end

    --region focus
    function XSetManager.SetFocusType(type)
        if type == 0 then
            return
        end
        XSetManager.FocusType = type
        CS.XRLFightSettings.SetFocusType(type)
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.FocusType, type)
        CS.UnityEngine.PlayerPrefs.Save()
        -- 如果不保存FocusButton，可能与设置显示不一致
    end

    function XSetManager.SetFocusButtonActive(focusType, value)
        if focusType == XSetManager.FocusType then
            CS.XRLFightSettings.SetFocusButtonActive(value)
        end
        XSetManager.FocusButton[focusType] = value and 1 or 0
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.FocusButton[focusType], XSetManager.FocusButton[focusType])
        CS.UnityEngine.PlayerPrefs.Save()
    end
    --endregion focus
    
    --region focus dlcHunt
    function XSetManager.SetFocusTypeDlcHunt(type)
        if type == 0 then
            return
        end
        XSetManager.FocusTypeDlcHunt = type
        CS.StatusSyncFight.XRLFightSettingsDLC.SetFocusType(type)
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.FocusTypeDlcHunt, type)
        CS.UnityEngine.PlayerPrefs.Save()
        -- 如果不保存FocusButton，可能与设置显示不一致
    end

    function XSetManager.SetFocusButtonActiveDlcHunt(focusType, value)
        if focusType == XSetManager.FocusTypeDlcHunt then
            CS.StatusSyncFight.XRLFightSettingsDLC.SetFocusButtonActive(value)
        end
        XSetManager.FocusButtonDlcHunt[focusType] = value and 1 or 0
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.FocusButtonDlcHunt[focusType], XSetManager.FocusButtonDlcHunt[focusType])
        CS.UnityEngine.PlayerPrefs.Save()
    end
    --endregion focus dlcHunt

    function XSetManager.SetInviteButtonActive(value)
        XSetManager.InviteButton = value and 1 or 0
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.InviteButton, XSetManager.InviteButton)
        CS.UnityEngine.PlayerPrefs.Save()
        
        if not value and XLuaUiManager.IsUiShow("UiArenaOnlineInvitation") then
            XDataCenter.ArenaOnlineManager.ClearPrivateChatData()
            XLuaUiManager.Close("UiArenaOnlineInvitation")
        end
        if not value then
            XMVCA.XDlcRoom:ClearReceiveInvitation()
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
    
    function XSetManager.SetCaptionType(type)
        if type == 0 then
            return
        end
        XSetManager.CaptionType = type
        CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.CaptionType, type)
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
    
    function XSetManager.SetDefaultNumStyleByCache()
        local style = XSaveTool.GetData(XSetConfigs.NumStyleKey)
        if style == nil then
            style = NumStyle
        end
        
        CS.XRLFightSettings.SetNumStyle(style);
    end
    
    
    function XSetManager.InitFightCameraVibration()
        local size = XSetManager.FightCameraVibration
        CS.XRLFightSettings.SetFightCameraVibration(size)
    end

    function XSetManager.SetFightCameraVibration(value)
        XSetManager.FightCameraVibration = value
        local CSPlayerPrefs = CS.UnityEngine.PlayerPrefs
        CSPlayerPrefs.SetInt(XPrefs.FightCameraVibration, value)
        CSPlayerPrefs.Save()
        CS.XRLFightSettings.SetFightCameraVibration(value)
    end


    function XSetManager.SetOwnFontSizeByKey(key)
        local size = XSetConfigs.SelfNumSizes[key] or 0
        XSetManager.SetOwnFontSize(size)
    end

    function XSetManager.SetOwnFontSizeByCache()
        local tab = XSetManager.GetOwnFontSizeByCache()
        XSetManager.SetOwnFontSizeByTab(tab)
    end

    function XSetManager.SetNumStyle(value)
        CS.XRLFightSettings.SetNumStyle(value)
    end
    
    function XSetManager.GetOwnFontSizeByCache()
        local tab = XSaveTool.GetData(XSetConfigs.SelfNum)
        if tab == nil or tab == "" then
            tab = XSetConfigs.DamageNumSize.Middle
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
    
    function XSetManager.SaveNumStyle(value)
        XSaveTool.SaveData(XSetConfigs.NumStyleKey, value)
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
    
    function XSetManager.GetInputMapIdList()
        local inputMapIdListConfig = XSetConfigs.GetInputMapIdList()
        local inputMapIdList = {}
        local timeId

        local stageType
        if CS.XFight.IsRunning then
            local stageId = CS.XFight.Instance.FightData.StageId
            if XTool.IsNumberValid(stageId) then
                stageType = XDataCenter.FubenManager.GetStageType(stageId)
            end
        end

        for _, inputMapId in ipairs(inputMapIdListConfig) do
            timeId = XSetConfigs.GetInputMapIdTimeId(inputMapId)
            if XFunctionManager.CheckInTimeByTimeId(timeId, false) or timeId == 0 then
                local stageTypes = XSetConfigs.GetInputMapIdTimeStageTypes(inputMapId)
                if XTool.IsTableEmpty(stageTypes) or table.indexof(stageTypes, stageType) then
                    table.insert(inputMapIdList, inputMapId)
                end
            end
        end

        -- 1、符合stagetype>不符合；2、ID从小到大
        table.sort(inputMapIdList, function(a, b)
            local aHasStageType = not XTool.IsTableEmpty(XSetConfigs.GetInputMapIdTimeStageTypes(a))
            local bHasStageType = not XTool.IsTableEmpty(XSetConfigs.GetInputMapIdTimeStageTypes(b))

            if aHasStageType ~= bHasStageType then
                return aHasStageType == true
            end
            return a < b
        end)

        return inputMapIdList
    end

    --- @desc 获取灵敏度值(战斗用)
    function XSetManager.GetSensitivityValue(id)
        local key = XPrefs.Sensitivity[id]
        if not key then
            XLog.Error( string.format("请检查XPrefs.Sensitivity是否定义【%s】", id))
            return 0
        end
        
        local defaultValue = CS.XGame.ClientConfig:GetFloat("SensitivityDefault"..id)
        local value = CS.UnityEngine.PlayerPrefs.GetFloat(key, defaultValue)
        value = tonumber(string.format("%.1f", value))
        return value
    end

    --- @desc 设置灵敏度(战斗用)
    function XSetManager.SetSensitivityValue(id, value)
        local key = XPrefs.Sensitivity[id]
        if not key then
            XLog.Error( string.format("请检查XPrefs.Sensitivity是否定义【%s】", id))
            return 0
        end

        value = tonumber(string.format("%.1f", value))
        local CSPlayerPrefs = CS.UnityEngine.PlayerPrefs
        CSPlayerPrefs.SetFloat(key, value)
        CSPlayerPrefs.Save()
    end
    
    --- @desc 获取灵敏度Id
    function XSetManager.GetSensitivityId()
        if not CS.XFight.Instance then return 0 end
        return CS.XFight.Instance.CameraMoveSensitivityKey
    end
    
    function XSetManager.OpenSensitivityUi()
        local isFight = true
        local panelIndex = 4
        local secondIndex = 1
        XLuaUiManager.Open("UiSet", isFight, panelIndex, secondIndex)
    end
    
    --region   ------------------系统设置埋点 start-------------------
    function XSetManager.SystemSettingBuriedPoint(dict)
        dict = dict or {}
        dict["event_time"]  = XTime.TimestampToLocalDateTimeString(XTime.GetServerNowTimestamp())
        dict["role_id"]     = XPlayer.Id
        dict["role_level"]  = XPlayer.GetLevel()
        dict["server_id"]   = XServerManager.Id
        CS.XRecord.Record(dict, "200009", "SystemSetting")
    end
    --endregion------------------系统设置埋点 finish------------------

    XSetManager.Init()
    return XSetManager
end