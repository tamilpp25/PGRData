local XUiNewRoomFightControl = require("XUi/XUiCommon/XUiNewRoomFightControl")
local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local CsXTextManager = CS.XTextManager
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiBattleRoleRoom:XLuaUi
---@field private _StageLineupConfig XTableStageLineupType
local XUiBattleRoleRoom = XLuaUiManager.Register(XLuaUi, "UiBattleRoleRoom")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")

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
    self.UiPointerCharacter1 = self.BtnChar1:GetComponent("XUiPointer")
    self.UiPointerCharacter2 = self.BtnChar2:GetComponent("XUiPointer")
    self.UiPointerCharacter3 = self.BtnChar3:GetComponent("XUiPointer")
    self.PanelRightTopTip = self.PanelTip
    self.TxtRightTopTip = self.TxtTips1
    self.FightControlGo = self.PanelNewRoomFightControl
    -- 重定义 end
    self.FubenManager = XDataCenter.FubenManager
    self.TeamManager = XDataCenter.TeamManager
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
    local stageConfig = XMVCA.XFuben:GetStageCfg(stageId)
    -- 判断是否有重复挑战
    if XRoomSingleManager.AgainBtnType[stageConfig.FunctionLeftBtn] 
        or XRoomSingleManager.AgainBtnType[stageConfig.FunctionRightBtn] then
        XUiBattleRoleRoom.__StageId2ArgData = XUiBattleRoleRoom.__StageId2ArgData or {}
        local argData = XUiBattleRoleRoom.__StageId2ArgData[stageId]
        if isReadArgsByCacheWithAgain and argData then
            team = argData.team
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

    -- 判断是否走特殊编队规则
    self._CanStageRobotBlendUse, self._StageLineupConfig = XMVCA.XFuben:GetConfigStageLineupType(stageId)
    
    local robotIds = stageConfig.RobotId
    if #robotIds > 0 and stageConfig.HideAction ~= 1 then -- 说明要使用机器人，默认抛弃传入的队伍和代理
        -- 去掉队伍是因为已经用不到原队伍，强制使用配置的机器人
        team = nil 
    end
    -- 若队伍为空，优先根据关卡固定机器人，其次读取默认主线队伍
    if team == nil then
        if #robotIds > 0 then
            if self._CanStageRobotBlendUse then
                team = self:GetBlendTeamDataByStageId(stageId, robotIds)
            else
                team = self.TeamManager.CreateTempTeam(XTool.CloneEx(robotIds, true))
            end
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
    self.Proxy:ClearErrorTeamEntityId(team, function(entityId)
        return self.Proxy:GetCharacterViewModelByEntityId(entityId) ~= nil
    end)
    
    self:CheckTeamMemberValid(self.StageId, self.Team)
    
    local isStop = self.Proxy:AOPOnStartBefore(self)
    if isStop then return end
    if not self.Proxy:CheckStageRobotIsUseCustomProxy(robotIds) then
        if proxy ~= nil then
            self.Proxy = XUiBattleRoleRoomDefaultProxy.New(team, stageId) -- 写回默认的代理
        end
    end
    -- 关卡名字刷新
    self:RefreshStageName()
    -- 关卡机制提示刷新
    self._IsEnableGeneralSkillSelection = true
    if self.Proxy.CheckIsEnableGeneralSkillSelection then
        self._IsEnableGeneralSkillSelection = self.Proxy:CheckIsEnableGeneralSkillSelection()
    end
    self:RefreshPanelRecommendGeneralSkill()
    self:RefreshGeneralSkill()

    local isShowRoleDetailInfo = self.Team:GetIsShowRoleDetailInfo()
    local stageConfig = XMVCA.XFuben:GetStageCfg(self.StageId)
    local isHasGeneralSkillIds = not string.IsNilOrEmpty(stageConfig.GeneralSkillIds)
    -- 如果有新机制  要强行打开信息按钮
    if isHasGeneralSkillIds then
        isShowRoleDetailInfo = true
    end
    -- 注册自动关闭
    local openAutoClose, autoCloseEndTime, callback = self.Proxy:GetAutoCloseInfo()
    if openAutoClose then
        self:SetAutoCloseInfo(autoCloseEndTime, callback)
    end
    -- 设置不可编辑时按钮状态
    local canEditor = self.Proxy:CheckIsCanEditorTeam(self.StageId, false)
    self.BtnTeamPrefab.gameObject:SetActiveEx(canEditor and not XUiManager.IsHideFunc)
    self.PanelFirstInfo.gameObject:SetActiveEx(canEditor)
    -- self.BtnShowInfoToggle:SetButtonState(isShowRoleDetailInfo and XUiButtonState.Select or XUiButtonState.Normal)
    -- self.BtnShowInfoToggle.gameObject:SetActiveEx(canEditor)
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
    local showRoleDetail = nil
    local canEditor = self.Proxy:CheckIsCanEditorTeam(self.StageId, false)

    if canEditor and not self.FirstInFin then
        local stageConfig = XMVCA.XFuben:GetStageCfg(self.StageId)
        if not string.IsNilOrEmpty(stageConfig.GeneralSkillIds) then
            self:OnBtnShowInfoToggleClicked(1)
            goto SkipCheckShow
        end
    end

    if not canEditor then 
        showRoleDetail =  false 
    end
    if self.Proxy.CheckIsEnableGeneralSkillSelection and self.Proxy:CheckIsEnableGeneralSkillSelection() then
        self.PanelGeneralSkill:Refresh()
    end
    self:RefreshRoleDetalInfo(true)
    :: SkipCheckShow ::
    self:RefreshRobotTeamBlenderShow()
    -- 设置子面板配置
    self.ChildPanelData = self.Proxy:GetChildPanelData()
    self:LoadChildPanelInfo()
    -- 设置进入战斗按钮状态
    self:RefreshBtnEnterFight()
    self:RefreshAnimationSet()
    self.Proxy:AOPOnEnableAfter(self)

    self.FirstInFin = true
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_ANIM_ENABLE, self.RefreshAnimationSet, self)
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
    XMVCA.XFavorability:StopCv()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_ANIM_ENABLE, self.RefreshAnimationSet, self)
