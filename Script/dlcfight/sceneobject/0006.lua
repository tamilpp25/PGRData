---@class XSObjVCamAgent
local XSObjVCamAgent = XDlcScriptManager.RegSceneObjScript(0006, "XSObjVCamAgent") --调用使用冒号
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs --调用使用句号

---@param proxy StatusSyncFight.XFightScriptProxy
function XSObjVCamAgent:Ctor(proxy)
    self._proxy = proxy
    self._triggerId = 0
    self._localPlayerNpcId = 0
end

function XSObjVCamAgent:Init()
    self._sceneObj = self._proxy:GetSceneObject()
    self._sceneObjPlaceId = self._proxy:GetSceneObjectPlaceId()
    self._vCamComp = self._sceneObj.VCamComponent
end

---@param dt number @ delta time
function XSObjVCamAgent:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XSObjVCamAgent:HandleEvent(eventType, eventArgs)
end

function XSObjVCamAgent:Terminate()
end

---@param ref number @用于坐标旋转参考的actorId，填-1使用触发者。
---@param follow number @虚拟相机跟随的目标actorId，填-1使用触发者。
---@param lookAt number @虚拟相机看向的目标actorId，填-1使用触发者。
function XSObjVCamAgent:SetActorIds(ref, follow, lookAt)
    self._vCamComp:SetActorIds(ref, follow, lookAt)
    --XLog.Debug(string.format("XSObjVCamAgent.SetActorIds members:%d %d %d ", ref, follow, lookAt))
end

---设置一个回调，在虚拟相机被激活前调用。
---@param callback function
function XSObjVCamAgent:SetCallBackBeforeActivated(callback)
    if type(callback) ~= "function" then
        return
    end

    self._vCamComp.SetActorsCallBack = callback
end

return XSObjVCamAgent