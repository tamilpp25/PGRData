local Platform = CS.UnityEngine.Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

XServerManager = XServerManager or {}

local Json = require("XCommon/Json")
local LoginTimeOutSecond = CS.XGame.Config:GetInt("LoginTimeOutInterval")
local SERVER_CONNECT_TIME_KEY = "SERVER_CONNECT_TIME_KEY"
local RECENT_TIME_PERIOD = 3600 * 24 * 7
local GetTime = os.time

XServerManager.SERVER_STATE = {
    MAINTAIN = 0, -- 维护
    LOW = 1, -- 畅通
    HIGH = 2, -- 爆满
    CHECK = 3, -- 检测中
    FAIL = 4, -- 失败
}

local ServerList = {}
local SortedList = {}
local TempServerDic = {}
local LastServerCheckTime = {}
local LastServerConnectTime = {}

local AndroidPayCallList = {}
local IosPayCallList = {}
local PcPayCallList = {}

function XServerManager.SplitPayCallList(list, str)
    if str == "" or str == nil then
        return
    end
    local strs = string.Split(str, '#')
    local i = 1
    for _, value in ipairs(strs) do
        list[i] = value
        i = i + 1
    end
end

XServerManager.Id = nil
XServerManager.ServerName = nil

function XServerManager.GetLoginUrl()
    local server = ServerList[XServerManager.Id]
    if not server then
        return nil
    end

    if XMain.IsDebug then
        server.LastTime = GetTime()
        LastServerConnectTime[server.Name] = server.LastTime
        XSaveTool.SaveData(SERVER_CONNECT_TIME_KEY, LastServerConnectTime)
    end

    return server.LoginUrl
end

function XServerManager.Init(cb)
    XServerManager.Id = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.ServerId, 1)
    ServerList = {}
    local i = 1
    local strs = string.Split(CS.XRemoteConfig.ServerListStr, "|")
    for _, value in ipairs(strs) do
        local item = string.Split(value, "#")
        if #item >= 2 then
            local server = {}
            server.Id = i
            server.Name = item[1]
            server.LoginUrl = item[2]

            ServerList[server.Id] = server
            i = i + 1
        end
    end

    if not ServerList or #ServerList <= 0 then
        XLog.Error("Get ServerList error. content = " .. CS.XRemoteConfig.ServerListStr)
        return
    end

    local androidCallbackListStr = CS.XRemoteConfig.AndroidPayCallbackList
    local iosCallbackListStr = CS.XRemoteConfig.IosPayCallbackList
    local pcCallbackListStr = CS.XRemoteConfig.PcPayCallbackList
    XServerManager.SplitPayCallList(AndroidPayCallList, androidCallbackListStr)
    XServerManager.SplitPayCallList(IosPayCallList, iosCallbackListStr)
    XServerManager.SplitPayCallList(PcPayCallList, pcCallbackListStr)

    if XServerManager.Id and ServerList[XServerManager.Id] then
        XServerManager.Select(ServerList[XServerManager.Id])
    else
        XServerManager.Select(ServerList[1])
    end

    XServerManager.UpdateSortedServer()

    if cb then
        cb()
    end
end

function XServerManager.UpdateSortedServer()
    if XMain.IsDebug then
        SortedList = {}
        LastServerConnectTime = XSaveTool.GetData(SERVER_CONNECT_TIME_KEY) or {}
        for _, v in pairs(ServerList) do
            v.LastTime = LastServerConnectTime[v.Name] or 0
            table.insert(SortedList, v)
        end
    end
end

function XServerManager.InsertTempServer(ip)
    if not XMain.IsDebug then
        return false, "该功能仅Debug模式下可使用！"
    end

    local ipValid, ipStr = string.IsIp(ip)
    if not ipValid then
        return false, "请输入合法Ip地址！"
    end

    if TempServerDic[ipStr] then
        return false, "该临时服已存在"
    end

    local tempServer = {
        Id = #ServerList + 1,
        Name = "临时服: " .. ipStr,
        LastTime = 0,
        LoginUrl = string.format("http://%s:2333/api/Login/Login", ipStr),
        IsTempServer = true,
    }

    table.insert(ServerList, tempServer)
    TempServerDic[ipStr] = true
    XServerManager.UpdateSortedServer()

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_SERVER_LIST_CHANGE)
    return true
