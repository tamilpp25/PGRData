local Time = CS.UnityEngine.Time
---@class XGuildDormNetwork
local XGuildDormNetwork = XClass(nil, "XGuildDormNetwork")

function XGuildDormNetwork:Ctor()
    self.CsNetwork = CS.XGuildDormNetwork()
    self.IpAddress = nil
    self.TcpPort = nil
    self.Token = nil
    self.KcpPort = nil
    self.KcpConv = nil
    self.HeartbeatTimeout = 10000
    self.HeartbeatInterval = 1000
    self.HeartbeatTimer = nil
    self.MaxDisconnectTime = 600
    self.MaxReconnectTimer = nil
    self.ReconnectTimer = nil
    self.ReconnectInterval = 3000
end

function XGuildDormNetwork:InitTimeConfig()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormConfig, 1)
    self.HeartbeatTimeout = config.HeartbeatTimeout
    self.HeartbeatInterval = config.HeartbeatInterval
    self.MaxDisconnectTime = config.MaxDisconnectTime
    self.ReconnectInterval = config.ReconnectInterval
end

-- 请求心跳
function XGuildDormNetwork:RequestHeartbeat()
    --if not self.CsNetwork.IsConnected then
    --    return
    --end
    -- 测试断线重连
    if XGuildDormConfig.DebugOpenReconnect
        and XGuildDormConfig.DebugReconnectSign then
        self:StartReconnect()
        return
    end
    -- 注册心跳最大超时检测
    self.HeartbeatTimer = XScheduleManager.ScheduleOnce(function()
        if self.CsNetwork.IsShowLog then
            XLog.Debug("guild heartbeat time out.")
        end
        self:StartReconnect()
    end, self.HeartbeatTimeout)
    if self.CsNetwork.IsShowLog then
        XLog.Debug("guild heartbeat request.")
    end
    -- 开始请求心跳
    self:Call("GuildDormHeartbeatRequest", {}, function(res)
        -- 取消心跳最大超时检测
        XScheduleManager.UnSchedule(self.HeartbeatTimer)
        if self.CsNetwork.IsShowLog then
            XLog.Debug("guild heartbeat response.")
        end
        if res.Code ~= XCode.Success then
            XLog.Debug("guild heartbeat faild", res.Code)
            self:StartReconnect()
            return
        end
        -- 注册间隔心跳检测
        self.HeartbeatTimer = XScheduleManager.ScheduleOnce(function()
            self:RequestHeartbeat()
        end, self.HeartbeatInterval)
    end, false)
end

-- 开始重连
function XGuildDormNetwork:StartReconnect()
    if self.CsNetwork.IsShowLog then
        XLog.Debug("XGuildDormNetwork 开始重连")
    end
    -- 取消心跳的监听
    if self.HeartbeatTimer then
        XScheduleManager.UnSchedule(self.HeartbeatTimer)
        self.HeartbeatTimer = nil
    end
    if self.ReconnectTimer then
        XScheduleManager.UnSchedule(self.ReconnectTimer)
        self.ReconnectTimer = nil
    end
    -- 断开连接
    self.CsNetwork:Disconnect()
    local startReconnectTime = Time.realtimeSinceStartup
    -- 默认取消最大重连时间检测
    if self.MaxReconnectTimer then
        XScheduleManager.UnSchedule(self.MaxReconnectTimer)
        self.MaxReconnectTimer = nil
    end
    -- 重新注册最大重连时间检测
    self.MaxReconnectTimer = XScheduleManager.ScheduleForever(function()
        if Time.realtimeSinceStartup - startReconnectTime > self.MaxDisconnectTime then
            if self.CsNetwork.IsShowLog then
                XLog.Debug("XGuildDormNetwork 超过最大重连时间")
            end
            XUiManager.TipErrorWithKey("GuildDormOverMaxReconnectTime")
            XDataCenter.GuildDormManager.Dispose()
            XLuaUiManager.RunMain()
        end
    end, 1000)
    self:DoReconnect()
