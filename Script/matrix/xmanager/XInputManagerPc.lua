XInputManagerPcCreator = function ()
    
    local XInputManagerPc = {}    
    
    local CSXInputManager = CS.XInputManager
    local XOperationType = CS.XOperationType
    local XOperationClickType = CS.XOperationClickType
    local CurrentLevel = 0

    XInputManagerPc.Updating = false
    XInputManagerPc.RegisteredKeyMapUi = {}           -- 按键对应的ui函数
    XInputManagerPc.RegisteredKeyPressMapUi = {}      -- 连续按下对应的ui函数
    XInputManagerPc.RegisteredKeyMapFunc = {}         -- 按键对应的函数
    XInputManagerPc.RegisteredKeyPressMapFunc = {}    -- 连续按下对应的函数

    XInputManagerPc.Init = function()
        CSXInputManager.UnregisterOnClick(XOperationType.System, XInputManagerPc.OnSystemClick)
        CSXInputManager.RegisterOnClick(XOperationType.System, XInputManagerPc.OnSystemClick)

        CSXInputManager.UnregisterOnPress(XOperationType.System, XInputManagerPc.OnSystemKeyPress)
        CSXInputManager.RegisterOnPress(XOperationType.System, XInputManagerPc.OnSystemKeyPress)
    end

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

    XInputManagerPc.Init()
    return XInputManagerPc
end