end

function XUiBattleRoleRoom:OnDestroy()
    XUiBattleRoleRoom.Super.OnDestroy(self)
    self:UnRegisterListeners()
    if self.ChildPanelData and self.ChildPanelData.instanceProxy
        and self.ChildPanelData.instanceProxy.OnDestroy then
        self.ChildPanelData.instanceProxy:OnDestroy()
    end
    XMVCA.XFavorability:StopCv()

    for k, cuteRandomControllers in pairs(self.CuteRandomControllers) do
        if cuteRandomControllers then
            cuteRandomControllers:Stop()
        end
    end

    self.XUiButtonLongClick1:Destroy()
    self.XUiButtonLongClick2:Destroy()
    self.XUiButtonLongClick3:Destroy()
end

--######################## 私有方法 ########################

function XUiBattleRoleRoom:RegisterUiEvents()
    self.BtnBack.CallBack = function()
        if self.Proxy:AOPOnClickBtnBack(self) then return end
        self:Close()
    end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnEnterFight.CallBack = function() self:OnBtnEnterFightClicked() end
    self.BtnShowInfoToggle.CallBack = function(val) self:OnBtnShowInfoToggleClicked(val) end
    self.BtnLeader.CallBack = function() self:OnBtnLeaderClicked() end
    -- 首出按钮组
    local firstTabGroup = { self.BtnRed, self.BtnBlue, self.BtnYellow }
    self.FirstEnterBtnGroup:Init(firstTabGroup, function(tabIndex) self:OnEnterSortBtnGroupClicked(tabIndex) end)
    -- 角色拖动相关
    self.XUiButtonLongClick1 = XUiButtonLongClick.New(self.UiPointerCharacter1, 10, self, nil, self.OnBtnCharacter1LongClicked, self.OnBtnCharacter1LongClickUp, false)
    self.XUiButtonLongClick2 = XUiButtonLongClick.New(self.UiPointerCharacter2, 10, self, nil, self.OnBtnCharacter2LongClicked, self.OnBtnCharacter2LongClickUp, false)
    self.XUiButtonLongClick3 = XUiButtonLongClick.New(self.UiPointerCharacter3, 10, self, nil, self.OnBtnCharacter3LongClicked, self.OnBtnCharacter3LongClickUp, false)
    -- 角色点击
    self:RegisterClickEvent(self.BtnChar1, self.OnBtnChar1Clicked)
    self:RegisterClickEvent(self.BtnChar2, self.OnBtnChar2Clicked)
    self:RegisterClickEvent(self.BtnChar3, self.OnBtnChar3Clicked)
    self.BtnTeamPrefab.CallBack = function() self:OnBtnTeamPrefabClicked() end
    -- 宠物加号点击
    local uiObjPartner
    for pos = 1, MAX_ROLE_COUNT do
        uiObjPartner = self["CharacterPets" .. pos]
        uiObjPartner:GetObject("BtnClick").CallBack = function()
            --混用规则优先
            if not self._CanStageRobotBlendUse then
                if not self.Proxy:CheckIsCanEditorTeam(self.StageId) then return end
            end
            
            if self.Proxy:AOPGoPartnerCarry(self.Team, pos) then
                return
            end
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
    -- 入场动画选择
    self.BtnAnimationSet.CallBack = handler(self, self.OnBtnAnimationSetClick)
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
        teamData = self.Proxy:FilterPresetTeamEntitiyIds(teamData)
        local playEntityId = 0
        local soundType = XEnumConst.Favorability.SoundEventType.MemberJoinTeam
        -- 优先队长音效
        local captainEntityId = teamData.TeamData[teamData.CaptainPos]
        -- PS:这里GetCaptainPos初版应该写错了，刚好造成设置队伍预设时导致永远播放预设中的队长进场音效
        -- 如果改回GetCaptainPosEntityId应该是符合初版的逻辑：队长音效优先，按顺序队员。后面如果有相关反馈，可以和策划对下用哪个逻辑即可。
        if captainEntityId ~= self.Team:GetCaptainPos() then
            playEntityId = captainEntityId
            soundType = XEnumConst.Favorability.SoundEventType.CaptainJoinTeam
        else -- 其次队员音效
            for pos, newEntityId in ipairs(teamData.TeamData) do
                if self.Team:GetEntityIdByTeamPos(pos) ~= newEntityId then
                    playEntityId = newEntityId
                    soundType = XEnumConst.Favorability.SoundEventType.MemberJoinTeam
                    break
                end
            end
        end
        self.Team:UpdateFromTeamData(teamData)
        if XLuaUiManager.IsUiShow("UiRoomTeamPrefab") then
            XLuaUiManager.Close("UiRoomTeamPrefab")
        end
        if XTool.IsNumberValid(playEntityId) then
            XMVCA.XFavorability:PlayCvByType(self.Proxy:GetCharacterIdByEntityId(playEntityId)
            , soundType)
        end
    end)
