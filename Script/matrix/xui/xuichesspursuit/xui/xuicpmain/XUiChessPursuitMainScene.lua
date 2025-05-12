local XChessPursuitCtrl = require("XUi/XUiChessPursuit/XChessPursuitCtrl")
local XUiChessPursuitMainBase = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitMainBase")
local XUiChessPursuitMainScene = XClass(XUiChessPursuitMainBase, "XUiChessPursuitMainScene")
local XChessPursuitSceneManager = require("XUi/XUiChessPursuit/XScene/XChessPursuitSceneManager")
local XChessPursuitTeam = require("XUi/XUiChessPursuit/XScene/XChessPursuitTeam")
local XUiChessPursuitBuzhenGrid = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitBuzhenGrid")
local XChessPursuitBoss = require("XUi/XUiChessPursuit/XScene/XChessPursuitBoss")
local XUiCPActionMachine = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionMachine")
local XUiChessPursuitCardGrid = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitCardGrid")
local XUiChessPursuitSkillGrid = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitSkillGrid")
local XUiChessPursuitSelectTipGrid = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitSelectTipGrid")
local XUiChessPursuitGridFight = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitGridFight")
local XUiChessPursuitSkillEffectGrid = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitSkillEffectGrid")
local XUiChessPursuitGuideGrid = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitGuideGrid")
local XUiChessPursuitMainAnimQueue = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitMainAnimQueue")

local CSUnityEngineWaitForSeconds = CS.UnityEngine.WaitForSeconds
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText

local CANCEL_SELECT_INDEX = -1
local DelayDestroyArrowEffectMilliSecond = 1500
local TxtNumberBattlesDefaultFontSize = 36

function XUiChessPursuitMainScene:Ctor(ui, rootUi, mapId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.MapId = mapId
    self:SetEndRound(true)

    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_FINISH_LOSEUI_CLOSE, self.FinishLoseuiClose, self)
end

function XUiChessPursuitMainScene:Disable()
    if self.UiChessPursuitSkillEffectGrids then
        for i, v in ipairs(self.UiChessPursuitSkillEffectGrids) do
            v:Disable()
        end
    end
end

function XUiChessPursuitMainScene:Dispose()
    self.UsedToGrid = {}
    self.UsedToBoss = {}

    self:StopUpdateTimer()
    self:StopDestroyArrowEffectUpdateTimer()
    self:StopBossEffectBloodUpdateTimer()
    if self.CurrentActionMachine then
        self.CurrentActionMachine:Interrupt()
        self.CurrentActionMachine = nil
    end 
    if self.ChessPursuitBoss then
        self.ChessPursuitBoss:Dispose()
        self.ChessPursuitBoss = nil
    end

    if self.UiChessPursuitBuzhenGrids then
        for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
            uiChessPursuitBuzhenGrid:Dispose()
        end
    end
    
    if self.ChessPursuitTeams then
        for i,chessPursuitTeam in ipairs(self.ChessPursuitTeams) do
            chessPursuitTeam:Dispose()
        end
    end
    
    if self.ChessPursuitCubes then
        for i,chessPursuitCubes in ipairs(self.ChessPursuitCubes) do
            chessPursuitCubes:Dispose()
        end
    end

    if self.UiChessPursuitCardGrids then
        for i,uiChessPursuitCardGrid in ipairs(self.UiChessPursuitCardGrids) do
            uiChessPursuitCardGrid:Dispose()
        end
    end

    if self.CSXChessPursuitCtrlCom then
        self.CSXChessPursuitCtrlCom:SetCameraMask(false)
    end

    if self.ChessPursuitCubes then
        for i,chessPursuitCube in ipairs(self.ChessPursuitCubes) do
            chessPursuitCube:Default()
            chessPursuitCube:Dispose()
        end
    end

    if self.UiChessPursuitSkillGrids then
        for i,v in ipairs(self.UiChessPursuitSkillGrids) do
            v:Dispose()
        end
    end

    if self.UiChessPursuitSkillGridBoss then
        self.UiChessPursuitSkillGridBoss:Dispose()
    end

    if self.UiChessPursuitSelectTipGrids then
        for i,v in ipairs(self.UiChessPursuitSelectTipGrids) do
            v:Dispose()
        end

        self.UiChessPursuitSelectTipGridBoss:Dispose()
    end

    if self.UiChessPursuitSkillEffectGrids then
        for i,v in ipairs(self.UiChessPursuitSkillEffectGrids) do
            v:Dispose()
        end
    end

    if self.UiChessPursuitGridFight then
        self.UiChessPursuitGridFight:Dispose()
    end
    
    if self.UiChessPursuitGuideGrid then
        self.UiChessPursuitGuideGrid:Dispose()
    end

    if self.UiChessPursuitMainAnimQueue then
        self.UiChessPursuitMainAnimQueue:Clear()
    end

    self:RemoveEventListener()
    self.GameObject:SetActiveEx(false)
    self:CheckOnClickCardHidePanel(CANCEL_SELECT_INDEX)

    XEventManager.RemoveEventListener(XEventId.EVENT_CHESSPURSUIT_BUY_CARD, self.RefreshBuyCard, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_FINISH_LOSEUI_CLOSE, self.FinishLoseuiClose, self)
end

function XUiChessPursuitMainScene:StopUpdateTimer()
    if self.UpdateTimer then
        XScheduleManager.UnSchedule(self.UpdateTimer)
        self.UpdateTimer = nil
    end
end

function XUiChessPursuitMainScene:StopDestroyArrowEffectUpdateTimer()
    if self.DestroyArrowEffectUpdateTimer then
        XScheduleManager.UnSchedule(self.DestroyArrowEffectUpdateTimer)
        self.DestroyArrowEffectUpdateTimer = nil
        self:DestroyArrowEffect()
    end
end

function XUiChessPursuitMainScene:StopBossEffectBloodUpdateTimer()
    if self.BossEffectBloodUpdateTimer then
        XScheduleManager.UnSchedule(self.BossEffectBloodUpdateTimer)
        self.BossEffectBloodUpdateTimer = nil
        self.EffectBloodVolume.gameObject:SetActiveEx(false)
    end
end

function XUiChessPursuitMainScene:FinishLoseuiClose()
    if self.CurrentActionMachine and self.CurrentActionMachine:GetActionType() == XDataCenter.ChessPursuitManager.ChessPursuitSyncActionType.EndBattle then
        self.CurrentActionMachine:OnExit()
    end

    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    local bossPos = chessPursuitMapDb:GetBossPos()
    XChessPursuitCtrl.SetSceneActive(true)
    local teamGridIndex = XChessPursuitConfig.GetTeamGridIndexByPos(self.MapId, bossPos)
    XLuaUiManager.Open("UiChessPursuitFightTips", self.MapId, teamGridIndex, function ()
        XChessPursuitCtrl.SetSceneActive(false)
    end, self.RootUi, self.CSXChessPursuitCtrlCom:GetChessPursuitDrawCamera())
end

--@region 主要的逻辑接口

