---@class XUiPcgGame : XLuaUi
---@field private _Control XPcgControl
local XUiPcgGame = XLuaUiManager.Register(XLuaUi, "UiPcgGame")

function XUiPcgGame:OnAwake()
    self.PanelUseSkill.gameObject:SetActiveEx(false)
    self.PanelDetail.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiPcgGame:OnStart()
    self:OnInit()
end

function XUiPcgGame:OnEnable()
    XDataCenter.TaskManager.CloseSyncTasksEvent()
end

function XUiPcgGame:OnDisable()
    XDataCenter.TaskManager.OpenSyncTasksEvent()
end

function XUiPcgGame:OnDestroy()
    self:ClearEffectSettleTimer()
end

function XUiPcgGame:OnGetLuaEvents()
    return {
        XEventId.EVENT_PCG_GAME_START,
        XEventId.EVENT_PCG_PLAY_CARD,
        XEventId.EVENT_PCG_SHOW_DETAIL,
        XEventId.EVENT_PCG_CLICK,
    }
end

function XUiPcgGame:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_PCG_GAME_START then
        self:OnInit()
    elseif evt == XEventId.EVENT_PCG_PLAY_CARD then
        local index = tonumber(args[1])
        self:PlayCard(index)
    elseif evt == XEventId.EVENT_PCG_SHOW_DETAIL then
        local type = tonumber(args[1])
        local idx = tonumber(args[2])
        local isShow = args[3] == "1"
        self:ShowDetail(type, idx, isShow)
    elseif evt == XEventId.EVENT_PCG_CLICK then
        local type = tonumber(args[1])
        local idx = tonumber(args[2])
        self:OnEventClick(type, idx)
    end
end

function XUiPcgGame:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
    self:RegisterClickEvent(self.BtnEnd, self.OnBtnEndClick)
    self:RegisterClickEvent(self.BtnLog, self.OnBtnLogClick)
    self:RegisterClickEvent(self.BtnCard, self.OnBtnCardClick)
    self:RegisterClickEvent(self.BtnDiscard, self.OnBtnDiscardClick)
    self:RegisterClickEvent(self.BtnCloseUseSkill, self.ClosePanelUseSkill)
    self.GetTokenLayerFunc = handler(self, self.GetTokenLayer)
end

function XUiPcgGame:OnBtnBackClick()
    local roundState = self._Control.GameSubControl:GetRoundState()
    if roundState ~= XEnumConst.PCG.ROUND_STATE.PLAY_CARDS then return end
    
    -- 使用指挥官技能中
    if self.IsUsingSkill then
        self:ClosePanelUseSkill()
        return
    end
    
    self:Close()
end

function XUiPcgGame:OnBtnMainUiClick()
    local roundState = self._Control.GameSubControl:GetRoundState()
    if roundState ~= XEnumConst.PCG.ROUND_STATE.PLAY_CARDS then return end
    XLuaUiManager.RunMain()
end

function XUiPcgGame:OnBtnEndClick()
    -- 非出牌阶段操作提示
    if not self:IsPlayCardState(true) then return end
    -- 正在播放动画
    if self:IsAnim() then return end
    -- 游戏结束
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.End then return end
    
    XMVCA.XPcg:PcgRoundEndRequest(function()
        self:EnterNextRoundState()
    end)
end

function XUiPcgGame:OnBtnLogClick()
    XLuaUiManager.Open("UiPcgPopupLog")
end

function XUiPcgGame:OnBtnCardClick()
    -- 非出牌阶段操作提示
    if not self:IsPlayCardState() then return end
    -- 正在播放动画
    if self:IsAnim() then return end
    -- 游戏结束
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.End then return end
    
    XLuaUiManager.Open("UiPcgPopupDeck", true)
end

function XUiPcgGame:OnBtnDiscardClick()
    -- 非出牌阶段操作提示
    if not self:IsPlayCardState() then return end
    -- 正在播放动画
    if self:IsAnim() then return end
    -- 游戏结束
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.End then return end
    
    XLuaUiManager.Open("UiPcgPopupDeck", false)
end

-- 游戏初始化，包括重新开始/下一关
function XUiPcgGame:OnInit()
    self.BtnEnd:SetDisable(false)
    self:Refresh()
    self._Control.GameSubControl:SetGameState(XEnumConst.PCG.GAME_STATE.Playing)
