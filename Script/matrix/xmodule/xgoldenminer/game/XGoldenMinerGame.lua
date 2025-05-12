---@class XGoldenMinerGameInitObjDir
---@field RectSize UnityEngine.Vector2
---@field MapRoot UnityEngine.Transform
---@field HookObjDir UnityEngine.Transform[]
---@field PartnerRoot UnityEngine.Transform
---@field HumanRoot UnityEngine.Transform
---@field ElectromagneticBox XGoInputHandler

---@class XGoldenMinerGameControl:XEntityControl
---@field private _Model XGoldenMinerModel
---@field private _MainControl XGoldenMinerControl
---@field SystemShip XGoldenMinerSystemShip
---@field SystemMap XGoldenMinerSystemMap
---@field SystemHook XGoldenMinerSystemHook
---@field SystemStone XGoldenMinerSystemStone
---@field SystemStoneMove XGoldenMinerSystemMove
---@field SystemBuff XGoldenMinerSystemBuff
---@field SystemTimeLine XGoldenMinerSystemTimeLineAnim
---@field SystemQTE XGoldenMinerSystemQTE
---@field SystemHideTask XGoldenMinerSystemHideTask
---@field SystemPartner XGoldenMinerSystemPartner
---@field SystemSlotScore XGoldenMinerSystemSlotScore
local XGoldenMinerGame = XClass(XEntityControl, "XGoldenMinerGame")

---@type UnityEngine.Time
local UnityTime = CS.UnityEngine.Time

--region Override
function XGoldenMinerGame:OnInit()
    self:_InitEnumConst()
    self:_InitCfgCacheData()

    ---@type XGoldenMinerGameData
    self._Data = false
    ---@type XGoldenMinerGameInitObjDir
    self._ObjDir = false

    ---一级状态：游戏状态
    self._Status = self.GAME_STATUS.NONE

    ---二级状态：暂停原因
    self._PauseReason = XEnumConst.GOLDEN_MINER.GAME_PAUSE_TYPE.NONE
    ---暂停前状态缓存
    self._PauseStageCatchStatus = self.GAME_STATUS.NONE
    ---时间停止前状态缓存
    self._TimeStopCatchStatus = self.GAME_STATUS.NONE
    ---QTE前状态缓存
    self._QTECatchStatus = self.GAME_STATUS.NONE

    self._GameClearIgnoreStoneTypeDir = nil -- 游戏结束判定忽略的抓取物类型
    self._IgnoreGameClearIgnoreStoneTypeDir = nil -- 忽略的 游戏结束判定忽略抓取物类型

    self._IsOpenRelicModule = false
    self._IsOpenSlotsScore = false

    self:_AddEventListener()
end

function XGoldenMinerGame:OnRelease()
    self._IsOpenRelicModule = false
    self._IsOpenSlotsScore = false
    self:_ReleaseEnumConst()
    self:_ReleaseCfgCacheData()
    self._Data = nil
    self._ObjDir = nil
    self._Status = nil
    self._PauseReason = nil
    self._PauseStageCatchStatus = nil
    self._GameClearIgnoreStoneTypeDir = nil
    self._IgnoreGameClearIgnoreStoneTypeDir = nil
    self._UpdateExFunc = nil
    self:_RemoveEventListener()
end

function XGoldenMinerGame:OnUpdate()
    local time = self:_CheckFrameTime(UnityTime.deltaTime)
    if self:IsQTE() then
        self:_UpdateQTE(time)
    elseif self:IsPlay() then
        self:_UpdateTime(time)
        self:_UpdateBuff(time)
        self:_UpdateHook(time)
        self:_UpdateShip(time)
        self:_UpdateStone(time)
        self:_UpdateStoneMove(time)
        self:_UpdatePartner(time)
        self:_UpdateTimeLine(time)
        self:_UpdateMap(time)
    elseif self:IsTimeStop() then
        self:_UpdateShip(time)
        self:_UpdateBuff(time)
        self:_UpdateHook(time)
        self:_UpdateStone(time)
        self:_UpdatePartner(time)
        self:_UpdateTimeLine(time)
        self:_UpdateMap(time)
    end
    if self:IsPause() then
        return
    end
    if self._UpdateExFunc then
        self._UpdateExFunc(time)
    end
end
--endregion

--region EnumConst
function XGoldenMinerGame:_InitEnumConst()
    self.MIN_FRAME_TIME = 1 / 20
    self.GAME_STATUS = {
        NONE = 0,
        INIT = 1,
        PLAY = 2,
        PAUSE = 3,
        END = 4,
        QTE = 5,
        TIME_STOP = 6,
    }
    self.ENTITY_TYPE = {
        SHIP = require("XModule/XGoldenMiner/Game/Entity/XGoldenMinerEntityShip"),
        HOOK = require("XModule/XGoldenMiner/Game/Entity/XGoldenMinerEntityHook"),
        STONE = require("XModule/XGoldenMiner/Game/Entity/XGoldenMinerEntityStone"),
        BUFF = require("XModule/XGoldenMiner/Game/Entity/XGoldenMinerEntityBuff"),
        PARTNER = require("XModule/XGoldenMiner/Game/Entity/XGoldenMinerEntityPartner"),
        REFLECT_EDGE = require("XModule/XGoldenMiner/Game/Entity/XGoldenMinerEntityReflectEdge"),
    }
    self.COMPONENT_TYPE = {
        SHIP_MOVE = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentShipMove"),
        SHIP_SHELL = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentShipShell"),
        SHIP_GRAB = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentShipGrab"),
        STONE = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentStone"),
        STONE_MOVE = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentMove"),
        STONE_MOUSE = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentMouse"),
        STONE_QTE = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentQTE"),
        STONE_MUSSEL = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentMussel"),
        STONE_DIRECTION = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentDirectionPoint"),
        STONE_DIRECTION_AIM = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentAimDirection"),
        STONE_PROJECTION = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentProjection"),
        STONE_PROJECTOR = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentProjector"),
        STONE_SHIELD = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentShield"),
        STONE_SUN_MOON = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentSunMoon"),
        HOOK = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentHook"),
        TIME_LINE = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentTimeLineAnim"),
        PARTNER_SHIP = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentPartnerShip"),
        PARTNER_SCAN = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentScanLine"),
        PARTNER_RADAR = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentPartnerRadar"),
        REFLECT_EDGE = require("XModule/XGoldenMiner/Game/Component/XGoldenMinerComponentReflectEdge"),
    }
end

function XGoldenMinerGame:_ReleaseEnumConst()
    self.MIN_FRAME_TIME = nil
    self.GAME_STATUS = nil
    self.ENTITY_TYPE = nil
    self.COMPONENT_TYPE = nil
