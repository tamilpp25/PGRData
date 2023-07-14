local CsXTextManager = CS.XTextManager
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiBattleRoleRoom = XLuaUiManager.Register(XLuaUi, "UiBattleRoleRoom")
local MAX_ROLE_COUNT = 3
local LONG_TIMER = 1
--[[
    基本描述：通用编队界面，支持所有类型角色编队（XCharacter, XRobot, 其他自定义实体）
    参数说明：stageId : Stage表的Id
             team : XTeam 队伍数据，可通过XTeamManager相关接口获取对应的队伍或自己系统创建的队伍
             proxy : 代理定义，必须传入继承自XUiBattleRoleRoomDefaultProxy的类定义或传入匿名类(如下)
                -- 偷懒的一种写法，来源于1.只想实现一个接口而不想创建整个文件 2.修正旧编队界面带来的耦合逻辑写法
                匿名类：{
                    -- proxy : 等同于self, 属于代理实例, 是匿名类重写的接口的第一个参数
                    GetRoleAbility = function(proxy, entityId)
                        -- eg : 根据id处理自己的角色战力
                    end
                }
            challengeCount : 挑战次数
    使用规则：1.可参考XUiBattleRoleRoomDefaultProxy文件去重写自己玩法需要的接口，接口已基本写明注释，或查询该文件看相关实现
             2.当前页面增加功能时，如果不是通用编队的功能或不是所有玩法大概率能够使用的功能尽量不要直接加，可通过AOP接口切上下去加自己的功能
             3.可任意追加AOP接口，比如AOPOnStartBefore，AOPOnStartAfter，只切上下面去处理自己的逻辑
]]
function XUiBattleRoleRoom:OnAwake()
    -- 重定义 begin
    self.FirstEnterBtnGroup = self.PanelTabCaptain
    self.PanelFirstEnterTag1 = self.PanelFirstRole1
    self.PanelFirstEnterTag2 = self.PanelFirstRole2
    self.PanelFirstEnterTag3 = self.PanelFirstRole3
    self.UiObjPartner1 = self.CharacterPets1
    self.UiObjPartner2 = self.CharacterPets2
    self.UiObjPartner3 = self.CharacterPets3
    self.UiPointerCharacter1 = self.BtnChar1:GetComponent("XUiPointer")
    self.UiPointerCharacter2 = self.BtnChar2:GetComponent("XUiPointer")
    self.UiPointerCharacter3 = self.BtnChar3:GetComponent("XUiPointer")
    self.PanelRightTopTip = self.PanelTip
    self.TxtRightTopTip = self.TxtTips1
    self.FightControlGo = self.PanelNewRoomFightControl
    -- 重定义 end
    self.FubenManager = XDataCenter.FubenManager
    self.TeamManager = XDataCenter.TeamManager
    self.FavorabilityManager = XDataCenter.FavorabilityManager
    -- XTeam
    self.Team = nil
    self.StageId = nil
    self.Proxy = nil
    self.ChallengeCount = nil
    self.UiPanelRoleModels = nil
    self.LongClickTime = 0
    self.Camera = nil
    self.ChildPanelData = nil
    -- XUiNewRoomFightControl
    self.FightControl = nil
    self:InitUiPanelRoleModels()
    self:RegisterUiEvents()
    self:RegisterListeners()
end

