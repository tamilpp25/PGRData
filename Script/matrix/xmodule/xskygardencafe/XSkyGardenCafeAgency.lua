local XBigWorldActivityAgency = require("XModule/XBase/XBigWorldActivityAgency")

---@class XSkyGardenCafeAgency : XBigWorldActivityAgency
---@field private _Model XSkyGardenCafeModel
local XSkyGardenCafeAgency = XClass(XBigWorldActivityAgency, "XSkyGardenCafeAgency")
function XSkyGardenCafeAgency:OnInit()
    self.StageType = {
        Story = 1, --剧情
        Challenge = 2, --挑战
        EndlessChallenge = 3, --无限挑战
    }

    self.UIType = {
        HandleBook = 1, --图鉴
        DeckEditor = 2, --卡组编辑
    }
    
    self.HudType = {
        CoffeeHud = 1,
        ReviewHud = 2,
        EmojiHud = 3,
        DialogHud = 4,
    }

    --卡组Id
    self.DeckIds = { 1, 2, 3 }
    
    self.CardUpdateEvent = {
        Create = 1,
        LongPress = 2,
        LongPressUp = 3,
        Reclaim = 4,
        Deck2Deal = 5,
        Deal2Deck = 6,
        DealSwitch = 7,
        CardClick = 8,
        RefreshContainer = 9,
    }
    
    self.CardContainer = {
        Deck = 2,
        Deal = 3,
        ReDraw = 4,
    }
    
    -- 抽卡类型
    self.DrawCardType = {
        --回合抽卡
        Round = 1,
        --出牌抽卡
        PlayCard = 2
    }
    
    self.EffectTriggerId = {
        --出牌时
        Deck2Deal = 1,
        --保留时
        KeepInDeck = 2,
        --弃牌时
        Discard = 3,
        --抽卡时
        DrawCard = 4,
        --卡牌资源发生改变时
        CardResourceChanged = 5,
        --回合资源发生改变
        RoundResourceChanged = 6,
        --回合开始时
        RoundBegin = 7,
        --回合结束
        RoundEnd = 8,
    }
    
    self.EffectType = {
        --优先抽牌
        PriorityLottery = 1,
        --保留手牌
        StayInHand = 2,
        --移除
        Remove = 3,
        --替换
        Replace = 4,
        --非定向抽取
        NonDirectedLottery = 5,
        --定向抽取
        TargetedLottery = 6,
        --插入
        Insert = 7,
        --发牌调整
        Pool2Deck = 8,
        --出牌区数量修改
        DealCountChange = 9,
        --改变卡的基础资源
        ResourceChange = 10,
        --卡的资源转化
        ResourceTransform = 11,
        --复制
        Copy = 12,
        --出牌区下标判断
        DealIndex = 13,
        --卡牌数量
        CardCount = 14,
        --出牌时携带符合条件的卡牌一起使用，且不占用槽位
        CarryWhenUse = 15,
        --卡牌使用次数
        CardUseCount = 16,
        --游戏回合
        GameRound = 17,
        --触发其他Buff
        ApplyOther = 18,
        --游戏回合持续Buff
        GameRoundSustain = 19,
        --卡牌资源永久改变
        ResourceChangeForever = 20,
        --创建新的卡牌
        CreateNew = 21,
    }
    
    self.ResourceType = {
        --咖啡销量
        Coffee = 1,
        --好评
        Review = 2,
    }
    
    --临时效果，在Buff销毁时复原
    self.NotPermanentEffectType = {
        [self.EffectType.DealCountChange] = true,
        [self.EffectType.Pool2Deck] = true,
        [self.EffectType.Remove] = true,
        [self.EffectType.CreateNew] = true,
    }
    
    self.Pattern = "{(%d+)}"
    
    self.RichTextImageCallBackCb = handler(self, self.RichTextImageCallBack)
end

function XSkyGardenCafeAgency:InitRpc()
    XRpc.NotifyBigWorldCafeSettle = handler(self, self.NotifyBigWorldCafeSettle)
    XRpc.NotifyBigWorldNewCafeCard = handler(self, self.NotifyBigWorldNewCafeCard)
end

function XSkyGardenCafeAgency:InitEvent()
end

function XSkyGardenCafeAgency:Reset()
    self._Model:Reset()
end

