local XUiPanelBabelTower = require("XUi/XUiNewRoomSingle/XUiPanelBabelTower")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiNewRoomSingle = XLuaUiManager.Register(XLuaUi, "UiNewRoomSingle")

local CHAR_POS1 = 1
local CHAR_POS2 = 2
local CHAR_POS3 = 3
local MAX_CHAR_COUNT = 3
local LONG_CLICK_TIME = 0
local TIMER = 1
local LOAD_TIME = 10

function XUiNewRoomSingle:OnAwake()
    self:AutoAddListener()
    self.PanelTip.gameObject:SetActiveEx(false)
    self.ImgRoleRepace.gameObject:SetActiveEx(false)
end
--== data 可能包含的变量 ----
-- ChallengeCount
-- ForceConditionIds
-- NodeId
-- TeamBuffId
-- WorldBossTeamDatas
-- BabelTowerData
-- ChallengeId
-- ChessPursuitData
--== end ----
-- !!! 该界面已废弃，请使用UiBattleRoleRoom
function XUiNewRoomSingle:OnStart(stageId, data, ...)
    self.Args = { ... }
    self.ChangeCharIndex = 0
    local uiModelRoot = self.UiModelGo.transform
    self.PanelCharacterInfo = {
        [1] = {
            PanelRoleEffect = uiModelRoot:FindTransform("PanelRoleEffect1"),
            TongdiaoEffect = uiModelRoot:FindTransform("ImgEffectTongDiao1"),
            RoleModelPanel = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelRoleModel1"), self.Name, nil, true, nil, true, true),
        },
        [2] = {
            PanelRoleEffect = uiModelRoot:FindTransform("PanelRoleEffect2"),
            TongdiaoEffect = uiModelRoot:FindTransform("ImgEffectTongDiao2"),
            RoleModelPanel = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelRoleModel2"), self.Name, nil, true, nil, true, true),
        },
        [3] = {
            PanelRoleEffect = uiModelRoot:FindTransform("PanelRoleEffect3"),
            TongdiaoEffect = uiModelRoot:FindTransform("ImgEffectTongDiao3"),
            RoleModelPanel = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelRoleModel3"), self.Name, nil, true, nil, true, true),
        },
    }

    self.Camera = self.Transform:GetComponent("Canvas").worldCamera
    self.RectTransform = self.Transform:GetComponent("RectTransform")
    self:InitInfo(stageId, data)
    self.Proxy = XUiNewRoomSingleProxy.ProxyDic[self.StageInfos.Type]
    self.BtnShowInfoToggle.CallBack = function(val)
        self:OnBtnShowInfoToggleByProxy(val)
    end
    -- 默认助战为关闭状态
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.OtherHelp) then
        self.BtnSupportToggle:SetButtonState(XUiButtonState.Normal)
    end

    self:InitEffectPositionInfo()
    self:InitTeamData()
    self:InitPanelTeam()
    self:SetWeakness()
    self:InitCharacterLimit()
    self:InitBtnLongClicks()
    self:SetCondition()
    self:SetStageInfo()
    self:InitEndurance()
    --更新战力限制提示
    self:InitFightControl()
    --更新战斗信息
    self:InitCharacterInfo()
    self:InitFirstFightTabBtns()

    if self.StageInfos.HaveAssist == 1 then
        self:ShowAssistToggle(true)
        -- 保存玩家选择助战状态
        local assistSwitch = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.AssistSwitch .. XPlayer.Id)
        if assistSwitch == nil or assistSwitch == 0 then
            self:SetAssistStatus(false)
        else
            self:SetAssistStatus(true)
        end
    else
        self:ShowAssistToggle(false)
        self:SetAssistStatus(false)
    end
    -- 更新爬塔活动切换助战按钮状态
    self:SetSwitchRole()
    self:InitProxyPanel()
    self:InitWorldBoss()
    self:InitPanelBabelTower()
    self:InitPanelNieR()
    self:InitChessPursuit()

    XEventManager.AddEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.UpdateTeamPrefab, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnOpenLoadingOrBeginPlayMovie, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnOpenLoadingOrBeginPlayMovie, self)
    -- 自动关闭
    local openAutoClose, autoCloseEndTime, callback = self:GetAutoCloseInfo()
    if openAutoClose then
        self:SetAutoCloseInfo(autoCloseEndTime, callback)
    end
end

function XUiNewRoomSingle:OnDestroy()
    self:DestroyNewRoomSingle()
    XUiHelper.StopAnimation()
    self:RemoveTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.UpdateTeamPrefab, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnOpenLoadingOrBeginPlayMovie, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnOpenLoadingOrBeginPlayMovie, self)
end

function XUiNewRoomSingle:OnEnable()
    XUiNewRoomSingle.Super.OnEnable(self)
    self:InitFightControl()
    self:InitCharacterInfo()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CHANGE_STAGE, self.OnSetStageId, self)
end

function XUiNewRoomSingle:OnDisable()
    XUiNewRoomSingle.Super.OnDisable(self)
    XDataCenter.FavorabilityManager.StopCv()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CHANGE_STAGE, self.OnSetStageId, self)
end

function XUiNewRoomSingle:OnSetStageId(stageId, data)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    if not CS.XFight.IsRunning and not XLuaUiManager.IsUiLoad("UiLoading") then
        local contenttext = CS.XTextManager.GetText("StageChangeInfo", stageCfg.Name)
        XUiManager.TipMsg(contenttext)
    end
    self:InitInfo(stageId, data)
    self:RefreshCharacterTypeTips()
end

function XUiNewRoomSingle:InitInfo(stageId, data)
    self.CurrentStageId = stageId
    if data then
        self.ChallengeCount = data.ChallengeCount
        self.SuggestedConditionIds = data.SuggestedConditionIds   -- 暂未使用
        self.ForceConditionIds = data.ForceConditionIds
        self.EventIds = data.EventIds   -- 暂未使用
        self.NodeId = data.NodeId
        self.TeamBuffId = data.TeamBuffId
        self.WorldBossTeamDatas = data.WorldBossTeamDatas
        self.ChessPursuitData = data.ChessPursuitData
        self.BabelTowerData = data.BabelTowerData
        self.ChallengeId = data.ChallengeId
        self.SimulateTrainInfo = data.SimulateTrainInfo
        self.LivWarRaceData = data.LivWarRaceData
    end
    -- 需要默认值的变量
    self.SuggestedConditionIds = self.SuggestedConditionIds or {}
    self.ForceConditionIds = self.ForceConditionIds or {}

    self.TypeIdMainLine = CS.XGame.Config:GetInt("TypeIdMainLine")
    self.TypeIdBossSingle = CS.XGame.Config:GetInt("TypeIdBossSingle")
    self.TypeIdExplore = CS.XGame.Config:GetInt("TypeIdExplore")
    self.TypeIdRpgTower = CS.XGame.Config:GetInt("TypeIdRpgTower")
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.StageInfos = XDataCenter.FubenManager.GetStageInfo(stageId)
end

function XUiNewRoomSingle:InitEffectPositionInfo()
    if self.StageInfos.Type ~= XDataCenter.FubenManager.StageType.InfestorExplore then
        self.PanelEffectPosition.gameObject:SetActiveEx(false)
        return
    end
    self.TxtEffectPosition.text = XDataCenter.FubenInfestorExploreManager.GetBuffDes()
    self.PanelEffectPosition.gameObject:SetActiveEx(true)
end

function XUiNewRoomSingle:InitCharacterLimit()
    local characterLimitType = self:GetCharacterLimitType()

    if not XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType) then
        self.PanelCharacterLimit.gameObject:SetActiveEx(false)
        return
    else
        self.PanelCharacterLimit.gameObject:SetActiveEx(true)
    end

    local icon = XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
    self.ImgCharacterLimit:SetSprite(icon)
end

function XUiNewRoomSingle:GetCurTeamCharacterType()
    for _, characterId in pairs(self.CurTeam.TeamData) do
        if characterId > 0 then
            return XCharacterConfigs.GetCharacterType(characterId)
        end
    end
end

-- 获取队伍类型队列
function XUiNewRoomSingle:GetCurTeamCharacterTypeList()
    local result = {}
    for _, characterId in pairs(self.CurTeam.TeamData) do
        if characterId > 0 then
            table.insert(result, XCharacterConfigs.GetCharacterType(characterId))
        end
    end
    return result
end

function XUiNewRoomSingle:RefreshCharacterTypeTips()
    if self.Proxy and self.Proxy.RefreshCharacterTypeTips then
        return self.Proxy.RefreshCharacterTypeTips(self)
    end

    local stageId = self.CurrentStageId
    local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
    local characterType = self:GetCurTeamCharacterType()
    local characterLimitType = self:GetCharacterLimitType()
    local text = XFubenConfigs.GetStageCharacterLimitTextTeamEdit(characterLimitType, characterType, limitBuffId)
    self.TxtCharacterLimit.text = text
end

-- 首次出场按钮组
function XUiNewRoomSingle:InitFirstFightTabBtns()
    if self:GetIsHideSwitchFirstFightPosBtnsWithProxy() then
        -- 出场按钮组与队长技能选择的显隐
        self.PanelTeamLeader.gameObject:SetActiveEx(false)
        self.PanelBtnLeader.gameObject:SetActiveEx(false)
        return
    end

    local tabGroup = {
        self.BtnRed,
        self.BtnBlue,
        self.BtnYellow,
    }
    self.PanelTabCaptain:Init(tabGroup, function(tabIndex) self:OnFirstFightTabClick(tabIndex) end)

    -- 首发位为nil或0,使其与队长位一致(因为服务器在之前只有队长位，后面区分了队长位与首发位,存在有队长位，没有首发位的情况)
    if self.CurTeam.FirstFightPos == nil or self.CurTeam.FirstFightPos == 0 then
        self.CurTeam.FirstFightPos = self.CurTeam.CaptainPos
    end

    -- 首发位依然为nil或0则报错，默认第一位为首发位
    if self.CurTeam.FirstFightPos == nil then
        XLog.Error("XUiNewRoomSingle:InitFirstFightTabBtns函数错误, self.CurTeam.FirstFightPos为nil")
        self.CurTeam.FirstFightPos = CHAR_POS1
    elseif self.CurTeam.FirstFightPos == 0 then
        XLog.Error("XUiNewRoomSingle:InitFirstFightTabBtns函数错误, self.CurTeam.FirstFightPos为0")
        self.CurTeam.FirstFightPos = CHAR_POS1
    end

    self.PanelTabCaptain:SelectIndex(self.CurTeam.FirstFightPos)
end

-- 设置首次出场
function XUiNewRoomSingle:OnFirstFightTabClick(tabIndex)
    local firstFightPos = self.CurTeam.FirstFightPos
    if firstFightPos == tabIndex then
        return
    end

    self.CurTeam.FirstFightPos = tabIndex
    self:SetFirstFightPosWithProxy(tabIndex)
    self:SetTeamByProxy()
    if self:IsBabelTower() then
        local cb = self.BabelTowerData.Cb
        if cb then
            cb(self.CurTeam.TeamData, self.CurTeam.CaptainPos, self.CurTeam.FirstFightPos)
        end
    end
    self:InitPanelTeam()
end

-- 设置队长技能
function XUiNewRoomSingle:OnClickTabCallBack(tabIndex)
    local captainPos = self.CurTeam.CaptainPos
    if captainPos == tabIndex then
        return
    end
    self.CurTeam.CaptainPos = tabIndex
    self:SetCaptainPosWithProxy(tabIndex)
    self:SetTeamByProxy()
    local isUnionKillType = self:IsUnionKillType()
    if isUnionKillType then
        self:UpdateTeamCaptionPos()
    end

    if self:IsBabelTower() then
        local cb = self.BabelTowerData.Cb
        if cb then
            cb(self.CurTeam.TeamData, self.CurTeam.CaptainPos, self.CurTeam.FirstFightPos)
        end
    end
    self:InitPanelTeam()
end

function XUiNewRoomSingle:OnOpenLoadingOrBeginPlayMovie()
    self:Remove()
end

