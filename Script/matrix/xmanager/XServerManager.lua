XServerManager = XServerManager or {}

local Json = require("XCommon/Json")
local LoginTimeOutSecond = CS.XGame.Config:GetInt("LoginTimeOutInterval")
local SERVER_CONNECT_TIME_KEY = "SERVER_CONNECT_TIME_KEY"
local RECENT_TIME_PERIOD = 3600 * 24 * 7
local GetTime = os.time

local CsApplication = CS.XApplication

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

local ChannelServerList = {}

XServerManager.Id = nil
XServerManager.ServerName = nil
XServerManager.LastServerId = nil

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

function XServerManager.SelectChannelServer(notTip)
    ServerList = {}
    local channel = XUserManager.LoginChannel and tostring(XUserManager.LoginChannel) or nil--这里调用获取渠道接口
    local channelServer = nil
    if channel and ChannelServerList[channel] then
        channelServer = ChannelServerList[channel]
    else
        XLog.Debug("pc channel is ".. tostring(channel) .. " , select default server")
        channelServer = ChannelServerList["default"]
    end
    if channelServer then
        channelServer.Id = 1 --渠道服务器列表只有1个
        ServerList[channelServer.Id] = channelServer
        CS.XLog.Debug("pc channel is " .. tostring(channelServer.Name))
    end

    if not ServerList or #ServerList <= 0 then
        if not notTip then
            XLog.Error("Get ChannelServerList error. content = " .. CS.XRemoteConfig.ChannelServerListStr)
        end
        return
    end

    XServerManager.SelectServerAndSort()
end

function XServerManager.Init(cb)
    XServerManager.Id = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.ServerId, 1)
    XServerManager.LastServerId = XServerManager.Id

    ServerList = {}
    ChannelServerList = {}
    if XDataCenter.UiPcManager.IsPcServer() then
        if not string.IsNilOrEmpty(CS.XRemoteConfig.ChannelServerListStr) then
            --CS.XLog.Debug("ChannelServerListStr:" .. CS.XRemoteConfig.ChannelServerListStr)
            local strs = string.Split(CS.XRemoteConfig.ChannelServerListStr, "|")
            for _, value in ipairs(strs) do
                local item = string.Split(value, "#")
                if #item >= 3 then
                    local server = {}
                    --server.Id = i
                    server.Name = item[2]
                    server.LoginUrl = item[3]
                    ChannelServerList[item[1]] = server
                end
            end
            --CS.XLog.Debug("ChannelServerList:" .. XLog.Dump(ChannelServerList))

            XServerManager.SelectChannelServer(true) --先不管三七二十一, 选一个default的, 后续设置渠道id的时候再设置一次
        else
            XLog.Error("Get ChannelServerListStr empty.")
            return
        end
    else
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

        XServerManager.SelectServerAndSort()
    end

    if cb then
        cb()
    end
end

function XServerManager.SelectServerAndSort()
    if XServerManager.Id and ServerList[XServerManager.Id] then
        XServerManager.Select(ServerList[XServerManager.Id])
    else
        XServerManager.Select(ServerList[1])
    end

    XServerManager.UpdateSortedServer()
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
        "&projectId=" .. CS.XHeroSdkAgent.GetAppProjectId() ..
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

function XServerManager.SetAndSelectServerByIp(ip)
    local index = #ServerList + 1
    for i = 1, #ServerList do
        local url = ServerList[i].LoginUrl
        local name = ServerList[i].Name
        if string.match(url, ip) ~= nil or string.match(name, ip) then
            index = i
            break
        end
    end

    if index == #ServerList + 1 then
        local ipValid, ipStr = string.IsIp(ip)
        if not ipValid then
            return false
        end
        XServerManager.InsertTempServer(ip)
    end

    XServerManager.Select(ServerList[index])
    return true
end