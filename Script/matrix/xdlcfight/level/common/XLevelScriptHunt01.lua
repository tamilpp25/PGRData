---@class XLevelScript0013 13关本地脚本，暂时在角色这里跑
local XLevelScriptHunt01 = XClass(nil, "XLevelScriptHunt01")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs
local TowerConfig = require("XDLCFight/Level/LevelConfig/Hunt01BossFightConfig").Towers -- 读取场景物体的配置数据
local Tool = require("XDLCFight/Level/Common/XLevelTools")
local Timer = require("XDLCFight/Level/Common/XTaskScheduler")

---@param proxy StatusSyncFight.XScriptLuaProxy
---@param npc number
function XLevelScriptHunt01:Ctor(proxy, npc)
    self._proxy = proxy
    self._timer = Timer.New()

    self._levelConfirmed = false ---是否确实是这关

    self._npc = npc
    self._boss = nil

    self._camLockAnchorIndex = 25003 ---相机选中的勾点

    self._npcCamLock0Index = 2402 ---两个中任意一个参数存在且非0时，角色镜头锁定怪物
    self._npcCamLock1Index = 2102
    self._npcCamLock0 = false
    self._npcCamLock1 = false ---角色镜头是否锁定怪物

    self._bossLockTrigger = 17 ---boss等待区域，用于开关玩家自动锁定boss的判断
    self._playerInBossLockTrigger = false
    self._bossLockTriggerRegistered = false
    self._towerLandTriggerRegistered = false

    self._jumpFunStarted = false
    self._levelSigh = 599013
    self._jumpFunStartSign = 5990130

    self._fakeFinishSign = 5990140
    self._removeFakeFinish = 5990141

    self._playerFocusAnchor = nil
    self._playerLandTower = nil

    self._closeFightUISign = 5000007
    self._FightUIActive = true

    self._currentLevelId = FuncSet.GetCurrentLevelId()

    if self._currentLevelId == 0013 or self._currentLevelId == 0014 or self._currentLevelId == 0015 or self._currentLevelId == 0016 then
        self._levelConfirmed = true
        XLog.Debug("<color=#F0D800>[SceneHunt01 BOSS战本地模块]</color>" .. tostring(self._currentLevelId) .. "关玩家本地模块上线")
        self._initialized = true
    end

    --[[    self._proxy:RegisterNpcEvent(EDlcScriptEvent.NpcCastSkill, self._npc)
        self._proxy:RegisterNpcEvent(EDlcScriptEvent.NpcExitSkill, self._npc)]]

end