function XUiNewRoomSingle:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnTeamPrefab, self.OnBtnTeamPrefabClick)
    self:RegisterClickEvent(self.BtnChar1, self.OnBtnChar1Click)
    self:RegisterClickEvent(self.BtnChar2, self.OnBtnChar2Click)
    self:RegisterClickEvent(self.BtnChar3, self.OnBtnChar3Click)

    self.CharacterPets1:GetObject("BtnClick").CallBack = function() self:HandlePartnerClick(CHAR_POS1) end
    self.CharacterPets2:GetObject("BtnClick").CallBack = function() self:HandlePartnerClick(CHAR_POS2) end
    self.CharacterPets3:GetObject("BtnClick").CallBack = function() self:HandlePartnerClick(CHAR_POS3) end

    self.BtnEnterFight.CallBack = function() self:OnBtnEnterFightClick() end
    self.BtnSupportToggle.CallBack = function(state) self:OnBtnAssistToggleClick(state) end
    self.BtnSwitchRole01.CallBack = function() self:OnBtnSwitchRoleClick() end
    self.BtnSwitchRole02.CallBack = function() self:OnBtnSwitchRoleClick() end
    self.BtnTeamBuff.CallBack = function() self:OnClickBtnTeamBuff() end
    self.BtnGo.CallBack = function() self:OnPanelBtnLeaderClick() end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.OtherHelp) then
        self.BtnSupportToggle:SetDisable(true)
    end
end

function XUiNewRoomSingle:OnPanelBtnLeaderClick()
    -- 获取机器人为RobotId，玩家角色为CharacterId的队伍数据
    -- 如果代理没有实现该接口，且队伍拥有没有使用RobotId的机器人，则无法获取机器人配置的时装与解放等级数据，队长头像会使用初始头像
    local realCharData = self:GetRealCharDataByProxy()
    local teamData = realCharData or self.CurTeam.TeamData

    XLuaUiManager.Open("UiNewRoomSingleTip", self, teamData, self.CurTeam.CaptainPos, function(index)
        self:OnClickTabCallBack(index)
    end)
end

function XUiNewRoomSingle:OnBtnTeamPrefabClick()
    if self:IsWorldBossType() then
        return
    end
    if self:IsRogueLikeType() then
        return
    end
    if self:CheckHasRobot() then
        return
    end

    local stageId = self.CurrentStageId
    local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
    local characterLimitType = self:GetCharacterLimitType()
    local teamGridId = self:GetTeamGridId()
    XLuaUiManager.Open("UiRoomTeamPrefab", self.CurTeam.CaptainPos, self.CurTeam.FirstFightPos, characterLimitType, limitBuffId, self.StageInfos.Type, teamGridId, nil, stageId, self.CurTeam)
end

function XUiNewRoomSingle:GetTeamGridId()
    local teamGridId
    if self:IsChessPursuit() then
        teamGridId = self.ChessPursuitData.TeamGridIndex
    end
    return teamGridId
end

function XUiNewRoomSingle:OnBtnShowInfoToggle(val)
    if val then
        local key = "NewRoomShowInfoToggle" .. tostring(XPlayer.Id)
        CS.UnityEngine.PlayerPrefs.SetInt(key, val)
    end
    self:InitCharacterInfo()
end

function XUiNewRoomSingle:OnBtnAssistToggleClick(state)
    if self:IsRogueLikeType() or self:IsUnionKillType() then
        return
    end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.OtherHelp) then
        return
    end

    self:SetAssistStatus(XUiHelper.GetToggleVal(state))
    local assistSwitch = self:GetAssistStatus() and 1 or 0
    CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.AssistSwitch .. XPlayer.Id, assistSwitch)
    if self:GetAssistStatus() then
        self:PlayTips("FightAssistOpen", true)
    else
        self:PlayTips("FightAssistClose", false)
    end
end

function XUiNewRoomSingle:SetBossSingleInfo()
    self:ShowAssistToggle(false)
end

-- 初始化长按事件
function XUiNewRoomSingle:InitBtnLongClicks()
    local btnLongClick1 = self.BtnChar1:GetComponent("XUiPointer")
    local btnLongClick2 = self.BtnChar2:GetComponent("XUiPointer")
    local btnLongClick3 = self.BtnChar3:GetComponent("XUiPointer")
    XUiButtonLongClick.New(btnLongClick1, 10, self, nil, self.OnBtnUnLockLongClick1, self.OnBtnUnLockLongUp, false)
    XUiButtonLongClick.New(btnLongClick2, 10, self, nil, self.OnBtnUnLockLongClick2, self.OnBtnUnLockLongUp, false)
    XUiButtonLongClick.New(btnLongClick3, 10, self, nil, self.OnBtnUnLockLongClick3, self.OnBtnUnLockLongUp, false)
end

function XUiNewRoomSingle:OnBtnUnLockLongUp()
    self.ImgRoleRepace.gameObject:SetActiveEx(false)
    self.IsUp = not self.IsUp
    LONG_CLICK_TIME = 0

    local stageId = self.CurrentStageId
    if not self:CheckCharCanClickByProxy(stageId) then
        return
    end

    if self.ChangeCharIndex > 0 then
        local targetX = math.floor(self:GetPisont().x + self.RectTransform.rect.width / 2)
        local targetIndex
        if targetX <= self.RectTransform.rect.width / 3 then
            targetIndex = CHAR_POS2
        elseif targetX > self.RectTransform.rect.width / 3 and targetX <= self.RectTransform.rect.width / 3 * 2 then
            targetIndex = CHAR_POS1 --UI的位置1号位是在中间的
        else
            targetIndex = CHAR_POS3
        end

        local changeIndex = self.ChangeCharIndex
        if targetIndex > 0 and targetIndex ~= changeIndex then
            local teamData = XTool.Clone(self.CurTeam.TeamData)
            local targetId = teamData[targetIndex]
            teamData[targetIndex] = teamData[changeIndex]
            teamData[changeIndex] = targetId

            self:HandleSwitchTeamPosWithProxy(changeIndex, targetIndex)
            self:UpdateTeam(teamData)

            if self:IsUnionKillType() then
                self:SwitchCacheTeam(changeIndex, targetIndex)
            end

            if self:IsRogueLikeType() and self.RogueLikeIsRobot then
                local teamCache = self.ChooseRobots
                local temp = teamCache[changeIndex]
                teamCache[changeIndex] = teamCache[targetIndex]
                teamCache[targetIndex] = temp
            end
        end
        self.ChangeCharIndex = 0
    end
end

function XUiNewRoomSingle:SeBtnUnLockLongClickt(index, time)
    if not self:CheckCharCanLongClickByProxy(self.CurrentStageId) then
        return
    end

    if self.CurTeam.TeamData[index] <= 0 then
        self.IsUp = true
        return
    end

    LONG_CLICK_TIME = LONG_CLICK_TIME + time / 1000
    if self.IsUp then
        self.IsUp = false
        return
    end
    if LONG_CLICK_TIME > TIMER and not self.IsUp then
        self.IsUp = false
        if not self.ImgRoleRepace.gameObject.activeSelf then
            self.ImgRoleRepace.gameObject:SetActiveEx(true)
        end
        self.ImgRoleRepace.gameObject.transform.localPosition = self:GetPisont()
    end
    if self.ChangeCharIndex <= 0 then
        self.ChangeCharIndex = index
    end
end

function XUiNewRoomSingle:GetPisont()
    local screenPoint
    if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
        screenPoint = CS.UnityEngine.Vector2(CS.UnityEngine.Input.mousePosition.x, CS.UnityEngine.Input.mousePosition.y)
    else
        screenPoint = CS.UnityEngine.Input.GetTouch(0).position
    end

    -- 设置拖拽
    local hasValue, v2 = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.RectTransform, screenPoint, self.Camera)
    if hasValue then
        return CS.UnityEngine.Vector3(v2.x, v2.y, 0)
    else
        return CS.UnityEngine.Vector3.zero
    end
end

function XUiNewRoomSingle:OnBtnUnLockLongClick1(time)
    self:SeBtnUnLockLongClickt(CHAR_POS1, time)
end

function XUiNewRoomSingle:OnBtnUnLockLongClick2(time)
    self:SeBtnUnLockLongClickt(CHAR_POS2, time)
end

function XUiNewRoomSingle:OnBtnUnLockLongClick3(time)
    self:SeBtnUnLockLongClickt(CHAR_POS3, time)
end

-- 初始化 team 数据
function XUiNewRoomSingle:InitTeamData()
    local curTeam
    curTeam = self:GetTeamByProxy()
    if not curTeam then
        if self.StageInfos.Type == XDataCenter.FubenManager.StageType.BossSingle then
            curTeam = XDataCenter.TeamManager.GetPlayerTeam(self.TypeIdBossSingle)
        elseif self.StageInfos.Type == XDataCenter.FubenManager.StageType.Explore then
            curTeam = XDataCenter.TeamManager.GetPlayerTeam(self.TypeIdExplore)
            --每次进入清空上次的选则
            for i = 1, #curTeam.TeamData do
                curTeam.TeamData[i] = 0
            end
        elseif self:IsWorldBossType() then
            local characterDatas = self.WorldBossTeamDatas
            local tmpData = {}
            for index, data in pairs(characterDatas) do
                tmpData.TeamData = tmpData.TeamData or {}
                if data.IsCaptain then
                    tmpData.CaptainPos = index
                end

                if data.IsFirstFight then
                    tmpData.FirstFightPos = index
                end

                if data.RobotId > 0 then
                    table.insert(tmpData.TeamData, data.RobotId)
                elseif data.Id > 0 then
                    table.insert(tmpData.TeamData, data.Id)
                else
                    table.insert(tmpData.TeamData, 0)
                end
            end
            curTeam = next(tmpData) and tmpData
            curTeam = curTeam or XWorldBossConfigs.DefaultTeam
        elseif self:IsChessPursuit() then
            -- 默认清空
            curTeam = self.ChessPursuitData.CurTeam
        elseif self:IsBabelTower() then
            curTeam = self.BabelTowerData.TeamList
        elseif self:IsNieRType() then
            curTeam = XDataCenter.NieRManager.GetPlayerTeamData(self.CurrentStageId)
        else
            curTeam = XDataCenter.TeamManager.GetPlayerTeam(self.TypeIdMainLine)
        end
    end
    if curTeam == nil then
        return
    end

    self:LimitCharacterByProxy(curTeam)

    -- 初始化爬塔阵容
    if self:IsRogueLikeType() then
        curTeam = self:RogueLikeInitTeam(curTeam)
    end
    -- 初始化狙击战阵容
    if self:IsUnionKillType() then
        curTeam = self:UnionKillInitTeam(curTeam)
    end
    self.CurTeam = curTeam
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.CurrentStageId)
    local RobotIds = self:GetRobotIdsByProxy(self.CurrentStageId)
    self.HasRobot = RobotIds and #RobotIds > 0 or (self:IsNieRType() and self.Args[3])

    if RobotIds and #RobotIds > 0 then
        self.CurTeam.TeamData = {}
        for i = 1, MAX_CHAR_COUNT do
            if i > #RobotIds then
                table.insert(self.CurTeam.TeamData, 0)
            else
                local charId = XRobotManager.GetCharacterId(RobotIds[i])
                table.insert(self.CurTeam.TeamData, charId)
            end
        end

        -- 有机器人出战位和首发位设为1
        self.CurTeam.CaptainPos = self:GetCaptainPos()
        self.CurTeam.FirstFightPos = self:GetFirstFightPos()
    end

    for i = 1, MAX_CHAR_COUNT do
        local teamCfg = XTeamConfig.GetTeamCfgById(i)
        if teamCfg and not string.IsNilOrEmpty(teamCfg.EffectPath) then
            self.PanelCharacterInfo[i].PanelRoleEffect:LoadPrefab(teamCfg.EffectPath, false)
        end
    end
end