end
--endregion

--region Game - Create
---@return XGoldenMinerGameData
function XGoldenMinerGame:CreateGameData(mapId)
    XMVCA.XGoldenMiner:DebugLog("本关地图:mapId=" .. mapId)
    if not self._Data then
        ---@type XGoldenMinerGameData
        self._Data = require("XModule/XGoldenMiner/Data/Game/XGoldenMinerGameData").New(mapId)
    else
        self._Data:OnRelease()
    end
    local stoneDataList = {}
    for i, stoneId in ipairs(self:GetCfgMapStoneId(mapId)) do
        table.insert(stoneDataList, self:CreateStoneData(stoneId, mapId, i))
    end
    self._Data:SetMapStoneDataList(stoneDataList)

    return self._Data
end

---@return XGoldenMinerMapStoneData
function XGoldenMinerGame:CreateStoneData(stoneId, mapId, i)
    ---@type XGoldenMinerMapStoneData
    local stoneData = require("XModule/XGoldenMiner/Data/Game/XGoldenMinerMapStoneData").New(stoneId)
    if mapId then
        stoneData:SetMapIndex(i)
        stoneData:SetXPosPercent(self:GetCfgMapXPosPercent(mapId, i))
        stoneData:SetYPosPercent(self:GetCfgMapYPosPercent(mapId, i))
        stoneData:SetRotationZ(self:GetCfgMapRotationZ(mapId, i))
        stoneData:SetScale(self:GetCfgMapScale(mapId, i))
    end
    stoneData:SetStoneConfig(self._Model:GetStoneCfg(stoneId))
    return stoneData
end
--endregion

--region Game - Control
---@param data XGoldenMinerGameData
---@param objDir XGoldenMinerGameInitObjDir
function XGoldenMinerGame:PrepareGame(data, objDir, updateExFunc)
    if not self:_IsStatus(self.GAME_STATUS.NONE) then
        return
    end
    self._Data = data
    self._ObjDir = objDir
    ---@type function
    self._UpdateExFunc = updateExFunc
    self._IsOpenRelicModule = self._MainControl:CheckIsCanOpenRelicModule(self._Data:GetMapId())
    self._IsOpenSlotsScore = self._MainControl:CheckIsCanOpenSlotsScore(self._Data:GetMapId())

    self:RegistrySystem()
end

function XGoldenMinerGame:EnterGame()
    self._Status = self.GAME_STATUS.INIT
    self:SystemEnterGame(self._ObjDir)
    self._Status = self.GAME_STATUS.PLAY
    self:StartTick(0)
end

function XGoldenMinerGame:ExitGame()
    self:StopTick()
    self:RemoveAllEntities()
    self._Data:OnRelease()
end

function XGoldenMinerGame:Resume(reason)
    if self:IsEnd() then
        return
    end
    if reason then
        self._PauseReason = self._PauseReason & (~reason)
    end
    if self._PauseReason ~= XEnumConst.GOLDEN_MINER.GAME_PAUSE_TYPE.NONE then
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

    self._Status = self.GAME_STATUS.PAUSE
end

function XGoldenMinerGame:GameOver()
    self._Status = self.GAME_STATUS.END
end

function XGoldenMinerGame:GameSettle(isSkip)
    if not isSkip then
        local gameData = self:GetGameData()
        local remainTime = self:GetGameData():GetTime()
        gameData:SetTimeScore(self._MainControl:GetTimeScore(remainTime))
        self:AddMapScore(gameData:GetTimeScore())
        gameData:SetPartnerRadarScore(self._MainControl:GetPartnerRadarScore(remainTime))
        self:AddMapScore(gameData:GetPartnerRadarScore())
    end
    self:_HideTaskSettle()
end
--endregion

--region Game - TimeStop
function XGoldenMinerGame:TimeStop()
    if self:IsEnd() or self:IsPause() then
        return
    end
    if not self:IsTimeStop() then
        self._TimeStopCatchStatus = self._Status
    end
    self._Status = self.GAME_STATUS.TIME_STOP
end

function XGoldenMinerGame:TimeResume()
    if self:IsEnd() or self:IsPause() then
        return
    end
    if self._TimeStopCatchStatus == self.GAME_STATUS.NONE then
        return
    end
    self._Status = self._TimeStopCatchStatus
end
--endregion

--region Game - Check
function XGoldenMinerGame:_CheckIsStoneClear()
    if self:_IsStatus(self.GAME_STATUS.INIT) then
        return
    end
    if not self._GameClearIgnoreStoneTypeDir then
        self._GameClearIgnoreStoneTypeDir = self:GetClientGameClearIgnoreStoneTypeDir()
    end
    for uid, _ in pairs(self:GetStoneEntityUidDirByType()) do
        local stoneEntity = self:GetStoneEntityByUid(uid)
        local stoneType = stoneEntity.Data:GetType()
        if not self._GameClearIgnoreStoneTypeDir[stoneType] or (self._IgnoreGameClearIgnoreStoneTypeDir and self._IgnoreGameClearIgnoreStoneTypeDir[stoneType]) then
            if not stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED) and not stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.DESTROY) then
                return false
            end
        end
    end
    self:GameOver()
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_STONE_CLEAR)
    return true
end

---防止卡顿跳帧
function XGoldenMinerGame:_CheckFrameTime(time)
    if time > self.MIN_FRAME_TIME then
        time = self.MIN_FRAME_TIME
    end
    return time
end

---@param status number self.GAME_STATUS
function XGoldenMinerGame:_IsStatus(status)
    return self._Status == status
end

function XGoldenMinerGame:IsRunning()
    return self:_IsStatus(self.GAME_STATUS.INIT)
            or self:IsPlay()
            or self:IsQTE()
            or self:IsTimeStop()
end

function XGoldenMinerGame:IsPlay()
    return self:_IsStatus(self.GAME_STATUS.PLAY)
end

function XGoldenMinerGame:IsQTE()
    return self:_IsStatus(self.GAME_STATUS.QTE)
end

function XGoldenMinerGame:IsPause(reason)
    local isReason = true
    if reason then
        isReason = self._PauseReason & reason ~= XEnumConst.GOLDEN_MINER.GAME_PAUSE_TYPE.NONE
    end
    return self:_IsStatus(self.GAME_STATUS.PAUSE) and isReason
end

function XGoldenMinerGame:IsTimeStop()
    return self:_IsStatus(self.GAME_STATUS.TIME_STOP)
end

function XGoldenMinerGame:IsEnd()
    return self:_IsStatus(self.GAME_STATUS.END)
end

