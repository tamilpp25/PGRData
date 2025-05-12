local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XMonsterTeam = require("XEntity/XMonsterCombat/XMonsterTeam")
---@class XUiMonsterCombatBattlePrepare : XLuaUi
local XUiMonsterCombatBattlePrepare = XLuaUiManager.Register(XLuaUi, "UiMonsterCombatBattlePrepare")

function XUiMonsterCombatBattlePrepare:OnAwake()
    self.MonsterTeam = nil
    self.StageId = nil
    self.Proxy = nil
    self.ChallengeCount = nil
    self:InitUiPanelRoleModel()
    self:RegisterUiEvents()
    self:RegisterListeners()
end

-- 只要一个角色，默认使用队长位置的角色
---@param monsterTeam XMonsterTeam
function XUiMonsterCombatBattlePrepare:OnStart(stageId, monsterTeam, proxy, challengeCount)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    -- 队伍
    if monsterTeam == nil then
        monsterTeam = XMonsterTeam.New(XTime.GetServerNowTimestamp())
        monsterTeam:UpdateLocalSave(false)
    end
    if challengeCount == nil then
        challengeCount = 1
    end
    self.MonsterTeam = monsterTeam
    self.StageId = stageId
    local proxyInstance = nil -- 代理实例
    if proxy == nil then
        -- 使用默认的
        proxyInstance = XUiBattleRoleRoomDefaultProxy.New(monsterTeam, stageId)
    elseif not CheckIsClass(proxy) then
        -- 使用匿名类
        proxyInstance = CreateAnonClassInstance(proxy, XUiBattleRoleRoomDefaultProxy, monsterTeam, stageId)
    else
        -- 使用自定义类
        proxyInstance = proxy.New(monsterTeam, stageId)
    end
    self.Proxy = proxyInstance
    self.ChallengeCount = challengeCount
    -- 注册自动关闭
    local openAutoClose, autoCloseEndTime, callback = self.Proxy:GetAutoCloseInfo()
    if openAutoClose then
        self:SetAutoCloseInfo(autoCloseEndTime, callback)
    end
    self.Proxy:AOPOnStartAfter(self)
end

function XUiMonsterCombatBattlePrepare:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshRoleInfos()
    -- 刷新角色详细信息
    self:RefreshRoleDetalInfo()
    -- 设置进入战斗按钮状态
    local isEmpty = self.MonsterTeam:GetIsEmpty()
    self.BtnEnterFight:SetDisable(isEmpty, not isEmpty)
    self.Proxy:AOPOnEnableAfter(self)
end

function XUiMonsterCombatBattlePrepare:OnDisable()
    self.Super.OnDisable(self)
    XMVCA.XFavorability:StopCv()
end

function XUiMonsterCombatBattlePrepare:OnDestroy()
    self.Super.OnDestroy(self)
    self:UnRegisterListeners()
    XMVCA.XFavorability:StopCv()
end

function XUiMonsterCombatBattlePrepare:InitUiPanelRoleModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    ---@type XUiPanelRoleModel
    self.UiPanelRoleModel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true, true)
end

function XUiMonsterCombatBattlePrepare:RefreshRoleInfos()
    -- 刷新角色模型
    self:RefreshRoleModel()
    -- 刷新伙伴
    self:RefreshPartner()
    self.Proxy:AOPRefreshRoleInfosAfter(self)
end

function XUiMonsterCombatBattlePrepare:RefreshRoleModel()
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    local modelCb = function()
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end
    local entityId = self.MonsterTeam:GetCaptainPosEntityId()
    ---@type XCharacterViewModel
    local characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
    self["ImgAdd2"].gameObject:SetActiveEx(characterViewModel == nil)
    if characterViewModel then
        self.UiPanelRoleModel:ShowRoleModel()
        local sourceEntityId = characterViewModel:GetSourceEntityId()
        if XRobotManager.CheckIsRobotId(sourceEntityId) then
            local robot2CharEntityId = XRobotManager.GetCharacterId(sourceEntityId)
            local isOwn = XMVCA.XCharacter:IsOwnCharacter(robot2CharEntityId)
            if XRobotManager.CheckUseFashion(sourceEntityId) and isOwn then
                local character2 = XMVCA.XCharacter:GetCharacter(robot2CharEntityId)
                local robot2CharViewModel = character2:GetCharacterViewModel()
                self.UiPanelRoleModel:UpdateCharacterModel(robot2CharEntityId, self.PanelRoleModel, self.Name, modelCb, nil, robot2CharViewModel:GetFashionId())
            else
                local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
                self.UiPanelRoleModel:UpdateRobotModel(sourceEntityId, robotConfig.CharacterId
                , nil, robotConfig.FashionId, robotConfig.WeaponId, modelCb, nil, self.PanelRoleModel, self.Name)
            end
        else
            self.UiPanelRoleModel:UpdateCharacterModel(sourceEntityId, self.PanelRoleModel, self.Name, modelCb, nil, characterViewModel:GetFashionId())
        end
    else
        self.UiPanelRoleModel:HideRoleModel()
    end
end

function XUiMonsterCombatBattlePrepare:RefreshPartner()
    local isStop = self.Proxy:AOPOnRefreshPartnersBefore(self)
    if isStop then
        return
    end
    local entityId = self.MonsterTeam:GetCaptainPosEntityId()
    ---@type XPartner
    local partner = self.Proxy:GetPartnerByEntityId(entityId)
    ---@type XCharacterViewModel
    local characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
    self.CharacterPets2.gameObject:SetActiveEx(characterViewModel ~= nil and not XUiManager.IsHideFunc)
    local rImgParnetIcon = self.CharacterPets2:GetObject("RImgType")
    rImgParnetIcon.gameObject:SetActiveEx(partner ~= nil)
    local rImgPlus = self.CharacterPets2:GetObject("Img+")
    rImgPlus.gameObject:SetActiveEx(not partner)
    if partner then
        rImgParnetIcon:SetRawImage(partner:GetIcon())
    end