-- team : XTeam, 不传的话默认使用主线队伍, 如果是旧系统改过来，可以参考下XTeamManager后面新加的接口去处理旧队伍数据
-- challengeCount : number, 挑战次数
function XUiBattleRoleRoom:OnStart(stageId, team, proxy, challengeCount, isReadArgsByCacheWithAgain)
    if isReadArgsByCacheWithAgain == nil then isReadArgsByCacheWithAgain = false end
    self.Camera = self.Transform:GetComponent("Canvas").worldCamera
    local stageConfig = self.FubenManager.GetStageCfg(stageId)
    -- 判断是否有重复挑战
    if XRoomSingleManager.AgainBtnType[stageConfig.FunctionLeftBtn] 
        or XRoomSingleManager.AgainBtnType[stageConfig.FunctionRightBtn] then
        XUiBattleRoleRoom.__StageId2ArgData = XUiBattleRoleRoom.__StageId2ArgData or {}
        local argData = XUiBattleRoleRoom.__StageId2ArgData[stageId]
        if isReadArgsByCacheWithAgain and argData then
            team = argData.Team
            proxy = argData.proxy
            challengeCount = argData.challengeCount
        end
        XUiBattleRoleRoom.__StageId2ArgData[stageId] = {
            stageId = stageId,
            team = team,
            proxy = proxy,
            challengeCount = challengeCount
        }
    end
    local robotIds = stageConfig.RobotId
    if #robotIds > 0 then -- 说明要使用机器人，默认抛弃传入的队伍和代理
        -- 去掉队伍是因为已经用不到原队伍，强制使用配置的机器人
        team = nil 
    end
    -- 若队伍为空，优先根据关卡固定机器人，其次读取默认主线队伍
    if team == nil then
        if #robotIds > 0 then
            team = self.TeamManager.CreateTempTeam(XTool.Clone(robotIds))
        else
            team = self.TeamManager.GetMainLineTeam()
        end
    end
    if challengeCount == nil then challengeCount = 1 end
    self.Team = team
    self.StageId = stageId
    local proxyInstance = nil -- 代理实例
    if proxy == nil then -- 使用默认的
        proxyInstance = XUiBattleRoleRoomDefaultProxy.New(team, stageId)
    elseif not CheckIsClass(proxy) then -- 使用匿名类
        proxyInstance = CreateAnonClassInstance(proxy, XUiBattleRoleRoomDefaultProxy, team, stageId)
    else -- 使用自定义类
        proxyInstance = proxy.New(team, stageId)
    end
    self.Proxy = proxyInstance
    self.ChallengeCount = challengeCount
    -- 避免其他系统队伍数据错乱，预先清除
    XEntityHelper.ClearErrorTeamEntityId(team, function(entityId)
        return self.Proxy:GetCharacterViewModelByEntityId(entityId) ~= nil
    end)
    local isStop = self.Proxy:AOPOnStartBefore(self)
    if isStop then return end
    if not self.Proxy:CheckStageRobotIsUseCustomProxy(robotIds) then
        if proxy ~= nil then
            self.Proxy = XUiBattleRoleRoomDefaultProxy.New(team, stageId) -- 写回默认的代理
        end
    end
    -- 关卡名字刷新
    self:RefreshStageName()
    self.BtnShowInfoToggle:SetButtonState(self.Team:GetIsShowRoleDetailInfo()
    and XUiButtonState.Select or XUiButtonState.Normal)
    -- 注册自动关闭
    local openAutoClose, autoCloseEndTime, callback = self.Proxy:GetAutoCloseInfo()
    if openAutoClose then
        self:SetAutoCloseInfo(autoCloseEndTime, callback)
    end
    -- 设置不可编辑时按钮状态
    local canEditor = self.Proxy:CheckIsCanEditorTeam(self.StageId, false)
    self.BtnTeamPrefab.gameObject:SetActiveEx(canEditor and not XUiManager.IsHideFunc)
    self.PanelFirstInfo.gameObject:SetActiveEx(canEditor)
    self.BtnShowInfoToggle.gameObject:SetActiveEx(canEditor)
    self.Proxy:AOPOnStartAfter(self)
end

function XUiBattleRoleRoom:OnEnable()
    XUiBattleRoleRoom.Super.OnEnable(self)
    self:RefreshRoleInfos()
    -- 设置首出信息
    self.FirstEnterBtnGroup:SelectIndex(self.Team:GetFirstFightPos())
    -- 刷新提示
    self:RefreshTipGrids()
    -- 刷新支援状态
    self:RefreshSupportToggle()
    -- 刷新战力控制状态
    self:RefreshFightControlState()
    -- 刷新角色详细信息
    local canEditor = self.Proxy:CheckIsCanEditorTeam(self.StageId, false)
    local showRoleDetail = nil
    if not canEditor then showRoleDetail = false end
    self:RefreshRoleDetalInfo(showRoleDetail)
    -- 设置子面板配置
    self.ChildPanelData = self.Proxy:GetChildPanelData()
    self:LoadChildPanelInfo()
    -- 设置进入战斗按钮状态
    local isEmpty = self.Team:GetIsEmpty()
    self.BtnEnterFight:SetDisable(isEmpty, not isEmpty)
    self.Proxy:AOPOnEnableAfter(self)
end

-- 此方法调用优先级高于所有方法，此时self.Proxy是空的
-- 因此这里只能硬编码
function XUiBattleRoleRoom:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET }
end

function XUiBattleRoleRoom:OnNotify(evt, ...)
    self.Proxy:OnNotify(evt, ...)
end

function XUiBattleRoleRoom:OnDisable()
    XUiBattleRoleRoom.Super.OnDisable(self)
    self.FavorabilityManager.StopCv()
end

