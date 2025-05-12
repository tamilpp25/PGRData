local XUiPlanetBattleMainGridRole = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetBattleMainGridRole")
local XPanelPlanetWeather = require("XUi/XUiPlanet/Weather/XPanelPlanetWeather")
local XPanelPlanetCard = require("XUi/XUiPlanet/Build/XPanelPlanetCard")
local XUiPlanetInBuildPanel = require("XUi/XUiPlanet/Build/XUiPlanetInBuildPanel")
local XGridPlanetBattleMainProp = require("XUi/XUiPlanet/Explore/View/Prop/XGridPlanetBattleMainProp")
local XUiButton = require("XUi/XUiCommon/XUiButton")
local XUiPlanetBattleMainTarget = require("XUi/XUiPlanet/Explore/View/Target/XUiPlanetBattleMainTarget")
local XPlanetCharacter = require("XEntity/XPlanet/Explore/XPlanetCharacter")
local XPlanetBoss = require("XEntity/XPlanet/Explore/XPlanetBoss")

local UiButtonState = CS.UiButtonState
local TIME_SCALE = XPlanetExploreConfigs.TIME_SCALE

---@class XUiPlanetBattleMain:XLuaUi
local XUiPlanetBattleMain = XLuaUiManager.Register(XLuaUi, "UiPlanetBattleMain")

function XUiPlanetBattleMain:Ctor()
    ---@type XPlanetStageScene
    self._Scene = false

    ---@type XPlanetRunningExplore
    self._Explore = XDataCenter.PlanetExploreManager.CreateExplore()

    self._RoleList = {}
    self._ItemList = {}
    ---@type XUiButton
    self._ButtonBoss = false

    self._Timer = false
    self._TimerMoneyGain = false
    self._BossOnShow = false
    self._BossEntityIdOnShow = false
    self._IsCamFollowLeader = false
    ---初始是否隐藏ui
    self._IsHideUi = false

    self._FightingPowerBoss = 0

    self._TimeOnEnalbe = 0
    self._DurationIgnoreClickExit = 1
end

function XUiPlanetBattleMain:OnAwake()
    self:RegisterClickEvent(self.BtnExit, self._OnClickExit)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_MONSTER, self.OnBossChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_PAUSE, self.UpdateBtnPlay, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_STAGE_WEATHER, self.UpdateWeather, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_IN_BUILD, self.OpenBuildModePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_STAGE, self.Update, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_PAUSE_RUNNING, self.ExplorePause, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_RESUME_RUNNING, self.ExploreResume, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_SET_CAPTAIN, self.SetCaptain, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_REMOVE_BOSS, self.OnBossRemoved, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_CHARACTER_ENTITY, self.UpdateRole, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_BOSS_ENTITY, self.UpdateBoss, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_CHARACTER, self.UpdateFightingPower, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_ITEM, self.UpdateProp, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_ON_CHARACTER_ENTITY_UPDATE, self.UpdateFightingPower, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_ON_CHARACTER_ENTITY_UPDATE, self.UpdateRole, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_ON_BOSS_MODEL_CREATE, self.PlayBossCam, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_HIDE_EXPLORE_UI, self.HideUi, self)
    self:AddGuideEventListener()

    self.PanelItems = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelRoot/PanelItems", "RectTransform")
    self.GridItem.gameObject:SetActiveEx(false)
    self:RegisterClickEvent(self.BtnGuardian, self._OnClickBoss)
    self._ButtonBoss = XUiButton.New(self.BtnGuardian)
    ---@type XUiPlanetBattleMainTarget
    self._PanelTarget = XUiPlanetBattleMainTarget.New(self.ImgTarget)
    self._PanelTarget.GameObject:SetActiveEx(true)
    self:UpdateBtnTarget()
    self._Explore:SetRootUi(self)

    self.EffectArrive = self.EffectArrive or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelRoot/BtnGuardian/EffectArrive", "RectTransform")
    self.RImgSummonBg = self.RImgSummonBg or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelRoot/BtnGuardian/RImgSummonBg", "RectTransform")
end