function XGoldenMinerGame:CheckItemCanUse(itemId)
    if not self:IsPlay() and not self:IsTimeStop() then
        return
    end
    local buffId = self._MainControl:GetCfgItemBuffId(itemId)
    local type = self._MainControl:GetCfgBuffType(buffId)
    if type == XEnumConst.GOLDEN_MINER.BUFF_TYPE.BOOM
            or type == XEnumConst.GOLDEN_MINER.BUFF_TYPE.STONE_CHANGE_GOLD
    then
        local result = false
        for _, uid in ipairs(self:GetHookEntityUidList()) do
            local hookEntity = self:GetHookEntityByUid(uid)
            for _, stoneUid in ipairs(hookEntity:GetGrabbingStoneUidList()) do
                if self:GetStoneEntityByUid(stoneUid):CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING) then
                    result = true
                end
            end
        end
        return result
    elseif type == XEnumConst.GOLDEN_MINER.BUFF_TYPE.TYPE_BOOM then
        for uid, _ in pairs(self:GetStoneEntityUidDirByType()) do
            if self:GetStoneEntityByUid(uid).Data:CheckType(self._MainControl:GetCfgBuffParams(buffId)[1]) then
                return true
            end
        end
        return false
    elseif type == XEnumConst.GOLDEN_MINER.BUFF_TYPE.ELECTROMAGNETIC then
        return self.SystemHook:CheckSystemIsIdle() and not self:CheckBuffStatusByType(type, XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.BE_DIE)
    end
    return true
end

function XGoldenMinerGame:CheckIsOpenRelicModule()
    return self._IsOpenRelicModule
end

function XGoldenMinerGame:CheckIsOpenSlotsScore()
    return self._IsOpenSlotsScore
end
--endregion

--region Data - Getter
function XGoldenMinerGame:GetGameData()
    return self._Data
end

function XGoldenMinerGame:GetControl()
    return self._MainControl
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
--endregion

--region Data - Setter

function XGoldenMinerGame:SetIgnoreGameClearIgnoreStoneTypeDir(value)
    self._IgnoreGameClearIgnoreStoneTypeDir = value
end

--endregion

--region Data - Update & Record
function XGoldenMinerGame:AddMapScore(score)
    local buff = self:CheckBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.STAGE_ADD_SCORE_FLOAT)
    if buff and self:IsRunning() then
        local rate = math.random(buff:GetBuffParams(1), buff:GetBuffParams(2))
        local newScore = math.ceil(score * (1 + rate / 100))
        XMVCA.XGoldenMiner:DebugWarning("关卡内全局加分浮动百分比:", rate, "原分数:", score, "新分数", newScore)
        score = newScore
    end

    self._Data:SetMapScore(self._Data:GetMapScore() + score)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_SCORE)
end

function XGoldenMinerGame:AddItem(itemId)
    if not XTool.IsNumberValid(itemId) then
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_ITEM, itemId)
end

---@param usedTime number 经过的时间
function XGoldenMinerGame:_UpdateTime(usedTime)
    if self:IsEnd() then
        return
    end
    local curUsedTime = self._Data:GetUsedTime()
    self._Data:SetUsedTime(curUsedTime + usedTime)
    self:_ChangeTime(usedTime)
end

---倒计时
function XGoldenMinerGame:_ChangeTime(usedTime)
    local curTime = self._Data:GetTime()
    self._Data:SetTime(curTime - usedTime)
    if self._Data:IsTimeOut() then
        self:GameOver()
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_TIMEOUT)
    end
end

function XGoldenMinerGame:AddTime(time)
    self._Data:SetTime(self._Data:GetTime() + time)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_TIME, time)
end

function XGoldenMinerGame:AddBuff(buffId, isAdd)
    if self.SystemBuff then
        self.SystemBuff:CreateBuffEntity(buffId, isAdd)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:AddReportObjInfo(stoneEntity)
    local stoneType = stoneEntity.Data:GetType()
    local carryEntity = stoneEntity:GetCarryStoneEntity()
    if stoneType == XEnumConst.GOLDEN_MINER.STONE_TYPE.MUSSEL and carryEntity then
        stoneType = carryEntity.Data:GetType()
    end
    local score = 0
    score = score + stoneEntity:GetComponentStone().CurScore
    if carryEntity then
        score = score + carryEntity:GetComponentStone().CurScore
    end
    if stoneEntity:GetComponentQTE() then
        score = score + stoneEntity:GetComponentQTE().AddScore
    end
    if stoneType ~= XEnumConst.GOLDEN_MINER.STONE_TYPE.ADD_TIME_STONE
            and stoneType ~= XEnumConst.GOLDEN_MINER.STONE_TYPE.ITEM_STONE
    then
        local exScore = stoneType == XEnumConst.GOLDEN_MINER.STONE_TYPE.RELIC_FRAG and self.SystemMap:GetRelicScore() or 0
        self._Data:AddReportGrabStoneData(stoneType, math.floor(score), exScore)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:AddSettleObjInfo(stoneEntity)
    ---@type XGoldenMinerGrabDataInfo
    local grabDataInfo
    local stoneId = stoneEntity.Data:GetId()
    grabDataInfo = self._Data:GetSettleGrabStoneData(stoneId)
    if not grabDataInfo then
        grabDataInfo = require("XModule/XGoldenMiner/Data/Settle/XGoldenMinerGrabDataInfo").New(stoneId)
        self._Data:AddSettleGrabStoneData(stoneId, grabDataInfo)
    end
    grabDataInfo:AddDataByStoneEntity(stoneEntity)
end

function XGoldenMinerGame:AddSlotScoreHandleCount(slotScoreType)
    self._Data:AddSlotScoreHandleCount(slotScoreType)
end
--endregion

--region Entity - Getter
---@return XGoldenMinerEntityStone
function XGoldenMinerGame:GetStoneEntityByUid(uid)
    return self:GetEntityWithUid(uid)
end

---@return table<number, boolean>
function XGoldenMinerGame:GetStoneEntityUidDirByType(stoneType)
    return self.SystemMap:GetStoneUidDirByType(stoneType)
end

---@return XGoldenMinerEntityHook
function XGoldenMinerGame:GetHookEntityByUid(uid)
    return self:GetEntityWithUid(uid)
end

function XGoldenMinerGame:GetHookEntityUidList()
    if not self.SystemHook then
        return {}
    end
    return self.SystemHook:GetHookEntityUidList()
end

---@return XGoldenMinerEntityBuff
function XGoldenMinerGame:GetBuffEntityByUid(uid)
    return self:GetEntityWithUid(uid)
end

---@return XGoldenMinerEntityPartner
function XGoldenMinerGame:GetPartnerEntityByUid(uid)
    return self:GetEntityWithUid(uid)
end
--endregion

