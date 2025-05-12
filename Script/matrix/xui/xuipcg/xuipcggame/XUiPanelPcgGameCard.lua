---@class XUiPanelPcgGameCard : XUiNode
---@field private _Control XPcgControl
---@field Parent XUiPcgGame
---@field GridCardDic table<number, XUiGridPcgCard>
---@field SelectedCards XUiGridPcgCard[]
---@field RecycleCards XUiGridPcgCard[]
---@field ExhibitionCards XUiGridPcgCard[]
---@field DrawCards XUiGridPcgCard[]
---@field DropCards XUiGridPcgCard[]
---@field SortCards XUiGridPcgCard[]
local XUiPanelPcgGameCard = XClass(XUiNode, "XUiPanelPcgGameCard")

function XUiPanelPcgGameCard:OnStart()
    self.MAX_SELECTED_CARD_CNT = 3
    self.CardPosDic = {}                -- 手牌位置挂点
    self.GridCardDic = {}               -- 手牌
    self.SelectedCards = {}             -- 选中卡牌
    self.RecycleCards = {}              -- 已回收卡牌
    self.ExhibitionCards = {}           -- 展示卡牌
    self.DrawCards = {}                 -- 抽堆卡牌
    self.DropCards = {}                 -- 弃牌堆卡牌
    self.SortCards = {}                 -- 洗牌区卡牌
    self:RegisterUiEvents()
    self:InitCards()
    self:ShowPanelUseCard(false)
end

function XUiPanelPcgGameCard:OnEnable()
    
end

function XUiPanelPcgGameCard:OnDisable()
    
end

function XUiPanelPcgGameCard:OnDestroy()
    self:ClearExhibitionTimer()
    self:ClearSortTimer()
    self:ClearCardSpacingTimer()
end

function XUiPanelPcgGameCard:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBgClose, self.OnBtnBgCloseClick, nil, true)
    self.TxtCardDesc.requestImage = XMVCA.XPcg.RichTextImageCallBack
end

function XUiPanelPcgGameCard:OnBtnBgCloseClick()
    self:ClearCardsSelected()
end

-- 点击出牌按钮
function XUiPanelPcgGameCard:OnBtnPlayClick()
    if #self.SelectedCards == 0 then
        self:ClearCardsSelected()
        return 
    end

    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local commander = stageData:GetCommander()
    local canPlay = commander:GetActionPoint() > 0
    if not canPlay then
        local tips = self._Control:GetClientConfig("ActionPointNoEnoughTips")
        XUiManager.TipError(tips)
        self:ClearCardsSelected()
        return
    end
    
    -- 根据下标排序
    local selectedIdxs = {}
    for _, gridCard in ipairs(self.SelectedCards) do
        table.insert(selectedIdxs, gridCard:GetIdx())
    end
    table.sort(selectedIdxs)
    
    -- 是否播消融动画
    local cardId = self.SelectedCards[1]:GetCfgId()
    local isDerivative = self._Control:GetCardType(cardId) == XEnumConst.PCG.CARD_TYPE.DERIVATIVE
    local isWhile = self._Control:GetCardColor(cardId) == XEnumConst.PCG.COLOR_TYPE.WHITE
    local isMelt = isDerivative and isWhile
    
    -- 请求出牌
    XMVCA.XPcg:PcgPlayCardRequest(selectedIdxs, function()
        if isMelt then
            -- 衍生牌移动到展示区后消融
            self:MoveCardsFromHandToMelt(selectedIdxs, function()
                self.Parent:PlayCacheEffectSettles(true, nil, true)
            end)
        else
            -- 非衍生牌直接消融
            self:MoveCardsFromHandToDrop(selectedIdxs, function()
                self.Parent:PlayCacheEffectSettles(true, nil, true)
            end)
        end
    end)
end

function XUiPanelPcgGameCard:Refresh()
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    self.CardCfgIds = stageData:GetHandPool()
    self:RefreshCards()
end

-- 获取对应位置卡牌Id
function XUiPanelPcgGameCard:GetCardId(idx)
    local grid = self.GridCardDic[idx]
    return grid and grid:GetCfgId() or 0
end

-- 检查最新的数据，判断是否播放增加卡牌动画
function XUiPanelPcgGameCard:CheckPlayAddCards(cb)
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local cardCfgIds = stageData:GetHandPool()
    if #cardCfgIds > #self.CardCfgIds then
        local addCardIds = {}
        for i = #self.CardCfgIds + 1, #cardCfgIds do
            table.insert(addCardIds, cardCfgIds[i])
        end
        self:MoveCardsFromDrawToHand(addCardIds, cb)
    else
        if cb then cb() end
    end
end

-- 初始化卡牌
function XUiPanelPcgGameCard:InitCards()
    local CSInstantiate =  CS.UnityEngine.Object.Instantiate
    self.CardPos.gameObject:SetActiveEx(false)
    
    -- 将UiPcgGridCard放进对象池
    self.UiPcgGridCard.transform:SetParent(self.CardPool)
    self.UiPcgGridCard.gameObject:SetActiveEx(false)
    
    -- 创建手牌挂点
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local stageId = stageData:GetId()
    self.MaxHandNum = self._Control:GetStageHandNum(stageId) -- 最大手牌数量
    for i = 1, self.MaxHandNum do
        local posGo = CSInstantiate(self.CardPos, self.CardPos.transform.parent)
        posGo.transform.name = "CardPos".. tostring(i)
        posGo.gameObject:SetActiveEx(true)
        self.CardPosDic[i] = posGo
    end
