--- Hunt02教学关，负责介绍游戏的基础操作
local XLevelGuide1 = XDlcScriptManager.RegLevelScript(0012, "XLevelGuide1")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs
local Config = require("XDLCFight/Level/LevelConfig/Hunt02GuideConfig") -- 读取场景物体的配置数据,作为实例存在本地
local Tool = require("XDLCFight/Level/Common/XLevelTools")
local Timer = require("XDLCFight/Level/Common/XTaskScheduler")

local _cameraResRefTable = {
}

function XLevelGuide1.GetCameraResRefTable()
    return _cameraResRefTable
end

local _effectRefTable = {
}

function XLevelGuide1.GetEffectRefTable()
    return _effectRefTable
end

---@param proxy StatusSyncFight.XScriptLuaProxy
function XLevelGuide1:Ctor(proxy)
    self._proxy = proxy
    self._exitActive = false

    self._gateOpen = false

    self._camLockAnchorIndex = 25003 ---相机选中的勾点

    --self._needYellowLock = false ---是否需要黄锁

    Config.Switches[1].object = self
    Config.Switches[2].object = self
    Config.Switches[3].object = self
    Config.Switches[1].func = self.GateControl
    Config.Switches[2].func = self.Step5Switch
    Config.Switches[3].func = self.EnableAnchor

    self._deathZonePlaceId = 9997
    self._jumpGuideTrigger = 1001
    self._jumpSucTrigger = 1002
    self._step5AnchorTrigger = 1003
    self._step5EndPosTrigger = 1004
    self._step6StartTrigger = 1005
    self._step7NearBossTrigger = 1006
    self._step8GroundTrigger = 1007

    self._resetNpcPosition = {
        x = -13.12,
        y = 4.06,
        z = -124.68,
    }
    self._resetNpcRotation = {
        x = 0,
        y = -90,
        z = 0,
    }
    self._resetBossPosition1 = {
        x = -21,
        y = 4.06,
        z = -125,
    }
    self._resetBossRotation1 = {
        x = 0,
        y = 45,
        z = 0,
    }
    self._resetBossPosition2 = {
        x = -21,
        y = 4.06,
        z = -137,
    }
    self._resetBossRotation2 = {
        x = 0,
        y = 0,
        z = 0,
    }
    self._bossDiePosition = {
        x = 40.4,
        y = 999,
        z = -96.7,
    }

    --- 关卡流程
    self._curProgress = 0
    self._initProgress = 1
    self._levelProgress = {
        [1] = {
            name = "开场介绍",
            start = false,
            finished = false,
            guideId = 1,
        },
        [2] = {
            name = "跳跃教学",
            start = false,
            finished = false,
            guideId = 10,
        },
        [3] = {
            name = "开关教学",
            start = false,
            finished = false,
            guideId = 20,
        },
        [4] = {
            name = "场景猎锚教学",
            start = false,
            finished = false,
            guideId = 30,
            focusListen = false,
            focusProgress = 0,
            focusTime = 0,
            focusTarget = nil,
        },
        [5] = {
            name = "场景猎锚实践",
            start = false,
            finished = false,
            guideId = 40,
            highGround = false,
            endPointListen = false,
        },
        [6] = {
            name = "战斗教学1 猎锚拉近",
            start = false,
            finished = false,
            guideId = 50,
        },
        [7] = {
            name = "战斗教学2 攻击造成部位破坏 ",
            start = false,
            finished = false,
            guideId = 60,
            attackPractice = false,
            giveBall = false,
            stageTime = 3,
            giveBallCD = 5,
            stunGuided = false,
        },
        [8] = {
            name = "战斗教学3 猎锚QTE上天 ",
            start = false,
            finished = false,
            guideId = 70,
            fly = false, --各项检测开关
            NormAtk = false,
            AtkCount = 0,
            Eliminate = false,
            EliminateCount = 0,
            Zuma = false,
            ZumaCount = 0,
            Color = false,
            ColorCount = 0,
        },
        [9] = {
            name = "战斗教学第二轮 实操演练 ",
            start = false,
            finished = false,
            guideId = 80,
            blueLockListen = false,
            fly = false,
            duration = 0,
            success = nil,
            qteFailRechallengeGuideId = 90,
        },
        [99] = {
            name = "关卡结束",
            start = false,
            guideId = 990,
        }
    }

    self._tipRef = nil --暂时储存的tip的id 合规写法是每个阶段都要清理tips和guide，就会用到这份数据

    self._debug = false
end

