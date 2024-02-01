---@class XDlcJoinWorldData
local XDlcJoinWorldData = XClass(nil, "XDlcJoinWorldData")

function XDlcJoinWorldData:Ctor(data)
    self._IpAddress = nil
    self._Port = nil
    self._WorldNo = nil
    self._Token = nil
    self._ReJoinWorldExpireTime = nil
    self._Result = nil
    self._IsClear = true
    self:SetData(data)
end 

function XDlcJoinWorldData:SetData(data)
    self:_Init(data)
end

function XDlcJoinWorldData:GetIpAddress()
    return self._IpAddress
end

function XDlcJoinWorldData:GetPort()
    return self._Port
end

function XDlcJoinWorldData:GetWorldNo()
    return self._WorldNo
end

function XDlcJoinWorldData:GetToken()
    return self._Token
end

function XDlcJoinWorldData:GetReJoinExpireTime()
    return self._ReJoinWorldExpireTime
end

function XDlcJoinWorldData:GetResult()
    return self._Result
end

function XDlcJoinWorldData:Clear()
    self._IsClear = true
    self._IpAddress = nil
    self._Port = nil
    self._WorldNo = nil
    self._Token = nil
    self._ReJoinWorldExpireTime = nil
    self._Result = nil
end

function XDlcJoinWorldData:IsClear()
    return self._IsClear
end

function XDlcJoinWorldData:_Init(data)
    if data then
        self._IsClear = false
        self._IpAddress = data.IpAddress
        self._Port = data.Port
        self._WorldNo = data.WorldNo
        if not XTool.IsNumberValid(self._WorldNo) then
            XLog.Error("重连数据WorldNo = " .. self._WorldNo)
        end
        self._Token = data.Token
        self._ReJoinWorldExpireTime = data.ReJoinWorldExpireTime
        self._Result = data.Result
    end
end

return XDlcJoinWorldData