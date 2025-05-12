XNetwork = XNetwork or {}

if XMain.IsEditorDebug then 
    CS.XNetwork.IsShowNetLog = false
    XNetwork.IsShowNetLog = true
    XNetwork.IsShowHearBeat = false
else
    XNetwork.IsShowNetLog = CS.XNetwork.IsShowNetLog
    XNetwork.IsShowHearBeat = true
end

local Ip
local Port
local LastIp
local LastPort
local XRpc = XRpc
local IsDebug = XMain.IsEditorDebug
local ShieldedProtocol = {}
local NeedShieldProtocol = false

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
    -- 讨论后先屏蔽 - 【#173976】屏蔽表格sha1校验的输出
    -- TipTableDiff(data.Sha1Table)
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
            --if XNetwork.IsShowNetLog then
            CS.XLog.Debug("PlayerId=" .. request.PlayerId .. ", Token=" .. request.Token .. ", LastMsgSeqNo=" .. request.LastMsgSeqNo)
            --end

            local request_func
            request_func = function()
                --放在外层，避免重连协议比其他协议慢返回
                XEventManager.DispatchEvent(XEventId.EVENT_NETWORK_RECONNECT)
                XNetwork.Call("ReconnectRequest", request, function(res)
                    -- XLog.Debug("服务器返回断线重连 测试，当作失败。" .. tostring(res.Code))
                    -- XLoginManager.OnReconnectFailed()
                    -- do return end
                    if res.Code ~= XCode.Success then
                        --if XNetwork.IsShowNetLog then
                            CS.XLog.Debug("服务器返回断线重连失败。" .. tostring(res.Code))
                        --end
                        XLoginManager.OnReconnectFailed()
                    else
                        XNetwork.Send("ReconnectAck")
                        --if XNetwork.IsShowNetLog then
                            CS.XLog.Debug(string.format("服务器返回断线重连成功。新的ReconnectToken：%s", res.ReconnectToken))
                        --end
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
                        if XDataCenter.UiPcManager.IsPc() then
                            CS.XTool.WaitCoroutine(CS.XApplication.CoDialog(CS.XApplication.GetText("Tip"),
                                CS.XStringEx.Format(CS.XApplication.GetText("PCUpdateApplication"), CS.XInfo.Version), cancelCb, 
                                CS.XApplication.Exit))
                        else
                            CS.XTool.WaitCoroutine(CS.XApplication.CoDialog(CS.XApplication.GetText("Tip"),
                                CS.XStringEx.Format(CS.XApplication.GetText("UpdateApplication"), CS.XInfo.Version), cancelCb, 
                            function() CS.XTool.WaitCoroutine(CS.XApplication.GoToUpdateURL(GetAppUpgradeUrl()), nil) end))
                        end
                    elseif response.Code == XCode.LoginDocumentVersionError then
                        XUiManager.DialogTip("", CS.XTextManager.GetCodeText(response.Code), XUiManager.DialogType.OnlySure, nil, function()
                            CS.XApplication.Exit()
                        end)
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
    CS.XNetwork.Connect(ip, tonumber(port), bReconnect)
end

function XNetwork.Send(handler, request)
    if IsDebug then
        if handler == "" or (string.find(handler, " ")) then
            XLog.Error("发送协议名错误！handler: " .. tostring(handler) .. ", request:", request)
            return
        end
    end
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

function XNetwork.Call(handler, request, reply, isEncoded, exReply, shieldReply)
    if IsDebug then
        if handler == "" or (string.find(handler, " ")) then
            XLog.Error("发送协议名错误！handler: " .. tostring(handler) .. ", request:", request)
            return
        end
    end
    -- 检查是否是屏蔽协议
    if NeedShieldProtocol and ShieldedProtocol[handler] then
        XUiManager.TipMsg(CS.XGame.ClientConfig:GetString("ShieldedProtocol"))
        if shieldReply then shieldReply() end
        return
    end

    if IsDebug then
        XRpc.DebugPrint(XRpc.DEBUG_TYPE.Send_Call, handler, isEncoded and XMessagePack.Decode(request) or request)
    end
    local requestContent, error
    if isEncoded == true then
        requestContent = request
    else
        requestContent, error = XMessagePack.Encode(request)
        if requestContent == nil then
            XLog.Error("XNetwork.Call 函数错误, 客户端发送给服务端的数据编码处理失败, 失败原因： " .. error)
            return
        end
    end

    if XLoginManager.CheckPrintHeartbeatLog() and handler == "HeartbeatRequest" then
        XLog.Error("上次心跳包收发异常，本次打印发送心跳包请求")
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

        if XLoginManager.CheckPrintHeartbeatLog() and handler == "HeartbeatRequest" then
            XLog.Error("上次心跳包收发异常，本次打印成功收到消息！")
        end
        reply(response)
    end, exReply)
end

function XNetwork.CallWithAutoHandleErrorCode(handler, request, reply, isEncoded)
    XNetwork.Call(handler, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if reply then reply(res) end
    end, isEncoded)
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