function XLevelGuide1:Init()
    self._localPlayerNpcId = FuncSet.GetLocalPlayerNpcId()
    self:AddBuff(self._localPlayerNpcId, 8004100)--教学关标记，用于战斗内知道现在正在新手关
    self:AddBuff(self._localPlayerNpcId, 1000069) --禁止角色得球

    self._timer = Timer.New()
    self._guider = Tool.NewGuider(Config.Guides, self, self._localPlayerNpcId)

    self:InitSceneObjects()

    self._proxy:RegisterNpcEvent(EScriptEvent.NpcCastSkill, self._localPlayerNpcId)
    self._proxy:RegisterNpcEvent(EScriptEvent.NpcExitSkill, self._localPlayerNpcId)
    self._proxy:RegisterSceneObjectTriggerEvent(self._jumpGuideTrigger, 1) --JumpGuide进入监听
    self._proxy:RegisterSceneObjectTriggerEvent(self._jumpSucTrigger, 1) --JumpGuide进入监听
    self._proxy:RegisterSceneObjectTriggerEvent(self._step5AnchorTrigger, 1) --JumpGuide进入监听
    self._proxy:RegisterSceneObjectTriggerEvent(self._step5EndPosTrigger, 1) --
    self._proxy:RegisterSceneObjectTriggerEvent(self._step6StartTrigger, 1) --
    self._proxy:RegisterSceneObjectTriggerEvent(self._step7NearBossTrigger, 1) --
    self._proxy:RegisterSceneObjectTriggerEvent(self._step8GroundTrigger, 1) --
    self._proxy:RegisterSceneObjectTriggerEvent(2, 1) -- 第一个猎锚的触发器监听
    self._proxy:RegisterSceneObjectTriggerEvent(4, 2) -- 第三个猎锚的触发器监听
    self._proxy:RegisterSceneObjectTriggerEvent(self._deathZonePlaceId, 1)
    --退出关卡的监听
    self._proxy:RegisterSceneObjectTriggerEvent(9999, 1)
    XLog.Debug("<color=#F0D800>[SceneHunt02]</color>监听注册完成")

    --开关关掉多余UI
    --FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnJump, false)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, false)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false)
    FuncSet.SetUiActive(EUiIndex.OnlineMsg, false)

    --关闭第五步的物体
    FuncSet.SetSceneObjectActive(5, false)
    FuncSet.SetSceneObjectActive(6, false)
    XLog.Debug("<color=#F0D800>[SceneHunt02]</color>关卡流程设置完成")

    self:StartGuideStep(self._initProgress)

    --从_curProgress的末尾（完成状态）开始，去触发要测试的下一阶段
    if not (self._initProgress == 1) then
        local pos = { x = 16.6, y = 4, z = -118.6 }
        FuncSet.SetNpcPosition(self._localPlayerNpcId, pos)
    end


end
---初始化场景物体
function XLevelGuide1:InitSceneObjects()
    -- 配置虚拟相机
    for i, v in pairs(Config.Cams) do
        v.agent = XDlcScriptManager.GetSceneObjectScript(v.placeId)
        v.agent:SetCallBackBeforeActivated(function()
            v.agent:SetActorIds(v.ref, v.follow, v.aim)
            v.agent:SetCallBackBeforeActivated(v.callBack)
        end)
    end

    -- 配置场景中开关
    self._switches = Tool.InitSwitch(Config.Switches)
    XLog.Debug("<color=#F0D800>[SceneHunt02]</color>初始化场景中开关完成")

    -- 设置场景中猎矛默认开关
    self._anchors = Tool.InitAnchor(Config.Anchors)
    XLog.Debug("<color=#F0D800>[SceneHunt02]</color>初始化场景中锚点完成")

end

---@param dt number @ delta time
function XLevelGuide1:Update(dt)
    self._timer:Update(dt)
    Tool.UpdateGuide(self._guider, dt)

    if self._curProgress == 4 and self._levelProgress[4].focusListen then
        self:Step4ListenFocus(dt)
    elseif self._curProgress == 7 and self._levelProgress[7].attackPractice then
        self:Step7Update(dt)
    elseif self._curProgress == 8 and not self._levelProgress[8].finished then
        self:Step8Listen()
    elseif self._curProgress == 9 and not self._levelProgress[9].finished then
        self:Step9Listen(dt)
    end