function XUiPlanetBattleMain:OnStart()
    XDataCenter.PlanetManager.SceneOpen(XPlanetConfigs.SceneOpenReason.UiPlanetBattleMain)
    XDataCenter.PlanetManager.CloseLoading()
    self.VeiwModel = XDataCenter.PlanetManager.GetViewModel()
    self._Scene = XDataCenter.PlanetManager.GetPlanetStageScene()
    self._Scene:RegisterUiEventListener(function(...)
        self:OnGameObjectClick(...)
    end, XPlanetConfigs.SceneUiEventType.OnClick)

    self:InitUi()

    self:StartGame()
    if not self._Explore:IsPlayingMovie() then
        self._Scene:UpdateCameraInStage(true, true)
    end

    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            if not self.GameObject:Exist() then
                return
            end
            self._Explore:Update(CS.UnityEngine.Time.deltaTime)
            self._Scene:CameraUpdate(self._Explore, CS.UnityEngine.Time.deltaTime * self._Explore:GetTimeScale())
        end, 0)
    end
    self._Explore:OnStart()
end

function XUiPlanetBattleMain:OnRelease()
    self.Super.OnRelease(self)
    self._Model = false
    XDataCenter.PlanetManager.ExitStage()
end

function XUiPlanetBattleMain:OnEnable()
    self._TimeOnEnalbe = CS.UnityEngine.Time.unscaledTime
    local stageData = XDataCenter.PlanetManager.GetStageData()
    if stageData:GetStageId() == 0 then
        return
    end

    self:UpdateMoney()
    self:UpdateProp()
    self._PanelTarget:OnEnalbe()
    self._Explore:OnEnable()
    self:UpdateFightingPower()
    self:RefreshBuildCardPanel()
end

function XUiPlanetBattleMain:OnDisable()
    self._PanelTarget:OnDisable()
    self._Explore:OnDisable()
end

function XUiPlanetBattleMain:OnDestroy()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end

    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_MONSTER, self.OnBossChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_PAUSE, self.UpdateBtnPlay, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_STAGE_WEATHER, self.UpdateWeather, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_IN_BUILD, self.OpenBuildModePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_STAGE, self.Update, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_PAUSE_RUNNING, self.ExplorePause, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_RESUME_RUNNING, self.ExploreResume, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_SET_CAPTAIN, self.SetCaptain, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_REMOVE_BOSS, self.OnBossRemoved, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_CHARACTER_ENTITY, self.UpdateRole, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_BOSS_ENTITY, self.UpdateBoss, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_CHARACTER, self.UpdateFightingPower, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_ITEM, self.UpdateProp, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_ON_CHARACTER_ENTITY_UPDATE, self.UpdateRole, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_ON_CHARACTER_ENTITY_UPDATE, self.UpdateFightingPower, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_ON_BOSS_MODEL_CREATE, self.PlayBossCam, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_HIDE_EXPLORE_UI, self.HideUi, self)
    self:RemoveGuideEventListener()
    XDataCenter.PlanetManager.SceneRelease(XPlanetConfigs.SceneOpenReason.UiPlanetBattleMain)

    if self._TimerMoneyGain then
        XScheduleManager.UnSchedule(self._TimerMoneyGain)
        self._TimerMoneyGain = false
    end
    XDataCenter.PlanetExploreManager.DestroyExplore()
end

function XUiPlanetBattleMain:OnGetEvents()
    return {
        XEventId.EVENT_GUIDE_START,
        XEventId.EVENT_GUIDE_END,
    }
end

function XUiPlanetBattleMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_GUIDE_START then
        self:OnGuideStart(...)
    elseif evt == XEventId.EVENT_GUIDE_END then
        self:OnGuideEnd()
    end
end

function XUiPlanetBattleMain:StartGame()
    ---@type XPlanetStageData
    local stageData = XDataCenter.PlanetManager.GetStageData()
    local characterData = stageData:GetCharacterData()
    local monsterData = stageData:GetMonsterData()

    local data = {
        CharacterData = characterData,
        MonsterData = monsterData
    }
    self._Explore:SetData(data)
    self._Explore:SetScene(self._Scene)
    self._Explore:SetBubbleManager()
    self._Explore:StartSync()
    self._Explore:Pause(XPlanetExploreConfigs.PAUSE_REASON.PLAYER)
    self:UpdateBtnPlay()
end

function XUiPlanetBattleMain:UpdateMoney()
    local itemId = XDataCenter.ItemManager.ItemId.PlanetRunningStageCoin
    local amount = XDataCenter.PlanetManager.GetStageData():GetCoin()
    self.ImgMoney:SetSprite(XItemConfigs.GetItemIconById(itemId))
    self.TxtMoney.text = amount
end

