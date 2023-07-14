XBackManagerCreator = function()
    ---@class XBackManager

    local XBackManager = {}

    local UiStacks
    local UiDict

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

    local function IsOnBtnClick()
        if XLuaUiManager.IsUiShow("UiLoading") or
                XLuaUiManager.IsUiShow("UiAssignInfo") or -- loading 界面 边界公约
                XDataCenter.GuideManager.CheckIsInGuidePlus() or
                XLuaUiManager.IsUiShow("UiBlackScreen") then
            return false
        end
        return true
    end

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
        XLog.Error("[XBackManager] 比较siblingOrder错误")
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

    function XBackManager.OnUiDisableAbandoned()
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
    function XBackManager.OnUiDisable()
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

        end
        if PerformButtonOnTopByLayer(CsXUiType.System) then
            return
        end
        -- XDataCenter.UiPcManager.OnEscBtnClick() -- en 的返回键还是~而不是esc

        if XDataCenter.GuideManager.CheckIsInGuide() then
            local button = XDataCenter.GuideManager.getButton()
            if _DictBtnBack[button.name] then
                XDataCenter.GuideManager.NextStep()
                --OnPointerClick
                PerformClick(button.transform)
            end
        end
    end

    function XBackManager.Init()
        UiStacks = XStack.New()
        UiDict = {}
    end

    XBackManager.Init()
    return XBackManager
end