function XUiBattleRoleRoom:OnDestroy()
    XUiBattleRoleRoom.Super.OnDestroy(self)
    self:UnRegisterListeners()
end

--######################## 私有方法 ########################

function XUiBattleRoleRoom:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnEnterFight.CallBack = function() self:OnBtnEnterFightClicked() end
    self.BtnShowInfoToggle.CallBack = function(val) self:OnBtnShowInfoToggleClicked(val) end
    self.BtnLeader.CallBack = function() self:OnBtnLeaderClicked() end
    -- 首出按钮组
    local firstTabGroup = { self.BtnRed, self.BtnBlue, self.BtnYellow }
    self.FirstEnterBtnGroup:Init(firstTabGroup, function(tabIndex) self:OnEnterSortBtnGroupClicked(tabIndex) end)
    -- 角色拖动相关
    XUiButtonLongClick.New(self.UiPointerCharacter1, 10, self, nil, self.OnBtnCharacter1LongClicked, self.OnBtnCharacter1LongClickUp, false)
    XUiButtonLongClick.New(self.UiPointerCharacter2, 10, self, nil, self.OnBtnCharacter2LongClicked, self.OnBtnCharacter2LongClickUp, false)
    XUiButtonLongClick.New(self.UiPointerCharacter3, 10, self, nil, self.OnBtnCharacter3LongClicked, self.OnBtnCharacter3LongClickUp, false)
    -- 角色点击
    self:RegisterClickEvent(self.BtnChar1, self.OnBtnChar1Clicked)
    self:RegisterClickEvent(self.BtnChar2, self.OnBtnChar2Clicked)
    self:RegisterClickEvent(self.BtnChar3, self.OnBtnChar3Clicked)
    self.BtnTeamPrefab.CallBack = function() self:OnBtnTeamPrefabClicked() end
    -- 宠物加号点击
    local uiObjPartner
    for pos = 1, MAX_ROLE_COUNT do
        uiObjPartner = self["UiObjPartner" .. pos]
        uiObjPartner:GetObject("BtnClick").CallBack = function()
            if not self.Proxy:CheckIsCanEditorTeam(self.StageId) then return end
            local entityId = self.Team:GetEntityIdByTeamPos(pos)
            if XEntityHelper.GetIsRobot(entityId) then
                XUiManager.TipErrorWithKey("RobotParnerTips")
                return
            end
            XDataCenter.PartnerManager.GoPartnerCarry(self.Team:GetEntityIdByTeamPos(pos), false)
        end
    end
    -- 支援
    self.BtnSupportToggle.CallBack = function(state) self:OnBtnSupportToggleClicked(state) end
end

function XUiBattleRoleRoom:RegisterListeners()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnBeginBattleAutoRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnBeginBattleAutoRemove, self)
end

function XUiBattleRoleRoom:UnRegisterListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnBeginBattleAutoRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnBeginBattleAutoRemove, self)
end

function XUiBattleRoleRoom:OnBtnSupportToggleClicked(state)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.OtherHelp) then
        return
    end
    CS.UnityEngine.PlayerPrefs.SetInt(XPrefs.AssistSwitch .. XPlayer.Id, state)
    if state == 1 then
        self:PlayRightTopTips(XUiHelper.GetText("FightAssistOpen"))
    else
        self:PlayRightTopTips(XUiHelper.GetText("FightAssistClose"))
    end
end

function XUiBattleRoleRoom:OnBtnTeamPrefabClicked()
    RunAsyn(function()
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
        XLuaUiManager.Open("UiRoomTeamPrefab", self.Team:GetCaptainPos()
        , self.Team:GetFirstFightPos()
        , self:GetCharacterLimitType()
        , nil, stageInfo.Type, nil, nil
        , self.StageId
        , self.Team)
        local signalCode, teamData = XLuaUiManager.AwaitSignal("UiRoomTeamPrefab", "RefreshTeamData", self)
        if signalCode ~= XSignalCode.SUCCESS then return end
        local playEntityId = 0
        local soundType = XFavorabilityConfigs.SoundEventType.MemberJoinTeam
        -- 优先队长音效
        local captainEntityId = teamData.TeamData[teamData.CaptainPos]
        if captainEntityId ~= self.Team:GetCaptainPos() then
            playEntityId = captainEntityId
            soundType = XFavorabilityConfigs.SoundEventType.CaptainJoinTeam
        else -- 其次队员音效
            for pos, newEntityId in ipairs(teamData.TeamData) do
                if self.Team:GetEntityIdByTeamPos(pos) ~= newEntityId then
                    playEntityId = newEntityId
                    soundType = XFavorabilityConfigs.SoundEventType.MemberJoinTeam
                    break
                end
            end
        end
        self.Team:UpdateFromTeamData(teamData)
        if playEntityId <= 0 then return end
        self.FavorabilityManager.PlayCvByType(self.Proxy:GetCharacterIdByEntityId(playEntityId)
        , soundType)
    end)