--region money
function XUiPlanetBattleMain:InitMoney()
    self:RegisterClickEvent(self.BtnMoney, function()
        XLuaUiManager.Open("UiPlanetPropertyResources", {
            XDataCenter.ItemManager.ItemId.PlanetRunningStageCoin,
            XDataCenter.ItemManager.ItemId.PlanetRunningTalent,
        })
    end)
    self:UpdateMoney()
    self.TxtMoneyAdd.gameObject:SetActiveEx(false)
    self:BindViewModelPropertyToObj(XDataCenter.PlanetManager.GetStageData(), function()
        local amountBefore = tonumber(self.TxtMoney.text) or 0
        local deltaCount = XDataCenter.PlanetManager.GetStageData():GetCoin() - amountBefore
        self:UpdateMoney()
        if deltaCount ~= 0 then
            self.TxtMoneyAdd.text = deltaCount > 0 and "+" .. deltaCount or deltaCount
            self.TxtMoneyAdd.color = XPlanetConfigs.GetMoneyChangeColor(deltaCount)
            self:PlayAnimationMoneyGain()
        end
        if deltaCount > 0 then
            self:CheckIsFirstGetMoney()
        end
        -- 刷新建造卡牌
        self:RefreshBuildCardPanel()
    end, "_Coin")
end

function XUiPlanetBattleMain:PlayAnimationMoneyGain()
    self.TxtMoneyAdd.gameObject:SetActiveEx(true)
    self:PlayAnimationWithMask("TxtMoneyAddEnable", function()
        self.TxtMoneyAdd.gameObject:SetActiveEx(false)
    end)
end
--endregion money

--region click gameObject
function XUiPlanetBattleMain:OnGameObjectClick(eventData)
    if XTool.UObjIsNil(eventData.pointerEnter) then
        return
    end
    local transform = eventData.pointerEnter.transform.parent.transform
    if transform then
        local entity = self._Explore:FindEntityByTransform(transform)
        self:OnClickEntity(entity)
    end
end