end

function XUiMonsterCombatBattlePrepare:RefreshRoleDetalInfo()
    self.CharacterInfo2.gameObject:SetActiveEx(true)
    local entityId = self.MonsterTeam:GetCaptainPosEntityId()
    local characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
    if characterViewModel then
        self.TxtFight2.text = self.Proxy:GetRoleAbility(entityId)
        self.RImgType2:SetRawImage(characterViewModel:GetProfessionIcon())
        self.PanelFirstRole2.gameObject:SetActiveEx(true)
    else
        self.CharacterInfo2.gameObject:SetActiveEx(false)
        self.PanelFirstRole2.gameObject:SetActiveEx(false)
    end
end

function XUiMonsterCombatBattlePrepare:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnterFight, self.OnBtnEnterFightClick)
    -- 角色点击
    XUiHelper.RegisterClickEvent(self, self.BtnChar2, self.OnBtnChar2Click)
    -- 宠物加号点击
    self.CharacterPets2:GetObject("BtnClick").CallBack = function()
        local entityId = self.MonsterTeam:GetCaptainPosEntityId()
        if XEntityHelper.GetIsRobot(entityId) then
            XUiManager.TipErrorWithKey("RobotParnerTips")
            return
        end
        XDataCenter.PartnerManager.GoPartnerCarry(self.MonsterTeam:GetCaptainPosEntityId(), false)
    end
    -- 怪物点击
    XUiHelper.RegisterClickEvent(self, self.BtnMonster1, self.OnBtnMonster1Click)
    XUiHelper.RegisterClickEvent(self, self.BtnMonster2, self.OnBtnMonster2Click)
end

function XUiMonsterCombatBattlePrepare:RegisterListeners()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnBeginBattleAutoRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnBeginBattleAutoRemove, self)
end

function XUiMonsterCombatBattlePrepare:UnRegisterListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnBeginBattleAutoRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnBeginBattleAutoRemove, self)
end

function XUiMonsterCombatBattlePrepare:OnBeginBattleAutoRemove()
    self:Remove()
end

function XUiMonsterCombatBattlePrepare:OnBtnBackClick()
    self:Close()
end

function XUiMonsterCombatBattlePrepare:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 进入战斗
function XUiMonsterCombatBattlePrepare:OnBtnEnterFightClick()
    local canEnterFight, errorTip = self.Proxy:GetIsCanEnterFight(self.MonsterTeam, self.StageId)
    if not canEnterFight then
        if errorTip then
            XUiManager.TipError(errorTip)
        end
        return
    end
    local isAssist = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.AssistSwitch .. XPlayer.Id) == 1
    self.Proxy:EnterFight(self.MonsterTeam, self.StageId, self.ChallengeCount, isAssist)
end

-- 角色点击
function XUiMonsterCombatBattlePrepare:OnBtnChar2Click()
    self:OnBtnCharacterClicked(self.MonsterTeam:GetCaptainPos())
end

function XUiMonsterCombatBattlePrepare:OnBtnCharacterClicked(index)
    local isStop = self.Proxy:AOPOnCharacterClickBefore(self, index)
    if isStop then
        return
    end
    RunAsyn(function()
        local oldEntityId = self.MonsterTeam:GetEntityIdByTeamPos(index)
        XLuaUiManager.Open("UiBattleRoomRoleDetail"
        , self.StageId
        , self.MonsterTeam
        , index
        , self.Proxy:GetRoleDetailProxy())
        local signalCode, newEntityId = XLuaUiManager.AwaitSignal("UiBattleRoomRoleDetail", "UpdateEntityId", self)
        if signalCode ~= XSignalCode.SUCCESS then
            return
        end
        if oldEntityId == newEntityId then
            return
        end
        if self.MonsterTeam:GetEntityIdByTeamPos(index) <= 0 then
            return
        end
        -- 播放音效
        local soundType = XEnumConst.Favorability.SoundEventType.MemberJoinTeam
        if self.MonsterTeam:GetCaptainPos() == index then
            soundType = XEnumConst.Favorability.SoundEventType.CaptainJoinTeam
        end
        XMVCA.XFavorability:PlayCvByType(self.Proxy:GetCharacterIdByEntityId(newEntityId), soundType)
    end)
end

function XUiMonsterCombatBattlePrepare:OnBtnMonster1Click()
    self:OnBtnMonsterClicked(1)
end

function XUiMonsterCombatBattlePrepare:OnBtnMonster2Click()
    self:OnBtnMonsterClicked(2)
end

function XUiMonsterCombatBattlePrepare:OnBtnMonsterClicked(index)
    RunAsyn(function()
        self.PlayMonsterAnimId = 0
        local oldMonsterId = self.MonsterTeam:GetMonsterIdByPos(index)
        XLuaUiManager.Open("UiMonsterCombatRoleList"
        , XMonsterCombatConfigs.MonsterInterfaceType.Battle
        , self.StageId
        , self.MonsterTeam
        , index)
        local signalCode, newMonsterId = XLuaUiManager.AwaitSignal("UiMonsterCombatRoleList", "UpdateMonsterId", self)
        if signalCode ~= XSignalCode.SUCCESS then
            return
        end
        if oldMonsterId == newMonsterId then
            return
        end
        if self.MonsterTeam:GetMonsterIdByPos(index) <= 0 then
            return
        end
        -- 保存更改后的怪物Id 用于动画播放
        self.PlayMonsterAnimId = self.MonsterTeam:GetMonsterIdByPos(index)
    end)
end

return XUiMonsterCombatBattlePrepare