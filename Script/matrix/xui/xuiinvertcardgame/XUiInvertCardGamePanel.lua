local tableInsert = table.insert
local Vector2 = CS.UnityEngine.Vector2
local CSTextManagerGetText = CS.XTextManager.GetText

local XUiInvertGamePanel = XClass(nil, "XUiInvertGamePanel")
local XUiInvertGameCardItem = require("XUi/XUiInvertCardGame/XUiInvertGameCardItem")

function XUiInvertGamePanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiInvertGamePanel:Init()
    self.CardWidth = self.GridDraw.rect.width
    self.CardHeight = self.GridDraw.rect.height
    self.GamePanelWidth = self.Transform.rect.width
    self.GamePanelHeight = self.Transform.rect.height
    self.HalfGamePanelWidth = self.GamePanelWidth / 2
    self.HalfGamePanelHeight = self.GamePanelHeight / 2
    self.CardPool = {}
    self.CardItems = {}
    self.GridDrawRoot.gameObject:SetActiveEx(false)
end

function XUiInvertGamePanel:Refresh(stageEntity)
    if stageEntity then
        self.StageEntity = stageEntity
        self.StageId = self.StageEntity:GetId()
        local stageStatus = self.StageEntity:GetStatus()
        if stageStatus == XInvertCardGameConfig.InvertCardGameStageStatusType.Lock then
            return
        elseif stageStatus == XInvertCardGameConfig.InvertCardGameStageStatusType.Process then
            local startState = XDataCenter.InvertCardGameManager.GetStartStage(self.StageEntity)
            if startState == XInvertCardGameConfig.InvertCardGameStartStage.NotStart then
                self:RefreshGamePanelWithFinish() -- 没开始的时候用配置卡牌顺序刷新面板
                self:RefreshMessagePanel()
                return
            end
            local cardList = stageEntity:GetRandomCardList()
            local datas = {}
            for index, data in ipairs(cardList) do
                local creatData = {
                    StageId = self.StageId,
                    Index = index,
                    CardId = data.CardId,
                    IsFinish = data.IsFinish,
                }
                tableInsert(datas, creatData)
            end
            self:RefreshLayout(self.StageEntity:GetRowAndColumnCount())
            self:CreateTemplates(datas)
        elseif stageStatus == XInvertCardGameConfig.InvertCardGameStageStatusType.Finish then
            self:RefreshGamePanelWithFinish()
        end
        self:RefreshMessagePanel()
    end
end

function XUiInvertGamePanel:RefreshGamePanelWithFinish(isBack)
    if self.StageEntity then
        local containCards = self.StageEntity:GetContainCards()
        local datas = {}
        for index, cardId in ipairs(containCards) do
            local creatData = {
                StageId = self.StageId,
                Index = index,
                CardId = cardId,
                IsFinish = true,
                IsBack = isBack,
            }
            tableInsert(datas, creatData)
        end
        self:RefreshLayout(self.StageEntity:GetRowAndColumnCount())
        self:CreateTemplates(datas)
    end
end

function XUiInvertGamePanel:RefreshMessagePanel()
    local stageStatus = self.StageEntity:GetStatus()
    local startState = XDataCenter.InvertCardGameManager.GetStartStage(self.StageEntity)
    if startState == XInvertCardGameConfig.InvertCardGameStartStage.NotStart then
        self.PanelMessage.gameObject:SetActiveEx(false)
        return
    end
    if stageStatus == XInvertCardGameConfig.InvertCardGameStageStatusType.Lock or stageStatus == XInvertCardGameConfig.InvertCardGameStageStatusType.Finish then
        self.PanelMessage.gameObject:SetActiveEx(false)
    elseif stageStatus == XInvertCardGameConfig.InvertCardGameStageStatusType.Process then
        self.PanelMessage.gameObject:SetActiveEx(true)
        if self.StageEntity:GetTotalCounts() < self.StageEntity:GetMaxCostNum() then
            self.TxtCount01.text = CSTextManagerGetText("InvertCardGameMaxInvertConutTextBlue", self.StageEntity:GetMaxCostNum(), self.StageEntity:GetTotalCounts(), self.StageEntity:GetMaxCostNum())
            if XDataCenter.InvertCardGameManager.CheckHasEnoughItem(self.StageEntity) then
                self.TxtSpend.text = CSTextManagerGetText("InvertCardGameConstomCountBlue", self.StageEntity:GetCostCoinNum())
            else
                self.TxtSpend.text = CSTextManagerGetText("InvertCardGameConstomCountRed", self.StageEntity:GetCostCoinNum())
            end
        else
            local maxCostNum = self.StageEntity:GetMaxCostNum()
            self.TxtCount01.text = CSTextManagerGetText("InvertCardGameMaxInvertConutTextNormal", maxCostNum, maxCostNum, maxCostNum)
            self.TxtSpend.text = CSTextManagerGetText("InvertCardGameConstomCountBlue", 0)
        end
        self.TxtCount02.text = CSTextManagerGetText("InvertCardGameCurInvertConutText", #self.StageEntity:GetInvertList(), self.StageEntity:GetMaxOnCardsNum())
        
        self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItem(XDataCenter.InvertCardGameManager.GetConsumeItemId()).Template.Icon)
    end