--region System - Init
function XGoldenMinerGame:RegistrySystem()
    self.SystemShip = self:AddSubControl(require("XModule/XGoldenMiner/Game/System/XGoldenMinerSystemShip"))
    self.SystemMap = self:AddSubControl(require("XModule/XGoldenMiner/Game/System/XGoldenMinerSystemMap"))
    self.SystemHook = self:AddSubControl(require("XModule/XGoldenMiner/Game/System/XGoldenMinerSystemHook"))
    self.SystemStone = self:AddSubControl(require("XModule/XGoldenMiner/Game/System/XGoldenMinerSystemStone"))
    self.SystemStoneMove = self:AddSubControl(require("XModule/XGoldenMiner/Game/System/XGoldenMinerSystemMove"))
    self.SystemBuff = self:AddSubControl(require("XModule/XGoldenMiner/Game/System/XGoldenMinerSystemBuff"))
    self.SystemTimeLine = self:AddSubControl(require("XModule/XGoldenMiner/Game/System/XGoldenMinerSystemTimeLineAnim"))
    self.SystemPartner = self:AddSubControl(require("XModule/XGoldenMiner/Game/System/XGoldenMinerSystemPartner"))
    -- 4期不开QTE和HideTask
    --self.SystemQTE = self:AddSubControl(require("XModule/XGoldenMiner/Game/System/XGoldenMinerSystemQTE"))
    --self.SystemHideTask = self:AddSubControl(require("XModule/XGoldenMiner/Game/System/XGoldenMinerSystemHideTask"))
    if self:CheckIsOpenSlotsScore() then
        self.SystemSlotScore = self:AddSubControl(require("XModule/XGoldenMiner/Game/System/XGoldenMinerSystemSlotScore"))
    end
end

---@param objDir XGoldenMinerGameInitObjDir
function XGoldenMinerGame:SystemEnterGame(objDir)
    if self.SystemShip then
        self.SystemShip:EnterGame(objDir)
    end
    if self.SystemMap then
        self.SystemMap:EnterGame(objDir)
    end
    if self.SystemHook then
        self.SystemHook:EnterGame(objDir)
    end
    if self.SystemStone then
        self.SystemStone:EnterGame(objDir)
    end
    if self.SystemBuff then
        self.SystemBuff:EnterGame(objDir)
    end
    if self.SystemTimeLine then
        self.SystemTimeLine:EnterGame(objDir)
    end
    if self.SystemPartner then
        self.SystemPartner:EnterGame(objDir)
    end
    if self.SystemQTE then
        self.SystemQTE:EnterGame(objDir)
    end
    if self.SystemHideTask then
        self.SystemHideTask:EnterGame(objDir)
    end
    if self.SystemSlotScore then
        self.SystemSlotScore:EnterGame(objDir)
    end
end
--endregion

--region System - Ship
function XGoldenMinerGame:_UpdateShip(time)
    if not self.SystemShip or self:IsEnd() then
        return
    end
    local isUsingHookBanMove = self.SystemHook and self.SystemHook:CheckSystemIsUsing() and self.SystemShip:CheckShipIsMoving()
    local isHitDirection = self.SystemHook and self.SystemHook:CheckIsHitDirection() and self.SystemShip:CheckShipIsMoving()
    -- 急不可耐(提升矿车速度)可以一边出钩一遍移动
    if isHitDirection or (isUsingHookBanMove and not self:CheckBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHIP_SPEED_MOVE)) then
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_SHIP_MOVE, XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.NONE)
        return
    end
    self.SystemShip:OnUpdate(time)
end

function XGoldenMinerGame:GetShip()
    if not self.SystemShip then
        return false
    end
    return self.SystemShip:GetShip()
end
--endregion

--region System - Hook
function XGoldenMinerGame:_UpdateHook(time)
    if self:IsEnd() or not self.SystemHook then
        return
    end
    self.SystemHook:OnUpdate(time)
end

function XGoldenMinerGame:HookShoot()
    self:_HideTaskClearCatch()
    self.SystemHook:HookShoot()
end

---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:HookGrab(hookEntity, stoneEntity)
    self:HandleHookGrabStone(hookEntity, stoneEntity)
    if self.SystemTimeLine then
        self.SystemTimeLine:PlayAnim(hookEntity, XEnumConst.GOLDEN_MINER.GAME_ANIM.HOOK_CLOSE, function()
            self:HookRevoke(hookEntity)
        end)
    else
        self.SystemHook:HookRevoke(hookEntity:GetComponentHook())
    end
end

---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerGame:HookRevoke(hookEntity)
    self.SystemHook:HookRevoke(hookEntity:GetComponentHook())
end

function XGoldenMinerGame:HookRevokeAll(status)
    self.SystemHook:HookRevokeAll(status)
end

function XGoldenMinerGame:HookAimRight()
    self.SystemHook:HookAimRight()
end

function XGoldenMinerGame:HookAimLeft()
    self.SystemHook:HookAimLeft()
end

function XGoldenMinerGame:HookAimIdle()
    self.SystemHook:HookAimIdle()
end

---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerGame:OnHookRevokeToIdle(hookEntity)
    local score = 0
    local grabbedCount = 0
    -- 收回
    local allNeedSettleStone = XTool.MergeArray(hookEntity:GetShipGrabbedStoneUidList(), hookEntity:GetGrabbingStoneUidList())
    for _, uid in ipairs(allNeedSettleStone) do
        local stoneEntity = self:GetStoneEntityByUid(uid)
        if stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED) then
            score = score + self:HandleStoneEntityToGrabbed(stoneEntity)
            grabbedCount = grabbedCount + 1

            self:HandleGrabbedStoneType(stoneEntity.Data:GetType())
        end
    end
    if self.SystemTimeLine and not XTool.IsTableEmpty(hookEntity:GetGrabbingStoneUidList()) then
        self.SystemTimeLine:PlayAnim(hookEntity, XEnumConst.GOLDEN_MINER.GAME_ANIM.HOOK_OPEN)
    end
    self:AddMapScore(score)
    -- 隐藏任务
    self:_HideTaskCheck(hookEntity)
    -- 表情
    if not hookEntity:GetComponentHook():IsNoShowFaceId() then
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
                XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.GRABBED,
                XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_ID.GRABBED)
    end
    hookEntity:GetComponentHook():SetIsNoShowFaceId(false)
    -- 记录本次回收抓取的个数(目前Partner机制的扫描线用到了)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_GRABBED_HANDLE, grabbedCount)
    -- 清理
    hookEntity:ClearShipGrabbedStone()
    hookEntity:ClearGrabbingStone()
    hookEntity:ClearHitStone()
    self:_BuffTriggerCountRevokeEndCount()
    self:_CheckIsStoneClear()
end

