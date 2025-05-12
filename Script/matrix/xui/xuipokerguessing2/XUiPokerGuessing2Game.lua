local XUiPokerGuessing2Character = require("XUi/XUiPokerGuessing2/Game/XUiPokerGuessing2Character")
local XUiPokerGuessing2Card = require("XUi/XUiPokerGuessing2/Game/XUiPokerGuessing2Card")
local XPokerGuessing2Enum = require("XModule/XPokerGuessing2/XPokerGuessing2Enum")

---@class XUiPokerGuessing2Game : XLuaUi
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2Game = XLuaUiManager.Register(XLuaUi, "UiPokerGuessing2Game")

function XUiPokerGuessing2Game:OnAwake()
    ---@type XUiPokerGuessing2Card[]
    self._EnemyPreviewCards = {}

    --self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe({
    --}, self.PanelSpecialTool, self)
    ---@type XUiPokerGuessing2Character
    self._Player = XUiPokerGuessing2Character.New(self.PanelRight, self, true)
    ---@type XUiPokerGuessing2Character
    self._Enemy = XUiPokerGuessing2Character.New(self.PanelLeft, self)
    XUiHelper.RegisterClickEvent(self, self.BtnPlay, self.OnClickPlay, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnClickHelp, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnClickBack, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnClickMain, nil, true)

    self.PanelDraw = self.PanelDraw or self.TxtDraw
    if self.PanelDraw then
        self.PanelDraw.gameObject:SetActiveEx(false)
    end
    self.TxtPlayerNum.text = 0
    self.TxtPlayerNextNum.text = 0
    self.TxtOpponentNum.text = 0
    self.TxtOpponentNextNum.text = 0

    self._IsPlayingAnimation = false
end

function XUiPokerGuessing2Game:OnStart()
    self:HideSpeak()
    self:UpdateScore()
    self:UpdateStageDesc()
    self:UpdatePlayer()
    self:UpdateEnemy()
    self:UpdateTips()
    self:PlayAnimationStartRound()
end

function XUiPokerGuessing2Game:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_TIPS, self.UpdateTips, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_SPEAK, self.UpdateSpeak, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_CONFIRM_RESULT, self.PlayAnimationConfirmResult, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_START_ROUND, self.PlayAnimationStartRound, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_RESTART, self.Restart, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_SELECT_PLAYER_CARD, self.PlayAnimationPlayerPutCard, self)
    
    -- 任务会导致卡顿, 因此延迟到游戏界面关闭时进行更新
    XDataCenter.TaskManager.CloseSyncTasksEvent()
end

function XUiPokerGuessing2Game:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_TIPS, self.UpdateTips, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_SPEAK, self.UpdateSpeak, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_CONFIRM_RESULT, self.PlayAnimationConfirmResult, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_START_ROUND, self.PlayAnimationStartRound, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_RESTART, self.Restart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_SELECT_PLAYER_CARD, self.PlayAnimationPlayerPutCard, self)
    
    XDataCenter.TaskManager.OpenSyncTasksEvent()
end

function XUiPokerGuessing2Game:OnDestroy()
    -- 防止遮罩层多次打开
    for i = 1, 99 do
        if XLuaUiManager.IsMaskShow("PokerGuessing2") then
            XLuaUiManager.SetMask(false, "PokerGuessing2")
        else
            break
        end
    end
    self._Control:SetCurrentStageId(nil, nil)
end

function XUiPokerGuessing2Game:PlayAnimationStartRound()
    local duration1 = 1.5
    local duration2 = 2
    local duration3 = 0.5

    self._IsPlayingAnimation = true
    -- 为什么延迟一帧，因为如果在第一回合startGame的网络协议回调时，连续open两个ui，会导致第二个ui打开失败，但是它的data一直存在，致使control无法回收
    -- 虽然已经过滤掉第一回合，但是还是保留延迟一帧吧
    if self._Control:GetRound() ~= 1 then
        self:TimerQuick(function()
            XLuaUiManager.Open("UiPokerGuessing2ToastRound")
        end, 0)
    end
    self:TimerQuick(function()
        XLuaUiManager.Close("UiPokerGuessing2ToastRound")

        self:TimerQuick(function()
            self:UpdateSpeak(XPokerGuessing2Enum.Speak.RoundStart)
        end, 0.5)

        self:TimerQuick(function()
            self._Enemy:PlayAnimationCardToPutDownRandom(duration3)
            self._IsPlayingAnimation = false
        end, duration2)
    end, duration1)
end

function XUiPokerGuessing2Game:TimerQuick(callback, duration)
    local time = CS.UnityEngine.Time.time + duration
    local timer
    timer = XScheduleManager.ScheduleForever(function()
        if CS.UnityEngine.Time.time >= time then
            XScheduleManager.UnSchedule(timer)
            self:_RemoveTimerIdAndDoCallback(timer)
            if callback then
                callback()
            end
        end
    end, 0)
    self:_AddTimerId(timer)
end

