---@class XBigWorldAgency : XAgency
---@field private _Model XBigWorldModel
local XBigWorldAgency = XClass(XAgency, "XBigWorldAgency")

---@type X3CCommand
local X3C_CMD = CS.X3CCommand

local CsBigWorldConfig = CS.XBigWorldConfig

function XBigWorldAgency:OnInit()
    --大世界通用
    self._MVCAList = {
        --基础组件
        ModuleId.XBigWorldCommon,
        ModuleId.XBigWorldUI,
        ModuleId.XBigWorldQuest,
        ModuleId.XBigWorldResource,
        --具体玩法
        ModuleId.XBigWorldCommanderDIY,
        ModuleId.XBigWorldBackpack,
        ModuleId.XBigWorldMessage,
        ModuleId.XBigWorldTeach,
        ModuleId.XBigWorldSet,
        ModuleId.XBigWorldLoading,
        ModuleId.XBigWorldMap,
    }
end

function XBigWorldAgency:InitRpc()
end

function XBigWorldAgency:InitEvent()
end

--- 初始化X3C注册,
function XBigWorldAgency:InitX3C()
    local register = function(cmd, func, obj)
        XMVCA.X3CProxy:RegisterHandler(cmd, func, obj)
    end

    -- 大世界任务
    register(X3C_CMD.CMD_QUEST_ALL_STATES_INIT, XMVCA.XBigWorldQuest.InitQuest, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_ACTIVATED, XMVCA.XBigWorldQuest.OnQuestActivated, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_UNDERTAKEN, XMVCA.XBigWorldQuest.OnQuestUndertaken, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_FINISH_NOTIFY, XMVCA.XBigWorldQuest.OnQuestFinished, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_STEP_STATE_CHANGED, XMVCA.XBigWorldQuest.OnStepChanged, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_STEP_OBJECTIVE_CHANGED, XMVCA.XBigWorldQuest.OnObjectiveChanged, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_NOTIFY_OPEN_QUEST_DELIVERY, XMVCA.XBigWorldQuest.OpenPopupDelivery, XMVCA.XBigWorldQuest)

    -- 大世界角色
    -- 大世界角色加载完毕
    register(X3C_CMD.CMD_LOCAL_PLAYER_NPC_LOAD_COMPLETED, XMVCA.XBigWorldCharacter.OnFightNpcLoadComplete,
        XMVCA.XBigWorldCharacter)
    register(X3C_CMD.CMD_TRIAL_NPC_JOIN_TEAM, XMVCA.XBigWorldCharacter.OnTrialNpcJoinTeam,
        XMVCA.XBigWorldCharacter)
    register(X3C_CMD.CMD_TRIAL_NPC_LEAVE_TEAM, XMVCA.XBigWorldCharacter.OnTrialNpcLeaveTeam,
        XMVCA.XBigWorldCharacter)

    -- 指挥官DIY
    register(X3C_CMD.CMD_SHOW_PLAYER_DIY_UI, XMVCA.XBigWorldCommanderDIY.OpenMainUi, XMVCA.XBigWorldCommanderDIY)
    -- 短信系统
    register(X3C_CMD.CMD_BIG_WORLD_MESSAGE_RECEIVE, XMVCA.XBigWorldMessage.OnReceiveMessage, XMVCA.XBigWorldMessage)
    -- 地图系统
    register(X3C_CMD.CMD_SET_MAP_PIN_VISIBLE, XMVCA.XBigWorldMap.OnDisplayMapPins, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_AUTO_STOP_TRACK_MAP_PIN, XMVCA.XBigWorldMap.OnCancelTrackMapPin, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_PLAYER_ENTER_SCENE_REGION, XMVCA.XBigWorldMap.OnPlayerEnterArea, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_PLAYER_EXIT_SCENE_REGION, XMVCA.XBigWorldMap.OnPlayerExitArea, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_ADD_QUEST_MAP_PIN, XMVCA.XBigWorldMap.OnAddQuestMapPin, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_REMOVE_QUEST_MAP_PIN, XMVCA.XBigWorldMap.OnRemoveQuestMapPin, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_REMOVE_QUEST_ALL_MAP_PIN, XMVCA.XBigWorldMap.OnRemoveQuestAllMapPins, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_START_TRACK_QUEST_MAP_PIN, XMVCA.XBigWorldMap.OnTrackQuestMapPin, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_STOP_TRACK_QUEST_MAP_PIN, XMVCA.XBigWorldMap.OnCancelTrackQuestMapPin, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_TELEPORT_PLAYER_COMPLETE, XMVCA.XBigWorldMap.OnTeleportComplete, XMVCA.XBigWorldMap)

    -- 通用功能
    register(X3C_CMD.CMD_OPEN_CONFIRM_POPUP_UI, XMVCA.XBigWorldUI.OpenConfirmPopupUiWithCmd, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_FIGHT_OPEN_UI_NOTIFY, XMVCA.XBigWorldUI.OnFightOpenUi, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_FIGHT_CLOSE_UI_NOTIFY, XMVCA.XBigWorldUI.OnFightCloseUi, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_SHOW_BIG_WORLD_OBTAIN, XMVCA.XBigWorldUI.OpenBigWorldObtainWithCmd, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_OPEN_DRAMA_SKIP_POPUP_UI, XMVCA.XBigWorldUI.OpenDramaSkipPopupWithCmd, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_OPEN_QUIT_CONFIRM_POPUP_UI, XMVCA.XBigWorldUI.OpenQuitConfirmPopupWithCmd, XMVCA.XBigWorldUI)
    
    -- 实例关卡相关功能(InstanceLevel)
    register(X3C_CMD.CMD_OPEN_LEAVE_INST_LEVEL_POPUP, XMVCA.XBigWorldCommon.OnOpenLeaveInstLevelPopup, XMVCA.XBigWorldCommon)

    -- 场景物体
    register(X3C_CMD.CMD_SET_SCENE_OBJECT_ACTIVE, XMVCA.XBigWorldService.OnSceneObjectActive, XMVCA.XBigWorldService)
    
    -- 加载Level
    register(X3C_CMD.CMD_DLC_FIGHT_ENTER_LEVEL, XMVCA.XBigWorldGamePlay.OnEnterLevel, XMVCA.XBigWorldGamePlay)
    register(X3C_CMD.CMD_DLC_FIGHT_LEAVE_LEVEL, XMVCA.XBigWorldGamePlay.OnLeaveLevel, XMVCA.XBigWorldGamePlay)
    register(X3C_CMD.CMD_DLC_FIGHT_BEGIN_UPDATE_LEVEL, XMVCA.XBigWorldGamePlay.OnLevelBeginUpdate, XMVCA.XBigWorldGamePlay)
    
    -- 切换实例关卡
    register(X3C_CMD.CMD_REQUEST_ENTER_INST_LEVEL, XMVCA.XBigWorldGamePlay.CmdRequestEnterInstLevel, XMVCA.XBigWorldGamePlay)
    register(X3C_CMD.CMD_REQUEST_LEAVE_INST_LEVEL, XMVCA.XBigWorldGamePlay.CmdRequestLeaveInstLevel, XMVCA.XBigWorldGamePlay)

    -- 打开玩法主入口
    register(X3C_CMD.CMD_BIG_WORLD_MAIN_OPEN_GAMEPLAY_MAIN_ENTRANCE, XMVCA.XBigWorldGamePlay.OnOpenMainUi, XMVCA.XBigWorldGamePlay)
    
    -- 图文教程
    register(X3C_CMD.CMD_BIG_WORLD_SHOW_TEACH, XMVCA.XBigWorldTeach.OnShowTeach, XMVCA.XBigWorldTeach)
    register(X3C_CMD.CMD_BIG_WORLD_OPEN_TEACH_POPUP, XMVCA.XBigWorldTeach.OnOpenTeachPopup, XMVCA.XBigWorldTeach)
    
    -- Loading
    register(X3C_CMD.CMD_FIGHT_OPEN_BLACK_LOADING, XMVCA.XBigWorldLoading.OnOpenBlackTransitionLoading, XMVCA.XBigWorldLoading)

    self:OnInitX3C()