--[[    if self._needYellowLock then
        self:AutoYellowLock()
    end]]

    if self._debug then
        if FuncSet.IsKeyDown(ENpcOperationKey.Ball8) then
            XLog.Debug(self._levelProgress)
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball9) then
            FuncSet.AddSkillBall(self._localPlayerNpcId, 0, 3)
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XLevelGuide1:HandleEvent(eventType, eventArgs)
    XLevelGuide1.Super.HandleEvent(self, eventType, eventArgs)
    if eventType == EScriptEvent.SceneObjectTrigger then
        XLog.Debug("XLevelPrototype SceneObjectTriggerEvent:"
                .. " TouchType " .. tostring(eventArgs.TouchType)
                .. " SourceActorId " .. tostring(eventArgs.SourceActorId)
                .. " SceneObjectId " .. tostring(eventArgs.SceneObjectId)
                .. " TriggerId " .. tostring(eventArgs.TriggerId)
                .. " TriggerState " .. tostring(eventArgs.TriggerState)
                .. " Log自关卡"
        )
        --XLog.Debug("关卡阶段：" .. tostring(self._curProgress))
        if eventArgs.SourceActorId == self._localPlayerNpcId then
            if self._curProgress == 1 then
                if eventArgs.SceneObjectId == self._jumpGuideTrigger and eventArgs.TriggerState == ESceneObjectTriggerState.Enter then
                    --and not self._levelProgress[2].start
                    --开启跳跃按钮
                    self:StartGuideStep(2)
                end
            elseif self._curProgress == 2 then
                if eventArgs.SceneObjectId == self._jumpSucTrigger and eventArgs.TriggerState == ESceneObjectTriggerState.Enter then
                    --and not self._levelProgress[3].start
                    self:StartGuideStep(3)
                end
            elseif self._curProgress == 3 then
                if eventArgs.SceneObjectId == 2 and eventArgs.TriggerState == ESceneObjectTriggerState.Enter then
                    --and not self._levelProgress[4].start
                    self:StartGuideStep(4)
                end
            elseif self._curProgress == 4 then
                if eventArgs.SceneObjectId == 4 and eventArgs.TriggerState == ESceneObjectTriggerState.Enter and not self._levelProgress[5].start then
                    --step4最后勾上T台，触发step5开始
                    self._timer:Schedule(1, self, self.StartGuideStep, 5)
                    self._levelProgress[5].start = true --因为是延时切换阶段，所以需要该变量避免重复触发延时切换任务
                end
            elseif self._curProgress == 5 then
                if eventArgs.SceneObjectId == self._step5AnchorTrigger and eventArgs.TriggerState == ESceneObjectTriggerState.Enter and not self._levelProgress[5].highGround then
                    --step5勾上高地
                    FuncSet.CreateLevelEffect(52, "FxTDSummonPoint02", 21.26, 9.05, -88, 0, 0, 0, 0, 0, 0)
                    --Tool.ShowGuide(self._guider, 43)
                    Tool.NextGuide(self._guider)
                    self._levelProgress[5].highGround = true
                    --润色：延时任务提示前往目标
                elseif eventArgs.SceneObjectId == self._step5EndPosTrigger and eventArgs.TriggerState == ESceneObjectTriggerState.Enter and not self._levelProgress[5].endPointListen then
                    --step5到达终点
                    if FuncSet.CheckLevelEffectExist(52) then
                        FuncSet.RemoveLevelEffect(52)
                    end
                    self._levelProgress[5].endPointListen = true
                    Tool.ShowGuide(self._guider, 45)
                    FuncSet.CreateLevelEffect(54, "FxTDSummonPoint02", 5.9, 3.98, -119.43, 0, 0, 0, 0, 0, 0)
                end
                if eventArgs.SceneObjectId == self._step6StartTrigger and eventArgs.TriggerState == ESceneObjectTriggerState.Enter then
                    --and not self._levelProgress[6].start
                    if not self._levelProgress[5].finished then
                        -- 鉴于经常从第五步结束开始，加一个额外的判断，方便第六步的初始化
                        self:FinishedGuideStep(5)
                    end
                    self:StartGuideStep(6)
                end
            elseif self._curProgress == 6 then
                --[[                if eventArgs.SceneObjectId == self._step7NearBossTrigger and eventArgs.TriggerState == ESceneObjectTriggerState.Enter and not self._levelProgress[7].start then
                                    self._timer:Schedule(1, self, self.StartGuideStep, 7)
                                    self._levelProgress[7].start = true --因为是延时切换阶段，所以需要该变量避免重复触发延时切换任务
                                end]]
            elseif self._curProgress == 7 then
            elseif self._curProgress == 8 then
                if eventArgs.SceneObjectId == self._step8GroundTrigger and eventArgs.TriggerState == ESceneObjectTriggerState.Enter
                        and self._levelProgress[8].finished and not self._levelProgress[9].start then
                    --延时重置关卡
                    self._timer:Schedule(1, self, self.ResetFight, 1)
                    --延时开始第九步
                    local id = self._timer:Schedule(3.5, self, self.StartGuideStep, 9)
                    self._levelProgress[9].start = true --因为是延时切换阶段，所以需要该变量避免重复触发延时切换任务
                    XLog.Debug("<color=#F0D800>[教学关]</color>注册阶段9开始任务，任务id为" .. tostring(id))
                end
            end
            --关卡结束判断
            if self._exitActive and eventArgs.SceneObjectId == 9999 then
                FuncSet.FinishFight(true)
            end
        end

        if eventArgs.SceneObjectId == self._deathZonePlaceId and FuncSet.IsPlayerNpc(eventArgs.SourceActorId) then
            FuncSet.ResetNpcToSafePoint(eventArgs.SourceActorId)
        end
    end
    if eventType == EScriptEvent.NpcCastSkill then
        --[[        XLog.Debug(string.format("<color=#F0D800>[SceneHunt02]</color>Level listen npc:%d cast skill:%d to target:%d",
                        eventArgs.LauncherId, eventArgs.SkillId, eventArgs.TargetId))]]
    elseif eventType == EScriptEvent.NpcExitSkill then
        --[[        XLog.Debug(string.format("<color=#F0D800>[SceneHunt02]</color>Level listen npc:%d exit skill:%d to target:%d",
                        eventArgs.LauncherId, eventArgs.SkillId, eventArgs.TargetId))]]
        if self._curProgress == 6 and eventArgs.SkillId == 100230 and not self._levelProgress[7].start then
            self._timer:Schedule(1, self, self.StartGuideStep, 7)
            self._levelProgress[7].start = true --因为是延时切换阶段，所以需要该变量避免重复触发延时切换任务
        end
    end
end