function XUiChessPursuitMainScene:Init(params, callBack)
    XUiChessPursuitMainScene.Super.Init(self, params)

    self:RequestChessPursuitEnterMapData(self.MapId, function ()
        self.GameObject:SetActiveEx(true)
        self.UiChessPursuitMainAnimQueue = XUiChessPursuitMainAnimQueue.New(self.RootUi)
        self.CSXChessPursuitCtrlCom = XChessPursuitCtrl.GetCSXChessPursuitCtrlCom()
        self.CSXChessPursuitCtrlCom:Init(self.ChessPursuitMapDb:GetBossPos() , self.ChessPursuitMapDb:GetBossMoveDirection())
        self.UiChessPursuitBuzhenGrids = {}
        self.ChessPursuitTeams = {}
        self.UiChessPursuitCardGrids = {}
        self.UsedToGrid = {}
        self.UsedToBoss = {}
    
        --初始化BOSS、队伍、格子...
        self:InitCubes()
        self:InitBoss()
        self:InitTeam()
        self:InitCards()
        self:InitSkills()
        self:InitSelectTips()
        self:InitSkillEffects()
        self:InitGridFight()
        self:PlayEnableAnimation()
        self:StopUpdateTimer()
        self:Update()
    
        self.UpdateTimer = XScheduleManager.ScheduleForever(function()
            self:Update()
        end, 0.1)
    
        if callBack then
            callBack()
        end
    end)
end

function XUiChessPursuitMainScene:Update()
    local sceneType = self:GetSceneType()
    if sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND then
        self:UpdateBossRound()
    elseif sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND then
        self:UpdateMyRound()
    elseif sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN then
        self:UpdateBuZhen()
    end

    --放在最后
    self.SceneType = sceneType
end

--@endregion

--@region 点击事件

function XUiChessPursuitMainScene:AutoAddListener()
    self.BtnTongBlue.CallBack = function() self:OnBtnTongBlueClick() end
    self.BtnBuChongzhi.CallBack = function() self:OnBtnBuChongzhi() end
    self.BtnBuSaodang.CallBack = function() self:OnBtnBuSaodang() end
    self.BtnBuJieshu.CallBack = function() self:OnBtnBuJieshu() end
    self.BtnShop.CallBack = function() self:OnBtnShop() end
    self.BtnAccelerate.CallBack = function() self:OnBtnAccelerate() end
    if self.BtnQuickDeploy then
        self.BtnQuickDeploy.CallBack = function() self:OnBtnQuickDeploy() end
    end

    XEventManager.AddEventListener(XEventId.EVENT_CHESSPURSUIT_BUY_CARD, self.RefreshBuyCard, self)
end

function XUiChessPursuitMainScene:OnBtnTongBlueClick()
    local title = CS.XTextManager.GetText("BfrtDeployTipTitle")
    XUiManager.DialogTip(title, CS.XTextManager.GetText("ChessPursuitBuZhenEnterTip"), XUiManager.DialogType.Normal, nil, function()
        local ret, msg = XDataCenter.ChessPursuitManager.RequestChessPursuitSetGridTeamData(self.MapId, function ()
            self:LoadJianTouEffect()
            XDataCenter.GuideManager.CheckGuideOpen()
        end)
        
        if not ret then
            XUiManager.TipError(msg)
        end
    end)
end
 
function XUiChessPursuitMainScene:OnBtnShop()
    if self.SceneType == XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND then
        --进入商店时设置不可拖动
        local chessPursuitDrawCamera = self.CSXChessPursuitCtrlCom:GetChessPursuitDrawCamera()
        chessPursuitDrawCamera:SwitchChessPursuitCameraState(CS.XChessPursuitCameraState.None)
        XLuaUiManager.Open("UiChessPursuitShop", self.MapId, function (oldBuyedCards)
            chessPursuitDrawCamera:SwitchChessPursuitCameraState(CS.XChessPursuitCameraState.Draw);
            self:CheckPlayNewCardsAnima(oldBuyedCards)
        end)
    else
        XLuaUiManager.Open("UiChessPursuitShop", self.MapId, function (oldBuyedCards)
            self:CheckPlayNewCardsAnima(oldBuyedCards)
        end)
    end
end

function XUiChessPursuitMainScene:CheckPlayNewCardsAnima(oldBuyedCards)
    if XTool.IsTableEmpty(oldBuyedCards) then
        self.RootUi:PlayAnimation("CardsEnable")
        return
    end
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    local curBuyedCards = chessPursuitMapDb:GetBuyedCards()
    if XTool.IsTableEmpty(curBuyedCards) then
        return
    end
    if #oldBuyedCards ~= #curBuyedCards then
        self.RootUi:PlayAnimation("CardsEnable")
    end
end

function XUiChessPursuitMainScene:OnBtnQuickDeploy()
    XLuaUiManager.Open("UiChessPursuitQuickDeploy", self.MapId)
end

function XUiChessPursuitMainScene:OnBtnAccelerate()
    if self.SceneType ~= XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND then
        return
    end

    if self.CurrentActionMachine and self.CurrentActionMachine:GetActionType() == XDataCenter.ChessPursuitManager.ChessPursuitSyncActionType.BeginBattle then
        self.IsSkip = false
        return
    end

    if self.IsSkip then
        return
    end

    self.IsSkip = true
    self.ChessPursuitSyncActionQueue:Clear()
end

function XUiChessPursuitMainScene:OnBtnBuChongzhi()
    if self.SceneType ~= XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND then
        return
    end
    XUiManager.DialogTip(CSXTextManagerGetText("TipTitle"), CSXTextManagerGetText("ChessPursuitResetTipContent"), XUiManager.DialogType.Normal, nil, function()
        XDataCenter.ChessPursuitManager.RequestChessPursuitResetMapData(function ()
            self.RootUi:SwtichUI(XChessPursuitCtrl.MAIN_UI_TYPE.SCENE, {
                MapId = self.MapId
            }, true)
        end, self.MapId)
    end)
end

function XUiChessPursuitMainScene:OnBtnBuSaodang(isAutoOpen)
    local sceneType = self:GetSceneType()
    if sceneType ~= XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND then
        return
    end

    if not self:IsCanSaoDang() then
        XUiManager.TipText("ChessPursuitCantAuto")
        return
    end

    if isAutoOpen then
        XDataCenter.ChessPursuitManager.SaveSaoDangIsAlreadyAutoOpen(self.MapId)
    end
    
    XUiManager.DialogTip(CSXTextManagerGetText("TipTitle"), CSXTextManagerGetText("ChessPursuitSaoDangIsFistOpen"), XUiManager.DialogType.Normal, nil, function()
        XDataCenter.ChessPursuitManager.RequestChessPursuitAutoClearData(function ()
            self:RefreshBloodAndCount()
            self:PlayBossKillerAnimation()
        end)
    end)
end

function XUiChessPursuitMainScene:OnBtnBuJieshu()
    if self.SceneType ~= XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND then
        return
    end

    self.BtnCardsGroup:CancelSelect()

    XDataCenter.ChessPursuitManager.RequestChessPursuitEndRoundData(self.UsedToGrid, self.UsedToBoss, function (bossRandomStep)
        self.UsedToGrid = {}
        self.UsedToBoss = {}

        self:Update()
        local cfg = XChessPursuitConfig.GetChessPursuitStepTemplateByStep(bossRandomStep)
        if cfg then
            self:PlayStep(cfg.Id)
        end
    end)