function XLevelScriptHunt01:Update(dt)
    if not self._initialized then
        return
    end

    if not self._levelConfirmed then
        return
    end

    self._timer:Update(dt)

    if self._currentLevelId == 0013 or self._currentLevelId == 0014 or self._currentLevelId == 0016 then
        if not self._jumpFunStarted then
            if FuncSet.CheckBuffByKind(self._npc, self._jumpFunStartSign) then
                -- 跳跳乐开始
                XLog.Debug("<color=#F0D800>[黑龙BOSS战本地模块]</color>玩家" .. tostring(self._npc) .. "跳跳乐模块已开启")
                FuncSet.ShowTip(13002)
                self._jumpFunStarted = true
                if not self._bossLockTriggerRegistered then
                    self._proxy:RegisterSceneObjectTriggerEvent(self._bossLockTrigger, 1) --boss停留在场地中央等待的区域检测
                    self._bossLockTriggerRegistered = true
                end

                if not self._towerLandTriggerRegistered then
                    for _, tower in pairs(TowerConfig) do
                        self._proxy:RegisterSceneObjectTriggerEvent(tower.placeId, 3)
                    end -- 注册所有塔的SpearUnusableTrigger的监听，用来作为玩家是否在塔之上的判断条件之一
                    self._towerLandTriggerRegistered = true
                end

                FuncSet.SetNpcNoteInt(self._npc, 2400, 2) --禁用锁定怪物
                FuncSet.SetNpcNoteFloat(self._npc, 40000, 60) --关卡专用QTE时长
                FuncSet.RemoveNpcFocusTarget(self._npc) --解除锁定
                self._allNpc = FuncSet.GetNpcList()
                for _, v in pairs(self._allNpc) do
                    if FuncSet.GetNpcCamp(v) == 2 then
                        self._boss = v
                        break
                    end
                end
            end
        elseif not FuncSet.CheckBuffByKind(self._npc, self._jumpFunStartSign) then
            -- 跳跳乐结束
            XLog.Debug("<color=#F0D800>[黑龙BOSS战本地模块]</color>玩家" .. tostring(self._npc) .. "跳跳乐模块已关闭")
            self._jumpFunStarted = false
            FuncSet.SetNpcNoteInt(self._npc, 2400, 0)
        end
    end

    if self._currentLevelId == 0014 then
        if FuncSet.CheckBuffByKind(self._npc, self._fakeFinishSign) then
            XLog.Debug("<color=#F0D800>[黑龙BOSS战本地模块]</color>玩家" .. tostring(self._npc) .. "出示健康码，开始装模做样")
            FuncSet.ApplyMagic(self._npc, self._npc, self._removeFakeFinish, 1)
            self:FakeLevelFinish()
            self._timer:Schedule(4, true, FuncSet.SetFakeSettleActive)
            self._timer:Schedule(8, false, FuncSet.SetFakeSettleActive)
        end
    end

    if not self._FightUIActive then
        if not FuncSet.CheckBuffByKind(self._npc, self._closeFightUISign) then
            Tool.SetFightUiActive(true)
            XLog.Debug("<color=#F0D800>[黑龙BOSS战本地模块]</color>玩家" .. tostring(self._npc) .. "开启FightUI")
            self._FightUIActive = true
        end
    elseif self._FightUIActive then
        if FuncSet.CheckBuffByKind(self._npc, self._closeFightUISign) then
            Tool.SetFightUiActive(false)
            XLog.Debug("<color=#F0D800>[黑龙BOSS战本地模块]</color>玩家" .. tostring(self._npc) .. "关闭FightUI")
            self._FightUIActive = false
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XLevelScriptHunt01:HandleEvent(eventType, eventArgs)
    --[[    if eventType == EDlcScriptEvent.SceneObjectTrigger then
            print("XLevelBossFight1 SceneObjectTriggerEvent:"
                    .. " TouchType " .. tostring(eventArgs.TouchType)
                    .. " SourceActorId " .. tostring(eventArgs.SourceActorId)
                    .. " SceneObjectId " .. tostring(eventArgs.SceneObjectId)
                    .. " TriggerId " .. tostring(eventArgs.TriggerId)
                    .. " TriggerState " .. tostring(eventArgs.TriggerState)
                    .. " Log自角色的关卡模块"
            )
        end]]
    if not self._levelConfirmed then
        return
    end
    if not self._jumpFunStarted then
        return
    end

    if eventType == EScriptEvent.SceneObjectTrigger and eventArgs.SourceActorId == self._npc then
        if eventArgs.SceneObjectId == self._bossLockTrigger then
            if eventArgs.TriggerState == 1 then
                --XLog.Debug("<color=#F0D800>[黑龙BOSS战本地模块]</color>进入自动锁范围，解锁玩家锁定怪物限制")
                self._playerInBossLockTrigger = true
                FuncSet.SetNpcNoteInt(self._npc, 2400, 0)
            elseif eventArgs.TriggerState == 2 then
                --XLog.Debug("<color=#F0D800>[黑龙BOSS战本地模块]</color>退出自动锁范围，限制玩家锁定怪物")
                self._playerInBossLockTrigger = false
                FuncSet.RemoveNpcFocusTarget(self._npc)
                FuncSet.SetNpcNoteInt(self._npc, 2400, 2)
            end
        elseif eventArgs.TriggerState == ESceneObjectTriggerState.Enter and eventArgs.TriggerId == 3 then
            XLog.Debug("<color=#F0D800>[黑龙BOSS战本地模块]</color>玩家进入塔" .. eventArgs.SceneObjectId)
            self._playerLandTower = eventArgs.SceneObjectId
        elseif eventArgs.TriggerState == ESceneObjectTriggerState.Exit and eventArgs.TriggerId == 3 then
            XLog.Debug("<color=#F0D800>[黑龙BOSS战本地模块]</color>玩家退出塔" .. eventArgs.SceneObjectId)
            self._playerLandTower = nil
        end
    elseif eventType == EScriptEvent.NpcCastSkill and eventArgs.LauncherId == self._npc then
        --角色使用猎矛
        if eventArgs.SkillId == 100241 or eventArgs.SkillId == 101439 or eventArgs.SkillId == 100736 then
            -- 玩家放出对勾点猎锚第一段 读取玩家猎矛勾选的对象
            self._playerFocusAnchor = FuncSet.GetNpcNoteInt(self._npc, self._camLockAnchorIndex)
            --print("<color=#F0D800>[黑龙BOSS战本地模块]</color>缓存玩家" .. tostring(self._npc) .. "勾取对象： " .. tostring(self._playerFocusAnchor))
            FuncSet.RemoveNpcFocusTarget(self._npc)
        end
    elseif eventType == EScriptEvent.NpcExitSkill and eventArgs.LauncherId == self._npc then
        if eventArgs.SkillId == 100242 or eventArgs.SkillId == 101440 or eventArgs.SkillId == 100737 then
            if self._playerInBossLockTrigger then
                --自动锁定boss
                --print("<color=#F0D800>[黑龙BOSS战本地模块]</color>触发玩家自动锁定boss")
                FuncSet.SetNpcNoteInt(self._npc, 30011, self._boss) --设置目标
                FuncSet.SetNpcNoteInt(self._npc, 2409, 3) --模拟手动点击
            elseif self._playerFocusAnchor ~= nil and self._playerLandTower ~= nil then
                --锁定下一座塔
                self:FocusNextTower()
            end
        end
    end