end

-- 重置
function XUiPcgGame:Reset()
    if self.UiPanelMonster then
        self.UiPanelMonster:Reset()
    end
    if self.UiPanelCommander then
        self.UiPanelCommander:Reset()
    end
end

--region 界面刷新
-- 刷新界面
function XUiPcgGame:Refresh()
    self:RefreshPanelCharacter()
    self:RefreshPanelMonster()
    self:RefreshPanelCommander()
    self:RefreshPanelCard()
    self:RefreshPanelTarget()
    self:RefreshBtnEnd()
end

-- 刷新角色面板
function XUiPcgGame:RefreshPanelCharacter()
    if not self.UiPanelCharacter then
        ---@type XUiPanelPcgGameCharacter
        self.UiPanelCharacter = require("XUi/XUiPcg/XUiPcgGame/XUiPanelPcgGameCharacter").New(self.PanelCharacter, self)
        self.UiPanelCharacter:Open()
    end
    self.UiPanelCharacter:Refresh()
end

-- 刷新怪物面板
function XUiPcgGame:RefreshPanelMonster()
    if not self.UiPanelMonster then
        ---@type XUiPanelPcgGameMonster
        self.UiPanelMonster = require("XUi/XUiPcg/XUiPcgGame/XUiPanelPcgGameMonster").New(self.PanelMonster, self)
        self.UiPanelMonster:Open()
    end
    self.UiPanelMonster:Refresh()
end

-- 刷新指挥官面板
function XUiPcgGame:RefreshPanelCommander()
    if not self.UiPanelCommander then
        ---@type XUiPanelPcgGameCommander
        self.UiPanelCommander = require("XUi/XUiPcg/XUiPcgGame/XUiPanelPcgGameCommander").New(self.PanelCommander, self)
        self.UiPanelCommander:Open()
    end
    self.UiPanelCommander:Refresh()
end

-- 刷新手牌面板
function XUiPcgGame:RefreshPanelCard()
    if not self.UiPanelCard then
        ---@type XUiPanelPcgGameCard
        self.UiPanelCard = require("XUi/XUiPcg/XUiPcgGame/XUiPanelPcgGameCard").New(self.PanelCard, self)
        self.UiPanelCard:Open()
    end
    self.UiPanelCard:Refresh()
end

-- 刷新目标面板
function XUiPcgGame:RefreshPanelTarget()
    if not self.UiPanelTarget then
        ---@type XUiPanelPcgGameTarget
        self.UiPanelTarget = require("XUi/XUiPcg/XUiPcgGame/XUiPanelPcgGameTarget").New(self.PanelTarget, self)
        self.UiPanelTarget:Open()
    end
    self.UiPanelTarget:Refresh()
end

-- 显示弹窗详情面板
function XUiPcgGame:ShowPanelPopupDetail(type, idx)
    if not self.UiPanelDetail then
        ---@type XUiPanelPcgGameDetail
        self.UiPanelDetail = require("XUi/XUiPcg/XUiPcgGame/XUiPanelPcgGameDetail").New(self.PanelDetail, self)
        self.UiPanelDetail:Open()
    end
    self.UiPanelDetail:Refresh(type, idx)
end

-- 关闭弹窗详情面板
function XUiPcgGame:ClosePanelPopupDetail()
    if self:IsShowPanelPopupDetail() then
        self.UiPanelDetail:OnBtnCloseClick()
    end
end

-- 是否正在显示弹窗详情
function XUiPcgGame:IsShowPanelPopupDetail()
    if self.UiPanelDetail and self.UiPanelDetail:GetIsDetailShow() then
        return true
    end
    return false
end

-- 刷新回合结束按钮
function XUiPcgGame:RefreshBtnEnd()
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local commander = stageData:GetCommander()
    local stageId = stageData:GetId()
    local curActionPoint = commander:GetActionPoint()
    local initActionPoint = self._Control:GetStageInitActionPoint(stageId)
    self.TxtActionPoint.text = curActionPoint .. "/" .. tostring(initActionPoint)
    self.EndEffect.gameObject:SetActiveEx(curActionPoint <= 0)
end

-- 刷新行动点
function XUiPcgGame:RefreshActionPoint(actionPoint)
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local stageId = stageData:GetId()
    local initActionPoint = self._Control:GetStageInitActionPoint(stageId)
    self.TxtActionPoint.text = actionPoint .. "/" .. tostring(initActionPoint)
