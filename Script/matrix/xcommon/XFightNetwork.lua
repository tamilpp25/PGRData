XFightNetwork = XFightNetwork or {}

function XFightNetwork.Send(handler, request)
    local requestContent, error = XMessagePack.Encode(request)
    if requestContent == nil then
        XLog.Error("Lua.XFightNetwork.Send 函数错误, 客户端发送给服务端的数据编码处理失败, 失败原因：" .. error)
        return
    end

    CS.XFightNetwork.Send(handler, requestContent);
end

function XFightNetwork.Call(handler, request, reply)
    local requestContent, error = XMessagePack.Encode(request)
    if requestContent == nil then
        XLog.Error("Lua.XFightNetwork.Call 函数错误, 客户端发送给服务端的数据编码处理失败, 失败原因： " .. error)
        return
    end

    CS.XFightNetwork.Call(handler, requestContent, function(responseContent)
        local response, err = XMessagePack.Decode(responseContent)
        if response == nil then
            XLog.Error("Lua.XFightNetwork.Call 函数错误, 服务端返回的数据解码失败, 失败原因: " .. err)
            return
        end
        reply(response)
    end)
end