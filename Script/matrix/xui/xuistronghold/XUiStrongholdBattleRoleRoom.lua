-- 矿区为多编队，目前没有多编队用UiBattleRoleRoom的先例
-- 而且矿区编队XStrongholdTeam不继承XTeam，所以只能弄个新的BattleRoleRoom给矿区特殊显示

local CsXTextManager = CS.XTextManager
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")

---@class XUiStrongholdBattleRoleRoom : XLuaUi
local XUiStrongholdBattleRoleRoom = XLuaUiManager.Register(XLuaUi, "UiStrongholdBattleRoleRoom")

local MAX_ROLE_COUNT = 3
local LONG_TIMER = 1

function XUiStrongholdBattleRoleRoom:OnAwake()
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

---@param teamList XStrongholdTeam[]
function XUiStrongholdBattleRoleRoom:OnStart(teamList, teamId, groupId, pos)
    self.Camera = self.Transform:GetComponent("Canvas").worldCamera
    self.Team = teamList[teamId]:CreateTempTeam()
    self.TeamList = teamList
    self.GroupId = groupId
    self.TeamId = teamId
    self.Pos = pos
    if self.GroupId then
        self.StageId = XDataCenter.StrongholdManager.GetGroupStageId(self.GroupId, teamId)
    else
        -- 从队伍预设入口进去时没有stageId，直接用第一关的第一个关卡Id
        local groupIds = XStrongholdConfigs.GetGroupIds(1)
        self.StageId = XDataCenter.StrongholdManager.GetGroupStageId(groupIds[1], 1)
    end

    XEntityHelper.ClearErrorTeamEntityId(self.Team, function(entityId)
        return self:GetCharacterViewModelByEntityId(entityId) ~= nil
    end)

    -- 关卡名字刷新
    self:RefreshStageName()
    self.BtnShowInfoToggle:SetButtonState(self.Team:GetIsShowRoleDetailInfo() and XUiButtonState.Select or XUiButtonState.Normal)

    -- 设置不可编辑时按钮状态
    self.BtnTeamPrefab.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.PanelFirstInfo.gameObject:SetActiveEx(true)
    self.BtnShowInfoToggle.gameObject:SetActiveEx(true)
    self.BtnEnterFight:SetNameByGroup(0, XUiHelper.GetText("ConfirmText"))
end

function XUiStrongholdBattleRoleRoom:OnEnable()
    -- 重新生成XTeam
    self.Team = self.TeamList[self.TeamId]:CreateTempTeam()

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
    self:RefreshRoleDetalInfo()
end

function XUiStrongholdBattleRoleRoom:OnDisable()
    XMVCA.XFavorability:StopCv()
end

function XUiStrongholdBattleRoleRoom:OnDestroy()
    self:UnRegisterListeners()
    XMVCA.XFavorability:StopCv()

    for _, cuteRandomControllers in pairs(self.CuteRandomControllers) do
        if cuteRandomControllers then
            cuteRandomControllers:Stop()
        end
    end
end

function XUiStrongholdBattleRoleRoom:RegisterUiEvents()
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

function XUiStrongholdBattleRoleRoom:RegisterListeners()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnBeginBattleAutoRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnBeginBattleAutoRemove, self)
end

function XUiStrongholdBattleRoleRoom:UnRegisterListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnBeginBattleAutoRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnBeginBattleAutoRemove, self)
end

function XUiStrongholdBattleRoleRoom:OnBtnSupportToggleClicked(state)
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