end

--index点击了第几张卡
function XUiChessPursuitMainScene:OnCardClick(index, btn)
    if self.ChessPursuitMapDb:IsClear() then
        return
    end
    
    --选中
    self.UiChessPursuitCardGrids[index]:SetDisable(false)

    if self.BtnCardsGroup.CurSelectId ~= CANCEL_SELECT_INDEX then
        local cards = self.ChessPursuitMapDb:GetBuyedCards()
        local card = cards[index]
        local cardCfg = XChessPursuitConfig.GetChessPursuitCardTemplate(card.CardCfgId)
        local selectTarge
        if cardCfg.TargetType == 0 then
            selectTarge = XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS
        elseif cardCfg.TargetType == 1 then
            selectTarge = XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE
        elseif cardCfg.TargetType == 2 then
            selectTarge = XChessPursuitCtrl.SCENE_SELECT_TARGET.TEAM
        end

        self:SwitchSelectTarge(selectTarge)
        self.CardDetails.gameObject:SetActiveEx(true)
        self.TxtCardDetails.text = cardCfg.Describe
        
        self:RemoveSelectCard(card)
        self:RefreshSkillGridsByTeamp()
        self:RefreshSelectTipGrids(selectTarge)
        self:CheckChessPursuitBossColliderIsActive(selectTarge)
    else
        --取消选中
        self:RefreshSelectTipGrids(XChessPursuitCtrl.SCENE_SELECT_TARGET.NONE)
        self:SwitchSelectTarge(XChessPursuitCtrl.SCENE_SELECT_TARGET.DEFAULT)
        self.CardDetails.gameObject:SetActiveEx(false)
        self:CheckChessPursuitBossColliderIsActive()
    end
    self:CheckOnClickCardHidePanel(self.BtnCardsGroup.CurSelectId, index)
end

function XUiChessPursuitMainScene:OnCubeClick(gridIndex)
    if self.BtnCardsGroup.CurSelectId == CANCEL_SELECT_INDEX  then
        local targetType = XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE
        local cubeIndex = gridIndex
        if self:CanOpenUiChessPursuitBuffTips(targetType, cubeIndex) then
            XLuaUiManager.Open("UiChessPursuitBuffTips", self.MapId, targetType, cubeIndex)
        end
    else
        local cards = self.ChessPursuitMapDb:GetBuyedCards()
        local card = cards[self.BtnCardsGroup.CurSelectId]

        self:RemoveSelectCard(card)
        self:AddSelectCard(card, XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE, gridIndex)
        self:RefreshSkillGridsByTeamp()
        self:SwitchSelectTarge(XChessPursuitCtrl.SCENE_SELECT_TARGET.DEFAULT)
        self.BtnCardsGroup:CancelSelect()
        self:RefreshSelectTipGrids(XChessPursuitCtrl.SCENE_SELECT_TARGET.NONE)
        self.CardDetails.gameObject:SetActiveEx(false)
        self:CheckOnClickCardHidePanel(CANCEL_SELECT_INDEX)
    end
end

function XUiChessPursuitMainScene:OnCaptainClick(gridIndex)
    if self.BtnCardsGroup.CurSelectId == CANCEL_SELECT_INDEX then
        --此处 队伍即等于格子类型
        local targetType = XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE
        local cubeIndex = self.UiChessPursuitBuzhenGrids[gridIndex]:GetCubeIndex()
        if self:CanOpenUiChessPursuitBuffTips(targetType, cubeIndex) then
            XLuaUiManager.Open("UiChessPursuitBuffTips", self.MapId, targetType, cubeIndex)
        end
    else
        local cards = self.ChessPursuitMapDb:GetBuyedCards()
        local card = cards[self.BtnCardsGroup.CurSelectId]
    
        self:RemoveSelectCard(card)
        self:AddSelectCard(card, XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE, self.UiChessPursuitBuzhenGrids[gridIndex]:GetCubeIndex())
        self:RefreshSkillGridsByTeamp()
        self:SwitchSelectTarge(XChessPursuitCtrl.SCENE_SELECT_TARGET.DEFAULT)
        self.BtnCardsGroup:CancelSelect()
        self:RefreshSelectTipGrids(XChessPursuitCtrl.SCENE_SELECT_TARGET.NONE)
        self.CardDetails.gameObject:SetActiveEx(false)
        self:CheckOnClickCardHidePanel(CANCEL_SELECT_INDEX)
    end
end

function XUiChessPursuitMainScene:OnBossClick()
    if self.BtnCardsGroup.CurSelectId == CANCEL_SELECT_INDEX then
        local targetType = XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS
        if self:CanOpenUiChessPursuitBuffTips(targetType) then
            XLuaUiManager.Open("UiChessPursuitBuffTips", self.MapId, targetType)
        end
    else
        local cards = self.ChessPursuitMapDb:GetBuyedCards()
        local card = cards[self.BtnCardsGroup.CurSelectId]

        self:RemoveSelectCard(card)
        self:AddSelectCard(card, XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS)
        self:RefreshSkillGridsByTeamp()
        self:SwitchSelectTarge(XChessPursuitCtrl.SCENE_SELECT_TARGET.DEFAULT)
        self.BtnCardsGroup:CancelSelect()
        self:RefreshSelectTipGrids(XChessPursuitCtrl.SCENE_SELECT_TARGET.NONE)
        self.CardDetails.gameObject:SetActiveEx(false)
        self:CheckChessPursuitBossColliderIsActive()
        self:CheckOnClickCardHidePanel(CANCEL_SELECT_INDEX)
    end
end

--选择卡牌中隐藏布局和按钮
function XUiChessPursuitMainScene:CheckOnClickCardHidePanel(selectedCardId, btnCardsIndex)
    if not self.ChessPursuitMapDb then
        return
    end

    local isHide = selectedCardId ~= CANCEL_SELECT_INDEX
    self.RightButtonGroup.gameObject:SetActiveEx(not isHide)
    self.Shop.gameObject:SetActiveEx(not isHide)
    self.RootUi:SetBtnHelpIsHide(not isHide)

    local cards = self.ChessPursuitMapDb:GetBuyedCards()
    for i = 1, XChessPursuitCtrl.CARD_MAX_COUNT do
        local cardGrid = self.UiChessPursuitCardGrids[i]
        if cardGrid then
            local card = cards[i]
            if isHide and btnCardsIndex ~= i then
                cardGrid:SetActive(false)
            else
                cardGrid:SetActive(card and true or false)
            end
        end
    end
end

function XUiChessPursuitMainScene:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_CHESSPURSUIT_SAVETEAM, self.RefreshTeam, self)
end

function XUiChessPursuitMainScene:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHESSPURSUIT_SAVETEAM, self.RefreshTeam, self)
end
--@endregion

--@region 初始化

