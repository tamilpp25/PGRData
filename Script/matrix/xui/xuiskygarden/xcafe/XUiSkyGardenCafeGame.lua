
---@class XUiSkyGardenCafeGame : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyGardenCafeControl
---@field _Cards XUiGridSGCardItem[]
local XUiSkyGardenCafeGame = XLuaUiManager.Register(XLuaUi, "UiSkyGardenCafeGame")

local XUiGridSGCardBattleItem = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGCardBattleItem")
local XUiGridSGCardBattleSmallItem = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGCardBattleSmallItem")

local CardUpdateEvent = XMVCA.XSkyGardenCafe.CardUpdateEvent
local CardContainer = XMVCA.XSkyGardenCafe.CardContainer
local DlcEventId = XMVCA.XBigWorldService.DlcEventId

function XUiSkyGardenCafeGame:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafeGame:OnStart()
    self:InitView()
    XMVCA.XBigWorldGamePlay:ActivateVCamera("UiSkyGardenCoffeeCameraBattle", 0)
    XEventManager.AddEventListener(DlcEventId.EVENT_CAFE_ROUND_BEGIN, self.OnRoundBegin, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_CAFE_UPDATE_PLAY_CARD, self.OnPlayCardUpdate, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_CAFE_HUD_REFRESH, self.RefreshHud, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_CAFE_RE_DRAW_CARD, self.RefreshReDraw, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_CAFE_ROUND_NPC_SHOW, self.OnNpcShow, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_CAFE_BAR_COUNTER_NPC_CHANGED, self.RefreshBarCounter, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE, self.RefreshLibCount, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_CAFE_SETTLEMENT, self.OnSettle, self)

    self:OpenChildUi("UiSkyGardenCafeComponent")
end

function XUiSkyGardenCafeGame:OnEnable()
    self:PlayAnimation("Show")
end

function XUiSkyGardenCafeGame:OnDestroy()
    XEventManager.RemoveEventListener(DlcEventId.EVENT_CAFE_ROUND_BEGIN, self.OnRoundBegin, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_CAFE_UPDATE_PLAY_CARD, self.OnPlayCardUpdate, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_CAFE_HUD_REFRESH, self.RefreshHud, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_CAFE_RE_DRAW_CARD, self.RefreshReDraw, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_CAFE_ROUND_NPC_SHOW, self.OnNpcShow, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_CAFE_BAR_COUNTER_NPC_CHANGED, self.RefreshBarCounter, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE, self.RefreshLibCount, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_CAFE_SETTLEMENT, self.OnSettle, self)

    if self._DialogTimer then
        XScheduleManager.UnSchedule(self._DialogTimer)
    end
    XMVCA.XBigWorldGamePlay:ActivateVCamera("UiSkyGardenCoffeeCameraMain", 0, true)
end