function XUiStrongholdBattleRoleRoom:OnBtnTeamPrefabClicked()
    RunAsyn(function()
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
        XLuaUiManager.Open("UiRoomTeamPrefab", self.Team:GetCaptainPos(), self.Team:GetFirstFightPos(), self:GetCharacterLimitType(), nil, stageInfo.Type, nil, nil, self.StageId, self.Team)
        local signalCode, teamData = XLuaUiManager.AwaitSignal("UiRoomTeamPrefab", "RefreshTeamData", self)
        if signalCode ~= XSignalCode.SUCCESS then
            return
        end
        local playEntityId = 0
        local soundType = XEnumConst.Favorability.SoundEventType.MemberJoinTeam
        local captainEntityId = teamData.TeamData[teamData.CaptainPos]
        if captainEntityId ~= self.Team:GetCaptainPos() then
            playEntityId = captainEntityId
            soundType = XEnumConst.Favorability.SoundEventType.CaptainJoinTeam
        else
            for pos, newEntityId in ipairs(teamData.TeamData) do
                if self.Team:GetEntityIdByTeamPos(pos) ~= newEntityId then
                    playEntityId = newEntityId
                    soundType = XEnumConst.Favorability.SoundEventType.MemberJoinTeam
                    break
                end
            end
        end
        self.Team:UpdateFromTeamData(teamData)
        if playEntityId <= 0 then
            return
        end
        XMVCA.XFavorability:PlayCvByType(self:GetCharacterIdByEntityId(playEntityId), soundType)
    end)
end

-- 通过实体Id获取角色Id，基本上只要实现好GetCharacterViewModelByEntityId接口可不必处理该接口
-- return : number 角色id
function XUiStrongholdBattleRoleRoom:GetCharacterIdByEntityId(id)
    local viewModel = self:GetCharacterViewModelByEntityId(id)
    if viewModel == nil then return end
    return viewModel:GetId()
end

function XUiStrongholdBattleRoleRoom:OnBeginBattleAutoRemove()
    self:Remove()
end

function XUiStrongholdBattleRoleRoom:OnBtnLeaderClicked()
    local characterViewModelDic = {}
    for pos, entityId in pairs(self.Team:GetEntityIds()) do
        characterViewModelDic[pos] = self:GetCharacterViewModelByEntityId(entityId)
    end
    XLuaUiManager.Open("UiBattleRoleRoomCaptain", characterViewModelDic, self.Team:GetCaptainPos(), function(newCaptainPos)
        self.Team:UpdateCaptainPos(newCaptainPos)
        self:RefreshCaptainPosInfo()
    end)
end

-- val : 1 or 0 , 1是开启，0是关闭
function XUiStrongholdBattleRoleRoom:OnBtnShowInfoToggleClicked(val)
    self.Team:SaveIsShowRoleDetailInfo(val)
    self:RefreshRoleDetalInfo(val == 1)
end

function XUiStrongholdBattleRoleRoom:OnBtnChar1Clicked()
    self:OnBtnCharacterClicked(1)
end

function XUiStrongholdBattleRoleRoom:OnBtnChar2Clicked()
    self:OnBtnCharacterClicked(2)
end

function XUiStrongholdBattleRoleRoom:OnBtnChar3Clicked()
    self:OnBtnCharacterClicked(3)
end

function XUiStrongholdBattleRoleRoom:OnBtnCharacter1LongClicked(time)
    self:OnBtnCharacterLongClick(1, time)
end

function XUiStrongholdBattleRoleRoom:OnBtnCharacter2LongClicked(time)
    self:OnBtnCharacterLongClick(2, time)
end

function XUiStrongholdBattleRoleRoom:OnBtnCharacter3LongClicked(time)
    self:OnBtnCharacterLongClick(3, time)
end

function XUiStrongholdBattleRoleRoom:OnBtnCharacter1LongClickUp()
    self:OnBtnCharacterLongClickUp(1)
end

function XUiStrongholdBattleRoleRoom:OnBtnCharacter2LongClickUp()
    self:OnBtnCharacterLongClickUp(2)
end

function XUiStrongholdBattleRoleRoom:OnBtnCharacter3LongClickUp()
    self:OnBtnCharacterLongClickUp(3)
end

