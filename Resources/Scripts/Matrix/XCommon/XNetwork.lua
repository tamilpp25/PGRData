XNetwork = XNetwork or {}

local Ip
local Port
local LastIp
local LastPort
local XRpc = XRpc
local IsDebug = XMain.IsEditorDebug
local ShieldedProtocol = {}
local NeedShieldProtocol = false

XNetwork.NetworkMode = {
    Auto = 1,
    Ipv4 = 2,
    Ipv6 = 3,
}
XNetwork.NetworkModeKey = "NETWORK_MODE_KEY"

local function GetIpAndPort()
    return Ip, Port
end

function XNetwork.SetGateAddress(ip, port)
    Ip = ip
    Port = port
end

function XNetwork.CheckIsChangedGate()
    return LastIp ~= Ip or LastPort ~= Port
end

local LogTableFunc = IsDebug and XLog.Debug or XLog.Error

local function TipTableDiff(sha1Table)
    if not CS.XTableManager.NeedSha1 then -- 开发环境下不解析Sha1
        return
    end

    XTool.LoopMap(CS.XTableManager.Sha1Table, function(k, v)
        local sha1 = sha1Table[k]
        if not sha1 then
            LogTableFunc("多余表格: " .. k)
            return
        end

        if v ~= sha1 then
            LogTableFunc("差异表格: " .. k .. ", 客户端sha1: " .. v .. " , 服务端sha1: " .. sha1)
        end

        sha1Table[k] = nil
    end)

    for k, _ in pairs(sha1Table) do
        LogTableFunc("缺少表格: " .. k)
    end
end

XRpc.NotifyCheckTableSha1 = function(data)
    TipTableDiff(data.Sha1Table)
end

function XNetwork.ConnectGateServer(args)
    if not args then
        return
    end
    
    if IsDebug then
        XRpc.CheckLuaNetLogEnable()
    end
    
    CS.XNetwork.OnConnect = function()
        if args.IsReconnect then
            local request = { PlayerId = XPlayer.Id, Token = XUserManager.ReconnectedToken, LastMsgSeqNo = CS.XNetwork.ServerMsgSeqNo }
            if CS.XNetwork.IsShowNetLog then
                XLog.Debug("PlayerId=" .. request.PlayerId .. ", Token=" .. request.Token .. ", LastMsgSeqNo=" .. request.LastMsgSeqNo)
            end

            local request_func
            request_func = function()
                XNetwork.Call("ReconnectRequest", request, function(res)
                    if res.Code == XCode.ReconnectAgain then
                        if CS.XNetwork.IsShowNetLog then
                            XLog.Debug("服务器返回再次重连。" .. tostring(res.Code))
                        end

                        XScheduleManager.ScheduleOnce(function()
                            request_func()
                        end, 1000)

                    elseif res.Code ~= XCode.Success then
                        if CS.XNetwork.IsShowNetLog then
                            XLog.Debug("服务器返回断线重连失败。" .. tostring(res.Code))
                        end
                        XLoginManager.DoDisconnect()
                    else
                        XNetwork.Send("ReconnectAck")
                        if CS.XNetwork.IsShowNetLog then
                            XLog.Debug("服务器返回断线重连成功。")
                        end
                        XUserManager.ReconnectedToken = res.ReconnectToken
                        if args.ConnectCb then
                            args.ConnectCb()
                        end

                        if res.OfflineMessages then
                            CS.XNetwork.ProcessReconnectMessageList(res.OfflineMessages)
                        end
                        CS.XNetwork.ReCall(res.RequestNo)
                    end
                end)
            end

            request_func()
        else
            XNetwork.Call("HandshakeRequest", {
                ApplicationVersion = CS.XRemoteConfig.ApplicationVersion,
                DocumentVersion = CS.XRemoteConfig.DocumentVersion,
                Sha1 = CS.XTableManager.Sha1
            }, function(response)
                if args.RemoveHandshakeTimerCb then
                    args.RemoveHandshakeTimerCb()
                end

                if response.Code ~= XCode.Success then
                    local msgTab = {}
                    msgTab.error_code = response.Code
                    CS.XRecord.Record(msgTab, "24019", "HandshakeRequest")
                    if response.Code == XCode.GateServerNotOpen then
                        local localTimeStr = XTime.TimestampToLocalDateTimeString(response.UtcOpenTime, "yyyy-MM-dd HH:mm(G'M'T z)")
                        local context = CS.XTextManager.GetCodeText(response.Code) .. localTimeStr
                        XUiManager.SystemDialogTip("", context, XUiManager.DialogType.OnlySure)
                    elseif response.Code == XCode.LoginApplicationVersionError then
                        -- 处于调试模式时进错服显示取消按钮，否则不显示
                        local cancelCb = XMain.IsDebug and function() end or nil
                        CS.XTool.WaitCoroutine(CS.XApplication.CoDialog(CS.XApplication.GetText("Tip"),
                        CS.XStringEx.Format(CS.XApplication.GetText("UpdateApplication"),
                        CS.XInfo.Version), cancelCb, function() CS.XTool.WaitCoroutine(CS.XApplication.GoToUpdateURL(GetAppUpgradeUrl()), nil) end))
                    else
                        XUiManager.DialogTip("", CS.XTextManager.GetCodeText(response.Code), XUiManager.DialogType.OnlySure)
                    end

                    if response.Code == XCode.LoginTableError then
                        XLog.Error("配置表客户端和服务端不一致")
                        TipTableDiff(response.Sha1Table)
                    end

                    CS.XNetwork.Disconnect()
                    return
                end

                CS.XRecord.Record("24020", "HandshakeRequestSuccess")
                if args.ConnectCb then
                    args.ConnectCb()
                end
            end)
        end
    end
    CS.XNetwork.OnDisconnect = function()
        if args.DisconnectCb then
            args.DisconnectCb()
        end
    end
    CS.XNetwork.OnRemoteDisconnect = function()
        if args.RemoteDisconnectCb then
            args.RemoteDisconnectCb()
        end
    end
    CS.XNetwork.OnError = function(error)
        if args.ErrorCb then
            args.ErrorCb(error)
        end
    end
    CS.XNetwork.OnMessageError = function()
        if args.MsgErrorCb then
            args.MsgErrorCb()
        end
    end
    CS.XNetwork.OnReconnectRequestFrequently = function()
        if args.ReconnectRequestFrequentlyCb then
            args.ReconnectRequestFrequentlyCb()
        end
    end

    local ip, port
    if args.IsReconnect then
        ip, port = LastIp, LastPort
    else
        ip, port = GetIpAndPort()
    end

    XNetwork.ConnectServer(ip, port, args.IsReconnect)