end

-- 出牌
function XUiPcgGame:PlayCard(index)
    local isSelected = self.UiPanelCard:IsCardSelected(index)
    if not isSelected then
        self.UiPanelCard:OnCardClick(index)
    end
    self.UiPanelCard:OnBtnPlayClick()
end

-- 显示详情
function XUiPcgGame:ShowDetail(type, idx, isShow)
    -- 卡牌详情
    if type == XEnumConst.PCG.POPUP_DETAIL_TYPE.CARD then
        if isShow then
            ---@type XPcgPlayingStage
            local stageData = self._Control.GameSubControl:GetPlayingStageData()
            local characterId = stageData:GetAttackCharacterId()
            local cardId = self.UiPanelCard:GetCardId(idx)
            XLuaUiManager.Open("UiPcgPopupCardDetail", cardId, characterId, true, true, self.GetTokenLayerFunc)
        else
            XLuaUiManager.Close("UiPcgPopupCardDetail")
        end
        return
    end
    
    -- 指挥官/怪物/成员详情
    if not isShow then
        self:ClosePanelPopupDetail()
    else
        self:ShowPanelPopupDetail(type, idx)
    end
end

-- 引导事件，点击指挥官/怪物/角色/卡牌
function XUiPcgGame:OnEventClick(type, idx)
    if type == XEnumConst.PCG.POPUP_DETAIL_TYPE.COMMANDER then
        
    elseif type == XEnumConst.PCG.POPUP_DETAIL_TYPE.MONSTER then
        self.UiPanelMonster:OnMonsterClick(idx)
    elseif type == XEnumConst.PCG.POPUP_DETAIL_TYPE.CHARACTER then
        self.UiPanelCharacter:OnCharacterClick(idx)
    elseif type == XEnumConst.PCG.POPUP_DETAIL_TYPE.CARD then
        self.UiPanelCard:OnCardClick(idx)
    end
end
--endregion

--region 回合状态
-- 进入下一个回合状态
function XUiPcgGame:EnterNextRoundState()
    self._Control.GameSubControl:SetNextRoundState()
    local roundState = self._Control.GameSubControl:GetRoundState()
    if roundState == XEnumConst.PCG.ROUND_STATE.PLAY_CARDS then
        self:OnStatePlayCards()
    elseif roundState == XEnumConst.PCG.ROUND_STATE.ROUND_END then
        self:OnStateRoundEnd()
    elseif roundState == XEnumConst.PCG.ROUND_STATE.MONSTER_ATTACK then
        self:OnStateMonsterAttack()
    elseif roundState == XEnumConst.PCG.ROUND_STATE.GET_CARDS then
        self:OnStateGetCards()
    else
        XLog.Error(string.format("未定义回合状态%s对应的处理函数", roundState))
    end
end

-- 切换到出牌状态
function XUiPcgGame:OnStatePlayCards()
    XLog.Warning("==============OnStatePlayCards")
    -- 检测游戏结束
    if self:CheckGameEnd() then return end
    -- 刷新界面
    self:Refresh()
    self.BtnEnd:SetDisable(false)
    XLuaUiManager.SetMask(true)
    XLuaUiManager.OpenWithCallback("UiPcgToastRound", function()
        XLuaUiManager.SetMask(false)
    end)
end

-- 切换到回合结束状态
function XUiPcgGame:OnStateRoundEnd()
    XLog.Warning("==============OnStateRoundEnd")
    self:EnterNextRoundState()
end

-- 切换到怪物进攻状态
function XUiPcgGame:OnStateMonsterAttack()
    XLog.Warning("==============OnStateMonsterAttack")
    self.BtnEnd:SetDisable(true)
    self.EndEffect.gameObject:SetActiveEx(false)
    self:PlayCacheEffectSettles(nil, true)
end

-- 切换抽取卡牌状态
function XUiPcgGame:OnStateGetCards()
    XLog.Warning("==============OnStateGetCards")
    -- 应用回合开始的数据
    self._Control.GameSubControl:UseCacheNextPlayingStageData()
    -- 放抽牌表现
    self.UiPanelCard:CheckPlayAddCards(function()
        self:EnterNextRoundState()
    end)