end

function XUiBattleRoleRoom:OnBeginBattleAutoRemove()
    self:Remove()
end

function XUiBattleRoleRoom:OnBtnLeaderClicked()
    local characterViewModelDic = {}
    local viewModel = nil
    for pos, entityId in pairs(self.Team:GetEntityIds()) do
        characterViewModelDic[pos] = self.Proxy:GetCharacterViewModelByEntityId(entityId)
    end
    XLuaUiManager.Open("UiBattleRoleRoomCaptain", characterViewModelDic, self.Team:GetCaptainPos(), function(newCaptainPos)
        if self.Proxy:AOPOnCaptainPosChangeBefore(newCaptainPos, self.Team) then return end
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
    if not self.Proxy:CheckIsCanMoveUpCharacter(index, time) then return end
    -- 混用规则优先
    if not self._CanStageRobotBlendUse then
        if not self.Proxy:CheckIsCanEditorTeam(self.StageId) then return end
    end
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
    if not self.ImgRoleRepace or not self.ImgRoleRepace.gameObject.activeSelf then return end
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
    if not self.Proxy:CheckIsCanMoveDownCharacter(targetIndex) then return end
    
    -- 判断关卡固定机器人混编
    if self._CanStageRobotBlendUse then
        -- 只有自由位才能相互交换
        local toType = self._StageLineupConfig.Type[targetIndex]
        local fromType = self._StageLineupConfig.Type[index]
        if fromType ~= XEnumConst.FuBen.StageLineupType.Free then
            XUiManager.TipText('BattleRoleRoomMoveFromInvalid')
            return
        end
        if toType ~= XEnumConst.FuBen.StageLineupType.Free then
            XUiManager.TipText('BattleRoleRoomMoveToInvalid')
            return
        end
    end
    
    self.Team:SwitchEntityPos(index, targetIndex)
    -- 刷新角色信息
    self:ActiveSelectColorEffect(targetIndex)
    self:RefreshRoleInfos()
    self:LoadChildPanelInfo()
    self:RefreshPartners()
    self:RefreshRoleDetalInfo(true)
    self:RefreshCharacterRImgType()
end

function XUiBattleRoleRoom:OnBtnCharacterClicked(index)
    local isStop = self.Proxy:AOPOnCharacterClickBefore(self, index)
    if isStop then return end
    --关卡固定队伍混编优先
    if self._CanStageRobotBlendUse then
        local type = self._StageLineupConfig.Type[index]
        if type == XEnumConst.FuBen.StageLineupType.RobotOnly then
            XUiManager.TipText('BattleRoleRoomRoleCannotEditTips')
            return
        elseif type == XEnumConst.FuBen.StageLineupType.Lock then
            XUiManager.TipText('BattleRoleRoomPosCannotEditTips')
            return
        end
    else
        if not self.Proxy:CheckIsCanEditorTeam(self.StageId) then return end
    end
    
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
        local soundType = XEnumConst.Favorability.SoundEventType.MemberJoinTeam
        if self.Team:GetCaptainPos() == index then
            soundType = XEnumConst.Favorability.SoundEventType.CaptainJoinTeam
        end
        XMVCA.XFavorability:PlayCvByType(self.Proxy:GetCharacterIdByEntityId(newEntityId)
        , soundType)

        -- 播放脚底选中特效
        self:ActiveSelectColorEffect(index)
    end)    
