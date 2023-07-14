local XGoldenMinerComponentHook = require("XUi/XUiGoldenMiner/Game/Component/XGoldenMinerComponentHook")
local XGoldenMinerComponentStone = require("XUi/XUiGoldenMiner/Game/Component/XGoldenMinerComponentStone")
local XGoldenMinerComponentMove = require("XUi/XUiGoldenMiner/Game/Component/XGoldenMinerComponentMove")
local XGoldenMinerComponentMouse = require("XUi/XUiGoldenMiner/Game/Component/XGoldenMinerComponentMouse")
local XGoldenMinerComponentQTE = require("XUi/XUiGoldenMiner/Game/Component/XGoldenMinerComponentQTE")
local XGoldenMinerComponentMussel = require("XUi/XUiGoldenMiner/Game/Component/XGoldenMinerComponentMussel")
local XGoldenMinerComponentDirectionPoint = require("XUi/XUiGoldenMiner/Game/Component/XGoldenMinerComponentDirectionPoint")
local XGoldenMinerComponentTimeLineAnim = require("XUi/XUiGoldenMiner/Game/Component/XGoldenMinerComponentTimeLineAnim")
local XGoldenMinerEntityHook = require("XUi/XUiGoldenMiner/Game/Entity/XGoldenMinerEntityHook")
local XGoldenMinerEntityStone = require("XUi/XUiGoldenMiner/Game/Entity/XGoldenMinerEntityStone")
local XGoldenMinerEntityBuffContainer = require("XUi/XUiGoldenMiner/Game/Entity/XGoldenMinerEntityBuffContainer")
local XGoldenMinerSystemHook = require("XUi/XUiGoldenMiner/Game/System/XGoldenMinerSystemHook")
local XGoldenMinerSystemStone = require("XUi/XUiGoldenMiner/Game/System/XGoldenMinerSystemStone")
local XGoldenMinerSystemMove = require("XUi/XUiGoldenMiner/Game/System/XGoldenMinerSystemMove")
local XGoldenMinerSystemBuff = require("XUi/XUiGoldenMiner/Game/System/XGoldenMinerSystemBuff")
local XGoldenMinerSystemQTE = require("XUi/XUiGoldenMiner/Game/System/XGoldenMinerSystemQTE")
local XGoldenMinerSystemTimeLineAnim = require("XUi/XUiGoldenMiner/Game/System/XGoldenMinerSystemTimeLineAnim")
local XGoldenMinerMapStoneData = require("XEntity/XGoldenMiner/Game/XGoldenMinerMapStoneData")

local GAME_STATUS = {
    NONE = 0,
    INIT = 1,
    PLAY = 2,
    PAUSE = 3,
    END = 4,
    QTE = 5,
    TIME_STOP = 6,
}
local MIN_FRAME_TIME = 1 / 20
local MILLION_PERCENT = 1000000
local W_PERCENT = 10000

local CSXResourceManagerLoad = CS.XResourceManager.Load

---@class XGoldenMinerGame
local XGoldenMinerGame = XClass(nil, "XGoldenMinerGame")

function XGoldenMinerGame:Ctor()
    ---@type XGoldenMinerGameData
    self._Data = false

    ---一级状态：游戏状态
    self._Status = GAME_STATUS.NONE

    ---二级状态：暂停原因
    self._PauseReason = XGoldenMinerConfigs.GAME_PAUSE_TYPE.NONE

    ---暂停前状态缓存
    self._PauseStageCatchStatus = GAME_STATUS.NONE

    ---时间停止前状态缓存
    self._TimeStopCatchStatus = GAME_STATUS.NONE

    ---QTE前状态缓存
    self._QTECatchStatus = GAME_STATUS.NONE

    ---@type UnityEngine.Transform
    self._MapObjRoot = false

    ---@type UnityEngine.Vector2
    self._RectSize = false

    ---@type UnityEngine.Transform[]
    self._HookObjDir = {}

    ---@type UnityEngine.Transform
    self._HookRoot = false

    ---资源字典
    self._ResourcePool = {}

    self.BuffIdList = {}
    
    ---@type XGoldenMinerEntityBuffContainer
    self.BuffContainer = XGoldenMinerEntityBuffContainer.New()

    ---@type XGoldenMinerEntityHook[]
    self.HookEntityList = false
    
    self.HookEntityStatus = XGoldenMinerConfigs.GAME_HOOK_ENTITY_STATUS.NONE

    ---@type XGoldenMinerEntityStone[]
    self.StoneEntityList = {}

    ---QTE触发钩子
    ---@type XGoldenMinerEntityHook
    self.QTEHookEntity = false

    ---QTE触发抓取
    ---@type XGoldenMinerEntityStone
    self.QTEStoneEntity = false

    ---QTE触发钩子缓存
    ---@type XGoldenMinerEntityHook
    self.QTECatchHookEntityList = { }

    ---QTE触发抓取缓存
    ---@type XGoldenMinerEntityStone
    self.QTECatchStoneEntityList = { }
    
    ---@type XGoldenMinerSystemHook
    self.SystemHook = XGoldenMinerSystemHook.New()

    ---@type XGoldenMinerSystemStone
    self.SystemStone = XGoldenMinerSystemStone.New()
    
    ---@type XGoldenMinerSystemMove
    self.SystemMove = XGoldenMinerSystemMove.New()

    ---@type XGoldenMinerSystemBuff
    self.SystemBuff = XGoldenMinerSystemBuff.New()

    ---@type XGoldenMinerSystemQTE
    self.SystemQTE = XGoldenMinerSystemQTE.New()

    ---@type XGoldenMinerSystemTimeLineAnim
    self.SystemTimeLimeAnim = XGoldenMinerSystemTimeLineAnim.New()
end

--region GameControl
function XGoldenMinerGame:Init()
    if not self:_IsStatus(GAME_STATUS.NONE) then
        return
    end
    self._Status = GAME_STATUS.INIT
    self:InitHook()
    self:InitMap()
    self:InitBuff()
    self:InitTimeLineAnim()
    self._Status = GAME_STATUS.PLAY
end

function XGoldenMinerGame:Update(time)
    time = self:_CheckFrameTime(time)
    if self:IsQTE() then
        self:UpdateQTE(time)
    elseif self:IsPlay() then
        self:UpdateTime(time)
        self:UpdateBuff(time)
        self:UpdateHook(time)
        self:UpdateStone(time)
        self:UpdateStoneMove(time)
        self:UpdateTimeLineAnim(time)
    elseif self:IsTimeStop() then
        self:UpdateBuff(time)
        self:UpdateHook(time)
        self:UpdateStone(time)
        self:UpdateTimeLineAnim(time)
    end
end

function XGoldenMinerGame:Resume(reason)
    if self:IsEnd() then
        return
    end
    if reason then
        self._PauseReason = self._PauseReason & (~reason)
    end
    if self._PauseReason ~= XGoldenMinerConfigs.GAME_PAUSE_TYPE.NONE then
        return
    end
    self._Status = self._PauseStageCatchStatus
end

function XGoldenMinerGame:Pause(reason)
    if self:IsEnd() or self:IsPause(reason) then
        return
    end
    if not self:IsPause() then
        self._PauseStageCatchStatus = self._Status
    end
    if reason then
        self._PauseReason = self._PauseReason | reason
    end

    self._Status = GAME_STATUS.PAUSE
end

function XGoldenMinerGame:GameOver()
    self._Status = GAME_STATUS.END
end

function XGoldenMinerGame:TimeStop()
    if self:IsEnd() or self:IsPause() then
        return
    end
    if not self:IsTimeStop() then
        self._TimeStopCatchStatus = self._Status
    end
    self._Status = GAME_STATUS.TIME_STOP
end

function XGoldenMinerGame:TimeResume()
    if self:IsEnd() or self:IsPause() then
        return
    end
    if self._TimeStopCatchStatus == GAME_STATUS.NONE then
        return
    end
    self._Status = self._TimeStopCatchStatus
end

function XGoldenMinerGame:Destroy()
    for _, resource in pairs(self._ResourcePool) do
        resource:Release()
    end
    self._Data = nil
    self._Status = nil
    self._PauseReason = nil
    self._PauseStageCatchStatus = nil
    self._MapObjRoot = nil
    self._RectSize = nil
    self._MapObjRoot = nil
    self._HookObjDir = nil
    self._HookRoot = nil
    self.HookEntityList = nil
    self.StoneEntityList = nil
    self.QTEHookEntity = nil
    self.QTEStoneEntity = nil
    self.SystemHook = nil
    self.SystemStone = nil
    self.SystemMove = nil
    self.SystemBuff = nil
    self.SystemQTE = nil
    self.SystemTimeLimeAnim = nil