---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:HandleHookGrabStone(hookEntity, stoneEntity)
    hookEntity:AddGrabbingStone(stoneEntity:GetUid())
    self.SystemHook:HookGrab(hookEntity:GetComponentHook(), stoneEntity)
    self.SystemStone:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING)
end
--endregion

--region System - Stone
function XGoldenMinerGame:_UpdateStone(time)
    if self:IsEnd() or not self.SystemStone then
        return
    end
    if self.SystemStone then
        self.SystemStone:OnUpdate(time)
    end
    self:_CheckIsStoneClear()
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:_CheckStoneEntityToGrabbed(stoneEntity)
    -- 特殊抓取物触发
    if stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE) then
        local redEnvelopeId = stoneEntity.AdditionValue[XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE]
        if not redEnvelopeId then
            local redEnvelopeGroupId = stoneEntity.Data:GetRedEnvelopeGroup()
            redEnvelopeId = self:GetCfgRedEnvelopeRandId(redEnvelopeGroupId)
            stoneEntity.AdditionValue[XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE] = redEnvelopeId
        end
        local itemId = self:GetCfgRedEnvelopeItemId(redEnvelopeId)
        stoneEntity:GetComponentStone().Score = itemId
        self:AddItem(itemId)
    elseif stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.ADD_TIME_STONE) then
        self:AddTime(stoneEntity.Data:GetAddTimeStoneAddTime())
    elseif stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.ITEM_STONE) then
        self:UseItemToAddBuff(stoneEntity.Data:GetItemStoneItemId())
    end
end

---@param stoneEntity XGoldenMinerEntityStone
---@return number stoneEntity.Score
function XGoldenMinerGame:HandleStoneEntityToGrabbed(stoneEntity, isNotTriggerKareninaBuff)
    local score = 0
    -- Buff
    self:_BuffTriggerStoneGrab(stoneEntity)
    -- 加分
    score = score + stoneEntity:GetComponentStone().CurScore
    -- 特殊抓取物触发
    self:_CheckStoneEntityToGrabbed(stoneEntity)

    local carryStone = stoneEntity:GetCarryStoneEntity()
    if carryStone then
        score = score + carryStone:GetComponentStone().CurScore
        self:_CheckStoneEntityToGrabbed(carryStone)
    end

    local qteComponent = stoneEntity:GetComponentQTE()
    if qteComponent then
        score = score + qteComponent.AddScore
        if XTool.IsNumberValid(qteComponent.AddBuff) then
            self:AddBuff(qteComponent.AddBuff)
        end
        if XTool.IsNumberValid(qteComponent.AddItemId) then
            self:AddItem(qteComponent.AddItemId)
        end
    end
    -- 遗迹碎片处理
    if self._IsOpenRelicModule then
        if stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.RELIC_FRAG) then
            score = score + self.SystemMap:GetAndUpdateRelicScore()
        end
    end
    --  buff触发
    if not isNotTriggerKareninaBuff then
        self:_CheckAndTriggerBuff(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_KARENINA)
    end

    self:AddReportObjInfo(stoneEntity)
    self:AddSettleObjInfo(stoneEntity)
    return score
end
--endregion

--region System - Buff
function XGoldenMinerGame:_UpdateBuff(time)
    if self:IsEnd() then
        return
    end
    if self.SystemBuff then
        self.SystemBuff:OnUpdate(time)
    end
end

function XGoldenMinerGame:_CheckAndTriggerBuff(buffType)
    if not self.SystemBuff then
        return false
    end
    if not self:CheckBuffAliveByType(buffType) then
        return false
    end
    local result = false
    for uid, _ in pairs(self.SystemBuff:GetBuffUidListByType(buffType)) do
        local buff = self:GetBuffEntityByUid(uid)
        if buff:IsAlive() then
            if buff:CheckTimeType(XEnumConst.GOLDEN_MINER.BUFF_TIME_TYPE.COUNT) then
                local isTrigger = self.SystemBuff:TriggerCountBuff(buff)
                result = result or isTrigger
            elseif buff:CheckTimeType(XEnumConst.GOLDEN_MINER.BUFF_TIME_TYPE.GLOBAL) then
                self.SystemBuff:TriggerGlobalRoleSkillBuff(buff)
            end
        end
    end
    return result
end

---触发回收时次数型Buff
function XGoldenMinerGame:_BuffTriggerCountRevokeEndCount()
    -- 按次数生效的回收速度buff
    self:_CheckAndTriggerBuff(XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHORTEN_SPEED)
    -- 防爆次数触发
    self:_CheckAndTriggerBuff(XEnumConst.GOLDEN_MINER.BUFF_TYPE.NOT_ACTIVE_BOOM)
end

---@param stoneType number
function XGoldenMinerGame:_BuffTriggerStoneHit(stoneType)
    if stoneType == XEnumConst.GOLDEN_MINER.STONE_TYPE.BOOM then
        self:_CheckAndTriggerBuff(XEnumConst.GOLDEN_MINER.BUFF_TYPE.BOOM_GET_SCORE)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:_BuffTriggerStoneGrab(stoneEntity)
    if stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.MOUSE) then
        self:_CheckAndTriggerBuff(XEnumConst.GOLDEN_MINER.BUFF_TYPE.MOUSE_GET_ITEM)
    elseif stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.QTE) then
        self:_CheckAndTriggerBuff(XEnumConst.GOLDEN_MINER.BUFF_TYPE.QTE_GET_SCORE)
    end
end

function XGoldenMinerGame:CheckBuffAliveByType(buffType)
    if self.SystemBuff then
        return self.SystemBuff:GetBuffAliveByType(buffType)
    end
    return false
end

function XGoldenMinerGame:CheckBuffStatusByType(buffType, statusType)
    if self.SystemBuff then
        return self.SystemBuff:CheckBuffStatusByType(buffType, statusType)
    end
    return false
end

function XGoldenMinerGame:UseItemToAddBuff(itemId)
    -- 使用道具获得buff
    local buffUidList = self.SystemBuff:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.USE_ITEM_ADD_BUFF)
    local itemBuffId = self._MainControl:GetCfgItemBuffId(itemId)
    local isAdd = false
    if not XTool.IsTableEmpty(buffUidList) then
        for uid, _ in pairs(buffUidList) do
            if self:GetBuffEntityByUid(uid):IsAlive() then
                self:AddBuff(self:GetBuffEntityByUid(uid):GetBuffParams(1))
                isAdd = true
            end
        end
    end
    -- 使用炸弹道具加分
    if self._MainControl:GetCfgBuffType(itemBuffId) == XEnumConst.GOLDEN_MINER.BUFF_TYPE.BOOM then
        self:_CheckAndTriggerBuff(XEnumConst.GOLDEN_MINER.BUFF_TYPE.BOOM_GET_SCORE)
    end
    self:AddBuff(itemBuffId, true)