function XUiStrongholdBattleRoleRoom:OnBtnCharacterLongClick(index, time)
    -- 无实体直接不处理
    if self.Team:GetEntityIdByTeamPos(index) == 0 then return end
    self.LongClickTime = self.LongClickTime + time / 1000
    if self.LongClickTime > LONG_TIMER then
        self.ImgRoleRepace.gameObject:SetActiveEx(true)
        self.ImgRoleRepace.transform.localPosition = self:GetClickPosition()
    end
end

function XUiStrongholdBattleRoleRoom:OnBtnCharacterLongClickUp(index)
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
    self:ActiveSelectColorEffect(targetIndex)
    self:RefreshRoleInfos()
    self:RefreshPartners()
    self:RefreshRoleDetalInfo()
end

function XUiStrongholdBattleRoleRoom:OnBtnCharacterClicked(index)
    XLuaUiManager.Open("UiStrongholdRoomCharacterV2P6", self.TeamList, self.Team.Id, index, self.GroupId, index)
end

function XUiStrongholdBattleRoleRoom:OnBtnEnterFightClicked()
    self:Close()
end

function XUiStrongholdBattleRoleRoom:OnEnterSortBtnGroupClicked(index)
    if self.Team:GetFirstFightPos() ~= index then
        self.Team:UpdateFirstFightPos(index)
    end
    self:RefreshFirstFightInfo()
end

function XUiStrongholdBattleRoleRoom:InitUiPanelRoleModels()
    local uiModelRoot = self.UiModelGo.transform
    self.UiPanelRoleModels = {}
    self.CuteRandomControllers = {}
    for i = 1, MAX_ROLE_COUNT do
        self.UiPanelRoleModels[i] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelRoleModel" .. i), self.Name, nil, true, nil, true, true)
        self.CuteRandomControllers[i] = XSpecialTrainActionRandom.New()
    end
end

function XUiStrongholdBattleRoleRoom:RefreshRoleModels()
    local characterViewModel
    local entityId
    local sourceEntityId
    local uiPanelRoleModel
    local cuteRandomController

    for pos = 1, MAX_ROLE_COUNT do
        cuteRandomController = self.CuteRandomControllers[pos]
        uiPanelRoleModel = self.UiPanelRoleModels[pos]
        entityId = self.Team:GetEntityIdByTeamPos(pos)
        characterViewModel = self:GetCharacterViewModelByEntityId(entityId)
        self["ImgAdd" .. pos].gameObject:SetActiveEx(characterViewModel == nil)
        if characterViewModel then
            --先展示模型根节点，避免隐藏后，重新显示时，动画无法播放
            uiPanelRoleModel:ShowRoleModel()
            sourceEntityId = characterViewModel:GetSourceEntityId()
            if XRobotManager.CheckIsRobotId(sourceEntityId) then
                local robot2CharEntityId = XRobotManager.GetCharacterId(sourceEntityId) -- charId
                local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(robot2CharEntityId)

                -- 检测启用q版
                if self:CheckUseCuteModel() and XCharacterCuteConfig.CheckHasCuteModel(robot2CharEntityId) then
                    if isOwn then
                        uiPanelRoleModel:UpdateCuteModel(nil, robot2CharEntityId, nil, nil, nil, nil, true)
                    else
                        local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
                        uiPanelRoleModel:UpdateCuteModel(nil, robotConfig.CharacterId, nil, nil, nil, nil, true)
                    end
                else
                    if XRobotManager.CheckUseFashion(sourceEntityId) and isOwn then
                        local character2 = XDataCenter.CharacterManager.GetCharacter(robot2CharEntityId)
                        local robot2CharViewModel = character2:GetCharacterViewModel()
                        uiPanelRoleModel:UpdateCharacterModel(robot2CharEntityId, nil, nil, nil, nil, robot2CharViewModel:GetFashionId())
                    else
                        local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
                        uiPanelRoleModel:UpdateRobotModel(sourceEntityId, robotConfig.CharacterId, nil, robotConfig.FashionId, robotConfig.WeaponId, nil, nil, nil, "UiBattleRoleRoom")
                    end
                end
            else
                if self:CheckUseCuteModel() and XCharacterCuteConfig.CheckHasCuteModel(sourceEntityId) then
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
    if self:CheckUseCuteModel() then
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