end

function XUiBattleRoleRoom:OnBtnEnterFightClicked()
    if self.Proxy:AOPOnClickFight(self) then
        return
    end
    self:EnterFight()
end

function XUiBattleRoleRoom:EnterFight()
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
    if self.Proxy:AOPOnFirstFightBtnClick(self.FirstEnterBtnGroup, index, self.Team) then return end
    if self.Team:GetFirstFightPos() ~= index then
        self.Team:UpdateFirstFightPos(index)
    end
    self:RefreshFirstFightInfo()
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

function XUiBattleRoleRoom:GetClickPosition()
    return XUiHelper.GetScreenClickPosition(self.Transform, self.Camera)
end

function XUiBattleRoleRoom:GetCharacterLimitType()
    return XFubenConfigs.GetStageCharacterLimitType(self.StageId)
end

function XUiBattleRoleRoom:InitUiPanelRoleModels()
    local uiModelRoot = self.UiModelGo.transform
    self.UiPanelRoleModels = {}
    self.CuteRandomControllers = {} 
    for i = 1, MAX_ROLE_COUNT do
        self.UiPanelRoleModels[i] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelRoleModel" .. i)
        , self.Name, nil, true, nil, true, true)
        self.CuteRandomControllers[i] = XSpecialTrainActionRandom.New()
    end
end

