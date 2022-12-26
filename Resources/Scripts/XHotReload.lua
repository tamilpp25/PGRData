-- 用于运行时热重载LUA逻辑，热键F3，在XDataCenter中初始化的相关Manager文件中涉及数据的改动需要重登或断线重连后生效(仅editor + debug模式下生效)
XHotReload = XHotReload or {}

local function updateFunc(newFunc, oldFunc)
    assert("function" == type(newFunc))
    assert("function" == type(oldFunc))

    local newUpvalueDic = {}
    for i = 1, math.huge do
        local name, newValue = debug.getupvalue(newFunc, i)
        if not name then break end
        newUpvalueDic[name] = newValue
    end

    for i = 1, math.huge do
        local name = debug.getupvalue(oldFunc, i)
        if not name then break end
        local newValue = newUpvalueDic[name]
        if newValue then
            debug.setupvalue(oldFunc, i, newValue)
        end
    end
end

local updateTable
function updateTable(newTable, oldTable)
    if "table" ~= type(oldTable) then return end
    if "table" ~= type(newTable) then return end

    for key, newValue in pairs(newTable) do
        local oldValue = oldTable[key]
        local typeValue = type(newValue)

        if typeValue == "table" then
            updateTable(newValue, oldValue)
        elseif typeValue == "function" then
            updateFunc(newValue, oldValue)
        end
        oldTable[key] = newValue--此处未处理newTable中值数量少于oldTable的情况
    end

    local oldMeta = debug.getmetatable(oldTable)
    local newMeta = debug.getmetatable(newTable)
    if type(oldMeta) == "table" and type(newMeta) == "table" then
        updateTable(newMeta, oldMeta)
    end
end

local function TryRunInitConfig(fileName)
    local _, endPos = string.find(fileName, "XConfig/")
    if not endPos or endPos < 0 then return end

    local className = string.sub(fileName, endPos + 1)
    local class = rawget(_G, className)
    if not class then return end

    if class.Init then class.Init() end
end

local function TryReplaceManager(filePath)
    local _, endPos = string.find(filePath, "XManager/")
    if not endPos or endPos < 0 then return end
    local name = string.sub(filePath, endPos + 1)

    local creatorName = string.format("%sCreator", name)
    local managerVar = rawget(_G, creatorName) or rawget(_G, name)
    if type(managerVar) == "function" then
        local newManager = managerVar()
        updateTable(newManager, XDataCenter[name])
    elseif type(managerVar) == "table" and managerVar.Init then
        managerVar.Init()
        XLog.Debug(string.format("已重新运行%s的Init", name))
    end
end

function XHotReload.Reload(fileName)
    if not XMain.IsEditorDebug then return end

    --local info = debug.getinfo(2)
    if not package.loaded[fileName] then
        XLog.Error("XHotReload.Reload reload file error: file never loaded, fileName is: ", fileName)
        return
    end

    local oldModule = package.loaded[fileName]
    package.loaded[fileName] = nil

    local ok, err = pcall(require, fileName)
    if not ok then
        package.loaded[fileName] = oldModule
        XLog.Error("XHotReload.Reload reload file error: ", err)
        return
    end

    local newModule = package.loaded[fileName]
    if "table" ~= type(newModule) then
        TryRunInitConfig(fileName)--全局函数中只处理Config文件
    end
    updateTable(newModule, oldModule)
    UpdateClassType(newModule, oldModule)

    if "boolean" == type(newModule) then
        TryReplaceManager(fileName) --改变XDataCenter所指向的Manager
    end

    package.loaded[fileName] = oldModule
    XLog.Debug("kkkttt XHotReload.Reload suc, fileName is: ", fileName)
end

-- 部分表在Manager里读取
function XHotReload.InitMgrTab()
    if not XMain.IsDebug then return end
    XReadOnlyTable.HotLoad = true
    --XNewRoleShowManager.Init()
    --XTipManager.Init()
    XConditionManager.Init()
    XFightUiManager.Init()
    XLoginManager.Init()
    XPlayerManager.Init()
    XResetManager.Init()
    XRobotManager.Init()
    XRoomSingleManager.Init()

    XFunctionManager.Init()
    XModelManager.Init()
    XRewardManager.Init()
    XReadOnlyTable.HotLoad = false

    CS.XGame.ClientConfig:Init("Client/Config/ClientConfig.tab")
    CS.XGame.Config:Init("Share/Config/Config.tab")
end