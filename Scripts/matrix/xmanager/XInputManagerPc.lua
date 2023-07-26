XInputManagerPcCreator = function ()
    --- @class XInputManagerPc
    local XInputManagerPc = {}    
    
    local CSXInputManager = CS.XInputManager
    local XOperationType = CS.XOperationType
    local XOperationClickType = CS.XOperationClickType
    local CurrentLevel = 0

    XInputManagerPc.Init = function()
        CSXInputManager.UnregisterOnClick(XOperationType.System, XInputManagerPc.OnSystemClick)
        CSXInputManager.RegisterOnClick(XOperationType.System, XInputManagerPc.OnSystemClick)

        CSXInputManager.UnregisterOnPress(XOperationType.System, XInputManagerPc.OnSystemKeyPress)
        CSXInputManager.RegisterOnPress(XOperationType.System, XInputManagerPc.OnSystemKeyPress)

        XInputManagerPc._InitActivityGameKeyListener()
    end
    
    ---切换当前操作模式
    XInputManagerPc.SetCurOperationType = function(operationType)
        CSXInputManager.SetCurOperationType(operationType)
    end

    ---还原当前操作模式
    XInputManagerPc.ResumeCurOperationType = function()
        CSXInputManager.SetCurOperationType(CSXInputManager.BeforeOperationType)
    end
    
    --region System - 系统界面按键监听
    XInputManagerPc.Updating = false
    XInputManagerPc.RegisteredKeyMapUi = {}           -- 按键对应的ui函数
    XInputManagerPc.RegisteredKeyPressMapUi = {}      -- 连续按下对应的ui函数
    XInputManagerPc.RegisteredKeyMapFunc = {}         -- 按键对应的函数
    XInputManagerPc.RegisteredKeyPressMapFunc = {}    -- 连续按下对应的函数

    XInputManagerPc.IncreaseLevel = function()
        CurrentLevel = CurrentLevel + 1
    end
    
    XInputManagerPc.DecreaseLevel = function()
        CurrentLevel = CurrentLevel - 1
        -- 避免掉至0级以下导致大部分监听失效
        if CurrentLevel < 0 then
            XLog.Error("错误的不成对调用导致监听等级将至0以下")
            CurrentLevel = 0
        end
    end

    XInputManagerPc.GetCurrentLevel = function()
        return CurrentLevel
    end

    XInputManagerPc.SetCurrentLevel = function(value)
        CurrentLevel = value
    end

    XInputManagerPc.RegisterButton = function(key, ui, level)
        if not level then
            level = CurrentLevel
        end

        if key and ui then
            local func = XInputManagerPc.GetButtonFunc(ui)
            if not func then
                return
            end
            -- 后续考虑可否将ui上的函数提取出来直接加入到FuncMap中
            XInputManagerPc.RegisteredKeyMapUi[key] = {}
            XInputManagerPc.RegisteredKeyMapUi[key].UI = ui;
            XInputManagerPc.RegisteredKeyMapUi[key].Level = CurrentLevel
        end
    end

    XInputManagerPc.UnregisterButton = function(key)
        if key and XInputManagerPc.RegisteredKeyMapUi[key] then
            XInputManagerPc.RegisteredKeyMapUi[key] = nil
        end
    end

    XInputManagerPc.RegisterFunc = function(key, func, level)
        if not level then
            level = CurrentLevel
        end
        if key and func then
            XInputManagerPc.RegisteredKeyMapFunc[key] = {}
            XInputManagerPc.RegisteredKeyMapFunc[key].Func = func
            XInputManagerPc.RegisteredKeyMapFunc[key].Level = CurrentLevel
        end
    end

    XInputManagerPc.UnregisterFunc = function(key)
        if key and XInputManagerPc.RegisteredKeyMapFunc[key] then
            XInputManagerPc.RegisteredKeyMapFunc[key] = nil
        end
    end

    XInputManagerPc.RegisterPressButton = function(key, ui, level)
        if not level then
            level = CurrentLevel
        end
        if key and ui then
            local func = XInputManagerPc.GetButtonFunc(ui)
            if not func then
                return
            end
            XInputManagerPc.RegisteredKeyPressMapUi[key] = {}
            XInputManagerPc.RegisteredKeyPressMapUi[key].UI = ui
            XInputManagerPc.RegisteredKeyPressMapUi[key].Level = CurrentLevel 
        end
    end

    XInputManagerPc.UnregisterPressButton = function(key)
        if key and XInputManagerPc.RegisteredKeyPressMapUi[key] then
            XInputManagerPc.RegisteredKeyPressMapUi[key] = nil
        end
    end

    XInputManagerPc.RegisterPressFunc = function(key, func, level)
        if not level then
            level = CurrentLevel
        end
        if key and func then
            XInputManagerPc.RegisteredKeyPressMapFunc[key] = {}
            XInputManagerPc.RegisteredKeyPressMapFunc[key].Func = func
            XInputManagerPc.RegisteredKeyPressMapFunc[key].Level = CurrentLevel
        end
    end

    XInputManagerPc.UnregisterPressFunc = function(key)
        if key and XInputManagerPc.RegisteredKeyPressMapFunc[key]  then
            XInputManagerPc.RegisteredKeyPressMapFunc[key] = nil
        end
    end

    XInputManagerPc.OnSystemClick = function(inputDevice, key, type)
        if CS.XUiManagerExtension.Masked then
            return
        end
        if type == XOperationClickType.KeyDown then
            -- key 是int
            local keyCode = CS.XUiPc.XUiPcCustomKeyEnum.__CastFrom(key)

            if keyCode and XInputManagerPc.RegisteredKeyMapUi[keyCode] then
                local unit = XInputManagerPc.RegisteredKeyMapUi[keyCode]
                if unit.Level >= CurrentLevel then
                    local ui = unit.UI
                    local func = XInputManagerPc.GetButtonFunc(ui)
                    func()
                end
            end
            
            if keyCode and XInputManagerPc.RegisteredKeyMapFunc[keyCode] then
                local unit = XInputManagerPc.RegisteredKeyMapFunc[keyCode]
                if unit.Level >= CurrentLevel then
                    local func = unit.Func
                    func()
                end
            end
        end
    end

    XInputManagerPc.OnSystemKeyPress = function(inputDevice, key)
        if CS.XUiManagerExtension.Masked then
            return
        end
        local keyCode = CS.XUiPc.XUiPcCustomKeyEnum.__CastFrom(key)

        if keyCode and XInputManagerPc.RegisteredKeyPressMapUi[keyCode] then
            local unit = XInputManagerPc.RegisteredKeyPressMapUi[keyCode]
            if unit.Level >= CurrentLevel then
                local ui = unit.UI
                local func = XInputManagerPc.GetButtonFunc(ui)
                func()
            end
        end

        if keyCode and XInputManagerPc.RegisteredKeyPressMapFunc[keyCode] then
            local unit = XInputManagerPc.RegisteredKeyPressMapFunc[keyCode]
            if unit.Level >= CurrentLevel then
                local func = unit.Func
                func()
            end
        end
    end

    XInputManagerPc.GetButtonFunc = function(ui)
        local type = ui.gameObject:GetComponent("XUiButton");
        if type ~= nil then
            return ui.CallBack
        else
            type = ui.gameObject:GetComponent("Button")
            if type ~= nil then
                return ui.onClick
            end
        end
        return nil
    end
    --endregion
    
    
    --region Public - ActivityGame - 活动小游戏按键监听
    XInputManagerPc.RegisterActivityGameKeyPressFunc = function(key, func, level)
        if not XInputManagerPc._CheckHasPressListener() then
            CSXInputManager.RegisterOnPress(XOperationType.ActivityGame, XInputManagerPc._OnActivityGameKeyPress)
        end
        XInputManagerPc._RegisterMapFunc(key, XInputManagerPc._RegisteredAGKeyPressMap, func, level)
    end

    XInputManagerPc.RegisterActivityGameKeyPressBtn = function(key, btn, level)
        local func = XInputManagerPc.GetButtonFunc(btn)
        XInputManagerPc.RegisterActivityGameKeyPressFunc(key, func, level)
    end

    XInputManagerPc.UnregisterActivityGameKeyPress = function(key)
        XInputManagerPc._RegisteredAGKeyPressMap[key] = nil
        if not XInputManagerPc._CheckHasPressListener() then
            CSXInputManager.UnregisterOnPress(XOperationType.ActivityGame, XInputManagerPc._OnActivityGameKeyPress)
        end
    end

    XInputManagerPc.RegisterActivityGameKeyDownFunc = function(key, func, level)
        if not XInputManagerPc._CheckHasClickListener() then
            CSXInputManager.RegisterOnClick(XOperationType.ActivityGame, XInputManagerPc._OnActivityGameKeyClick)
        end
        XInputManagerPc._RegisterMapFunc(key, XInputManagerPc._RegisteredAGKeyDownMap, func, level)
    end

    XInputManagerPc.RegisterActivityGameKeyDownBtn = function(key, btn, level)
        local func = XInputManagerPc.GetButtonFunc(btn)
        XInputManagerPc.RegisterActivityGameKeyDownFunc(key, func, level)
    end

    XInputManagerPc.UnregisterActivityGameKeyDown = function(key)
        XInputManagerPc._RegisteredAGKeyDownMap[key] = nil
        if not XInputManagerPc._CheckHasClickListener() then
            CSXInputManager.UnregisterOnClick(XOperationType.ActivityGame, XInputManagerPc._OnActivityGameKeyClick)
        end
    end

    XInputManagerPc.RegisterActivityGameKeyUpFunc = function(key, func, level)
        if not XInputManagerPc._CheckHasClickListener() then
            CSXInputManager.RegisterOnClick(XOperationType.ActivityGame, XInputManagerPc._OnActivityGameKeyClick)
        end
        XInputManagerPc._RegisterMapFunc(key, XInputManagerPc._RegisteredAGKeyUpMap, func, level)
    end

    XInputManagerPc.RegisterActivityGameKeyUpBtn = function(key, btn, level)
        local func = XInputManagerPc.GetButtonFunc(btn)
        XInputManagerPc.RegisterActivityGameKeyUpFunc(key, func, level)
    end

    XInputManagerPc.UnregisterActivityGameKeyUp = function(key)
        XInputManagerPc._RegisteredAGKeyUpMap[key] = nil
        if not XInputManagerPc._CheckHasClickListener() then
            CSXInputManager.UnregisterOnClick(XOperationType.ActivityGame, XInputManagerPc._OnActivityGameKeyClick)
        end
    end
    --endregion


    --region Private - ActivityGame
    XInputManagerPc._RegisteredAGKeyDownMap = {}     -- 活动游戏按下键位监听
    XInputManagerPc._RegisteredAGKeyPressMap = {}    -- 活动游戏按住键位监听
    XInputManagerPc._RegisteredAGKeyUpMap = {}       -- 活动游戏抬起键位监听

    XInputManagerPc._InitActivityGameKeyListener = function()
        XInputManagerPc._RegisteredAGKeyDownMap = {}
        XInputManagerPc._RegisteredAGKeyPressMap = {}
        XInputManagerPc._RegisteredAGKeyUpMap = {}
        XInputManagerPc._ReleaseActivityGameKeyListener()
    end

    ---当活动游戏按键被按时
    XInputManagerPc._OnActivityGameKeyClick = function(inputDevice, key, type)
        if not key then
            return
        end
        if type == XOperationClickType.KeyDown then
            local unit = XInputManagerPc._RegisteredAGKeyDownMap[key]
            if unit and unit.Level >= CurrentLevel and unit.Func then
                unit.Func()
            end
        elseif type == XOperationClickType.KeyUp then
            local unit = XInputManagerPc._RegisteredAGKeyUpMap[key]
            if unit and unit.Level >= CurrentLevel and unit.Func then
                unit.Func()
            end
        end
    end

    ---当活动游戏按键被按住时
    XInputManagerPc._OnActivityGameKeyPress = function(inputDevice, key)
        local unit = XInputManagerPc._RegisteredAGKeyPressMap[key]
        if unit and unit.Level >= CurrentLevel and unit.func then
            unit.func()
        end
    end

    XInputManagerPc._CheckHasPressListener = function()
        return next(XInputManagerPc._RegisteredAGKeyPressMap)
    end

    XInputManagerPc._CheckHasClickListener = function()
        return next(XInputManagerPc._RegisteredAGKeyDownMap) or next(XInputManagerPc._RegisteredAGKeyUpMap)
    end

    XInputManagerPc._RegisterMapFunc = function(key, map, func, level)
        if not level then
            level = CurrentLevel
        end
        if key and func then
            map[key] = { }
            map[key].Level = level
            map[key].Func = func
        end
    end

    XInputManagerPc._ReleaseActivityGameKeyListener = function()
        CSXInputManager.UnregisterOnClick(XOperationType.ActivityGame, XInputManagerPc._OnActivityGameKeyClick)
        CSXInputManager.UnregisterOnPress(XOperationType.ActivityGame, XInputManagerPc._OnActivityGameKeyPress)
    end
    --endregion

    XInputManagerPc.Init()
    return XInputManagerPc
end