---@param entitySelected XPlanetRunningExploreEntity
function XUiPlanetBattleMain:OnClickEntity(entitySelected)
    if not entitySelected then
        return
    end
    if entitySelected.Camp.CampType == XPlanetExploreConfigs.CAMP.PLAYER then
        local entities = self._Explore:GetCharacterAlive()
        ---@type XPlanetCharacter[]
        local characterList = {}
        local characterSelected = false
        for i = 1, #entities do
            local entity = entities[i]
            local characterId = entity.Data.IdFromConfig
            ---@type XPlanetCharacter
            local character = XPlanetCharacter.New(characterId)
            character:SetUid(entity.Id)
            character:SetAlive(true)
            characterList[#characterList + 1] = character
        end
        for i = 1, #characterList do
            local character = characterList[i]
            if character:GetUid() == entitySelected.Id then
                characterSelected = character
            end
        end

        if characterSelected then
            XDataCenter.PlanetManager.RequestStageOpenRoleDetial(characterSelected, characterList)
        end
        return
    end

    if entitySelected.Camp.CampType == XPlanetExploreConfigs.CAMP.BOSS then
        local gridId = entitySelected.Move.TileIdCurrent
        local entities = self._Explore:GetBossListByGrid(gridId)
        ---@type XPlanetBoss[]
        local bossList = {}
        ---@type XPlanetBoss
        local bossSelected = false
        for i = 1, #entities do
            local entity = entities[i]
            local bossId = entity.Data.IdFromConfig
            for j = 1, entity.Data.Amount do
                ---@type XPlanetBoss
                local boss = XPlanetBoss.New(bossId)
                boss:SetUid(entity.Id)
                boss:SetAlive(true)
                boss:SetIdFromServer(entity.Data.IdFromServer)
                boss:SetGridId(gridId)
                boss:SetGroupIdByStage()
                bossList[#bossList + 1] = boss
            end
        end
        for i = 1, #bossList do
            local boss = bossList[i]
            if boss:GetUid() == entitySelected.Id then
                bossSelected = boss
                break
            end
        end
        if bossSelected and bossSelected:IsSpecialBoss() then
            self:_OnClickBoss(nil, entitySelected.Id)
            return
        end
        if bossSelected then
            XDataCenter.PlanetManager.RequestStageOpenMonsterDetial(bossSelected, bossList)
        end
        return
    end
end
--endregion click gameObject

function XUiPlanetBattleMain:InitUi()
    self:RegisterClickEvent(self.ToggleQuickBuild, self._OnClickQuickBuild)
    self.ToggleQuickBuild.isOn = XDataCenter.PlanetManager.GetStageQuickBuildMode()
    self:RegisterClickEvent(self.BtnClickGuardian, self._OnClickBoss)
    self:RegisterClickEvent(self.BtnLocation, self._OnClickBtnLocationClick)
    self:RegisterClickEvent(self.BtnLocation02, self._OnClickBtnLocationClick)
    self:RegisterClickEvent(self.BtnScreenShot, self._OnClickBtnScreenShot)
    self:RegisterClickEvent(self.BtnHide, self._OnClickBtnHideShot)
    self:InitMoney()
    self:UpdateBoss()
    self.PanelWeather = XPanelPlanetWeather.New(self, self.BtnWeather, false)
    self.PanelBuildCardPanel = XPanelPlanetCard.New(self, self.PanelCard, false)
    self.PanelInBuildMenu = XUiPlanetInBuildPanel.New(self, self.PanelMenu, false)
    self.PanelInBuildMenu:SetCallBack(nil, function()
        self.PanelBottom.gameObject:SetActiveEx(true)
    end)
    self:RegisterClickEvent(self.BtnTarget, self._OnClickTarget)
    self:RegisterClickEvent(self.BtnDepart, self._OnClickPlay)
    self:RegisterClickEvent(self.BtnPause, self._OnClickPlay)
    self:UpdateBtnPlay()

    self:RegisterClickEvent(self.BtnDoubleaccel01, self._OnClickTimeScale)
    self:RegisterClickEvent(self.BtnDoubleaccel02, self._OnClickTimeScale)
    self:UpdateTimeScale()

    self.ToggleSkip.isOn = self._Explore:IsSkipFight()
    self:RegisterClickEvent(self.ToggleSkip, self._OnClickSkipFight)

    -- 道具
    --self.GridItem = XGridPlanetBattleMainProp.New(self.GridItem, self)
    --self.PanelItem

    self.PanelMenu.gameObject:SetActiveEx(false)
    self.BtnLocation.gameObject:SetActiveEx(not self._Scene:CheckCameraIsFollowMode() and not self:CheckIsGuideStage())
    self.BtnLocation02.gameObject:SetActiveEx(self._Scene:CheckCameraIsFollowMode() and not self:CheckIsGuideStage())
    self.BtnScreenShot.gameObject:SetActiveEx(not self._IsHideUi and not self:CheckIsGuideStage())
    self.BtnHide.gameObject:SetActiveEx(self._IsHideUi and not self:CheckIsGuideStage())

    self.GridRole.gameObject:SetActiveEx(false)
    self:UpdateRole()

    self:UpdateWeather()
    self:UpdateScreenShow()

    -- 目标面板
    if not self.Tri1 then
        self.Tri1 = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelBtnLeft/Tri1")
    end
end

function XUiPlanetBattleMain:_OnClickQuickBuild()
    local isOn = self.ToggleQuickBuild.isOn
    XDataCenter.PlanetManager.SetStageQuickBuildMode(isOn)
end

function XUiPlanetBattleMain:OpenBuildModePanel()
    self.PanelBottom.gameObject:SetActiveEx(false)
    self.PanelInBuildMenu:Open()
end

function XUiPlanetBattleMain:_OnClickBtnLocationClick()
    if self.PanelInBuildMenu:IsOpen() or self._Explore:IsPause(XPlanetExploreConfigs.PAUSE_REASON.BUILD) then
        return
    end
    local roleTransform = self._Explore:GetCaptainTransform()
    if self._IsCamFollowLeader or not roleTransform then
        self._IsCamFollowLeader = false
        self._Scene:UpdateCameraInStage()
    else
        local cam = XDataCenter.PlanetManager.GetCamera(XPlanetConfigs.GetCamFollowRole())
        self._IsCamFollowLeader = true
        self._Explore:Pause(XPlanetExploreConfigs.PAUSE_REASON.FOLLOW)
        self._Scene:SetCameraFollow(roleTransform, cam, function()
            self._Explore:Resume(XPlanetExploreConfigs.PAUSE_REASON.FOLLOW)
        end)
    end
    self:UpdateUiInCamFollow()
    self.BtnLocation.gameObject:SetActiveEx(not self._Scene:CheckCameraIsFollowMode() and not self:CheckIsGuideStage())
    self.BtnLocation02.gameObject:SetActiveEx(self._Scene:CheckCameraIsFollowMode() and not self:CheckIsGuideStage())
end

function XUiPlanetBattleMain:_OnClickBtnScreenShot()
    self._IsHideUi = true
    self:PlayUiActiveAnim()
end

function XUiPlanetBattleMain:_OnClickBtnHideShot()
    self._IsHideUi = false
    self:PlayUiActiveAnim()
end

function XUiPlanetBattleMain:UpdateScreenShow()
    self.PanelRoot.gameObject:SetActiveEx(not self._IsHideUi)
    self.BtnTarget.gameObject:SetActiveEx(not self._IsHideUi)
    self.BtnScreenShot.gameObject:SetActiveEx(not self._IsHideUi and not self:CheckIsGuideStage())
    self.BtnLocation.gameObject:SetActiveEx(not self._IsHideUi and not self._Scene:CheckCameraIsFollowMode() and not self:CheckIsGuideStage())
    self.BtnLocation02.gameObject:SetActiveEx(not self._IsHideUi and self._Scene:CheckCameraIsFollowMode() and not self:CheckIsGuideStage())
    self.ImgTarget.gameObject:SetActiveEx(not self._IsHideUi)
end

function XUiPlanetBattleMain:PlayUiActiveAnim()
    self.BtnScreenShot.gameObject:SetActiveEx(not self._IsHideUi and not self:CheckIsGuideStage())
    self.BtnHide.gameObject:SetActiveEx(self._IsHideUi and not self:CheckIsGuideStage())
    if self._IsHideUi then
        self:PlayAnimationWithMask("UiHide", handler(self, self.UpdateScreenShow))
    else
        self:UpdateScreenShow()
        self:PlayAnimationWithMask("UiEnable")
    end
end

function XUiPlanetBattleMain:UpdateUiInCamFollow()
    self.PanelBottom.gameObject:SetActiveEx(not self._IsCamFollowLeader)
    if not self._IsCamFollowLeader then
        self.PanelBuildCardPanel:UpdateDynamicTable()
    end
end

function XUiPlanetBattleMain:UpdateBoss()
    ---@type XPlanetBoss
    local bossOnShow = false
    local entity = false
    local progress = 0
    self._BossEntityIdOnShow = false
    local stageData = XDataCenter.PlanetManager.GetStageData()

    -- 当前有boss在场
    local stage = XDataCenter.PlanetExploreManager.GetStage()
    local bossList = stage:GetBoss()
    for i = 1, #bossList do
        local boss = bossList[i]
        local bossId = boss:GetBossId()
        entity = self._Explore:FindBoss(bossId)
        if entity then
            boss:SetAlive(true)
            bossOnShow = boss
            progress = 1
            break
        end
    end

    -- 找下一个未出生的boss
    if not bossOnShow then
        local round = stageData:GetCycle() - 1
        local progressPerRound = stage:GetProgressPerRound()
        local progressCurrent = progressPerRound * round
        for i = 1, #bossList do
            local boss = bossList[i]
            local bossId = boss:GetBossId()
            if not stageData:IsKillBossId(bossId) then
                local progress2Born = boss:GetProgress2Born()
                boss:SetAlive(false)
                bossOnShow = boss
                if progress2Born > 0 then
                    progress = progressCurrent / progress2Born
                else
                    progress = 1
                end
                break
            end
        end
    end

    if bossOnShow then
        self._ButtonBoss:SetRawImage("ImgRole/RImgRole", bossOnShow:GetIcon())
        self._ButtonBoss:SetFillAmount("ImgBarBg/ImgBarBossProgress", progress)
        local isAlive = progress >= 1
        self._ButtonBoss:SetActive("TxtArrive", isAlive)
        self.EffectArrive.gameObject:SetActiveEx(isAlive)
        self._ButtonBoss:SetText("TxtStrength/TxtStrengthNum", bossOnShow:GetFightingPower())

        self._BossOnShow = bossOnShow
        self._BossEntityIdOnShow = entity and entity.Id or false

        local powerRecommend = bossOnShow:GetFightingPowerRecommend()
        self._FightingPowerBoss = powerRecommend
        self:UpdateFightingPower()
    end
end

function XUiPlanetBattleMain:UpdateFightingPower()
    local entities = self._Explore:GetCharacterAlive()
    XDataCenter.PlanetExploreManager.UpdateCharacterListAttrByClient(entities)
    local powerPlayer = XPlanetExploreConfigs.GetPlayerFightingPower(entities)
    local powerRecommend = self._FightingPowerBoss
    if powerPlayer >= powerRecommend then
        self.TxtTeamNum.text = string.format("<color=#00ff00>%d</color>/%d", powerPlayer, powerRecommend)
        if self._BossOnShow and self._BossOnShow:IsAlive() then
            self._ButtonBoss:SetActive("TxtSummon", false)
            if self.RImgSummonBg then
                self.RImgSummonBg.gameObject:SetActiveEx(false)
            end
        else
            self._ButtonBoss:SetActive("TxtSummon", true)
            if self.RImgSummonBg then
                self.RImgSummonBg.gameObject:SetActiveEx(true)
            end
        end
    else
        self.TxtTeamNum.text = string.format("<color=#ff0000>%d</color>/%d", powerPlayer, powerRecommend)
        self._ButtonBoss:SetActive("TxtSummon", false)
        if self.RImgSummonBg then
            self.RImgSummonBg.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPlanetBattleMain:_OnClickBoss(_, entityId)
    entityId = entityId or self._BossEntityIdOnShow
    if entityId then
        local entity = self._Explore:GetEntity(entityId)
        if entity then
            local bossId = entity.Data.IdFromConfig
            local gridId = entity.Move.TileIdCurrent
            ---@type XPlanetBoss
            local boss = XPlanetBoss.New(bossId)
            boss:SetUid(entity.Id)
            boss:SetAlive(true)
            boss:SetIdFromServer(entity.Data.IdFromServer)
            boss:SetGridId(gridId)
            boss:SetGroupIdByStage()
            XDataCenter.PlanetManager.RequestStageOpenMonsterDetial(boss)
        end
    else
        XLuaUiManager.Open("UiPlanetDetail02", self._BossOnShow)
    end
end

function XUiPlanetBattleMain:_OnClickPlay()
    if self._Explore:IsRunning() then
        self._Explore:Pause(XPlanetExploreConfigs.PAUSE_REASON.PLAYER)
    else
        if self._Explore:IsPauseNotByPlayer() and self._Explore:IsPause() then
            return
        end
        self._Explore:Resume(XPlanetExploreConfigs.PAUSE_REASON.PLAYER)
    end
    self:UpdateBtnPlay()
end

function XUiPlanetBattleMain:UpdateBtnPlay()
    if self._Explore:IsRunning() then
        self.BtnDepart.gameObject:SetActiveEx(false)
        self.BtnPause.gameObject:SetActiveEx(true)
    else
        self.BtnDepart.gameObject:SetActiveEx(true)
        self.BtnPause.gameObject:SetActiveEx(false)
    end
end

function XUiPlanetBattleMain:OnBossChanged()
    self:UpdateBossByStageData()
end

function XUiPlanetBattleMain:PlayBossMovie(movieId, finishCb)
    if not movieId then
        return
    end
    self._Explore:PlayMovie(movieId, finishCb)
end

function XUiPlanetBattleMain:_OnClickTimeScale()
    if self._Explore:GetTimeScale() == TIME_SCALE.NORMAL then
        self._Explore:SetTimeScale(TIME_SCALE.X2)

    elseif self._Explore:GetTimeScale() == TIME_SCALE.X2 then
        self._Explore:SetTimeScale(TIME_SCALE.NORMAL)
    end
    self:UpdateTimeScale()
end

function XUiPlanetBattleMain:UpdateTimeScale()
    if self._Explore:GetTimeScale() == TIME_SCALE.NORMAL then
        self.BtnDoubleaccel01.gameObject:SetActiveEx(true)
        self.BtnDoubleaccel02.gameObject:SetActiveEx(false)

    elseif self._Explore:GetTimeScale() == TIME_SCALE.X2 then
        self.BtnDoubleaccel01.gameObject:SetActiveEx(false)
        self.BtnDoubleaccel02.gameObject:SetActiveEx(true)
    end
end

function XUiPlanetBattleMain:_OnClickSkipFight()
    if self.ToggleSkip.isOn then
        self._Explore:SetSkipFight(true)
    else
        self._Explore:SetSkipFight(false)
    end
end

function XUiPlanetBattleMain:UpdateRole()
    ---@type XPlanetRunningExploreEntity[]
    local entityList = self._Explore:GetCharacter()
    for i = 1, #entityList do
        local entity = entityList[i]
        ---@type XUiPlanetBattleMainGridRole
        local grid = self._RoleList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridRole, self.GridRole.parent.transform)
            grid = XUiPlanetBattleMainGridRole.New(ui)
            self._RoleList[i] = grid
        end
        grid:RegisterClick(function()
            self:OnClickEntity(entity)
        end)
        grid.GameObject:SetActiveEx(true)
        local isLeader = i == 1
        grid:Update(entity, isLeader)
    end
    for i = #entityList + 1, #self._RoleList do
        local grid = self._RoleList[i]
        grid.GameObject:SetActiveEx(false)
    end
end

function XUiPlanetBattleMain:_OnClickExit()
    local time = CS.UnityEngine.Time.unscaledTime
    if self._TimeOnEnalbe then
        if time - self._TimeOnEnalbe < self._DurationIgnoreClickExit then
            return
        end
    end
    -- 防止在结算时, 误点退出窗口
    if self._Explore:IsPause(XPlanetExploreConfigs.PAUSE_REASON.FIGHT) then
        return
    end
    if self._Explore:IsPause(XPlanetExploreConfigs.PAUSE_REASON.RESULT) then
        return
    end
    self._Explore:Pause()
    XLuaUiManager.Open("UiPlanetPropertyPopover")
end

function XUiPlanetBattleMain:UpdateWeather()
    self.PanelWeather:Refresh()
    if XTool.UObjIsNil(self.Effect) then
        return
    end
    local stageData = XDataCenter.PlanetManager.GetStageData()
    local weatherId = stageData:GetWeatherId()
    local icon = XTool.IsNumberValid(weatherId) and XPlanetWorldConfigs.GetWeatherEffectUrl(weatherId) or XPlanetConfigs.GetMainMeteorEffect()
    if not string.IsNilOrEmpty(icon) then
        self.Effect:LoadUiEffect(icon)
        self.Effect.gameObject:SetActiveEx(true)
    else
        self.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiPlanetBattleMain:RefreshBuildCardPanel()
    if self.PanelBuildCardPanel then
        self.PanelBuildCardPanel:RefreshGird()
    end
end

function XUiPlanetBattleMain:UpdateProp()
    local stageData = XDataCenter.PlanetManager.GetStageData()
    local items = stageData:GetRunningItem()

    if not XPlanetStageConfigs.IsStageShowProp(stageData:GetStageId()) and #items <= 0 then
        self.PanelItems.gameObject:SetActiveEx(false)
        return
    end
    self.PanelItems.gameObject:SetActiveEx(true)

    for i = 1, #items do
        local item = items[i]
        ---@type XGridPlanetBattleMainProp
        local grid = self._ItemList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridItem, self.GridItem.parent.transform)
            grid = XGridPlanetBattleMainProp.New(ui, self)
            self._ItemList[i] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Update(item)
    end
    for i = #items + 1, #self._ItemList do
        local grid = self._ItemList[i]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiPlanetBattleMain:Update()
    self:UpdateProp()
    self:UpdateBoss()
    self:UpdateRole()
    self:UpdateWeather()
