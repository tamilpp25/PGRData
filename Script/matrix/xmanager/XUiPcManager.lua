XUiPcManagerCreator = function()
    ---@class XUiPcManager
    local XUiPcManager = {}

    local EditingKey = false
    local ExitingGame = false

    local FullScreenMode = CS.UnityEngine.FullScreenMode
    
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
        XQuitHandler.OnEscBtnClick()
    end

    XUiPcManager.IsPc = function()
        return CS.XUiPc.XUiPcManager.IsPcMode()
    end

    -- 设备分辨率,非游戏分辨率
    XUiPcManager.GetDeviceScreenResolution = function()
        local vector = CS.XSettingHelper.GetDeviceResolution()
        return vector.x, vector.y
    end

    XUiPcManager.GetTabUiPcResolution = function()
        local config = XUiPcConfig.GetTabUiPcResolution()
        local deviceWidth, deviceHeight = XUiPcManager.GetDeviceScreenResolution()
        local result = {}
        for i, size in pairs(config) do
            if size.y <= deviceHeight - 50
                    and size.x <= deviceWidth
            then
                result[#result + 1] = size
            end
        end
        return result
    end

    XUiPcManager.GetOriginPcResolution = function()
        local config = XUiPcConfig.GetTabUiPcResolution()
        local result = {}
        for i, size in pairs(config) do
            result[#result + 1] = size
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

    XUiPcManager.SetEditingKeyState = function(editing)
        CS.XPc.XCursorHelper.ForceResponse = not editing
        XQuitHandler.SetEditingKeyState(editing)
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_EDITING_KEYSET, editing)
    end
    
    XUiPcManager.RefreshJoystickActive = function()
        XEventManager.DispatchEvent(XEventId.EVENT_JOYSTICK_ACTIVE_CHANGED)
    end

    XUiPcManager.RefreshJoystickType = function()
        XEventManager.DispatchEvent(XEventId.EVENT_JOYSTICK_TYPE_CHANGED)
    end

    XUiPcManager.FullScreenableCheck = function()
        local width, height = XUiPcManager.GetDeviceScreenResolution(); -- 获取设备分辨率
        local resolutions = XUiPcManager.GetOriginPcResolution();       -- 获取配置表最大分辨率
        local lastResolution = XUiPcManager.GetLastResolution()         -- 获取上一次设备分辨率
        local lastScreen = XUiPcManager.GetLastScreen()                 -- 获取上一次使用的屏幕分辨率 
        local unityScreen = XUiPcManager.GetUnityScreen()               -- 获取Unity写入的屏幕分辨率
        local length = #resolutions;
        local minResolution = resolutions[1];
        local maxResolution = resolutions[length];
        local lastFullScreen = XUiPcManager.GetLastFullScreen();
        local noFrame = XUiPcManager.GetLastNoFrame();
        local windowdMode = FullScreenMode.Windowed;
        local fullScreenMode = not noFrame and FullScreenMode.ExclusiveFullScreen or FullScreenMode.FullScreenWindow;
        local mode = lastFullScreen and fullScreenMode or windowdMode;
        CS.XLog.Debug("width", width, "height", height, "maxResolution", maxResolution, "lastResolution", lastResolution, "lastScreen", lastScreen)
        if width > maxResolution.x or height > maxResolution.y then
            CS.XLog.Debug("不能使用全屏")
            -- compare -- 当获取的屏幕尺寸超过配置表最大值时
            -- 这货不能用全屏, 给他禁掉
            CS.XSettingHelper.ForceWindow = true;
            -- 同时立即设置为窗口模式
            CS.UnityEngine.Screen.fullScreen = false
            local fitWidth;
            local fitHeight;
            if (lastScreen.width ~= 0 and lastScreen.height ~= 0) and lastScreen.width <= maxResolution.x and lastScreen.height <= maxResolution.y then
                fitWidth = lastScreen.width;
                fitHeight = lastScreen.height;
            else
                fitWidth = maxResolution.x;
                fitHeight = maxResolution.y;
            end
            CS.XLog.Debug("fitResolution", fitWidth, fitHeight)
            XUiPcManager.SetResolution(fitWidth, fitHeight, windowdMode)
        elseif width < lastResolution.width or height < lastResolution.height then       
            if (lastScreen.width > minResolution.x and lastScreen.height > minResolution.y) and (width < lastScreen.width or height < lastScreen.height) then
                -- 当前设备分辨率小于上一次使用的屏幕分辨率, 使其全屏
                CS.XLog.Debug("新设备比旧设备分辨率小, 直接使用当前分辨率并全屏", width, height)
                XUiPcManager.SetResolution(width, height, fullScreenMode);
                CS.XSettingHelper.ForceWindow = false;
            else
                -- 当前设备分辨率大于上一次使用的屏幕分辨率, 直接使用上一次的作为当前窗口分辨率设置
                CS.XLog.Debug("新设备比旧设备分辨率小, 但是大于上一次窗口分辨率设置, 使用上一次的窗口化分辨率", lastScreen.width, lastScreen.height, lastFullScreen)
                local mode = lastFullScreen and fullScreenMode or windowdMode
                XUiPcManager.SetResolution(lastScreen.width, lastScreen.height, mode)
            end
        else
            if unityScreen.width < minResolution.x or unityScreen.height < minResolution.y then
                -- unity读取的尺寸很可能导致条幅屏, 判断是否有正确的缓存值 -- todo 这里会存在和国服有差异的地方
				if lastScreen.width > minResolution.x and lastScreen.height > minResolution.y then
				    -- 如果有正确的缓存值
					CS.XLog.Debug("设置过正确的缓存值, 使用这个")
					XUiPcManager.SetResolution(lastScreen.width, lastScreen.height, mode)
				else
				    -- 没有正确的缓存值, 使用全屏
				    CS.XLog.Debug("未被设置过, 使用全屏")
                    XUiPcManager.SetResolution(width, height, mode)
				end
            else
                CS.XLog.Debug("不需要任何变化")
            end
            CS.XSettingHelper.ForceWindow = false;
        end
        -- 记录设备分辨率
        XUiPcManager.SaveResolution(width, height)
    end

    -- 得到窗口化时可使用的最大分辨率
    XUiPcManager.GetWindowedMaxResolution = function()
        -- 窗口化分辨率
        local windowedMaxResolutions = XUiPcManager.GetTabUiPcResolution();
        local windowedLength = #windowedMaxResolutions;
        local windowedMaxResolution = windowedMaxResolutions[windowedLength];
        return windowedMaxResolution;
    end

    XUiPcManager.LastResolution = nil
    XUiPcManager.GetLastResolution = function()
        if not XUiPcManager.LastResolution then
            local prefs = CS.UnityEngine.PlayerPrefs.GetString("LastResolution", nil);
            if not prefs or prefs == "" then
                XUiPcManager.LastResolution = CS.UnityEngine.Screen.currentResolution;
            else
                local empty = CS.XUnityEx.ResolutionEmpty;
                local arr = string.Split(prefs, ",");
                empty.width = arr[1];
                empty.height = arr[2];
                XUiPcManager.LastResolution = empty;
            end
        end
        return XUiPcManager.LastResolution;
    end

    XUiPcManager.LastScreen = nil
    XUiPcManager.GetLastScreen = function()
        if not XUiPcManager.LastScreen then
            local prefs = CS.UnityEngine.PlayerPrefs.GetString("LastScreen", nil)
            if not prefs or prefs == "" then
                XUiPcManager.LastScreen = CS.XUnityEx.ResolutionEmpty
            else
                local empty = CS.XUnityEx.ResolutionEmpty
                local arr = string.Split(prefs, ",")
                empty.width = arr[1]
                empty.height = arr[2]
                XUiPcManager.LastScreen = empty
            end
        end
        return XUiPcManager.LastScreen
    end

    XUiPcManager.GetUnityScreen = function()
		local Screen = CS.UnityEngine.Screen
		local result = {
		    width = Screen.width,
			height = Screen.height
		}
		return result;
	end

    XUiPcManager.LastFullScreen = false
    XUiPcManager.GotLastFullScreen = false
    XUiPcManager.GetLastFullScreen = function()
        if not XUiPcManager.GotLastFullScreen then
            XUiPcManager.GotLastFullScreen = true
            local prefs = CS.UnityEngine.PlayerPrefs.GetInt("LastFullScreen", -1)
            if prefs == -1 then
                XUiPcManager.LastFullScreen = CS.UnityEngine.Screen.fullScreen
            else
                XUiPcManager.LastFullScreen = prefs == 1
            end
        end
        return XUiPcManager.LastFullScreen
    end

    XUiPcManager.LastNoFrame = false
    XUiPcManager.GotLastNoFrame = false
    XUiPcManager.GetLastNoFrame = function()
        if not XUiPcManager.GotLastNoFrame then
            XUiPcManager.GotLastNoFrame = true
            local prefs = CS.UnityEngine.PlayerPrefs.GetInt("LastNoFrame", -1)
            if prefs == -1 then
                XUiPcManager.LastNoFrame = true
            else
                XUiPcManager.LastNoFrame = prefs == 1
            end
        end
        return XUiPcManager.LastNoFrame
    end

    XUiPcManager.SetNoFrame = function(value)
        XUiPcManager.LastNoFrame = value
        CS.UnityEngine.PlayerPrefs.SetInt("LastNoFrame", value and 1 or 0)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    XUiPcManager.SetResolution = function(width, height, fullscreenMode)
        CS.XSettingHelper.SetResolution(width, height, fullscreenMode)
        XUiPcManager.SaveResolution(width, height)
        XUiPcManager.SaveFullScreen(fullscreenMode == FullScreenMode.FullScreenWindow)
    end

    XUiPcManager.SaveResolution = function(width, height)
        local empty = CS.XUnityEx.ResolutionEmpty;
        empty.width = width;
        empty.height = height;
        XUiPcManager.LastResolution = empty;
        CS.UnityEngine.PlayerPrefs.SetString("LastResolution", width .. "," .. height);
        CS.UnityEngine.PlayerPrefs.Save();
    end

    XUiPcManager.SaveScreen = function(width, height)
        local empty = CS.XUnityEx.ResolutionEmpty
        empty.width = width
        empty.height = height
        XUiPcManager.LastScreen = empty
        CS.UnityEngine.PlayerPrefs.SetString("LastScreen", width .. "," .. height)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    XUiPcManager.SaveFullScreen = function(fullScreen)
        XUiPcManager.LastFullScreen = fullScreen
        CS.UnityEngine.PlayerPrefs.SetInt("LastFullScreen", fullScreen and 1 or 0)
        CS.UnityEngine.PlayerPrefs.Save()
    end 

    XUiPcManager.Init()
    return XUiPcManager
end