end

function XUiBattleRoleRoom:OnBeginBattleAutoRemove()
    self:Remove()
end

function XUiBattleRoleRoom:OnBtnLeaderClicked()
    local characterViewModelDic = {}
    local viewModel = nil
    for pos, entityId in ipairs(self.Team:GetEntityIds()) do
        characterViewModelDic[pos] = self.Proxy:GetCharacterViewModelByEntityId(entityId)
    end
    XLuaUiManager.Open("UiBattleRoleRoomCaptain", characterViewModelDic, self.Team:GetCaptainPos(), function(newCaptainPos)
        self.Team:UpdateCaptainPos(newCaptainPos)
        self:RefreshCaptainPosInfo()
    end)
end

-- val : 1 or 0 , 1是开启，0是关闭
function XUiBattleRoleRoom:OnBtnShowInfoToggleClicked(val)
    self.Team:SaveIsShowRoleDetailInfo(val)
    self:RefreshRoleDetalInfo(val == 1)
end

function XUiBattleRoleRoom:OnBtnChar1Clicked()
    self:OnBtnCharacterClicked(1)
end

function XUiBattleRoleRoom:OnBtnChar2Clicked()
    self:OnBtnCharacterClicked(2)
end

function XUiBattleRoleRoom:OnBtnChar3Clicked()
    self:OnBtnCharacterClicked(3)
end

function XUiBattleRoleRoom:OnBtnCharacter1LongClicked(time)
    self:OnBtnCharacterLongClick(1, time)
end

function XUiBattleRoleRoom:OnBtnCharacter2LongClicked(time)
    self:OnBtnCharacterLongClick(2, time)
end

function XUiBattleRoleRoom:OnBtnCharacter3LongClicked(time)
    self:OnBtnCharacterLongClick(3, time)
end

function XUiBattleRoleRoom:OnBtnCharacter1LongClickUp()
    self:OnBtnCharacterLongClickUp(1)
end

function XUiBattleRoleRoom:OnBtnCharacter2LongClickUp()
    self:OnBtnCharacterLongClickUp(2)
end

function XUiBattleRoleRoom:OnBtnCharacter3LongClickUp()
    self:OnBtnCharacterLongClickUp(3)
end

function XUiBattleRoleRoom:OnBtnCharacterLongClick(index, time)
    if not self.Proxy:CheckIsCanEditorTeam(self.StageId) then return end
    if not self.Proxy:CheckIsCanDrag(self.StageId) then return end
    -- 无实体直接不处理
    if self.Team:GetEntityIdByTeamPos(index) == 0 then return end
    self.LongClickTime = self.LongClickTime + time / 1000
    if self.LongClickTime > LONG_TIMER then
        self.ImgRoleRepace.gameObject:SetActiveEx(true)
        self.ImgRoleRepace.transform.localPosition = self:GetClickPosition()
    end
end

function XUiBattleRoleRoom:OnBtnCharacterLongClickUp(index)
    -- 未激活不处理
    if not self.ImgRoleRepace.gameObject.activeSelf then return end
    self.LongClickTime = 0
    self.ImgRoleRepace.gameObject:SetActiveEx(false)
    local transformWidth = self.Transform.rect.width
    local targetX = math.floor(self:GetClickPosition().x + transformWidth / 2)
    local targetIndex
    if targetX <= transformWidth / 3 then
        targetIndex = 2
    elseif targetX > transformWidth / 3 and targetX <= transformWidth / 3 * 2 then
        targetIndex = 1
    else
        targetIndex = 3
    end
    -- 相同直接不处理
    if index == targetIndex then return end
    self.Team:SwitchEntityPos(index, targetIndex)
    -- 刷新角色信息
    self:RefreshRoleInfos()
    self:LoadChildPanelInfo()
    self:RefreshPartners()
    self:RefreshRoleDetalInfo()
end