end

function XServerManager.Select(server)
    if not server then
        XLog.Error("Selected Server is nil.")
        return
    end

    XServerManager.Id = server.Id
    XServerManager.ServerName = server.Name
    CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.ServerId, server.Id)
    if XUserManager.UserId then -- 海外修改
        XSaveTool.SaveData(XPrefs.User_ServerId..XUserManager.UserId, tostring(server.Id))
    end

    if Platform == RuntimePlatform.Android then
        if server.Id > #AndroidPayCallList then
            XLog.Error("支付服务器地址数量与服务器数量不匹配")
            return
        end
        XHgSdkManager.SetCallBackUrl(AndroidPayCallList[server.Id])
    elseif Platform == RuntimePlatform.IPhonePlayer then
        if server.Id > #IosPayCallList then
            XLog.Error("支付服务器地址数量与服务器数量不匹配")
            return
        end
        XHgSdkManager.SetCallBackUrl(IosPayCallList[server.Id])
    elseif Platform == RuntimePlatform.WindowsPlayer then
        if server.Id > #PcPayCallList then
            XLog.Error("支付服务器地址数量与服务器数量不匹配")
        end
        XHgSdkManager.SetCallBackUrl(PcPayCallList[server.Id])
    else
        XLog.Debug("其他平台无需设置支付回调地址")
    end
end

function XServerManager.CheckOpenSelect()
    return ServerList and #ServerList > 1
end

function XServerManager.GetServerList(needSort)
    if not XMain.IsDebug or not needSort then
        return ServerList
    end

    table.sort(SortedList, function(a, b)
        if a.IsTempServer ~= b.IsTempServer then
            return a.IsTempServer
        end

        if GetTime() - a.LastTime < RECENT_TIME_PERIOD
        or GetTime() - b.LastTime < RECENT_TIME_PERIOD then
            return a.LastTime > b.LastTime
        else
            return a.Id < b.Id
        end
    end)

    return SortedList
end

function XServerManager.GetCurServerName()
    return XServerManager.ServerName
end

function XServerManager.TestConnectivity(server, gridCb)
    if not server or not gridCb then return end
    local id = server.Id
    if LastServerCheckTime[id]
    and LastServerCheckTime[id] + LoginTimeOutSecond > GetTime() then
        gridCb()
        return
    end

    ServerList[id].State = XServerManager.SERVER_STATE.CHECK
    LastServerCheckTime[id] = GetTime()
    gridCb()

    local loginUrl = server.LoginUrl
    if not XUserManager.IsNeedLogin() then
        loginUrl = server.LoginUrl ..
        "?loginType=" .. XUserManager.Channel ..
        "&userId=" .. XUserManager.UserId ..
        "&projectId=" .. CS.XHgSdkAgent.GetAppProjectId() ..
        "&token=" .. (XUserManager.Token or "")
    end

    local request = CS.UnityEngine.Networking.UnityWebRequest.Get(loginUrl)
    request.timeout = LoginTimeOutSecond
    CS.XTool.WaitNativeCoroutine(request:SendWebRequest(), function()
        LastServerCheckTime[id] = GetTime()
        if request.isDone and not string.IsNilOrEmpty(request.error) then
            ServerList[id].State = XServerManager.SERVER_STATE.FAIL
            request:Dispose()
            gridCb()
            return
        end

        local result = Json.decode(request.downloadHandler.text)
        if result.code == 1 -- 服务器暂未开放
        or result.code == 8 -- 服务器未开放
        or result.code == 9 -- 服务器已满员
        or result.code == 10 then
            -- 服务器内部错误
            ServerList[id].State = XServerManager.SERVER_STATE.MAINTAIN
            gridCb()
            return
        end
        ServerList[id].State = XServerManager.SERVER_STATE.LOW
        gridCb()
    end)
end