end
--endregion

--region System - Move
function XGoldenMinerGame:_UpdateStoneMove(time)
    if self:IsEnd() then
        return
    end
    if self.SystemStoneMove then
        self.SystemStoneMove:OnUpdate(time)
    end
end
--endregion

--region System - TimeLineAnim
function XGoldenMinerGame:_UpdateTimeLine(time)
    if self:IsEnd() then
        return
    end
    if self.SystemTimeLine then
        self.SystemTimeLine:OnUpdate(time)
    end
end
--endregion

--region System - HideTask
---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerGame:_HideTaskCheck(hookEntity)
    if not self.SystemHideTask then
        return
    end
    self.SystemHideTask:CheckHideTask(hookEntity)
end

function XGoldenMinerGame:_HideTaskClearCatch()
    if not self.SystemHideTask then
        return
    end
    self.SystemHideTask:ClearHideTaskCatch()
end

function XGoldenMinerGame:_HideTaskSettle()
    if not self.SystemHideTask then
        return
    end
    self:GetGameData():SetHideTaskInfoList(self.SystemHideTask:GetHideTaskInfoList())
end
--endregion

--region System - QTE
---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGame:QTEStart(hookEntity, stoneEntity)
    if self:IsEnd() or self:IsPause() or not self.SystemQTE then
        return
    end
    if self.SystemQTE:QTEStart(hookEntity, stoneEntity, self:IsQTE()) then
        self._QTECatchStatus = self._Status
        self._Status = self.GAME_STATUS.QTE
    end
end

function XGoldenMinerGame:QTEResume()
    if self:IsEnd() or self:IsPause() or not self.SystemQTE then
        return
    end
    if self._QTECatchStatus == self.GAME_STATUS.NONE then
        return
    end
    self._Status = self._QTECatchStatus
end

function XGoldenMinerGame:QTEClick()
    if not self:IsQTE() then
        return
    end
    self.SystemQTE:ClickQTE()
end

function XGoldenMinerGame:_UpdateQTE(time)
    if self:IsEnd() or not self.SystemQTE then
        return
    end
    self.SystemQTE:OnUpdate(time)
end
--endregion

--region System - Partner
function XGoldenMinerGame:_UpdatePartner(time)
    if self:IsEnd() or not self.SystemPartner then
        return
    end
    self.SystemPartner:OnUpdate(time)
end

function XGoldenMinerGame:PlayPartnerTriggerSound(partnerType)
    local soundId = self:_GetCfgPartnerTriggerSoundId(partnerType)
    if not XTool.IsNumberValid(soundId) then
        return
    end
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, soundId)
end
--endregion

--region System - Map

function XGoldenMinerGame:_UpdateMap(time)
    if self:IsEnd() or not self.SystemMap then
        return
    end
    self.SystemMap:OnUpdate(time)
end

--endregion

--region System - SlotScore

function XGoldenMinerGame:HandleGrabbedStoneType(stoneType)
    if self:CheckIsOpenSlotsScore() then
        self.SystemSlotScore:HandleGrabbedStoneType(stoneType)
    end
end

--endregion

--region Cfg - CacheData
function XGoldenMinerGame:_InitCfgCacheData()
    self._CfgGoldWeightDic = {}
    self._CfgQTELevelGroupDir = {}
    self._CfgRedEnvelopePoolGroup = {}
end

function XGoldenMinerGame:_ReleaseCfgCacheData()
    self._CfgGoldWeightDic = nil
    self._CfgQTELevelGroupDir = nil
    self._CfgRedEnvelopePoolGroup = nil
end
--endregion

--region Cfg - ClientParams Ship
function XGoldenMinerGame:GetClientShortenSpeedParameter()
    return self._Model:GetClientCfgNumberValue("ShortenSpeedParameter", 1)
end

function XGoldenMinerGame:GetClientHumanMoveSpeed()
    return self._Model:GetClientCfgNumberValue("HumenMoveSpeed", 1)
end

function XGoldenMinerGame:GetClientRoleMoveRangePercent()
    return self._Model:GetClientCfgNumberValue("RoleMoveRangePercent", 1) / 100
end

function XGoldenMinerGame:GetClientFinalShipMaxCount()
    return self._Model:GetClientCfgNumberValue("FinalShipMaxCount", 1)
end

function XGoldenMinerGame:GetClientShipImagePath(key)
    return self._Model:GetClientCfgValue(key, 1)
end

---@return UnityEngine.Vector2
function XGoldenMinerGame:GetClientShipSize(key)
    return Vector2(self._Model:GetClientCfgNumberValue(key, 1), self._Model:GetClientCfgNumberValue(key, 2))
end

function XGoldenMinerGame:GetClientElectromagneticResult()
    local params = self._Model:GetClientConfigCfg("ElectromagneticResult").Values
    local result = {}
    for i = 1, #params / 3 do
        local info = {}
        local index = (i - 1) * 3
        info.min = tonumber(params[index + 1])
        info.max = tonumber(params[index + 2])
        info.stoneId = tonumber(params[index + 3])
        table.insert(result, info)
    end
    return result
end

function XGoldenMinerGame:GetClientGameClearIgnoreStoneTypeDir()
    local params = self._Model:GetClientConfigCfg("GameClearIgnoreStoneTypeList").Values
    local result = {}
    for _, type in ipairs(params) do
        result[tonumber(type)] = true
    end
    return result
end
--endregion

--region Cfg - ClientParams Hook
function XGoldenMinerGame:GetClientRopeStretchSpeed()
    return self._Model:GetClientCfgNumberValue("RopeStretchSpeed", 1)
end

function XGoldenMinerGame:GetClientRopeShortenSpeed()
    return self._Model:GetClientCfgNumberValue("RopeShortenSpeed", 1)
end

function XGoldenMinerGame:GetClientRopeRockSpeed()
    return self._Model:GetClientCfgNumberValue("RopeRockSpeed", 1)
end

function XGoldenMinerGame:GetClientShortenMinSpeed()
    return self._Model:GetClientCfgNumberValue("ShortenMinSpeed", 1)
end

function XGoldenMinerGame:GetClientHookIdleAngleRange()
    return self._Model:GetClientCfgNumberValue("HookIdleAngleRange", 1), self._Model:GetClientCfgNumberValue("HookIdleAngleRange", 2)
end

function XGoldenMinerGame:GetClientHookHitPointRevokeSpeed(hitCount)
    return self._Model:GetClientCfgNumberValue("HookHitPointRevokeSpeed", hitCount)
end

function XGoldenMinerGame:GetClientHookRopeExLength()
    return self._Model:GetClientCfgNumberValue("HookRopeExLength", 1)