function XUiChessPursuitMainScene:InitBoss()
    self.ChessPursuitBoss = XChessPursuitBoss.New()
    local chessPursuitScene = XChessPursuitSceneManager.GetCurrentScene()
    local sceneGameObject = chessPursuitScene:GetSceneGameObject()

    self.ChessPursuitBoss:LoadBoss(self.ChessPursuitMapBoss:GetId(), sceneGameObject.transform:Find("Playmaker/ChessPieces"))
    self.ChessPursuitBoss:AddClick(function ()
        self:OnBossClick()
    end)

    if self.ChessPursuitMapDb:IsClear() then
        self.ChessPursuitBoss.GameObject:SetActiveEx(false)
    end
end

function XUiChessPursuitMainScene:InitTeam()
    self.TeamHeadNode.gameObject:SetActiveEx(false)
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)

    --表的index从0开始
    for teamGridIndex,cubeIndex in ipairs(config.TeamGrid) do
        local grid = CSUnityEngineObjectInstantiate(self.TeamHeadNode, self.PanelArrangment.transform)
        local uiChessPursuitBuzhenGrid = XUiChessPursuitBuzhenGrid.New(grid, self, cubeIndex+1, teamGridIndex, self.MapId)
        table.insert(self.UiChessPursuitBuzhenGrids, uiChessPursuitBuzhenGrid)
        table.insert(self.ChessPursuitTeams, XChessPursuitTeam.New(cubeIndex+1, teamGridIndex, self.MapId))

        uiChessPursuitBuzhenGrid:Init()
    end

    self:RefreshTeam()
end

function XUiChessPursuitMainScene:InitCubes()
    self.ChessPursuitCubes = XChessPursuitCtrl.GetChessPursuitCubes()

    for i,chessPursuitCube in ipairs(self.ChessPursuitCubes) do
        chessPursuitCube:AddClick(function ()
            self:OnCubeClick(i)
        end)
    end
end

function XUiChessPursuitMainScene:InitSelectTips()
    self.UiChessPursuitSelectTipGrids = {}
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)

    --表的index从0开始
    for teamGridIndex,cubeIndex in ipairs(config.TeamGrid) do
        local grid = CSUnityEngineObjectInstantiate(self.SelectTips, self.PanelArrangment.transform)
        local uiChessPursuitSelectTipGrid = XUiChessPursuitSelectTipGrid.New(grid, self, cubeIndex+1, self.MapId, XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE)
        table.insert(self.UiChessPursuitSelectTipGrids, uiChessPursuitSelectTipGrid)
    end

    local grid = CSUnityEngineObjectInstantiate(self.SelectTips, self.PanelArrangment.transform)
    local uiChessPursuitSelectTipGrid = XUiChessPursuitSelectTipGrid.New(grid, self, nil, self.MapId, XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS)
    self.UiChessPursuitSelectTipGridBoss = uiChessPursuitSelectTipGrid
end

function XUiChessPursuitMainScene:InitGridFight()
    local grid = CSUnityEngineObjectInstantiate(self.GridFight, self.PanelArrangment.transform)
    local uiChessPursuitGridFight = XUiChessPursuitGridFight.New(grid, self, self.MapId)
    self.UiChessPursuitGridFight = uiChessPursuitGridFight
end

function XUiChessPursuitMainScene:InitSkills()
    self.UiChessPursuitSkillGrids = {}

    for cubeIndex,chessPursuitCube in ipairs(self.ChessPursuitCubes) do
        local grid = CSUnityEngineObjectInstantiate(self.SkillsNode, self.PanelArrangment.transform)
        local uiChessPursuitSkillGrid = XUiChessPursuitSkillGrid.New(grid, self, cubeIndex, self.MapId, XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE)
        table.insert(self.UiChessPursuitSkillGrids, uiChessPursuitSkillGrid)
    end

    local grid = CSUnityEngineObjectInstantiate(self.SkillsNode, self.PanelArrangment.transform)
    local uiChessPursuitSkillGrid = XUiChessPursuitSkillGrid.New(grid, self, nil, self.MapId, XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS)
    self.UiChessPursuitSkillGridBoss = uiChessPursuitSkillGrid
end

function XUiChessPursuitMainScene:InitSkillEffects()
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
    self.UiChessPursuitSkillEffectGrids = {}

    for cubeIndex,chessPursuitCube in ipairs(self.ChessPursuitCubes) do
        local uiChessPursuitSkillEffectGrid = XUiChessPursuitSkillEffectGrid.New(self, cubeIndex, XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE, self.MapId)
        table.insert(self.UiChessPursuitSkillEffectGrids, uiChessPursuitSkillEffectGrid)
    end

    local uiChessPursuitSkillEffectGrid = XUiChessPursuitSkillEffectGrid.New(self, nil, XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS, self.MapId)
    table.insert(self.UiChessPursuitSkillEffectGrids, uiChessPursuitSkillEffectGrid)
end

function XUiChessPursuitMainScene:InitGuideGrid()
    local teamGridIndex = 1
    
    if self.ChessPursuitTeams[teamGridIndex].Transform then
        local grid = CSUnityEngineObjectInstantiate(self.GuideTeamClick, self.PanelArrangment.transform)
        self.UiChessPursuitGuideGrid = XUiChessPursuitGuideGrid.New(grid, self, self.ChessPursuitTeams[teamGridIndex].Transform)
        self.UiChessPursuitGuideGrid:AddClick(function ()
            self:OnCaptainClick(teamGridIndex)
        end)
    end
end

function XUiChessPursuitMainScene:InitCards()
    local btns = {}
    for i=1, XChessPursuitCtrl.CARD_MAX_COUNT do
        local uiChessPursuitCardGrid = XUiChessPursuitCardGrid.New(self["BtnCards" .. i], self, i, self.MapId)
        table.insert(self.UiChessPursuitCardGrids, uiChessPursuitCardGrid)
        table.insert(btns, self["BtnCards" .. i])
    end

    self.BtnCardsGroup:Init(btns, function(index)
        self:OnCardClick(index, btns[index])
    end)
    
    --一开始什么都不选
    self.BtnCardsGroup:CancelSelect()
    self.BtnCardsGroup.CurSelectId = CANCEL_SELECT_INDEX
end

--@endregion

--@region XUiChessPursuitAction状态机

function XUiChessPursuitMainScene:UpdateActionMachine()
    self:UpdateCurrentActionMachine()
    
    if not self.CurrentActionMachine then
        return
    end

    self.CurrentActionMachine:Update()

    if self.CurrentActionMachine:GetState() == "finish" then
        self.CurrentActionMachine:Dispose()
        self.CurrentActionMachine = nil
    end
end

function XUiChessPursuitMainScene:UpdateCurrentActionMachine()
    if self.CurrentActionMachine then
        if self.IsSkip and self.CurrentActionMachine:GetActionType() == XDataCenter.ChessPursuitManager.ChessPursuitSyncActionType.BeginBattle then
            self.IsSkip = false
        end
        return
    end

    if self.IsSkiping then
        return
    end

    --正在跳转
    if self.IsSkip then
        self.IsSkiping = true
        self:RequestChessPursuitEnterMapData(self.MapId, function ()
            self.CSXChessPursuitCtrlCom:Init(self.ChessPursuitMapDb:GetBossPos() , self.ChessPursuitMapDb:GetBossMoveDirection())
            self:RefreshTeamActive()
            self.IsSkip = false
            self.IsSkiping = false
        end)
        return
    end

    local chessPursuitSyncAction = self.ChessPursuitSyncActionQueue:Pop()
    if chessPursuitSyncAction then
        self.CurrentActionMachine = XUiCPActionMachine.Create(chessPursuitSyncAction:GetType(), {
            UiRoot = self,
            ParentUiRoot = self.RootUi,
            ChessPursuitSyncAction = chessPursuitSyncAction,
            MapId = self.MapId,
            BossId = self.ChessPursuitMapBoss:GetId()
        })
    end
