---Hunt01Boss战专用测试关
local XLevel9001 = XDlcScriptManager.RegLevelLogicScript(9001, "XLevel9001")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs
local Tool = require("Level/Common/XLevelTools")

local _cameraResRefTable = {

}

function XLevel9001.GetCameraResRefTable()
    return _cameraResRefTable
end

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevel9001:Ctor(proxy)
    self._proxy = proxy

    self._levelSigh = 599013

    self._jumpFunDebug = false
    self._jumpFunStarted = false
    self._jumpFunLetBoss2Ready = false
    self._jumpFunStartSign = 5990130

    self._localPlayerNpcId = FuncSet.GetLocalPlayerNpcId()
    self._bossId = nil ---boss的id

    self._switches = {
        {
            placeId = 4,
            agent = nil,
            object = self,
            func = self.JumpFunDebugEnable,
            param = nil,
            times = -1,
            defaultEnable = true
        },
    }
end

function XLevel9001:Init()
    FuncSet.AddBuff(self._localPlayerNpcId, self._levelSigh)
    -- 配置场景中开关
    self._switches = Tool.InitSwitch(self._switches)
    XLog.Debug("初始化场景中开关完成")
    self._proxy:RegisterSceneObjectTriggerEvent(18, 1) --boss跳到中央塔的位置的检测
    self._proxy:RegisterSceneObjectTriggerEvent(19, 1) --boss停留在场地中央等待的区域检测
end

---@param dt number @ delta time
function XLevel9001:Update(dt)
    --调试功能：强制关闭跳跳乐
    if self._jumpFunDebug then
        if FuncSet.IsKeyDown(18) then
            XLog.Debug("按键输入信号球5,boss退出被操状态，2#9000=0")
            FuncSet.SetNpcNoteInt(self._bossId, 90000, 0)
        elseif FuncSet.IsKeyDown(19) then
            XLog.Debug("按键输入信号球6，boss进入被操状态，2#9000=1")
            FuncSet.SetNpcNoteInt(self._bossId, 90000, 1)
        elseif FuncSet.IsKeyDown(20) then
            XLog.Debug("按键输入信号球7，boss放大绝，2#9000=10")
            FuncSet.SetNpcNoteInt(self._bossId, 90000, 10)
        elseif FuncSet.IsKeyDown(21) then
            XLog.Debug("按键输入信号球8，boss蓄力失败被肛，2#9000=20")
            FuncSet.SetNpcNoteInt(self._bossId, 90000, 20)
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XLevel9001:HandleEvent(eventType, eventArgs)
    self.Super.HandleEvent(self, eventType, eventArgs)
    if eventType == EScriptEvent.SceneObjectTrigger then
        XLog.Debug("XLevelBossFight1 SceneObjectTriggerEvent:"
                .. " TouchType " .. tostring(eventArgs.TouchType)
                .. " SourceActorId " .. tostring(eventArgs.SourceActorId)
                .. " SceneObjectId " .. tostring(eventArgs.SceneObjectId)
                .. " TriggerId " .. tostring(eventArgs.TriggerId)
                .. " TriggerState " .. tostring(eventArgs.TriggerState)
                .. " Log自关卡"
        )
        if self._jumpFunLetBoss2Ready then
            if eventArgs.SceneObjectId == 18 and eventArgs.TriggerState == 1 and
                    not self._jumpFunStarted and eventArgs.SourceActorId == self._bossId then
                self:StartJumpFun()
            end
        end
        if eventArgs.SceneObjectId == 19 and eventArgs.TriggerState == 1 and
                eventArgs.SourceActorId == self._localPlayerNpcId then
            FuncSet.SetNpcNoteInt(self._localPlayerNpcId, 30011, self._bossId) --设置目标
            FuncSet.SetNpcNoteInt(self._localPlayerNpcId, 2409, 3) --模拟手动点击
            XLog.Debug("自动锁定目标")
        end
    end
end

function XLevel9001:JumpFunDebugEnable()
    self._jumpFunDebug = not self._jumpFunDebug

    if self._jumpFunDebug then
        if self._bossId == nil then
            self._allNpc = FuncSet.GetNpcList()
            for i, v in pairs(self._allNpc) do
                if FuncSet.GetNpcCamp(v) == 2 then
                    self._bossId = v
                    break
                end
            end
        end
        self._jumpFunLetBoss2Ready = true
        FuncSet.SetNpcNoteFloat3(self._bossId, 9001, 60, 3, 60)
        FuncSet.AddBuff(self._localPlayerNpcId, self._jumpFunStartSign)
        XLog.Debug("测试版跳跳乐开始")
    else
        self:EndJumpFun()
    end
end

---开始跳跳乐
function XLevel9001:StartJumpFun()
    self._jumpFunStarted = true

    -- 怪物开始蓄力，可以被qte
    FuncSet.SetNpcNoteInt(self._bossId, 90000, 1)
    XLog.Debug("boss已就位")
end

---结束跳跳乐
function XLevel9001:EndJumpFun()

    self._jumpFunLetBoss2Ready = false
    self._jumpFunStarted = false


    --boss解除状态
    FuncSet.SetNpcNoteInt(self._bossId, 90000, 0)
    FuncSet.SetNpcNoteFloat3(self._bossId, 9001, 0, 0, 0)

    --玩家回复锁定能力
    FuncSet.RemoveBuff(self._localPlayerNpcId, self._jumpFunStartSign)

    XLog.Debug("测试版跳跳乐结束")
end

function XLevel9001:Terminate()

end

return XLevel9001