end

-- 检测游戏结束
function XUiPcgGame:CheckGameEnd()
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.End then
        XLuaUiManager.SetMask(true)
        XLuaUiManager.Remove("UiPcgPopupLog")
        XLuaUiManager.Remove("UiPcgToastRound")
        XLuaUiManager.Remove("UiPcgPopupCardDetail")
        XLuaUiManager.OpenWithCallback("UiPcgPopupSettlement", function()
            XLuaUiManager.SetMask(false)
        end)
        return true
    end
    return false
end

-- 当前是否是出牌状态
function XUiPcgGame:IsPlayCardState(isTips)
    local roundState = self._Control.GameSubControl:GetRoundState()
    local isPlayCardState = roundState == XEnumConst.PCG.ROUND_STATE.PLAY_CARDS
    if not isPlayCardState and isTips then
        local tips = self._Control:GetClientConfig("CanNoPlayCardTips")
        XUiManager.TipError(tips)
    end
    return isPlayCardState
end
--endregion

--region 效果结算
-- 播放缓存的效果结算
function XUiPcgGame:PlayCacheEffectSettles(isCheckEnd, isEnterNextState, isRefresh, cb)
    self.IsPlayingEffectSettles = true
    ---@type XPcgEffectSettle[]
    local effectSettles = self._Control.GameSubControl:UseCacheEffectSettles()
    local settleCnt = #effectSettles
    if settleCnt == 0 then
        self:OnPlayEffectSettlesFinish(isCheckEnd, isEnterNextState, isRefresh, cb)
        return
    end

    self.PlayCvEffectDic = {}
    local TICK_TIME = 50
    local index = 1
    local waitTime = 0
    self:ClearEffectSettleTimer()
    self.EffectSettleTimer = XScheduleManager.ScheduleForever(function()
        waitTime = waitTime - TICK_TIME
        if waitTime > 0 then return end
    
        -- 效果播放结束
        if index > settleCnt then
            self:ClearEffectSettleTimer()
            self:OnPlayEffectSettlesFinish(isCheckEnd, isEnterNextState, isRefresh, cb)
            return
        end
        
        while(index <= settleCnt) do
            local settle = effectSettles[index]
            local nextSettle = effectSettles[index + 1]
            local isNextSameType = self:IsEffectSettleSameType(settle, nextSettle) -- TODO 下一期合并EFFECT_SETTLE_TYPE.CARD_POOL_CHANGE类型的多张卡牌变化
            -- 获取播放时长
            if not isNextSameType then
                waitTime = self:GetEffectSettleTime(index, effectSettles)
            end
            -- 所有EffectSettle效果处理完成的延迟结束
            if index == settleCnt then
                waitTime = waitTime + XEnumConst.PCG.ANIM_TIME_SETTLE_DELAY_FINISH
            end
            -- 播放效果
            self:PlayEffectSettle(settle, isNextSameType)
            index = index + 1
            if waitTime > 0 then break end
        end
    end, TICK_TIME)
end

-- 清理效果结算定时器
function XUiPcgGame:ClearEffectSettleTimer()
    if self.EffectSettleTimer then
        XScheduleManager.UnSchedule(self.EffectSettleTimer)
        self.EffectSettleTimer = nil
    end
end