function XUiBattleRoleRoom:RefreshRoleModels()
    local characterViewModel
    local entityId
    local sourceEntityId
    local uiPanelRoleModel
    local cuteRandomController
    -- local finishedCallback = function()
    -- end
    for pos = 1, MAX_ROLE_COUNT do
        cuteRandomController = self.CuteRandomControllers[pos]
        uiPanelRoleModel = self.UiPanelRoleModels[pos]
        entityId = self.Team:GetEntityIdByTeamPos(pos)
        characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
        self["ImgAdd" .. pos].gameObject:SetActiveEx(characterViewModel == nil)
        if characterViewModel then
            --先展示模型根节点，避免隐藏后，重新显示时，动画无法播放
            uiPanelRoleModel:ShowRoleModel()
            sourceEntityId = characterViewModel:GetSourceEntityId()
            if XRobotManager.CheckIsRobotId(sourceEntityId) then
                local robot2CharEntityId = XRobotManager.GetCharacterId(sourceEntityId) -- charId
                local isOwn = XMVCA.XCharacter:IsOwnCharacter(robot2CharEntityId)

                -- 检测启用q版
                if self.Proxy:CheckUseCuteModel() and XCharacterCuteConfig.CheckHasCuteModel(robot2CharEntityId) then
                    if isOwn then
                        uiPanelRoleModel:UpdateCuteModel(nil, robot2CharEntityId, nil, nil, nil, nil, true)
                    else
                        local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
                        uiPanelRoleModel:UpdateCuteModel(nil, robotConfig.CharacterId, nil, nil, nil, nil, true)
                    end
                else
                    if XRobotManager.CheckUseFashion(sourceEntityId) and isOwn then
                        local character2 = XMVCA.XCharacter:GetCharacter(robot2CharEntityId)
                        local robot2CharViewModel = character2:GetCharacterViewModel()
                        uiPanelRoleModel:UpdateCharacterModel(robot2CharEntityId, nil, nil, nil, nil, robot2CharViewModel:GetFashionId())
                    else
                        local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
                        uiPanelRoleModel:UpdateRobotModel(sourceEntityId, robotConfig.CharacterId
                        , nil, robotConfig.FashionId, robotConfig.WeaponId, nil, nil, nil, "UiBattleRoleRoom")
                    end
                end
            else
                if self.Proxy:CheckUseCuteModel() and XCharacterCuteConfig.CheckHasCuteModel(sourceEntityId) then
                    uiPanelRoleModel:UpdateCuteModel(nil, sourceEntityId, nil, nil, nil, nil, true)
                else
                    uiPanelRoleModel:UpdateCharacterModel(sourceEntityId, nil, self.Name, nil, nil, characterViewModel:GetFashionId())
                end
            end
        else
            uiPanelRoleModel:HideRoleModel()
        end
    end

    -- 最后再刷新q版状态机
    if self.Proxy:CheckUseCuteModel() then
        for pos = 1, MAX_ROLE_COUNT do
            cuteRandomController = self.CuteRandomControllers[pos]
            uiPanelRoleModel = self.UiPanelRoleModels[pos]
            cuteRandomController:Stop()
    
            -- 如果有人物再刷新
            if uiPanelRoleModel:GetAnimator() then
                cuteRandomController:SetAnimator(uiPanelRoleModel:GetAnimator(), {}, uiPanelRoleModel)
                cuteRandomController:Play()
            end
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
        uiObjPartner = self["CharacterPets" .. pos]
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

