---Hunt02教学专用测试关
local XLevel9002 = XDlcScriptManager.RegLevelLogicScript(9002, "XLevel9002")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs
local Config = require("Level/LevelConfig/Hunt02TestConfig") -- 读取场景物体的配置数据
local Tool = require("Level/Common/XLevelTools")
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")

local _cameraResRefTable = {
    "MHWCam0",
}

function XLevel9002.GetCameraResRefTable()
    return _cameraResRefTable
end

local _effectRefTable = {
    "FxCollectible03",
    "FxDLCJiantou02",
    "FxZhayaotongBaoZha",
    "FxCaijiChenggong",
    "FxMabixianjingBaozha",
    "FxMhwflash01",
    "FxMhwXianjingLoop",
    "FxReactiveNotice",
    "FxQte",
    "FxDianyingPingmu00"
}

function XLevel9002.GetEffectRefTable()
    return _effectRefTable
end

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevel9002:Ctor(proxy)
    self._proxy = proxy

    self._uiEnable = true

    self._playerNpcContainer = XPlayerNpcContainer.New()
    self._playerNpcList = nil ---@type table<number>
    self._playerRescueDict = {}

    self._switches = Config.Switches

    self._switches[1].object = self
    self._switches[1].func = self.EnableAnchor
    self._switches[2].object = self
    self._switches[2].func = self.EnableAnchor
    self._switches[3].object = self
    self._switches[3].func = self.EnableSwitch
    self._switches[4].object = self
    self._switches[4].func = self.RaiseTower
    self._switches[5].object = self
    self._switches[5].func = self.RaiseTower
    self._switches[6].object = self
    self._switches[6].func = self.Tips
    self._switches[7].object = self
    self._switches[7].func = self.Tips
    self._switches[8].object = self
    self._switches[8].func = self.Tips
    self._switches[9].object = self
    self._switches[9].func = self.Guide
    self._switches[10].object = self
    self._switches[10].func = self.Guide
    self._switches[11].object = self
    self._switches[11].func = self.Guide

    self._enterTrigger = 2000 --用来做触发器的空间

    self._effectId = 3

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
        y = 90,
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

    self._time = 0
    self._tipsState = {}
    self._guideState = {}
end

function XLevel9002:Init()
    self._playerNpcContainer:Init()
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    for i = 1, #self._playerNpcList do
        local npc = self._playerNpcList[i]
        self._playerRescueDict[npc] = nil
    end
    self:InitSceneObjects()
    self._proxy:RegisterSceneObjectTriggerEvent(self._enterTrigger, 1)
    self._proxy:RegisterSceneObjectTriggerEvent(9999, 1)
end

---@param dt number @ delta time
function XLevel9002:Update(dt)
    self._time = self._time + dt

    if FuncSet.IsKeyDown(ENpcOperationKey.Ball5) then
        if FuncSet.CheckNpc(self._bossId) then
            FuncSet.NpcDie(self._bossId)
        else
            self._bossId = FuncSet.GenerateNpc(8004, 2, self._resetBossPosition1, self._resetBossRotation1)
            FuncSet.AddBuff(self._bossId, 8004004)
        end
    elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball6) then
        FuncSet.AddBuff(self._bossId,8004014)
    elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball7) then
        local rot = FuncSet.GetNpcRotation(self._playerNpcList[1])
        rot.y = rot.y +180
        FuncSet.SetNpcRotation(self._playerNpcList[1], rot)
    elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball8) then
        FuncSet.AddBuff(self._playerNpcList[1],5000004)
    end


--[[    if FuncSet.IsKeyDown(ENpcOperationKey.Ball8) then
        FuncSet.ShowGuide(12037)
        XLog.Debug("稍微反馈一下")
        self._uiEnable = not self._uiEnable
    elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball7) then
        local pos = FuncSet.GetNpcPosition(self._playerNpcList[1])
        pos.z = pos.z + 2
        self._bossId = FuncSet.GenerateNpc(8001, 2, pos, { x = 0, y = 90, z = 0 })
    elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball6) then
        local pos = FuncSet.GetNpcPosition(self._playerNpcList[1])
        pos.z = pos.z + 2
        FuncSet.SetNpcPosition(self._bossId, pos)
        FuncSet.SetNpcRotation(self._bossId, { x = 0, y = 0, z = 0 })
    elseif FuncSet.IsKeyDown(ENpcOperationKey.NextStory) then
        XLog.Debug("检测到next了！！")
    end
    if FuncSet.IsKeyDown(ENpcOperationKey.GuideClick) then
        XLog.Debug("检测到GuideClick了！！")
    end]]