end

---猎矛的时候锁定下一座塔
function XLevelScriptHunt01:FocusNextTower()
    if TowerConfig[self._playerFocusAnchor].next == nil then
        return
    end
    local focusId = self:GetNearestTower(TowerConfig[self._playerFocusAnchor].next)
    if focusId ~= nil then
        local uuID = FuncSet.GetSceneObjectUUID(focusId)
        self._timer:Schedule(0.1, self, self.TempFocus, uuID)
        XLog.Debug("<color=#F0D800>[黑龙BOSS战本地模块]</color>玩家当前目标：" .. self._playerFocusAnchor .. "   锁定：" .. focusId)
    end
    self._playerFocusAnchor = nil
end

---暂时镜头锁定到下一个塔
function XLevelScriptHunt01:TempFocus(id)
    FuncSet.SetNpcFocusTarget(self._npc, id)
end

---计算角度最小的塔
function XLevelScriptHunt01:GetNearestTower(towerIdSet)
    local nearestId = 0
    local nearestAngle = 360
    for i, id in pairs(towerIdSet) do
        local position = FuncSet.GetSceneObjectPosition(id)
        local angle = FuncSet.GetCameraAngleFromPos(position, false)
        if angle < nearestAngle then
            nearestAngle = angle
            nearestId = id
        end
    end
    return nearestId
end

function XLevelScriptHunt01:FakeLevelFinish()
    FuncSet.ApplyMagic(self._npc, self._npc, 715678, 1)
    FuncSet.ApplyMagic(self._npc, self._npc, 100000, 1)
    FuncSet.ApplyMagic(self._npc, self._npc, 100001, 1)
    FuncSet.ApplyMagic(self._npc, self._npc, 100007, 1)
    FuncSet.ApplyMagic(self._npc, self._npc, 100016, 1)
    FuncSet.ApplyMagic(self._npc, self._npc, 100021, 1)
    FuncSet.ApplyMagic(self._npc, self._npc, 100022, 1)
    FuncSet.ApplyMagic(self._npc, self._npc, 100091, 1)
    FuncSet.ApplyMagic(self._npc, self._npc, 100093, 1)
    Tool.SetFightUiActive(false)
    self._timer:Schedule(8, true, Tool.SetFightUiActive)
    self._timer:Schedule(3, self, self.BlackScreen, true)
    self._timer:Schedule(3.5, self, self.BlackScreen, false)
end

function XLevelScriptHunt01:BlackScreen(enable)
    if enable then
        FuncSet.ApplyMagic(self._npc, self._npc, 5000003, 1)
    else
        FuncSet.ApplyMagic(self._npc, self._npc, 5000006, 1)
    end
end

return XLevelScriptHunt01