function XLevelGuide1:StartGuideStep(step)
    if self._curProgress == step or (self._curProgress > 0 and not self._levelProgress[self._curProgress].finished) then
        --XLog.Error("<color=#F0D800>[教学关]</color> 切换到关卡阶段" .. tostring(step) .. "失败 " .. tostring(self._curProgress) .. tostring(self._levelProgress[step].finished))
        return
    end

    self._curProgress = step
    XLog.Debug("<color=#F0D800>[教学关]</color>关卡阶段" .. tostring(step) .. ": " .. self._levelProgress[step].name .. "开始执行")
    --self._levelProgress[step].start = true

    if step == 1 then
    elseif step == 2 then
        FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnJump, true)
        if FuncSet.CheckLevelEffectExist(11) then
            FuncSet.RemoveLevelEffect(11)
        end
        --润色：延时任务再次提示使用跳跃按键
    elseif step == 3 then
        --润色：延时任务再次提示攻击开关
    elseif step == 4 then
        --关闭上一步的横幅提示
        self:CloseTip()
        --润色：延时任务再次提示使用猎锚按键
    elseif step == 5 then
        self.Step5ObjectReveal()
    elseif step == 6 then
        --step6开始那个门
        if FuncSet.CheckLevelEffectExist(54) then
            FuncSet.RemoveLevelEffect(54)
        end
        self:CloseTip()
    elseif step == 7 then
        --self._needYellowLock = true
    elseif step == 8 then
        --如果玩家没有lock怪物，那就帮他lock
        self:AutoYellowLock()
        self:AddBuff(self._localPlayerNpcId, 8004005)
    elseif step == 9 then
        self:AddBuff(self._localPlayerNpcId, 8004007)
    elseif step == 10 then
    elseif step == 99 then
        XLog.Debug("<color=#F0D800>[教学关]</color>临时使用角色落地触发关卡结束")
        self._levelProgress[99].start = true --避免被重复触发
        self:FinishGuide()
        return
    end
    Tool.ShowGuide(self._guider, self._levelProgress[step].guideId)
end

function XLevelGuide1:FinishedGuideStep(step)
    if self._curProgress ~= step then
        XLog.Error("<color=#F0D800>[教学关]</color>FinishedGuideStep failed, current progress not equals:" .. tostring(step))
        return
    end
    XLog.Debug("<color=#F0D800>[教学关]</color>关卡阶段" .. tostring(step) .. ": " .. self._levelProgress[step].name .. "执行完成")
    self._levelProgress[step].finished = true

    if step == 1 then
        --关闭多余UI
        FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnJump, false)
        FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, false)
        FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false)
        --创建目的地特效
        FuncSet.CreateLevelEffect(11, "FxTDSummonPoint02", 27, 1.987, -13, 0, 0, 0, 0, 0, 0)
    elseif step == 2 then
        FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, false)
        FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false)
    elseif step == 3 then
        FuncSet.RemoveNpcFocusTarget(self._localPlayerNpcId)
        FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, false)
        FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false)
        self:ShowTip(12020)
    elseif step == 4 then
    elseif step == 5 then
        FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false)
        --召唤boss
        self._bossId = FuncSet.GenerateNpc(1, 8004, 2, self._resetBossPosition1, self._resetBossRotation1)
        self:ShowTip(12041)
    elseif step == 6 then
    elseif step == 7 then
        --self._needYellowLock = false
        self:CloseTip()
        self:StartGuideStep(8)
    elseif step == 8 then
        self:AddBuff(self._localPlayerNpcId, 8004006)
        FuncSet.RemoveBuff(self._localPlayerNpcId, 8004018)
    elseif step == 9 then
    elseif step == 10 then
    end
    --self._curProgress = self._curProgress + 1
end
---开关门，每次调用切换门的状态
function XLevelGuide1:GateControl()
    if self._gateOpen then
        FuncSet.PlaySceneAnimation(0)
    else
        FuncSet.PlaySceneAnimation(1)
    end
    self._gateOpen = not self._gateOpen
    if self._tipRef == 12020 then
        self:ShowTip(12021)
    end
end
---关卡退出开关
function XLevelGuide1:SetExitActive(active)
    if active and not self._exitActive then
        XLog.Debug("<color=#F0D800>[SceneHunt02]</color>关卡退出出口启动")
        if not FuncSet.CheckLevelEffectExist(9999) then
            FuncSet.CreateLevelEffect(9999, "FxExitGate", -53.994, 5.822186, -125.7642, 0, 90, 0, 0, 0, 0)
        end
    elseif not active and self._exitActive then
        XLog.Debug("<color=#F0D800>[SceneHunt02]</color>关卡退出出口关闭")
        if FuncSet.CheckLevelEffectExist(9999) then
            FuncSet.RemoveLevelEffect(9999)
        end
    end
    self._exitActive = active
end
---开启猎锚勾点
function XLevelGuide1:EnableAnchor(placeId)
    self._anchors[placeId].agent:SetEnable(true)
end
---注视场景物体
function XLevelGuide1:FocusOnSceneObj(placeId)
    XLog.Debug("<color=#F0D800>[教学关]</color>FOCUS ON" .. tostring(placeId))
    local uuid = FuncSet.GetSceneObjectUUID(placeId)
    FuncSet.SetNpcFocusTarget(self._localPlayerNpcId, uuid)
end
---注视npc
function XLevelGuide1:FocusOnNpc()
    FuncSet.SetNpcFocusTarget(self._localPlayerNpcId, self._bossId)
end
---取消注视
function XLevelGuide1:RemoveFocus()
    FuncSet.RemoveNpcFocusTarget(self._localPlayerNpcId)
end
---显示任务提示，暂时不支持多种提示共存
function XLevelGuide1:ShowTip(id, param)
    if id ~= self._tipRef then
        self:CloseTip()
    end
    if id ~= nil then
        FuncSet.ShowTip(id, param)
        self._tipRef = id
    end
end
---自动关闭任务提示
function XLevelGuide1:CloseTip()
    if self._tipRef ~= nil then
        FuncSet.CloseTip(self._tipRef)
        self._tipRef = nil
    end