-- 该界面是否启用q版模型 默认用愚人节检测
function XUiStrongholdBattleRoleRoom:CheckUseCuteModel()
    return XDataCenter.AprilFoolDayManager.IsInCuteModelTime()
end

function XUiStrongholdBattleRoleRoom:RefreshPartners()
    local entityId = 0
    local partner = nil
    local characterViewModel = nil
    local uiObjPartner
    local rImgParnetIcon = nil
    local rImgPlus = nil
    for pos = 1, MAX_ROLE_COUNT do
        entityId = self.Team:GetEntityIdByTeamPos(pos)
        partner = self:GetPartnerByEntityId(entityId)
        characterViewModel = self:GetCharacterViewModelByEntityId(entityId)
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

-- 根据实体Id获取伙伴实体
-- return : XPartner
function XUiStrongholdBattleRoleRoom:GetPartnerByEntityId(id)
    if id <= 0 then return nil end
    local result = nil
    if XEntityHelper.GetIsRobot(id) then
        result = XRobotManager.GetRobotPartner(id)
    else
        result = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(id)
    end
    return result
end

function XUiStrongholdBattleRoleRoom:RefreshRoleEffects()

end

-- 激活脚底选人特效
function XUiStrongholdBattleRoleRoom:ActiveSelectColorEffect(index)
    local uiModelRoot = self.UiModelGo.transform
    local panelRoleBGEffect = uiModelRoot:FindTransform("PanelRoleEffect" .. index)
    local activeAnim = panelRoleBGEffect:FindTransform("DimianStart")
    activeAnim:GetComponent(typeof(CS.UnityEngine.ParticleSystem)):Play()
end

function XUiStrongholdBattleRoleRoom:RefreshFirstFightInfo()
    for i = 1, MAX_ROLE_COUNT do
        self["PanelFirstEnterTag" .. i].gameObject:SetActiveEx(self.Team:GetFirstFightPos() == i)
    end
end

function XUiStrongholdBattleRoleRoom:RefreshCaptainPosInfo()
    local captainPos = self.Team:GetCaptainPos()
    local entityId = self.Team:GetEntityIdByTeamPos(captainPos)
    local characterViewModel = self:GetCharacterViewModelByEntityId(entityId)
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

function XUiStrongholdBattleRoleRoom:RefreshRoleInfos()
    -- 刷新角色模型
    self:RefreshRoleModels()
    -- 刷新角色特效
    self:RefreshRoleEffects()
    -- 刷新伙伴
    self:RefreshPartners()
    -- 刷新队长信息
    self:RefreshCaptainPosInfo()
end

function XUiStrongholdBattleRoleRoom:RefreshStageName()
    if XTool.IsNumberValid(self.GroupId) then
        local chapterName, stageName = self.FubenManager.GetFubenNames(self.StageId)
        self.TxtChapterName.text = chapterName
        self.TxtStageName.text = stageName
    else
        -- 队伍预设
        self.TxtChapterName.text = ""
        self.TxtStageName.text = XUiHelper.GetText("StrongholdTeamTitle", self.TeamId)
    end
end

function XUiStrongholdBattleRoleRoom:RefreshRoleDetalInfo(isShow)
    if isShow == nil then isShow = self.Team:GetIsShowRoleDetailInfo() end
    local entityId
    local characterViewModel
    for pos = 1, 3 do
        self["CharacterInfo" .. pos].gameObject:SetActiveEx(isShow)
        if isShow then
            entityId = self.Team:GetEntityIdByTeamPos(pos)
            characterViewModel = self:GetCharacterViewModelByEntityId(entityId)
            if characterViewModel then
                self["TxtFight" .. pos].text = self:GetRoleAbility(entityId)
                self["RImgType" .. pos]:SetRawImage(characterViewModel:GetProfessionIcon())
            else
                self["CharacterInfo" .. pos].gameObject:SetActiveEx(false)
            end
        end
    end