end

function XGoldenMinerGame:GetClientHookMaxReflectCount()
    return self._Model:GetClientCfgNumberValue("HookMaxReflectCount", 1)
end

function XGoldenMinerGame:GetClientRopeShortenNotCatchSpeed()
    return self._Model:GetClientCfgNumberValue("RopeShortenNotCatchSpeed", 1)
end
--endregion

--region Cfg - ClientParams Stone
function XGoldenMinerGame:GetClientMouseGrabOffset()
    return self._Model:GetClientCfgNumberValue("MouseGrabOffset", 1)
end

function XGoldenMinerGame:GetClientQTEWaitTime()
    return self._Model:GetClientCfgNumberValue("QTEWaitTime", 1)
end

function XGoldenMinerGame:GetClientRelicGatherScore()
    return self._Model:GetClientCfgNumberValue("RelicGatherScore", 1)
end
--endregion

--region Cfg - ClientParams Effect
function XGoldenMinerGame:GetClientUseBoomEffect()
    return self._Model:GetClientCfgValue("UseBoomEffect", 1)
end

function XGoldenMinerGame:GetClientWeightFloatEffect()
    return self._Model:GetClientCfgValue("WeightFloatEffect", 1)
end

function XGoldenMinerGame:GetClientStopTimeStartEffect()
    return self._Model:GetClientCfgValue("StopTimeStartEffect", 1)
end

function XGoldenMinerGame:GetClientStopTimeStopEffect()
    return self._Model:GetClientCfgValue("StopTimeStopEffect", 1)
end

-- 抓取物自动销毁爆炸特效
function XGoldenMinerGame:GetClientDestroyEffect()
    return self._Model:GetClientCfgValue("SelfDestroyEffect", 1)
end

-- 2期超里大炮物品爆炸特效
function XGoldenMinerGame:GetClientTypeBoomEffect()
    return self._Model:GetClientCfgValue("TypeBoomEffect", 1)
end

function XGoldenMinerGame:GetClientEffectQTEComplete()
    return self._Model:GetClientCfgValue("EffectPomegranateComplete", 1)
end

function XGoldenMinerGame:GetClientEffectQTEClick()
    return self._Model:GetClientCfgValue("EffectPomegranateClick", 1)
end

-- 4期电磁炮持续时间
function XGoldenMinerGame:GetClientElectromagneticTime()
    local value = self._Model:GetClientCfgValue("ElectromagneticTime", 1)
    return value and tonumber(value) / 1000 or 0.5
end

function XGoldenMinerGame:GetClientProjectorSoundId(index)
    return self._Model:GetClientCfgNumberValue("ProjectorSoundId", index)
end

function XGoldenMinerGame:GetClientTypeShipGrabStoneEffect()
    return self._Model:GetClientCfgValue("ShipGrabStoneEffect", 1)
end

function XGoldenMinerGame:GetClientTypeChangeSunOrMoonEffect(isSun)
    if isSun then
        return self._Model:GetClientCfgValue("ChangeSunOrMoonEffect", 1)
    else
        return self._Model:GetClientCfgValue("ChangeSunOrMoonEffect", 2)
    end
end

function XGoldenMinerGame:GetClientTypeRadarRandomItemEffect()
    return self._Model:GetClientCfgValue("RadarRandomItemEffect", 1)
end
--endregion

--region Cfg - ClientParams SlotScore

function XGoldenMinerGame:GetClientSlotScoreScore(type)
    return self._Model:GetClientCfgNumberValue("SlotsScores", type)
end

--endregion

--region Cfg - ClientParams Map

function XGoldenMinerGame:GetSunMoonChangedCD()
    return self._Model:GetClientCfgNumberValue("SunMoonChangedCD", 1)
end

--endregion

--region Cfg - HookType
function XGoldenMinerGame:GetCfgHookIgnoreTypeList(type)
    local cfg = self._Model:GetHookCfg(type)
    return cfg and cfg.IgnoreStoneTypeList
end
--endregion

--region Cfg - Map
function XGoldenMinerGame:GetCfgMapStoneId(id)
    local cfg = self._Model:GetMapCfg(id)
    return cfg and cfg.StoneId
end

function XGoldenMinerGame:GetCfgMapType(id)
    local cfg = self._Model:GetMapCfg(id)
    return cfg and cfg.MapType
end

--function XGoldenMinerGame:GetCfgMapIsOpenSlotsScore(id)
--    local cfg = self._Model:GetMapCfg(id)
--    return cfg and cfg.IsOpenSlotsScore
--end

function XGoldenMinerGame:GetCfgMapSunMoonInitialType(id)
    local cfg = self._Model:GetMapCfg(id)
    return cfg and cfg.SunMoonInitialType
end

function XGoldenMinerGame:GetCfgMapXPosPercent(id, index)
    local cfg = self._Model:GetMapCfg(id)
    local xPosPercent = cfg and cfg.XPosPercent
    return index and xPosPercent[index] or xPosPercent
end

function XGoldenMinerGame:GetCfgMapYPosPercent(id, index)
    local cfg = self._Model:GetMapCfg(id)
    local yPosPercent = cfg and cfg.YPosPercent
    return index and yPosPercent[index] or yPosPercent
end

function XGoldenMinerGame:GetCfgMapScale(id, index)
    local cfg = self._Model:GetMapCfg(id)
    local scale = cfg and cfg.Scale
    return index and scale[index] or scale
end

function XGoldenMinerGame:GetCfgMapRotationZ(id, index)
    local cfg = self._Model:GetMapCfg(id)
    local rotationZ = cfg and cfg.RotationZ
    return index and rotationZ[index] or rotationZ
end

function XGoldenMinerGame:GetCfgMapHideTask(id)
    local cfg = self._Model:GetMapCfg(id)
    return cfg and cfg.HideTask
end
--endregion

--region Cfg - Stone
function XGoldenMinerGame:GetStoneGoldIdByWeight(weight, id)
    if XTool.IsTableEmpty(self._CfgGoldWeightDic) then
        self._CfgGoldWeightDic = {}
        for _, cfg in pairs(self._Model:GetStoneCfgList()) do
            if cfg.Type == XEnumConst.GOLDEN_MINER.STONE_TYPE.GOLD then
                self._CfgGoldWeightDic[cfg.Weight] = cfg.Id
            end
        end
    end
    if self:GetCfgStoneType(id) == XEnumConst.GOLDEN_MINER.STONE_TYPE.GOLD then
        return
    end
    return self._CfgGoldWeightDic[weight]
end

function XGoldenMinerGame:GetCfgStoneType(id)
    local cfg = self._Model:GetStoneCfg(id)
    return cfg and cfg.Type