end

---@param eventType number
---@param eventArgs userdata
function XLevel9002:HandleEvent(eventType, eventArgs)
    self.Super.HandleEvent(self, eventType, eventArgs)
    if eventType == EScriptEvent.SceneObjectTrigger then
        XLog.Debug("XLevelPrototype SceneObjectTriggerEvent:"
                .. " TouchType " .. tostring(eventArgs.TouchType)
                .. " SourceActorId " .. tostring(eventArgs.SourceActorId)
                .. " SceneObjectId " .. tostring(eventArgs.SceneObjectId)
                .. " TriggerId " .. tostring(eventArgs.TriggerId)
                .. " TriggerState " .. tostring(eventArgs.TriggerState)
        )

        if eventArgs.SceneObjectId == 9999 then
            FuncSet.FinishFight(true)
        elseif eventArgs.SceneObjectId == self._enterTrigger then
            if eventArgs.TriggerState == ESceneObjectTriggerState.Enter then
                local pos = FuncSet.GetNpcPosition(eventArgs.SourceActorId)
                FuncSet.CreateLevelEffect(self._effectId, "FxCaijiChenggong", pos.x, pos.y, pos.z, 0, 0, 0, 0, 0, 0)
                FuncSet.SetSceneObjectActive(2001, false)
            elseif eventArgs.TriggerState == ESceneObjectTriggerState.Exit then
                if FuncSet.CheckLevelEffectExist(self._effectId) then
                    FuncSet.RemoveLevelEffect(self._effectId)
                end
                self._effectId = self._effectId + 1
                if not FuncSet.IsSceneObjectActive(2001) then
                    FuncSet.SetSceneObjectActive(2001, true)
                    FuncSet.CreateLevelEffect(1, "FxQte", -14, 3.99, -130, 0, 0, 0, 0, 0, 0)
                    FuncSet.CreateLevelEffect(2, "FxReactiveNotice", -14, 4.59, -130, 0, 0, 0, 0, 0, 0)
                end
            end
        end
    end

    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
end

function XLevel9002:InitSceneObjects()
    -- 设置场景中猎矛勾点
    self._anchors = Tool.InitAnchor(Config.Anchors)
    XLog.Debug("初始化场景中猎锚勾点完成")

    -- 初始化塔
    self._towers = Tool.InitTower(Config.Towers)
    XLog.Debug("初始化场景中塔完成")

    -- 配置场景中开关
    self._switches = Tool.InitSwitch(self._switches) -- 由于需要在关卡脚本里指定执行的方法，因此只能在创建的时候对配置进行赋值
    XLog.Debug("初始化场景中开关完成")
end

---开关猎锚勾点
function XLevel9002:EnableAnchor(placeId)
    self._anchors[placeId].agent:SetEnable(not self._anchors[placeId].agent._enable)
end

---开关开关
function XLevel9002:EnableSwitch(placeId)
    self._switches[placeId].agent:SetEnable(not self._switches[placeId].agent._enable)
end

---升降塔
function XLevel9002:RaiseTower(placeId)
    self._towers[placeId].agent:TowerMove()
end

function XLevel9002:Tips(tipsId)
    if self._tipsState[tipsId] ~= false then
        FuncSet.ShowTip(tipsId, self:ToInteger(self._time))
        XLog.Debug("开启提示 " .. tipsId)
    else
        FuncSet.CloseTip(tipsId)
        XLog.Debug("关闭提示 " .. tipsId)
    end
    self._tipsState[tipsId] = self._tipsState[tipsId] == nil and true or (not self._tipsState[tipsId])
end

function XLevel9002:Guide(guideID)
    if self._guideState[guideID] ~= false then
        FuncSet.ShowGuide(guideID)
        XLog.Debug("开启引导 " .. guideID)
    else
        FuncSet.HideGuide()
        XLog.Debug("关闭引导 " .. guideID)
    end
    self._guideState[guideID] = self._guideState[guideID] == nil and true or (not self._guideState[guideID])
end

function XLevel9002:ToInteger(number)
    return math.floor(tonumber(number) or error("Could not cast '" .. tostring(number) .. "' to number.'"))
end

function XLevel9002:RespawnBoss()
    if FuncSet.CheckNpc(self._bossId) then
        FuncSet.NpcDie(self._bossId)
    else
        self._bossId = FuncSet.GenerateNpc(8004, 2, self._resetBossPosition1, self._resetBossRotation1)
        FuncSet.AddBuff(self._bossId, 8004004)
    end
end

function XLevel9002:Terminate()
end

return XLevel9002