function XUiBattleRoleRoom:RefreshCharacterRImgType()
    local entityId = 0
    local characterViewModel = nil
    local curRImgType = nil
    local iconPath = nil

    local tankCharInTeamCount = 0
    local amplifierInTeamCount = 0
    for pos = 1, MAX_ROLE_COUNT do
        entityId = self.Team:GetEntityIdByTeamPos(pos)
        characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
        if characterViewModel and characterViewModel:GetProfessionType() == XEnumConst.CHARACTER.Career.Tank then
            tankCharInTeamCount = tankCharInTeamCount + 1
        elseif characterViewModel and characterViewModel:GetProfessionType() == XEnumConst.CHARACTER.Career.Amplifier then
            amplifierInTeamCount = amplifierInTeamCount + 1
        end
    end

    local obsActiveCarrer, obsPos = self.Team:GetObservationActiveCareer()
    for pos = 1, MAX_ROLE_COUNT do
        entityId = self.Team:GetEntityIdByTeamPos(pos)
        characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
        -- 观测者职业的特殊处理
        curRImgType = self["RImgType" .. pos]
        curRImgType.gameObject:SetActiveEx(XTool.IsNumberValid(entityId))
        local tankEffectTrans = curRImgType.transform:Find("TankEffect")
        local amplifierEffectTrans = curRImgType.transform:Find("AmplifierEffect")
        if not tankEffectTrans or not amplifierEffectTrans then
            return
        end
        local tankEffectGo = tankEffectTrans.gameObject
        local amplifierEffectGo = amplifierEffectTrans.gameObject
        tankEffectGo:SetActiveEx(false)
        amplifierEffectGo:SetActiveEx(false)
        if obsActiveCarrer ~= XEnumConst.CHARACTER.Career.None and XTool.IsNumberValid(obsPos) and obsPos == pos then
            iconPath = XMVCA.XCharacter:GetNpcTypeIconObs(obsActiveCarrer)
            if obsActiveCarrer == XEnumConst.CHARACTER.Career.Tank then
                tankEffectGo:SetActiveEx(true)
            elseif obsActiveCarrer == XEnumConst.CHARACTER.Career.Amplifier or obsActiveCarrer == XEnumConst.CHARACTER.Career.Support then
                amplifierEffectGo:SetActiveEx(true)
            end
        elseif characterViewModel then
            iconPath = characterViewModel:GetProfessionIcon()
        end

        if not string.IsNilOrEmpty(iconPath) then
            curRImgType:SetRawImage(iconPath)
        end
    end
end

function XUiBattleRoleRoom:RefreshRoleEffects()
    -- local uiModelRoot = self.UiModelGo.transform
    -- local panelRoleBGEffectGo
    -- local teamConfig
    -- local isLoadRoleBGEffect = self.Proxy:GetIsShowRoleBGEffect()

    -- 暂时不需要加载特效了
    -- for i = 1, MAX_ROLE_COUNT do
    --     -- 加载背景特效
    --     if isLoadRoleBGEffect then
    --         teamConfig = XTeamConfig.GetTeamCfgById(i)
    --         panelRoleBGEffectGo = uiModelRoot:FindTransform("PanelRoleEffect" .. i).gameObject
    --         panelRoleBGEffectGo:LoadPrefab(teamConfig.EffectPath, false)
    --     end
    -- end
    --
end

-- 激活脚底选人特效
function XUiBattleRoleRoom:ActiveSelectColorEffect(index)
    local uiModelRoot = self.UiModelGo.transform
    local panelRoleBGEffect = uiModelRoot:FindTransform("PanelRoleEffect" .. index)
    local activeAnim = panelRoleBGEffect:FindTransform("DimianStart")
    activeAnim:GetComponent(typeof(CS.UnityEngine.ParticleSystem)):Play()
end

function XUiBattleRoleRoom:RefreshFirstFightInfo()
    for i = 1, MAX_ROLE_COUNT do
        self["PanelFirstRole" .. i].gameObject:SetActiveEx(self.Team:GetFirstFightPos() == i)
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
    -- 刷新职业信息
    self:RefreshCharacterRImgType()
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
    local chapterName, stageName = XMVCA.XFuben:GetFubenNames(self.StageId)
    self.TxtChapterName.text = chapterName
    self.TxtStageName.text = stageName
end