-- team Ui 初始化
function XUiNewRoomSingle:InitPanelTeam()
    self.BtnEnterFight:SetDisable(true, false)

    if not self.CurTeam then
        return
    end
    local firstFightPos = self.CurTeam.FirstFightPos
    -- 记录是否全部加载完成
    self.LoadModelCount = 0
    for i = 1, MAX_CHAR_COUNT do
        local posData = self.CurTeam.TeamData[i]
        if posData and posData > 0 then
            self.LoadModelCount = self.LoadModelCount + 1
        end

        -- 设置首发标签，隐藏所有队长标签
        self["PanelLeader" .. i].gameObject:SetActiveEx(false)
        self["PanelFirstRole" .. i].gameObject:SetActiveEx(not self:GetIsHideSwitchFirstFightPosBtnsWithProxy()
        and i == firstFightPos)

    end

    for i = 1, MAX_CHAR_COUNT do
        self["Timer" .. i] = XScheduleManager.ScheduleOnce(function()
            -- if XTool.UObjIsNil(self.Transform) or not self.GameObject.activeSelf then
            --     return
            -- end
            if XTool.UObjIsNil(self.Transform) then
                return
            end
            local posData = self.CurTeam.TeamData[i]
            if posData and posData > 0 then
                self:UpdateRoleModelByProxy(posData, self.PanelCharacterInfo[i].RoleModelPanel, i)
                self["ImgAdd" .. i].gameObject:SetActiveEx(false)
                self:UpdateRoleStanmina(posData, i)
            else
                self["PanelStaminaBar" .. i].gameObject:SetActiveEx(false)
                self["ImgAdd" .. i].gameObject:SetActiveEx(true)
            end
        end, i * LOAD_TIME)
    end

    self:RefreshCaptainSkill()
end

function XUiNewRoomSingle:UpdateFightControl()
    local teamAbility = {}

    for _, v in ipairs(self.CurTeam.TeamData) do
        if self.Proxy and self.Proxy.GetCharAbility then
            table.insert(teamAbility, self.Proxy.GetCharAbility(v))
        end
        local isRobot = XRobotManager.CheckIsRobotId(v)
        local char = XDataCenter.CharacterManager.GetCharacter(v)

        if isRobot then
            table.insert(teamAbility, XRobotManager.GetRobotAbility(v))
        elseif char == nil then
            table.insert(teamAbility, 0)
        else
            table.insert(teamAbility, char.Ability)
        end
    end
    local conditionResult = true
    for _, id in pairs(self.ForceConditionIds) do
        local ret = XConditionManager.CheckCondition(id, self.CurTeam.TeamData)
        if not ret then
            conditionResult = false
        end
    end
    self.FightControlResult = self.FightControl:UpdateInfo(self.StageCfg.FightControlId, teamAbility, conditionResult, self.CurrentStageId, self.CurTeam.TeamData)
end

function XUiNewRoomSingle:RemoveTimer()
    for i = 1, MAX_CHAR_COUNT do
        if self["Timer" .. i] then
            XScheduleManager.UnSchedule(self["Timer" .. i])
            self["Timer" .. i] = nil
        end
    end
end

--更新模型
function XUiNewRoomSingle:UpdateRoleModel(charId, roleModelPanel, pos)
    roleModelPanel:ShowRoleModel() -- 先Active 再加载模型以及播放动画
    local callback = function()
        self.LoadModelCount = self.LoadModelCount - 1
        if self.LoadModelCount <= 0 then
            self.BtnEnterFight:SetDisable(false)
        end
    end
    -- 根据机器人id来更新模型
    if self.HasRobot then
        local RobotIds = self:GetRobotIdsByProxy(self.CurrentStageId)
        local robotId = RobotIds[pos]
        self:UpdateRobotModel(robotId, roleModelPanel, callback)
    else
        if self:IsRogueLikeType() and self.RogueLikeIsRobot then
            roleModelPanel:UpdateCharacterModel(charId, nil, nil, nil, callback, self:GetRogueLikeFactionByCid(charId))
        elseif self:IsUnionKillType() then
            self:UpdateUnionKillMode(roleModelPanel, pos, callback, charId)
        else
            if XRobotManager.CheckIsRobotId(charId) then
                local robotId = charId
                self:UpdateRobotModel(robotId, roleModelPanel, callback)
            else
                roleModelPanel:UpdateCharacterModel(charId, nil, nil, nil, callback)
            end
        end
    end
end

--==============================
 ---@desc 更新机器人模型，支持自定义涂装
 ---@robotId 机器人Id 
 ---@roleModelPanel @class XUiPanelRoleModel 
 ---@callback 回调 
--==============================
function XUiNewRoomSingle:UpdateRobotModel(robotId, roleModelPanel, callback)
    local characterId = XRobotManager.GetCharacterId(robotId)
    local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(characterId)
    if XRobotManager.CheckUseFashion(robotId) and isOwn then
        local character = XDataCenter.CharacterManager.GetCharacter(characterId)
        local viewModel = character:GetCharacterViewModel()
        roleModelPanel:UpdateCharacterModel(characterId, nil, nil, nil, callback, viewModel:GetFashionId())
    else
        local robotCfg = XRobotManager.GetRobotTemplate(robotId)
        roleModelPanel:UpdateRobotModel(robotId, characterId, callback, robotCfg.FashionId, robotCfg.WeaponId)
    end
end

--更新耐力值
function XUiNewRoomSingle:UpdateRoleStanmina(charId, index)
    local maxStamina = 9
    local curStamina = 0
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.BossSingle then
        maxStamina = XDataCenter.FubenBossSingleManager.GetMaxStamina()
        curStamina = maxStamina - XDataCenter.FubenBossSingleManager.GetCharacterChallengeCount(charId)
    elseif self.StageInfos.Type == XDataCenter.FubenManager.StageType.Explore then
        maxStamina = XDataCenter.FubenExploreManager.GetMaxEndurance(XDataCenter.FubenExploreManager.GetCurChapterId())
        curStamina = maxStamina - XDataCenter.FubenExploreManager.GetEndurance(XDataCenter.FubenExploreManager.GetCurChapterId(), charId)
    else
        self["PanelStaminaBar" .. index].gameObject:SetActiveEx(false)
        return
    end

    local text = CSXTextManagerGetText("RoomStamina", curStamina, maxStamina)
    self["TxtMyStamina" .. index].text = text
    self["ImgStaminaExpFill" .. index].fillAmount = curStamina / maxStamina
    self["PanelStaminaBar" .. index].gameObject:SetActiveEx(true)
end

function XUiNewRoomSingle:SetAssistStatus(active)
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.OtherHelp) then
        if active then
            self.BtnSupportToggle:SetButtonState(XUiButtonState.Select)
        else
            self.BtnSupportToggle:SetButtonState(XUiButtonState.Normal)
        end
    end
end

function XUiNewRoomSingle:ShowAssistToggle(show)
    if show then
        self.BtnSupportToggle.gameObject:SetActiveEx(true)
    else
        self.BtnSupportToggle.gameObject:SetActiveEx(false)
    end
end

function XUiNewRoomSingle:GetAssistStatus()
    return self.BtnSupportToggle:GetToggleState()
end

function XUiNewRoomSingle:SetWeakness()
    self.PanelWeakness.gameObject:SetActiveEx(true)

    local eventDesc
    if self.EventIds and #self.EventIds > 0 and self.EventIds[1] > 0 then
        eventDesc = XRoomSingleManager.GetEvenDesc(self.EventIds[1])
        self.TxtWeaknessDesc.text = eventDesc
        return
    end

    eventDesc = XRoomSingleManager.GetEventDescByMapId(self.CurrentStageId)
    if eventDesc then
        self.TxtWeaknessDesc.text = eventDesc
    else
        self.PanelWeakness.gameObject:SetActiveEx(false)
    end
end

function XUiNewRoomSingle:SetCondition()
    self.GridCondition.gameObject:SetActiveEx(false)

    local stageSuggestedConditionIds, stageForceConditionIds = XDataCenter.FubenManager.GetConditonByMapId(self.CurrentStageId)
    for _, value in pairs(stageSuggestedConditionIds) do
        table.insert(self.SuggestedConditionIds, value)
    end

    for _, value in pairs(stageForceConditionIds) do
        table.insert(self.ForceConditionIds, value)
    end

    for _, id in pairs(self.SuggestedConditionIds) do
        self:SetConditionGrid(id)
    end

    for _, id in pairs(self.ForceConditionIds) do
        self:SetConditionGrid(id)
    end
end

function XUiNewRoomSingle:SetConditionGrid(id)
    local item = CS.UnityEngine.Object.Instantiate(self.GridCondition)
    item.gameObject.transform:SetParent(self.PanelConditionContent, false)
    local textDesc = item.gameObject.transform:Find("TxtDesc"):GetComponent("Text")
    local _, desc = XConditionManager.CheckCondition(id, self.CurTeam.TeamData)
    textDesc.text = desc
    item.gameObject:SetActiveEx(true)
end

function XUiNewRoomSingle:RefreshCaptainSkill()
    -- 开启技能面板、队长头像、技能描述
    self.PanelSkill.gameObject:SetActiveEx(true)
    self.PanelRole.gameObject:SetActiveEx(true)
    self.TxtSkillDesc.gameObject:SetActiveEx(true)

    local teamMemberNum = self:GetCurTeamMemberNum()
    local captainId = self:GetCaptainIdByProxy()

    -- 获取机器人为RobotId，玩家角色为CharacterId的队伍数据
    -- 如果代理没有实现该接口，且队伍拥有没有使用RobotId的机器人，则无法获取机器人配置的时装与解放等级数据，队长头像会使用初始头像
    local realCharData = self:GetRealCharDataByProxy()
    if realCharData then
        captainId = realCharData[self.CurTeam.CaptainPos]
    end

    if captainId <= 0 then
        -- 当前队长位没有角色
        if teamMemberNum <= 0 then
            -- 队伍内没有角色，隐藏技能面板
            self.PanelSkill.gameObject:SetActiveEx(false)
        else
            -- 队伍内还有其他角色，隐藏队长头像与技能描述
            self.PanelRole.gameObject:SetActiveEx(false)
            self.TxtSkillDesc.gameObject:SetActiveEx(false)

            -- 队长技能名称更改为未选择队长
            self.TxtSkillName.text = CS.XTextManager.GetText("TeamDoNotChooseCaptain")
        end
        return
    end

    -- 获取队长技能信息
    local captianSkillInfo
    if not XRobotManager.CheckIsRobotId(captainId) then
        captianSkillInfo = XDataCenter.CharacterManager.GetCaptainSkillInfo(captainId)
    else
        captianSkillInfo = XRobotManager.GetRobotCaptainSkillInfo(captainId)
    end

    if captianSkillInfo == nil then
        return
    end

    -- 设置队长技能图标与名称
    self:SetUiSprite(self.ImgSkillIcon, captianSkillInfo.Icon)
    self.TxtSkillName.text = captianSkillInfo.Name

    -- 设置队长头像与队长技能描述
    local head
    local skillDesc
    if not XRobotManager.CheckIsRobotId(captainId) then
        if self.HasRobot or self.RogueLikeIsRobot then
            -- 使用了CharacterId的机器人
            skillDesc = captianSkillInfo.Intro
            -- 机器人使用了CharacterId，无法得知机器人的RobotId（获取终解等级与时装配置数据），使用初始头像代替
            head = XDataCenter.CharacterManager.GetCharSmallHeadIcon(captainId, true)
        else
            -- 玩家角色
            skillDesc = captianSkillInfo.Level > 0 and captianSkillInfo.Intro or CS.XTextManager.GetText("CaptainSkillLock")
            head = XDataCenter.CharacterManager.GetCharSmallHeadIcon(captainId)
        end
    else
        -- 使用了RobotId的机器人
        head = XRobotManager.GetRobotSmallHeadIcon(captainId)
        skillDesc = captianSkillInfo.Intro
    end
    if head then
        self.RImgCapIcon:SetRawImage(head)
    end
    if skillDesc then
        self.TxtSkillDesc.text = skillDesc
    end

end

function XUiNewRoomSingle:SetStageInfo()
    local chapterName, stageName = XDataCenter.FubenManager.GetFubenNames(self.CurrentStageId)
    self.TxtChapterName.text = chapterName
    self.TxtStageName.text = stageName
end

function XUiNewRoomSingle:InitEndurance()
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.Explore then
        if XDataCenter.FubenExploreManager.IsNodeFinish(XDataCenter.FubenExploreManager.GetCurChapterId(), XDataCenter.FubenExploreManager.GetCurNodeId()) then
            self.PanelEndurance.gameObject:SetActiveEx(false)
        else
            self.PanelEndurance.gameObject:SetActiveEx(true)
            self.TxtEnduranceNum.text = XDataCenter.FubenExploreManager.GetCurNodeEndurance()
        end
    else
        self.PanelEndurance.gameObject:SetActiveEx(false)
    end
end

