---@class XBigWorldGamePlayAgency : XAgency
---@field private _Model XBigWorldGamePlayModel
---@field private _Camera UnityEngine.Camera
---@field private _ActivityAgency table<number, XBigWorldActivityAgency> 活动Id -> 活动Agency
---@field private _Level2Agency table<number, XBigWorldActivityAgency> LevelId -> 活动Agency
local XBigWorldGamePlayAgency = XClass(XAgency, "XBigWorldGamePlayAgency")

local XBigWorldActivityAgency = require("XModule/XBase/XBigWorldActivityAgency")
local IsWindowsEditor = XMain.IsWindowsEditor

---@type XBigWorldHelper
local CsHelper = CS.XBigWorldHelper
local CsSetViewPosToTransformLocalPosition = CS.XUiHelper.SetViewPosToTransformLocalPosition

function XBigWorldGamePlayAgency:OnInit()
    -- 初始化一些变量
    self._ClientArgs = false
    self._CurrentModuleId = 0
    -- 场景相机
    self._Camera = false

    self._ActivityAgency = {}
    self._Level2Agency = {}
end

function XBigWorldGamePlayAgency:InitRpc()
    -- 实现服务器事件注册
end

function XBigWorldGamePlayAgency:InitEvent()
    self._OnEnterFight = Handler(self, self.OnEnterFight)
    self._OnExitFight = Handler(self, self.OnExitFight)
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_DLC_FIGHT_ENTER, self._OnEnterFight)
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFight)
end

function XBigWorldGamePlayAgency:RemoveEvent()
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_DLC_FIGHT_ENTER, self._OnEnterFight)
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFight)
end

function XBigWorldGamePlayAgency:SetCurrentGameAgency(worldId)
    local moduleId = self._Model:GetModuleIdByWorldId(worldId)

    if string.IsNilOrEmpty(moduleId) then
        XLog.Error("当前世界ID没有对应的模块ID! 请检查配置表BigWorldGamePlay.tab WorldId: " .. worldId)
        return
    end

    self._CurrentModuleId = moduleId
end

---@return XBigWorldAgency
function XBigWorldGamePlayAgency:GetCurrentAgency()
    local moduleId
    if self:IsInGame() then
        moduleId = self._CurrentModuleId
    else
        moduleId = ModuleId.XBigWorld
        XLog.Error("当前不在进入大世界玩法中!")
    end
    
    if not XMVCA:IsRegisterAgency(moduleId) then
        XMVCA:RegisterAgency(moduleId)
    end
    return XMVCA:GetAgency(moduleId)
end

function XBigWorldGamePlayAgency:GetCurrentWorldId()
    if self:IsInGame() then
        if XMVCA.XBigWorldGamePlay:IsInDebugGame() then
            return XMVCA.XBigWorldGamePlay:GetDebugWorldId()
        else
            return self._Model:GetCurrentWorldId()
        end
    end

    XLog.Error("当前不在进入大世界玩法中!")
    
    return 0
end

function XBigWorldGamePlayAgency:GetCurrentLevelId()
    if self:IsInGame() then
        if XMVCA.XBigWorldGamePlay:IsInDebugGame() then
            return XMVCA.XBigWorldGamePlay:GetDebugLevelId()
        else
            return self._Model:GetCurrentLevelId()
        end
    end

    XLog.Error("当前不在进入大世界玩法中!")

    return 0
end

function XBigWorldGamePlayAgency:IsInGame()
    return XTool.IsNumberValid(self._CurrentModuleId)
end

--- 大世界玩法是否开启
---@return boolean
function XBigWorldGamePlayAgency:IsBigWorldOpen()
    --主干直接关闭
    return false
end

--region 进入大世界流程

