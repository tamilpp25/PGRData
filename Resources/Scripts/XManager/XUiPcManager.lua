XUiPcManagerCreator = function()
    ---@class XUiPcManager
    local XUiPcManager = {}

    XUiPcManager.Init = function()
        -- if not XUiPcManager.IsPc() then
        --     return
        -- end
        -- CsXGameEventManager.Instance:RegisterEvent(
        --     CS.XEventId.EVENT_UI_AWAKE,
        --     function(evt, ui)
        --         XUiPcManager.OnUiSceneLoaded(ui)
        --     end
        -- )
    end

    XUiPcManager.OnEscBtnClick = function()
        -- 它自己
        if XLuaUiManager.IsUiShow("UiSystemDialog") then
            XLuaUiManager.Close("UiSystemDialog")
            return
        end

        if XLuaUiManager.IsUiShow("UiGuide") then
            XUiPcManager.ExitGame()
            return;
        end

        -- -- cg
        -- if XLuaUiManager.IsUiShow("UiFightVideoPlayer") then
        --     return
        -- end

        -- 战斗中
        if CS.XFight.IsRunning then            
            if CS.XFight.Instance.HideCloseButton then
                return
            end
            if XLuaUiManager.IsUiShow("UiSet") then
                XUiPcManager.ExitGame();
                return
            end
            XLuaUiManager.Open("UiSet", true)
            return
        end
        -- -- 剧情
        -- if XLuaUiManager.IsUiShow("UiMovie") then
        --     return
        -- end
        
        -- -- loading 界面
        -- if XLuaUiManager.IsUiShow("UiLoading") then
        --     return
        -- end
        -- -- loading 界面 边界公约
        -- if XLuaUiManager.IsUiShow("UiAssignInfo") then
        --     return
        -- end
        --退出游戏

        XUiPcManager.ExitGame()
    end
    
    XUiPcManager.ExitGame = function()
        local title = CS.XTextManager.GetText("TipTitle")
        local content = CS.XTextManager.GetText("GameExitMsg")
        local confirmCb = function()
            CS.XDriver.Exit()
        end
        -- 会关闭公告, 尝试不发此事件
        -- CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Tip_Big)
        XLuaUiManager.Open("UiSystemDialog", title, content, XUiManager.DialogType.Normal, nil, confirmCb)
        -- XLuaUiManager.Open("UiDialogExitGame", title, content, XUiManager.DialogType.Normal, nil, confirmCb)
    end

    XUiPcManager.IsPc = function()
        return true
        --if true then
        --    return true
        --end
        -- 除了windows都不开
        -- local platform = CS.UnityEngine.Application.platform
        -- if platform ~= CS.UnityEngine.RuntimePlatform.WindowsEditor
        --         and platform ~= CS.UnityEngine.RuntimePlatform.WindowsPlayer
        -- then
        --     return false
        -- end
        -- if CS.XCustomUi.PCSetEnable then
        --     return true
        -- end
        -- return false
    end

    -- 设备分辨率,非游戏分辨率
    local _DeviceScreenResolution = false
    XUiPcManager.GetDeviceScreenResolution = function()
        if not _DeviceScreenResolution then
            local resolutions = CS.UnityEngine.Screen.resolutions
            local maxResolution = 0
            local maxIndex = 1
            for i = 1, resolutions.Length - 1 do
                local resolution = resolutions[i]
                local product = resolution.width * resolution.height
                if product > maxResolution then
                    maxResolution = product
                    maxIndex = i
                end
            end
            local resolution = resolutions[maxIndex]
            _DeviceScreenResolution = {
                Width = resolution.width,
                Height = resolution.height
            }
        end
        return _DeviceScreenResolution.Width, _DeviceScreenResolution.Height
    end

    XUiPcManager.GetTabUiPcResolution = function()
        local config = XUiPcConfig.GetTabUiPcResolution()
        local deviceWidth, deviceHeight = XUiPcManager.GetDeviceScreenResolution()
        local result = {}
        for i, size in pairs(config) do
            if size.y <= (deviceHeight - 50)
                    and size.x <= deviceWidth
            then
                result[#result + 1] = size
            end
        end
        return result
    end

    XUiPcManager.OnUiSceneLoaded = function(ui)
        local ui = ui[0]
        local uiName = ui.UiData.UiName
        -- local prefabPath = ui.UiData.PrefabUrl
        local replaceDataArray = XUiPcConfig.GetTabUiPcReplace(uiName)
        if #replaceDataArray > 0 then
            local root = ui.GameObject.transform
            for i = 1, #replaceDataArray do
                local replaceData = replaceDataArray[i]
                local buttonTransform = root:Find(replaceData.ButtonPath)
                if buttonTransform then
                    if not buttonTransform:GetComponent('XUiPcControl') then
                        local uiPcControl = buttonTransform.gameObject:AddComponent(typeof(CS.XUiPc.XUiPcControl))
                        uiPcControl:SetReferenceDataEx(replaceData.PrefabPath, replaceData.PrefabGuid)
                        XLog.Debug('自动添加了组件Pc ui:' .. replaceData.ButtonPath)
                    end
                end
            end
        end
    end

    XUiPcManager.Init()
    return XUiPcManager
end