--更新战斗信息
function XUiNewRoomSingle:InitCharacterInfo()
    self:UpdateTeamBuff()
    self:UpdatePartnerInfo()
    self:UpdateFeatureInfo()
    --机器人关卡不显示战斗信息
    if self.HasRobot or self:IsRogueLikeType() or self:IsUnionKillType() or self:IsNieRType() then
        self.BtnShowInfoToggle.gameObject:SetActiveEx(false)
        for i = 1, MAX_CHAR_COUNT do
            self["CharacterInfo" .. i].gameObject:SetActiveEx(false)
        end
        self:InitCharacterInfoByProxy()
        return
    end
    self.BtnShowInfoToggle.gameObject:SetActiveEx(true)
    self.IsShowCharacterInfo = 0
    local key = "NewRoomShowInfoToggle" .. tostring(XPlayer.Id)
    if CS.UnityEngine.PlayerPrefs.HasKey(key) then
        self.IsShowCharacterInfo = CS.UnityEngine.PlayerPrefs.GetInt(key)
    else
        CS.UnityEngine.PlayerPrefs.SetInt(key, 0)
    end
    self:InitCharacterInfoByProxy()
    self.PanelCombatPower = {}
    self.TxtCombatPower = {}
    self.ImgCombatPower = {}
    for i = 1, MAX_CHAR_COUNT do
        -- 位于角色右上方的战斗参数
        self.PanelCombatPower[i] = self["CharacterInfo" .. i]
        self.TxtCombatPower[i] = self["TxtFight" .. i]
        self.ImgCombatPower[i] = self["RImgType" .. i]
    end


    if self.IsShowCharacterInfo > 0 then

        self.BtnShowInfoToggle:SetButtonState(XUiButtonState.Select)
        for i = 1, #self.CurTeam.TeamData do
            if not XRobotManager.CheckIsRobotId(self.CurTeam.TeamData[i]) then
                local character = XDataCenter.CharacterManager.GetCharacter(self.CurTeam.TeamData[i])
                if character == nil then
                    self.PanelCombatPower[i].gameObject:SetActiveEx(false)
                else
                    self.PanelCombatPower[i].gameObject:SetActiveEx(true)
                    self.TxtCombatPower[i].text = math.floor(character.Ability)
                    self.ImgCombatPower[i]:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(character.Type))
                end
            elseif self.CurTeam.TeamData[i] > 0 then
                local robotId = self.CurTeam.TeamData[i]
                local robotData = XRobotManager.GetRobotTemplate(robotId)
                local detailConfig = XCharacterConfigs.GetCharDetailTemplate(robotData.CharacterId)
                local careerConfig = XCharacterConfigs.GetNpcTypeTemplate(detailConfig.Career)
                if robotData == nil then
                    self.PanelCombatPower[i].gameObject:SetActiveEx(false)
                else
                    self.PanelCombatPower[i].gameObject:SetActiveEx(true)
                    if self.Proxy and self.Proxy.GetCharAbility then
                        self.TxtCombatPower[i].text = self.Proxy.GetCharAbility(robotId)
                    else
                        self.TxtCombatPower[i].text = XRobotManager.GetRobotAbility(robotId)
                    end
                    self.ImgCombatPower[i]:SetRawImage(careerConfig.Icon)
                end
            else
                self.PanelCombatPower[i].gameObject:SetActiveEx(false)
            end
        end
    else
        self.BtnShowInfoToggle:SetButtonState(XUiButtonState.Normal)
        for i = 1, MAX_CHAR_COUNT do
            self.PanelCombatPower[i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiNewRoomSingle:DefaultUpdatePartnerInfo()
    if self.HasRobot or self:IsRogueLikeType() or self:IsUnionKillType() or self:IsNieRType() then
        for i = 1, MAX_CHAR_COUNT do
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.CurrentStageId)
            local robotId = stageCfg.RobotId[i]
            if robotId then
                local robotPartner = XRobotManager.GetRobotPartner(robotId)
                self:ShowPartner(self["CharacterPets" .. i], robotPartner, true)
            else
                self["CharacterPets" .. i].gameObject:SetActiveEx(false)
            end
        end
        return
    end

    self.PanelPartner = {}
    for i = 1, MAX_CHAR_COUNT do
        self.PanelPartner[i] = self["CharacterPets" .. i]
    end

    for i = 1, #self.CurTeam.TeamData do
        if not XRobotManager.CheckIsRobotId(self.CurTeam.TeamData[i]) then
            local character = XDataCenter.CharacterManager.GetCharacter(self.CurTeam.TeamData[i])
            if character == nil then
                self.PanelPartner[i].gameObject:SetActiveEx(false)
            else
                self.PanelPartner[i].gameObject:SetActiveEx(true)
                local partner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(character.Id)
                self:ShowPartner(self.PanelPartner[i], partner, false)
            end
        elseif self.CurTeam.TeamData[i] > 0 then
            local robotId = self.CurTeam.TeamData[i]
            local robotData = XRobotManager.GetRobotTemplate(robotId)
            local robotPartner = XRobotManager.GetRobotPartner(robotId)

            if robotData == nil then
                self.PanelPartner[i].gameObject:SetActiveEx(false)
            else
                self.PanelPartner[i].gameObject:SetActiveEx(true)
                self:ShowPartner(self.PanelPartner[i], robotPartner, true)
            end
        else
            self.PanelPartner[i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiNewRoomSingle:DefaultUpdateFeatureInfo()
    for i = 1, MAX_CHAR_COUNT do
        self["CharacterFeature" .. i].gameObject:SetActiveEx(false)
    end

    self.PanelStageFeature.gameObject:SetActiveEx(false)
end

function XUiNewRoomSingle:ShowPartner(panel, partner, IsRobot)
    if partner and next(partner) then
        panel:GetObject("RImgType"):SetRawImage(partner:GetIcon())
    end
    local IsHasPartner = partner and next(partner)
    panel:GetObject("RImgType").gameObject:SetActiveEx(IsHasPartner)
    panel.gameObject:SetActiveEx(IsHasPartner or (not IsRobot))
end

function XUiNewRoomSingle:OnBtnBackClick()
    self:Close()
end

function XUiNewRoomSingle:OnBtnMainUiClick()
    if self.Proxy and self.Proxy.HandleBtnMainUiClick then
        self.Proxy.HandleBtnMainUiClick()
        return
    else
        XLuaUiManager.RunMain()
    end
end

function XUiNewRoomSingle:HandleCharClick(charPos)
    if self:IsRogueLikeType() and self.RogueLikeIsRobot then
        self:OnRogueLikeChangeRole(charPos)
        return
    end
    if self:IsUnionKillType() then
        self:OnUnionKillChangeRole(charPos)
        return
    end

    local stageId = self.CurrentStageId

    -- 默认交给代理检查，否则目前单一检查是否为机器人
    if not self:CheckCharCanClickByProxy(stageId) then
        return
    end

    local teamData = XTool.Clone(self.CurTeam.TeamData)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)

    if self:IsChessPursuit() then
        XLuaUiManager.Open("UiRoomCharacter", teamData, charPos, function(resTeam)
            self:UpdateTeam(resTeam)
        end, stageInfo.Type, nil, {
            IsHideQuitButton = self.ChessPursuitData.SceneUiType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND,
            RobotIdList = self.ChessPursuitData.RobotList,
            MapId = self.ChessPursuitData.MapId,
            TeamGridIndex = self.ChessPursuitData.TeamGridIndex,
            SceneUiType = self.ChessPursuitData.SceneUiType,
        })
    elseif self:IsBabelTower() then
        self:OpenBabelRoomCharacter(teamData, charPos)
    elseif self:IsWorldBossType() then
        local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
        if worldBossActivity then
            local robotBuffIdList = worldBossActivity:GetGetedRobotIdList()
            local robotIdList = {}
            for _, buffId in pairs(robotBuffIdList) do
                local buffData = XDataCenter.WorldBossManager.GetWorldBossBuffById(buffId)
                table.insert(robotIdList, buffData:GetCustomizeId())
            end

            XLuaUiManager.Open("UiRoomCharacter", teamData, charPos, function(resTeam)
                self:UpdateTeam(resTeam)
            end, stageInfo.Type, nil, { RobotIdList = robotIdList })
        end
    elseif self:IsNieRType() then
        local robotList = XDataCenter.NieRManager.GetChapterCharacterList(self.Args[1], self.Args[2])
        XLuaUiManager.Open("UiSelectCharacterWin", function(resTeam)
            self:UpdateTeam(resTeam)
        end, UiSelectCharacterType.NieROnlyRobot, teamData, charPos, robotList)
    else
        self:HandleCharClickByProxy(charPos)
    end
end

-- 进入辅助机选择
function XUiNewRoomSingle:HandlePartnerClick(charPos)
    local stageId = self.CurrentStageId
    if not self:CheckCharCanClickByProxy(stageId) then return end

    self:HandlePartnerClickByProxy(charPos)
end

function XUiNewRoomSingle:OnBtnChar1Click()
    self:HandleCharClick(CHAR_POS1)
end

function XUiNewRoomSingle:OnBtnChar2Click()
    self:HandleCharClick(CHAR_POS2)
end

function XUiNewRoomSingle:OnBtnChar3Click()
    self:HandleCharClick(CHAR_POS3)
end

function XUiNewRoomSingle:GetTeamData()
    return self.CurTeam
end

-- 更新队伍
function XUiNewRoomSingle:UpdateTeam(teamData, isUsePrefab)
    for posId, val in pairs(teamData) do
        local oldCharId = self.CurTeam.TeamData[posId]
        if oldCharId and oldCharId > 0 and oldCharId ~= val then
            -- 检查被替换的位置是否有角色，并且不相同
            self.PanelCharacterInfo[posId].RoleModelPanel:HideRoleModel()
        end
    end

    self.CurTeam.TeamData = XTool.Clone(teamData)

    self:UpdateTeamByProxy()
    self:InitPanelTeam() -- 更新当前队伍显示状态

    if self:IsBabelTower() then
        local cb = self.BabelTowerData.Cb
        if cb then
            cb(teamData, self.CurTeam.CaptainPos, self.CurTeam.FirstFightPos)
        end
    elseif self:IsNieRType() then
        XDataCenter.NieRManager.SetPlayerTeamData(self.CurTeam, self.CurrentStageId)
    elseif self:IsChessPursuit() then
        XDataCenter.ChessPursuitManager.SetPlayerTeamData(self.CurTeam, self.ChessPursuitData.MapId, self.ChessPursuitData.TeamGridIndex, isUsePrefab)
    elseif self:GetIsSaveTeamData() then
        XDataCenter.TeamManager.SetPlayerTeam(self.CurTeam, false) -- 保存数据
    end
    --更新角色信息面板
    self:InitCharacterInfo()
end

function XUiNewRoomSingle:UpdateTeamBuff()
    local teamBuffId = self.TeamBuffId

    if not teamBuffId or teamBuffId <= 0 then
        self.PanelTeamBuff.gameObject:SetActiveEx(false)
        return
    end

    local maxCount = XFubenConfigs.GetTeamBuffMaxBuffCount(teamBuffId)
    if maxCount <= 0 then
        self.PanelTeamBuff.gameObject:SetActiveEx(false)
        return
    end

    self.PanelTeamBuff.gameObject:SetActiveEx(true)

    local fitCount = XFubenConfigs.GetTeamBuffFitCharacterCount(teamBuffId, self.CurTeam.TeamData)
    local isBuffOn = fitCount > 0
    self.PanelTeamBuffOn.gameObject:SetActiveEx(isBuffOn)
    self.PanelTeamBuffOff.gameObject:SetActiveEx(not isBuffOn)
    self.TxtTeamBuff.text = CSXTextManagerGetText("NewRoomSingleTeamBuffDes", fitCount, maxCount)
end

function XUiNewRoomSingle:UpdateTeamPrefab(team)
    -- 巴别塔特殊检查
    if self:IsBabelTower() then
        team = XDataCenter.FubenBabelTowerManager.FilterPrefabTeamData(self.CurrentStageId, self.BabelTowerData.TeamId, team)
        self.BabelTowerPanel:Refresh(team.TeamData)
    end
    self:OnClickTabCallBack(team.CaptainPos)
    self.PanelTabCaptain:SelectIndex(team.FirstFightPos)

    if self:IsUnionKillType() then
        self:UpdateUnionKillTeamCache(team.TeamData)
    end
    self:UpdateTeam(team.TeamData, true)
end

