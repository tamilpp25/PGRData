---V2.9魔方嘉年华 关卡逻辑脚本
local XLevelScript100 = XDlcScriptManager.RegLevelLogicScript(100, "XLevelLogicScript100")
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")


--脚本构造函数
---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScript100:Ctor(proxy)
    self._proxy = proxy
    self._playerNpcContainer = XPlayerNpcContainer.New(self._proxy)
end

--初始化
function XLevelScript100:Init()

    XLog.Debug("准备调用Container")
    self._playerNpcContainer:Init()
    XLog.Debug("准备获得玩家列表")
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    XLog.Debug("获得玩家列表完成")
    
    local monId = 8101
    local monPosition = {x=41.65, y=1.04, z=44.17}
    local monRotation = {x=0.0, y=0.0, z=0.0}
    self.monRefId = nil
    XLog.Debug("初始赋值完成")
    self.monRefId = self._proxy:GenerateNpc(1, monId, 2, monPosition, monRotation)
    
    self._triggerOfFalling = 101
    self._trigger102 = 102
    self._trigger103 = 103
    self._trigger104 = 104
    XLog.Debug("Trigger赋值完成")
    
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectTrigger)
    XLog.Debug("Level0100 Logic trigger事件注册完成")

    self._respawnPositionFall = { x=41.46,y=1,z=48.57}
    self._respawnRotationFall = {x=0.0, y=0.0, z=0.0}
end

--事件
---@param eventType number
---@param eventArgs userdata
function XLevelScript100:HandleEvent(eventType, eventArgs)
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)

    XLog.Debug("Level100 handle event:" .. tostring(eventType))
    if (eventType == EWorldEvent.SceneObjectTrigger) then
        XLog.Debug("有trigger被触发了")
        if (eventArgs.SceneObjectId == self._triggerOfFalling)  then
            XLog.Debug("收到来自trigger101的事件")
            if (eventArgs.SourceActorId == self._playerNpcList[1]) then
                self._triggerNpc = self._playerNpcList[1]
                XLog.Debug("1号玩家掉下去了")
            end
            if (eventArgs.SourceActorId == self._playerNpcList[2]) then
                self._triggerNpc = self._playerNpcList[2]
                XLog.Debug("2号玩家掉下去了")
            end
            if (eventArgs.SourceActorId == self._playerNpcList[3]) then
                self._triggerNpc = self._playerNpcList[3]
                XLog.Debug("3号玩家掉下去了")
            end
            XLog.Debug("玩家列表"..table.concat(self._playerNpcList,","))
            XLog.Debug("玩家npcID是"..eventArgs.SourceActorId)
            XLog.Debug("玩家ID是"..self._playerNpcList[1])

            XLog.Debug("准备传送玩家")
            --self._proxy:SetNpcPosition(self._triggerNpc, self._respawnPositionFall, self._respawnRotationFall)
            self._proxy:ResetNpcToCustomSafePoint(self._triggerNpc, 41.46, 1, 48.57)
            XLog.Debug("玩家传送完毕 准备加眩晕buff")
            self._proxy:ApplyMagic(self._triggerNpc, self._triggerNpc, 8101001, 1)     --眩晕         
            XLog.Debug("眩晕buff增加完毕")
            
         end
    end

end
--每帧执行
---@param dt number @ delta time
function XLevelScript100:Update(dt)

end

--脚本终止
function XLevelScript100:Terminate()

end

return XLevelScript100