function XUiSkyGardenCafeGame:InitUi()
    --大牌
    self._ItemDict = {}
    --小牌
    self._ItemSmallDict = {}
    local isEndless = self._Control:IsEndlessChallengeStage()
    self.BtnGiveup.gameObject:SetActiveEx(not isEndless)
    self.BtnLeave.gameObject:SetActiveEx(isEndless)
    self.BtnSkip.gameObject:SetActiveEx(false)
    self.BtnClick.gameObject:SetActiveEx(false)
    
    self.PanelTalk.gameObject:SetActiveEx(false)
    self.PanelBubble.gameObject:SetActiveEx(false)
    self.ListBuff.gameObject:SetActiveEx(true)
    self.PanelReDraw.gameObject:SetActiveEx(false)
    self.UiBigCard.gameObject:SetActiveEx(false)
    self.PanelCardDetail.gameObject:SetActiveEx(false)
    
    self.SafeAreaContentPane = self.Transform:FindTransform("SafeAreaContentPane")
    if not self.PanelDeal then
        self.PanelDeal = self.SafeAreaContentPane:Find("PanelGame/PanelDeal")
    end
    
    self._PanelTarget = require("XUi/XUiSkyGarden/XCafe/Panel/XUiPanelSGCafeBill").New(self.PanelTarget, self)
    
    self._BarTableClickCd = self._Control:GetBarTableClickCd()
    self._DialogShowTime = self._BarTableClickCd * 1000 - 400
    
    self._Control:SetTargetWorldPosition(XMVCA.XSkyGardenCafe.HudType.CoffeeHud, self.TargetCoffee.transform.position)
    self._Control:SetTargetWorldPosition(XMVCA.XSkyGardenCafe.HudType.ReviewHud, self.TargetReview.transform.position)

    local isSelect = self._Control:IsSkipAnimation()
    self.BtnSwitch:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiSkyGardenCafeGame:InitCb()
    self.GiveUpCb = function()
        self._Control:GetBattle():GiveUp(function()
            self:Close()
        end)
    end
    self.BtnGiveup.CallBack = function()
        local data = XMVCA.XBigWorldCommon:GetPopupConfirmData()
        data:InitInfo(nil, self._Control:GetQuitGameText()):InitToggleActive(false):InitSureClick(nil, self.GiveUpCb)
        
        XMVCA.XBigWorldUI:OpenConfirmPopup(data)
    end
    
    self.BtnLeave.CallBack = function() 
        self:Close()
    end
    
    self.BtnCollapse.CallBack = function() 
        self:OnBtnCollapseClick()
    end
    
    self.BtnStart.CallBack = function() 
        self:OnBtnStartClick()
    end
    
    self.BtnClick.CallBack = function() 
        self:OnBtnRoleClick()
    end
    
    self.BtnReDraw.CallBack = function() 
        self:OnBtnReDrawClick()
    end
    
    self.BtnLibrary.CallBack = function()
        self:OnBtnLibraryClick()
    end
    
    self.BtnCloseDetail.CallBack = function() 
        self:RefreshBigItem(false)
    end
    
    self.BtnSwitch.CallBack = function() 
        self:OnBtnSwitchClick()
    end
    
    self._Control:SetCardUpdateHandler(handler(self, self.CardUpdate))
    
    self._CardUpdateFunc = {
        [CardUpdateEvent.Create] = handler(self, self.OnCardCreate),
        [CardUpdateEvent.Reclaim] = handler(self, self.OnCardReclaim),
        [CardUpdateEvent.CardClick] = handler(self, self.OnCardClick),
        [CardUpdateEvent.RefreshContainer] = handler(self, self.OnCardContainerRefresh),
    }
end

function XUiSkyGardenCafeGame:InitView()
    self._IsReviewStage = self._Control:IsReviewStage()

    self.BtnLibrary.gameObject:SetActiveEx(not self._Control:GetBattle():IsStoryStage())

    self.UiSkyGardenCafeGridBuff.gameObject:SetActiveEx(false)
    local battle = self._Control:GetBattle()
    local stageId = battle:GetStageId()
    local buffListId = self._Control:GetStageBuffListId(stageId)
    if buffListId and buffListId > 0 then
        self._GridBuff = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGBuffItem").New(self.UiSkyGardenCafeGridBuff, self, buffListId)
        self._GridBuff:Open()
    end
    local round = self._Control:GetStageRounds(stageId)
    self._PanelRound = require("XUi/XUiSkyGarden/XCafe/Panel/XUiPanelSGRound").New(self.PanelStageDetailNormal, self, round)
end

function XUiSkyGardenCafeGame:OnRoundBegin()
    self:RefreshView()
    local round = self._Control:GetBattle():GetBattleInfo():GetRound()
    self._PanelRound:Refresh(round)
end

function XUiSkyGardenCafeGame:OnPlayCardUpdate()
    local battleInfo = self._Control:GetBattle():GetBattleInfo()
    local coffee = battleInfo:GetAddScore()
    local review = battleInfo:GetAddReview()
    self.TxtPreivew.text = coffee
    self.TxtAdd.gameObject:SetActiveEx(review > 0)
    self.TxtMinus.gameObject:SetActiveEx(review < 0)
    if review > 0 then
        self.TxtAdd.text = string.format("+%d", review)
    end

    if review < 0 then
        self.TxtMinus.text = review
    end