end
---第四步启用锚点
function XLevelGuide1:Step4EnableAnchors()
    self._anchors[2].agent:SetEnable(true)
    self._anchors[3].agent:SetEnable(true)
    self._anchors[4].agent:SetEnable(true)
end
---第四步 猎锚监听1开始
function XLevelGuide1:Step4EnableFocusListen()
    self._levelProgress[4].focusListen = true
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, false)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false)
    self:CloseTip(self._tipRef)
end
---第四步教学 猎锚瞄准
function XLevelGuide1:Step4ListenFocus(dt)
    local camLockAnchor = FuncSet.GetNpcNoteInt(self._localPlayerNpcId, self._camLockAnchorIndex)

    -- 如果当前没有目标，设置一个目标，直接利用_tipRef的值来表示
    if self._tipRef == nil then
        if self._levelProgress[4].focusProgress <= 1 then
            if camLockAnchor == 2 then
                self._tipRef = 12033
            else
                self._tipRef = 12032
            end
        elseif self._levelProgress[4].focusProgress == 2 then
            self._tipRef = 12034
        elseif self._levelProgress[4].focusProgress == 3 then
            self._tipRef = 12035 -- 目标已达成，提示一个完成
        end
        self._levelProgress[4].focusTime = 0
        self:ShowTip(self._tipRef, self._levelProgress[4].focusProgress)-- 显示目标
    end

    -- 目标达成判断
    if self._levelProgress[4].focusTime > 0.5 then
        --目标切换后即便直接达成目标，也给玩家一个感知到发生的过程
        if camLockAnchor == 2 and self._tipRef == 12032 then
            self:CloseTip()
            self._levelProgress[4].focusProgress = self._levelProgress[4].focusProgress + 1
        elseif camLockAnchor == 3 and self._tipRef == 12033 then
            self:CloseTip()
            self._levelProgress[4].focusProgress = self._levelProgress[4].focusProgress + 1
        elseif camLockAnchor == 4 and self._tipRef == 12034 then
            self:CloseTip()
            self._levelProgress[4].focusProgress = self._levelProgress[4].focusProgress + 1
        end
    end

    -- 最终目标达成，提示完成后结束本方法的监听
    if self._tipRef == 12035 and self._levelProgress[4].focusTime > 1 then
        self._levelProgress[4].focusListen = false
        Tool.ShowGuide(self._guider, 37)
        self._timer:Schedule(0.1, self, self.Step4EnableAnchorListen)
        self:CloseTip()
    end

    self._levelProgress[4].focusTime = self._levelProgress[4].focusTime + dt
end
---第四步教学 猎锚监听2开始
function XLevelGuide1:Step4EnableAnchorListen()
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, true)
    local camLockAnchor = FuncSet.GetNpcNoteInt(self._localPlayerNpcId, self._camLockAnchorIndex)
    if camLockAnchor ~= 4 then
        self:FocusOnSceneObj(4)
    end
end
---显示第五步的物体
function XLevelGuide1:Step5ObjectReveal()
    FuncSet.SetSceneObjectActive(5, true)
    FuncSet.SetSceneObjectActive(6, true)
    FuncSet.CreateLevelEffect(50, "FxQte", 39.86927, 5.046208, -64.46697, 0, 0, 0, 0, 0, 0)
    FuncSet.CreateLevelEffect(51, "FxQte", 41.96107, 8.160282, -69.77538, 90, 0, 0, 0, 0, 0)
end
function XLevelGuide1:Step5ShowSwitchTips()
    self:ShowTip(12040)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false)
end
---5号开关
function XLevelGuide1:Step5Switch()
    self:EnableAnchor(6)
    self:CloseTip()
    Tool.ShowGuide(self._guider, 42)
end
---第五步开始最后的练习
function XLevelGuide1:Step5StartTraining()
    self._anchors[7].agent:SetEnable(true)
    self:FocusOnSceneObj(7)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false)
end
---第六步瞄准按钮显现
function XLevelGuide1:Step6ShowFocusBtn()
    FuncSet.SetNpcNoteInt(self._localPlayerNpcId, 200, 1)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, true)
end
---第七步教学 攻击练习
function XLevelGuide1:Step7AttackPractice()
    self:ShowTip(12060)
    self._levelProgress[7].attackPractice = true --开启攻击练习，部位破坏的监控
end
---第七步教学 检测部位被破坏，引导执行qte
function XLevelGuide1:Step7Update(dt)
    if FuncSet.CheckBuffByKind(self._bossId, 8004021) and not self._levelProgress[7].stunGuided then
        XLog.Debug("<color=#F0D800>[教学关]</color>检测到怪物硬直")
        FuncSet.RemoveBuff(self._bossId, 8004021)
        Tool.ShowGuide(self._guider, 63)
        self._levelProgress[7].stunGuided = true
    end
    if FuncSet.CheckBuffByKind(self._bossId, 8004029) then
        if self:CheckBlueLock() then
            FuncSet.RemoveBuff(self._bossId, 8004029)
            self._timer:Schedule(0.7, self._guider, Tool.ShowGuide, 64)
            self._levelProgress[7].attackPractice = false --关闭攻击练习，部位破坏的监控
            FuncSet.ClearAllSkillBalls(self._localPlayerNpcId)
            XLog.Debug("<color=#F0D800>[教学关]</color>检测到怪物部位被破坏了")
        else
            -- 要求蓝锁
        end
    end
    if FuncSet.GetSkillBallCount(self._localPlayerNpcId) <= 3 then
        self._levelProgress[7].stageTime = self._levelProgress[7].stageTime + dt
    end
    if self._levelProgress[7].stageTime >= self._levelProgress[7].giveBallCD then
        self._levelProgress[7].stageTime = 0
        if math.random(100) > 50 then
            FuncSet.AddSkillBall(self._localPlayerNpcId, 2, 3)
            FuncSet.AddSkillBall(self._localPlayerNpcId, 3, 1)
        else
            FuncSet.AddSkillBall(self._localPlayerNpcId, 3, 3)
            FuncSet.AddSkillBall(self._localPlayerNpcId, 2, 1)
        end
        FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 3)
    end