end

function XNetwork.ConnectServer(ip, port, bReconnect)
    if not ip or not port then
        return
    end

    LastIp, LastPort = ip, port
    local networkMode = XSaveTool.GetData(XNetwork.NetworkModeKey) or XNetwork.NetworkMode.Auto
    if networkMode == XNetwork.NetworkMode.Auto then
        CS.XNetwork.Connect(ip, tonumber(port), bReconnect, CS.XNetwork.NetworkMode.Auto)
    elseif networkMode == XNetwork.NetworkMode.Ipv4 then
        CS.XNetwork.Connect(ip, tonumber(port), bReconnect, CS.XNetwork.NetworkMode.Ipv4)
    elseif networkMode == XNetwork.NetworkMode.Ipv6 then
        CS.XNetwork.Connect(ip, tonumber(port), bReconnect, CS.XNetwork.NetworkMode.Ipv6)
    else -- Auto保底
        CS.XNetwork.Connect(ip, tonumber(port), bReconnect, CS.XNetwork.NetworkMode.Auto)
    end
end

function XNetwork.Send(handler, request)
    -- 检查是否是屏蔽协议
    if NeedShieldProtocol and ShieldedProtocol[handler] then
        XUiManager.TipMsg(CS.XGame.ClientConfig:GetString("ShieldedProtocol"))
        return
    end
    local requestContent, error = XMessagePack.Encode(request)
    if IsDebug then
        XRpc.DebugPrint(XRpc.DEBUG_TYPE.Send, handler, requestContent)
    end

    if requestContent == nil then
        XLog.Error("XNetwork.Send 函数错误, 客户端发送给服务端的数据编码处理失败, 失败原因：" .. error)
        return
    end

    CS.XNetwork.Send(handler, requestContent);
end

function XNetwork.Call(handler, request, reply)
    -- 检查是否是屏蔽协议
    if NeedShieldProtocol and ShieldedProtocol[handler] then
        XUiManager.TipMsg(CS.XGame.ClientConfig:GetString("ShieldedProtocol"))
        return
    end
    if IsDebug then
         XRpc.DebugPrint(XRpc.DEBUG_TYPE.Send_Call, handler, request)
    end

    local requestContent, error = XMessagePack.Encode(request)
    if requestContent == nil then
        XLog.Error("XNetwork.Call 函数错误, 客户端发送给服务端的数据编码处理失败, 失败原因： " .. error)
        return
    end

    CS.XNetwork.Call(handler, requestContent, function(responseContent)
        local response, err = XMessagePack.Decode(responseContent)
        if response == nil then
            XLog.Error("XNetwork.Call 函数错误, 服务端返回的数据解码失败, 失败原因: " .. err)
            return
        end
        
        if IsDebug then
            XRpc.DebugPrint(XRpc.DEBUG_TYPE.Recv_Call, handler, response)
        end
        
        reply(response)
    end)
end

--================
--设置协议屏蔽列表
--@param protocolList:屏蔽协议名列表
--================
function XNetwork.SetShieldedProtocolList(protocolList)
    if not protocolList then return end
    ShieldedProtocol = {}
    NeedShieldProtocol = false
    for _, protocolName in pairs(protocolList) do
        NeedShieldProtocol = true
        ShieldedProtocol[protocolName] = true
    end
end