end
--endregion

--region GameCheck
function XGoldenMinerGame:CheckIsStoneClear()
    for _, stoneEntity in ipairs(self.StoneEntityList) do
        if not stoneEntity.HookDirectionPoint and
                stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED and
                stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.DESTROY
        then
            return false
        end
    end
    self._Status = GAME_STATUS.END
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_STONE_CLEAR)
    return true
end

---防止卡顿跳帧
function XGoldenMinerGame:_CheckFrameTime(time)
    if time > MIN_FRAME_TIME then
        time = MIN_FRAME_TIME
    end
    return time
end

---@param status number GAME_STATUS
function XGoldenMinerGame:_IsStatus(status)
    return self._Status == status
end

function XGoldenMinerGame:IsRunning()
    return self:_IsStatus(GAME_STATUS.INIT)
            or self:IsPlay()
            or self:IsQTE()
            or self:IsTimeStop()
end

function XGoldenMinerGame:IsPlay()
    return self:_IsStatus(GAME_STATUS.PLAY)
end

function XGoldenMinerGame:IsQTE()
    return self:_IsStatus(GAME_STATUS.QTE)
end

function XGoldenMinerGame:IsPause(reason)
    local isReason = true
    if reason then
        isReason = self._PauseReason & reason ~= XGoldenMinerConfigs.GAME_PAUSE_TYPE.NONE
    end
    return self:_IsStatus(GAME_STATUS.PAUSE) and isReason
end

function XGoldenMinerGame:IsTimeStop()
    return self:_IsStatus(GAME_STATUS.TIME_STOP)
end

function XGoldenMinerGame:IsEnd()
    return self:_IsStatus(GAME_STATUS.END)
end
--endregion

--region Data
---@param data XGoldenMinerGameData
function XGoldenMinerGame:SetData(data)
    self._Data = data
end

function XGoldenMinerGame:SetBuffIdList(buffIdList)
    self.BuffIdList = buffIdList
end

---@param mapObjRoot UnityEngine.Transform
function XGoldenMinerGame:SetMapObjRoot(mapObjRoot)
    self._MapObjRoot = mapObjRoot
end

---@param rectSize UnityEngine.Vector2
function XGoldenMinerGame:SetRectSize(rectSize)
    self._RectSize = rectSize
end

---@param hookObjDir UnityEngine.Transform[]
function XGoldenMinerGame:SetHookObjDir(hookObjDir)
    self._HookObjDir = hookObjDir
end

---@param hookColliderDir UnityEngine.Collider2D[]
function XGoldenMinerGame:SetHookColliderDir(hookRoot)
    self._HookRoot = hookRoot
end

function XGoldenMinerGame:GetData()
    return self._Data
end

function XGoldenMinerGame:GetCurScore()
    if not self._Data then
        return 0
    end
    return self._Data:GetCurScore()
end

function XGoldenMinerGame:GetChangeScore()
    if not self._Data then
        return 0
    end
    return self._Data:GetChangeScore()
end

function XGoldenMinerGame:GetOldScore()
    if not self._Data then
        return 0
    end
    return self._Data:GetOldScore()
end

---@return XGoldenMinerEntityStone[]
function XGoldenMinerGame:GetGrabbedStoneEntityList()
    local result = {}
    for _, hookEntity in ipairs(self.HookEntityList) do
        if not XTool.IsTableEmpty(hookEntity.HookGrabbedStoneList) then
            for _, stoneEntity in ipairs(hookEntity.HookGrabbedStoneList) do
                result[#result + 1] = stoneEntity
            end
        end
    end
    return result
end

---@return XGoldenMinerEntityStone[]
function XGoldenMinerGame:GetGrabbedScoreDir()
    local result = {}
    local AddScore = function(type, score)
        if not XTool.IsNumberValid(result[type]) then
            result[type] = 0
        end
        result[type] = result[type] + score
    end
    for _, hookEntity in ipairs(self.HookEntityList) do
        if not XTool.IsTableEmpty(hookEntity.HookGrabbedStoneList) then
            for _, stoneEntity in ipairs(hookEntity.HookGrabbedStoneList) do
                local type = stoneEntity.Data:GetType()
                if type == XGoldenMinerConfigs.StoneType.Mussel and stoneEntity.CarryStone then
                    type = stoneEntity.CarryStone.Data:GetType()
                end
                AddScore(type, stoneEntity.Stone.CurScore)
                if stoneEntity.CarryStone then
                    AddScore(type, stoneEntity.CarryStone.Stone.CurScore)
                end
                if stoneEntity.QTE then
                    AddScore(type, stoneEntity.QTE.AddScore)
                end
            end
        end
    end
    return result
end

function XGoldenMinerGame:GetStopTime()
    if not self.SystemBuff then
        return 0
    end
    local time = 0
    ---@type XGoldenMinerComponentBuff
    local buff
    buff = self.SystemBuff:GetAliveBuffByType(self.BuffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerUseItemStopTime)
    if buff then
        time = time + buff.Time
    end
    buff = self.SystemBuff:GetAliveBuffByType(self.BuffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerItemStopTime)
    if buff then
        time = time + buff.Time
    end
    return math.ceil(time)
end

function XGoldenMinerGame:AddMapScore(score)
    self._Data:SetMapScore(self._Data:GetMapScore() + score)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_SCORE)
end

function XGoldenMinerGame:AddTime(time)
    self._Data:SetTime(self._Data:GetTime() + time)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_TIME, time)
end

function XGoldenMinerGame:AddItem(itemId)
    if not XTool.IsNumberValid(itemId) then
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_ITEM, itemId)
end
--endregion

--region Data - Time
---@param usedTime number 经过的时间
function XGoldenMinerGame:UpdateTime(usedTime)
    if self:IsEnd() then
        return
    end
    local curUsedTime = self._Data:GetUsedTime()
    self._Data:SetUsedTime(curUsedTime + usedTime)
    self:ChangeTime(usedTime)
end

---改变时间
function XGoldenMinerGame:ChangeTime(usedTime)
    local curTime = self._Data:GetTime()
    self._Data:SetTime(curTime - usedTime)
    if self._Data:IsTimeOut() then
        self._Status = GAME_STATUS.END
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_TIMEOUT)
    end
end
--endregion