end

function XBigWorldAgency:OnInitX3C()
end

function XBigWorldAgency:BeforeEnterGame()
    CsBigWorldConfig.Instance:Init()
    self:OnBeforeEnter()
end

function XBigWorldAgency:OnBeforeEnter()
end

function XBigWorldAgency:AfterEnterGame()
    self:OnAfterEnterGame()
end

function XBigWorldAgency:OnAfterEnterGame()
end

function XBigWorldAgency:EnterFight()
    XMVCA.XBigWorldMap:InitMapPinData(XMVCA.XBigWorldGamePlay:GetCurrentWorldId())
    XMVCA.XBigWorldMap:SendCurrentTrackCommand()
    self:OnEnterFight()
end

function XBigWorldAgency:OnEnterFight()
end

function XBigWorldAgency:ExitFight()
    XMVCA.XBigWorldMap:ForceCloseBigWorldLittleMapUi()
    XMVCA.XBigWorldUI:ForceResetSystemInput()
    self:OnExitFight()
end

function XBigWorldAgency:OnExitFight()
end

function XBigWorldAgency:EnterLevel(levelId)
    XMVCA.XBigWorldMap:ChangeLittleMapRefCount(true)
    self:OnEnterLevel(levelId)
end

function XBigWorldAgency:OnEnterLevel(levelId)
end

function XBigWorldAgency:LeaveLevel(levelId)
    XMVCA.XBigWorldMap:ChangeLittleMapRefCount(false)
    self:OnLeaveLevel(levelId)