function XUiBattleRoleRoom:OnBtnCharacterClicked(index)
    local isStop = self.Proxy:AOPOnCharacterClickBefore(self, index)
    if isStop then return end
    if not self.Proxy:CheckIsCanEditorTeam(self.StageId) then return end
    RunAsyn(function()
        local oldEntityId = self.Team:GetEntityIdByTeamPos(index)
        XLuaUiManager.Open("UiBattleRoomRoleDetail"
        , self.StageId
        , self.Team
        , index
        , self.Proxy:GetRoleDetailProxy())
        local signalCode, newEntityId = XLuaUiManager.AwaitSignal("UiBattleRoomRoleDetail", "UpdateEntityId", self)
        if signalCode ~= XSignalCode.SUCCESS then return end
        if oldEntityId == newEntityId then return end
        if self.Team:GetEntityIdByTeamPos(index) <= 0 then return end
        -- 播放音效
        local soundType = XFavorabilityConfigs.SoundEventType.MemberJoinTeam
        if self.Team:GetCaptainPos() == index then
            soundType = XFavorabilityConfigs.SoundEventType.CaptainJoinTeam
        end
        self.FavorabilityManager.PlayCvByType(self.Proxy:GetCharacterIdByEntityId(newEntityId)
        , soundType)
    end)
end

function XUiBattleRoleRoom:OnBtnEnterFightClicked()
    local canEnterFight, errorTip = self.Proxy:GetIsCanEnterFight(self.Team, self.StageId)
    if not canEnterFight then
        if errorTip then
            XUiManager.TipError(errorTip)
        end
        return
    end
    RunAsyn(function()
        -- 战力警告
        if self.FightControl then
            local fightControlResult, tipContent = self.FightControl:GetResult()
            if fightControlResult == XUiFightControlState.Ex then
                XUiManager.DialogTip(XUiHelper.GetText("AbilityInsufficient"), tipContent, XUiManager.DialogType.Normal)
                local signalCode, isOK = XLuaUiManager.AwaitSignal("UiDialog", "Close", self)
                if signalCode ~= XSignalCode.SUCCESS then return end
                if not isOK then return end
            end
        end
        local isAssist = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.AssistSwitch .. XPlayer.Id) == 1
        self.Proxy:EnterFight(self.Team, self.StageId, self.ChallengeCount, isAssist)
    end)
end

function XUiBattleRoleRoom:OnEnterSortBtnGroupClicked(index)
    self.Team:UpdateFirstFightPos(index)
    self:RefreshFirstFightInfo()
end

function XUiBattleRoleRoom:InitUiPanelRoleModels()
    local uiModelRoot = self.UiModelGo.transform
    self.UiPanelRoleModels = {}
    for i = 1, MAX_ROLE_COUNT do
        self.UiPanelRoleModels[i] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelRoleModel" .. i)
        , self.Name, nil, true, nil, true, true)
    end
end

function XUiBattleRoleRoom:RefreshRoleModels()
    local characterViewModel
    local entityId
    local sourceEntityId
    local uiPanelRoleModel
    -- local finishedCallback = function()
    -- end
    for pos = 1, MAX_ROLE_COUNT do
        uiPanelRoleModel = self.UiPanelRoleModels[pos]
        entityId = self.Team:GetEntityIdByTeamPos(pos)
        characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
        self["ImgAdd" .. pos].gameObject:SetActiveEx(characterViewModel == nil)
        if characterViewModel then
            sourceEntityId = characterViewModel:GetSourceEntityId()
            if XRobotManager.CheckIsRobotId(sourceEntityId) then
                local robot2CharEntityId = XRobotManager.GetCharacterId(sourceEntityId)
                local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(robot2CharEntityId)
                if XRobotManager.CheckUseFashion(sourceEntityId) and isOwn then
                    local character = XDataCenter.CharacterManager.GetCharacter(robot2CharEntityId)
                    local robot2CharViewModel = character:GetCharacterViewModel()
                    uiPanelRoleModel:UpdateCharacterModel(robot2CharEntityId, nil, nil, nil, nil, robot2CharViewModel:GetFashionId())
                else
                    local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
                    uiPanelRoleModel:UpdateRobotModel(sourceEntityId, robotConfig.CharacterId
                    , nil, robotConfig.FashionId, robotConfig.WeaponId)
                end
            else
                uiPanelRoleModel:UpdateCharacterModel(sourceEntityId, nil, nil, nil, nil, characterViewModel:GetFashionId())
            end
            uiPanelRoleModel:ShowRoleModel()
        else
            uiPanelRoleModel:HideRoleModel()
        end
    end
end