--region Data - HideTask
---隐藏任务
---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerGame:CheckHideTask(hookEntity)
    if XTool.IsTableEmpty(hookEntity.HookGrabbingStoneList) then
        return
    end
    local hideTaskList = self._Data:GetHideTaskInfoList()
    if XTool.IsTableEmpty(hideTaskList) then
        return
    end
    for _, hideTaskInfo in ipairs(hideTaskList) do
        if not hideTaskInfo:IsFinish() then
            local type = hideTaskInfo:GetType()
            if type == XGoldenMinerConfigs.HideTaskType.GrabStone then
                for _, stoneEntity in ipairs(hookEntity.HookGrabbingStoneList) do
                    if stoneEntity.Data:GetId() == hideTaskInfo:GetParams()[1] then
                        hideTaskInfo:AddCurProgress()
                    end
                end
            elseif type == XGoldenMinerConfigs.HideTaskType.GrabStoneByOnce then
                local isFinish = false
                for _, stoneEntity in ipairs(hookEntity.HookGrabbingStoneList) do
                    if stoneEntity.Data:GetId() == hideTaskInfo:GetParams()[1] then
                        hideTaskInfo:SetCatchValue(hideTaskInfo:GetCatchValue() + 1)
                        isFinish = hideTaskInfo:GetCatchValue() >= hideTaskInfo:GetParams()[2]
                    end
                end
                if isFinish then
                    hideTaskInfo:AddCurProgress()
                end
            elseif type == XGoldenMinerConfigs.HideTaskType.GrabStoneInBuff then
                -- 在某Buff加持下抓取物品
                if self:CheckHasBuffByBuffId(hideTaskInfo:GetParams()[2]) then
                    for _, stoneEntity in ipairs(hookEntity.HookGrabbingStoneList) do
                        if stoneEntity.Data:GetId() == hideTaskInfo:GetParams()[1] then
                            hideTaskInfo:AddCurProgress()
                        end
                    end
                end
            elseif type == XGoldenMinerConfigs.HideTaskType.GrabStoneByReflection then
                local isGrab = false
                local isHitCount = 0
                for _, stoneEntity in ipairs(hookEntity.HookGrabbingStoneList) do
                    if stoneEntity.Data:GetId() == hideTaskInfo:GetParams()[1] then
                        isGrab = true
                    end
                end

                if not XTool.IsTableEmpty(hookEntity.HookHitStoneList) then
                    for i = 2, #hideTaskInfo:GetParams() do
                        for _, stoneEntity in ipairs(hookEntity.HookHitStoneList) do
                            if stoneEntity.Data:GetId() == hideTaskInfo:GetParams()[i] then
                                isHitCount = isHitCount + 1
                            end
                        end
                    end
                end
                if isGrab and isHitCount >= #hideTaskInfo:GetParams() - 1 then
                    hideTaskInfo:AddCurProgress()
                end
            elseif type == XGoldenMinerConfigs.HideTaskType.GrabDrawMap then
                local mapDrawGroup = XGoldenMinerConfigs.GetHideTaskMapDrawGroup(hideTaskInfo:GetParams()[1])
                local isFinish = true
                for _, drawId in ipairs(mapDrawGroup) do
                    local index = XGoldenMinerConfigs.GetHideTaskMapDrawGroupStoneIdIndex(drawId)
                    local isStay = XGoldenMinerConfigs.GetHideTaskMapDrawGroupIsStay(drawId)
                    local stoneEntity = self.StoneEntityList[index]
                    if isStay then
                        if stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE then
                            isFinish = false
                        end
                    else
                        if stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED
                                and stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_DESTROY
                                and stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.DESTROY
                        then
                            isFinish = false
                        end
                    end
                end
                if isFinish then
                    hideTaskInfo:AddCurProgress()
                end
            end
            if hideTaskInfo:IsFinish() then
                --XGoldenMinerConfigs.DebugLog("隐藏任务完成:HideTaskId="..hideTaskInfo:GetId())
            end
        end
    end
end

---隐藏任务缓存值清除
function XGoldenMinerGame:ClearHideTaskCatch()
    local hideTaskList = self._Data:GetHideTaskInfoList()
    if XTool.IsTableEmpty(hideTaskList) then
        return
    end
    for _, hideTaskInfo in ipairs(hideTaskList) do
        if not hideTaskInfo:IsFinish() then
            hideTaskInfo:SetCatchValue(0)
        end
    end
end
--endregion

--region System - HookEntity
function XGoldenMinerGame:InitHook()
    self.HookEntityList = {}
    for _, type in ipairs(self._Data:GetHookTypeList()) do
        ---@type XGoldenMinerEntityHook
        local hookEntity = XGoldenMinerEntityHook.New()
        hookEntity.Hook = self:_CreateHookComponent(type, self._HookObjDir[type], self._HookRoot)
        hookEntity.HookGrabbingStoneList = {}
        hookEntity.HookGrabbedStoneList = {}
        hookEntity.HookHitStoneList = {}

        for _, aim in pairs(hookEntity.Hook.AimTranList) do
            local length = math.ceil(math.sqrt(self._RectSize.x ^ 2 + self._RectSize.y ^ 2))
            local rectTran = aim.gameObject:GetComponent("RectTransform")
            local sizeDelta = rectTran.sizeDelta
            rectTran.sizeDelta = Vector2(sizeDelta.x, length)
            aim.gameObject:SetActiveEx(false)
        end
        self:RegisterHookHitCallBack(hookEntity)
        self.HookEntityList[#self.HookEntityList + 1] = hookEntity
    end

    if self.SystemHook then
        self.SystemHook:Init(self)
    end
end

function XGoldenMinerGame:UpdateHook(time)
    if self:IsEnd() then
        return
    end
    if not self.SystemHook then
        return
    end
    self.SystemHook:Update(self, time)
end

---@return XGoldenMinerComponentHook
function XGoldenMinerGame:_CreateHookComponent(type, hookObj, hookRoot)
    if XTool.UObjIsNil(hookObj) then
        return false
    end
    ---@type XGoldenMinerComponentHook
    local hook = XGoldenMinerComponentHook.New()
    hook.Type = type
    hook.Transform = hookObj

    hook.HookObj = XUiHelper.TryGetComponent(hook.Transform, "Hook")
    hook.HookObjStartLocalPosition = hook.HookObj.localPosition
    hook.RopeObjList = { XUiHelper.TryGetComponent(hook.Transform, "RopeRoot/Rope") }
    hook.RopeObjStartLocalPosition = hook.RopeObjList[1].localPosition

    local Collider2DList = hook.HookObj.gameObject:GetComponentsInChildren(typeof(CS.UnityEngine.Collider2D))
    for i = 0, Collider2DList.Length - 1 do
        hook.ColliderList[i + 1] = Collider2DList[i]
        hook.GoInputHandlerList[i + 1] = hook.ColliderList[i + 1].transform:GetComponent(typeof(CS.XGoInputHandler))
        if XTool.UObjIsNil(hook.GoInputHandlerList[i + 1]) then
            hook.GoInputHandlerList[i + 1] = hook.ColliderList[i + 1].transform.gameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
    end
    -- 绳子碰撞点，用于碰撞转向点
    local ropeColliderObj = XUiHelper.TryGetComponent(hook.Transform, "RopeCollider")
    if ropeColliderObj then
        hook.RopeCollider = ropeColliderObj.transform:GetComponent(typeof(CS.UnityEngine.Collider2D))
        hook.RopeInputHandler = hook.RopeCollider.transform:GetComponent(typeof(CS.XGoInputHandler))
        if XTool.UObjIsNil(hook.RopeInputHandler) then
            hook.RopeInputHandler = hook.RopeCollider.gameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
    end

    hook.GrabPoint = XUiHelper.TryGetComponent(hook.Transform, "Hook/RopeCord/TriggerObjs")
    hook.AimTranList = {
        XUiHelper.TryGetComponent(hook.Transform, "Hook/RopeCord/Aim"),
        XUiHelper.TryGetComponent(hook.Transform, "Hook/RopeCord/Aim2"),
        XUiHelper.TryGetComponent(hook.Transform, "Hook/RopeCord/Aim3")
    }

    hook.RopeMaxLength = math.ceil(math.sqrt(self._RectSize.x ^ 2 + self._RectSize.y ^ 2) + XGoldenMinerConfigs.GetHookRopeExLength())
    hook.RopeMinLength = hook.RopeObjList[1].sizeDelta.y
    hook.RopeLength = hook.RopeMinLength
    hook.IdleSpeed = XGoldenMinerConfigs.GetRopeRockSpeed()
    hook.ShootSpeed = XGoldenMinerConfigs.GetRopeStretchSpeed()
    hook.CurShootSpeed = hook.ShootSpeed
    hook.IdleRotateDirection = false
    hook.CurIdleRotateAngle = hook.Transform.localRotation.eulerAngles
    return hook
end

---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerGame:RegisterHookHitCallBack(hookEntity)
    if not hookEntity.Hook or XTool.IsTableEmpty(hookEntity.Hook.GoInputHandlerList) then
        return
    end
    for _, goInputHandler in ipairs(hookEntity.Hook.GoInputHandlerList) do
        goInputHandler:AddTriggerEnter2DCallback(function(collider)
            self:HookHit(hookEntity, collider)
        end)
    end
    if hookEntity.Hook.RopeInputHandler then
        hookEntity.Hook.RopeInputHandler:AddTriggerEnter2DCallback(function(collider)
            self:RopeHit(hookEntity, collider)
        end)
    end
end

function XGoldenMinerGame:HookShoot()
    self:ClearHideTaskCatch()
    if self.SystemHook then
        self.SystemHook:HookShoot(self)
    end
end

---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:HookGrab(hookEntity, stoneEntity)
    if not self.SystemHook then
        return
    end

    self:SetStoneGrab(hookEntity, stoneEntity)
    if self.SystemTimeLimeAnim then
        self.SystemTimeLimeAnim:PlayAnim(hookEntity, XGoldenMinerConfigs.GAME_ANIM.HOOK_CLOSE, function()
            self:HookRevoke(hookEntity)
        end)
    else
        self.SystemHook:HookRevoke(self, hookEntity.Hook)
    end
end

---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerGame:HookRevoke(hookEntity)
    if self.SystemHook then
        self.SystemHook:HookRevoke(self, hookEntity.Hook)
    end
end

---@param hookEntity XGoldenMinerEntityHook
---@param collider UnityEngine.Collider2D
function XGoldenMinerGame:HookHit(hookEntity, collider)
    local stoneEntity = self:FindStoneEntityByCollider(collider)
    local hitHookEntity = self:FindHookEntityByCollider(collider)
    if hitHookEntity then
        return
    end
    if self.SystemHook then
        self.SystemHook:OnHookHit(self, hookEntity, stoneEntity)
    end
end

---@param hookEntity XGoldenMinerEntityHook
---@param collider UnityEngine.Collider2D
function XGoldenMinerGame:RopeHit(hookEntity, collider)
    local stoneEntity = self:FindStoneEntityByCollider(collider)
    local hitHookEntity = self:FindHookEntityByCollider(collider)
    if hitHookEntity then
        return
    end
    if self.SystemHook then
        self.SystemHook:OnRopeHit(self, hookEntity, stoneEntity)
    end
end

---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerGame:OnHookRevokeToIdle(hookEntity)
    local score = 0
    -- 收回
    for _, stoneEntity in ipairs(hookEntity.HookGrabbingStoneList) do
        if stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED then
            -- Buff
            self:TriggerStoneGrabBuff(stoneEntity)
            -- 加分
            score = score + stoneEntity.Stone.CurScore
            -- 特殊抓取物触发
            self:CheckHookRevokeToIdle(stoneEntity)

            if stoneEntity.CarryStone then
                score = score + stoneEntity.CarryStone.Stone.CurScore
                self:CheckHookRevokeToIdle(stoneEntity.CarryStone)
            end

            if stoneEntity.QTE then
                score = score + stoneEntity.QTE.AddScore
                if XTool.IsNumberValid(stoneEntity.QTE.AddBuff) then
                    self:AddBuff(stoneEntity.QTE.AddBuff)
                end
                if XTool.IsNumberValid(stoneEntity.QTE.AddItemId) then
                    self:AddItem(stoneEntity.QTE.AddItemId)
                end
            end
        end
    end
    if self.SystemTimeLimeAnim and not XTool.IsTableEmpty(hookEntity.HookGrabbingStoneList) then
        self.SystemTimeLimeAnim:PlayAnim(hookEntity, XGoldenMinerConfigs.GAME_ANIM.HOOK_OPEN)
    end
    self:AddMapScore(score)
    -- 隐藏任务
    self:CheckHideTask(hookEntity)
    -- 表情
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
            XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.GRABBED,
            XGoldenMinerConfigs.GAME_FACE_PLAY_ID.GRABBED)
    -- 清理
    hookEntity.HookGrabbingStoneList = {}
    hookEntity.HookHitStoneList = {}
    self:TriggerCountRevokeEndCountBuff()
    self:CheckIsStoneClear()
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:CheckHookRevokeToIdle(stoneEntity)
    -- 特殊抓取物触发
    if stoneEntity.Data:GetType() == XGoldenMinerConfigs.StoneType.RedEnvelope then
        local redEnvelopeId = stoneEntity.AdditionValue[XGoldenMinerConfigs.StoneType.RedEnvelope]
        if not redEnvelopeId then
            local redEnvelopeGroup = stoneEntity.Data:GetRedEnvelopeGroup()
            redEnvelopeId = XGoldenMinerConfigs.GetRedEnvelopeRandId(redEnvelopeGroup)
            stoneEntity.AdditionValue[XGoldenMinerConfigs.StoneType.RedEnvelope] = redEnvelopeId
        end
        local itemId = XGoldenMinerConfigs.GetRedEnvelopeItemId(redEnvelopeId)
        stoneEntity.Stone.Score = itemId
        self:AddItem(itemId)
    elseif stoneEntity.Data:GetType() == XGoldenMinerConfigs.StoneType.AddTimeStone then
        self:AddTime(stoneEntity.Data:GetAddTimeStoneAddTime())
    elseif stoneEntity.Data:GetType() == XGoldenMinerConfigs.StoneType.ItemStone then
        self:UseItemToAddBuff(stoneEntity.Data:GetItemStoneItemId())
    end