end

-- 获取新的手牌
function XUiPanelPcgGameCard:GetNewCard()
    local poolCnt = #self.RecycleCards
    if poolCnt > 0 then
        local grid = self.RecycleCards[poolCnt]
        grid:SetSelected(false, true)
        table.remove(self.RecycleCards, poolCnt)
        grid:Open()
        return grid
    end

    local go = CS.UnityEngine.Object.Instantiate(self.UiPcgGridCard, self.CardPool.transform)
    local XUiGridPcgCard = require("XUi/XUiPcg/XUiGrid/XUiGridPcgCard")
    ---@type XUiGridPcgCard
    local grid = XUiGridPcgCard.New(go, self)
    grid:SetInputCallBack(function(idx, eventData)
        self:OnPointerClick(idx, eventData)
    end, function(idx, time)
        self:OnPress(idx, time)
    end, function(idx, eventData)  
        self:OnBeginDrag(idx, eventData)
    end, function(idx, eventData)
        self:OnDrag(idx, eventData)
    end, function(idx, eventData)
        self:OnEndDrag(idx, eventData)
    end, function(idx, eventData)
        self:OnPointerUp(idx, eventData)
    end)
    grid:Open()
    return grid
end

-- 回收手牌区卡牌
function XUiPanelPcgGameCard:RecycleHandCards()
    for i = self.MaxHandNum, 1, -1 do
        local card = self.GridCardDic[i]
        if card then
            self:RecycleCard(card)
        end
    end
    self.GridCardDic = {}
end

-- 回收弃牌堆卡牌
function XUiPanelPcgGameCard:RecycleDropCards()
    if #self.DropCards > 0 then
        for _, grid in pairs(self.DropCards) do
            self:RecycleCard(grid)
        end
        self.DropCards = {}
    end
end

-- 回收展示区卡牌
function XUiPanelPcgGameCard:RecycleExhibitionCards()
    if #self.ExhibitionCards > 0 then
        for _, grid in pairs(self.ExhibitionCards) do
            self:RecycleCard(grid)
        end
        self.ExhibitionCards = {}
    end
end

-- 回收卡牌
function XUiPanelPcgGameCard:RecycleCard(gridCard, isDisable)
    gridCard:ChangeIdx(-1, self.CardPool)
    gridCard:Close()
    table.insert(self.RecycleCards, gridCard)
end

-- 刷新卡牌
function XUiPanelPcgGameCard:RefreshCards()
    -- 回收所有手牌
    self:RecycleHandCards()
    
    -- 重新创建手牌
    local characterType = self:GetCharacterType()
    for i, cardCfgId in ipairs(self.CardCfgIds) do
        local cardPos = self.CardPosDic[i]
        local grid = self:GetNewCard(true)
        self.GridCardDic[i] = grid
        grid:SetCardData(cardCfgId, i, cardPos, true, self.Parent.GetTokenLayerFunc)
        grid:SetCharacterType(characterType)
    end
    
    -- 更新卡牌间距
    local cardCnt = #self.CardCfgIds
    self:RefreshCardSpacing(cardCnt, false)

    -- 卡牌右边区域
    self.CardPosRight.transform:SetParent(self.CardPosDic[cardCnt])
    self.CardPosRight.localPosition = XLuaVector3.New(0, 0, 0)
end

-- 获取当前出站角色类型
function XUiPanelPcgGameCard:GetCharacterType()
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local characterId = stageData:GetAttackCharacterId()
    local characterCfg = self._Control:GetConfigCharacter(characterId)
    return characterCfg.Type
end

-- 选中卡牌
function XUiPanelPcgGameCard:OnSelectCard(idx)
    ---@type XUiGridPcgCard
    local grid = self.GridCardDic[idx]
    grid:SetSelected(true)
    table.insert(self.SelectedCards, grid)
end

-- 是否选中卡牌
function XUiPanelPcgGameCard:IsCardSelected(idx)
    for _, grid in pairs(self.SelectedCards) do
        if grid:GetIdx() == idx then
            return true
        end
    end
    return false
end

-- 取消所有卡牌的选中
function XUiPanelPcgGameCard:ClearCardsSelected(isIgnoreAnim)
    if #self.SelectedCards > 0 then
        for _, gridCard in ipairs(self.SelectedCards) do
            gridCard:SetSelected(false, isIgnoreAnim)
            gridCard:ShowPreviewTxt(false)
        end
        self.SelectedCards = {}
    end
    self:ShowPanelUseCard(false)
end