--- 发送进入大世界入口协议
function XBigWorldGamePlayAgency:EnterGame()
    if not self:IsBigWorldOpen() then
        XUiManager.TipText("CommonNotOpen")
        return
    end
    XNetwork.Call("BigWorldEnterWorldRequest", {
        WorldId = 0,
        LevelId = 0,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local enterData = res.EnterResultData

        if not enterData then
            XLog.Error("EnterResultData is nil, 进入大世界失败!")
            return
        end
        if not enterData.WorldData then
            XLog.Error("WorldData is nil, 进入大世界失败!")
            return
        end

        local worldData = enterData.WorldData

        self:_InitWorldId(worldData.WorldId)
        self:_InitLevelId(worldData.LevelId)
        self:RegisterMVCA()
        self:UpdatePlayerData(res.PlayerData)
        self:DoWorldSaveRequest(worldData, enterData.FightData, enterData.LevelData)
        XMVCA.XBigWorldService:InitQuestItemMap(res.DlcQuestBag)
        self:InitX3C()
        self:InitActivityAgency()
    end)
end

function XBigWorldGamePlayAgency:DoPlayerDataRequest()
    XNetwork.Call("BigWorldPlayerDataRequest", nil, function(res)
        self:UpdatePlayerData(res)
    end)
end

--- 大世界总协议返回后的请求
function XBigWorldGamePlayAgency:DoWorldSaveRequest(worldData, fightData, levelData)
    local worldId = self:GetCurrentWorldId()

    self:RegisterWorldSaveDataRequest(worldData, fightData, levelData)
    CS.StatusSyncFight.XWorldSaveSystem.RequestWorldSave(worldId)
end

function XBigWorldGamePlayAgency:DoQuestBagRequest()
    -- 背包数据
    XNetwork.Call("DlcQuestBagRequest", nil, function(res)
        XMVCA.XBigWorldService:InitQuestItemMap(res.DlcQuestBag)
    end)
end

--- 正式进入到大世界
function XBigWorldGamePlayAgency:DoEnterGame(worldData, fightData, levelData)
    if not fightData or not levelData then
        XLog.Error("fightData or levelData is nil, 进入大世界失败!")
        return
    end

    -- 初始化战斗
    self:CsStatusSyncFightInit()
    -- 设置当前大世界类型
    self:InitCurrentBigWorldType()
    -- 对应大世界执行进入战斗前逻辑
    self:GetCurrentAgency():BeforeEnterGame()
    -- 进入战斗
    self:CsStatusSyncEnterFight(worldData, fightData, levelData, XPlayer.Id)
    XMVCA.XDlcWorld:OnEnterFight(self:GetCurrentWorldId())
    -- 对应大世界执行进入战斗后逻辑
    self:GetCurrentAgency():AfterEnterGame()
end

--- 退出大世界
function XBigWorldGamePlayAgency:ExitGame()
    if not self:IsInGame() then
        return
    end

    self:CsStatusSyncExitFight()
    self:GetCurrentAgency():Exit()
    self:UnRegisterMVCA()
    XMVCA.XBigWorldQuest:ResetData()
end

--- 战斗事件通知，进入战斗（已经进入）
function XBigWorldGamePlayAgency:OnEnterFight()
    if self:IsInGame() then
        self:GetCurrentAgency():EnterFight()
    end
end

--- 战斗事件通知，退出战斗
function XBigWorldGamePlayAgency:OnExitFight()
    if self:IsInGame() then
        self._Camera = false
        self:GetCurrentAgency():ExitFight()
        self._CurrentModuleId = 0
        CsHelper.SetBigWorldType(CsHelper.BigWorldType.None)
        self:ClearX3C()
        self:ClearActivityAgency()
        self:ClearDebugState()
        self._Model:Clear()
        CS.StatusSyncFight.XWorldSaveSystem.Cleanup()
    end
end

--- 注册玩家进入DlcWorld时，服务器返回消息的回调
function XBigWorldGamePlayAgency:RegisterWorldSaveDataRequest(worldData, fightData, levelData)
    self._OnReceivedWorldSaveDataCb = function(worldSaveData)
        self:UpdateWorldData(worldSaveData)
        self:DoEnterGame(worldData, fightData, levelData)
        self:UnRegisterWorldSaveDataRequest()
    end

    local CsWorldSystem = CS.StatusSyncFight.XWorldSaveSystem

    if CsWorldSystem.ReceivedWorldSaveDataCb == nil then
        CsWorldSystem.ReceivedWorldSaveDataCb = self._OnReceivedWorldSaveDataCb
    else
        CsWorldSystem.ReceivedWorldSaveDataCb = CsWorldSystem.ReceivedWorldSaveDataCb + self._OnReceivedWorldSaveDataCb
    end
end

--- 取消注册玩家进入DlcWorld时，服务器返回消息的回调
function XBigWorldGamePlayAgency:UnRegisterWorldSaveDataRequest()
    local CsWorldSystem = CS.StatusSyncFight.XWorldSaveSystem
    if CsWorldSystem.ReceivedWorldSaveDataCb == nil then
        return
    end
    if not self._OnReceivedWorldSaveDataCb then
        return
    end
    CsWorldSystem.ReceivedWorldSaveDataCb = CsWorldSystem.ReceivedWorldSaveDataCb - self._OnReceivedWorldSaveDataCb
end

--- 初始化X3C，服务器DlcWorldSaveDataResponse协议返回时调用
function XBigWorldGamePlayAgency:InitX3C()
    if not self:IsInGame() then
        return
    end

    self:ClearX3C()
    self:GetCurrentAgency():InitX3C()
end

function XBigWorldGamePlayAgency:ClearX3C()
    XMVCA.X3CProxy:ClearHandlers()
end

--- 初始化大世界类型
function XBigWorldGamePlayAgency:InitCurrentBigWorldType()
    local worldId = self:GetCurrentWorldId()
    local worldType = XMVCA.XDlcWorld:GetWorldTypeById(worldId)

    if XTool.IsNumberValid(worldType) then
        CsHelper.SetBigWorldType(worldType)
    else
        XLog.Error("当前WroldId = " .. tostring(worldId) .. "未配置WorldType!")
    end
end

--- 初始化战斗
function XBigWorldGamePlayAgency:CsStatusSyncFightInit()
    CS.StatusSyncFight.XFight.Init()
end

function XBigWorldGamePlayAgency:CsStatusSyncEnterFight(worldData, fightData, levelData, playerId)
    local args = self:CreateClientArgs()
    CS.StatusSyncFight.XFightClient.EnterFight(worldData, fightData, levelData, playerId, args)
end

function XBigWorldGamePlayAgency:CsStatusSyncExitFight()
    CS.StatusSyncFight.XFightClient.RequestExitFight()
end

function XBigWorldGamePlayAgency:CreateClientArgs()
    if not self._ClientArgs then
        self._ClientArgs = CS.StatusSyncFight.XFightClientArgs()
    end

    self._ClientArgs.LoadProgressCb = Handler(self, self.OnLoadingProgress)
    self._ClientArgs.OpenLoadingUiCb = Handler(self, self.OnOpenLoadingUi)
    self._ClientArgs.CloseLoadingUiCb = Handler(self, self.OnCloseLoadingUi)

    return self._ClientArgs
end

-- 进大世界加载进度
---@param progress number
function XBigWorldGamePlayAgency:OnLoadingProgress(progress)
end

function XBigWorldGamePlayAgency:OnOpenLoadingUi(worldId, levelId)
    XMVCA.XBigWorldUI:OpenLoadingMask(nil, worldId, levelId)
end

function XBigWorldGamePlayAgency:OnCloseLoadingUi()
    XMVCA.XBigWorldUI:CloseLoadingMask()
end

--endregion

--region 玩家数据

--- 更新玩家数据
function XBigWorldGamePlayAgency:UpdatePlayerData(res)
    if not self:IsInGame() then
        return
    end

    self:GetCurrentAgency():UpdatePlayerData(res)
end

--- 更新世界数据
---@param res Protocol.Protocol.Frontend.DlcWorldSaveDataResponse
function XBigWorldGamePlayAgency:UpdateWorldData(res)
    if not self:IsInGame() then
        return
    end
    self:GetCurrentAgency():UpdateWorldData(res)
end

--endregion

--region 关卡切换事件

-- 设置虚拟摄像机
function XBigWorldGamePlayAgency:ActivateVCamera(VCameraName, Duration, DeactivateAllPreVCam)
    if string.IsNilOrEmpty(VCameraName) then
        return
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_ACTIVATE_VIRTUAL_CAMERA, {
        VCameraName = VCameraName,
        Duration = Duration or 0,
        DeactivateAllPreVCam = DeactivateAllPreVCam or false,
    })