end

function XUiSkyGardenCafeGame:RefreshView()
    self:OnPlayCardUpdate()
    self:RefreshLibCount()
end

function XUiSkyGardenCafeGame:RefreshLibCount()
    local dataList = self._Control:GetBattle():GetRoundEntity():GetPoolEntities()
    self.BtnLibrary:SetNameByGroup(0, dataList and #dataList or 0)
end

function XUiSkyGardenCafeGame:OnSettle()
    self.SafeAreaContentPane.gameObject:SetActiveEx(false)
end

function XUiSkyGardenCafeGame:RefreshBarCounter()
    self._BarTableUUId = self._Control:GetBattle():GetBarCounterNpcUUID()
    self.BtnClick.gameObject:SetActiveEx(self._BarTableUUId and self._BarTableUUId > 0)
end

function XUiSkyGardenCafeGame:RefreshReDraw(isOpen)
    self.PanelReDraw.gameObject:SetActiveEx(isOpen)
    if not isOpen then
        return
    end
    local btnText = self._Control:GetBtnReDrawText()
    self.BtnReDraw:SetNameByGroup(0, btnText)
end

function XUiSkyGardenCafeGame:OnCardCreate(event, containerType, index , card)
    local cardItem = self:FetchCardItem(card, containerType)
    if not cardItem then
        XLog.Error("卡牌获取异常：", event, containerType, index , card)
        return
    end
    local dataList = self:GetCardEntities(containerType)
    local data = dataList and dataList[index + 1] or nil
    cardItem:Refresh(data, containerType, false)
end

function XUiSkyGardenCafeGame:OnCardReclaim(event, containerType, index , card)
    local cardItem = self:FetchCardItem(card, containerType)
    if not cardItem then
        XLog.Error("卡牌获取异常：", event, containerType, index , card)
        return
    end
    cardItem:Reclaim()
end

function XUiSkyGardenCafeGame:OnCardClick(event, containerType, index , card)
    if containerType == CardContainer.ReDraw then
        local cardItem = self:FetchCardItem(card, containerType)
        if not cardItem then
            XLog.Error("卡牌获取异常：", event, containerType, index , card)
            return
        end
        cardItem:SetSelect(index + 1)
    else
        local dataList = self:GetCardEntities(containerType)
        local data = dataList and dataList[index + 1] or nil
        self:RefreshBigItem(true, containerType, data)
    end
end

function XUiSkyGardenCafeGame:OnCardContainerRefresh(event, containerType, index , card)
    local cardItem = self:FetchCardItem(card, containerType)
    if not cardItem then
        XLog.Error("卡牌获取异常：", event, containerType, index , card)
        return
    end
    local dataList = self:GetCardEntities(containerType)
    local data = dataList and dataList[index + 1] or nil
    cardItem:Refresh(data, containerType, false)
end

function XUiSkyGardenCafeGame:CardUpdate(evt, type, index, card)
    local func = self._CardUpdateFunc[evt]
    if not func then
        return
    end
    func(evt, type, index, card)
end

function XUiSkyGardenCafeGame:OnNpcShow(isShow)
    --self.SafeAreaContentPane.gameObject:SetActiveEx(not isShow)
    self.BtnLibrary.gameObject:SetActiveEx(not isShow and not self._Control:GetBattle():IsStoryStage())
    self.PanelDeal.gameObject:SetActiveEx(not isShow)
    if self._GridBuff then
        if isShow then
            self._GridBuff:Close()
        else
            self._GridBuff:Open()
        end
    end
    if isShow then
        self._PanelTarget:Close()
        if self._GridBuff then
            self._GridBuff:Close()
        end
    else
        self._PanelTarget:Open()
        if self._GridBuff then
            self._GridBuff:Open()
        end
    end
end

function XUiSkyGardenCafeGame:OnDealRefresh()
end

function XUiSkyGardenCafeGame:RefreshHud(id, target, offset, type, value)
    if type == XMVCA.XSkyGardenCafe.HudType.DialogHud then
        self.PanelTalk.gameObject:SetActiveEx(true)
        self.TxtTalk.text = value
        self._DialogTimer = XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.PanelTalk) then
                return
            end
            self._DialogTimer = nil
            self.PanelTalk.gameObject:SetActiveEx(false)
        end, self._DialogShowTime)
    end