end 

-- 处理重连
function XGuildDormNetwork:DoReconnect()
    if self.CsNetwork.IsConnected then
        return
    end
    -- 注册间隔重连检测
    self.ReconnectTimer = XScheduleManager.ScheduleOnce(function()
        if self.CsNetwork.IsShowLog then
            XLog.Debug("XGuildDormNetwork 断线重连响应超时")
        end
        self.CsNetwork:Disconnect()
        self:DoReconnect()
    end, self.ReconnectInterval)
    if self.CsNetwork.IsShowLog then
        XLog.Debug("XGuildDormNetwork 开始断线重连")
    end
    self.CsNetwork:Disconnect()
    XDataCenter.GuildDormManager.RequestLoadRoom(nil, nil, function(errorCode)
        if errorCode == XGuildDormConfig.ErrorCode.Success then
            -- 断开重连相关的检测，表示全部重连完成
            if self.ReconnectTimer then
                XScheduleManager.UnSchedule(self.ReconnectTimer) 
                self.ReconnectTimer = nil
            end
            if self.MaxReconnectTimer then
                XScheduleManager.UnSchedule(self.MaxReconnectTimer)
                self.MaxReconnectTimer = nil
            end
            if XGuildDormConfig.DebugOpenReconnect then
                XGuildDormConfig.DebugReconnectSign = false
            end
            XDataCenter.GuildDormManager.HandleReConnectSuccess()
        elseif errorCode == XGuildDormConfig.ErrorCode.PreEnterFailed
            or errorCode == XGuildDormConfig.ErrorCode.EnterFailed then
            XDataCenter.GuildDormManager.Dispose()
            XLuaUiManager.RunMain()
        end
    end)
end

function XGuildDormNetwork:Call(handler, request, reply, handleError)
    if handleError == nil then handleError = true end
    local requestContent, error = XMessagePack.Encode(request)
    if requestContent == nil then
        XLog.Error("Lua.XGuildDormNetwork.Call 函数错误, 客户端发送给服务端的数据编码处理失败, 失败原因： " .. error)
        return
    end
    self.CsNetwork:Call(handler, requestContent, function(responseContent)
        local response, err = XMessagePack.Decode(responseContent)
        if response == nil then
            XLog.Error("Lua.XGuildDormNetwork.Call 函数错误, 服务端返回的数据解码失败, 失败原因: " .. err)
            return
        end
        if handleError and response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        if XMain.IsEditorDebug then
            XRpc.DebugPrint(XRpc.DEBUG_TYPE.Recv_Call, handler, response)
        end
        reply(response)
    end)
end

function XGuildDormNetwork:Disconnect()
    -- 取消若干时间函数
    if self.HeartbeatTimer then
        XScheduleManager.UnSchedule(self.HeartbeatTimer)
        self.HeartbeatTimer = nil
    end
    if self.MaxReconnectTimer then
        XScheduleManager.UnSchedule(self.MaxReconnectTimer)
        self.MaxReconnectTimer = nil
    end
    if self.ReconnectTimer then
        XScheduleManager.UnSchedule(self.ReconnectTimer)
        self.ReconnectTimer = nil
    end
    -- 清除所有的Mask
    XLuaUiManager.ClearAllMask(false)
    -- 真正断开公会宿舍相关网络
    self.CsNetwork:Disconnect()
end

function XGuildDormNetwork:RequestPlayAction(actionId)
    self.CsNetwork:SendPlayAction(actionId)
end

-- function XGuildDormNetwork:RequestSyncPlayerState(x, z, angle, state)
--     if not self.CsNetwork.IsConnected then
--         return
--     end
--     self.CsNetwork:SendSyncData(x, z, angle, state)
-- end

function XGuildDormNetwork:GetCsNetwork()
    return self.CsNetwork
end

return XGuildDormNetwork