end

function XUiPlanetBattleMain:ExplorePause(reason)
    self._Explore:Pause(reason or XPlanetExploreConfigs.PAUSE_REASON.BUILD)
    self:UpdateBtnPlay()
end

function XUiPlanetBattleMain:ExploreResume(reason)
    self._Explore:Resume(reason or XPlanetExploreConfigs.PAUSE_REASON.BUILD)
    self:UpdateBtnPlay()
end

---@param character XPlanetCharacter
function XUiPlanetBattleMain:SetCaptain(character)
    self._Explore:SetCaptainByCharacterId(character:GetCharacterId())
end

function XUiPlanetBattleMain:OnBossRemoved()
    self:UpdateBossByStageData()
end

function XUiPlanetBattleMain:UpdateBossByStageData()
    self._Explore:UpdateDataBoss()
    self._Explore:UpdateBoss()
end

function XUiPlanetBattleMain:_OnClickTarget()
    if self._PanelTarget.GameObject.activeSelf then
        if self.Tri1 then
            self.Tri1.gameObject:SetActiveEx(false)
        end
        self._PanelTarget.GameObject:SetActiveEx(false)
    else
        if self.Tri1 then
            self.Tri1.gameObject:SetActiveEx(true)
        end
        self._PanelTarget.GameObject:SetActiveEx(true)
        self:PlayAnimation("ImgTargetEnable")
    end
    self:UpdateBtnTarget()