function XUiPanelPcgGameCard:OnCardClick(idx)
    ---@type XUiGridPcgCard
    local grid = self.GridCardDic[idx]
    local isSelected = grid:IsSelected()
    -- 取消旧卡牌选中
    self:ClearCardsSelected()
    -- 选中新卡牌
    if not isSelected then
        self:ShowPanelUseCard(true)
        self:OnSelectCard(idx)

        -- 红、黄、蓝卡牌支持连消，最多3消
        local cardColor = grid:GetCardColor()
        local isMult = cardColor == XEnumConst.PCG.COLOR_TYPE.RED or cardColor == XEnumConst.PCG.COLOR_TYPE.BLUE or cardColor == XEnumConst.PCG.COLOR_TYPE.YELLOW
        if isMult then
            -- 左1
            local leftGrid1 = self.GridCardDic[idx - 1]
            if leftGrid1 and leftGrid1:GetCardColor() == cardColor then
                self:OnSelectCard(idx - 1)
                -- 左2
                local leftGrid2 = self.GridCardDic[idx - 2]
                if leftGrid2 and leftGrid2:GetCardColor() == cardColor then
                    self:OnSelectCard(idx - 2)
                end
            end
            -- 右1
            local rightGrid1 = self.GridCardDic[idx + 1]
            if #self.SelectedCards < self.MAX_SELECTED_CARD_CNT and rightGrid1 and rightGrid1:IsNodeShow() and rightGrid1:GetCardColor() == cardColor then
                self:OnSelectCard(idx + 1)
                -- 右2
                local rightGrid2 = self.GridCardDic[idx + 2]
                if #self.SelectedCards < self.MAX_SELECTED_CARD_CNT and rightGrid2 and rightGrid2:IsNodeShow() and rightGrid2:GetCardColor() == cardColor then
                    self:OnSelectCard(idx + 2)
                end
            end
        end
        
        -- 选中卡牌的出牌效果预览
        self:ShowSelectedCardDesc()
    end
end

-- 请求使用指挥官技能
function XUiPanelPcgGameCard:OnRequestCommanderSkill()
    local curCfgIds = {}
    for i = 1, self.MaxHandNum do
        local gridCard = self.GridCardDic[i]
        if gridCard then
            table.insert(curCfgIds, gridCard:GetCfgId())
        end
    end
    
    local isCardPosChange = false
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local oldCfgIds = stageData:GetHandPool()
    for i, cfgId in ipairs(oldCfgIds) do
        if cfgId ~= curCfgIds[i] then
            isCardPosChange = true
        end
    end

    -- 卡牌位置没有变化
    if not isCardPosChange then
        self:ClearCardsSelected()
        self:RefreshCards()
        return
    end
    
    XMVCA.XPcg:PcgCommanderBehaviorRequest(curCfgIds,function()
        self:ClearCardsSelected()
        self.Parent:ClosePanelUseSkill()
    end)
end

-- 刷新卡牌间距
function XUiPanelPcgGameCard:RefreshCardSpacing(cardCnt, isAnim, changeCardCnt)
    if cardCnt == 0 then return end
    
    local cardSpacing = tonumber(self._Control:GetClientConfig("CardSpacing", cardCnt))
    if self.LastCardSpacing == cardSpacing then
        return
    end

    if not isAnim then
        self.CardList.spacing = cardSpacing
    else
        local ANIM_TIME = changeCardCnt * XEnumConst.PCG.ANIM_TIME_CARD_SPACING_OFFSET / 1000
        local startValue = self.CardList.spacing
        local endValue = cardSpacing
        self:ClearCardSpacingTimer()
        self.CardSpacingTimer = XUiHelper.Tween(ANIM_TIME, function(f)
            self.CardList.spacing = startValue + (endValue - startValue) * f
        end, function()
            self.CardList.spacing = endValue
        end)
    end
    self.LastCardSpacing = cardSpacing
end

function XUiPanelPcgGameCard:ClearCardSpacingTimer()
    if self.CardSpacingTimer then
        XScheduleManager.UnSchedule(self.CardSpacingTimer)
        self.CardSpacingTimer = nil
    end
end

-- 设置是否在执行动画过程中
function XUiPanelPcgGameCard:SetIsAnim(isAnim)
    if self.IsAnim == isAnim then
        XLog.Warning("XUiPanelPcgGameCard:SetIsAnim 重复设置动画状态 self.IsAnim = " .. tostring(isAnim))
    end
    self.IsAnim = isAnim
end

-- 是否在执行动画过程中
function XUiPanelPcgGameCard:GetIsAnim()
    return self.IsAnim == true
end

-- 选中卡牌的出牌效果预览
function XUiPanelPcgGameCard:ShowSelectedCardDesc()
    if #self.SelectedCards == 0 then return end
    ---@type XUiGridPcgCard
    local firstCard = nil
    for _, card in ipairs(self.SelectedCards) do
        if not firstCard or card:GetIdx() < firstCard:GetIdx() then
            firstCard = card
        end
    end

    local cardCfgId = firstCard:GetCfgId()
    local cardCfg = self._Control:GetConfigCards(cardCfgId)
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local characterId = stageData:GetAttackCharacterId()
    local characterCfg = self._Control:GetConfigCharacter(characterId)
    local txt = ""
    if cardCfg.Color == XEnumConst.PCG.COLOR_TYPE.RED then
        txt = characterCfg.RedBallDesc
    elseif cardCfg.Color == XEnumConst.PCG.COLOR_TYPE.BLUE then
        txt = characterCfg.BlueBallDesc
    elseif cardCfg.Color == XEnumConst.PCG.COLOR_TYPE.YELLOW then
        txt = characterCfg.YellowBallDesc
    end
    if not string.IsNilOrEmpty(txt) then
        firstCard:ShowPreviewTxt(true, txt)
    end