function XUiPokerGuessing2Game:PlayAnimationConfirmResult(state, roundState)
    XLuaUiManager.SetMask(true, "PokerGuessing2")
    -- 掀开敌人的卡
    self:RevealEnemyCard()

    -- 判断输赢
    self:TimerQuick(function()
        if roundState == XPokerGuessing2Enum.RoundState.RoundWin then
            self._Player:SetTheRevealCardWin()
            self._Player:ShowEffectSuccess()
        elseif roundState == XPokerGuessing2Enum.RoundState.RoundLose then
            self._Enemy:SetTheRevealCardWin()
            self._Enemy:ShowEffectSuccess()
        elseif roundState == XPokerGuessing2Enum.RoundState.RoundDrawn then
            self.PanelDraw.gameObject:SetActiveEx(true)
        end
    end, 0.3)

    -- 更新分数
    self:TimerQuick(function()
        self:UpdateScore()
    end, 1.3)

    -- 显示对话
    local speak = self._Control:GetDialogue(state)
    self:TimerQuick(function()
        if speak.Player then
            self._Player:Speak(speak.Player)
        end
    end, 0.7)
    self:TimerQuick(function()
        self._Enemy:Speak(speak.Enemy)
    end, 0.7)

    -- 判断是否结束
    if self._Control:IsGameOver() then
        -- 结算界面
        self:TimerQuick(function()
            XLuaUiManager.SetMask(false, "PokerGuessing2")
            XLuaUiManager.Open("UiPokerGuessing2PopupSettlement")
        end, 2.5)
    else
        -- 开始下一轮
        self:TimerQuick(function()
            XLuaUiManager.SetMask(false, "PokerGuessing2")

            self.PanelDraw.gameObject:SetActiveEx(false)
            -- 移除掀开的牌
            self:UpdatePlayer()
            self:UpdateEnemy()
            self._Player:HideCardWin()
            self._Enemy:HideCardWin()
            self._Player:SetAllCardPutOnGroup(false)
            self._Enemy:SetAllCardPutOnGroup(false)
            self:PlayAnimationStartRound()
        end, 2.5)
    end
end

function XUiPokerGuessing2Game:UpdateScore()
    local playerScore, enemyScore = self._Control:GetScore()
    if tostring(playerScore) ~= self.TxtPlayerNum.text then
        self.TxtPlayerNextNum.text = self.TxtPlayerNum.text
        self.TxtPlayerNum.text = playerScore
        self:PlayAnimation("PlayerScoreJump")
    end
    if tostring(enemyScore) ~= self.TxtOpponentNum.text then
        self.TxtOpponentNextNum.text = self.TxtOpponentNum.text
        self.TxtOpponentNum.text = enemyScore
        self:PlayAnimation("OpponentScoreJump")
    end
end

function XUiPokerGuessing2Game:UpdateStageDesc()
    local desc = self._Control:GetUiMain().StageDesc
    self.TxtDetail1.text = desc
end

function XUiPokerGuessing2Game:OnClickPlay()
    if self._IsPlayingAnimation then
        return
    end
    self._Control:Confirm()
end

function XUiPokerGuessing2Game:OnClickHelp()
    self._Control:UseTips()
end

function XUiPokerGuessing2Game:UpdateTips()
    local tipsAmount, tipsMax = self._Control:GetTipsAmount()
    self.BtnHelp:SetNameByGroup(0, tipsAmount .. "/" .. tipsMax)

    local tipsCardSpeak = self._Control:GetTipsCardSpeak()
    if tipsCardSpeak then
        self._Player:Speak(tipsCardSpeak)
    end
end

function XUiPokerGuessing2Game:UpdateEnemy()
    local enemy = self._Control:GetEnemy()
    self._Enemy:Update(enemy)
    XTool.UpdateDynamicItem(self._EnemyPreviewCards, enemy.PreviewCards, self.GridSmallCard, XUiPokerGuessing2Card, self)
    self._Enemy:CoverAllTheCards()
end

function XUiPokerGuessing2Game:RevealEnemyCard()
    local enemy = self._Control:GetEnemy()
    self._Enemy:RevealCoveredCard(enemy.Card)
    -- 移除掀开的牌
    self._Control:RemoveEnemyCard()
end

function XUiPokerGuessing2Game:UpdatePlayer()
    self._Player:Update(self._Control:GetPlayer())
end

function XUiPokerGuessing2Game:HideSpeak()
    self._Enemy:Speak()
    self._Player:Speak()
end

function XUiPokerGuessing2Game:UpdateSpeak(state)
    local speak = self._Control:GetDialogue(state)
    self._Enemy:Speak(speak.Enemy)
    if speak.Player then
        self._Player:Speak(speak.Player)
    else
        self._Player:Speak()
    end
end

function XUiPokerGuessing2Game:Restart()
    self._Control:Restart(function()
        self:UpdateScore()
        self:UpdateStageDesc()
        self:UpdatePlayer()
        self:UpdateEnemy()
        self:UpdateTips()
        self._Player:Reset()
        self._Enemy:Reset()
        self.PanelDraw.gameObject:SetActiveEx(false)
    end)
end

function XUiPokerGuessing2Game:OnClickBack()
    XUiManager.DialogTip(nil, XUiHelper.GetText("PokerGuessing2GiveUp"), nil, nil, function()
        self:Close()
    end)
end

function XUiPokerGuessing2Game:OnClickMain()
    XUiManager.DialogTip(nil, XUiHelper.GetText("PokerGuessing2GiveUp"), nil, nil, function()
        XLuaUiManager.RunMain()
    end)
end

-- 打出玩家指定位置的手牌
function XUiPokerGuessing2Game:PlayAnimationPlayerPutCard(cardIndex)
    cardIndex = tonumber(cardIndex)
    if cardIndex == nil then
        XLog.Warning("[XUiPokerGuessing2Game] PlayAnimationPlayerPutCard cardIndex is nil")
        return
    end
    local card = self._Player:PlayAnimationCardToPutDown(cardIndex, 0.5)
    if card then
        card:SetPlayerSelected()
        self._Player:RevertCardParentAndPosition(card)
    end
end

return XUiPokerGuessing2Game