end

function XUiPlanetBattleMain:UpdateBtnTarget()
    if self._PanelTarget.GameObject.activeSelf then
        self.BtnTarget:SetButtonState(UiButtonState.Select)
        -- XUiButton在OnPointerDown时有个TempState变量存了当前按钮状态
        -- 如果在点击过程中通过接口改变状态
        -- 在指针离开按钮触发XUiButton的OnPointerExit状态会会恢复为TempState
        self.BtnTarget.TempState = UiButtonState.Select
    else
        self.BtnTarget:SetButtonState(UiButtonState.Normal)
        self.BtnTarget.TempState = UiButtonState.Normal
    end
end

--region 剧情调用接口
function XUiPlanetBattleMain:HideUi()
    self.PanelRoot.gameObject:SetActiveEx(false)
    self.BtnTarget.gameObject:SetActiveEx(false)
    self.BtnHide.gameObject:SetActiveEx(false)
    self.BtnScreenShot.gameObject:SetActiveEx(false)
    self.BtnLocation.gameObject:SetActiveEx(false)
    self.BtnLocation02.gameObject:SetActiveEx(false)
    self.ImgTarget.gameObject:SetActiveEx(false)
    if self.Tri1 then
        self.Tri1.gameObject:SetActiveEx(false)
    end
