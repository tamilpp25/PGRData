XRpc = XRpc or {}

------- 方便调试协议的打印 ------
local IsPrintLuaRpc = false
if XMain.IsEditorDebug then 
    CS.XNetwork.IsShowNetLog = false
end
XRpc.IgnoreRpcNames = { ["HeartbeatRequest"] = true, ["HeartbeatResponse"] = true, ["KcpHeartbeatRequest"] = true, ["KcpHeartbeatResponse"] = true }
XRpc.DEBUG_TYPE = {
    Send = "Send",
    Send_Call = "Send_Call",
    Recv = "Recv",
    Recv_Call = "Recv_Call",
}
XRpc.DEBUG_TYPE_COLOR = {
    Send = "#5bf54f",
    Send_Call = "#5bf54f",
    Recv = "#42a8fa",
    Recv_Call = "#42a8fa",
}
-- 浅色主题用的字体颜色
-- XRpc.DEBUG_TYPE_COLOR = {
--     Send = "green",
--     Send_Call = "green",
--     Recv = "blue",
--     Recv_Call = "blue",
-- }
XRpc.DebugKeyWords = {"GuildBoss"} -- 【关键协议】

function XRpc.CheckLuaNetLogEnable()
    IsPrintLuaRpc = XMain.IsEditorDebug and XSaveTool.GetData(XPrefs.LuaNetLog)
    return IsPrintLuaRpc
end

function XRpc.SetLuaNetLogEnable(value)
    IsPrintLuaRpc = value
    XSaveTool.SaveData(XPrefs.LuaNetLog, IsPrintLuaRpc)
end

function XRpc.DebugPrint(debugType, rpcName, request)
    if not IsPrintLuaRpc or XRpc.IgnoreRpcNames[rpcName] then
        return
    end
    local color = XRpc.DEBUG_TYPE_COLOR[debugType]
    if XRpc.DebugKeyWords then
        for i, keyWord in ipairs(XRpc.DebugKeyWords) do
            if (string.find(rpcName, keyWord)) then
                rpcName = "<color=red>" .. rpcName .. "</color>" -- 【关键协议】显示为红色  可本地自定义
                break
            end
        end
    end
    XLog.Debug("<color=" .. color .. "> " .. debugType .. ": " .. rpcName .. ", content: </color>" .. XLog.Dump(request))
end
-------------------------------

local handlers = {}
local IsHotReloadOpen = XMain.IsEditorDebug

function XRpc.Do(name, content)
    local handler = handlers[name]
    if handler == nil then
        XLog.Error("XRpc.Do 函数错误, 没有定义相应的接收服务端数据的函数, 函数名是: " .. name)
        return
    end

    local request, error = XMessagePack.Decode(content)
    if request == nil then
        XLog.Error("XRpc.Do 函数错误, 服务端返回的数据解码错误, 错误原因: " .. error)
        return
    end

    XRpc.DebugPrint(XRpc.DEBUG_TYPE.Recv, name, request)
    handler(request)
end

setmetatable(XRpc, {
    __newindex = function(_, name, handler)
        if type(name) ~= "string" then
            XLog.Error("XRpc.register 函数错误, 参数name必须是string类型, type: " .. type(name))
            return
        end

        if type(handler) ~= "function" then
            XLog.Error("XRpc.register 函数错误, 注册的接收服务端数据的函数的值必须是函数类型, type: " .. type(handler))
            return
        end

        if handlers[name] and not IsHotReloadOpen then
            XLog.Error("XRpc.register 函数错误, 存在相同名字的接收服务端数据的函数, 名字是: " .. name)
            return
        end
        handlers[name] = handler
    end,
})

XRpc.TestRequest = function(request)
    XLog.Warning(request);
end