function XUiNewRoomSingle:PlayTips(key, isOn)
    local msg = CSXTextManagerGetText(key)
    self.TxtTips1.text = isOn and msg or ""
    self.TxtTips2.text = isOn and "" or msg
    self.PanelTip.gameObject:SetActiveEx(true)

    self:PlayAnimation("PanelTipEnable", handler(self, function()
        self.PanelTip.gameObject:SetActiveEx(false)
    end))
end

function XUiNewRoomSingle:CheckHasRobot()
    if self.HasRobot then
        local text = CSXTextManagerGetText("NewRoomSingleCannotSetRobot")
        XUiManager.TipError(text)
    end
    return self.HasRobot
end

function XUiNewRoomSingle:OnBtnEnterFightClick()
    -- 进战前检查
    if not self:CheckEnterFightByProxy() then
        return
    end

    -- 巴别塔进入战斗
    if self:IsBabelTower() then
        self:HandleEnterBabelTower()
        return
    end

    if self:GetIsCheckCaptainIdAndFirstFightId() then
        local captainId = self:GetTeamCaptainId()
        local firstFightId = self:GetTeamFirstFightId()
        -- 检查队长位与首发位是否为空
        if captainId == nil or captainId <= 0 then
            XUiManager.TipText("TeamManagerCheckCaptainNil")
            return
        end
        if firstFightId == nil or firstFightId <= 0 then
            XUiManager.TipText("TeamManagerCheckFirstFightNil")
            return
        end
    end

    if not XDataCenter.FubenManager.CheckFightConditionByTeamData(self.ForceConditionIds, self.CurTeam.TeamData) then
        return
    end

    if not self:CheckRoleStanmina() then
        return
    end

    local stage = XDataCenter.FubenManager.GetStageCfg(self.CurrentStageId)
    local isAssist = self:GetAssistStatus()

    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.Explore then
        XDataCenter.FubenExploreManager.SetCurTeam(self.CurTeam)
    end

    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.Daily then
        XDataCenter.FubenDailyManager.SetFubenDailyRecord(self.CurrentStageId)
    end

    -- 狙击战进入战斗相关
    if self:IsUnionKillType() then
        self:HandleEnterUnionKill(stage)
        return
    end

    -- 爬塔玩法出站人数必须为3人
    if self:IsRogueLikeType() then
        self:HandleEnterRogueLike(stage)
        return
    end

    --追击玩法
    if self:IsChessPursuit() then
        self:HandleSaveChessPursuit(stage)
        return
    end

    -- 世界boss进入战斗
    if self:IsWorldBossType() then
        self:HandleEnterWorldBoss(stage)
        return
    end

    -- 尼尔玩法进入战斗
    if self:IsNieRType() then
        self:HandleEnterNieR(stage)
        return
    end

    --跑团BOSS进入战斗
    if XTRPGConfigs.IsBossStage(self.CurrentStageId) then
        self:HandleEnterTRPGWorldBoss(stage)
        return
    end

    --杀戮无双进入战斗
    if self:IsKillZone() then
        self:HandleEnterKillZone(stage)
        return
    end

    --全服决战进入战斗
    if self:IsAreaWar() then
        self:HandleEnterAreaWar(stage)
        return
    end

    if self:IsActivityBossSingle() then
        self:HandleEnterActivityBossSingle(stage)
        return
    end

    if self:IsPracticeBoss() then
        self:HandleEnterPracticeBoss(stage)
        return
    end

    --特训关检查是否超时
    if self:IsSpecialTrain() then
        if XDataCenter.FubenSpecialTrainManager.CheckActivityTimeout(XDataCenter.FubenSpecialTrainManager.CurActiveId, true) then
            return
        end
    end

    --战力警告
    if self.FightControlResult == XUiFightControlState.Ex then
        local data = XFubenConfigs.GetStageFightControl(self.StageCfg.FightControlId)
        local contenttext
        --计算战力
        local teamAbility = {}
        for i = 1, #self.CurTeam.TeamData do
            local character = XDataCenter.CharacterManager.GetCharacter(self.CurTeam.TeamData[i])
            if character == nil then
                table.insert(teamAbility, 0)
            else
                table.insert(teamAbility, character.Ability)
            end
        end

        if data.MaxRecommendFight > 0 then
            contenttext = CSXTextManagerGetText("Insufficient", data.MaxShowFight)
        elseif data.AvgRecommendFight > 0 then
            local count = 0
            for _, v in pairs(teamAbility) do
                if v > 0 then
                    if v < data.AvgShowFight then
                        count = count + 1
                    end
                end
            end
            contenttext = CSXTextManagerGetText("AvgInsufficient", count, data.AvgShowFight)
        else
            contenttext = CSXTextManagerGetText("Insufficient", data.ShowFight)
        end

        local titletext = CSXTextManagerGetText("AbilityInsufficient")
        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.FubenManager.EnterFight(stage, self.CurTeam.TeamId, isAssist, self.ChallengeCount)
        end)
    else
        XDataCenter.FubenManager.EnterFight(stage, self.CurTeam.TeamId, isAssist, self.ChallengeCount, self.ChallengeId)
    end
end

function XUiNewRoomSingle:CheckRoleStanmina()
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.BossSingle then
        for i = 1, MAX_CHAR_COUNT do
            local posData = self.CurTeam.TeamData[i]
            if posData and posData > 0 then
                local curStamina = XDataCenter.FubenBossSingleManager.GetMaxStamina() - XDataCenter.FubenBossSingleManager.GetCharacterChallengeCount(posData)
                if curStamina <= 0 then
                    local charName = XCharacterConfigs.GetCharacterName(posData)
                    local text = CSXTextManagerGetText("BossSingleNoStamina", charName)
                    XUiManager.TipError(text)
                    return false
                end
            end
        end
    end

    return true
end

-- 获取当前队伍的角色数
function XUiNewRoomSingle:GetCurTeamMemberNum()
    local count = 0
    for _, id in pairs(self.CurTeam.TeamData) do
        if id > 0 then
            count = count + 1
        end
    end
    return count
end

--------------------------------------------------------------------------------------------------------------------------狙击战相关
function XUiNewRoomSingle:IsUnionKillType()
    return self.StageInfos.Type == XDataCenter.FubenManager.StageType.UnionKill
end

function XUiNewRoomSingle:UpdateTeamCaptionPos()
    local teamCache = XDataCenter.FubenUnionKillManager.GetCacheTeam()
    local captainPos = self.CurTeam.CaptainPos
    for i = 1, MAX_CHAR_COUNT do
        local memberInfo = teamCache[i]
        if memberInfo then
            memberInfo.IsTeamLeader = captainPos == i
        end
    end
end

-- 初始化阵容
function XUiNewRoomSingle:UnionKillInitTeam(curTeam)
    -- UiUnionKillTipCardShare
    --
    -- 显示共享角色
    --
    local fightData = XDataCenter.FubenUnionKillManager.GetCurRoomData()
    if fightData and fightData.UnionKillPlayerInfos and not fightData.IsShowShareCharacter then
        local shareInfos = {}
        for _, v in pairs(fightData.UnionKillPlayerInfos) do
            if v.Id ~= XPlayer.Id then
                table.insert(shareInfos, v.ShareNpcData)
            end
        end
        if #shareInfos > 0 then
            XLuaUiManager.Open("UiUnionKillTipCardShare", shareInfos)
        end
        fightData.IsShowShareCharacter = true
    end

    local isTrialBoss = XDataCenter.FubenUnionKillManager.IsTrialStage(self.CurrentStageId) and XDataCenter.FubenUnionKillManager.CurIsTrialBoss()
    local isUseShare = XDataCenter.FubenUnionKillManager.GetTrialUseShare()
    -- 是试炼关清掉共享角色
    if isTrialBoss and not isUseShare then
        local adjustCache = {}
        local shareTeamCache = XDataCenter.FubenUnionKillManager.GetCacheTeam()
        for i = 1, MAX_CHAR_COUNT do
            local characterInfo = shareTeamCache[i]
            if characterInfo and not characterInfo.IsShare then
                adjustCache[i] = {}
                adjustCache[i].CharacterId = characterInfo.CharacterId
                adjustCache[i].IsShare = false
                adjustCache[i].PlayerId = characterInfo.PlayerId
                adjustCache[i].IsTeamLeader = characterInfo.IsTeamLeader
            end
        end
        XDataCenter.FubenUnionKillManager.UpdateCacheTeam(adjustCache)
    end

    local unionTeam = XTool.Clone(curTeam)
    local teamCache = XDataCenter.FubenUnionKillManager.GetCacheTeam()
    unionTeam.CaptainPos = 1
    for i = 1, MAX_CHAR_COUNT do
        unionTeam.TeamData[i] = 0
        local characterInfo = teamCache[i]
        if characterInfo then
            unionTeam.TeamData[i] = characterInfo.CharacterId
            if characterInfo.IsTeamLeader then
                unionTeam.CaptainPos = i
            end
        end
    end

    curTeam = unionTeam
    return curTeam
end

-- 缓存阵容切换
function XUiNewRoomSingle:SwitchCacheTeam(changeIndex, targetIndex)
    local teamCache = XDataCenter.FubenUnionKillManager.GetCacheTeam()
    local temp = teamCache[changeIndex]
    teamCache[changeIndex] = teamCache[targetIndex]
    teamCache[targetIndex] = temp
    for i = 1, MAX_CHAR_COUNT do
        local characterInfo = teamCache[i]
        if characterInfo then
            characterInfo.IsTeamLeader = i == self.CurTeam.CaptainPos
        end
    end
end

-- 狙击战换人
function XUiNewRoomSingle:OnUnionKillChangeRole(index)

    local args = {}
    args.StageId = self.CurrentStageId
    args.DefaultSelectId = self.CurTeam.TeamData[index]
    args.Index = index
    args.CallBack = function(selectItem, isJoin)
        self:OnUnionKillSelectRole(index, selectItem, isJoin)
    end

    args.InTeamList = {}
    args.CharacterInTeamList = {}
    local teamCache = XDataCenter.FubenUnionKillManager.GetCacheTeam()
    for i = 1, MAX_CHAR_COUNT do
        if teamCache[i] then
            local characterId = teamCache[i].CharacterId
            local playerId = teamCache[i].PlayerId
            local key = string.format("%s_%s", tostring(playerId), tostring(characterId))
            args.InTeamList[key] = true
            args.CharacterInTeamList[tostring(characterId)] = true
        end
    end
    if teamCache[index] then
        args.DefaultSelectOwner = teamCache[index].PlayerId
    else
        args.DefaultSelectOwner = XPlayer.Id
    end

    -- 我的角色
    args.CharacterList = {}
    local ownCharacters = XDataCenter.CharacterManager.GetOwnCharacterList()
    for _, v in pairs(ownCharacters or {}) do
        table.insert(args.CharacterList, {
            Id = v.Id,
            OwnerId = XPlayer.Id,
            Flag = XFubenUnionKillConfigs.UnionKillCharType.Own,
            Ability = math.floor(v.Ability)
        })
    end

    -- 共享角色
    local unionFightRoomData = XDataCenter.FubenUnionKillManager.GetCurRoomData()
    local isTrialBoss = XDataCenter.FubenUnionKillManager.IsTrialStage(self.CurrentStageId) and XDataCenter.FubenUnionKillManager.CurIsTrialBoss()
    local isUseShare = XDataCenter.FubenUnionKillManager.GetTrialUseShare()
    local dontShare = isTrialBoss and not isUseShare
    if unionFightRoomData and not dontShare then
        for id, playerInfo in pairs(unionFightRoomData.UnionKillPlayerInfos or {}) do
            if id ~= XPlayer.Id then
                local character = playerInfo.ShareNpcData.Character
                table.insert(args.CharacterList, {
                    Id = character.Id,
                    OwnerId = id,
                    Flag = XFubenUnionKillConfigs.UnionKillCharType.Share,
                    OwnerInfo = playerInfo,
                    Ability = math.floor(character.Ability)
                })
            end
        end
    end

    XLuaUiManager.Open("UiUnionKillXuanRen", args)
end

function XUiNewRoomSingle:UpdateUnionKillTeamCache(teamData)
    local teamCache = XDataCenter.FubenUnionKillManager.GetCacheTeam()
    for i = 1, MAX_CHAR_COUNT do
        if teamData[i] and teamData[i] > 0 then
            teamCache[i] = {}
            teamCache[i].CharacterId = teamData[i]
            teamCache[i].IsShare = false
            teamCache[i].PlayerId = XPlayer.Id
            teamCache[i].IsTeamLeader = self.CurTeam.CaptainPos == i
        else
            teamCache[i] = nil
        end
    end