end

function XBigWorldAgency:OnLeaveLevel(levelId)
end

function XBigWorldAgency:LevelBeginUpdate()
    XMVCA.XBigWorldMap:TryOpenLittleMapUi()
    XMVCA.XBigWorldMessage:TryOpenMessageTipUi()
    XMVCA.XBigWorldTeach:TryShowTeach()
    self:OnLevelBeginUpdate()
end

function XBigWorldAgency:OnLevelBeginUpdate()
end

function XBigWorldAgency:UpdatePlayerData(res)
    if not res then
        return
    end
    XMVCA.XBigWorldCommanderDIY:UpdateData(res.Gender, res.CommanderWearFashionDict, res.CommanderFashionBags)
    XMVCA.XBigWorldCharacter:UpdateTeam(res.CurrentTeamId, res.TeamDict)
    XMVCA.XBigWorldCharacter:UpdateCharacter(res.CharacterWearFashionDict)
    XMVCA.XBigWorldQuest:UpdateData(res.CurrentTraceQuestId)
    XMVCA.XBigWorldMessage:UpdateAllMessageData(res.BigWorldMessageDict)
    XMVCA.XBigWorldMap:UpdateTrackMapPin(res.MapTrackPinData)
    XMVCA.XBigWorldTeach:UpdateTeachUnlockServerData(res.BigWorldHelpCourseList)
    self:OnUpdatePlayerData(res)
end

function XBigWorldAgency:OnUpdatePlayerData(res)
end

--- 更新世界数据
---@param res Protocol.Protocol.Frontend.DlcWorldSaveDataResponse
function XBigWorldAgency:UpdateWorldData(res)
    self:OnUpdateWorldData(res)
end

function XBigWorldAgency:OnUpdateWorldData(res)
end

function XBigWorldAgency:Exit()
    self:OnExit()
    CsBigWorldConfig.Instance:Dispose()
end

function XBigWorldAgency:OnExit()
end

function XBigWorldAgency:DoRegisterMVCA()
    --先注册BigWorld
    for _, moduleId in pairs(self._MVCAList) do
        if not XMVCA:IsRegisterAgency(moduleId) then
            XMVCA:RegisterAgency(moduleId)
        end
    end
    --在注册子类
    self:OnRegisterMVCA()
end

function XBigWorldAgency:OnRegisterMVCA()
end

function XBigWorldAgency:DoUnRegisterMVCA()
    --先注销子类
    self:OnUnRegisterMVCA()
    --再注销BigWorld
    for _, moduleId in pairs(self._MVCAList) do
        if XMVCA:IsRegisterAgency(moduleId) then
            XMVCA:ReleaseModule(moduleId)
        end
    end
end

function XBigWorldAgency:OnUnRegisterMVCA()
end

--region BigWorldConfig

function XBigWorldAgency:GetInt(key)
    return CsBigWorldConfig.Instance:GetInt(key)
end

function XBigWorldAgency:GetFloat(key)
    return CsBigWorldConfig.Instance:GetFloat(key)
end

function XBigWorldAgency:GetBool(key)
    return CsBigWorldConfig.Instance:GetBool(key)
end

function XBigWorldAgency:GetString(key)
    return CsBigWorldConfig.Instance:GetString(key)
end

--endregion BigWorldConfig

--region 主界面跳转

function XBigWorldAgency:OpenMenu()
    XMVCA.XBigWorldUI:Open("UiBigWorldMenu")
end

function XBigWorldAgency:OpenQuest(index, questId)
    if XMVCA.XBigWorldQuest:IsTemporaryShield(questId) then
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldTaskMain", index, questId)
end

function XBigWorldAgency:OpenBackpack()
    XMVCA.XBigWorldUI:Open("UiBigWorldBackpack")
end

function XBigWorldAgency:OpenMessage()
    XMVCA.XBigWorldUI:Open("UiBigWorldMessage")
end

function XBigWorldAgency:OpenTeam()
    XMVCA.XBigWorldUI:Open("UiBigWorldRoleRoom")
end

function XBigWorldAgency:OpenExplore()
    XLog.Warning("打开探索界面")
end

function XBigWorldAgency:OpenPhoto()
    XLog.Warning("打开拍照界面")
end

function XBigWorldAgency:OpenTeaching()
    XMVCA.XBigWorldTeach:OpenTeachMainUi()
end

function XBigWorldAgency:OpenSetting()
    XMVCA.XBigWorldSet:OpenSettingUi()
end

function XBigWorldAgency:OpenMap()
    XMVCA.XBigWorldMap:OpenBigWorldMapUi()
end

function XBigWorldAgency:OpenFashion(characterId, typeIndex)
    XMVCA.XBigWorldUI:Open("UiBigWorldCoating", characterId, typeIndex)
end

--endregion 主界面跳转

return XBigWorldAgency