end

function XGoldenMinerGame:GetStoneScore(id)
    local cfg = self._Model:GetStoneCfg(id)
    return cfg and cfg.Score
end
--endregion

--region Cfg - StoneType

function XGoldenMinerGame:GetCfgStoneTypeIsSlotAnyType(type)
    local cfg = self._Model:GetStoneTypeCfg(type)
    return cfg and cfg.IsSlotAnyType
end

--endregion

--region Cfg - RedEnvelopeRandPool
function XGoldenMinerGame:GetCfgRedEnvelopeRandId(groupId)
    if XTool.IsTableEmpty(self._CfgRedEnvelopePoolGroup) then
        self._CfgRedEnvelopePoolGroup = {}
        for _, config in ipairs(self._Model:GetRedEnvelopeRandPoolCfgList()) do
            if XTool.IsTableEmpty(self._CfgRedEnvelopePoolGroup[config.GroupId]) then
                self._CfgRedEnvelopePoolGroup[config.GroupId] = {}
            end
            table.insert(self._CfgRedEnvelopePoolGroup[config.GroupId], config)
        end
    end
    if XTool.IsNumberValid(groupId) and not XTool.IsTableEmpty(self._CfgRedEnvelopePoolGroup[groupId]) then
        local result = XTool.WeightRandomSelect(self._CfgRedEnvelopePoolGroup[groupId], true)
        return result and result.Id
    end
    local config = XTool.WeightRandomSelect(self._Model:GetRedEnvelopeRandPoolCfgList(), true)
    return config and config.Id
end

function XGoldenMinerGame:GetCfgRedEnvelopeScore(id)
    local cfg = self._Model:GetRedEnvelopeRandPoolCfg(id)
    return cfg and cfg.Params[1]
end

function XGoldenMinerGame:GetCfgRedEnvelopeItemId(id)
    local cfg = self._Model:GetRedEnvelopeRandPoolCfg(id)
    return cfg and cfg.Params[2]
end

function XGoldenMinerGame:GetCfgRedEnvelopeHeft(id)
    local cfg = self._Model:GetRedEnvelopeRandPoolCfg(id)
    return cfg and cfg.Heft
end
--endregion

--region Cfg - QTE
function XGoldenMinerGame:_GetCfgQTELevelGroup(groupId)
    if XTool.IsTableEmpty(self._CfgQTELevelGroupDir) then
        self._CfgQTELevelGroupDir = {}
        for _, cfg in ipairs(self._Model:GetQTELevelGroupCfgList()) do
            if not self._CfgQTELevelGroupDir[cfg.GroupId] then
                self._CfgQTELevelGroupDir[cfg.GroupId] = {}
            end
            self._CfgQTELevelGroupDir[cfg.GroupId][#self._CfgQTELevelGroupDir[cfg.GroupId] + 1] = cfg.Id
        end
    end
    return self._CfgQTELevelGroupDir[groupId]
end

function XGoldenMinerGame:GetCfgQTELevelGroupMaxClickCount(groupId)
    local groupIdList = self:_GetCfgQTELevelGroup(groupId)
    if XTool.IsTableEmpty(groupIdList) then
        return 0
    end
    return self:_GetCfgQTELevelGroupClickCount(groupIdList[#groupIdList])
end

---@return number Id
function XGoldenMinerGame:GetCfgQTELevelGroupByCount(groupId, count)
    local groupIdList = self:_GetCfgQTELevelGroup(groupId)
    local result = false
    if XTool.IsTableEmpty(groupIdList) then
        XLog.Error("QTE组为空,GroupId = " .. groupId .. " Count = " .. count)
        return result
    end
    if count == 0 then
        return groupIdList[1]
    end
    for _, id in ipairs(groupIdList) do
        if self:_GetCfgQTELevelGroupClickCount(id) <= count then
            result = id
        end
    end
    return result
end

function XGoldenMinerGame:GetCfgQTELevelGroupType(id)
    local cfg = self._Model:GetQTELevelGroupCfg(id)
    return cfg and cfg.Type
end

function XGoldenMinerGame:_GetCfgQTELevelGroupClickCount(id)
    local cfg = self._Model:GetQTELevelGroupCfg(id)
    return cfg and cfg.ClickCount
end

function XGoldenMinerGame:GetCfgQTELevelGroupIcon(id)
    local cfg = self._Model:GetQTELevelGroupCfg(id)
    return cfg and cfg.Icon
end

function XGoldenMinerGame:GetCfgQTELevelDownTime(id)
    local cfg = self._Model:GetQTELevelGroupCfg(id)
    return cfg and cfg.DownTime
end

function XGoldenMinerGame:GetCfgQTELevelSpeedRate(id)
    local cfg = self._Model:GetQTELevelGroupCfg(id)
    return cfg and cfg.SpeedRate
end

function XGoldenMinerGame:GetCfgQTELevelGroupParams(id)
    local cfg = self._Model:GetQTELevelGroupCfg(id)
    return cfg and cfg.Params
end
--endregion

--region Cfg - Partner
function XGoldenMinerGame:GetCfgPartner(type)
    return self._Model:GetGoldenMinerPartnerCfg(type)
end

function XGoldenMinerGame:GetCfgPartnerIgnoreStoneList(type)
    local cfg = self._Model:GetGoldenMinerPartnerCfg(type)
    if string.IsNilOrEmpty(cfg.IgnoreStoneConfigKey) then
        return nil
    end
    return self._Model:GetClientConfigCfg(cfg.IgnoreStoneConfigKey).Values
end

function XGoldenMinerGame:_GetCfgPartnerTriggerSoundId(type)
    local cfg = self._Model:GetGoldenMinerPartnerCfg(type)
    return cfg and cfg.TriggerSoundId
end
--endregion

--region Cfg - SHIP_SHELL

function XGoldenMinerGame:GetShipShellById(id)
    return self._Model:GetShipShellCfg(id)
end

--endregion

--region EventListener
function XGoldenMinerGame:_AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PAUSE, self.Pause, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_RESUME, self.Resume, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_START, self.QTEStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_CLICK, self.QTEClick, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_HIT, self._BuffTriggerStoneHit, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_TIME, self.AddTime, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_SCORE, self.AddMapScore, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_ITEM, self.AddItem, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_BUFF, self.AddBuff, self)
end

function XGoldenMinerGame:_RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PAUSE, self.Pause, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_RESUME, self.Resume, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_START, self.QTEStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_CLICK, self.QTEClick, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_HIT, self._BuffTriggerStoneHit, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_TIME, self.AddTime, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_SCORE, self.AddMapScore, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_ITEM, self.AddItem, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_BUFF, self.AddBuff, self)
end
--endregion

return XGoldenMinerGame