local XDlcScript = XClass(nil, "XDlcScript")

---@param proxy StatusSyncFight.XFightScriptProxy
function XDlcScript:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end

function XDlcScript:Init() --初始化逻辑

end

---@param dt number @ delta time
function XDlcScript:Update(dt) --每帧更新逻辑

end

---@param eventType number
---@param eventArgs userdata
function XDlcScript:HandleEvent(eventType, eventArgs) --事件响应逻辑

end

function XDlcScript:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

return XDlcScript