end

--@endregion

--@region 各回合的主要刷新逻辑

function XUiChessPursuitMainScene:UpdateBossRound()
    if self.SceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND then
        --等待动画结束再执行下一个动作
        if self.UiChessPursuitMainAnimQueue:GetCount() > 0 then
            self.UiChessPursuitMainAnimQueue:PopAndPlay()
        else
            self:UpdateActionMachine()
        end
        
        self.UiChessPursuitGridFight:RefreshPos()
        self:RefreshSkillGridsPos()
        self:RefreshBuzhenGridsPos()
        return 
    else
        self.UiChessPursuitMainAnimQueue:Push("PanelTipsEnemyRoundEnable", function() 
            self.PanelTipsEnemyRound.gameObject:SetActiveEx(true)
        end,function ()
            self.PanelTipsEnemyRound.gameObject:SetActiveEx(false)
        end)
        
        self:RefreshUiActive(XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND)
        self:SwitchSelectTarge(XChessPursuitCtrl.SCENE_SELECT_TARGET.DEFAULT)
        self:RefreshSkillGrids(true)
        self:RefreshCard(XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND)
        self:RefreshBloodAndCount()

        local chessPursuitDrawCamera = self.CSXChessPursuitCtrlCom:GetChessPursuitDrawCamera()
        chessPursuitDrawCamera:SwitchChessPursuitCameraState(CS.XChessPursuitCameraState.Follow);
        chessPursuitDrawCamera:SwitchFieldOfViewState(CS.XFieldOfView.Near)

        for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
            uiChessPursuitBuzhenGrid:UpdateBossHurMax()
        end

        self:RefreshSkillEffect()
        self:RefreshSelectTipGrids(XChessPursuitCtrl.SCENE_SELECT_TARGET.NONE)
    end
end

--自己回合界面刷新
function XUiChessPursuitMainScene:UpdateMyRound()
    if self.SceneType == XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND then
        self.UiChessPursuitGridFight:RefreshPos()
        self:RefreshSelectTipGridsPos()
        self:RefreshSkillGridsPos()
        self:RefreshBuzhenGridsPos()
        if self.UiChessPursuitGuideGrid then
            self.UiChessPursuitGuideGrid:RefreshPos()
        end
        return 
    else
        self:RefreshTeamActive()
        self:RefreshSkillEffect()
        self.PanelTipsRound.gameObject:SetActiveEx(true)
        self.RootUi:PlayAnimationWithMask("PanelMyRoundEnable", function ()
            self.PanelTipsRound.gameObject:SetActiveEx(false)
        end)
        
        self.CardDetails.gameObject:SetActiveEx(false)
        self:RefreshUiActive(XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND)
        self:SwitchSelectTarge(XChessPursuitCtrl.SCENE_SELECT_TARGET.DEFAULT)
        self:RefreshSkillGrids(true)
        self:RefreshBloodAndCount()

        local chessPursuitDrawCamera = self.CSXChessPursuitCtrlCom:GetChessPursuitDrawCamera()
        chessPursuitDrawCamera:SwitchChessPursuitCameraState(CS.XChessPursuitCameraState.Draw);
        chessPursuitDrawCamera:SwitchFieldOfViewState(CS.XFieldOfView.Near)
        self:RefreshCard(XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND)

        for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
            uiChessPursuitBuzhenGrid:UpdateBossHurMax()
        end

        local isCanSaoDang = XChessPursuitConfig.IsChessPursuitMapCanAutoClear(self.MapId)
        self.BtnBuSaodang.gameObject:SetActiveEx(isCanSaoDang)
        if isCanSaoDang then
            self:OpenSaoDangDangTips()
        end
        self:CheckChessPursuitBossColliderIsActive()
    end
end

--布阵回合界面刷新
function XUiChessPursuitMainScene:UpdateBuZhen()
    if self.SceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN then
        self:RefreshBuzhenGridsPos()
        return 
    else
        self:RefreshUiActive(XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN)
        self:RefreshTeam()
        self:SwitchSelectTarge(XChessPursuitCtrl.SCENE_SELECT_TARGET.NONE)
        self:RefreshSkillGrids(false)

        local chessPursuitDrawCamera = self.CSXChessPursuitCtrlCom:GetChessPursuitDrawCamera()
        chessPursuitDrawCamera:SwitchChessPursuitCameraState(CS.XChessPursuitCameraState.None);
        chessPursuitDrawCamera:SwitchFieldOfViewState(CS.XFieldOfView.Far)
    end
end

--@endregion

--@region 各种子UI信息Refresh

--控制各个回合的界面整体显隐
function XUiChessPursuitMainScene:RefreshUiActive(sceneType)
    if self.SceneType == sceneType then
        return
    end

    if sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND then
        self.PanelBossRound.gameObject:SetActiveEx(true)
        self.PanelMyRound.gameObject:SetActiveEx(false)
        self.PanelBuzhen.gameObject:SetActiveEx(false)
        self.PanelCare.gameObject:SetActiveEx(true)
    elseif sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND then
        self.PanelBossRound.gameObject:SetActiveEx(false)
        self.PanelMyRound.gameObject:SetActiveEx(true)
        self.PanelBuzhen.gameObject:SetActiveEx(false)
        self.PanelCare.gameObject:SetActiveEx(true)
    elseif sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN then
        self.PanelBossRound.gameObject:SetActiveEx(false)
        self.PanelMyRound.gameObject:SetActiveEx(false)
        self.PanelBuzhen.gameObject:SetActiveEx(true)
        self.PanelCare.gameObject:SetActiveEx(false)
    end

    local disable = sceneType ~= XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND
    local needCallBack = not disable
    self.BtnBuChongzhi:SetDisable(disable, needCallBack)

    local bossIsClear = self.ChessPursuitMapDb:IsClear()
    disable = sceneType ~= XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND or bossIsClear
    needCallBack = not disable
    self.BtnBuJieshu:SetDisable(disable, needCallBack)
    self.BtnBuSaodang:SetDisable(disable, needCallBack)
    self.BtnShop:SetDisable(disable, needCallBack)
    for _, cardGrid in ipairs(self.UiChessPursuitCardGrids) do
        cardGrid:SetDisable(disable)
    end

    self.CardMyRound.gameObject:SetActiveEx(sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND)
    self.CardBossRound.gameObject:SetActiveEx(sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND)

    for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
        uiChessPursuitBuzhenGrid:SetActive(sceneType)
    end
end