end
---第八步教学 期间每帧监控
function XLevelGuide1:Step8Listen(dt)
    if self._levelProgress[8].Fly then
        if FuncSet.CheckBuffByKind(self._localPlayerNpcId, 8004022) then
            FuncSet.RemoveBuff(self._localPlayerNpcId, 8004022)
            self._levelProgress[8].Fly = false

            XLog.Debug("<color=#F0D800>[教学关]</color>检测到角色上天儿了")
            Tool.ShowGuide(self._guider, 71)
            --需要清除一次角色的球
            FuncSet.ClearAllSkillBalls(self._localPlayerNpcId)
            --玩家攻击力扣到0
            FuncSet.AddBuff(self._localPlayerNpcId, 8004018)
        end
    elseif self._levelProgress[8].NormAtk then
        if FuncSet.CheckBuffByKind(self._localPlayerNpcId, 8004025) then
            FuncSet.RemoveBuff(self._localPlayerNpcId, 8004025)
            self._levelProgress[8].AtkCount = self._levelProgress[8].AtkCount + 1
            XLog.Debug("<color=#F0D800>[教学关]</color>检测到普攻一次" .. tostring(self._levelProgress[8].AtkCount))
            --普攻发球
            FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 1)
            if self._levelProgress[8].AtkCount >= 6 then
                self:ShowTip(12071, self._levelProgress[8].AtkCount)
                self._levelProgress[8].NormAtk = false
                XLog.Debug("<color=#F0D800>[教学关]</color>普攻了六次，接着教学消除")
                self._timer:Schedule(1, self._guider, Tool.ShowGuide, 72)
                self._timer:Schedule(1, self, self.CloseTip)
                self._timer:Schedule(1, self._localPlayerNpcId, FuncSet.RemoveBuff, 8004026)
            end
            self:ShowTip(self._tipRef, self._levelProgress[8].AtkCount)
        end
    elseif self._levelProgress[8].Eliminate then
        if FuncSet.CheckBuffByKind(self._localPlayerNpcId, 8004026) then
            FuncSet.RemoveBuff(self._localPlayerNpcId, 8004026)
            self._levelProgress[8].EliminateCount = self._levelProgress[8].EliminateCount + 1
            XLog.Debug("<color=#F0D800>[教学关]</color>检测到消球一次")
            if self._levelProgress[8].EliminateCount >= 3 then
                self:ShowTip(12073, self._levelProgress[8].EliminateCount)
                self._levelProgress[8].Eliminate = false
                XLog.Debug("<color=#F0D800>[教学关]</color>消球了三次，接着教学连消")
                self._timer:Schedule(1, self._guider, Tool.ShowGuide, 74)
                self._timer:Schedule(1, self, self.CloseTip)
                self._timer:Schedule(1, self._localPlayerNpcId, FuncSet.RemoveBuff, 8004023)
            elseif FuncSet.GetSkillBallCount(self._localPlayerNpcId) <= 1 then
                local random = math.random(100)
                if random < 34 then
                    FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 3)
                elseif random > 66 then
                    FuncSet.AddSkillBall(self._localPlayerNpcId, 3, 3)
                else
                    FuncSet.AddSkillBall(self._localPlayerNpcId, 2, 3)
                end
            end
            self:ShowTip(self._tipRef, self._levelProgress[8].EliminateCount)
        end
    elseif self._levelProgress[8].Zuma then
        if FuncSet.CheckBuffByKind(self._localPlayerNpcId, 8004023) then
            FuncSet.RemoveBuff(self._localPlayerNpcId, 8004023)
            self._levelProgress[8].ZumaCount = self._levelProgress[8].ZumaCount + 1
            XLog.Debug("<color=#F0D800>[教学关]</color>检测到连消一次")
            if self._levelProgress[8].ZumaCount >= 1 then
                self:ShowTip(12075, self._levelProgress[8].ZumaCount)
                self._levelProgress[8].Zuma = false
                XLog.Debug("<color=#F0D800>[教学关]</color>祖玛了一次，下一步")
                self._timer:Schedule(0.5, self._guider, Tool.ShowGuide, 75)
                self._timer:Schedule(0.5, self, self.CloseTip)
                self._timer:Schedule(0.5, self._localPlayerNpcId, FuncSet.RemoveBuff, 8004024)
                FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 2)
                FuncSet.AddSkillBall(self._localPlayerNpcId, 3, 3)
                FuncSet.AddSkillBall(self._localPlayerNpcId, 2, 1)
                FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 1)
                FuncSet.AddSkillBall(self._localPlayerNpcId, 3, 2)
                FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 2)
            end
            self:ShowTip(self._tipRef, self._levelProgress[8].ZumaCount)
        elseif FuncSet.GetSkillBallCount(self._localPlayerNpcId) <= 3 and FuncSet.CheckBuffByKind(self._localPlayerNpcId, 8004026) then
            FuncSet.RemoveBuff(self._localPlayerNpcId, 8004026)
            --祖玛失败的处理 再发一次球
            FuncSet.ClearAllSkillBalls(self._localPlayerNpcId)
            FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 2)
            FuncSet.AddSkillBall(self._localPlayerNpcId, 2, 1)
            FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 2)
        end
    elseif self._levelProgress[8].Color then
        if FuncSet.CheckBuffByKind(self._localPlayerNpcId, 8004024) then
            FuncSet.RemoveBuff(self._localPlayerNpcId, 8004024)
            self._levelProgress[8].ColorCount = self._levelProgress[8].ColorCount + 1
            XLog.Debug("<color=#F0D800>[教学关]</color>检测到彩消一次")
            if self._levelProgress[8].ColorCount >= 1 then
                self._levelProgress[8].Color = false
                XLog.Debug("<color=#F0D800>[教学关]</color>彩消了一次，下一步")
                self._timer:Schedule(2, self._guider, Tool.ShowGuide, 76)
                FuncSet.RemoveBuff(self._localPlayerNpcId, 1000069)
            end
        elseif FuncSet.GetSkillBallCount(self._localPlayerNpcId) <= 1 then
            FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 2)
            FuncSet.AddSkillBall(self._localPlayerNpcId, 3, 3)
            FuncSet.AddSkillBall(self._localPlayerNpcId, 2, 1)
            FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 1)
            FuncSet.AddSkillBall(self._localPlayerNpcId, 3, 2)
            FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 2)
        end
    end
