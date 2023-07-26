local XDlcScript = XClass(nil, "XDlcScript")

local _cameraResRefTable = {}

function XDlcScript.GetCameraResRefTable()
    return _cameraResRefTable
end

function XDlcScript:Ctor()

end

function XDlcScript:Init()

end

---@param dt number @ delta time
function XDlcScript:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XDlcScript:HandleEvent(eventType, eventArgs)
    --todo: 处理关卡加载完成等较为常用的事件，再调用特定的可重载的的某个函数（例如OnLevelLoadComplete）来处理
end

function XDlcScript:Terminate()

end

return XDlcScript