end

function XGoldenMinerGame:HookAimRight()
    for _, hookEntity in ipairs(self.HookEntityList) do
        hookEntity.Hook.IdleRotateDirection = Vector3.forward
    end
end

function XGoldenMinerGame:HookAimLeft()
    for _, hookEntity in ipairs(self.HookEntityList) do
        hookEntity.Hook.IdleRotateDirection = Vector3.back
    end
end

function XGoldenMinerGame:HookAimIdle()
    for _, hookEntity in ipairs(self.HookEntityList) do
        hookEntity.Hook.IdleRotateDirection = false
    end
end

---@param hook XGoldenMinerComponentHook
---@return XGoldenMinerEntityHook
function XGoldenMinerGame:GetHookEntityByHook(hook)
    for _, hookEntity in ipairs(self.HookEntityList) do
        if hookEntity.Hook == hook then
            return hookEntity
        end
    end
    return false
end

---@param anim XGoldenMinerComponentTimeLineAnim
---@return XGoldenMinerEntityHook
function XGoldenMinerGame:GetHookEntityByAnim(anim)
    for _, hookEntity in ipairs(self.HookEntityList) do
        if hookEntity.Anim == anim then
            return hookEntity
        end
    end
    return false
end

---@param hookStatus number XGoldenMinerConfigs.GAME_HOOK_STATUS
---@return XGoldenMinerEntityStone[]
function XGoldenMinerGame:GetHookGrabEntity(hookStatus, stoneStatus)
    local stoneEntityList = {}
    for _, hookEntity in ipairs(self.HookEntityList) do
        if (not hookStatus or hookEntity.Hook.Status == hookStatus)
                and not XTool.IsTableEmpty(hookEntity.HookGrabbingStoneList) then
            for _, stoneEntity in ipairs(hookEntity.HookGrabbingStoneList) do
                if not stoneStatus or stoneEntity.Status == stoneStatus then
                    stoneEntityList[#stoneEntityList + 1] = stoneEntity
                end
            end
        end
    end
    return stoneEntityList
end

function XGoldenMinerGame:GetHookGrabWeight(stoneStatus)
    local stoneEntityList = self:GetHookGrabEntity(nil, stoneStatus)
    local weight = 0
    for _, stoneEntity in pairs(stoneEntityList) do
        weight = weight + stoneEntity.Stone.CurWeight
        if stoneEntity.CarryStone then
            weight = weight + stoneEntity.CarryStone.Stone.CurWeight
        end
    end
    return weight
end

function XGoldenMinerGame:GetHookGrabScore(stoneStatus)
    local stoneEntityList = self:GetHookGrabEntity(nil, stoneStatus)
    local score = 0
    for _, stoneEntity in pairs(stoneEntityList) do
        score = score + stoneEntity.Stone.CurScore
        if stoneEntity.CarryStone then
            score = score + stoneEntity.CarryStone.Stone.CurScore
        end
        if stoneEntity.QTE then
            score = score + stoneEntity.QTE.AddScore
        end
    end
    return score
end

---@param collider UnityEngine.Collider2D
---@return XGoldenMinerEntityHook
function XGoldenMinerGame:FindHookEntityByCollider(collider)
    if XTool.IsTableEmpty(self.HookEntityList) then
        return false
    end
    for _, entity in ipairs(self.HookEntityList) do
        if not XTool.IsTableEmpty(entity.Hook.ColliderList) then
            for _, hookCollider in ipairs(entity.Hook.ColliderList) do
                if hookCollider == collider then
                    return entity
                end
            end
        end
        if entity.Hook.RopeCollider and entity.Hook.RopeCollider == collider then
            return entity
        end
    end
    return false
end
--endregion

--region System - StoneEntity
function XGoldenMinerGame:InitMap()
    self.StoneEntityList = {}
    local mapStoneList = self._Data:GetMapStoneDataList()
    if XTool.IsTableEmpty(mapStoneList) then
        return
    end
    for _, stoneData in ipairs(mapStoneList) do
        local stoneEntity = self:CreateStoneEntity(stoneData)
        self.StoneEntityList[#self.StoneEntityList + 1] = stoneEntity
    end
    if self.SystemStone then
        self.SystemStone:Init(self)
    end
end

function XGoldenMinerGame:UpdateStone(time)
    if self:IsEnd() then
        return
    end
    if self.SystemStone then
        self.SystemStone:Update(self, time)
    end
    self:CheckIsStoneClear()
end

function XGoldenMinerGame:UpdateStoneMove(time)
    if self:IsEnd() then
        return
    end
    if self.SystemMove then
        self.SystemMove:Update(self, time)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:ChangeToGold(stoneEntity)
    if stoneEntity.Mouse or stoneEntity.Mussel then
        self:_CarryStoneChangeToGold(stoneEntity)
    else
        self:_StoneChangeToGold(stoneEntity)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:_StoneChangeToGold(stoneEntity)
    local goldId = XGoldenMinerConfigs.GetGoldIdByWeight(stoneEntity.Stone.Weight, stoneEntity.Data:GetId())
    if not goldId then
        return
    end

    local parent = stoneEntity.Stone.Transform.parent
    local stoneData = XGoldenMinerMapStoneData.New(goldId)

    XUiHelper.Destroy(stoneEntity.Stone.Transform.gameObject)

    stoneEntity.Data = stoneData
    stoneEntity.Stone = self:_CreateStoneComponent(stoneData)
    stoneEntity.Move = self:_CreateMoveComponent(stoneData, stoneEntity.Stone.Transform)
    stoneEntity.CarryStone = self:_CreateCarryStone(stoneEntity, stoneEntity.Data:GetCarryStoneId())
    stoneEntity.Anim = false

    stoneEntity.Stone.Transform:SetParent(parent, false)
    local rectTransform = stoneEntity.Stone.Transform:GetComponent("RectTransform")
    rectTransform.anchorMin = Vector2(0.5, 1)
    rectTransform.anchorMax = Vector2(0.5, 1)
    rectTransform.pivot = Vector2(0.5, 1)
    stoneEntity.Stone.Transform.localPosition = Vector3.zero
    stoneEntity.Stone.Transform.localRotation = CS.UnityEngine.Quaternion.identity
    stoneEntity.Stone.Score = stoneEntity.Data:GetScore()
    stoneEntity.Stone.CurScore = stoneEntity.Stone.Score
    stoneEntity.Mussel = false
    stoneEntity.QTE = false
end

---猫猫点石成金只改携带物
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:_CarryStoneChangeToGold(stoneEntity)
    -- 没有携带物则道具白用
    if not stoneEntity.CarryStone then
        return
    end
    local goldId = XGoldenMinerConfigs.GetGoldIdByWeight(stoneEntity.CarryStone.Data:GetWeight(), stoneEntity.Data:GetCarryStoneId())
    if not goldId then
        return
    end

    XUiHelper.Destroy(stoneEntity.CarryStone.Stone.Transform.gameObject)
    stoneEntity.CarryStone = nil
    stoneEntity.CarryStone = self:_CreateCarryStone(stoneEntity, goldId)
    
    stoneEntity.Stone.Score = stoneEntity.Data:GetScore()
    stoneEntity.Stone.CurScore = stoneEntity.Stone.Score
    stoneEntity.CarryStone.Stone.Score = stoneEntity.CarryStone.Data:GetScore()
    stoneEntity.CarryStone.Stone.CurScore = stoneEntity.CarryStone.Data:GetScore()
end

---@param stoneData XGoldenMinerMapStoneData
---@return XGoldenMinerEntityStone
function XGoldenMinerGame:CreateStoneEntity(stoneData)
    ---@type XGoldenMinerEntityStone
    local stoneEntity = XGoldenMinerEntityStone.New()
    stoneEntity.Data = stoneData
    stoneEntity.Stone = self:_CreateStoneComponent(stoneData)
    stoneEntity.Move = self:_CreateMoveComponent(stoneData, stoneEntity.Stone.Transform)
    stoneEntity.Mouse = self:_CreateMouseComponent(stoneData, stoneEntity.Stone.Transform)
    stoneEntity.QTE = self:_CreateQTEComponent(stoneData, stoneEntity.Stone.Transform)
    stoneEntity.Mussel = self:_CreateMusselComponent(stoneData, stoneEntity.Stone.Transform)
    stoneEntity.HookDirectionPoint = self:_CreateDirectionPointComponent(stoneData, stoneEntity.Stone.Transform)
    stoneEntity.CarryStone = self:_CreateCarryStone(stoneEntity, stoneEntity.Data:GetCarryStoneId())
    -- 注册抓取物间碰撞
    self:RegisterStoneHitCallBack(stoneEntity)
    self:_RegisterMusselHitCallBack(stoneEntity)
    return stoneEntity
end

---@param stoneEntity XGoldenMinerEntityStone
---@return XGoldenMinerEntityStone
function XGoldenMinerGame:_CreateCarryStone(stoneEntity, carryStoneId)
    if not stoneEntity.Stone or not stoneEntity.Data:IsHaveCarryStone() then
        return false
    end
    if stoneEntity.Mouse then
        stoneEntity.Stone.CarryItemParent = stoneEntity.Mouse.CarryPoint[XGoldenMinerConfigs.GAME_MOUSE_STATE.ALIVE]
    elseif stoneEntity.Mussel and stoneEntity.Mussel.GrabCarry then
        stoneEntity.Stone.CarryItemParent = stoneEntity.Mussel.GrabCarry
    else
        stoneEntity.Stone.CarryItemParent = stoneEntity.Stone.Transform
    end
    if not stoneEntity.Stone.CarryItemParent then
        return false
    end

    ---@type XGoldenMinerEntityStone
    local carryStone = XGoldenMinerEntityStone.New()
    local carryStoneData = XGoldenMinerMapStoneData.New(carryStoneId)
    carryStone.Data = carryStoneData
    carryStone.Stone = XGoldenMinerComponentStone.New()
    carryStone.Stone.Transform = self:_LoadStone(carryStoneData, stoneEntity.Stone.CarryItemParent)
    carryStone.Stone.Collider = XUiHelper.TryGetComponent(carryStone.Stone.Transform, "", "Collider2D")
    -- 携带物不需要碰撞体
    if carryStone.Stone.Collider then
        carryStone.Stone.Collider.enabled = false
    end
    -- 不移动不处理移动方向
    if stoneEntity.Move and stoneEntity.Move.MoveType == XGoldenMinerConfigs.StoneMoveType.None
            or not stoneEntity.Move then
        return carryStone
    end
    -- 携带物要处理方向
    carryStone.Stone.Transform.localScale = Vector3(
            carryStone.Stone.Transform.localScale.x * stoneEntity.Data:GetStartMoveDirection(),
            carryStone.Stone.Transform.localScale.y,
            carryStone.Stone.Transform.localScale.z)

    if carryStoneData:GetType() == XGoldenMinerConfigs.StoneType.Boom then  -- 爆炸物默认碰撞体关闭
        carryStone.Stone.BoomCollider = XUiHelper.TryGetComponent(carryStone.Stone.Transform, "", "CircleCollider2D")
        if carryStone.Stone.BoomCollider then
            carryStone.Stone.BoomCollider.enabled = false
        end
    end
    return carryStone
end

---@param stoneData XGoldenMinerMapStoneData
---@return XGoldenMinerComponentStone
function XGoldenMinerGame:_CreateStoneComponent(stoneData)
    ---@type XGoldenMinerComponentStone
    local stone = XGoldenMinerComponentStone.New()
    stone.Transform = self:_LoadStone(stoneData, self._MapObjRoot)
    if not stone.Transform then
        XLog.Error("抓取物创建失败!请检查Prefab字段!id="..stoneData:GetId())
    end
    stone.Collider = XUiHelper.TryGetComponent(stone.Transform, "", "Collider2D")
    stone.BornDelayTime = stoneData:GetBornDelay()
    stone.AutoDestroyTime = stoneData:GetDestroyTime() > 0 and (stoneData:GetBornDelay() + stoneData:GetDestroyTime()) or 0
    stone.BeDestroyTime = 0
    stone.HideTime = 0
    stone.GoInputHandler = stone.Transform:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(stone.GoInputHandler) then
        stone.GoInputHandler = stone.Transform.gameObject:AddComponent(typeof(CS.XGoInputHandler))
    end

    if stoneData:GetType() == XGoldenMinerConfigs.StoneType.Boom then  -- 爆炸物默认碰撞体关闭
        stone.BoomCollider = XUiHelper.TryGetComponent(stone.Transform, "", "CircleCollider2D")
        if stone.BoomCollider then
            stone.BoomCollider.enabled = false
        end
    end
    return stone
end

---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentQTE
function XGoldenMinerGame:_CreateQTEComponent(stoneData, transform)
    if not stoneData:IsHaveQTE() then
        return false
    end
    ---@type XGoldenMinerComponentQTE
    local qte = XGoldenMinerComponentQTE.New()
    qte.QTEGroupId = stoneData:GetQTEGroupId()
    qte.Time = stoneData:GetQTETime()
    if self.SystemQTE then
        self.SystemQTE:InitQTE(qte, transform)
    end
    return qte
end

---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentMussel
function XGoldenMinerGame:_CreateMusselComponent(stoneData, transform)
    if not stoneData:IsHaveMussel() then
        return false
    end
    ---@type XGoldenMinerComponentMussel
    local mussel = XGoldenMinerComponentMussel.New()
    mussel.CanHide = true
    mussel.IsGrabbed = stoneData:GetMusselIsGrabbed()
    mussel.InitIsOpen = stoneData:GetMusselInitIsOpen()
    mussel.OpenTime = stoneData:GetMusselOpenTime()
    mussel.HideTime = stoneData:GetMusselHideTime()
    mussel.AnimOpen = XUiHelper.TryGetComponent(transform, "AnimOpen/Open")
    mussel.AnimClose = XUiHelper.TryGetComponent(transform, "AnimClose/Close")
    mussel.OpenCollider = XUiHelper.TryGetComponent(transform, "AnimOpen", "Collider2D")
    mussel.CloseCollider = XUiHelper.TryGetComponent(transform, "AnimClose", "Collider2D")
    mussel.GrabCarry = XUiHelper.TryGetComponent(transform, "UiGoldenMinerBx04/ContentPos")
    if not mussel.GrabCarry then
        mussel.GrabCarry = XUiHelper.TryGetComponent(transform, "ContentPos")
    end
    if mussel.InitIsOpen then
        mussel.Status = XGoldenMinerConfigs.GAME_MUSSEL_STATUS.OPEN
        mussel.CurTime = mussel.OpenTime
    else
        mussel.Status = XGoldenMinerConfigs.GAME_MUSSEL_STATUS.CLOSE
        mussel.CurTime = mussel.HideTime
    end
    if mussel.AnimOpen then
        mussel.AnimOpen.gameObject:SetActiveEx(mussel.Status == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.OPEN)
        mussel.AnimClose.gameObject:SetActiveEx(mussel.Status == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.CLOSE)
    end
    if mussel.OpenCollider then
        mussel.OpenCollider.gameObject:SetActiveEx(mussel.Status == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.OPEN)
        mussel.OpenGoInputHandler = mussel.OpenCollider.transform:GetComponent(typeof(CS.XGoInputHandler))
        if XTool.UObjIsNil(mussel.OpenGoInputHandler) then
            mussel.OpenGoInputHandler = mussel.OpenCollider.gameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
    end
    if mussel.CloseCollider then
        mussel.CloseCollider.gameObject:SetActiveEx(mussel.Status == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.CLOSE)
        mussel.CloseGoInputHandler = mussel.CloseCollider.transform:GetComponent(typeof(CS.XGoInputHandler))
        if XTool.UObjIsNil(mussel.CloseGoInputHandler) then
            mussel.CloseGoInputHandler = mussel.CloseCollider.gameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
    end
    return mussel
end

---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentMussel
function XGoldenMinerGame:_CreateMouseComponent(stoneData, transform)
    if not (stoneData:GetType() == XGoldenMinerConfigs.StoneType.Mouse) then
        return false
    end

    ---@type XGoldenMinerComponentMouse
    local component = XGoldenMinerComponentMouse.New()
    component.IsBoom = false
    component.StateTrans[XGoldenMinerConfigs.GAME_MOUSE_STATE.ALIVE] = XUiHelper.TryGetComponent(transform, "Run")
    component.StateTrans[XGoldenMinerConfigs.GAME_MOUSE_STATE.GRABBING] = XUiHelper.TryGetComponent(transform, "Grab")
    component.StateTrans[XGoldenMinerConfigs.GAME_MOUSE_STATE.BOOM] = XUiHelper.TryGetComponent(transform, "Bomb")

    component.CarryPoint[XGoldenMinerConfigs.GAME_MOUSE_STATE.ALIVE] = XUiHelper.TryGetComponent(transform, "Run/RunCarryItemParent")
    component.CarryPoint[XGoldenMinerConfigs.GAME_MOUSE_STATE.GRABBING] = XUiHelper.TryGetComponent(transform, "Grab/GrabCarryItemParent")
    return component
end

---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentDirectionPoint
function XGoldenMinerGame:_CreateDirectionPointComponent(stoneData, transform)
    if not stoneData:IsHaveDirectionPoint() then
        return false
    end
    ---@type XGoldenMinerComponentDirectionPoint
    local directionPoint = XGoldenMinerComponentDirectionPoint.New()
    directionPoint.AngleList = stoneData:GetHookDirectionPointAngleList()
    directionPoint.AngleTimeList = stoneData:GetHookDirectionPointTimeList()
    directionPoint.CurAngleIndex = 1
    directionPoint.CurTime = directionPoint.AngleTimeList[directionPoint.CurAngleIndex]
    directionPoint.AngleTransform = transform
    directionPoint.FillImage = XUiHelper.TryGetComponent(transform, "RImgBg03", "Image")
    return directionPoint
end

---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentMove
function XGoldenMinerGame:_CreateMoveComponent(stoneData, transform)
    if not transform or XTool.UObjIsNil(transform) then
        return false
    end
    ---@type XGoldenMinerComponentMove
    local move = XGoldenMinerComponentMove.New()
    move.MoveType = stoneData:GetMoveType()
    -- 静止的物体不需要其他参数
    if move.MoveType == XGoldenMinerConfigs.StoneMoveType.None then
        return move
    end
    move.StartDirection = stoneData:GetStartMoveDirection()
    move.CurDirection = stoneData:GetStartMoveDirection()
    move.Speed = stoneData:GetMoveSpeed()
    if move.MoveType == XGoldenMinerConfigs.StoneMoveType.Circle then
        local x =  transform.localPosition.x + stoneData:GetMoveRange() * math.cos(move.StartDirection / 180 * math.pi)
        local y =  transform.localPosition.y + stoneData:GetMoveRange() * math.sin(move.StartDirection / 180 * math.pi)
        move.CircleMovePoint = transform.position
        move.StartPoint = Vector3(x, y, 0)
        transform:Rotate(0, 0, move.CurDirection - 90)
        transform.localPosition = move.StartPoint
    else
        move.StartPoint = transform.localPosition
        local aLimit, bLimit
        if move.MoveType == XGoldenMinerConfigs.StoneMoveType.Horizontal then
            aLimit = transform.localPosition.x
        elseif move.MoveType == XGoldenMinerConfigs.StoneMoveType.Vertical then
            aLimit = transform.localPosition.y
        end
        bLimit = aLimit + move.StartDirection * stoneData:GetMoveRange()
        move.MoveMinLimit = math.min(aLimit, bLimit)
        move.MoveMaxLimit = math.max(aLimit, bLimit)
    end

    -- 定春需要处理方向
    if stoneData:GetType() == XGoldenMinerConfigs.StoneType.Mouse
            and move.MoveType ~= XGoldenMinerConfigs.StoneMoveType.None
            and move.MoveType ~= XGoldenMinerConfigs.StoneMoveType.Circle then
        transform.localScale = Vector3(
                transform.localScale.x * stoneData:GetStartMoveDirection(),
                transform.localScale.y,
                transform.localScale.z)
    end
    return move
end

---@param stoneData XGoldenMinerMapStoneData
---@param objRoot UnityEngine.Transform
---@return UnityEngine.Transform
function XGoldenMinerGame:_LoadStone(stoneData, objRoot)
    local path = stoneData:GetPrefab()
    
    if string.IsNilOrEmpty(path) or not objRoot or not self._RectSize then
        return
    end
    local resource = self._ResourcePool[path]
    if not resource then
        resource = CSXResourceManagerLoad(path)
        self._ResourcePool[path] = resource
    end

    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XGoldenMinerGame:LoadStone加载资源，路径：%s", path))
        return
    end

    local obj = XUiHelper.Instantiate(resource.Asset, objRoot)
    -- 抓取物的携带物不存在index,直接返回
    if not XTool.IsNumberValid(stoneData:GetMapIndex()) then
        obj.transform.localPosition = Vector3.zero
        return obj.transform
    end

    local width = self._RectSize.x
    local height = self._RectSize.y
    local xPosPercent = stoneData:GetXPosPercent() / MILLION_PERCENT
    local yPosPercent = stoneData:GetYPosPercent() / MILLION_PERCENT
    local scale = stoneData:GetScale() / MILLION_PERCENT
    local rotationZ = stoneData:GetRotationZ() / W_PERCENT
    obj.transform.localPosition = Vector3(xPosPercent * width, yPosPercent * height, 0)
    obj.transform.localScale = Vector3(scale, scale, scale)
    obj.transform.localEulerAngles = Vector3(0, 0, rotationZ)
    return obj.transform
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:RegisterStoneHitCallBack(stoneEntity)
    if not stoneEntity or not stoneEntity.Stone.GoInputHandler or XTool.UObjIsNil(stoneEntity.Stone.GoInputHandler) then
        return
    end
    stoneEntity.Stone.GoInputHandler:AddTriggerEnter2DCallback(function(collider)
        self:StoneHit(stoneEntity, collider)
    end)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:_RegisterMusselHitCallBack(stoneEntity)
    if not stoneEntity or not stoneEntity.Mussel or not stoneEntity.Mussel.OpenGoInputHandler then
        return
    end
    stoneEntity.Mussel.OpenGoInputHandler:AddTriggerEnter2DCallback(function(collider)
        self:StoneHit(stoneEntity, collider)
    end)
    stoneEntity.Mussel.CloseGoInputHandler:AddTriggerEnter2DCallback(function(collider)
        self:StoneHit(stoneEntity, collider)
    end)
end

---@param stoneEntity XGoldenMinerEntityStone
---@param collider UnityEngine.Collider2D
function XGoldenMinerGame:StoneHit(stoneEntity, collider)
    local beHitStoneEntity = self:FindStoneEntityByCollider(collider)
    if self.SystemStone then
        self.SystemStone:OnStoneHit(stoneEntity, beHitStoneEntity)
    end
end

---@param collider UnityEngine.Collider2D
function XGoldenMinerGame:FindStoneEntityByCollider(collider)
    if XTool.IsTableEmpty(self.StoneEntityList) then
        return false
    end
    for _, entity in ipairs(self.StoneEntityList) do
        if entity.Stone.Transform and entity.Stone.Transform == collider.transform then
            return entity
        end
        if entity.Mussel then
            if entity.Mussel.OpenCollider and entity.Mussel.OpenCollider == collider then
                return entity
            end
            if entity.Mussel.CloseCollider and entity.Mussel.CloseCollider == collider then
                return entity
            end
        end
        if entity.CarryStone
                and entity.CarryStone.Stone.Transform
                and entity.CarryStone.Stone.Transform == collider.transform then
            return entity
        end
    end
    return false
end

---@param stoneEntity XGoldenMinerEntityStone
---@param status number XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS
function XGoldenMinerGame:SetStoneEntityStatus(stoneEntity, status)
    self.SystemStone:SetStoneEntityStatus(stoneEntity, status)
end

---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:SetStoneGrab(hookEntity, stoneEntity)
    hookEntity.HookGrabbingStoneList[#hookEntity.HookGrabbingStoneList + 1] = stoneEntity
    self.SystemHook:HookGrab(self, hookEntity.Hook, stoneEntity)
    self:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:SetCarryStoneBoom(stoneEntity)
    if not stoneEntity.CarryStone then
        return
    end
    if stoneEntity.CarryStone.Stone.BoomCollider then
        stoneEntity.CarryStone.Stone.BoomCollider.enabled = true
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                XGoldenMinerConfigs.GAME_EFFECT_TYPE.STONE_BOOM,
                stoneEntity.CarryStone.Stone.Transform,
                stoneEntity.CarryStone.Data:GetCatchEffect())
    end
end

---@param stoneType number XGoldenMinerConfigs.StoneType
---@param stoneStatusType number XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS
---@return XGoldenMinerEntityStone[]
function XGoldenMinerGame:GetStoneEntityList(stoneType, stoneStatusType)
    local result = {}
    for _, stoneEntity in ipairs(self.StoneEntityList) do
        if (not stoneStatusType or stoneEntity.Status == stoneStatusType) and
                (not stoneType or stoneEntity.Data:GetType() == stoneType) then
            result[#result + 1] = stoneEntity
        end
    end
    return result
end
--endregion

--region System - QTE
---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:QTEStart(hookEntity, stoneEntity)
    if self:IsEnd() or self:IsPause() then
        return
    end
    if self:IsQTE() then
        if self.QTEHookEntity and self.QTEHookEntity ~= hookEntity
                and self.QTEStoneEntity and self.QTEStoneEntity ~= stoneEntity
                and not table.indexof(self.QTECatchHookEntityList, hookEntity)
                and not table.indexof(self.QTECatchStoneEntityList, stoneEntity)
        then
            self.QTECatchHookEntityList[#self.QTECatchHookEntityList + 1] = hookEntity
            self.QTECatchStoneEntityList[#self.QTECatchStoneEntityList + 1] = stoneEntity
        end
        return
    end
    if not self:IsQTE() then
        self._QTECatchStatus = self._Status
    end
    self.QTEHookEntity = hookEntity
    self.QTEStoneEntity = stoneEntity
    self._Status = GAME_STATUS.QTE
end

function XGoldenMinerGame:QTEResume()
    if self:IsEnd() or self:IsPause() then
        return
    end
    if self._QTECatchStatus == GAME_STATUS.NONE then
        return
    end
    self._Status = self._QTECatchStatus
end

function XGoldenMinerGame:UpdateQTE(time)
    if self:IsEnd() then
        return
    end
    if self.SystemQTE then
        self.SystemQTE:Update(self, time)
    end
end

function XGoldenMinerGame:QTEClick()
    if not self:IsQTE() then
        return
    end
    if self.SystemQTE then
        self.SystemQTE:ClickQTE(self)
    end
end

function XGoldenMinerGame:QTECrab()
    if not self:IsQTE() then
        return
    end
    
    local QTE = self.QTEStoneEntity.QTE
    local qteId = XGoldenMinerConfigs.GetQTELevelGroupByCount(QTE.QTEGroupId, QTE.CurClickCount)
    local params = XGoldenMinerConfigs.GetQTELevelGroupParams(qteId)
    local type = XGoldenMinerConfigs.GetQTELevelGroupType(qteId)
    if type == XGoldenMinerConfigs.QTEGroupType.Score then
        QTE.AddScore = params[1]
    elseif type == XGoldenMinerConfigs.QTEGroupType.Item then
        QTE.AddItemId = params[1]
    elseif type == XGoldenMinerConfigs.QTEGroupType.Buff then
        QTE.AddBuff = params[1]
    elseif type == XGoldenMinerConfigs.QTEGroupType.ScoreAndBuff then
        QTE.AddScore = params[1]
        QTE.AddBuff = params[2]
    elseif type == XGoldenMinerConfigs.QTEGroupType.ScoreAndItem then
        QTE.AddScore = params[1]
        QTE.AddItemId = params[2]
    elseif type == XGoldenMinerConfigs.QTEGroupType.BuffAndItem then
        QTE.AddBuff = params[1]
        QTE.AddItemId = params[2]
    elseif type == XGoldenMinerConfigs.QTEGroupType.All then
        QTE.AddScore = params[1]
        QTE.AddBuff = params[2]
        QTE.AddItemId = params[3]
    end
    
    if self.QTEHookEntity then
        -- 状态不对过滤
        if self.QTEHookEntity.Hook.Type == XGoldenMinerConfigs.FalculaType.Magnetic
                or self.QTEHookEntity.Hook.Type == XGoldenMinerConfigs.FalculaType.StorePressMagnetic then
            self:SetStoneGrab(self.QTEHookEntity, self.QTEStoneEntity)
        else
            self:HookGrab(self.QTEHookEntity, self.QTEStoneEntity)
        end
    end
    self.QTEHookEntity = false
    self.QTEStoneEntity = false
    self:QTEResume()
    self:QTECheck()
end

function XGoldenMinerGame:QTECheck()
    if XTool.IsTableEmpty(self.QTECatchHookEntityList) then
        return
    end
    local hookEntity = self.QTECatchHookEntityList[1]
    local stoneEntity = self.QTECatchStoneEntityList[1]
    local newHookList = {}
    local newStoneList = {}
    for i = 2, #self.QTECatchHookEntityList do
        newHookList[#newHookList + 1] = self.QTECatchHookEntityList[i]
        newStoneList[#newStoneList + 1] = self.QTECatchStoneEntityList[i]
    end
    self.QTECatchHookEntityList = newHookList
    self.QTECatchStoneEntityList = newStoneList
    self:QTEStart(hookEntity, stoneEntity)
end
--endregion

--region System - TimeLineAnim
function XGoldenMinerGame:InitTimeLineAnim()
    for _, entity in ipairs(self.HookEntityList) do
        entity.Anim = self:_CreateAnimComponent(entity.Hook.Transform)
    end
    for _, entity in ipairs(self.StoneEntityList) do
        if entity.Data:GetType() == XGoldenMinerConfigs.StoneType.Mouse then
            entity.Anim = self:_CreateAnimComponent(entity.Stone.Transform)
        end
    end
end

function XGoldenMinerGame:UpdateTimeLineAnim(time)
    if self:IsEnd() then
        return
    end
    if self.SystemTimeLimeAnim then
        self.SystemTimeLimeAnim:Update(self, time)
    end
end

---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentTimeLineAnim
function XGoldenMinerGame:_CreateAnimComponent(transform)
    if not transform or XTool.UObjIsNil(transform) then
        return false
    end
    ---@type XGoldenMinerComponentTimeLineAnim
    local anim = XGoldenMinerComponentTimeLineAnim.New()
    anim.AnimRoot = XUiHelper.TryGetComponent(transform, "Animation")
    anim.CurAnim = XGoldenMinerConfigs.GAME_ANIM.NONE
    anim.FinishCallBack = false
    anim.BePlayAnim = XGoldenMinerConfigs.GAME_ANIM.NONE
    anim.BeFinishCallBack = false
    return anim
end
--endregion

--region System - Buff&Item
function XGoldenMinerGame:InitBuff()
    if self.SystemBuff then
        self.SystemBuff:Init(self)
    end
end

function XGoldenMinerGame:UpdateBuff(time)
    if self:IsEnd() then
        return
    end
    if self.SystemBuff then
        self.SystemBuff:Update(self, time)
    end
end

---@return table<number, XGoldenMinerComponentBuff[]>
function XGoldenMinerGame:GetBuffDir()
    return self.BuffContainer.BuffTypeDir
end

function XGoldenMinerGame:CheckHasBuff(buffType)
    if self.SystemBuff then
        return self.SystemBuff:CheckHasBuff(self.BuffContainer, buffType)
    end
    return false
end

function XGoldenMinerGame:CheckHasBuffByBuffId(buffId)
    if self.SystemBuff then
        return self.SystemBuff:CheckHasBuffByBuffId(self.BuffContainer, XGoldenMinerConfigs.GetBuffType(buffId), buffId)
    end
    return false
end

function XGoldenMinerGame:CheckItemCanUse(itemId)
    if not self:IsPlay() and not self:IsTimeStop() then
        return
    end
    local buffId = XGoldenMinerConfigs.GetItemBuffId(itemId)
    local type = XGoldenMinerConfigs.GetBuffType(buffId)
    if type == XGoldenMinerConfigs.BuffType.GoldenMinerBoom
            or type == XGoldenMinerConfigs.BuffType.GoldenMinerStoneChangeGold
    then
        local result = false
        for _, hookEntity in ipairs(self.HookEntityList) do
            if not XTool.IsTableEmpty(hookEntity.HookGrabbingStoneList) then
                for _, stoneEntity in ipairs(hookEntity.HookGrabbingStoneList) do
                    if stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING then
                        result = true
                    end
                end
            end
        end
        return result
    elseif type == XGoldenMinerConfigs.BuffType.GoldenMinerTypeBoom then
        for _, stoneEntity in ipairs(self.StoneEntityList) do
            if stoneEntity.Data:GetType() == XGoldenMinerConfigs.GetBuffParams(buffId)[1] then
                return true
            end
        end
        return false
    end
    return true
end

function XGoldenMinerGame:UseItemToAddBuff(itemId)
    local characterBuffList = XGoldenMinerConfigs.GetCharacterBuffIds(self._Data:GetCurCharacterId())
    local itemBuffId = XGoldenMinerConfigs.GetItemBuffId(itemId)
    for _, buffId in pairs(characterBuffList) do
        -- 使用道具时停
        if XGoldenMinerConfigs.GetBuffType(buffId) == XGoldenMinerConfigs.BuffType.GoldenMinerUseItemStopTime then
            self:AddBuff(buffId)
        end
        -- 使用道具加时
        if XGoldenMinerConfigs.GetBuffType(buffId) == XGoldenMinerConfigs.BuffType.GoldenMinerUseItemAddTime then
            self:AddBuff(buffId)
        end
    end
    -- 使用炸弹道具加分
    if XGoldenMinerConfigs.GetBuffType(itemBuffId) == XGoldenMinerConfigs.BuffType.GoldenMinerBoom then
        self:CheckAndTriggerBuff(XGoldenMinerConfigs.BuffType.GoldenMinerBoomGetScore)
    end
    self:AddBuff(XGoldenMinerConfigs.GetItemBuffId(itemId))
end

function XGoldenMinerGame:AddBuff(buffId)
    if self.SystemBuff then
        self.SystemBuff:AddBuffById(self.BuffContainer, buffId)
    end
end

function XGoldenMinerGame:CheckAndTriggerBuff(buffType)
    if not self.SystemBuff then
        return false
    end
    if not self:CheckHasBuff(buffType) then
        return false
    end
    local result = false
    for _, buff in ipairs(self.BuffContainer.BuffTypeDir[buffType]) do
        if self.SystemBuff:CheckBuffIsAlive(buff) then
            if buff.TimeType == XGoldenMinerConfigs.BuffTimeType.Count then
                local isTrigger = self.SystemBuff:TriggerCountBuff(buff)
                result = result or isTrigger
            elseif buff.TimeType == XGoldenMinerConfigs.BuffTimeType.Global then
                self.SystemBuff:TriggerGlobalRoleSkillBuff(self, buff)
            end
        end
    end
    return result
end

---触发回收时次数型Buff
function XGoldenMinerGame:TriggerCountRevokeEndCountBuff()
    -- 按次数生效的回收速度buff
    self:CheckAndTriggerBuff(XGoldenMinerConfigs.BuffType.GoldenMinerShortenSpeed)
    -- 防爆次数触发
    self:CheckAndTriggerBuff(XGoldenMinerConfigs.BuffType.GoldenMinerNotActiveBoom)
end

---触发抓到炸弹时Buff
function XGoldenMinerGame:TriggerCountGrabBoomCountBuff()
    return self:CheckAndTriggerBuff(XGoldenMinerConfigs.BuffType.GoldenMinerNotActiveBoom)
end

---@param stoneType number
function XGoldenMinerGame:TriggerStoneHitBuff(stoneType)
    if stoneType == XGoldenMinerConfigs.StoneType.Boom then
        self:CheckAndTriggerBuff(XGoldenMinerConfigs.BuffType.GoldenMinerBoomGetScore)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:TriggerStoneGrabBuff(stoneEntity)
    if stoneEntity.Data:GetType() == XGoldenMinerConfigs.StoneType.Mouse then
        self:CheckAndTriggerBuff(XGoldenMinerConfigs.BuffType.GoldenMinerMouseGetItem)
    elseif stoneEntity.Data:GetType() == XGoldenMinerConfigs.StoneType.QTE then
        self:CheckAndTriggerBuff(XGoldenMinerConfigs.BuffType.GoldenMinerQTEGetScore)
    end
end
--endregion

--region EventListener
function XGoldenMinerGame:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PAUSE, self.Pause, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_RESUME, self.Resume, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_START, self.QTEStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_END, self.QTECrab, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_HIT, self.TriggerStoneHitBuff, self)
end

function XGoldenMinerGame:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PAUSE, self.Pause, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_RESUME, self.Resume, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_START, self.QTEStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_END, self.QTECrab, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_HIT, self.TriggerStoneHitBuff, self)
end
--endregion

return XGoldenMinerGame