-- 播放一个结算效果
---@param settle XPcgEffectSettle
function XUiPcgGame:PlayEffectSettle(settle, isNextSameType)
    local EFFECT_SETTLE_TYPE = XEnumConst.PCG.EFFECT_SETTLE_TYPE
    local type = settle:GetEffectSettleType()
    local effectId = settle:GetEffectId()
    
    -- Effect音效
    if effectId ~= 0 and not self.PlayCvEffectDic[effectId] then
        local cvId = self._Control:GetEffectCv(effectId)
        if XTool.IsNumberValid(cvId) then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cvId)
            self.PlayCvEffectDic[effectId] = true
        end
    end

    -- 触发角色核心被动特效
    local charIdx = self:GetCharacterIdxByEffectId(effectId)
    if XTool.IsNumberValid(charIdx) then
        local isPlayPassiveSkillEffect = true
        if type == EFFECT_SETTLE_TYPE.TOKEN_CHANGE then
            local tokenId = settle:GetParam3()
            local tokenCfg = self._Control:GetConfigToken(tokenId)
            if tokenCfg.IsShow ~= 1 then
                isPlayPassiveSkillEffect = false
            end
        end
        if isPlayPassiveSkillEffect then
            ---@type XUiGridPcgCharacter
            local char = self.UiPanelCharacter:GetCharacter(charIdx)
            char:PlayPassiveSkillEffect()
        end
    end

    -- 根据效果类型做表现
    if type == EFFECT_SETTLE_TYPE.DAMAGE then
        local targetType = settle:GetParam2()
        local targetIdx = settle:GetParam4()
        local targetType2 = settle:GetParam5()
        local targetIdx2 = settle:GetParam7()
        local target = self:GetTarget(targetType, targetIdx)
        local target2 = self:GetTarget(targetType2, targetIdx2)
        target:PlayAnimAttack(target2)
        
    elseif type == EFFECT_SETTLE_TYPE.HP_CHANGE then
        local val = settle:GetParam1()
        local targetType = settle:GetParam2()
        local targetIdx = settle:GetParam4()
        local target = self:GetTarget(targetType, targetIdx)
        if not target then
            XLog.Error("处理Effect效果，获取目标失败，打印数据：" .. settle:ToString())
            return
        end
        target:SetHp(val)
        
    elseif type == EFFECT_SETTLE_TYPE.ARMOR_CHANGE then
        local val = settle:GetParam1()
        local targetType = settle:GetParam2()
        local targetIdx = settle:GetParam4()
        local target = self:GetTarget(targetType, targetIdx)
        if not target then
            XLog.Error("处理Effect效果，获取目标失败，打印数据：" .. settle:ToString())
            return
        end
        target:SetArmor(val)
        
    elseif type == EFFECT_SETTLE_TYPE.ACTION_POINT_CHANGE then
        local val = settle:GetParam1()
        local target = self:GetTarget(XEnumConst.PCG.TARGET_TYPE.COMMANDER)
        if not target then
            XLog.Error("处理Effect效果，获取目标失败，打印数据：" .. settle:ToString())
            return
        end
        self:RefreshActionPoint(val)
        
    elseif type == EFFECT_SETTLE_TYPE.CHARACTER_POS_CHANGE then
        local characterId = settle:GetParam1()
        self.UiPanelCharacter:SetCharacterToFirst(characterId)
        
    elseif type == EFFECT_SETTLE_TYPE.CARD_POOL_CHANGE then
        local cardId = settle:GetParam1()
        local cardPos1 = settle:GetParam2() -- 原位置
        local cardPos2 = settle:GetParam3() -- 目标位置
        if cardId == 0 then
            --[[ 这个黑条提示给玩家感觉像是bug
            local tips = self._Control:GetClientConfig("NoValidCardTips")
            XUiManager.TipError(tips)
            ]]
            return
        end
        -- 卡牌变化表现
        -- 抽牌堆->手牌
        if cardPos1 == XEnumConst.PCG.CARD_POS_TYPE.DRAW and cardPos2 == XEnumConst.PCG.CARD_POS_TYPE.HAND then
            self.CacheCardsFromDrawToHand = self.CacheCardsFromDrawToHand or {}
            table.insert(self.CacheCardsFromDrawToHand, cardId)
            if not isNextSameType then
                self.UiPanelCard:MoveCardsFromDrawToHand(self.CacheCardsFromDrawToHand)
                self.CacheCardsFromDrawToHand = nil
            end
        -- 弃牌堆->手牌
        elseif cardPos1 == XEnumConst.PCG.CARD_POS_TYPE.DROP and cardPos2 == XEnumConst.PCG.CARD_POS_TYPE.HAND then
            self.CacheCardsFromDropToHand = self.CacheCardsFromDropToHand or {}
            table.insert(self.CacheCardsFromDropToHand, cardId)
            if not isNextSameType then
                self.UiPanelCard:MoveCardsFromDropToHand(self.CacheCardsFromDropToHand)
                self.CacheCardsFromDropToHand = nil
            end
        -- 衍生区->手牌
        elseif cardPos1 == XEnumConst.PCG.CARD_POS_TYPE.DERIVATIVE and cardPos2 == XEnumConst.PCG.CARD_POS_TYPE.HAND then
            self.CacheCardsFromDerivativeToHand = self.CacheCardsFromDerivativeToHand or {}
            table.insert(self.CacheCardsFromDerivativeToHand, cardId)
            if not isNextSameType then
                self.UiPanelCard:MoveCardsFromDerivativeToHand(self.CacheCardsFromDerivativeToHand)
                self.CacheCardsFromDerivativeToHand = nil
            end
        -- 手牌->弃牌堆
        elseif cardPos1 == XEnumConst.PCG.CARD_POS_TYPE.HAND and cardPos2 == XEnumConst.PCG.CARD_POS_TYPE.DROP then
            local isSLAY = self._Control:GetCardType(cardId) == XEnumConst.PCG.CARD_TYPE.SLAY
            if isSLAY then
                XLuaUiManager.Open("UiPcgSkillPopup", cardId)
            end
        end
        
    elseif type == EFFECT_SETTLE_TYPE.TOKEN_CHANGE then
        local targetType = settle:GetParam1()
        local tokenId = settle:GetParam3()
        local tokenNum = settle:GetParam4()
        local targetIdx = settle:GetParam5()
        local target = self:GetTarget(targetType, targetIdx)
        if not target then
            XLog.Error("处理Effect效果，获取目标失败，打印数据：" .. settle:ToString())
            return
        end
        target:SetToken(tokenId, tokenNum)
        
    elseif type == EFFECT_SETTLE_TYPE.MONSTER_CHANGE then
        local monster1 = settle:GetParam1()
        local monster2 = settle:GetParam2()
        local monster3 = settle:GetParam3()
        local monster4 = settle:GetParam4()
        local monster5 = settle:GetParam5()
        self.UiPanelMonster:ChangeMonsters(monster1, monster2, monster3, monster4, monster5)

    elseif type == EFFECT_SETTLE_TYPE.HAND_POOL_SORT then
        local cardIds = settle:GetCardList()
        self.UiPanelCard:PlaySortCards(cardIds)
    elseif type == EFFECT_SETTLE_TYPE.ADJUST_CARD_POOL_ORDER then
        local cardPos = settle:GetParam1()
        local idx = XMVCA.XPcg:ConvertCSharpIndexToLuaIndex(settle:GetParam3())
        local targetIdx = XMVCA.XPcg:ConvertCSharpIndexToLuaIndex(settle:GetParam4())
        if cardPos == XEnumConst.PCG.CARD_POS_TYPE.HAND then
            self.UiPanelCard:PlayMoveCard(idx, targetIdx)
        end
    elseif type == EFFECT_SETTLE_TYPE.DROP_HAND_CARDS then
        local cardIdxs = XMVCA.XPcg:ConvertCSharpIndexToLuaIndex(settle:GetCardIdxList())
        self.UiPanelCard:MoveCardsFromHandToDrop(cardIdxs)
    elseif type == EFFECT_SETTLE_TYPE.ADD_HAND_CARDS then
        local cardPos1 = settle:GetParam1()
        local cardIds = settle:GetCardList()
        if #cardIds > 0 and cardPos1 == XEnumConst.PCG.CARD_POS_TYPE.HAND then
            self.UiPanelCard:MoveCardsFromDerivativeToHand(cardIds)
        end
    elseif type == EFFECT_SETTLE_TYPE.WAVE_MONSTER_DEAD then
        self.UiPanelMonster:ClearAllMonster()
    end