end

-- 刷新提示
function XUiStrongholdBattleRoleRoom:RefreshTipGrids()
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
            table.insert(viewModels, self:GetCharacterViewModelByEntityId(entityId))
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
    -- 与队伍比较
    for index, value in ipairs(viewModels) do
        if self:GetRoleAbility(teamEntityIds[index]) < (characterId2AbilityDicWithRobot[value:GetId()] or 0) then
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

function XUiStrongholdBattleRoleRoom:RefreshRoleLimitTip()
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

function XUiStrongholdBattleRoleRoom:GetTeamCharacterTypes()
    local result = {}
    for _, entityId in ipairs(self.Team:GetEntityIds()) do
        if entityId > 0 then
            table.insert(result, self:GetCharacterViewModelByEntityId(entityId):GetCharacterType())
        end
    end
    return result
end

function XUiStrongholdBattleRoleRoom:RefreshSupportToggle()
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

function XUiStrongholdBattleRoleRoom:PlayRightTopTips(message)
    self.PanelRightTopTip.gameObject:SetActiveEx(true)
    self.TxtRightTopTip.text = message
    self:PlayAnimation("PanelTipEnable")
end

-- 刷新战力控制状态
function XUiStrongholdBattleRoleRoom:RefreshFightControlState()
    local stageConfig = self.FubenManager.GetStageCfg(self.StageId)
    local teamAbilities = {}
    local viewModel = nil
    for pos, entityId in ipairs(self.Team:GetEntityIds()) do
        viewModel = self:GetCharacterViewModelByEntityId(entityId)
        if viewModel == nil then
            table.insert(teamAbilities, 0)
        else
            table.insert(teamAbilities, self:GetRoleAbility(entityId))
        end
    end
    if self.FightControl == nil then
        self.FightControl = XUiNewRoomFightControl.New(self.FightControlGo)
    end
    self.FightControl:UpdateInfo(stageConfig.FightControlId, teamAbilities, self:CheckStageForceConditionWithTeamEntityId(self.Team, self.StageId, false), self.StageId, self.Team:GetEntityIds())
end


-- 获取实体战力，如有特殊战力计算公式，可重写
-- return : number 战力
function XUiStrongholdBattleRoleRoom:GetRoleAbility(entityId)
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    return ag:GetCharacterHaveRobotAbilityById(entityId)
end

-- 根据实体id获取角色视图数据
-- return : XCharacterViewModel
function XUiStrongholdBattleRoleRoom:GetCharacterViewModelByEntityId(id)
    if id > 0 then
        local entity = nil
        if XEntityHelper.GetIsRobot(id) then
            entity = XRobotManager.GetRobotById(id)
        else
            entity = XDataCenter.CharacterManager.GetCharacter(id)
        end
        if entity == nil then
            XLog.Warning(string.format("找不到id%s的角色", id))
            return
        end
        return entity:GetCharacterViewModel()
    end
    return nil
end

-- 检查是否满足关卡配置的强制性条件
-- return : bool
function XUiStrongholdBattleRoleRoom:CheckStageForceConditionWithTeamEntityId(team, stageId, showTip)
    local fubenManager = XDataCenter.FubenManager
    local _, forceConditionIds = fubenManager.GetConditonByMapId(stageId)
    return fubenManager.CheckFightConditionByTeamData(forceConditionIds, team:GetEntityIds(), showTip)
end

function XUiStrongholdBattleRoleRoom:GetClickPosition()
    return XUiHelper.GetScreenClickPosition(self.Transform, self.Camera)
end

function XUiStrongholdBattleRoleRoom:GetCharacterLimitType()
    return XFubenConfigs.GetStageCharacterLimitType(self.StageId)
end

return XUiStrongholdBattleRoleRoom