end

---第八步教学 上天检测，上天后引导进入下一步
function XLevelGuide1:Step8WaitingFly()
    self._levelProgress[8].Fly = true
end
---第八步教学 上天检测，普攻
function XLevelGuide1:Step8WaitingAtk()
    self._levelProgress[8].NormAtk = true
    self:ShowTip(12070)
    FuncSet.ClearAllSkillBalls(self._localPlayerNpcId)
end
---第八步教学 上天检测，消球引导
function XLevelGuide1:Step8WaitingEliminate()
    self._levelProgress[8].Eliminate = true
    self:ShowTip(12072)
    FuncSet.ClearAllSkillBalls(self._localPlayerNpcId)
    FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 2)
    FuncSet.AddSkillBall(self._localPlayerNpcId, 2, 3)
    FuncSet.AddSkillBall(self._localPlayerNpcId, 3, 4)
end
---第八步教学 上天检测，祖玛引导
function XLevelGuide1:Step8WaitingZuma()
    self._levelProgress[8].Zuma = true
    self:ShowTip(12074)
    FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 2)
    FuncSet.AddSkillBall(self._localPlayerNpcId, 2, 1)
    FuncSet.AddSkillBall(self._localPlayerNpcId, 1, 2)
end
---第八步教学
function XLevelGuide1:Step8WaitingColor()
    self._levelProgress[8].Color = true
end
---第九步教学 蓝锁检测处理引导 和 上天以后的提示、失败判定
function XLevelGuide1:Step9Listen(dt)
    if not self._levelProgress[9].success then
        --蓝锁检测
        if self._levelProgress[9].blueLockListen then
            if --[[FuncSet.CheckBuffByKind(self._bossId, 1000000) and]] FuncSet.CheckBuffByKind(self._bossId, 8004029) then
                FuncSet.RemoveBuff(self._bossId, 8004029)
                XLog.Debug("<color=#F0D800>[教学关]</color>检测到成部位破坏，触发猎锚提示")
                Tool.NextGuide(self._guider)
                self._levelProgress[9].blueLockListen = false
            end
        end

        --成功失败检测
        if FuncSet.CheckBuffByKind(self._bossId, 8004027) then
            XLog.Debug("<color=#F0D800>[教学关]</color>检测到钉入成功")
            FuncSet.RemoveBuff(self._bossId, 8004027)
            self._levelProgress[9].success = true
            self:FinishGuide()
            self:CloseTip()
            return
        elseif FuncSet.CheckBuffByKind(self._bossId, 8004028) then
            XLog.Debug("<color=#F0D800>[教学关]</color>检测到钉入失败")
            FuncSet.RemoveBuff(self._bossId, 8004028)
            self._levelProgress[9].duration = 0
            self._timer:Schedule(4, self, self.ResetFight, 1)
            self._timer:Schedule(6.5, self._guider, Tool.ShowGuide, self._levelProgress[9].qteFailRechallengeGuideId)
            self._timer:Schedule(5, self, self.SetExitActive, true)
            self:FocusOnNpc(self._bossId)
            Tool.SetFightUiActive(false)
            return
        end

        --上天检测
        if not self._levelProgress[9].fly then
            if FuncSet.CheckBuffByKind(self._localPlayerNpcId, 8004022) then
                XLog.Debug("<color=#F0D800>[教学关]</color>检测到角色上天儿了")
                FuncSet.RemoveBuff(self._localPlayerNpcId, 8004022)
                self._levelProgress[9].fly = true
                self._levelProgress[9].duration = 0
                Tool.CloseGuide(self._guider) -- 应该是关闭Guide了
            end
        else
            self._levelProgress[9].duration = self._levelProgress[9].duration + dt
            local timeLeft = 8 - math.floor(self._levelProgress[9].duration)
            if timeLeft < 0 then
                self:CloseTip()
                self._levelProgress[9].fly = false
            else
                self:ShowTip(12080, timeLeft)
            end
        end
    else
        if FuncSet.CheckBuffByKind(self._bossId, 8004027) then
            XLog.Debug("<color=#F0D800>[教学关]</color>检测到钉入成功")
            FuncSet.RemoveBuff(self._bossId, 8004027)
            self:ResetFight(2)
            self._timer:Schedule(2.3, true, Tool.SetFightUiActive)
        elseif FuncSet.CheckBuffByKind(self._bossId, 8004028) then
            XLog.Debug("<color=#F0D800>[教学关]</color>检测到钉入失败")
            FuncSet.RemoveBuff(self._bossId, 8004028)
            self:ResetFight(2)
            self._timer:Schedule(2.3, true, Tool.SetFightUiActive)
        end
    end