end

function XUiInvertGamePanel:RefreshLayout(rowCount, columnCount)
    local spacingRow = (self.GamePanelWidth - columnCount * self.CardWidth) / (columnCount + 1) + self.CardWidth
    local spacingColumn = (self.GamePanelHeight - rowCount * self.CardHeight) / (rowCount + 1) + self.CardHeight
    if spacingRow < self.CardWidth or spacingColumn < self.CardHeight then
        XLog.Error("Invert Card Game Refresh Layout Error")
        return
    end
    self.LayoutGroup.spacing = Vector2(spacingRow, spacingColumn)
    self.LayoutGroup.constraintCount = columnCount
end

function XUiInvertGamePanel:CreateTemplates(datas)
    self.CardItems = {}
    local onCreat = function(cardItem, data)
        cardItem:SetActiveEx(true)
        cardItem:OnCreat(data, self)
        tableInsert(self.CardItems, cardItem)
    end

    XUiHelper.CreateTemplates(self.RootUi, self.CardPool, datas, XUiInvertGameCardItem.New, self.GridDrawRoot,
        self.LayoutGroup.transform, onCreat)
end

function XUiInvertGamePanel:PlayAllTurnOnAnimation(cb)
    for index, cardItem in ipairs(self.CardItems) do
        if index == #self.CardItems then
            cardItem:DORotate(function()
                cardItem:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Front)
            end, function()
                if cb then
                    cb()
                end
            end)
        else
            cardItem:DORotate(function()
                cardItem:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Front)
            end)
        end
    end
end

function XUiInvertGamePanel:PlayAllTurnOffAnimation(cb)
    for index, cardItem in ipairs(self.CardItems) do
        if index == #self.CardItems then
            cardItem:DORotate(function()
                cardItem:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Back)
            end, function()
                if cb then
                    cb()
                end
            end)
        else
            cardItem:DORotate(function()
                cardItem:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Back)
            end)
        end
    end
end

function XUiInvertGamePanel:PlayCardGatherAnimation(cb)
    for index, cardItem in ipairs(self.CardItems) do
        if index == #self.CardItems then
            cardItem:DOMoveToCenter(function()
                if cb then
                    cb()
                end
            end)
        else
            cardItem:DOMoveToCenter()
        end
    end
end

function XUiInvertGamePanel:PlayCardDisperseAnimation(cb)
    for index, cardItem in ipairs(self.CardItems) do
        if index == #self.CardItems then
            cardItem:DOMoveFromCenter(function()
                if cb then
                    cb()
                end
            end)
        else
            cardItem:DOMoveFromCenter()
        end
    end
end

function XUiInvertGamePanel:PlayUpsetCardAnimation(cb)
    self.RootUi:PlayAnimation("Refresh", cb)
end

function XUiInvertGamePanel:PlayStartAnimation()
    local AsynPlayAllTurnOnAnimation = asynTask(self.PlayAllTurnOnAnimation, self)
    local AsynPlayAllTurnOffAnimation = asynTask(self.PlayAllTurnOffAnimation, self)
    local AsynPlayCardGatherAnimation = asynTask(self.PlayCardGatherAnimation, self)
    local AsynPlayCardDisperseAnimation = asynTask(self.PlayCardDisperseAnimation, self)
    local AsynPlayUpsetCardAnimation = asynTask(self.PlayUpsetCardAnimation, self)
    RunAsyn(function()
        AsynPlayAllTurnOnAnimation() -- 播放转到正面动画
        asynWaitSecond(1) -- 延迟1秒
        AsynPlayAllTurnOffAnimation() -- 播放转回背面动画
        self:SetLayoutGroupEnableEx(false) -- 关闭布局
        asynWaitSecond(1) -- 延迟1秒
        AsynPlayCardGatherAnimation() -- 播放集中卡牌动画
        self.GameObject:SetActiveEx(false)
        -- 播放异步洗牌动画
        AsynPlayUpsetCardAnimation() -- 洗牌动画
        self.GameObject:SetActiveEx(true) -- 打开游戏面板
        -- asynWaitSecond(0.1)
        AsynPlayCardDisperseAnimation() -- 播放分散动画
        self:SetLayoutGroupEnableEx(true) -- 打开布局
        self:Refresh(self.StageEntity) -- 重新用服务器生成的随机卡牌刷新
        self.RootUi:SetFullCoverActiveEx(false) -- 关闭全局遮罩
    end)