end

-- 取消设置虚拟摄像机（看看后面玩法是不是通用的，玩法主界面关闭后设置回去）
function XBigWorldGamePlayAgency:DeactivateVCamera(VCameraName, IsIgnoreBlendOut)
    if string.IsNilOrEmpty(VCameraName) then
        return
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_DEACTIVATE_VIRTUAL_CAMERA, {
        VCameraName = VCameraName,
        IsIgnoreBlendOut = IsIgnoreBlendOut or false,
    })
end

-- 设置相机投影模式
function XBigWorldGamePlayAgency:SetCameraProjection(isOrthographic)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_SET_CAMERA_PROJECTION_MODE, {
        IsOrthographic = isOrthographic,
    })
end

--设置相机物理模式
function XBigWorldGamePlayAgency:SetCameraPhysicalMode(IsPhysical, GateFitMode)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_SET_CAMERA_PHYSICAL_MODE, {
        IsPhysical = IsPhysical,
        GateFitMode = GateFitMode,
    })
end

--- 设置当前NPC的显隐
---@param npcActive boolean 显示/隐藏
---@param includeAssist boolean 是否包含跟随物体
function XBigWorldGamePlayAgency:SetCurNpcAndAssistActive(npcActive, includeAssist)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SET_CUR_NPC_AND_ASSIST_ACTIVE, {
        IsActive = npcActive,
        IsIncludeAssist = includeAssist,
    })