end

-- 选中角色
function XUiNewRoomSingle:OnUnionKillSelectRole(index, selectItem, isJoin)
    local teamCache = XDataCenter.FubenUnionKillManager.GetCacheTeam()
    if selectItem then
        if isJoin then
            local oldIndex
            local oldItem
            for i = 1, MAX_CHAR_COUNT do
                local cacheItem = teamCache[i]
                if cacheItem then
                    if selectItem.OwnerId == cacheItem.PlayerId and selectItem.Id == cacheItem.CharacterId and i ~= index then
                        oldIndex = i
                        oldItem = cacheItem
                        break
                    end
                end
            end
            if oldIndex and oldItem then
                teamCache[oldIndex] = teamCache[index]
            end
            teamCache[index] = {}
            teamCache[index].CharacterId = selectItem.Id
            teamCache[index].IsShare = selectItem.Flag == XFubenUnionKillConfigs.UnionKillCharType.Share
            teamCache[index].PlayerId = selectItem.OwnerId
            teamCache[index].IsTeamLeader = self.CurTeam.CaptainPos == index
            if selectItem.Flag == XFubenUnionKillConfigs.UnionKillCharType.Share then
                local unionFightRoomData = XDataCenter.FubenUnionKillManager.GetCurRoomData()
                if unionFightRoomData and unionFightRoomData.UnionKillPlayerInfos then
                    local playerInfo = unionFightRoomData.UnionKillPlayerInfos[selectItem.OwnerId]
                    if playerInfo then
                        teamCache[index].Character = playerInfo.ShareNpcData.Character
                    end
                end
            else
                teamCache[index].Character = nil
            end
        else
            teamCache[index] = nil
        end
    end

    -- 更新
    local teamData = {}
    for i = 1, MAX_CHAR_COUNT do
        if teamCache[i] then
            teamData[i] = teamCache[i].CharacterId
        else
            teamData[i] = 0
        end
    end
    self:UpdateTeam(teamData)
end

-- 更新狙击战模型
function XUiNewRoomSingle:UpdateUnionKillMode(roleModelPanel, pos, callback, defaultCharId)
    local teamCache = XDataCenter.FubenUnionKillManager.GetCacheTeam()
    local teamItem = teamCache[pos]
    if teamItem and teamItem.IsShare then
        local playerId = teamItem.PlayerId
        local fashionId
        local shareNpcData
        local unionFightRoomData = XDataCenter.FubenUnionKillManager.GetCurRoomData()
        if unionFightRoomData and unionFightRoomData.UnionKillPlayerInfos then
            local playerInfo = unionFightRoomData.UnionKillPlayerInfos[playerId]
            if playerInfo then
                fashionId = playerInfo.ShareNpcData.Character.FashionId
                shareNpcData = playerInfo.ShareNpcData
            end
        end

        local roleModelLoadedCb = function(model)
            if shareNpcData then
                roleModelPanel:UpdateEquipsModelsByFightNpcData(model, shareNpcData)
            end
        end

        roleModelPanel:UpdateCharacterModel(defaultCharId, nil, nil, roleModelLoadedCb, callback, fashionId)
    else
        local characterInfo = XDataCenter.CharacterManager.GetCharacter(teamItem.CharacterId)
        roleModelPanel:UpdateCharacterModel(defaultCharId, nil, nil, nil, callback, characterInfo.FashionId)
    end
end

-- 狙击战进入战斗
function XUiNewRoomSingle:HandleEnterUnionKill(stage)
    local teamCache = XDataCenter.FubenUnionKillManager.GetCacheTeam()
    XDataCenter.FubenManager.EnterUnionKillFight(stage, self.CurTeam, teamCache, function()
        -- 进入战斗请求后续处理
    end)
end

--------------------------------------------------------------------------------------------------------------------------爬塔活动相关
-- 初始化阵容
function XUiNewRoomSingle:RogueLikeInitTeam(curTeam)
    local rogueLikeTeam = XTool.Clone(curTeam)
    local characterInfos = XDataCenter.FubenRogueLikeManager.GetCharacterInfos()
    for i = 1, MAX_CHAR_COUNT do
        local characterInfo = characterInfos[i]
        if characterInfo then
            rogueLikeTeam.TeamData[characterInfo.TeamPos] = characterInfo.Id
            if characterInfo.Captain == 1 then
                rogueLikeTeam.CaptainPos = characterInfo.TeamPos
            end
            if characterInfo.FirstFight == 1 then
                rogueLikeTeam.FirstFightPos = characterInfo.TeamPos
            end
        else
            rogueLikeTeam.TeamData[i] = 0
        end
    end
    curTeam = rogueLikeTeam
    return curTeam
end


-- 爬塔活动玩法
function XUiNewRoomSingle:IsRogueLikeType()
    return self.StageInfos.Type == XDataCenter.FubenManager.StageType.RogueLike
end

function XUiNewRoomSingle:IsRogueLikeIsTiral()
    return XDataCenter.FubenRogueLikeManager.IsSectionPurgatory()
end

-- 特训关活动玩法
function XUiNewRoomSingle:IsSpecialTrain()
    return self.StageInfos.Type == XDataCenter.FubenManager.StageType.SpecialTrain
end

--追击玩法
function XUiNewRoomSingle:IsChessPursuit()
    return self.StageInfos.Type == XDataCenter.FubenManager.StageType.ChessPursuit
end

--世界boss玩法
function XUiNewRoomSingle:IsWorldBossType()
    return self.StageInfos.Type == XDataCenter.FubenManager.StageType.WorldBoss
end

--尼尔玩法
function XUiNewRoomSingle:IsNieRType()
    return self.StageInfos.Type == XDataCenter.FubenManager.StageType.NieR
end

--杀戮无双
function XUiNewRoomSingle:IsKillZone()
    return self.StageInfos.Type == XDataCenter.FubenManager.StageType.KillZone
end

--全服决战
function XUiNewRoomSingle:IsAreaWar()
    return self.StageInfos.Type == XDataCenter.FubenManager.StageType.AreaWar
end

--活动个人boss
function XUiNewRoomSingle:IsActivityBossSingle()
    return self.StageInfos.Type == XDataCenter.FubenManager.StageType.ActivityBossSingle
end

--拟真boss
function XUiNewRoomSingle:IsPracticeBoss()
    return self.StageInfos.Type == XDataCenter.FubenManager.StageType.PracticeBoss
end

-- 更换爬塔助战角色
function XUiNewRoomSingle:OnRogueLikeChangeRole(index)
    local currentActivityId = XDataCenter.FubenRogueLikeManager.GetRogueLikeActivityId()
    local activityTemplate = XFubenRogueLikeConfig.GetRougueLikeTemplateById(currentActivityId)
    local args = {}
    args.TeamSelectPos = index
    args.TeamCharIdMap = self.ChooseRobots
    args.Type = XFubenRogueLikeConfig.SelectCharacterType.Robot
    args.CharacterLimitType = activityTemplate.CharacterLimitType
    args.LimitBuffId = XFubenConfigs.GetLimitShowBuffId(activityTemplate.LimitBuffId)
    args.CallBack = function(selectId, isJoin, isReset)
        self:HandleSelectRobot(index, selectId, isJoin, isReset)
    end
    XLuaUiManager.Open("UiRogueLikeRoomCharacter", args)
end

-- 选完机器人回来
function XUiNewRoomSingle:HandleSelectRobot(index, selectRobot, isJoin, isReset)
    if isReset then
        self.ChooseRobots = {}
    end

    if isJoin then
        local oldIndex
        local oldRobot
        for k, v in pairs(self.ChooseRobots) do
            if k ~= index and v == selectRobot then
                oldIndex = k
                oldRobot = v
                break
            end
        end
        if oldIndex and oldRobot then
            self.ChooseRobots[oldIndex] = self.ChooseRobots[index]
            self.ChooseRobots[index] = selectRobot
        else
            self.ChooseRobots[index] = selectRobot
        end

    else
        self.ChooseRobots[index] = nil
    end
    -- 更新
    local teamData = {}
    for i = 1, MAX_CHAR_COUNT do
        local robotId = self.ChooseRobots[i]
        if robotId then
            local characterId = XRobotManager.GetCharacterId(robotId)
            teamData[i] = characterId
        else
            teamData[i] = 0
        end
    end
    self:UpdateTeam(teamData)
end

function XUiNewRoomSingle:GetRogueLikeFactionByCid(cid)
    local factionId
    for i = 1, MAX_CHAR_COUNT do
        local robotId = self.ChooseRobots[i]
        if robotId then
            local robotTemplate = XRobotManager.GetRobotTemplate(robotId)
            if robotTemplate and cid == robotTemplate.CharacterId then
                factionId = robotTemplate.FashionId
                break
            end

        end
    end
    return factionId
end

-- 爬塔活动切换助战角色
function XUiNewRoomSingle:OnBtnSwitchRoleClick()
    if not self:CanRogueLikeSwitchAssist() and not self.RogueLikeIsRobot then
        XUiManager.TipMsg(CSXTextManagerGetText("RogueLikeNeed3SupportChars"))
        return
    end
    self.RogueLikeIsRobot = not self.RogueLikeIsRobot
    if self.CurTeam then
        local teamData = {}
        self.PanelTeamLeader.gameObject:SetActiveEx(not self.RogueLikeIsRobot)
        self.PanelBtnLeader.gameObject:SetActiveEx(not self.RogueLikeIsRobot)
        if self.RogueLikeIsRobot then
            for i = 1, MAX_CHAR_COUNT do
                local robotId = self.ChooseRobots[i]
                if robotId then
                    local characterId = XRobotManager.GetCharacterId(robotId)
                    teamData[i] = characterId
                else
                    teamData[i] = 0
                end
            end

            -- 设置队长位与首发位为1
            self.CurTeam.CaptainPos = 1
            self.CurTeam.FirstFightPos = 1

            self:InitPanelTeam()
            self:SetRogueLikeRobotTips()
        else
            -- 获取NotifyRogueLikeData下发的参战列表，并检查是不是首发或者队长
            -- 切换队长与首发时，爬塔活动不保存阵容，只在开始战斗时保存阵容
            local characterInfos = XDataCenter.FubenRogueLikeManager.GetCharacterInfos()
            for i = 1, MAX_CHAR_COUNT do
                local characterInfo = characterInfos[i]
                if characterInfo then
                    teamData[characterInfo.TeamPos] = characterInfo.Id
                    if characterInfo.Captain == 1 then
                        self.CurTeam.CaptainPos = characterInfo.TeamPos
                        self:InitPanelTeam()
                    end

                    if characterInfo.FirstFight == 1 then
                        self.CurTeam.FirstFightPos = characterInfo.TeamPos
                        self:InitPanelTeam()
                    end
                else
                    teamData[i] = 0
                end
            end
            self:SetRogueLikeCharacterTips()
        end
        self:UpdateTeam(teamData)
        self:PlayAnimation("AnimEnable")
        self.BtnSwitchRole01.gameObject:SetActiveEx(not self.RogueLikeIsRobot)
        self.BtnSwitchRole02.gameObject:SetActiveEx(self.RogueLikeIsRobot)
    end
end

function XUiNewRoomSingle:SetSwitchRole()
    self.RogueLikeIsRobot = false
    self.BtnSwitchRole01.gameObject:SetActiveEx(not self.RogueLikeIsRobot and self:IsRogueLikeType() and not self:IsRogueLikeIsTiral())
    self.BtnSwitchRole02.gameObject:SetActiveEx(self.RogueLikeIsRobot and self:IsRogueLikeType() and not self:IsRogueLikeIsTiral())
    self.BtnSwitchRole01:SetDisable(not self:CanRogueLikeSwitchAssist())
    self.ChooseRobots = {}
    if #self.ChooseRobots < MAX_CHAR_COUNT then
        local robots = XDataCenter.FubenRogueLikeManager.GetAssistRobots()
        for i = 1, MAX_CHAR_COUNT do
            self.ChooseRobots[i] = robots[i] and robots[i].Id or nil
        end
    end

    local teamPrefabState = (self:IsRogueLikeType() or self:IsWorldBossType()) and XUiButtonState.Disable or XUiButtonState.Normal
    self.BtnTeamPrefab:SetButtonState(teamPrefabState)

    self:SetPanelRogueLikeByProxy()