function XUiChessPursuitMainScene:RefreshBloodAndCount()
    local ration = self.ChessPursuitMapDb:GetBossHp() / self.ChessPursuitMapBoss:GetInitHp()
    local itemIcon = XItemConfigs.GetItemIconById(XChessPursuitConfig.SHOP_COIN_ITEM_ID)
    local mapCfg = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
    local bossCfg = XChessPursuitConfig.GetChessPursuitBossTemplate(mapCfg.BossId)

    self.HeadObject:SetRawImage(bossCfg.HeadIcon)
    -- 如果BOSS发生扣血播放一下特效（abs防止浮点数误差）
    if math.abs(self.ImgExpSlider.fillAmount - ration) > 0.0001 then
        self:StopBossEffectBloodUpdateTimer()
        self.EffectBloodVolume.gameObject:SetActiveEx(true)
        self.BossEffectBloodUpdateTimer = XScheduleManager.ScheduleOnce(function()
            self.EffectBloodVolume.gameObject:SetActiveEx(false)
        end, 1500)
    end

    self.ImgExpSlider.fillAmount = ration

    local bloodVolume = ration * 100
    if bloodVolume > 0 and bloodVolume < 0.01 then
        bloodVolume = 0.01
    end
    self.TxtBloodVolume.text = string.format("%.2f%%", bloodVolume)

    self:RefreshCoinCount()
    self.RImgShopIcon:SetRawImage(itemIcon)
    self.BossKilled.gameObject:SetActiveEx(self.ChessPursuitMapDb:IsClear())
    self.ImgBossDie.gameObject:SetActiveEx(self.ChessPursuitMapDb:IsClear())
    self:RefreshTxtNumberBattles(self.ChessPursuitMapDb:GetBossBattleCount())
    self.TxtBossRule1.text = CSXTextManagerGetText("ChessPursuitBossStep", self.ChessPursuitMapBoss:GetBossStepMin(), self.ChessPursuitMapBoss:GetBossStepMax())
    local mapsCfg = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
    if mapsCfg.Stage == XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD then
        self.TxtBossRule2.text = CSXTextManagerGetText("ChessPursuitBossMaxRatio", CSXTextManagerGetText("ChessPursuitInfinite"))
    else
        local maxRatio = self.ChessPursuitMapBoss:GetMaxHpRatio()
        maxRatio = string.format("%.0f%%", maxRatio * 100)
        self.TxtBossRule2.text = CSXTextManagerGetText("ChessPursuitBossMaxRatio", maxRatio)
    end
end

function XUiChessPursuitMainScene:RefreshTxtNumberBattles(battleCount)
    local digits = self:GetIntDigits(battleCount)
    local defaultFontSizeDigits = 3    --3位数以内的都用默认的字体大小
    local fontSize = digits <= defaultFontSizeDigits and TxtNumberBattlesDefaultFontSize or math.max(TxtNumberBattlesDefaultFontSize - ((digits - defaultFontSizeDigits) * 6), 1)
    self.TxtNumberBattles.text = battleCount
    self.TxtNumberBattles.fontSize = fontSize
end

function XUiChessPursuitMainScene:GetIntDigits(number)
    if not number then
        return 0
    end

    local digits = 0
    local numberTemp = number
    while numberTemp > 0 do
        numberTemp = math.floor(numberTemp / 10) 
        digits = digits + 1
    end

    return digits
end

function XUiChessPursuitMainScene:RefreshCoinCount()
    self.TxtShopCoin.text = self.ChessPursuitMapDb:GetCoin()
end

--先从服务端数据里拿，再去临时数据里拿
function XUiChessPursuitMainScene:RefreshTeam()
    local sceneType = self:GetSceneType()
    for teamGridIndex,uiChessPursuitBuzhenGrids in ipairs(self.UiChessPursuitBuzhenGrids) do
        local teamMapDb = self.ChessPursuitMapDb:GetTeamCharacterIds(teamGridIndex)
        if next(teamMapDb) then
            uiChessPursuitBuzhenGrids:UpdateTeamHeadIconByMapDb(sceneType)
            local captainCharacterId = self.ChessPursuitMapDb:GetGridTeamCaptainCharacterIdIdByGridId(teamGridIndex)
            self.ChessPursuitTeams[teamGridIndex]:LoadCaptainCharacter(captainCharacterId)
            self.ChessPursuitTeams[teamGridIndex]:AddClick(function()
                self:OnCaptainClick(teamGridIndex)
            end)
        else
            local tempTeamData = XDataCenter.ChessPursuitManager.GetSaveTempTeamData(self.MapId, teamGridIndex)
            local captainId = tempTeamData and tempTeamData.TeamData[tempTeamData.CaptainPos] or 0
            uiChessPursuitBuzhenGrids:UpdateTeamHeadIconByTempTeam(sceneType)
            if captainId > 0 then
                local captainCharacterId = XRobotManager.CheckIdToCharacterId(captainId)
                self.ChessPursuitTeams[teamGridIndex]:LoadCaptainCharacter(captainCharacterId)
                self.ChessPursuitTeams[teamGridIndex]:AddClick(function()
                    self:OnCaptainClick(teamGridIndex)
                end)
            else
                self.ChessPursuitTeams[teamGridIndex]:Dispose()
            end
        end
    end

    self:InitGuideGrid()
end

function XUiChessPursuitMainScene:RefreshTeamActive(active)
    if self.ChessPursuitMapDb:IsClear() then
        return
    end

    self.UiChessPursuitGridFight:SetActiveEx(false)

    for i,chessPursuitTeam in ipairs(self.ChessPursuitTeams) do
        local tempActive = active or (chessPursuitTeam:GetCubeIndex() ~= (self.ChessPursuitMapDb:GetBossPos() + 1))
        chessPursuitTeam:SetActive(tempActive)

        if not tempActive then
            self.UiChessPursuitGridFight:SetActiveEx(true)
        end
    end
end

function XUiChessPursuitMainScene:CheckChessPursuitBossColliderIsActive(selectTarget)
    if self.ChessPursuitMapDb:IsClear() then
        return
    end

    if selectTarget == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
        self.ChessPursuitBoss:SetColliderActive(true)
        return
    elseif selectTarget == XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE then
        self.ChessPursuitBoss:SetColliderActive(false)
        return
    end

    local bossPos = self.ChessPursuitMapDb:GetBossPos() + 1
    for i, chessPursuitTeam in ipairs(self.ChessPursuitTeams) do
        if chessPursuitTeam:GetCubeIndex() == bossPos then
            self.ChessPursuitBoss:SetColliderActive(false)
            return
        end
    end
    self.ChessPursuitBoss:SetColliderActive(true)
end

function XUiChessPursuitMainScene:RefreshBuyCard(sceneType)
    self:RefreshCoinCount()
    self:RefreshCard()
end

function XUiChessPursuitMainScene:RefreshCard(sceneType)
    sceneType = sceneType or self.SceneType
    local cards = self.ChessPursuitMapDb:GetBuyedCards()
    for i=1,XChessPursuitCtrl.CARD_MAX_COUNT do
        self.UiChessPursuitCardGrids[i]:Refresh(self.UsedToGrid, self.UsedToBoss, sceneType)
    end

    self:RefreshBtnCardsDi(sceneType)
