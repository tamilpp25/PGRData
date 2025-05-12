---@class X3CProxyAgency : XAgency
---@field private _Model X3CProxyModel
---@field private _X3CProxy X3CProxy
local X3CProxyAgency = XClass(XAgency, "X3CProxyAgency")

local Print3CMsg = false
local LocalKey = "X3C_PRINT_ENABLE"

local CmdType = {
    --Lua发送到C#
    L2C = 1,
    --C#发送到Lua
    C2L = 2,
}

local CmdColor = {
    [CmdType.L2C] = "#33FFFF",
    [CmdType.C2L] = "#FFFF33"
}

local CmdPrefix = {
    [CmdType.L2C] = "L2C: ",
    [CmdType.C2L] = "C2L: "
}

function X3CProxyAgency:OnInit()
    --初始化一些变量
    self._HandlerTab = {}
    self._CmdId2CmdName = {}
    self._X3CProxy = CS.X3CProxy.Instance
    
    self:CheckPrintEnable()
end

function X3CProxyAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function X3CProxyAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------
---@param cmd number 指令id
---@param func function 函数
---@param obj any
function X3CProxyAgency:RegisterHandler(cmd, func, obj)
    if self._HandlerTab[cmd] then
        XLog.Error("请勿重复注册handler, cmd: " .. tostring(cmd))
        return 
    end
    self._HandlerTab[cmd] = {func, obj}
end

--- 取消注册
---@param cmd number  
--------------------------
function X3CProxyAgency:UnRegisterHandler(cmd)
    if not cmd then
        return
    end
    self._HandlerTab[cmd] = nil
end

function X3CProxyAgency:ClearHandlers()
    self._HandlerTab = {}
end

function X3CProxyAgency:ClearAll()
    self._HandlerTab = {}
    self._X3CProxy = nil
end

---向C#层发送事件, 并接收C#的返回值, 注意：参数data与返回值尽量使用local, 使用非local变量，可能会导致C#修改到原数据
---@param cmd number 指令id
---@param data table 参数
---@return any
function X3CProxyAgency:Send(cmd, data)
    local ok, receive = pcall(self._X3CProxy.RequestCSharp, self._X3CProxy, cmd, data)
    if not ok then
        XLog.Error("x3d send error", receive)
        return nil
    end
    --local receive = self._X3CProxy:RequestCSharp(cmd, data)
    self:PrintMsg(CmdType.L2C, cmd, data, receive)
    return receive
end


---接收C#的事件, 并返回值给到C#层 注意：参数data尽量使用local, 使用非local变量，可能会导致C#修改到原数据
---@param cmd number 指令id
---@param data table 参数
---@return any
function X3CProxyAgency:Receive(cmd, data)
    local handler = self._HandlerTab[cmd]
    if not handler then
        XLog.Warning("无法找到handler, cmd:" .. tostring(cmd))
        return nil
    end
    local ok, receive = pcall(handler[1], handler[2], data)
    if not ok then
        XLog.Error("x3c receive error", receive)
        return nil
    end
    self:PrintMsg(CmdType.C2L, cmd, data, receive)
    return receive
end

----------public end----------

----------private start----------
function X3CProxyAgency:OnRelease()
    self:ClearAll()
end

function X3CProxyAgency:ResetAll()
    self._HandlerTab = {}
end

----------private end----------

function X3CProxyAgency:CheckPrintEnable()
    Print3CMsg = CS.XApplication.Debug and XSaveTool.GetData(LocalKey)
    return Print3CMsg
end

function X3CProxyAgency:SetPrintEnable(value)
    Print3CMsg = value
    XSaveTool.SaveData(LocalKey, value)
end

function X3CProxyAgency:PrintMsg(cmdType, cmd, sendData, receiveData)
    if not Print3CMsg then
        return
    end
    if not self._X3CProxy.GetCmdNameByCmdId then
        self:SetPrintEnable(false)
        return
    end
    local color = CmdColor[cmdType]
    local name = self._CmdId2CmdName[cmd]
    if string.IsNilOrEmpty(name) then
        name = self._X3CProxy:GetCmdNameByCmdId(cmd)
        self._CmdId2CmdName[cmd] = name
    end
    local prefix = CmdPrefix[cmdType]
    local log = string.format("<color=%s>%s%s</color>\nSend:", color, prefix, name)
    XLog.Debug(log, sendData, "Receive:", receiveData)
end

return X3CProxyAgency