end

function XUiInvertGamePanel:PlayCardsChangedAnimation(stageEntity, invertCardIdx, punishCardIdxs, clearCardIdxs)
    local AsynPlayTurnOnAnimation = asynTask(self.PlayTurnOnAnimation, self)
    local AsynPlayPunishAnimation = asynTask(self.PlayPunishAnimation, self)
    local AsynPlayClearCardAnimation = asynTask(self.PlayClearCardAnimation, self)
    local AsynPlayFinishStageAnimation = asynTask(self.PlayFinishStageAnimation, self)
        RunAsyn(function()
            self.RootUi:SetFullCoverActiveEx(true) -- 打开全局遮罩
            AsynPlayTurnOnAnimation(invertCardIdx)
            if punishCardIdxs and next(punishCardIdxs) then
                AsynPlayPunishAnimation(punishCardIdxs)
            end
            if clearCardIdxs and next(clearCardIdxs) then
                AsynPlayClearCardAnimation(clearCardIdxs)
            end
            --self:PlayClearCardAnimation(clearCardIdxs)
            if stageEntity:GetStatus() == XInvertCardGameConfig.InvertCardGameStageStatusType.Finish then
                self:RefreshGamePanelWithFinish(true)
                AsynPlayFinishStageAnimation()
            end
            self:RefreshMessagePanel()
            self.RootUi:RefreshBtnTab()
            self.RootUi.RewardPanel:Refresh(stageEntity)
            self.RootUi:SetFullCoverActiveEx(false) -- 关闭全局遮罩
            XEventManager.DispatchEvent(XEventId.EVENT_INVERT_CARD_GAME_CARD_CHANGED)
        end)
end

function XUiInvertGamePanel:PlayTurnOnAnimation(cardIndex, cb)
    if cardIndex and cardIndex ~= 0 and self.CardItems[cardIndex] then
        self.CardItems[cardIndex]:DORotate(function()
            self.CardItems[cardIndex]:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Front)
        end, function()
            if cb then
                cb()
            end
        end)
    else
        if cb then
            cb()
        end
    end
end

function XUiInvertGamePanel:PlayPunishAnimation(cardIdxs, cb)
    for index, cardIndex in ipairs(cardIdxs) do
        if index == #cardIdxs then
            self.CardItems[cardIndex]:DORotate(function()
                self.CardItems[cardIndex]:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Back)
            end, function()
                if cb then
                    cb()
                end
            end)
        else
            self.CardItems[cardIndex]:DORotate(function()
                self.CardItems[cardIndex]:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Back)
            end)
        end
    end
end

function XUiInvertGamePanel:PlayClearCardAnimation(cardIdxs, cb)
    for index, cardIndex in ipairs(cardIdxs) do
        local card = self.CardItems[cardIndex]
        if index == #cardIdxs then
            card:PlayClearEffectAnimation(function()
                card:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Finish)
                if cb then
                    cb()
                end
            end)
        else
            card:PlayClearEffectAnimation(function()
                card:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Finish)
            end)
        end
    end
end

function XUiInvertGamePanel:PlayFinishStageAnimation(cb)
    for index, cardItem in ipairs(self.CardItems) do
        cardItem:StopClearEffectAnimation()
        cardItem:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Back)
        if index == #self.CardItems then
            cardItem:DORotate(function()
                cardItem:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Front)
            end, function()
                if cb then
                    cb()
                end
            end)
        else
            cardItem:DORotate(function()
                cardItem:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Front)
            end)
        end
    end
end

function XUiInvertGamePanel:SetLayoutGroupEnableEx(bool)
    self.LayoutGroup.enabled = bool
end

return XUiInvertGamePanel