end

-- 获取单个EffectSettle播放时间
function XUiPcgGame:GetEffectSettleTime(index, effectSettles)
    ---@type XPcgEffectSettle
    local settle = effectSettles[index]
    local time = 0
    local EFFECT_SETTLE_TYPE = XEnumConst.PCG.EFFECT_SETTLE_TYPE
    local type = settle:GetEffectSettleType()
    if type == EFFECT_SETTLE_TYPE.DAMAGE then
        local targetType = settle:GetParam2()
        if targetType == XEnumConst.PCG.TARGET_TYPE.MONSTER then
            time = XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART1 + XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART2 + XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART3
        elseif targetType == XEnumConst.PCG.TARGET_TYPE.CHARACTER then
            time = XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART1 + XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART2 + XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART3
        end
        
    elseif type == EFFECT_SETTLE_TYPE.HP_CHANGE then
        local val = settle:GetParam1()
        local targetType = settle:GetParam2()
        time = XEnumConst.PCG.ANIM_TIME_ATTR_CHANGE + XEnumConst.PCG.ANIM_TIME_SETTLE_OFFSET
        -- 怪物死亡动画
        if targetType == XEnumConst.PCG.TARGET_TYPE.MONSTER and val <= 0 then
            time = time + XEnumConst.PCG.ANIM_TIME_MONSTER_DIE
        end
        
    elseif type == EFFECT_SETTLE_TYPE.ARMOR_CHANGE then
        time = XEnumConst.PCG.ANIM_TIME_ATTR_CHANGE + XEnumConst.PCG.ANIM_TIME_SETTLE_OFFSET
        
    elseif type == EFFECT_SETTLE_TYPE.CHARACTER_POS_CHANGE then
        time = XEnumConst.PCG.ANIM_TIME_CHARACTER_CHANGE
    elseif type == EFFECT_SETTLE_TYPE.CARD_POOL_CHANGE then
        local cardId = settle:GetParam1()
        local cardPos1 = settle:GetParam2()
        local cardPos2 = settle:GetParam3()
        -- 卡牌变化表现
        -- 抽牌堆/弃牌堆/衍生区->手牌
        if cardPos2 == XEnumConst.PCG.CARD_POS_TYPE.HAND then
            time = XEnumConst.PCG.ANIM_TIME_CARD_BACK + XEnumConst.PCG.ANIM_TIME_EXHIBITION + XEnumConst.PCG.ANIM_TIME_CARD_BACK + XEnumConst.PCG.ANIM_TIME_SETTLE_OFFSET
            -- 连续卡牌判断
            local lastIndex = index - 1
            while true do
                local nextSettle = effectSettles[lastIndex]
                local isSame = nextSettle and nextSettle:GetEffectSettleType() == type and nextSettle:GetParam2() == cardPos1 and nextSettle:GetParam3() == cardPos2
                if isSame then
                    time = time + XEnumConst.PCG.ANIM_TIME_CARD_OFFSET
                    lastIndex = lastIndex - 1
                else
                    break
                end
            end
        -- 手牌->弃牌堆
        elseif cardPos1 == XEnumConst.PCG.CARD_POS_TYPE.HAND and cardPos2 == XEnumConst.PCG.CARD_POS_TYPE.DROP then
            local isSLAY = self._Control:GetCardType(cardId) == XEnumConst.PCG.CARD_TYPE.SLAY
            if isSLAY then
                time = XEnumConst.PCG.ANIM_TIME_SLAY + XEnumConst.PCG.ANIM_TIME_SETTLE_OFFSET
            end
        end
    elseif type == EFFECT_SETTLE_TYPE.MONSTER_CHANGE then
        time = XEnumConst.PCG.ANIM_TIME_MONSTER_ENABLE
    elseif type == EFFECT_SETTLE_TYPE.HAND_POOL_SORT then
        time = XEnumConst.PCG.ANIM_TIME_CARD_BACK + XEnumConst.PCG.ANIM_TIME_CARD_FLIP + XEnumConst.PCG.ANIM_TIME_CARD_BACK + XEnumConst.PCG.ANIM_TIME_SETTLE_OFFSET
    elseif type == EFFECT_SETTLE_TYPE.ADJUST_CARD_POOL_ORDER then
        time = XEnumConst.PCG.ANIM_TIME_CARD_BACK + XEnumConst.PCG.ANIM_TIME_SETTLE_OFFSET
    elseif type == EFFECT_SETTLE_TYPE.DROP_HAND_CARDS then
        local cardList = settle:GetCardIdxList()
        time = XEnumConst.PCG.ANIM_TIME_CARD_BACK + XEnumConst.PCG.ANIM_TIME_EXHIBITION + XEnumConst.PCG.ANIM_TIME_CARD_BACK + #cardList * XEnumConst.PCG.ANIM_TIME_CARD_OFFSET + XEnumConst.PCG.ANIM_TIME_SETTLE_OFFSET
    elseif type == EFFECT_SETTLE_TYPE.ADD_HAND_CARDS then
        local cardPos1 = settle:GetParam1()
        local cardIds = settle:GetCardList()
        if #cardIds > 0 and cardPos1 == XEnumConst.PCG.CARD_POS_TYPE.HAND then
            time = XEnumConst.PCG.ANIM_TIME_CARD_BACK + XEnumConst.PCG.ANIM_TIME_EXHIBITION + XEnumConst.PCG.ANIM_TIME_CARD_BACK + XEnumConst.PCG.ANIM_TIME_CARD_OFFSET*(#cardIds - 1) + XEnumConst.PCG.ANIM_TIME_SETTLE_OFFSET
        end
    elseif type == EFFECT_SETTLE_TYPE.WAVE_MONSTER_DEAD then
        if self.UiPanelMonster:IsMonsterExit() then
            time = XEnumConst.PCG.ANIM_TIME_MONSTER_DIE + XEnumConst.PCG.ANIM_TIME_SETTLE_OFFSET
        end
    end
    return time
end

-- 是否是相同结算类型
---@param settle1 XPcgEffectSettle
---@param settle2 XPcgEffectSettle
function XUiPcgGame:IsEffectSettleSameType(settle1, settle2)
    if not settle1 or not settle2 then return false end
    if settle1:GetEffectId() ~= settle2:GetEffectId() then return false end
    if settle1:GetEffectSettleType() ~= settle2:GetEffectSettleType() then return false end
    
    local EFFECT_SETTLE_TYPE = XEnumConst.PCG.EFFECT_SETTLE_TYPE
    local type = settle1:GetEffectSettleType()
    if type == EFFECT_SETTLE_TYPE.CARD_POOL_CHANGE then
        if settle1:GetParam2() == settle2:GetParam2() and settle1:GetParam3() == settle2:GetParam3() then
            return true
        end
        return false
    end
    return false
end

-- 获取目标对象
function XUiPcgGame:GetTarget(targetType, idx)
    if targetType == XEnumConst.PCG.TARGET_TYPE.COMMANDER then
        return self.UiPanelCommander
    elseif targetType == XEnumConst.PCG.TARGET_TYPE.MONSTER then
        return self.UiPanelMonster:GetMonster(idx)
    elseif targetType == XEnumConst.PCG.TARGET_TYPE.CHARACTER then
        return self.UiPanelCharacter:GetCharacter(idx)
    end
end

-- 通过被动特效Id获取对应角色下标
function XUiPcgGame:GetCharacterIdxByEffectId(effectId)
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local characterDatas = stageData:GetCharacters()
    for _, characterData in ipairs(characterDatas) do
        local cfgId = characterData:GetId()
        local idx = characterData:GetIdx()
        if XTool.IsNumberValid(cfgId) and self._Control:IsCharacterContainEffectId(cfgId, effectId) then
            return idx
        end
    end
end

-- 效果结算播放完毕回调
function XUiPcgGame:OnPlayEffectSettlesFinish(isCheckEnd, isEnterNextState, isRefresh)
    XLog.Warning("==============[OnPlayEffectSettlesFinish]")
    self.IsPlayingEffectSettles = false
    -- 播放完表现，检测游戏结束
    if isCheckEnd and self:CheckGameEnd() then
        return
    end
    -- 刷新
    if isRefresh then
        self:Refresh()
    end
    -- 进入下一个阶段
    if isEnterNextState then
        self:EnterNextRoundState()
    end
end

-- 是否正在播放动画
function XUiPcgGame:IsAnim()
    return self.IsPlayingEffectSettles or self.UiPanelCard:GetIsAnim()
end
--endregion

--region 指挥官技能
-- 是否正在使用指挥官技能
function XUiPcgGame:GetIsUsingSkill()
    return self.IsUsingSkill == true
end

-- 打开使用技能面板
function XUiPcgGame:OpenPanelUseSkill()
    self.IsUsingSkill = true
    self.PanelUseSkill.gameObject:SetActiveEx(true)
    self.UiPanelCard:ClearCardsSelected()
end

-- 关闭使用技能面板
function XUiPcgGame:ClosePanelUseSkill()
    self.IsUsingSkill = false
    self.PanelUseSkill.gameObject:SetActiveEx(false)
    self.UiPanelCard:ClearCardsSelected()
    self:Refresh()
end
--endregion

-- 获取场内Token的总层数(指挥官+成员)
function XUiPcgGame:GetTokenLayer(tokenId)
    return self.UiPanelCommander:GetTokenLayer(tokenId) +  self.UiPanelCharacter:GetTokenLayer(tokenId)
end

return XUiPcgGame