end

--region 手势操作
function XUiPanelPcgGameCard:OnPointerClick(idx, eventData)
    -- 非出牌阶段不可操作
    if not self.Parent:IsPlayCardState(true) then return end
    -- 正在播放动画
    if self.Parent:IsAnim() then return end
    
    local isUsingSkill = self.Parent:GetIsUsingSkill()
    if not isUsingSkill then
        self:OnCardClick(idx)
    end
end

function XUiPanelPcgGameCard:OnPress(idx, time)
    -- 长按超过0.2秒才响应操作
    if time < 0.2 then return end
    -- 不在手牌区
    if idx == -1 then return end

    -- 打开卡牌详情
    local isUsingSkill = self.Parent:GetIsUsingSkill()
    if not self.IsDraging and not isUsingSkill and not self.IsShowCardDetail then
        ---@type XPcgPlayingStage
        local stageData = self._Control.GameSubControl:GetPlayingStageData()
        local characterId = stageData:GetAttackCharacterId()
        local grid = self.GridCardDic[idx]
        local cardId = grid:GetCfgId()
        XLuaUiManager.Open("UiPcgPopupCardDetail", cardId, characterId, true, true, self.Parent.GetTokenLayerFunc)
        self.IsShowCardDetail = true
    end
end

function XUiPanelPcgGameCard:OnBeginDrag(idx, eventData)
    -- 非出牌阶段不可操作
    if not self.Parent:IsPlayCardState(true) then return end
    -- 正在播放动画
    if self.Parent:IsAnim() then return end
    -- 正在显示卡牌详情
    if self.IsShowCardDetail then return end
    self.IsDraging = true

    local isUsingSkill = self.Parent:GetIsUsingSkill()
    if isUsingSkill then
        self:ClearCardsSelected()
        self:OnSelectCard(idx) -- 指挥官技能只能选择单张卡牌
    else
        -- 支持在未选中当前卡牌情况下直接拖拽
        if not self:IsCardSelected(idx) then
            self:OnCardClick(idx) -- 普通出牌有连选机制
        end
    end

    -- 停止选中卡牌弹起动画
    for _, tempGrid in ipairs(self.SelectedCards) do
        tempGrid:KillTween()
        tempGrid:SetSelected(true, true)
    end

    -- 记录初始位置
    local grid = self.GridCardDic[idx]
    self.BeginDragCardLocalPos = grid:GetLocalPosition()
    local hasValue, pos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.Transform, eventData.position, eventData.pressEventCamera)
    self.BeginDragFingerPos = pos
end

function XUiPanelPcgGameCard:OnDrag(idx, eventData)
    if not self.IsDraging then return end
    -- 非出牌阶段不可操作
    if not self.Parent:IsPlayCardState() then return end
    -- 正在播放动画
    if self.Parent:IsAnim() then return end
    
    -- 卡牌拖拽移动
    local hasValue, pos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.Transform, eventData.position, eventData.pressEventCamera)
    local deltaX = pos.x - self.BeginDragFingerPos.x
    local deltaY = pos.y - self.BeginDragFingerPos.y
    local deltaPos = XLuaVector3.New(self.BeginDragCardLocalPos.x + deltaX, self.BeginDragCardLocalPos.y + deltaY, 0)
    for _, tempGrid in ipairs(self.SelectedCards) do
        tempGrid:SetLocalPosition(deltaPos)
    end
    
    -- 使用指挥官技能时，拖拽卡牌卡牌会影响其他手牌挂点
    local isUsingSkill = self.Parent:GetIsUsingSkill()
    if isUsingSkill then
        local curIdx = self.SelectedCards[1]:GetIdx()
        local moveIdx = self:CheckCardMoveIdx(eventData)
        if moveIdx and curIdx ~= moveIdx then
            self:MoveCardOnDrag(curIdx, moveIdx)
        end
    end
end

function XUiPanelPcgGameCard:OnEndDrag(idx, eventData)
    if not self.IsDraging then return end
    self.IsDraging = false
    
    -- 游戏结束
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.End then
        self:ClearCardsSelected()
        return 
    end

    local isUsingSkill = self.Parent:GetIsUsingSkill()
    if isUsingSkill then
        local isInRest = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(self.UseSkillArea, eventData.position, eventData.pressEventCamera)
        if isInRest then
            -- 使用指挥官技能
            self:OnRequestCommanderSkill()
        else
            -- 取消使用技能，还原卡牌和位置
            self:ClearCardsSelected()
            self:RefreshCards()
        end
    else
        local rect = self.UseCardArea:GetComponent("RectTransform")
        local isInRest = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(rect, eventData.position, eventData.pressEventCamera)
        if isInRest then
            -- 在出牌区域松手，视为出牌
            self:OnBtnPlayClick()
        else
            -- 卡牌取消选中并归位
            self:ClearCardsSelected()
        end
    end
end

function XUiPanelPcgGameCard:OnPointerUp(idx, eventData)
    -- 关闭卡牌详情
    if self.IsShowCardDetail then
        self.IsShowCardDetail = false
        XLuaUiManager.Close("UiPcgPopupCardDetail")
    end
end