function XUiBattleRoleRoom:RefreshRoleDetalInfo(isShow)
    if isShow == nil then isShow = self.Team:GetIsShowRoleDetailInfo() end
    
    local entityId
    local characterViewModel
    for pos = 1, 3 do
        self["CharacterInfo" .. pos].gameObject:SetActiveEx(true)

        local panelGeneralSkill = nil

        if self._PanelGeneralSkillList == nil then
            self._PanelGeneralSkillList = {}
        end
        panelGeneralSkill = self._PanelGeneralSkillList[pos]

        if not panelGeneralSkill then
            -- 检查是否开启效应选择
            local uiName = "GeneralSkillParent"..pos
            self[uiName].gameObject:SetActiveEx(false)
            panelGeneralSkill = require('XUi/XUiNewRoomSingle/XUiPanelRoleGeneralSkillList').New(self[uiName], self, self._IsEnableGeneralSkillSelection)
            panelGeneralSkill:Close()

            self._PanelGeneralSkillList[pos] = panelGeneralSkill
        end
        
        entityId = self.Team:GetEntityIdByTeamPos(pos)
        characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
        if characterViewModel then
            -- 机制信息
            local charId = XRobotManager.GetCharacterId(entityId)

            if self._IsEnableGeneralSkillSelection then
                panelGeneralSkill:Open()
                panelGeneralSkill:UpdateCharacterId(charId)
            end

            if isShow then
                self["TxtFight" .. pos].text = self.Proxy:GetRoleAbility(entityId)
                if self._IsEnableGeneralSkillSelection then
                    panelGeneralSkill:RefreshGeneralSkillIcons()
                end
            else
                if self._IsEnableGeneralSkillSelection then
                    panelGeneralSkill:ShowActiveGeneralSkillIcon()
                end
            end
        else
            self["CharacterInfo" .. pos].gameObject:SetActiveEx(false)
            if self._IsEnableGeneralSkillSelection then
                panelGeneralSkill:Close()
            end
        end
    end
end

-- 刷新机制提示
function XUiBattleRoleRoom:RefreshPanelRecommendGeneralSkill()
    self.PanelRecommendGeneralSkill.gameObject:SetActiveEx(false)

    if self.Proxy and self.Proxy.AOPOnRefreshRecommendGeneralSkillBefore then
        if self.Proxy:AOPOnRefreshRecommendGeneralSkillBefore(self, self.PanelRecommendGeneralSkill) then
            return
        end
    end
    
    local generalSkillIds = XMVCA.XFuben:GetGeneralSkillIds(self.StageId)
    if XTool.IsTableEmpty(generalSkillIds)  then
        return
    end

    local XUiPanelRecommendGeneralSkill = require("XUi/XUiNewRoomSingle/XUiPanelRecommendGeneralSkill")
    self.XUiPanelRecommendGeneralSkill = XUiPanelRecommendGeneralSkill.New(self.PanelRecommendGeneralSkill, self, self.StageId)
    self.XUiPanelRecommendGeneralSkill:Open()
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
    if self.Proxy:AOPHideCharacterLimits() then
        return
    end
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
            local professionIcon = XMVCA.XCharacter:GetNpcTypeIcon(types[index])
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

function XUiBattleRoleRoom:RefreshSupportToggle()
    local stageInfo = XMVCA.XFuben:GetStageInfo(self.StageId)
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

-- 刷新激活效应
function XUiBattleRoleRoom:RefreshGeneralSkill()
    if self._IsEnableGeneralSkillSelection then
        self.PanelGeneralSkill = require('XUi/XUiNewRoomSingle/XUiGridGeneralSkill').New(self.PaneGeneralSkill, self, self.StageId)
        self.PanelGeneralSkill:Open()
    else
        self.PaneGeneralSkill.gameObject:SetActiveEx(false)
    end
end

-- 刷新战力控制状态
function XUiBattleRoleRoom:RefreshFightControlState()
    local isStop = self.Proxy:AOPRefreshFightControlStateBefore(self)
    if isStop then return end
    local stageConfig = XMVCA.XFuben:GetStageCfg(self.StageId)
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

function XUiBattleRoleRoom:RefreshBtnEnterFight()
    local isEmpty = self.Team:GetIsEmpty()
    self.BtnEnterFight:SetDisable(isEmpty, not isEmpty)
    local proxyName = self.Proxy:GetBtnEnterName()
    if proxyName == nil or proxyName == "" then
        proxyName = CsXTextManager.GetText("UIBattleRoleRoomBtnEnter")
    end
    self.BtnEnterFight:SetName(proxyName)