end

function XUiChessPursuitMainScene:RefreshSelectTipGrids(selectTarget)
    for i,v in ipairs(self.UiChessPursuitSelectTipGrids) do
        v:SetActiveEx(selectTarget == XChessPursuitCtrl.SCENE_SELECT_TARGET.TEAM)
    end

    self.UiChessPursuitSelectTipGridBoss:SetActiveEx(selectTarget == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS)

    self:RefreshTeamActive(selectTarget == XChessPursuitCtrl.SCENE_SELECT_TARGET.TEAM)
end

function XUiChessPursuitMainScene:RefreshSkillEffect()
    for i, v in ipairs(self.UiChessPursuitSkillEffectGrids) do
        v:Refresh()
    end
end

function XUiChessPursuitMainScene:LoadJianTouEffect()
    for i, v in ipairs(self.UiChessPursuitSkillEffectGrids) do
        v:LoadJianTou()
    end
    self.DestroyArrowEffectUpdateTimer = CS.XScheduleManager.ScheduleOnce(function()
        self:DestroyArrowEffect()
    end, DelayDestroyArrowEffectMilliSecond)
end

function XUiChessPursuitMainScene:DestroyArrowEffect()
    for i, v in ipairs(self.UiChessPursuitSkillEffectGrids) do
        v:DestroyArrow()
    end
end

function XUiChessPursuitMainScene:RefreshSkillGrids(isShow)
    if isShow then
        for i,v in ipairs(self.UiChessPursuitSkillGrids) do
            v:Refresh()
        end

        self.UiChessPursuitSkillGridBoss:Refresh()
    else
        for i,v in ipairs(self.UiChessPursuitSkillGrids) do
            v:SetActiveEx(false)
        end

        self.UiChessPursuitSkillGridBoss:SetActiveEx(false)
    end
end

function XUiChessPursuitMainScene:RefreshSkillGridsByTeamp()
    local tmCards = {}
    for i,v in ipairs(self.ChessPursuitMapDb:GetBuyedCards()) do
        tmCards[v.Id] = v
    end

    for i,v in ipairs(self.UiChessPursuitSkillGrids) do
        local cardIds = self.UsedToGrid[i-1]
        if cardIds then
            local cards = {}
            for k,cardId in pairs(cardIds) do
                table.insert(cards, tmCards[cardId])
            end
            v:RefreshByTemp(cards)
        else
            v:RefreshByTemp(nil)
        end
    end

    if next(self.UsedToBoss) then
        local cards = {}
        for i,cardId in ipairs(self.UsedToBoss) do
            table.insert(cards, tmCards[cardId])
        end
        self.UiChessPursuitSkillGridBoss:RefreshByTemp(cards)
    else
        self.UiChessPursuitSkillGridBoss:RefreshByTemp(nil)
    end
end

function XUiChessPursuitMainScene:RefreshSelectTipGridsPos()
    for i,v in ipairs(self.UiChessPursuitSelectTipGrids) do
        v:RefreshPos()
    end

    self.UiChessPursuitSelectTipGridBoss:RefreshPos()
end

function XUiChessPursuitMainScene:RefreshSkillGridsPos()
    for i,v in ipairs(self.UiChessPursuitSkillGrids) do
        v:RefreshPos()
    end

    self.UiChessPursuitSkillGridBoss:RefreshPos()
end

function XUiChessPursuitMainScene:RefreshBuzhenGridsPos()
    if self.UiChessPursuitBuzhenGrids then
        for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
            uiChessPursuitBuzhenGrid:RefreshPos()
        end
    end
end

function XUiChessPursuitMainScene:RefreshBtnCardsDi(sceneType)
    self.BtnCardsDi:SetDisable(sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND)
    local cards = self.ChessPursuitMapDb:GetBuyedCards()
    if sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND then
        self.BtnCardsDi.gameObject:SetActiveEx(true)
        self.CardsNone.gameObject:SetActiveEx(false)
    else
        self.BtnCardsDi.gameObject:SetActiveEx(next(cards))
        self.CardsNone.gameObject:SetActiveEx(not next(cards))
    end
end
--@endregion

--@region 通用函数

function XUiChessPursuitMainScene:SwitchSelectTarge(selectTarge)
    if selectTarge == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
        self.CSXChessPursuitCtrlCom:SetCameraMask(true)

        self.ChessPursuitBoss:HighLight()
        for i,chessPursuitTeam in ipairs(self.ChessPursuitTeams) do
            chessPursuitTeam:SetTransparent()
        end

        for i,chessPursuitCube in ipairs(self.ChessPursuitCubes) do
            chessPursuitCube:None()
        end

        for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
            uiChessPursuitBuzhenGrid.GameObject:SetActiveEx(false)
        end
    elseif selectTarge == XChessPursuitCtrl.SCENE_SELECT_TARGET.TEAM then
        self.CSXChessPursuitCtrlCom:SetCameraMask(true)
        
        self.ChessPursuitBoss:SetTransparent()
        for i,chessPursuitTeam in ipairs(self.ChessPursuitTeams) do
            chessPursuitTeam:HighLight()
        end

        for i,chessPursuitCube in ipairs(self.ChessPursuitCubes) do
            chessPursuitCube:None()
        end

        for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
            uiChessPursuitBuzhenGrid.GameObject:SetActiveEx(false)
        end
    elseif selectTarge == XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE then
        self.CSXChessPursuitCtrlCom:SetCameraMask(true)

        self.ChessPursuitBoss:SetTransparent()
        for i,chessPursuitTeam in ipairs(self.ChessPursuitTeams) do
            chessPursuitTeam:SetTransparent()
        end
        
        for i,chessPursuitCube in ipairs(self.ChessPursuitCubes) do
            chessPursuitCube:HighLight()
        end

        for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
            uiChessPursuitBuzhenGrid.GameObject:SetActiveEx(false)
        end
    elseif selectTarge == XChessPursuitCtrl.SCENE_SELECT_TARGET.DEFAULT then
        self.CSXChessPursuitCtrlCom:SetCameraMask(false)

        self.ChessPursuitBoss:Default()
        for i,chessPursuitTeam in ipairs(self.ChessPursuitTeams) do
            chessPursuitTeam:Default()
        end
        
        for i,chessPursuitCube in ipairs(self.ChessPursuitCubes) do
            chessPursuitCube:Default()
        end

        for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
            uiChessPursuitBuzhenGrid.GameObject:SetActiveEx(true)
        end
    else
        self.CSXChessPursuitCtrlCom:SetCameraMask(false)

        self.ChessPursuitBoss:None()
        for i,chessPursuitTeam in ipairs(self.ChessPursuitTeams) do
            chessPursuitTeam:None()
        end
        
        for i,chessPursuitCube in ipairs(self.ChessPursuitCubes) do
            chessPursuitCube:None()
        end

        for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
            uiChessPursuitBuzhenGrid.GameObject:SetActiveEx(true)
        end
    end
end

