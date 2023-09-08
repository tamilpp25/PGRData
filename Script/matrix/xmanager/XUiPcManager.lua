XUiPcManagerCreator = function()
    ---@class XUiPcManager
    local XUiPcManager = {}

    local FullScreenMode = CS.UnityEngine.FullScreenMode
    local PlayerPrefs = CS.UnityEngine.PlayerPrefs

    local EditingKey
    local ExitingGame
    local UiStacks
    local UiDict

    local CsXGameEventManager = CS.XGameEventManager
    local CSEventId = CS.XEventId

    local function IsOnBtnClick()
        if XLuaUiManager.IsUiShow("UiLoading") or
                XLuaUiManager.IsUiShow("UiAssignInfo") or -- loading 界面 边界公约
                XDataCenter.GuideManager.CheckIsInGuide() or
                XLuaUiManager.IsUiShow("UiBlackScreen") then
            return false
        end
        return true
    end

    function XUiPcManager.OnUiEnable()
        -- todo 删除
    end

    -- 这些是返回键
    local _DictBtnBack = {
        BtnBack = true,
        BtnTanchuangCloseBig = true,
        BtnTanchuangClose = true,
        BtnClose = true,
        ButtonClose = true,
        ButtonBack = true,
        BtnExit = true,
        BtnMask = true,
        BtnBlock = true,
        BtnTreasureBg = true,
        BtnCancel = true,
        BtnCloseDetail = true,
        SceneBtnBack = true,
        BtnDetermine = true,
        BtnClosePopup = true,
        BtnHideCurResonance = true,
        BtnChannelMask = true,
        CloseMask = true,
        Close = true,
        BtnBg = true,
        BtnCloseAllScreen = true,
        BtnCloseMask1 = true,
        BtnCloseMask2 = true,
        BtnCloseMask3 = true,
        BtnCloseMask4 = true,
        BtnTanchuangCloseWhite = true,
        BtnCloseCollection = true,
    }

    -- 这些界面的这些键 是返回键
    local _DictBtnBackSpecial = {
        UiPhotograph = {
            Btn = true
        },
        UiCharacterTowerPlot = {
            BtnUnHide = true
        },
        UiBiancaTheatreRecruit = {
            UiBiancaTheatreRecruit = true
        },
        UiFubenMainLine3D = {
            Mask = true
        },
        UiDormSecond = {
            BtnHide = true
        },
        UiDormTerminalSystem = {
            BtnDarkBg = true
        },
        UiAssignDeploy = {
            BtnTongBlueLight = true
        },
        UiAwarenessDeploy = {
            BtnTongBlueLight = true
        },
        UiArchiveMonsterDetail = {
            BtnHide = true
        },
        UiBfrtDeploy = {
            BtnSave = true
        },
        UiMultiplayerRoom = {
            BtnCloseDifficulty = true
        },
        UiRegressionTips = {
            BtnPreviewConfirm = true
        },
        UiBattleRoleRoom = {
            BtnCloseDifficulty = true
        },
    }

    -- 这些界面的这些键 不是返回键
    local _DictBtnBackIgnored = {
        UiStrongholdRewardTip = {
            BtnMask = true
        },
        UiTheatreContinue = {
            BtnMask = true
        },
        UiGoldenMinerSuspend = {
            BtnExit = true
        },
        UiGoldenMinerDialog = {
            BtnClose = true
        },
    }

    -- 这些界面 不响应返回键
    local _DictBtnBackUiIgnored = {
        UiBfrtPostWarCount = true,
        UiAssignPostWarCount = true,
        UiSettleWinSingleBoss = true,
        UiFubenFlopReward = true,
        UiSettleWinMainLine = true,
        UiSettleWin = true,
    }

    -- 这些界面 不响应返回键 而且中断下层(Normal Dialog等)继续查找
    local _DictBtnBackUiDisable = {
        UiStrongholdAnimation = true,
        UiStrongholdInfo = true,
    }

    local function GetUiSiblingIndexArray(rootName, transform)
        local array = {}
        local parentTransform = transform
        for i = 1, 99 do
            if not parentTransform then
                break
            end
            if parentTransform.name == rootName then
                break
            end
            local siblingIndex = parentTransform:GetSiblingIndex()
            table.insert(array, 1, siblingIndex)
            parentTransform = parentTransform.parent
        end
        return array
    end

    local function CompareBySiblingArray(rootName, transform1, transform2)
        if not transform1 then
            return false
        end
        if not transform2 then
            return true
        end
        local array1 = GetUiSiblingIndexArray(rootName, transform1)
        local array2 = GetUiSiblingIndexArray(rootName, transform2)
        for i = 1, #array1 do
            local siblingIndex1 = array1[i]
            local siblingIndex2 = array2[i]
            if siblingIndex1 ~= siblingIndex2 then
                return siblingIndex1 < siblingIndex2
            end
        end
        XLog.Error("[XUiPcManager] 比较siblingOrder错误")
        return false
    end

    local function FindButtonOnTop(root, type)
        local buttons = root:GetComponentsInChildren(type)
        local buttonOnTop
        local sortingOrderOnTop = 0
        local renderOrderOnTop = 0
        local relativeDepthOnTop = 0
        local rootName = root.name

        for i = 0, buttons.Length - 1 do
            local button = buttons[i]
            local buttonName = button.name
            local isSpecial = _DictBtnBackSpecial[rootName] and _DictBtnBackSpecial[rootName][buttonName]
            local isIgnored = _DictBtnBackIgnored[rootName] and _DictBtnBackIgnored[rootName][buttonName]
            if (not isIgnored) and (isSpecial or _DictBtnBack[buttonName]) then
                local canvasRenderer = button.transform:GetComponent(typeof(CS.UnityEngine.CanvasRenderer))
                if not XTool.UObjIsNil(canvasRenderer) then
                    -- 自身不透明
                    local alpha = canvasRenderer:GetAlpha()
                    if alpha > 0 then

                        -- 所在group不透明
                        local canvasGroup = button:GetComponentInParent(typeof(CS.UnityEngine.CanvasGroup))
                        if (not canvasGroup) or (canvasGroup.alpha > 0) then
                            -- 这个界面的renderOrder是反转的
                            if rootName == "UiBiancaTheatreRecruit"
                                    or rootName == "UiBiancaTheatrePlayMain"
                            then
                                if CompareBySiblingArray(buttonOnTop, button) then
                                    buttonOnTop = button
                                end
                            else
                                local isOnTop = false
                                local canvas = button:GetComponentInParent(typeof(CS.UnityEngine.Canvas))
                                local sortingOrder = canvas.sortingOrder or 0
                                local renderOrder = canvas.renderOrder or 0
                                local relativeDepth = canvasRenderer.relativeDepth or 0

                                if sortingOrder == sortingOrderOnTop then
                                    if renderOrder == renderOrderOnTop then
                                        if relativeDepth > relativeDepthOnTop then
                                            isOnTop = true
                                        end
                                    elseif renderOrder > renderOrderOnTop then
                                        isOnTop = true
                                    end
                                elseif sortingOrder > sortingOrderOnTop then
                                    isOnTop = true
                                end

                                if isOnTop then
                                    sortingOrderOnTop = sortingOrder
                                    renderOrderOnTop = renderOrder
                                    relativeDepthOnTop = relativeDepth
                                    buttonOnTop = button.transform
                                end
                            end
                        end
                    end
                end
            end
        end

        return buttonOnTop
    end

    function XUiPcManager.OnUiDisableAbandoned()
        -- todo 删除
    end

    local function PerformClick(transform)
        --自身不可见则不响应
        if (not transform.gameObject.activeSelf) or (not transform.gameObject.activeInHierarchy) then
            return
        end
        local xuiButton = transform:GetComponent(typeof(CS.XUiComponent.XUiButton))
        if xuiButton then
            local pointerEventData = CS.UnityEngine.EventSystems.PointerEventData(CS.UnityEngine.EventSystems.EventSystem.current)
            pointerEventData.button = CS.UnityEngine.EventSystems.PointerEventData.InputButton.Left
            xuiButton:OnPointerClick(pointerEventData)
        end

        if XTool.UObjIsNil(transform) then
            return
        end

        local listener = transform:GetComponent("XUguiEventListener")
        if listener then
            local pointerEventData = CS.UnityEngine.EventSystems.PointerEventData(CS.UnityEngine.EventSystems.EventSystem.current)
            pointerEventData.button = CS.UnityEngine.EventSystems.PointerEventData.InputButton.Left
            listener:OnPointerClick(pointerEventData)
        end

        if XTool.UObjIsNil(transform) then
            return
        end

        local button = transform:GetComponent(typeof(CS.UnityEngine.UI.Button))
        if button then
            button.onClick:Invoke()
        end
    end

    local function PerformButtonOnTopByLayer(layer)
        local ui
        if CsXUiManager.Instance.GetTopUiEx then
            ui = CsXUiManager.Instance:GetTopUiEx(layer)
        else
            ui = CsXUiManager.Instance:GetTopUi(layer)
        end
        if ui and ui.UiData.IsLuaUi then
            local uiName = ui.UiData.UiName
            if _DictBtnBackUiIgnored[uiName] then
                return false
            end
            if _DictBtnBackUiDisable[uiName] then
                -- 中断下层
                return true
            end

            -- 特殊处理:公会利用popup来实现两层界面，导致找不到按钮
            if uiName == "UiGuildDormCommon" then
                local uiGuildDorm = CsXUiManager.Instance:FindTopUi("UiGuildDormMain")
                if uiGuildDorm then
                    ui = uiGuildDorm
                end
            elseif uiName == "UiEquipAwarenessPopup" then
                local uiGuildDorm = CsXUiManager.Instance:FindTopUi("UiEquipAwarenessReplace")
                if uiGuildDorm then
                    ui = uiGuildDorm
                end
                
            elseif uiName == "UiRestaurantCommon" then
                local uiRestaurant = CsXUiManager.Instance:FindTopUi("UiRestaurantMain")
                if uiRestaurant then
                    ui = uiRestaurant
                end
            end

            ---@type XLuaUi
            local uiProxy = ui.UiProxy
            local root = uiProxy.GameObject
            local button = FindButtonOnTop(root, typeof(CS.UnityEngine.UI.Button))
            if button then
                PerformClick(button)
                return true
            end
        end
        return false
    end

    --local function IsInputFieldFocused()
    --    local EventSystem = CS.UnityEngine.EventSystems.EventSystem
    --    if EventSystem then
    --        local isFocused = EventSystem.current.isFocused
    --        if isFocused then
    --            local currentSelectedGameObject = EventSystem.current.currentSelectedGameObject
    --            if not XTool.UObjIsNil(currentSelectedGameObject) then
    --                if currentSelectedGameObject:GetComponent(typeof(CS.UnityEngine.UI.InputField)) then
    --                    return true
    --                end
    --            end
    --        end
    --    end
    --    return false
    --end

    --- 关闭界面
    function XUiPcManager.OnUiDisable()
        if CS.XUiManagerExtension.Masked then
            return
        end

        if XDataCenter.GuideManager.CheckIsInGuide() then
            if CS.XQuitHandler and CS.XQuitHandler.OnBtnBackGuide then
                CS.XQuitHandler.OnBtnBackGuide()
            end
            return
        end

        if not IsOnBtnClick() then
            return
        end

        --if IsInputFieldFocused() then
        --    return
        --end

        if PerformButtonOnTopByLayer(CsXUiType.Tips) then
            return
        end
        if PerformButtonOnTopByLayer(CsXUiType.Dialog) then
            return
        end
        if PerformButtonOnTopByLayer(CsXUiType.Popup) then
            return
        end
        if PerformButtonOnTopByLayer(CsXUiType.Normal) then
            return
        end
        XUiPcManager.OnEscBtnClick()

        if XDataCenter.GuideManager.CheckIsInGuide() then
            local button = XDataCenter.GuideManager.getButton()
            if _DictBtnBack[button.name] then
                XDataCenter.GuideManager.NextStep()
                --OnPointerClick
                PerformClick(button.transform)
            end
        end
    end

    XUiPcManager.Init = function()
        EditingKey = false
        ExitingGame = false
        UiStacks = XStack.New()
        UiDict = {}
        CS.XUiManagerExtension.SetBlackList("UiNoticeTips") -- 跑马灯
    end

    XUiPcManager.OnEscBtnClick = function()
        if XLuaUiManager.IsUiShow("UiGuide") then
            -- 新手引导当做系统界面处理
            -- XUiPcManager.ExitGame()
            return
        end
        -- 战斗中
        local fight = CS.XFight.Instance
        if fight then
            if fight.IsClosedLoading and fight.State == CS.XFightState.Fight then
                fight.UiManager:GetUi(typeof(CS.XUiFight)):OnClickExit(nil)
            end
            return
        end
        -- 剧情
        if XLuaUiManager.IsUiShow("UiMovie") then
            return
        end
        -- cg
        if XLuaUiManager.IsUiShow("UiVideoPlayer") then
            return
        end
        if not IsOnBtnClick() then
            return
        end
        if XLuaUiManager.IsUiShow("UiGoldenMinerBattle") then
            XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_EXIT_CLICK)
            return
        end
        -- 它自己
        if XLuaUiManager.IsUiShow("UiDialogExitGame") then
            return
        end

        if XUiPcManager.IsEditingKey() then
            return
        end

        if CS.XUiManagerExtension.Masked then
            return
        end

        if not XLuaUiManager.IsUiShow("UiMain") and not XLuaUiManager.IsUiShow("UiLogin") then
            return
        end
        if not CS.XUiManagerExtension.IsUIEnabled("UiMain") and not CS.XUiManagerExtension.IsUIEnabled("UiLogin") then
            return
        end
        --退出游戏
        XUiPcManager.ExitGame()
    end

    XUiPcManager.ExitGame = function()

        if ExitingGame then
            return
        end
        ExitingGame = true

        local title = CS.XTextManager.GetText("TipTitle")
        local content = CS.XTextManager.GetText("GameExitMsg")
        local confirmCb = function()
            CS.XDriver.Exit()
        end
        -- 会关闭公告, 尝试不发此事件
        -- CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Tip_Big)
        XLuaUiManager.Open("UiDialogExitGame", title, content, XUiManager.DialogType.Normal, nil, confirmCb)
    end

    XUiPcManager.SetExitingGame = function(value)
        ExitingGame = value
    end

    XUiPcManager.GetExitingGame = function()
        return ExitingGame
    end

    XUiPcManager.IsPc = function()
        return CS.XUiPc.XUiPcManager.IsPcMode()
    end

    XUiPcManager.IsOverSea = function()
        return false
    end

    XUiPcManager.IsPcServer = function()
        return CS.XUiPc.XUiPcManager.IsPcModeServer()
    end

    -- 设备分辨率,非游戏分辨率
    XUiPcManager.GetDeviceScreenResolution = function()
        local vector = CS.XWin32Api.GetResolutionSize();
        return vector.x, vector.y;
    end

    XUiPcManager.GetTabUiPcResolution = function()
        local config = XUiPcConfig.GetTabUiPcResolution()
        local width, height = XUiPcManager.GetDeviceScreenResolution()
        local result = {}
        for i, size in pairs(config) do
            if size.y <= (height - 10)
                    and size.x <= width
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
        CS.XJoystickLSHelper.ForceResponse = not editing
        XUiPcManager.EditingKey = editing
        CS.XCommonGenericEventManager.NotifyInt(CSEventId.EVENT_EDITING_KEYSET, editing and 1 or 0)
    end

    XUiPcManager.IsEditingKey = function()
        return XUiPcManager.EditingKey
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
        local lastResolution = XUiPcManager.GetLastResolution();        -- 获取上一次设备分辨率
        local lastScreen = XUiPcManager.GetLastScreen();                -- 获取上一次使用的屏幕分辨率 
        local unityScreen = XUiPcManager.GetUnityScreen();              -- 获取Unity写入的设备分辨率
        local length = #resolutions;
		local minResolution = resolutions[1]
        local maxResolution = resolutions[length];
        local noFrame = XUiPcManager.GetLastNoFrame();
        local lastFullScreen = XUiPcManager.GetLastFullScreen();
        local windowedMode = FullScreenMode.Windowed;
        local fullScreenMode = not noFrame and FullScreenMode.ExclusiveFullScreen or FullScreenMode.FullScreenWindow;
        local mode = lastFullScreen and fullScreenMode or windowedMode;
        CS.XLog.Debug("width", width, "height", height, "maxResolution", maxResolution, "minResolution", minResolution, "lastResolution", lastResolution, "lastScreen", lastScreen)
        if width > maxResolution.x or height > maxResolution.y then
            CS.XLog.Debug("不能使用全屏")
            -- compare -- 当获取的屏幕尺寸超过配置表最大值时
            -- 这货不能用全屏, 给他禁掉
            CS.XSettingHelper.ForceWindow = true;
            -- 同时立即设置为窗口模式
            CS.UnityEngine.Screen.fullScreen = false;
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
            XUiPcManager.SetResolution(fitWidth, fitHeight, windowedMode)
        elseif width < lastResolution.width or height < lastResolution.height then
            if (lastScreen.width > minResolution.x and lastScreen.height > minResolution.y) and (width < lastScreen.width or height < lastScreen.height) then
                -- 当前设备分辨率小于上一次使用的屏幕分辨率, 使其全屏
                CS.XLog.Debug("新设备比旧设备分辨率小, 直接使用当前分辨率并全屏", width, height)
                XUiPcManager.SetResolution(width, height, fullScreenMode);
            else
                -- 当前设备分辨率大于上一次使用的屏幕分辨率, 直接使用上一次的作为当前窗口分辨率设置
                CS.XLog.Debug("新设备比旧设备分辨率小, 但是大于上一次窗口分辨率设置, 使用上一次的窗口化分辨率", lastScreen.width, lastScreen.height, mode)
                XUiPcManager.SetResolution(lastScreen.width, lastScreen.height, mode)
            end
            CS.XSettingHelper.ForceWindow = false;
        else
            if unityScreen.width < minResolution.x or unityScreen.height < minResolution.y then
                -- unity读取的尺寸很可能导致条幅屏, 判断是否有正确的缓存值
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

    XUiPcManager.LastResolution = nil
    XUiPcManager.GetLastResolution = function()
        if not XUiPcManager.LastResolution then
            local prefs = PlayerPrefs.GetString("LastResolution", nil);
            if not prefs or prefs == "" then
                XUiPcManager.LastResolution = CS.UnityEngine.Screen.currentResolution
            else
                local empty = CS.XUnityEx.ResolutionEmpty
                local arr = string.Split(prefs, ",")
                empty.width = arr[1]
                empty.height = arr[2]
                XUiPcManager.LastResolution = empty
            end
        end
        return XUiPcManager.LastResolution
    end

    XUiPcManager.LastScreen = nil
    XUiPcManager.GetLastScreen = function()
        if not XUiPcManager.LastScreen then
            local prefs = PlayerPrefs.GetString("LastScreen", nil)
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
    XUiPcManager.GetLastFullScreen = function()
        if not XUiPcManager.LastFullScreen then
            local prefs = PlayerPrefs.GetInt("LastFullScreen", -1)
            if prefs == -1 then
                XUiPcManager.LastFullScreen = CS.UnityEngine.Screen.fullScreen
            else
                XUiPcManager.LastFullScreen = prefs == 1
            end
        end
        return XUiPcManager.LastFullScreen
    end

    XUiPcManager.LastFullScreenMode = nil
    XUiPcManager.GetLastFullScreenMode = function()
        if not XUiPcManager.LastFullScreenMode then
            local prefs = PlayerPrefs.GetInt("LastFullScreenMode", -1);
            if prefs < 0 or prefs > 3 then
                XUiPcManager.LastFullScreenMode = CS.UnityEngine.Screen.fullScreenMode;
            else
                XUiPcManager.LastFullScreenMode = FullScreenMode.__CastFrom(prefs)
            end
        end
        return XUiPcManager.LastFullScreenMode
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

    ---@param width number
    ---@param height number
    ---@param fullScreenMode FullScreenMode
    XUiPcManager.SetResolution = function(width, height, fullScreenMode)
        CS.XSettingHelper.SetResolution(width, height, fullScreenMode)
        XUiPcManager.SaveScreen(width, height)
        XUiPcManager.SaveFullScreen(fullScreenMode == FullScreenMode.FullScreenMode)
        XUiPcManager.SaveFullScreenMode(fullScreenMode)
    end

    XUiPcManager.SaveResolution = function(width, height)
        local empty = CS.XUnityEx.ResolutionEmpty
        empty.width = width;
        empty.height = height
        XUiPcManager.LastResolution = empty
        PlayerPrefs.SetString("LastResolution", width .. "," .. height);
        PlayerPrefs.Save();
    end

    XUiPcManager.SaveScreen = function(width, height)
        local empty = CS.XUnityEx.ResolutionEmpty
        empty.width = width
        empty.height = height
        XUiPcManager.LastScreen = empty
        PlayerPrefs.SetString("LastScreen", width .. "," .. height)
        PlayerPrefs.Save()
    end

    XUiPcManager.SaveFullScreen = function(fullScreen)
        XUiPcManager.LastFullScreen = fullScreen
        PlayerPrefs.SetInt("LastFullScreen", fullScreen and 1 or 0)
        PlayerPrefs.Save()
    end

    XUiPcManager.SaveFullScreenMode = function(fullScreenMode)
        XUiPcManager.LastFullScreenMode = fullScreenMode;
        PlayerPrefs.SetInt("LastFullScreenMode", fullScreenMode);
        PlayerPrefs.Save()
    end

    XUiPcManager.AddCustomUI = function(root)
        CS.XUiManagerExtension.AddCustomUI(root)
    end

    XUiPcManager.RemoveCustomUI = function(root)
        CS.XUiManagerExtension.RemoveCustomUI(root)
    end

    XUiPcManager.Init()
    return XUiPcManager
end