end

function XUiPlanetBattleMain:ShowUi()
    self.PanelRoot.gameObject:SetActiveEx(not self._IsHideUi)
    self.BtnTarget.gameObject:SetActiveEx(not self._IsHideUi)
    self.BtnHide.gameObject:SetActiveEx(self._IsHideUi and not self:CheckIsGuideStage())
    self.BtnScreenShot.gameObject:SetActiveEx(not self._IsHideUi and not self:CheckIsGuideStage())
    self.BtnLocation.gameObject:SetActiveEx(not self._IsHideUi and not self._Scene:CheckCameraIsFollowMode() and not self:CheckIsGuideStage())
    self.BtnLocation02.gameObject:SetActiveEx(not self._IsHideUi and self._Scene:CheckCameraIsFollowMode() and not self:CheckIsGuideStage())
    self.ImgTarget.gameObject:SetActiveEx(not self._IsHideUi)
    if self.Tri1 then
        self.Tri1.gameObject:SetActiveEx(not self._IsHideUi)
    end
end
--endregion

--region Boss出现镜头动画
function XUiPlanetBattleMain:PlayBossCam(entityId)
    if not XTool.IsNumberValid(entityId) then
        return
    end

    if self._Explore:IsPlayingMovie() then
        return
    end
    local model = self._Explore:GetModel(entityId)
    if not model then
        return
    end
    local transform = model:GetTransform()
    if not transform then
        model:ShowRoleModel()
        XLog.Error("[XUiPlanetBattleMain] boss模型不存在")
        self:ShowUi()
        return
    end
    self:ExplorePause(XPlanetExploreConfigs.PAUSE_REASON.CAMERA)
    self:HideUi()
    self._Scene:UpdateCameraInBoss(model:GetTransform(), function()
        model:ShowRoleModel()
        self._Explore:PlayBornEffect(self._Explore:GetEntity(entityId))
        XScheduleManager.ScheduleOnce(function()
            self._IsCamFollowLeader = false
            self:ShowUi()
            self:ExploreResume(XPlanetExploreConfigs.PAUSE_REASON.CAMERA)
        end, 0.7 * XScheduleManager.SECOND)
    end)