-- 检测卡牌移动下标
function XUiPanelPcgGameCard:CheckCardMoveIdx(eventData)
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local count = stageData:GetHandPoolCount() -- 卡牌数量
    
    -- 最右边
    local CSRectTransformUtility = CS.UnityEngine.RectTransformUtility
    local isInLeftRest = CSRectTransformUtility.RectangleContainsScreenPoint(self.CardPosRight, eventData.position, eventData.pressEventCamera)
    if isInLeftRest then
        return count
    end
    
    -- 从后往前遍历检测
    for i = self.MaxHandNum, 1, -1 do
        local grid = self.GridCardDic[i]
        if grid then
            local rect = self.CardPosDic[i]
            local isInRest = CSRectTransformUtility.RectangleContainsScreenPoint(rect, eventData.position, eventData.pressEventCamera)
            if isInRest then
                return i
            end
        end
    end
end

-- 拖拽中移动单张卡牌
function XUiPanelPcgGameCard:MoveCardOnDrag(idx, targetIdx)
    if idx < targetIdx then
        local grid = self.GridCardDic[idx]
        -- 左移1位
        for i = idx + 1, targetIdx do
            local tempGrid = self.GridCardDic[i]
            local newIdx = i - 1
            self.GridCardDic[newIdx] = tempGrid
            tempGrid:ChangeIdx(newIdx, self.CardPosDic[newIdx], true)
            -- 卡牌移动音效
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XEnumConst.PCG.CUE_ID_CARD_MOVE)
        end
        self.GridCardDic[targetIdx] = grid
        local beforePos = grid:GetLocalPosition()
        grid:ChangeIdx(targetIdx, self.CardPosDic[targetIdx])
        local afterPos = grid:GetLocalPosition()
        local offsetPos = XLuaVector3.New(beforePos.x - afterPos.x, beforePos.y - afterPos.y, beforePos.z - afterPos.z)
        self.BeginDragCardLocalPos = XLuaVector3.New(self.BeginDragCardLocalPos.x - offsetPos.x, self.BeginDragCardLocalPos.y - offsetPos.y, self.BeginDragCardLocalPos.z - offsetPos.z)
    elseif idx > targetIdx then
        local grid = self.GridCardDic[idx]
        -- 右边移1位
        for i = idx - 1, targetIdx, -1 do
            local tempGrid = self.GridCardDic[i]
            local newIdx = i + 1
            self.GridCardDic[newIdx] = tempGrid
            tempGrid:ChangeIdx(newIdx, self.CardPosDic[newIdx], true)
            -- 卡牌移动音效
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XEnumConst.PCG.CUE_ID_CARD_MOVE)
        end
        self.GridCardDic[targetIdx] = grid
        local beforePos = grid:GetLocalPosition()
        grid:ChangeIdx(targetIdx, self.CardPosDic[targetIdx])
        local afterPos = grid:GetLocalPosition()
        local offsetPos = XLuaVector3.New(beforePos.x - afterPos.x, beforePos.y - afterPos.y, beforePos.z - afterPos.z)
        self.BeginDragCardLocalPos = XLuaVector3.New(self.BeginDragCardLocalPos.x - offsetPos.x, self.BeginDragCardLocalPos.y - offsetPos.y, self.BeginDragCardLocalPos.z - offsetPos.z)
    end
end

-- 是否显示使用卡牌面板
function XUiPanelPcgGameCard:ShowPanelUseCard(isShow)
    self.PanelUseCard.gameObject:SetActiveEx(isShow)
end
--endregion

--region 展示区卡牌处理
-- 卡牌从手牌到弃牌区
function XUiPanelPcgGameCard:MoveCardsFromHandToDrop(cardIdxs, cb)
    XLuaUiManager.Remove("UiPcgPopupCardDetail")
    self:SetIsAnim(true)
    -- 回收上一次进入弃牌堆的卡牌
    self:RecycleDropCards()
    -- 卡牌从手牌区进入展示区
    self:AddExhibitionCardsFromHand(cardIdxs)

    -- 卡牌从展示区进入弃牌堆
    self:ClearExhibitionTimer()
    self.ExhibitionTimer = XScheduleManager.ScheduleOnce(function()
        self.ExhibitionTimer = nil
        self:RemoveExhibitionCardsToDrop(function()
            self:SetIsAnim(false)
            if cb then cb() end
        end)
    end, XEnumConst.PCG.ANIM_TIME_EXHIBITION + XEnumConst.PCG.ANIM_TIME_CARD_BACK)
end

-- 卡牌从手牌到消融
function XUiPanelPcgGameCard:MoveCardsFromHandToMelt(cardIdxs, cb)
    XLuaUiManager.Remove("UiPcgPopupCardDetail")
    self:SetIsAnim(true)
    -- 回收上一次进入弃牌堆的卡牌
    self:RecycleDropCards()
    -- 卡牌从手牌区进入展示区
    self:AddExhibitionCardsFromHand(cardIdxs)

    -- 卡牌从展示区进入弃牌堆
    self:ClearExhibitionTimer()
    self.ExhibitionTimer = XScheduleManager.ScheduleOnce(function()
        self.ExhibitionTimer = nil
        self:RemoveExhibitionCardsToMelt(function()
            self:SetIsAnim(false)
            if cb then cb() end
        end)
    end, XEnumConst.PCG.ANIM_TIME_EXHIBITION + XEnumConst.PCG.ANIM_TIME_CARD_BACK)
