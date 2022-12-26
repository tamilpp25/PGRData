local CsXTextManager = CS.XTextManager
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiBattleRoleRoom = XLuaUiManager.Register(XLuaUi, "UiBattleRoleRoom")
local MAX_ROLE_COUNT = 3
local LONG_TIMER = 1

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
    -- 重定义 end
    -- XTeam
    self.Team = nil
    self.StageId = nil
    self.Proxy = nil
    self.UiPanelRoleModels = nil
    self.LongClickTime = 0
    self.Camera = nil
    self.ChildPanelData = nil
    self:InitUiPanelRoleModels()
    self:RegisterUiEvents()
end

-- team : XTeam
function XUiBattleRoleRoom:OnStart(team, stageId, proxy)
    self.Camera = self.Transform:GetComponent("Canvas").worldCamera
    if proxy == nil then proxy = XUiBattleRoleRoomDefaultProxy end
    self.Team = team
    self.StageId = stageId
    self.Proxy = proxy.New()
    local isStop = self.Proxy:AOPOnStartBefore(self)
    if isStop then return end
    -- 关卡名字刷新
    self:RefreshStageName()
    self.BtnShowInfoToggle:SetButtonState(self.Team:GetIsShowRoleDetailInfo() 
        and XUiButtonState.Select or XUiButtonState.Normal)
    -- 注册自动关闭
    local openAutoClose, autoCloseEndTime, callback = self.Proxy:GetAutoCloseInfo()
    if openAutoClose then
        self:SetAutoCloseInfo(autoCloseEndTime, callback)
    end
    self.Proxy:AOPOnStartAfter(self)
end

function XUiBattleRoleRoom:OnEnable()
    XUiBattleRoleRoom.Super.OnEnable(self)
    -- 刷新角色模型
    self:RefreshRoleModels()
    -- 刷新角色特效
    self:RefreshRoleEffects()
    -- 刷新伙伴
    self:RefreshPartners()
    -- 刷新队长信息
    self:RefreshCaptainPosInfo()
    -- 设置首出信息
    self.FirstEnterBtnGroup:SelectIndex(self.Team:GetFirstFightPos())
    -- 刷新角色详细信息
    self:RefreshRoleDetalInfo()
    -- 角色限制提示
    self:RefreshRoleLimitTip()
    -- 设置子面板配置
    self.ChildPanelData = self.Proxy:GetChildPanelData()
    self:LoadChildPanelInfo()
    self:RegisterListeners()
end

function XUiBattleRoleRoom:OnDisable()
    XUiBattleRoleRoom.Super.OnDisable(self)
end

function XUiBattleRoleRoom:OnDestory()
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
            self[string.format("OnBtnChar%sClicked", pos)](self)
        end
    end
end

function XUiBattleRoleRoom:RegisterListeners()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnBeginBattleAutoRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnBeginBattleAutoRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.OnTeamPrefabSelect, self)
end

function XUiBattleRoleRoom:UnRegisterListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnBeginBattleAutoRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnBeginBattleAutoRemove, self)
    -- XEventManager.RemoveEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.OnTeamPrefabSelect, self)
end

function XUiBattleRoleRoom:OnBtnTeamPrefabClicked()
    XLuaUiManager.Open("UiRoomTeamPrefab", self.Team:GetCaptainPos()
        , self.Team:GetFirstFightPos()
        , self.Team:GetCharacterLimitType())
end

function XUiBattleRoleRoom:OnTeamPrefabSelect(teamData)
    self.Team:UpdateFromTeamData(teamData)
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
        self.Team:UpdateCaptianPos(newCaptainPos)
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
    XLuaUiManager.Open("UiBattleRoomRoleDetail"
        , self.StageId
        , self.Team
        , index
        , self.Proxy:GetRoleDetailProxy(), self.StageId)
end

function XUiBattleRoleRoom:OnBtnEnterFightClicked()
    local canEnterFight, errorTip = self.Proxy:GetIsCanEnterFight(self.Team)
    if not canEnterFight then
        XUiManager.TipError(errorTip)
        return
    end
    self.Proxy:EnterFight(self.Team, self.StageId)
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
                local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
                uiPanelRoleModel:UpdateRobotModel(sourceEntityId, robotConfig.CharacterId
                    , nil, robotConfig.FashionId, robotConfig.WeaponId)
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
    local entityId = 0
    local partner = nil
    local characterViewModel = nil
    local uiObjPartner
    local rImgParnetIcon = nil
    for pos = 1, MAX_ROLE_COUNT do
        entityId = self.Team:GetEntityIdByTeamPos(pos)
        partner = self.Proxy:GetPartnerByEntityId(entityId)
        characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
        uiObjPartner = self["UiObjPartner" .. pos]
        uiObjPartner.gameObject:SetActiveEx(characterViewModel ~= nil)
        rImgParnetIcon = uiObjPartner:GetObject("RImgType")
        rImgParnetIcon.gameObject:SetActiveEx(partner ~= nil)
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

function XUiBattleRoleRoom:RefreshRoleLimitTip()
    -- XFubenConfigs.CharacterLimitType
    local limitType = XFubenConfigs.GetStageCharacterLimitType(self.StageId)
    local isShow = XFubenConfigs.IsStageCharacterLimitConfigExist(limitType)
    self.PanelCharacterLimit.gameObject:SetActiveEx(isShow)
    if not isShow then return end
    -- 图标
    self.ImgCharacterLimit:SetSprite(XFubenConfigs.GetStageCharacterLimitImageTeamEdit(limitType))
    -- 文案
    local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(self.StageId)
    self.TxtCharacterLimit.text = XFubenConfigs.GetStageCharacterLimitTextTeamEdit(limitType
        , self.Team:GetCharacterType(), limitBuffId)
end

function XUiBattleRoleRoom:RefreshStageName()
    local chapterName, stageName = XDataCenter.FubenManager.GetFubenNames(self.StageId)
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

function XUiBattleRoleRoom:GetClickPosition()
    return XUiHelper.GetScreenClickPosition(self.Transform, self.Camera)
end

return XUiBattleRoleRoom