end

function XUiNewRoomSingle:SetRogueLikeCharacterTips()
    if self.Proxy and self.Proxy.SetRogueLikeCharacterTips then
        return self.Proxy.SetRogueLikeCharacterTips(self)
    end

    local activityId = XDataCenter.FubenRogueLikeManager.GetRogueLikeActivityId()
    if not activityId then return end
    local activityTemplate = XFubenRogueLikeConfig.GetRougueLikeTemplateById(activityId)
    if not activityTemplate then return end
    self.PanelEnduranceRogueLike.gameObject:SetActiveEx(not self:IsRogueLikeIsTiral())
    self.TxtActionPointNum.text = CSXTextManagerGetText("RogueLikeCostAction", activityTemplate.FightNeedPoint)
    self.TxtTeamMemberCount.text = CSXTextManagerGetText("RogueLikeTeamNeedCount", XDataCenter.FubenRogueLikeManager:GetTeamMemberCount())
end

function XUiNewRoomSingle:SetRogueLikeRobotTips()
    --self.PanelEnduranceRogueLike.gameObject:SetActiveEx(false)
    local activityId = XDataCenter.FubenRogueLikeManager.GetRogueLikeActivityId()
    if not activityId then return end
    local activityTemplate = XFubenRogueLikeConfig.GetRougueLikeTemplateById(activityId)
    if not activityTemplate then return end
    self.TxtActionPointNum.text = CSXTextManagerGetText("RogueLikeCostAction", activityTemplate.FightNeedPoint) --CSXTextManagerGetText("RogueLikeNotCostAction")
    self.TxtTeamMemberCount.text = CSXTextManagerGetText("RogueLikeDefaultSupportChar")
end

-- 是否为爬塔并且不可以切换上阵角色
function XUiNewRoomSingle:IsRogueLikeLockCharacter()
    return self:IsRogueLikeType() and XDataCenter.FubenRogueLikeManager.IsRogueLikeCharacterLock()
end

-- 是否为爬塔并且可以切换为助战角色
function XUiNewRoomSingle:CanRogueLikeSwitchAssist()
    return self:IsRogueLikeType() and XDataCenter.FubenRogueLikeManager.CanSwitch2Assist()
end

-- 爬塔进入战斗并保存阵容
function XUiNewRoomSingle:HandleEnterRogueLike(stage)
    local curTeamMemberCount = 0
    local isAssist = self.RogueLikeIsRobot and 1 or 0
    for i = 1, #self.CurTeam.TeamData do
        if self.CurTeam.TeamData[i] > 0 then
            curTeamMemberCount = curTeamMemberCount + 1
        end
    end
    if XDataCenter.FubenRogueLikeManager.GetTeamMemberCount() > curTeamMemberCount then
        XUiManager.TipMsg(CSXTextManagerGetText("RogueLikeTeamMaxMember"))
        return
    end

    XDataCenter.FubenRogueLikeManager.UpdateRogueLikeStageRobots(self.CurrentStageId, isAssist, self.ChooseRobots)

    -- function参数是PreFightRequest协议返回之后的回调函数
    XDataCenter.FubenManager.EnterRogueLikeFight(stage, self.CurTeam, isAssist, self.NodeId, function()
        for _, robotId in pairs(self.ChooseRobots or {}) do
            XDataCenter.FubenRogueLikeManager.UpdateNewRobots(robotId)
        end
        -- 非机器人
        -- 更新位置、队长位置、首发位置
        if not self.RogueLikeIsRobot then
            local id2Index = {}
            local characterInfos = XDataCenter.FubenRogueLikeManager.GetCharacterInfos()
            for i = 1, #self.CurTeam.TeamData do
                id2Index[self.CurTeam.TeamData[i]] = i
            end
            for i = 1, #characterInfos do
                local characterInfo = characterInfos[i]
                local characterId = characterInfo.Id
                characterInfo.TeamPos = id2Index[characterId]
                characterInfo.Captain = (self.CurTeam.CaptainPos == id2Index[characterId]) and 1 or 0
                characterInfo.FirstFight = (self.CurTeam.FirstFightPos == id2Index[characterId]) and 1 or 0
            end
        end
    end)
end