end

-- 卡牌从抽牌堆到手牌
function XUiPanelPcgGameCard:MoveCardsFromDrawToHand(cardIds, cb)
    self:SetIsAnim(true)
    -- 回收上一次进入弃牌堆的卡牌
    self:RecycleDropCards()
    -- 卡牌从手牌区进入展示区
    self:AddExhibitionCardsFromDraw(cardIds)

    -- 卡牌从展示区进入手牌
    self:ClearExhibitionTimer()
    self.ExhibitionTimer = XScheduleManager.ScheduleOnce(function()
        self.ExhibitionTimer = nil
        self:RemoveExhibitionCardsToHand(function()
            self:SetIsAnim(false)
            if cb then cb() end
        end)
    end, XEnumConst.PCG.ANIM_TIME_EXHIBITION + XEnumConst.PCG.ANIM_TIME_CARD_BACK)
end

-- 卡牌从弃牌堆到手牌
function XUiPanelPcgGameCard:MoveCardsFromDropToHand(cardIds, cb)
    self:SetIsAnim(true)
    -- 回收上一次进入弃牌堆的卡牌
    self:RecycleDropCards()
    -- 卡牌从手牌区进入展示区
    self:AddExhibitionCardsFromDrop(cardIds)

    -- 卡牌从展示区进入手牌
    self:ClearExhibitionTimer()
    self.ExhibitionTimer = XScheduleManager.ScheduleOnce(function()
        self.ExhibitionTimer = nil
        self:RemoveExhibitionCardsToHand(function()
            self:SetIsAnim(false)
            if cb then cb() end
        end)
    end, XEnumConst.PCG.ANIM_TIME_EXHIBITION + XEnumConst.PCG.ANIM_TIME_CARD_BACK)
end

-- 卡牌从衍生牌区到手牌
function XUiPanelPcgGameCard:MoveCardsFromDerivativeToHand(cardIds)
    self:SetIsAnim(true)
    -- 回收上一次进入弃牌堆的卡牌
    self:RecycleDropCards()
    -- 卡牌从手牌区进入展示区
    self:AddExhibitionCardsFromDerivative(cardIds)

    -- 卡牌从展示区进入手牌
    self:ClearExhibitionTimer()
    self.ExhibitionTimer = XScheduleManager.ScheduleOnce(function()
        self.ExhibitionTimer = nil
        self:RemoveExhibitionCardsToHand(function()
            self:SetIsAnim(false)
        end)
    end, XEnumConst.PCG.ANIM_TIME_EXHIBITION + XEnumConst.PCG.ANIM_TIME_CARD_BACK)
end

-- 整理手牌
function XUiPanelPcgGameCard:PlaySortCards(cardIds)
    XLuaUiManager.Remove("UiPcgPopupCardDetail")
    self:SetIsAnim(true)
    -- 回收上一次进入弃牌堆的卡牌
    self:RecycleDropCards()
    -- 卡牌从手牌区进入洗牌区
    self:AddSortCardsFromHand(cardIds)

    -- 卡牌从洗牌区回到手牌
    self:ClearSortTimer()
    self.SortTimer = XScheduleManager.ScheduleOnce(function()
        self.SortTimer = nil
        self:RemoveSortCardsToHand(cardIds, function()
            self:SetIsAnim(false)
        end)
    end, XEnumConst.PCG.ANIM_TIME_CARD_BACK)
end

-- 移动单张手牌
function XUiPanelPcgGameCard:PlayMoveCard(idx, targetIdx)
    if idx < targetIdx then
        local grid = self.GridCardDic[idx]
        -- 左移1位
        for i = idx + 1, targetIdx do
            local tempGrid = self.GridCardDic[i]
            local newIdx = i - 1
            self.GridCardDic[newIdx] = tempGrid
            tempGrid:ChangeIdx(newIdx, self.CardPosDic[newIdx], true)
        end
        self.GridCardDic[targetIdx] = grid
        grid:ChangeIdx(targetIdx, self.CardPosDic[targetIdx], true)
    elseif idx > targetIdx then
        local grid = self.GridCardDic[idx]
        -- 右边移1位
        for i = idx - 1, targetIdx, -1 do
            local tempGrid = self.GridCardDic[i]
            local newIdx = i + 1
            self.GridCardDic[newIdx] = tempGrid
            tempGrid:ChangeIdx(newIdx, self.CardPosDic[newIdx], true)
        end
        self.GridCardDic[targetIdx] = grid
        grid:ChangeIdx(targetIdx, self.CardPosDic[targetIdx], true)
    end
end

