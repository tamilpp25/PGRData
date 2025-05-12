local XUiPokerGuessing2Card = require("XUi/XUiPokerGuessing2/Game/XUiPokerGuessing2Card")

---@class XUiPokerGuessing2Character : XUiNode
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2Character = XClass(XUiNode, "XUiPokerGuessing2Character")

function XUiPokerGuessing2Character:OnStart(isPlayer)
    ---@type XUiPokerGuessing2Card[]
    self._Cards = {
        self.GridCard1 and XUiPokerGuessing2Card.New(self.GridCard1, self),
        self.GridCard2 and XUiPokerGuessing2Card.New(self.GridCard2, self),
        self.GridCard3 and XUiPokerGuessing2Card.New(self.GridCard3, self),
        self.GridCard4 and XUiPokerGuessing2Card.New(self.GridCard4, self),
        self.GridCard5 and XUiPokerGuessing2Card.New(self.GridCard5, self),
    }
    if self._Data then
        XLog.Warning("[XUiPokerGuessing2Character] data已经赋值了")
    else
        self._Data = false
    end
    self._IsPlayer = isPlayer

    if self.PutDownEffect then
        self.PutDownEffect.gameObject:SetActiveEx(false)
    end
    if self.SuccessEffect then
        self.SuccessEffect.gameObject:SetActiveEx(false)
    end
end

function XUiPokerGuessing2Character:SetAllCardPutOnGroup(value)
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        card:SetPutOnGround(value)
    end
end

--对手牌重新排序
function XUiPokerGuessing2Character:ResortCards()
    ---@type XUiPokerGuessing2Card[]
    local cards = {}
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        if not card:IsPutOnGround() then
            table.insert(cards, card)
        end
    end
    table.sort(cards, function(a, b)
        return a:GetOriginalSiblingIndex() < b:GetOriginalSiblingIndex()
    end)
    for i = 1, #cards do
        local card = cards[i]
        card.Transform:SetSiblingIndex(i - 1)
    end
end

function XUiPokerGuessing2Character:RevertCardParentAndPosition(except)
    if except then
        for i = 1, #self._Cards do
            local card = self._Cards[i]
            if card ~= except then
                card:ReverParent()
            end
        end
        for i = 1, #self._Cards do
            local card = self._Cards[i]
            if card ~= except then
                card:ReverSiblingIndex()
            end
        end
    else
        for i = 1, #self._Cards do
            local card = self._Cards[i]
            if not card:IsOnOriginalParent() then
                card:ReverParent()
            end
        end
        local cards = {}
        for i = 1, #self._Cards do
            local card = self._Cards[i]
            table.insert(cards, card)
        end
        table.sort(cards, function(a, b)
            return a:GetOriginalSiblingIndex() < b:GetOriginalSiblingIndex()
        end)
        for i = 1, #cards do
            local card = cards[i]
            card:ReverSiblingIndex()
        end
    end
end

---@param data XUiPokerGuessing2CharacterData
function XUiPokerGuessing2Character:Update(data)
    self._Data = data
    self:RevertCardParentAndPosition()
    if self.GridCard or self.GridCard1 then
        XTool.UpdateDynamicItem(self._Cards, data.Cards, self.GridCard or self.GridCard1, XUiPokerGuessing2Card, self)
    end
    if not data.IsLock then
        if self.PanelNone then
            self.PanelNone.gameObject:SetActiveEx(false)
        end
        self.RImgCharacter.gameObject:SetActiveEx(true)
        self.RImgCharacter:SetRawImage(data.Icon)
        self.TxtName.text = data.Name

        for i = 1, #self._Cards do
            self._Cards[i]:SetParentOnDrag(self.NodeToPutDown)
        end
        if self._IsPlayer then
            for i = 1, #self._Cards do
                self._Cards[i]:SetIsCanDrag(true)
            end
        else
            for i = 1, #self._Cards do
                self._Cards[i]:SetVisibleCardFace(false)
                self._Cards[i]:SetIsCanDrag(false)
            end
        end
    else
        if self.PanelNone then
            self.PanelNone.gameObject:SetActiveEx(true)
            self.RImgCharacter.gameObject:SetActiveEx(false)
            self.PanelTalk.gameObject:SetActiveEx(false)
            -- 如果是因为前置关卡未通关, 改成 "神秘对手"
            self.TxtName.text = XUiHelper.GetText("PokerGuessing2UnknownName")
        end
    end
end

function XUiPokerGuessing2Character:UpdateTimeForLockedStage()
    -- 如果是因为时间导致的,改成倒计时
    if self._Data.IsLock4Time then
        local timerId = self._Data.TimeId
        if timerId and timerId > 0 then
            if XFunctionManager.CheckInTimeByTimeId(timerId) then
                XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_MAIN_ENEMY)
            else
                local endTime = XFunctionManager.GetStartTimeByTimeId(timerId)
                local current = XTime.GetServerNowTimestamp()
                local remainTime = endTime - current
                if remainTime > 0 then
                    local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
                    self.TxtName.text = XUiHelper.GetText("PokerGuessing2CountDown", timeStr)
                end
            end
        end
    end
end

function XUiPokerGuessing2Character:Speak(text)
    if text and text ~= "" then
        self.PanelTalk.gameObject:SetActiveEx(true)
        self.TxtTalk.text = text
    else
        self.PanelTalk.gameObject:SetActiveEx(false)
    end
end

function XUiPokerGuessing2Character:PlayAnimationCardToPutDownRandom(duration)
    if not self._Data then
        return
    end
    local cardIndex = math.random(1, #self._Data.Cards)
    if not self._Cards[cardIndex] then
        cardIndex = 1
    end
    self:PlayAnimationCardToPutDown(cardIndex, duration)
end

function XUiPokerGuessing2Character:PlayAnimationCardToPutDown(cardIndex, duration)
    local card = self._Cards[cardIndex]
    if not card then
        XLog.Warning("[XUiPokerGuessing2Character] card is nil")
        return
    end
    if card then
        card:PlayAnimationCardToPutDown(duration)
        return card
    end
end

-- 揭开盖上的卡
function XUiPokerGuessing2Character:RevealCoveredCard(cardData)
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        if card:IsPutOnGround() then
            card:Update(cardData)
            -- 播放先开牌动画
            card:PlayAnimationRevealTheCard()
            return
        end
    end
end

function XUiPokerGuessing2Character:SetTheRevealCardWin()
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        if card:IsPutOnGround() then
            card:SetWin(true)
        end
    end
end

function XUiPokerGuessing2Character:HideCardWin()
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        card:SetWin(false)
    end
end

function XUiPokerGuessing2Character:Reset()
    self:SetAllCardPutOnGroup(false)
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        card:Reset()
    end
end

function XUiPokerGuessing2Character:ShowEffectPutDown()
    self.PutDownEffect.gameObject:SetActiveEx(false)
    self.PutDownEffect.gameObject:SetActiveEx(true)
end

function XUiPokerGuessing2Character:ShowEffectSuccess()
    self.SuccessEffect.gameObject:SetActiveEx(false)
    self.SuccessEffect.gameObject:SetActiveEx(true)
end

-- 使所有牌背面向上
function XUiPokerGuessing2Character:CoverAllTheCards()
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        card:SetVisibleCardFace(false)
        card:SetVisibleCardBack(true)
    end
end

return XUiPokerGuessing2Character