end

-- 玩法主界面打开 (C# => Lua)
function XBigWorldGamePlayAgency:OnOpenMainUi(data)
    local id = data and data.BigWorldActivityId or 0
    if id and id > 0 then
        local agency = self:GetActivityAgencyById(id)
        if agency then
            local config = agency:GetConfig()
            self:ActivateVCamera(config.VirtureCamera, config.CameraDuration)
            agency:OpenMainUi(id, data.Args)
        end
    end
end

--- DLC战斗进入关卡 (C# => Lua)
function XBigWorldGamePlayAgency:OnEnterLevel(data)
    local levelId = data.LevelId
    local agency = self:GetActivityAgencyByLevelId(levelId, true)
    if agency then
        agency:OnEnterLevel()
    end

    self._Model:SetCurrentLevelId(levelId)
    self:GetCurrentAgency():EnterLevel(levelId)
end

--- DLC战斗离开关卡 (C# => Lua)
function XBigWorldGamePlayAgency:OnLeaveLevel(data)
    local levelId = data.LevelId
    local agency = self:GetActivityAgencyByLevelId(levelId, true)
    if agency then
        agency:OnLeaveLevel()
    end

    self._Camera = false
    self:GetCurrentAgency():LeaveLevel(levelId)
end

--- DLC战斗开始更新关卡 (C# => Lua)
function XBigWorldGamePlayAgency:OnLevelBeginUpdate()
    local levelId = self._Model:GetCurrentLevelId()
    local agency = self:GetActivityAgencyByLevelId(levelId, true)
    if agency then
        agency:OnLevelBeginUpdate()
    end
    self:GetCurrentAgency():LevelBeginUpdate()

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, levelId)
end

--endregion

--region 战斗暂停&输入&战斗UI隐藏 相关

function XBigWorldGamePlayAgency:PauseFight()
    if CS.StatusSyncFight.XFightClient.FightInstance then
        -- 战斗端有引用计数，只需要保持成对调用即可！
        CS.StatusSyncFight.XFightClient.FightInstance:OnPauseForClient()
    end
end

function XBigWorldGamePlayAgency:ResumeFight()
    if CS.StatusSyncFight.XFightClient.FightInstance then
        -- 战斗端有引用计数，只需要保持成对调用即可！
        CS.StatusSyncFight.XFightClient.FightInstance:OnResumeForClient()
    end
end

function XBigWorldGamePlayAgency:ChangeFightInput()
    CS.XInputManager.SetCurInputMap(CS.XInputManager.BeforeInputMapID)
    CS.StatusSyncFight.XFightClient.SetControlCameraByDrag(false)
end

function XBigWorldGamePlayAgency:ChangeSystemInput()
    CS.XInputManager.SetCurInputMap(CS.XInputMapId.System)
    CS.StatusSyncFight.XFightClient.SetControlCameraByDrag(true)
end

function XBigWorldGamePlayAgency:SetFightUiActive(isActive)
    XLuaUiManager.SetUiActive("UiFightDLC", isActive)
end

--- 获取战斗的相机
---@return UnityEngine.Camera
function XBigWorldGamePlayAgency:GetCamera()
    if self._Camera then
        return self._Camera
    end
    -- 获取到相机
    local transform = CS.StatusSyncFight.XFightClient.GetCameraTransform()
    if not transform then
        XLog.Error("获取相机时机错误，请在关卡初始化完成后再获取！")
        return
    end
    self._Camera = transform:GetComponent("Camera")
    if not self._Camera then
        XLog.Error("节点不存在相机组件! " .. transform.gameObject.name)
        return
    end

    return self._Camera
end

--- 设置UiObj映射3DObj
---@param uiTransform UnityEngine.RectTransform ui节点
---@param objTransform UnityEngine.Transform 场景节点
---@param offset UnityEngine.Vector2 偏移量
---@param pivot UnityEngine.Vector2 ui父节点的锚点
function XBigWorldGamePlayAgency:SetViewPosToTransformLocalPosition(uiTransform, objTransform, offset, pivot)
    local camera = self._Camera
    if not camera then
        camera = self:GetCamera()
        if not camera then
            return
        end
    end
    if XTool.UObjIsNil(uiTransform) or XTool.UObjIsNil(objTransform) then
        return
    end
    CsSetViewPosToTransformLocalPosition(camera, uiTransform, objTransform, offset, pivot)
end

--endregion

--region Private

function XBigWorldGamePlayAgency:_InitWorldId(worldId)
    self._Model:SetCurrentWorldId(worldId)
    self:SetCurrentGameAgency(worldId)
end

function XBigWorldGamePlayAgency:_InitLevelId(levelId)
    self._Model:SetCurrentLevelId(levelId)
end

function XBigWorldGamePlayAgency:RegisterMVCA()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:DoRegisterMVCA()
end

function XBigWorldGamePlayAgency:UnRegisterMVCA()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:DoUnRegisterMVCA()
end

--endregion

--region 协议请求

function XBigWorldGamePlayAgency:RequestEnterInstLevel(worldId, levelId, team, targetPos, lastPos, resultHandle)
    XNetwork.Call("EnterInstLevelRequest", {
        WorldId = worldId,
        InstLevelId = levelId,
        Team = team,
        TargetPosA = targetPos,
        LastBigWorldPos = lastPos,
    }, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XBigWorldUI:TipCode(res.Code)
            return
        end

        if resultHandle then
            resultHandle(res.EnterResultData)
        end
    end)
end

function XBigWorldGamePlayAgency:RequestLeaveInstLevel(isResetSaveData, callback)
    XNetwork.Call("LeaveInstLevelRequest", {
        ResetSaveDataExit = isResetSaveData or false,
    }, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XBigWorldUI:TipCode(res.Code)
            return
        end

        if callback then
            callback()
        end
    end)
end

--endregion

--region 活动数据

--- 注册活动Agency
---@param agency XBigWorldActivityAgency
--------------------------
function XBigWorldGamePlayAgency:RegisterActivityAgency(agency)
    if IsWindowsEditor then
        if not CheckClassSuper(agency, XBigWorldActivityAgency) then
            XLog.Error(string.format("%s Agency 需要继承 XBigWorldActivityAgency", agency:GetId()))
            return
        end
    end
    local id = agency:GetActivityId()
    if id and id > 0 then
        self._ActivityAgency[id] = agency
    end
    local levelId = agency:GetLevelId()
    if levelId and levelId > 0 then
        self._Level2Agency[levelId] = agency
    end
end

function XBigWorldGamePlayAgency:InitActivityAgency()
    local templates = self._Model:GetAllActivityTemplates()
    for _, t in pairs(templates) do
        local moduleId = t.ModuleId
        if moduleId then
            ---@type XBigWorldActivityAgency
            local agency = XMVCA:GetAgency(moduleId)
            agency:SetConfig(t)
            agency:RegisterActivityAgency()
        else
            XLog.Error(string.format("活动：%s 未找到对应模块", t.Id))
        end
    end
end

function XBigWorldGamePlayAgency:ClearActivityAgency()
    self._ActivityAgency = {}
    self._Level2Agency = {}
end

function XBigWorldGamePlayAgency:GetActivityAgencyById(id)
    local agency = self._ActivityAgency[id]
    if not agency then
        XLog.Error("尚未注册活动Agency!, Id = " .. id)
        return
    end
    return agency
end

function XBigWorldGamePlayAgency:GetActivityAgencyByLevelId(levelId, noTips)
    local agency = self._Level2Agency[levelId]
    if not agency and not noTips then
        XLog.Error("尚未注册活动Agency!, LevelId = " .. levelId)
        return
    end
    return agency
end

--endregion

--region X3C

function XBigWorldGamePlayAgency:CmdRequestEnterInstLevel(data)
    local worldId = data.WorldId or 0
    local levelId = data.InstLevelId
    local team = data.Team
    local targetPos = data.TargetPos
    local lastPos = data.LastBigWorldPos

    if not team then
        local currentTeam = XMVCA.XBigWorldCharacter:GetCurrentTeam()

        team = currentTeam:ToServerTeam()
    end

    self:RequestEnterInstLevel(worldId, levelId, team, targetPos, lastPos)
end

function XBigWorldGamePlayAgency:CmdRequestLeaveInstLevel(data)
    self:RequestLeaveInstLevel(data.ResetSaveDataExit or false)
end

--endregion

--region Debug/黑幕进战斗

function XBigWorldGamePlayAgency:IsInDebugGame()
    return self._IsInDebugGame
end

function XBigWorldGamePlayAgency:GetDebugWorldId()
    return self._DebugWorldId
end

function XBigWorldGamePlayAgency:GetDebugLevelId()
    return self._DebugLevelId
end

function XBigWorldGamePlayAgency:EnterDebugGame(worldId, levelId)
    self._IsInDebugGame = true
    self._DebugWorldId = worldId
    self._DebugLevelId = levelId
    self._CurrentModuleId = ModuleId.XBigWorld

    self:InitX3C()
    self:GetCurrentAgency():BeforeEnterGame()
    XMVCA.XDlcWorld:OnEnterFight(self:GetCurrentWorldId())
    self:GetCurrentAgency():AfterEnterGame()
end

function XBigWorldGamePlayAgency:ClearDebugState()
    self._DebugLevelId = nil
    self._DebugWorldId = nil
    self._IsInDebugGame = nil
end

function XBigWorldGamePlayAgency.DebugEnter(worldId, levelId)
    XMVCA.XBigWorldGamePlay:EnterDebugGame(worldId, levelId)
end

--endregion

return XBigWorldGamePlayAgency