function XUiBattleRoleRoom:RefreshPartners()
    local isStop = self.Proxy:AOPOnRefreshPartnersBefore(self)
    if isStop then return end
    local entityId = 0
    local partner = nil
    local characterViewModel = nil
    local uiObjPartner
    local rImgParnetIcon = nil
    local rImgPlus = nil
    for pos = 1, MAX_ROLE_COUNT do
        entityId = self.Team:GetEntityIdByTeamPos(pos)
        partner = self.Proxy:GetPartnerByEntityId(entityId)
        characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
        uiObjPartner = self["UiObjPartner" .. pos]
        uiObjPartner.gameObject:SetActiveEx(characterViewModel ~= nil and not XUiManager.IsHideFunc)
        rImgParnetIcon = uiObjPartner:GetObject("RImgType")
        rImgParnetIcon.gameObject:SetActiveEx(partner ~= nil)
        rImgPlus = uiObjPartner:GetObject("Img+")
        rImgPlus.gameObject:SetActiveEx(not partner)
        if partner then
            rImgParnetIcon:SetRawImage(partner:GetIcon())
        end
    end
end

function XUiBattleRoleRoom:RefreshRoleEffects()
    local uiModelRoot = self.UiModelGo.transform
    local panelRoleBGEffectGo
    local teamConfig
    local isLoadRoleBGEffect = self.Proxy:GetIsShowRoleBGEffect()
    for i = 1, MAX_ROLE_COUNT do
        -- 加载背景特效
        if isLoadRoleBGEffect then
            teamConfig = XTeamConfig.GetTeamCfgById(i)
            panelRoleBGEffectGo = uiModelRoot:FindTransform("PanelRoleEffect" .. i).gameObject
            panelRoleBGEffectGo:LoadPrefab(teamConfig.EffectPath, false)
        end
    end
end

function XUiBattleRoleRoom:RefreshFirstFightInfo()
    for i = 1, MAX_ROLE_COUNT do
        self["PanelFirstEnterTag" .. i].gameObject:SetActiveEx(self.Team:GetFirstFightPos() == i)
    end
end

function XUiBattleRoleRoom:RefreshCaptainPosInfo()
    local captainPos = self.Team:GetCaptainPos()
    local entityId = self.Team:GetEntityIdByTeamPos(captainPos)
    local characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
    self.RImgCapIcon.gameObject:SetActiveEx(characterViewModel ~= nil)
    self.TxtSkillDesc.gameObject:SetActiveEx(characterViewModel ~= nil)
    if characterViewModel then
        local captainSkillInfo = characterViewModel:GetCaptainSkillInfo()
        self.RImgCapIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())
        self.TxtSkillName.text = captainSkillInfo.Name
        self.TxtSkillDesc.text = captainSkillInfo.Level > 0 and
        captainSkillInfo.Intro or CsXTextManager.GetText("CaptainSkillLock")
    else
        self.TxtSkillName.text = CsXTextManager.GetText("TeamDoNotChooseCaptain")
    end
end

function XUiBattleRoleRoom:RefreshRoleInfos()
    -- 刷新角色模型
    self:RefreshRoleModels()
    -- 刷新角色特效
    self:RefreshRoleEffects()
    -- 刷新伙伴
    self:RefreshPartners()
    -- 刷新队长信息
    self:RefreshCaptainPosInfo()
    self.Proxy:AOPRefreshRoleInfosAfter(self)
end