end

---@param card XSkyGardenCafeCardEntity
function XUiSkyGardenCafeGame:RefreshBigItem(isShow, containerType, card)
    if not self._BigItem then
        self._BigItem = self:FetchCardItem(self.UiBigCard, CardContainer.Deck)
    end
    self.PanelCardDetail.gameObject:SetActiveEx(isShow)
    if isShow then
        self._BigItem:Open()
        self._BigItem:Refresh(card, containerType, true)
        card:PrintBuff()
    else
        self._BigItem:Close()
    end
end

function XUiSkyGardenCafeGame:OnBtnCollapseClick()
    self._Control:GetBattle():Collapse()
end

function XUiSkyGardenCafeGame:OnBtnStartClick()
    self._Control:GetBattle():Play()
end

function XUiSkyGardenCafeGame:OnBtnRoleClick()
    if not self._BarTableUUId or self._BarTableUUId <= 0 then
        self.BtnClick.gameObject:SetActiveEx(false)
        return
    end
    local lastClick = self._LastClickRoleTime or 0
    local interval = os.time() - lastClick
    if interval < self._BarTableClickCd then
        return
    end
    self._LastClickRoleTime = os.time()
    self._Control:GetBattle():DoNpcClicked(self._BarTableUUId)
end

function XUiSkyGardenCafeGame:OnBtnReDrawClick()
    self._Control:GetBattle():GetRoundEntity():ReDrawToDeck()
end

function XUiSkyGardenCafeGame:OnBtnLibraryClick()
    XLuaUiManager.Open("UiSkyGardenCafeLibrary", false)
end

function XUiSkyGardenCafeGame:OnBtnSwitchClick()
    local value = self._Control:IsSkipAnimation()
    self._Control:MarkSkipAnimation(not value)
end

--- 根据容器类型获取卡牌视图
---@param card XCafe.XCard
---@param containerType number
---@return XUiGridSGCardBattleItem | XUiGridSGCardBattleSmallItem
function XUiSkyGardenCafeGame:FetchCardItem(card, containerType)
    if not card then
        return
    end
    local insId = card.gameObject:GetInstanceID()
    if self._ItemDict[insId] then
        return self._ItemDict[insId]
    end
    if containerType == CardContainer.ReDraw or containerType == CardContainer.Deck then
        local item = XUiGridSGCardBattleItem.New(card, self._Control)
        self._ItemDict[insId] = item
        return item
    else
        local item = XUiGridSGCardBattleSmallItem.New(card, self._Control)
        self._ItemDict[insId] = item
        return item
    end
end

--- 根据容器类型获取卡牌数据
---@param containerType number
---@return XSkyGardenCafeCardEntity[]
function XUiSkyGardenCafeGame:GetCardEntities(containerType)
    local entity = self._Control:GetBattle():GetRoundEntity()
    if containerType == CardContainer.Deal then
        return entity:GetDealCardEntities()
    elseif containerType == CardContainer.ReDraw then
        return entity:GetReDrawCardEntities()
    elseif containerType == CardContainer.Deck then
        return entity:GetDeckCardEntities()
    end
    XLog.Error("容器类型:" .. containerType .. "，不存在卡牌数据")
    return {}
end

function XUiSkyGardenCafeGame:SetBillEffect(isCoffee, isShow)
    local obj = isCoffee and self.FxScoreYellow or self.FxScoreBlue
    obj.gameObject:SetActiveEx(false)
    if isShow then
        obj.gameObject:SetActiveEx(true)
    end
end