function XUiNewRoomSingle:HandleSaveChessPursuit(stage)
    if self.CurTeam.TeamData[self.CurTeam.CaptainPos] == nil or self.CurTeam.TeamData[self.CurTeam.CaptainPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    if self.CurTeam.TeamData[self.CurTeam.FirstFightPos] == nil or self.CurTeam.TeamData[self.CurTeam.FirstFightPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end

    if self.ChessPursuitData.SceneUiType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND then
        XDataCenter.ChessPursuitManager.RequestChessPursuitChangeTeam(self.ChessPursuitData.TeamGridIndex)
    else
        XDataCenter.ChessPursuitManager.SaveTempTeamData(self.ChessPursuitData.MapId)
    end

    self:Close()
end

-- 世界boss进入战斗,检查队长位与首发位是否为空
function XUiNewRoomSingle:HandleEnterWorldBoss(stage)
    if self.CurTeam.TeamData[self.CurTeam.CaptainPos] == nil or self.CurTeam.TeamData[self.CurTeam.CaptainPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    if self.CurTeam.TeamData[self.CurTeam.FirstFightPos] == nil or self.CurTeam.TeamData[self.CurTeam.FirstFightPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end
    local stageLevel = XDataCenter.WorldBossManager.GetBossStageLevel()
    XDataCenter.FubenManager.EnterWorldBossFight(stage, self.CurTeam, stageLevel)
end

-- 尼尔玩法进入战斗,检查队长位与首发位是否为空
function XUiNewRoomSingle:HandleEnterNieR(stage)
    if self.CurTeam.TeamData[self.CurTeam.CaptainPos] == nil or self.CurTeam.TeamData[self.CurTeam.CaptainPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    if self.CurTeam.TeamData[self.CurTeam.FirstFightPos] == nil or self.CurTeam.TeamData[self.CurTeam.FirstFightPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end
    XDataCenter.FubenManager.EnterNieRFight(stage, self.CurTeam)
end

-- 跑团世界boss进入战斗,检查队长位与首发位是否为空
function XUiNewRoomSingle:HandleEnterTRPGWorldBoss(stage)
    if self.CurTeam.TeamData[self.CurTeam.CaptainPos] == nil or self.CurTeam.TeamData[self.CurTeam.CaptainPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    if self.CurTeam.TeamData[self.CurTeam.FirstFightPos] == nil or self.CurTeam.TeamData[self.CurTeam.FirstFightPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end
    XDataCenter.FubenManager.EnterTRPGWorldBossFight(stage, self.CurTeam)
end

function XUiNewRoomSingle:HandleEnterKillZone(stage)
    if self.CurTeam.TeamData[self.CurTeam.CaptainPos] == nil or self.CurTeam.TeamData[self.CurTeam.CaptainPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    if self.CurTeam.TeamData[self.CurTeam.FirstFightPos] == nil or self.CurTeam.TeamData[self.CurTeam.FirstFightPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end
    XDataCenter.FubenManager.EnterKillZoneFight(stage, self.CurTeam)
end

function XUiNewRoomSingle:HandleEnterAreaWar(stage)
    if self.CurTeam.TeamData[self.CurTeam.CaptainPos] == nil or self.CurTeam.TeamData[self.CurTeam.CaptainPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    if self.CurTeam.TeamData[self.CurTeam.FirstFightPos] == nil or self.CurTeam.TeamData[self.CurTeam.FirstFightPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end
    XDataCenter.FubenManager.EnterStageWithRobot(stage, self.CurTeam)
end

function XUiNewRoomSingle:HandleEnterActivityBossSingle(stage)
    if self.CurTeam.TeamData[self.CurTeam.CaptainPos] == nil or self.CurTeam.TeamData[self.CurTeam.CaptainPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    if self.CurTeam.TeamData[self.CurTeam.FirstFightPos] == nil or self.CurTeam.TeamData[self.CurTeam.FirstFightPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end
    XDataCenter.FubenManager.EnterStageWithRobot(stage, self.CurTeam)
end

function XUiNewRoomSingle:HandleEnterPracticeBoss(stage)
    if self.CurTeam.TeamData[self.CurTeam.CaptainPos] == nil or self.CurTeam.TeamData[self.CurTeam.CaptainPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    if self.CurTeam.TeamData[self.CurTeam.FirstFightPos] == nil or self.CurTeam.TeamData[self.CurTeam.FirstFightPos] <= 0 then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end
    XDataCenter.FubenManager.EnterPracticeBoss(stage, self.CurTeam, self.SimulateTrainInfo)
end

function XUiNewRoomSingle:GetCharacterLimitType()
    if self:IsRogueLikeType() then
        local currentActivityId = XDataCenter.FubenRogueLikeManager.GetRogueLikeActivityId()
        local activityTemplate = XFubenRogueLikeConfig.GetRougueLikeTemplateById(currentActivityId)
        return activityTemplate.CharacterLimitType
    end

    local stageId = self.CurrentStageId
    return stageId and XFubenConfigs.GetStageCharacterLimitType(stageId)
end

function XUiNewRoomSingle:OnClickBtnTeamBuff()
    XLuaUiManager.Open("UiRoomTeamBuff", self.TeamBuffId)
end

function XUiNewRoomSingle:InitWorldBoss()
    if not self:IsWorldBossType() then return end
    self.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

function XUiNewRoomSingle:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET }
end

function XUiNewRoomSingle:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        self:OnResetEvent(args[1])
    end
end

function XUiNewRoomSingle:IsBabelTower()
    return self.StageInfos.Type == XDataCenter.FubenManager.StageType.BabelTower
end

function XUiNewRoomSingle:InitPanelBabelTower()
    if not self:IsBabelTower() then
        self.PanelBabel.gameObject:SetActiveEx(false)
        return
    end
    self.PanelBabel.gameObject:SetActiveEx(true)
    -- local maxTeamMemberCount = XDataCenter.FubenBabelTowerManager.GetMaxTeamMemberCount()
    -- self.BtnTeamPrefab.gameObject:SetActiveEx(maxTeamMemberCount >= 3)
    self.BtnTeamPrefab.gameObject:SetActiveEx(false)

    self.BabelTowerPanel = XUiPanelBabelTower.New(self.PanelBabel, self.CurrentStageId, self.CurTeam.TeamData)
    self.BtnEnterFight:SetNameByGroup(0, CSXTextManagerGetText("BabelTowerNewRoomBtnName"))
end

function XUiNewRoomSingle:InitChessPursuit()
    if not self:IsChessPursuit() then
        return
    end

    self.BtnTeamPrefab.gameObject:SetActiveEx(self.ChessPursuitData.SceneUiType == XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN and not XUiManager.IsHideFunc)
    self.BtnEnterFight:SetNameByGroup(0, CSXTextManagerGetText("ChessPursuitBuZhenEnter"))
end

function XUiNewRoomSingle:OpenBabelRoomCharacter(teamData, charPos)
    local args = {}
    args.StageId = self.CurrentStageId
    args.TeamId = self.BabelTowerData.TeamId
    args.Index = charPos
    args.CurTeamList = teamData
    args.CharacterLimitType = XFubenConfigs.GetStageCharacterLimitType(self.CurrentStageId)
    args.LimitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(self.CurrentStageId)
    XLuaUiManager.Open("UiBabelTowerRoomCharacter", args, function(resTeam)
        self:UpdateTeam(resTeam)
        self.BabelTowerPanel:Refresh(resTeam)
    end)
end

-- 巴别塔进入战斗,检查队长位与首发位是否为空
function XUiNewRoomSingle:HandleEnterBabelTower()
    local captainPos = self.CurTeam.CaptainPos
    local firstFightPos = self.CurTeam.FirstFightPos
    local team = self.CurTeam.TeamData

    local captainId = team[captainPos]
    if captainId == nil or captainId <= 0 then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end

    local firFightId = team[firstFightPos]
    if firFightId == nil or firFightId <= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("TeamManagerCheckFirstFightNil"))
        return
    end

    local closeCb = self.BabelTowerData.CloseCb
    if closeCb then
        XLuaUiManager.Remove("UiNewRoomSingle")
        closeCb(team, captainPos, firstFightPos)
    else
        self:Close()
    end
end

function XUiNewRoomSingle:InitPanelNieR()
    if not self:IsNieRType() then
        return
    end
    self.BtnTeamPrefab.gameObject:SetActiveEx(false)
    self.PanelCharacterLimit.gameObject:SetActiveEx(false)
    self:ShowAssistToggle(false)
end


function XUiNewRoomSingle:GetLivWarRaceData()
    return self.LivWarRaceData
end
--============================================================
--                         页面代理方法
--           详情参考XUiNewRoomSingleProxy，注册页面代理
--============================================================
--================
--初始化界面
--================
function XUiNewRoomSingle:InitProxyPanel()
    if not self.Proxy then return end
    if self.Proxy.InitEditBattleUi then self.Proxy.InitEditBattleUi(self) end
end

--================
--显示资料处理
--================
function XUiNewRoomSingle:OnBtnShowInfoToggleByProxy(val)
    if (not self.Proxy) or (not self.Proxy.OnBtnShowInfoToggle) then
        self:OnBtnShowInfoToggle(val)
    else
        self.Proxy.OnBtnShowInfoToggle(self, val)
    end
end
--================
--刷新成员信息处理
--================
function XUiNewRoomSingle:InitCharacterInfoByProxy()
    if (not self.Proxy) or (not self.Proxy.InitEditBattleUiCharacterInfo) then
        self:RefreshCharacterTypeTips()
        return
    end
    self.Proxy.InitEditBattleUiCharacterInfo(self)
end
--================
--保存玩法出战队伍操作，更改队长位和首发位时触发
--================
function XUiNewRoomSingle:SetTeamByProxy()
    if not self.Proxy then
        -- 不保存阵容
        if not self:IsRogueLikeType()
        and not self:IsUnionKillType()
        and not self:IsBabelTower()
        and not self:IsWorldBossType()
        and not self:IsChessPursuit()
        and not self:IsNieRType() then
            XDataCenter.TeamManager.SetPlayerTeam(self.CurTeam, false)
        end
        return
    end

    if self.Proxy.SetPlayerTeam then
        self.Proxy.SetPlayerTeam(self.CurTeam)
    end

    if self.Proxy.SetEditBattleUiTeam then
        self.Proxy.SetEditBattleUiTeam(self)
    elseif self.Proxy.UpdateTeam then
        self.Proxy.UpdateTeam(self)
    end
end

--================
--获取队长ID
--================
function XUiNewRoomSingle:GetCaptainIdByProxy()
    if (not self.Proxy) or (not self.Proxy.GetEditBattleUiCaptainId) then
        return self.CurTeam.TeamData[self.CurTeam.CaptainPos]
    end
    return self.Proxy.GetEditBattleUiCaptainId(self)
end

--================
--获取队伍数据
--================
function XUiNewRoomSingle:GetTeamByProxy()
    if not self.Proxy then return nil end
    if self.Proxy.GetBattleTeamData then
        return self.Proxy.GetBattleTeamData(self)
    end
    return nil
end

--=========================================
--获取队伍的角色Id
--与CurTeam不同，它主要用于区分机器人与玩家角色
--在CurTeam中，有些机器人用了CharacterId而不是RobotId，无法获得得到机器人配置数据
--
--所以如果玩法中有机器人，并且CurTeam使用了CharacterId，则代理需要实现接口返回机器人的robotId，玩家角色则不变
--不然机器人会使用玩家数据或者默认数据
--
--返回的数据结构与TeamData一致，索引1为中间，2为左边，3为右边
--机器人是robotId，玩家角色是characterId
--=========================================
function XUiNewRoomSingle:GetRealCharDataByProxy()
    if not self.Proxy then
        return nil
    end
    if self.Proxy.GetRealCharData then
        return self.Proxy.GetRealCharData(self, self.CurrentStageId)
    end
    return nil
end

--================
--当点击角色模型时
--================
function XUiNewRoomSingle:HandleCharClickByProxy(charPos)
    if (not self.Proxy) or (not self.Proxy.HandleCharClick) then
        local teamData = XTool.Clone(self.CurTeam.TeamData)
        local stageId = self.CurrentStageId
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local characterLimitType = self:GetCharacterLimitType()
        XLuaUiManager.Open("UiRoomCharacter", teamData, charPos,
        function(resTeam)
            self:UpdateTeam(resTeam)
        end,
        stageInfo.Type,
        characterLimitType,
        {
            LimitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(stageId),
            ChallengeId = self.ChallengeId,
            TeamBuffId = self.TeamBuffId,
        })
        return
    end
    self.Proxy.HandleCharClick(self, charPos, self.CurrentStageId)
end

--================
--当点击角色辅助机时
--================
function XUiNewRoomSingle:HandlePartnerClickByProxy(charPos)
    if (not self.Proxy) or (not self.Proxy.HandlePartnerClick) then
        self:HandleCharClick(charPos)
        return
    end
    self.Proxy.HandlePartnerClick(self, charPos, self.CurrentStageId)
end

--================
--刷新警告面板
--================
function XUiNewRoomSingle:InitFightControl()
    if not self.FightControl then
        self.FightControl = XUiNewRoomFightControl.New(self.PanelNewRoomFightControl)
    end
    if (not self.Proxy) or (not self.Proxy.UpdateFightControl) then
        self:UpdateFightControl()
    else
        self.FightControlResult = self.Proxy.UpdateFightControl(self, self.CurTeam)
    end
end

--================
--刷新队伍，编队角色或编队顺序发生变化时触发
--================
function XUiNewRoomSingle:UpdateTeamByProxy()
    if (not self.Proxy) or (not self.Proxy.UpdateTeam) then
        return
    end
    self.Proxy.UpdateTeam(self)
end

--================
--刷新模型
--================
function XUiNewRoomSingle:UpdateRoleModelByProxy(charId, roleModelPanel, pos)
    if (not self.Proxy) or (not self.Proxy.UpdateRoleModel) then
        self:UpdateRoleModel(charId, roleModelPanel, pos)
        return
    end
    self.Proxy.UpdateRoleModel(self, charId, roleModelPanel, pos)
end

--================
--接受到活动重置或结束消息时
--================
function XUiNewRoomSingle:OnResetEvent(stageType)
    if self.StageInfos.Type ~= stageType then return end
    if self.Proxy.OnResetEvent then self.Proxy.OnResetEvent(self) end
end

--================
--筛选角色
--================
function XUiNewRoomSingle:LimitCharacterByProxy(curTeam)
    if (not self.Proxy) or (not self.Proxy.LimitCharacter) then
        return
    end
    self.Proxy.LimitCharacter(self, curTeam)
end

function XUiNewRoomSingle:GetRobotIdsByProxy(stageId)
    if self.Proxy and self.Proxy.GetRobotIds then
        return self.Proxy.GetRobotIds(stageId)
    end
    return XDataCenter.FubenManager.GetStageCfg(stageId).RobotId
end

function XUiNewRoomSingle:CheckCharCanLongClickByProxy(stageId)
    if self.Proxy and self.Proxy.CheckCanCharLongClick then
        return self.Proxy.CheckCanCharLongClick(self, stageId)
    end
    return true
end

function XUiNewRoomSingle:CheckCharCanClickByProxy(stageId)
    if self.Proxy and self.Proxy.CheckCanCharClick then
        return self.Proxy.CheckCanCharClick(self, stageId)
    end
    return not self:CheckHasRobot()
end

-- 获取是否隐藏切换第一次战斗位置按钮信息（红色，蓝色，黄色）
function XUiNewRoomSingle:GetIsHideSwitchFirstFightPosBtnsWithProxy()
    if self.Proxy and self.Proxy.GetIsHideSwitchFirstFightPosBtns then
        return self.Proxy.GetIsHideSwitchFirstFightPosBtns()
    end
    return self.HasRobot
end
--================
--销毁窗口时
--================
function XUiNewRoomSingle:DestroyNewRoomSingle()
    if (not self.Proxy) or (not self.Proxy.DestroyNewRoomSingle) then
        return
    end
    self.Proxy.DestroyNewRoomSingle(self)
end
--================
--更新伙伴信息
--================
function XUiNewRoomSingle:UpdatePartnerInfo()
    if (not self.Proxy) or (not self.Proxy.UpdatePartnerInfo) then
        self:DefaultUpdatePartnerInfo()
        return
    end
    self.Proxy.UpdatePartnerInfo(self, MAX_CHAR_COUNT)
end

--================
--更新人物特性信息
--================
function XUiNewRoomSingle:UpdateFeatureInfo()
    if (not self.Proxy) or (not self.Proxy.UpdateFeatureInfo) then
        self:DefaultUpdateFeatureInfo()
        return
    end
    self.Proxy.UpdateFeatureInfo(self, MAX_CHAR_COUNT)
end

--================
--进战前检查
--================
function XUiNewRoomSingle:CheckEnterFightByProxy()
    if (not self.Proxy) or (not self.Proxy.CheckEnterFight) then
        return true
    end
    return self.Proxy.CheckEnterFight(self, self.CurTeam)
end

function XUiNewRoomSingle:GetIsSaveTeamData()
    if self.Proxy and self.Proxy.GetIsSaveTeamData then
        return self.Proxy.GetIsSaveTeamData()
    end
    return not self:IsRogueLikeType() and not self:IsUnionKillType() and not self:IsWorldBossType()
end

function XUiNewRoomSingle:HandleSwitchTeamPosWithProxy(fromPos, toPos)
    if self.Proxy and self.Proxy.SwitchTeamPos then
        self.Proxy.SwitchTeamPos(self.CurrentStageId, fromPos, toPos)
    end
end

function XUiNewRoomSingle:SetFirstFightPosWithProxy(index)
    if self.Proxy and self.Proxy.SetFirstFightPos then
        self.Proxy.SetFirstFightPos(self.CurrentStageId, index)
    end
end

function XUiNewRoomSingle:SetCaptainPosWithProxy(index)
    if self.Proxy and self.Proxy.SetCaptainPos then
        self.Proxy.SetCaptainPos(self.CurrentStageId, index)
    end
end

function XUiNewRoomSingle:GetFirstFightPos()
    if self.Proxy and self.Proxy.GetFirstFightPos then
        return self.Proxy.GetFirstFightPos(self.CurrentStageId)
    end
    return CHAR_POS1
end

function XUiNewRoomSingle:GetCaptainPos()
    if self.Proxy and self.Proxy.GetCaptainPos then
        return self.Proxy.GetCaptainPos(self.CurrentStageId)
    end
    return CHAR_POS1
end

function XUiNewRoomSingle:GetTeamCaptainId()
    if self.Proxy and self.Proxy.GetTeamCaptainId then
        return self.Proxy.GetTeamCaptainId(self.CurrentStageId)
    end
    return XDataCenter.TeamManager.GetTeamCaptainId(self.CurTeam.TeamId)
end

function XUiNewRoomSingle:GetTeamFirstFightId()
    if self.Proxy and self.Proxy.GetTeamFirstFightId then
        return self.Proxy.GetTeamFirstFightId(self.CurrentStageId)
    end
    return XDataCenter.TeamManager.GetTeamFirstFightId(self.CurTeam.TeamId)
end

function XUiNewRoomSingle:GetIsCheckCaptainIdAndFirstFightId()
    if self.Proxy and self.Proxy.GetIsCheckCaptainIdAndFirstFightId then
        return self.Proxy.GetIsCheckCaptainIdAndFirstFightId(self.CurrentStageId)
    end
    return not self:IsWorldBossType()
    and not self.HasRobot
    and (not self:IsRogueLikeType())
    and (not self:IsUnionKillType())
    and (not self:IsChessPursuit())
    and (not self:IsNieRType())
end

function XUiNewRoomSingle:GetAutoCloseInfo()
    if self.Proxy and self.Proxy.GetAutoCloseInfo then
        return self.Proxy.GetAutoCloseInfo(self.StageCfg)
    end
    return false
end

--================
--左下红底的出战人数说明
--================
function XUiNewRoomSingle:SetPanelRogueLikeByProxy()
    if self.Proxy and self.Proxy.SetPanelRogueLike then
        return self.Proxy.SetPanelRogueLike(self)
    end

    if self.PanelRogueLike then
        self.PanelRogueLike.gameObject:SetActiveEx(self:IsRogueLikeType())
        if self.RogueLikeIsRobot then
            self:SetRogueLikeRobotTips()
        else
            self:SetRogueLikeCharacterTips()
        end
    end
end