function XUiBattleRoleRoom:LoadChildPanelInfo()
    if not self.ChildPanelData then return end
    local childPanelData = self.ChildPanelData
    -- 加载panel asset
    local instanceGo = childPanelData.instanceGo
    if XTool.UObjIsNil(instanceGo) then
        instanceGo = self.PanelExtraUiInfo:LoadPrefab(childPanelData.assetPath)
        childPanelData.instanceGo = instanceGo
        -- 加载panel proxy
        childPanelData.instanceProxy = childPanelData.proxy.New(instanceGo)
    end
    -- 加载proxy参数
    local proxyArgs = {}
    if childPanelData.proxyArgs then
        for _, argName in ipairs(childPanelData.proxyArgs) do
            if type(argName) == "string" then
                proxyArgs[#proxyArgs + 1] = self[argName]
            else
                proxyArgs[#proxyArgs + 1] = argName
            end
        end
    end
    childPanelData.instanceProxy:SetData(table.unpack(proxyArgs))
end

function XUiBattleRoleRoom:RefreshStageName()
    local chapterName, stageName = self.FubenManager.GetFubenNames(self.StageId)
    self.TxtChapterName.text = chapterName
    self.TxtStageName.text = stageName
end

function XUiBattleRoleRoom:RefreshRoleDetalInfo(isShow)
    if isShow == nil then isShow = self.Team:GetIsShowRoleDetailInfo() end
    local entityId
    local characterViewModel
    for pos = 1, 3 do
        self["CharacterInfo" .. pos].gameObject:SetActiveEx(isShow)
        if isShow then
            entityId = self.Team:GetEntityIdByTeamPos(pos)
            characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
            if characterViewModel then
                self["TxtFight" .. pos].text = self.Proxy:GetRoleAbility(entityId)
                self["RImgType" .. pos]:SetRawImage(characterViewModel:GetProfessionIcon())
            else
                self["CharacterInfo" .. pos].gameObject:SetActiveEx(false)
            end
        end
    end
end

-- 刷新提示
function XUiBattleRoleRoom:RefreshTipGrids()
    -- 创建玩法自定义提示
    self.Proxy:CreateCustomTipGo(self.PanelTipGoContainer)
    -- 自身提示
    local descs = {}
    -- 关卡条件描述
    local suggestedConditionIds, forceConditionIds = XDataCenter.FubenManager.GetConditonByMapId(self.StageId)
    local conditions = {}
    appendArray(conditions, suggestedConditionIds)
    appendArray(conditions, forceConditionIds)
    for _, id in ipairs(conditions) do
        local _, desc = XConditionManager.CheckCondition(id, self.Team:GetEntityIds())
        table.insert(descs, desc)
    end
    -- 关卡事件配置描述
    local eventDesc = XRoomSingleManager.GetEventDescByMapId(self.StageId)
    if eventDesc then table.insert(descs, eventDesc) end
    -- 追加代理提示
    descs = appendArray(descs, self.Proxy:GetTipDescs())
    -- 创建提示
    XUiHelper.RefreshCustomizedList(self.PanelTipContainer, self.GridTips, #descs, function(i, grid)
        grid:GetComponent("UiObject"):GetObject("TxtDesc").text = descs[i]
    end)
    self.PanelTipContainer.gameObject:SetActiveEx(#descs > 0)
    -- 将所有的限制，职业，试用提示隐藏
    self.PanelCharacterLimit.gameObject:SetActiveEx(false)
    self.PanelCharacterCareer.gameObject:SetActiveEx(false)
    local viewModels = {}
    local teamEntityIds = {}
    for _, entityId in ipairs(self.Team:GetEntityIds()) do
        if entityId > 0 then
            table.insert(viewModels, self.Proxy:GetCharacterViewModelByEntityId(entityId))
            table.insert(teamEntityIds, entityId)
        end
    end
    -- 检查是否满足角色限制条件
    if XEntityHelper.CheckIsNeedRoleLimit(self.StageId, viewModels) then
        self:RefreshRoleLimitTip()
        return
    end
    -- 检查职业推荐
    local needCareerTip, types, indexDic = XEntityHelper.CheckIsNeedCareerLimit(self.StageId, viewModels)
    if needCareerTip then
        self.PanelCharacterCareer.gameObject:SetActiveEx(true)
        XUiHelper.RefreshCustomizedList(self.PanelCareerList, self.GridCareer, #types, function(index, grid)
            local uiObject = grid.transform:GetComponent("UiObject")
            local isActive = indexDic[index] or false
            local professionIcon = XCharacterConfigs.GetNpcTypeIcon(types[index])
            uiObject:GetObject("Normal").gameObject:SetActiveEx(isActive)
            uiObject:GetObject("Disable").gameObject:SetActiveEx(not isActive)
            uiObject:GetObject("RImgNormalIcon"):SetRawImage(professionIcon)
            uiObject:GetObject("RImgDisableIcon"):SetRawImage(professionIcon)
        end)
        return
    end
    -- 检查试用角色
    if XFubenConfigs.GetStageAISuggestType(self.StageId) ~= XFubenConfigs.AISuggestType.Robot then
        return
    end
    local compareAbility = false
    -- 拿到试玩角色的战力字典
    local characterId2AbilityDicWithRobot = {}
    local viewModel
    local entities = self.Proxy:GetEntities()
    if #entities <= 0 then
        XLog.Error(string.format("关卡Id%s字段AISuggestType配置为AISuggestType.Robot，但GetEntities获取数据为空，请实现GetEntities接口，可支持机器人战力提示"
            , self.StageId))
    end
    for _, entity in ipairs(entities) do
        viewModel = self.Proxy:GetCharacterViewModelByEntityId(entity:GetId())
        if XEntityHelper.GetIsRobot(viewModel:GetSourceEntityId()) then
            characterId2AbilityDicWithRobot[viewModel:GetId()] = self.Proxy:GetRoleAbility(entity:GetId())
        end
    end
    -- 与队伍比较
    for index, value in ipairs(viewModels) do
        if self.Proxy:GetRoleAbility(teamEntityIds[index])
        < (characterId2AbilityDicWithRobot[value:GetId()] or 0) then
            compareAbility = true
            break
        end
    end
    if compareAbility then
        self.PanelCharacterLimit.gameObject:SetActiveEx(true)
        self.ImgCharacterLimit.gameObject:SetActiveEx(false)
        self.TxtCharacterLimit.text = XUiHelper.GetText("TeamRobotTips")
    end
end

function XUiBattleRoleRoom:RefreshRoleLimitTip()
    -- XFubenConfigs.CharacterLimitType
    local limitType = self:GetCharacterLimitType()
    local isShow = XFubenConfigs.IsStageCharacterLimitConfigExist(limitType)
    self.PanelCharacterLimit.gameObject:SetActiveEx(isShow or false)
    if not isShow then return end
    -- 图标
    self.ImgCharacterLimit:SetSprite(XFubenConfigs.GetStageCharacterLimitImageTeamEdit(limitType))
    -- 文案
    if limitType == XFubenConfigs.CharacterLimitType.IsomerDebuff or 
        limitType == XFubenConfigs.CharacterLimitType.NormalDebuff then
        self.TxtCharacterLimit.text = XFubenConfigs.GetStageMixCharacterLimitTips(limitType
        , self:GetTeamCharacterTypes())
        return
    end
    local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(self.StageId)
    self.TxtCharacterLimit.text = XFubenConfigs.GetStageCharacterLimitTextTeamEdit(limitType
        , self.Team:GetCharacterType(), limitBuffId)
end

function XUiBattleRoleRoom:GetTeamCharacterTypes()
    local result = {}
    for _, entityId in ipairs(self.Team:GetEntityIds()) do
        if entityId > 0 then
            table.insert(result, self.Proxy:GetCharacterViewModelByEntityId(entityId):GetCharacterType())
        end
    end
    return result
end

function XUiBattleRoleRoom:RefreshSupportToggle()
    local stageInfo = self.FubenManager.GetStageInfo(self.StageId)
    -- 关卡不需要支援直接隐藏返回
    if stageInfo and stageInfo.HaveAssist ~= 1 then
        self.BtnSupportToggle.gameObject:SetActiveEx(false)
        return
    end
    -- 主线，或者HaveAssist为1显示支援
    self.BtnSupportToggle.gameObject:SetActiveEx(true)
    -- 设置是否开启支援功能
    local canOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.OtherHelp)
    self.BtnSupportToggle:SetButtonState(canOpen and XUiButtonState.Normal or XUiButtonState.Disable)
    if not canOpen then return end
    -- 设置上一次支援状态
    local assistSwitch = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.AssistSwitch .. XPlayer.Id)
    self.BtnSupportToggle:SetButtonState(assistSwitch == 1
    and XUiButtonState.Select or XUiButtonState.Normal)
end

function XUiBattleRoleRoom:PlayRightTopTips(message)
    self.PanelRightTopTip.gameObject:SetActiveEx(true)
    self.TxtRightTopTip.text = message
    self:PlayAnimation("PanelTipEnable")
end

-- 刷新战力控制状态
function XUiBattleRoleRoom:RefreshFightControlState()
    local isStop = self.Proxy:AOPRefreshFightControlStateBefore(self)
    if isStop then return end
    local stageConfig = self.FubenManager.GetStageCfg(self.StageId)
    local teamAbilities = {}
    local viewModel = nil
    for pos, entityId in ipairs(self.Team:GetEntityIds()) do
        viewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
        if viewModel == nil then
            table.insert(teamAbilities, 0)
        else
            table.insert(teamAbilities, self.Proxy:GetRoleAbility(entityId))
        end
    end
    if self.FightControl == nil then
        self.FightControl = XUiNewRoomFightControl.New(self.FightControlGo)
    end
    self.FightControl:UpdateInfo(stageConfig.FightControlId
    , teamAbilities
    , self.Proxy:CheckStageForceConditionWithTeamEntityId(self.Team, self.StageId, false)
    , self.StageId
    , self.Team:GetEntityIds())
end

function XUiBattleRoleRoom:GetClickPosition()
    return XUiHelper.GetScreenClickPosition(self.Transform, self.Camera)
end

function XUiBattleRoleRoom:GetCharacterLimitType()
    return XFubenConfigs.GetStageCharacterLimitType(self.StageId)
end

return XUiBattleRoleRoom