-- 卡牌 手牌->展示区
function XUiPanelPcgGameCard:AddExhibitionCardsFromHand(cardIdxs)
    self:ClearCardsSelected(true)
    
    -- 卡牌进入展示区
    for i, cardIdx in ipairs(cardIdxs) do
        -- 手牌移除该卡牌
        local grid = self.GridCardDic[cardIdx]
        self.GridCardDic[cardIdx] = nil

        -- 进入展示牌区
        local posLink = self:GetExhibitionPosLink(i)
        grid:ChangeIdx(-1, posLink, true)
        table.insert(self.ExhibitionCards, grid)
    end
    -- 播放出牌音效
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XEnumConst.PCG.CUE_ID_CARD_OUT_HAND)
    
    -- 整理手牌
    self:AdjustCards(#cardIdxs)
end

-- 添加展示区卡牌
function XUiPanelPcgGameCard:AddExhibitionCards(cardIds, originParent)
    local characterType = self:GetCharacterType()
    for _, cardId in ipairs(cardIds) do
        -- 创建抽牌堆卡牌
        local grid = self:GetNewCard()
        grid:SetCardData(cardId, -1, originParent, true, self.Parent.GetTokenLayerFunc)
        grid:SetCharacterType(characterType)
        -- 移动进展示区
        local posIndex = #self.ExhibitionCards + 1
        local posLink = self:GetExhibitionPosLink(posIndex)
        grid:ChangeIdx(posIndex, posLink, true)
        table.insert(self.ExhibitionCards, grid)
    end

    -- 播放卡牌出现音效
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XEnumConst.PCG.CUE_ID_CARD_ENABLE)
end

-- 卡牌 抽牌堆->展示区
function XUiPanelPcgGameCard:AddExhibitionCardsFromDraw(cardIds)
    self:AddExhibitionCards(cardIds, self.DrawPoolPos)
end

-- 卡牌 衍生牌区->展示区
function XUiPanelPcgGameCard:AddExhibitionCardsFromDerivative(cardIds)
    self:AddExhibitionCards(cardIds, self.DerivativePoolPos)
end

-- 卡牌 弃牌堆->展示区
function XUiPanelPcgGameCard:AddExhibitionCardsFromDrop(cardIds)
    self:AddExhibitionCards(cardIds, self.DropPoolPos)
end

-- 卡牌 展示区->手牌
function XUiPanelPcgGameCard:RemoveExhibitionCardsToHand(cb)
    -- 修改挂点和引用
    ---@type XUiGridPcgCard[]
    local cards = {}
    local curCardCnt = #self.CardCfgIds
    for i, grid in ipairs(self.ExhibitionCards) do
        local handIndex = curCardCnt + i
        -- 超过手牌最大上限，移到弃牌堆
        if handIndex > self.MaxHandNum then
            grid:ChangeIdx(-1, self.DropPoolPos, false)
            table.insert(self.DropCards, grid)
        -- 进入手牌区
        else
            local parent = self.CardPosDic[handIndex]
            grid:ChangeIdx(handIndex, parent, false)
            self.GridCardDic[handIndex] = grid
        end
        table.insert(cards, grid)
    end
    self.ExhibitionCards = {}

    -- 错开播放移动动画
    local cardCnt = #cards
    local index = 1
    if cardCnt > 1 then
        cards[index]:PlayAnimBack()
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XEnumConst.PCG.CUE_ID_CARD_MOVE_HAND)
        local loopCnt = cardCnt - 1
        self:ClearExhibitionTimer()
        self.ExhibitionTimer = XScheduleManager.Schedule(function()
            index = index + 1
            if index < cardCnt then
                cards[index]:PlayAnimBack()
                XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XEnumConst.PCG.CUE_ID_CARD_MOVE_HAND)
            else
                self.ExhibitionTimer = nil
                -- 最后一个动画结束执行回调
                cards[index]:PlayAnimBack(cb)
                XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XEnumConst.PCG.CUE_ID_CARD_MOVE_HAND)
            end
        end, XEnumConst.PCG.ANIM_TIME_CARD_OFFSET, loopCnt)
    else
        cards[index]:PlayAnimBack(cb)
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XEnumConst.PCG.CUE_ID_CARD_MOVE_HAND)
    end

    -- 整理手牌
    self:AdjustCards(cardCnt)
end

-- 卡牌 展示区->抽牌堆
function XUiPanelPcgGameCard:RemoveExhibitionCardsToDraw()

end

-- 卡牌 展示区->弃牌堆
function XUiPanelPcgGameCard:RemoveExhibitionCardsToDrop(cb)
    -- 修改挂点和引用
    for _, grid in ipairs(self.ExhibitionCards) do
        grid:ChangeIdx(-1, self.DropPoolPos, false)
        table.insert(self.DropCards, grid)
    end
    self.ExhibitionCards = {}
    
    -- 错开播放移动动画
    local index = #self.DropCards
    if index > 1 then
        self.DropCards[index]:PlayAnimBack()
        local loopCnt = index - 1
        self:ClearExhibitionTimer()
        self.ExhibitionTimer = XScheduleManager.Schedule(function()
            index = index - 1
            if index > 1 then
                self.DropCards[index]:PlayAnimBack()
            else
                -- 最后一个动画结束执行回调
                self.DropCards[index]:PlayAnimBack(cb)
            end
        end, XEnumConst.PCG.ANIM_TIME_CARD_OFFSET, loopCnt)
    else
        self.DropCards[index]:PlayAnimBack(cb)
    end
end