function XSkyGardenCafeAgency:OpenMainUi(id, args)
    if not self._Model:IsOpen() then
        XLog.Error("活动未开启")
        return
    end
    if args then
        self._X = tonumber(args[0])
        self._Y = tonumber(args[1])
        self._Z = tonumber(args[2])
    end
    --打开活动主界面
    XLuaUiManager.Open("UiSkyGardenCafeMain")
    
    XMVCA.XBigWorldGamePlay:SetCurNpcAndAssistActive(false, false)
end

function XSkyGardenCafeAgency:EnterGameLevel()
    if not XMVCA.XBigWorldGamePlay:IsInGame() then
        return
    end
    local curLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    if curLevelId == self:GetLevelId() then
        local data = self._Model:GetFightData()
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ENTER_FIGHT, data.StageId, data.DeckId)
        return
    end
    XMVCA.XBigWorldMap:SendTeleportCommand(self:GetLevelId(), self._X, self._Y, self._Z, 0)
end

function XSkyGardenCafeAgency:ExitGameLevel()
    --判断是否返回到上个Level
    if not XMVCA.XSkyGardenCafe:IsEnterLevel() then
        return
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_TELEPORT_PLAYER_TO_LAST_LEVEL)
end

function XSkyGardenCafeAgency:GetName()
    return self._Model:GetActivityName() 
end

function XSkyGardenCafeAgency:OnLevelBeginUpdate()
    local data = self._Model:GetFightData()
    if not data then
        return
    end
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ENTER_FIGHT, data.StageId, data.DeckId)
end

function XSkyGardenCafeAgency:OnLeaveLevel()
    self:DoLevelLevel()
end

function XSkyGardenCafeAgency:DoLevelLevel()
    --切换相机
    XMVCA.XBigWorldGamePlay:DeactivateVCamera("UiSkyGardenCoffeeCameraMain")
    --显示指挥官
    XMVCA.XBigWorldGamePlay:SetCurNpcAndAssistActive(true, false)
    XMVCA.XBigWorldUI:SafeClose("UiSkyGardenCafeMain")
end

--region Util

function XSkyGardenCafeAgency:GetChangeValueByPercent(oldValue, percent)
    local newValue = oldValue * (1 + percent)
    return math.floor(newValue - oldValue)
end

--endregion

function XSkyGardenCafeAgency:RequestActivityData()
    XNetwork.Call("BigWorldCafeDataRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        --更新对局数据
        self._Model:UpdateBattle(res.CafeGambling)
        --更新牌组数据
        self._Model:UpdateCardDeck(res.CardGroupList, true)
        --更新关卡信息
        self._Model:InitStageInfo(res.CafeStageList)
        --更新玩家数据
        self._Model:UpdateOwnCardDeck(res.CardDict)
    end)
end

--- 结算通知
--------------------------
function XSkyGardenCafeAgency:NotifyBigWorldCafeSettle(data)
    if not data then
        return
    end
    
    local stageId = data.StageId
    local info = self._Model:GetStageInfo(stageId)
    info:DoSettle(data.Star, data.SumSales)
    local battle = self._Model:GetBattleInfo()
    battle:DoSettle(data.SumSales, data.AwardList)
    
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_SETTLEMENT, stageId)
end

function XSkyGardenCafeAgency:NotifyBigWorldNewCafeCard(data)
    if not data then
        return
    end
    local deck = self._Model:GetOwnCardDeck()
    deck:UpdateCards({
        [data.CardId] = data.Num,
    })
end

function XSkyGardenCafeAgency:FightRequestData()
    local battleInfo = self._Model:GetBattleInfo()
    local stageId = battleInfo:GetStageId()
    --1:没有正在进行的游戏数据 2:有正在进行的游戏数据
    local state = 1
    if stageId > 0 then
        state = 2
    end
    
    return {
        GameplayState = state
    }
end

function XSkyGardenCafeAgency:FightRequestGiveUp()
    XNetwork.Call("BigWorldCafeGiveUpRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:GetBattleInfo():Reset()
    end)
end

--- 富文本图文并排回调
---@param key string BigWorldAssetUrl.tab的Key值
---@param image UnityEngine.UI.Image
function XSkyGardenCafeAgency:RichTextImageCallBack(key, image)
    if XTool.UObjIsNil(image) then
        XLog.Error("创建图片失败! Image组件为空")
        return
    end
    local url = XMVCA.XBigWorldResource:GetAssetUrl(key)
    if string.IsNilOrEmpty(url) then
        XLog.Error("创建图片失败! BigWorldAssetUrl.tab 不存在主键 = " .. key)
        return
    end
    image:SetSprite(url)
end

return XSkyGardenCafeAgency