function XUiChessPursuitMainScene:GetSceneType()
    --状态机未执行完即返回
    if self.CurrentActionMachine then
        return self.SceneType
    end
    -- 当前是BOSS回合，需要等到EndRound才能切换到自己的回合
    if self.SceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND then
        if self.EndRound and self.ChessPursuitSyncActionQueue:GetCount() <= 0 then
            return XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND
        else
            return XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND
        end
    else
        --布阵阶段
        if self.ChessPursuitMapDb:NeedBuZhen() then
            return XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN
        end

        --BOSS的ACTION是否完了
        if self.ChessPursuitSyncActionQueue:GetCount() > 0 then
            self:SetEndRound(false)
            return XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND
        end

        return XChessPursuitCtrl.SCENE_UI_TYPE.MY_ROUND
    end
end

function XUiChessPursuitMainScene:PlayStep(stepId, callBack)
    local cfg = XChessPursuitConfig.GetChessPursuitStepTemplate(stepId)
    if not cfg then
        return
    end
    self.RImgEffectSteps:SetRawImage(cfg.Icon)
    self.UiChessPursuitMainAnimQueue:Push("RImgEffectEnable", function()
        self.PanelSteps.gameObject:SetActiveEx(true)
    end, function ()
        self.RootUi:PlayAnimation("RImgEffectDisable", function ()
            self.PanelSteps.gameObject:SetActiveEx(false)
            if callBack then
                callBack()
            end
        end)
    end)
end

function XUiChessPursuitMainScene:AddSelectCard(card, selectTarget, gridIndex)
    if selectTarget == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
        table.insert(self.UsedToBoss, card.Id)
    elseif selectTarget == XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE then
        --服务端index从0开始
        local tempGridIndex = gridIndex - 1
        if not self.UsedToGrid[tempGridIndex] then
            self.UsedToGrid[tempGridIndex] = {}
        end

        table.insert(self.UsedToGrid[tempGridIndex], card.Id)
    end

    for i,uiChessPursuitSkillEffectGrids in ipairs(self.UiChessPursuitSkillEffectGrids) do
        if selectTarget == uiChessPursuitSkillEffectGrids:GetTargetType() then
            if uiChessPursuitSkillEffectGrids:GetTargetType() == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
                uiChessPursuitSkillEffectGrids:LoadUseCardEffect()
                break
            else
                if gridIndex == i then
                    uiChessPursuitSkillEffectGrids:LoadUseCardEffect()
                    break
                end
            end
        end
    end

    for i,v in ipairs(self.ChessPursuitMapDb:GetBuyedCards()) do
        if card.Id == v.Id then
            self.UiChessPursuitCardGrids[i]:SetDisable(true)
            break
        end
    end
end

function XUiChessPursuitMainScene:RemoveSelectCard(card)
    if not card then
        return
    end
    for gridIndex,list in pairs(self.UsedToGrid) do
        for i, cardId in ipairs(list) do
            if cardId == card.Id then
                table.remove(list, i)
                break
            end
        end
    end

    for i,cardId in pairs(self.UsedToBoss) do
        if cardId == card.Id then
            table.remove(self.UsedToBoss, i)
            break
        end
    end
end

function XUiChessPursuitMainScene:SetEndRound(vlaue)
    self.EndRound = vlaue
end

--能否扫荡：只要每个点有打过即可
function XUiChessPursuitMainScene:IsCanSaoDang()
    local mapsCfg = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
    if mapsCfg.Stage ~= XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD then
        for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
            if uiChessPursuitBuzhenGrid:GetBossHurMax() <= 0 then
                return false
            end
        end
    
        return true
    else
        return false
    end
end

--能扫荡而且造成的伤害达到最大，弹出提示窗
function XUiChessPursuitMainScene:OpenSaoDangDangTips()
    if self.ChessPursuitMapDb:IsClear() then
        return
    end

    local maxRatio = self.ChessPursuitMapBoss:GetMaxHpRatio()
    for i,uiChessPursuitBuzhenGrid in ipairs(self.UiChessPursuitBuzhenGrids) do
        if uiChessPursuitBuzhenGrid:GetBossHurMax() < maxRatio then
            XDataCenter.ChessPursuitManager.RemoveSaoDangIsAlreadyAutoOpen(self.MapId)
            return
        end
    end

    if XDataCenter.ChessPursuitManager.IsSaoDangAlreadyAutoOpen(self.MapId) then
        return
    end
    
    self:OnBtnBuSaodang(true)
end

function XUiChessPursuitMainScene:PlayEnableAnimation()
    local sceneType = self:GetSceneType()
    local aniName
    if sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN or sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND then
        aniName = "PanelBuzhenEnable"
    else
        aniName = "PanelCareEnable"
    end
    self.RootUi:PlayAnimationWithMask(aniName)
end

function XUiChessPursuitMainScene:CanOpenUiChessPursuitBuffTips(targetType, cubeIndex)
    local sceneType = self:GetSceneType()
    if sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN then
        return false
    end

    if targetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
        local xChessPursuitCardDbList = self.ChessPursuitMapDb:GetBossCardDb()

        if next(xChessPursuitCardDbList) then
            return true
        else
            return false
        end
    else
        local xChessPursuitMapGridCardDb = self.ChessPursuitMapDb:GetGridCardDb()

        for _,v in ipairs(xChessPursuitMapGridCardDb) do
            if v.Id == cubeIndex-1 then
                local xChessPursuitCardDbList = v.Cards
                if next(xChessPursuitCardDbList) then
                    return true
                else
                    return false
                end
            end
        end
    end

    return false
end

function XUiChessPursuitMainScene:PlayBossKillerAnimation(callBack)
    if self.ChessPursuitMapDb:IsClear() then
        self.PanelFull.gameObject:SetActiveEx(true)
        self.ChessPursuitBoss.GameObject:SetActiveEx(false)
        self.RootUi:PlayAnimationWithMask("PanelFullEnable", function ()
            self.RootUi:PlayAnimationWithMask("PanelFullDisable", function ()
                self.PanelFull.gameObject:SetActiveEx(false)
                if callBack then
                    callBack()
                end

                self.RootUi:OnBtnBackClick()
                
                local mapsCfg = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
                if mapsCfg.Stage == XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_DEFAULT then
                    if XDataCenter.ChessPursuitManager.IsOpenFightHeard() then
                        XUiManager.TipMsg(CS.XTextManager.GetText("ChessPursuitHardOpen"))
                    end
                end
            end)
        end)
    end
end

function XUiChessPursuitMainScene:RequestChessPursuitEnterMapData(mapId, callBack)
    XDataCenter.ChessPursuitManager.RequestChessPursuitEnterMapData(mapId, function ()
        local config = XChessPursuitConfig.GetChessPursuitMapTemplate(mapId)
        self.ChessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(mapId)
        self.ChessPursuitMapBoss = XDataCenter.ChessPursuitManager.GetChessPursuitMapBoss(config.BossId)
        self.ChessPursuitSyncActionQueue = XDataCenter.ChessPursuitManager.GetChessPursuitSyncActionQueue()

        if self.ChessPursuitSyncActionQueue:GetCount() <= 0 then
            self:SetEndRound(true)
        end

        if callBack then
            callBack()
        end
    end)
end

--@endregion

return XUiChessPursuitMainScene