-- 卡牌 展示区->消融
function XUiPanelPcgGameCard:RemoveExhibitionCardsToMelt(cb)
    local cardCnt = #self.ExhibitionCards
    for i = 1, cardCnt do
        local card = self.ExhibitionCards[i]
        if i == cardCnt then
            card:PlayAnimCardDisable(function()
                self:RecycleExhibitionCards()
                if cb then cb() end
            end)
        else
            card:PlayAnimCardDisable()
        end
    end
end

-- 卡牌从手牌区进入洗牌区
function XUiPanelPcgGameCard:AddSortCardsFromHand()
    self:ClearCardsSelected(true)

    -- 卡牌进入洗牌区
    for _, card in pairs(self.GridCardDic) do
        table.insert(self.SortCards, card)
        card:ChangeIdx(-1, self.SortPoolPos, true)
    end
    self.GridCardDic = {}
end

-- 移除洗牌区卡牌到手牌区
function XUiPanelPcgGameCard:RemoveSortCardsToHand(cardIds, cb)
    -- 播放翻牌动画
    for i, card in pairs(self.SortCards) do
        card:PlayAnimFlipCard()
    end

    -- 调整卡牌顺序
    self.SortTimer2 = XScheduleManager.ScheduleOnce(function()
        -- 确定洗牌后卡牌对应的位置，卡牌Id:卡牌位置
        local cardIdToIdx = {}
        for i, cardId in ipairs(cardIds) do
            cardIdToIdx[cardId] = cardIdToIdx[cardId] or {} -- 衍生牌会有多张相同Id手牌
            table.insert(cardIdToIdx[cardId], i)
        end

        -- 修改挂点和引用
        for _, card in ipairs(self.SortCards) do
            local cardId = card:GetCfgId()
            local idxs = cardIdToIdx[cardId]
            local idx = idxs[1]
            table.remove(idxs, 1)
            local parent = self.CardPosDic[idx]
            self.GridCardDic[idx] = card
            card:ChangeIdx(idx, parent)
        end
        self.SortCards = {}
    end, XEnumConst.PCG.ANIM_TIME_CARD_FLIP_CHANGE)

    -- 播放移动动画
    self.SortTimer3 = XScheduleManager.ScheduleOnce(function()
        for i, card in pairs(self.GridCardDic) do
            if i == 1 then
                card:PlayAnimBack(cb)
            else
                card:PlayAnimBack()
            end
        end
    end, XEnumConst.PCG.ANIM_TIME_CARD_FLIP)
end

function XUiPanelPcgGameCard:ClearSortTimer()
    if self.SortTimer then
        XScheduleManager.UnSchedule(self.SortTimer)
        self.SortTimer = nil
    end
    if self.SortTimer2 then
        XScheduleManager.UnSchedule(self.SortTimer2)
        self.SortTimer2 = nil
    end
    if self.SortTimer3 then
        XScheduleManager.UnSchedule(self.SortTimer3)
        self.SortTimer3 = nil
    end
end

-- 获取展示区卡牌位置挂点
function XUiPanelPcgGameCard:GetExhibitionPosLink(index)
    self.ExhibitionCardPos.gameObject:SetActiveEx(false)
    self.ExhibitionPosLinks = self.ExhibitionPosLinks or {}
    local curPosCnt = #self.ExhibitionPosLinks
    if curPosCnt < index then
        local CSInstantiate = CS.UnityEngine.Object.Instantiate
        for i = curPosCnt + 1, 10 do
            local go = CSInstantiate(self.ExhibitionCardPos, self.ExhibitionCardPos.transform.parent)
            go.transform.name = "ExhibitionCardPos" .. tostring(i)
            go.gameObject:SetActiveEx(true)
            table.insert(self.ExhibitionPosLinks, go)
        end
    end
    return self.ExhibitionPosLinks[index]
end

-- 清除展示区相关定时器
function XUiPanelPcgGameCard:ClearExhibitionTimer()
    if self.ExhibitionTimer then
        XScheduleManager.UnSchedule(self.ExhibitionTimer)
        self.ExhibitionTimer = nil
    end
end

-- 整理手牌
function XUiPanelPcgGameCard:AdjustCards(changeCardCnt)
    -- 如果前面有空位置，手牌往前移
    for i = 1, self.MaxHandNum do
        -- 当前位置没有手牌
        if not self.GridCardDic[i] then
            -- 往后遍历找到第一张手牌
            for j = i + 1, self.MaxHandNum do
                if self.GridCardDic[j] then
                    local grid = self.GridCardDic[j]
                    grid:ChangeIdx(i, self.CardPosDic[i],true)
                    self.GridCardDic[i] = grid
                    self.GridCardDic[j] = nil
                    break
                end
            end
        end
    end

    -- 隐藏没有卡牌的挂点
    self.CardCfgIds = {}
    for i = 1, self.MaxHandNum do
        local grid = self.GridCardDic[i]
        local isShow = grid ~= nil
        if isShow then
            table.insert(self.CardCfgIds, grid:GetCfgId())
        end
    end

    -- 更新卡牌间距
    local cardCnt = #self.CardCfgIds
    self:RefreshCardSpacing(cardCnt, true, changeCardCnt)

    -- 卡牌右边区域
    self.CardPosRight.transform:SetParent(self.CardPosDic[cardCnt])
    self.CardPosRight.localPosition = XLuaVector3.New(0, 0, 0)
end
--endregion

return XUiPanelPcgGameCard