end
---第九步教学 蓝锁检测开始
function XLevelGuide1:Step9BlueLockListen()
    self._levelProgress[9].blueLockListen = true
end
---第九步教学 重新尝试
function XLevelGuide1:Step9RepeatGuide()
    self._levelProgress[9].blueLockListen = true
end
---教学结束
function XLevelGuide1:FinishGuide()
    XLog.Debug("<color=#F0D800>[教学关]</color>教学关结束")
    self._timer:Schedule(6, self, self.ResetFight, 2)
    self._timer:Schedule(8, self._guider, Tool.ShowGuide, 990)
    self._timer:Schedule(7, self, self.SetExitActive, true)
end

function XLevelGuide1:ResetFight(case)
    XLog.Debug("<color=#F0D800>[教学关]</color>重置战斗状态")
    self:RemoveFocus()
    self:AddBuff(self._localPlayerNpcId, 5000003) --黑屏
    self._timer:Schedule(2, self._localPlayerNpcId, FuncSet.RemoveBuff, 5000003) --黑屏2s

    if self._bossId ~= nil and FuncSet.CheckNpc(self._bossId) then
        --die会持续一段时间，以后需要换成remove
        self._timer:Schedule(0.5, self._bossId, FuncSet.SetNpcPosition, self._bossDiePosition) -- 把boss传送到看不见的地方
        self._timer:Schedule(0.5, self._bossId, FuncSet.NpcDie)
        self:AddBuff(self._localPlayerNpcId, 8004015)--隐藏猎锚及其特效
        FuncSet.RemoveNpcFocusTarget(self._localPlayerNpcId) --解除锁定
    end

    self._timer:Schedule(0.1, false, Tool.SetFightUiActive)
    self._timer:Schedule(1.9, true, Tool.SetFightUiActive)
    self._timer:Schedule(0.6, self, self.ReGenerateNpc, case) --召唤新boss

end

function XLevelGuide1:ReGenerateNpc(case)
    self._bossId = FuncSet.GenerateNpc(1, 8004, 2, self._bossDiePosition, self._resetBossRotation1) --在玩家看不见的地方召唤新的boss
    --self:AddBuff(self._bossId, 8004008) --修改部位阈值为造成1750伤害即可钉入成功
    --[[    if case == 1 then
            self:AddBuff(self._bossId, 8004014) --怪物进入大受击
            self:AddBuff(self._bossId, 8004016)
        end]]
    self:ResetPosition(case)
end

function XLevelGuide1:ResetPosition(case)
    FuncSet.SetNpcPosAndRot(self._localPlayerNpcId, self._resetNpcPosition, self._resetNpcRotation)
    if case == 1 then
        FuncSet.SetNpcPosAndRot(self._bossId, self._resetBossPosition1, self._resetBossRotation1)
    elseif case == 2 then
        FuncSet.SetNpcPosAndRot(self._bossId, self._resetBossPosition2, self._resetBossRotation2)
    end
end
---log并加buff，替换直接加buff
function XLevelGuide1:AddBuff(npc, buffId)
    if self._debug then
        XLog.Debug("<color=#F0D8F0>[教学关BUFF]</color> npc" .. tostring(npc) .. " buff" .. tostring(buffId))
    end
    FuncSet.AddBuff(npc, buffId)
end
---自动黄锁
function XLevelGuide1:AutoYellowLock()
    --如果玩家没有lock怪物，那就帮他lock
    local npcCamLock0 = FuncSet.GetNpcNoteInt(self._localPlayerNpcId, 2402) ~= 0
    local npcCamLock1 = FuncSet.GetNpcNoteInt(self._localPlayerNpcId, 2102) ~= 0
    if not (npcCamLock0 or npcCamLock1) then
        XLog.Debug("<color=#F0D800>[教学关]</color>帮玩家锁定怪物")
        FuncSet.SetNpcNoteInt(self._localPlayerNpcId, 30011, self._bossId) --设置目标
        FuncSet.SetNpcNoteInt(self._localPlayerNpcId, 2409, 3) --模拟手动点击
    end
end
---蓝锁检测
function XLevelGuide1:CheckBlueLock()
    return FuncSet.CheckBuffByKind(self._bossId, 1000000) or FuncSet.CheckBuffByKind(self._bossId, 1000001) or FuncSet.CheckBuffByKind(self._bossId, 1000002) or FuncSet.CheckBuffByKind(self._bossId, 1000003)
end

function XLevelGuide1:Terminate()

end

return XLevelGuide1