end
--endregion

--region 引导
function XUiPlanetBattleMain:CheckIsGuideStage()
    local stageData = XDataCenter.PlanetManager.GetStageData()
    local guideStageIdList = XPlanetConfigs.GetGuideStageClickCardToDragList()
    if stageData:GetStageId() == 0 or XTool.IsTableEmpty(guideStageIdList) then
        return false
    end
    for _, stageId in ipairs(guideStageIdList) do
        if stageData:GetStageId() == stageId then
            return true
        end
    end
    return false
end

function XUiPlanetBattleMain:AddGuideEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_STAGE_MOVIE_STOP, self.CheckIsAfterEnterMovie, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUNCTION_EVENT_COMPLETE, self.OnGuideEnd, self)
end

function XUiPlanetBattleMain:RemoveGuideEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_STAGE_MOVIE_STOP, self.CheckIsAfterEnterMovie, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUNCTION_EVENT_COMPLETE, self.OnGuideEnd, self)
end

function XUiPlanetBattleMain:OnGuideStart(guideId)
    XDataCenter.PlanetManager.SetGuideEnd(guideId)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.GUIDE)
end

function XUiPlanetBattleMain:OnGuideEnd()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.GUIDE)
end

function XUiPlanetBattleMain:CheckIsAfterEnterMovie()
    if XDataCenter.PlanetManager.SetGuideEnterMovie(true) and XDataCenter.PlanetManager.CheckGuideOpen() then
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.GUIDE)
    end
end

function XUiPlanetBattleMain:CheckIsFirstGetMoney()
    if self._Explore:IsRunning() and XDataCenter.PlanetManager.SetGuideFirstGetMoney(true) and XDataCenter.PlanetManager.CheckGuideOpen() then
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.GUIDE)
    end
end
--endregion

return XUiPlanetBattleMain