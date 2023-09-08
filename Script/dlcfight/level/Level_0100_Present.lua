---V2.9魔方嘉年华 关卡表现脚本
local XLevelScript100 = XDlcScriptManager.RegLevelPresentScript(100, "XLevelPresentScript100")


--脚本构造函数
---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScript100:Ctor(proxy)
    self._proxy = proxy

end

--初始化
function XLevelScript100:Init()

    self._proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, false)
    self._proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnAttack, false)
    self._proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false)
    
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectTrigger)
    XLog.Debug("Level0100 Present trigger事件注册完成")

end

--事件
---@param eventType number
---@param eventArgs userdata
function XLevelScript100:HandleEvent(eventType, eventArgs)

    XLog.Debug("Level0100 Present handle event:" .. tostring(eventType))
    if eventType == EWorldEvent.SceneObjectTrigger then
        XLog.Debug(string.format("Level0100 Present 有trigger被触发了:%d %d", eventArgs.TriggerId, eventArgs.SceneObjectId))
    end

end

--每帧执行
---@param dt number @ delta time
function XLevelScript100:Update(dt)
end

--脚本终止
function XLevelScript100:Terminate()
    XLog.Debug("Level0100 Present Terminate")
end

return XLevelScript100