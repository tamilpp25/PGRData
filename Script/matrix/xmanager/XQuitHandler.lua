local ExitingGame = false

XQuitHandler = XQuitHandler or {}

XQuitHandler.OnEscBtnClick = function()
    if XLuaUiManager.IsUiShow("UiGuide") then
        -- 新手引导当做系统界面处理
        XQuitHandler.ExitGame()
        return
    end

    if XLuaUiManager.IsUiShow("UiFightButtonSettings") then
        return
    end

    -- 战斗中
    local fight = CS.XFight.Instance
    if fight then
        if XLuaUiManager.IsUiShow("UiSet") then
            XQuitHandler.ExitGame()
            return;
        end
        if fight.IsAlreadyCloseLoading and fight.State == CS.XFightState.Fight then
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
    -- loading 界面
    if XLuaUiManager.IsUiShow("UiLoading") then
        return
    end
    -- loading 界面 边界公约
    if XLuaUiManager.IsUiShow("UiAssignInfo") then
        return
    end

    if XQuitHandler.IsEditingKey() then
        return
    end

    --退出游戏
    XQuitHandler.ExitGame()
end

XQuitHandler.ExitGame = function()
    -- 它自己
    -- if XLuaUiManager.IsUiShow("UiDialogExitGame") then
    --     return
    -- end
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

XQuitHandler.SetExitingGame = function(value)
    ExitingGame = value
end

XQuitHandler.GetExitingGame = function()
    return ExitingGame
end

XQuitHandler.SetEditingKeyState = function(editing)
    XQuitHandler.EditingKey = editing
end

XQuitHandler.IsEditingKey = function()
    return XQuitHandler.EditingKey
end