end

--- 刷新机器人队伍混编显示
function XUiBattleRoleRoom:RefreshRobotTeamBlenderShow()
    if self._CanStageRobotBlendUse then
        for i = 1, 3 do
            ---@type XUiComponent.XUiStateControl
            local stateCtrl = self['TeamBlendNode'..i]
            local imgAdd = self['ImgAdd'..i]

            local isImgAddShow
            if imgAdd then
                isImgAddShow = imgAdd.gameObject.activeSelf
                imgAdd.gameObject:SetActiveEx(false)
            end
            
            if stateCtrl then
                local type = self._StageLineupConfig.Type[i] or 0

                if type == XEnumConst.FuBen.StageLineupType.Lock then
                    stateCtrl:ChangeState('Disable')
                elseif type == XEnumConst.FuBen.StageLineupType.RobotOnly then
                    stateCtrl:ChangeState('Lock')
                elseif type == XEnumConst.FuBen.StageLineupType.CharacterOnly then
                    stateCtrl:ChangeState('Change')
                else
                    stateCtrl:ChangeState('None')

                    if imgAdd then
                        imgAdd.gameObject:SetActiveEx(isImgAddShow)
                    end
                end
            end
        end
    end
end

function XUiBattleRoleRoom:CheckTeamMemberValid(stageId, team)
    local entityList = self.Proxy:GetValidEntityIdList(stageId, team)

    if not XTool.IsTableEmpty(entityList) then
        self.Team:CheckEntitiesValid(entityList)
    end
    
end

function XUiBattleRoleRoom:RefreshAnimationSet()
    if self.Proxy.CheckShowAnimationSet then
        self.BtnAnimationSet.gameObject:SetActiveEx(self.Proxy:CheckShowAnimationSet() and XMVCA.XFuben:IsFightCgEnable())
    else
        self.BtnAnimationSet.gameObject:SetActiveEx(false)
    end
end

function XUiBattleRoleRoom:OnBtnAnimationSetClick()
    XLuaUiManager.Open("UiPopupAnimationSet", self.Team)
end

function XUiBattleRoleRoom:GetBlendTeamDataByStageId(stageId, robotIds)
    ---@type XTeam
    local team = self.TeamManager.GetXTeamByStageIdEx(stageId)
    team:UpdateAutoSave(true)

    if team:GetIsEmpty() then
        -- 如果是空队伍，则直接覆盖
        team:UpdateEntityIds(XTool.CloneEx(robotIds, true))
    else
        -- 否则需要根据各个位置的权限和上阵角色进行校验和修正
        for k, v in pairs(robotIds) do
            local entityId = team:GetEntityIdByTeamPos(k)
            
            if self._StageLineupConfig.Type[k] == XEnumConst.FuBen.StageLineupType.Lock then
                -- 锁定的位置不能有角色
                if XTool.IsNumberValid(team:GetEntityIdByTeamPos(k)) then
                    team:UpdateEntityTeamPos(entityId, k, false)
                end
            elseif self._StageLineupConfig.Type[k] == XEnumConst.FuBen.StageLineupType.RobotOnly then
                -- 机器人位必须和配置一致
                if entityId ~= v then
                    team:UpdateEntityTeamPos(v, k, true)
                end
            elseif self._StageLineupConfig.Type[k] == XEnumConst.FuBen.StageLineupType.CharacterOnly then
                -- 角色位, 不是指定机器人或关联角色，则强制上机器人
                local characterId = XRobotManager.GetCharacterId(v)

                if XMVCA.XCharacter:CheckIsCharOrRobot(entityId) then
                    if (entityId ~= v and entityId ~= characterId) or (entityId == characterId and not XMVCA.XCharacter:IsOwnCharacter(characterId)) then
                        team:UpdateEntityTeamPos(v, k, true)
                    end
                else
                    team:UpdateEntityTeamPos(v, k, true)
                end
            end
        end
    end
    
    return team
end

return XUiBattleRoleRoom