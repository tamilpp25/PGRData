local XPokerGuessing2Game = require("XModule/XPokerGuessing2/Game/XPokerGuessing2Game")
local XPokerGuessing2Enum = require("XModule/XPokerGuessing2/XPokerGuessing2Enum")

---@class XPokerGuessing2Control : XControl
---@field private _Model XPokerGuessing2Model
local XPokerGuessing2Control = XClass(XControl, "XPokerGuessing2Control")

function XPokerGuessing2Control:OnInit()
    self._Main = {
        Time = 0,
        ---@type XUiPokerGuessing2CharacterData
        Enemy = {
            Name = "",
            Icon = "",
            Card = nil,
            Cards = {},
        },
        EnemyCardIndex = 1,
        ---@type XUiPokerGuessing2CharacterData
        Player = {
            Name = "",
            Icon = "",
            Card = nil,
            Cards = {},
        },
        StageDesc = "",
        StageIndex = 0,
        StageMaxIndex = 0,
        IsOpen = false,
        StageId = 0,
        EnemyDialogue = "",
        IsPassed = false,
    }
    self._SelectCharacter = {
        ---@type XPokerGuessing2UiCharacter[]
        Characters = {},
        ---@type XPokerGuessing2UiCharacter
        Selected = nil,
    }
    self._Settlement = {
        IsWin = false,
        Round = 0,
        Rewards = {},
    }
    self._SelectedCharacterId = XSaveTool.GetData("PokerGuessing2CharacterId" .. XPlayer.Id) or 0
    self._SelectedCardId = 0

    self._StageConfigList = false

    --为了可以重开，游戏结束后，也不清除
    self._GameStageId = 0

    ---@type XPokerGuessing2Game
    self._Game = XPokerGuessing2Game.New()
end

function XPokerGuessing2Control:AddAgencyEvent()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XPokerGuessing2Control:RemoveAgencyEvent()
    XScheduleManager.UnSchedule(self._Timer)
end

function XPokerGuessing2Control:OnRelease()
    self:SetCurrentStageId(nil, nil)
end

function XPokerGuessing2Control:RemoveEnemyCard()
    self._Game:RemoveEnemyCard()
end

function XPokerGuessing2Control:Restart(callback)
    local stageId = self._GameStageId
    if not stageId or stageId == 0 then
        XLog.Error("[XPokerGuessing2Control] 重开失败, stageId:", tostring(stageId))
        return
    end
    XMVCA.XPokerGuessing2:StartNewPokerGuessing2Request(stageId, function(res)
        if not res then
            XLuaUiManager.Close("UiPokerGuessing2Game")
            return
        end
        self:SetCurrentStageId(stageId, 1)
        self._Game:Reset()
        local cards = res.PlayerCards
        self._Game:SetPlayerCards(cards)
        self._Game:SetEnemyCards(cards)
        local maxTipsAmount = self._Model:GetPokerGuessing2ActivityMaxTipsCountById(self._Model:GetActivityId())
        self._Game:SetMaxTipsAmount(maxTipsAmount)
        if callback then
            callback()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_SPEAK, XPokerGuessing2Enum.Speak.RoundStart)
        XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_START_ROUND)
    end)
end

function XPokerGuessing2Control:StartGame()
    local stageId = self._Main.StageId
    XMVCA.XPokerGuessing2:StartNewPokerGuessing2Request(stageId, function(res)
        self:SetCurrentStageId(stageId, 1)
        self._GameStageId = stageId
        self._Game:Reset()
        local cards = res.PlayerCards
        self._Game:SetPlayerCards(cards)
        self._Game:SetEnemyCards(cards)
        local maxTipsAmount = self._Model:GetPokerGuessing2ActivityMaxTipsCountById(self._Model:GetActivityId())
        self._Game:SetMaxTipsAmount(maxTipsAmount)
        XLuaUiManager.Open("UiPokerGuessing2Game")
    end)
end

function XPokerGuessing2Control:GetScore()
    return self._Game:GetScore()
end

function XPokerGuessing2Control:GetStageList()
    if self._StageConfigList then
        return self._StageConfigList
    end
    local stageList = {}
    local activityId = self._Model:GetActivityId()
    local stages = self._Model:GetPokerGuessing2StageConfigs()
    for i, stageConfig in pairs(stages) do
        if stageConfig.ActivityId == activityId then
            stageList[#stageList + 1] = stageConfig
        end
    end
    table.sort(stageList, function(a, b)
        return a.Id < b.Id
    end)
    self._StageConfigList = stageList
    return stageList
end

function XPokerGuessing2Control:GetEnemyCardIndex()
    return self._Main.EnemyCardIndex
end

function XPokerGuessing2Control:PlayFirstTimeStory()
    if XSaveTool.GetData("XPokerGuessing2FirstTimeStory" .. XPlayer.Id) == true then
        return
    end
    local config = self:GetActivityConfig()
    if config then
        local storyId = config.StoryId
        if storyId and storyId ~= "" then
            XDataCenter.MovieManager.PlayMovie(storyId, function()
                XSaveTool.SaveData("XPokerGuessing2FirstTimeStory" .. XPlayer.Id, true)
            end)
        end
    end
end

function XPokerGuessing2Control:SelectDefaultStage()
    local stageList = self:GetStageList()
    local selectStageId = self._Main.StageId
    if selectStageId == 0 then
        -- 找到第一个未通关且可挑战的关卡
        for i = 1, #stageList do
            local stageData = stageList[i]
            local stageId = stageData.Id
            if self._Model:IsStageCanChallenge(stageId) and not self._Model:IsStagePassed(stageId) then
                selectStageId = stageId
                break
            end
        end
        -- 否则选中最后一个可挑战的
        if selectStageId == 0 then
            for i = 1, #stageList do
                local stageData = stageList[i]
                local stageId = stageData.Id
                if self._Model:IsStageCanChallenge(stageId) then
                    selectStageId = stageId
                end
            end
        end
        if selectStageId == 0 then
            if #stageList == 0 then
                XLog.Error("[XPokerGuessing2Control] 关卡列表为空")
            else
                XLog.Error("[XPokerGuessing2Control] 没有一关可挑战?")
                selectStageId = stageList[1].Id
            end
        end
    end
    self._Main.StageId = selectStageId
end

function XPokerGuessing2Control:GetUiMain()
    local data = self._Main

    local stageList = self:GetStageList()
    local selectStageId = self._Main.StageId
    if selectStageId ~= 0 then
        local stageConfig = self._Model:GetPokerGuessing2StageConfigById(selectStageId)
        self._Main.StageId = selectStageId
        self._Main.IsOpen = self._Model:IsStageCanChallenge(selectStageId)
        self._Main.IsPassed = self._Model:IsStagePassed(selectStageId)
        if stageConfig.EffectDesc then
            self._Main.StageDesc = XUiHelper.ReplaceTextNewLine(stageConfig.EffectDesc)
        else
            self._Main.StageDesc = ""
        end
        for i = 1, #stageList do
            if stageList[i].Id == selectStageId then
                self._Main.StageIndex = i
            end
        end

        self._Main.EnemyDialogue = self:RandomSpeak(stageConfig.LineLevel)
    else
        self._Main.StageIndex = 0
        XLog.Error("[XPokerGuessing2Control] 无法找到关卡")
    end
    self._Main.StageMaxIndex = #stageList

    local selectedCharacterId = self._SelectedCharacterId
    if selectedCharacterId == 0 then
        local characters = self._Model:GetAllCharacters()
        if #characters == 0 then
            XLog.Error("[XPokerGuessing2Control] 已解锁角色数量为0")
        else
            self:SetSelectedCharacter(characters[1].Id)
        end
    end
    if selectedCharacterId ~= 0 then
        if XMVCA.XCharacter:GetModelCharacterConfigById(selectedCharacterId) then
            self._Main.Player.Name = XMVCA.XCharacter:GetCharacterName(selectedCharacterId)
            local storyConfig = self._Model:GetStoryConfig(selectedCharacterId)
            self._Main.Player.Icon = storyConfig.Icon
        else
            XLog.Error("[XPokerGuessing2Control] 不存在这个角色:", selectedCharacterId)
        end
    end
    return data
end

function XPokerGuessing2Control:GetDialogue(speak)
    local stageConfig = self:GetStageConfig()
    local characterConfig = self:GetCharacterConfig()
    local enemyText, playerText
    if speak == XPokerGuessing2Enum.Speak.GameWin then
        enemyText = self:RandomSpeak(stageConfig.LineGameLose)
        playerText = self:RandomSpeak(characterConfig.LineGameWin)
    elseif speak == XPokerGuessing2Enum.Speak.GameLose then
        enemyText = self:RandomSpeak(stageConfig.LineGameWin)
        playerText = self:RandomSpeak(characterConfig.LineGameLose)
    elseif speak == XPokerGuessing2Enum.Speak.RoundWin then
        enemyText = self:RandomSpeak(stageConfig.LineRoundLose)
        playerText = self:RandomSpeak(characterConfig.LineRoundWin)
    elseif speak == XPokerGuessing2Enum.Speak.RoundLose then
        enemyText = self:RandomSpeak(stageConfig.LineRoundWin)
        playerText = self:RandomSpeak(characterConfig.LineRoundLose)
    elseif speak == XPokerGuessing2Enum.Speak.RoundDraw then
        enemyText = self:RandomSpeak(stageConfig.LineRoundDraw)
        playerText = self:RandomSpeak(characterConfig.LineRoundDraw)

    elseif speak == XPokerGuessing2Enum.Speak.RoundStart then
        local round = self._Game:GetRound()
        enemyText = stageConfig.LineLevelStart[round]
        playerText = false

        --if isTipsAlways then
        --    playerText = characterConfig.LineLevelStart[round]
        --end
    end
    return {
        Enemy = enemyText,
        Player = playerText,
    }
end

function XPokerGuessing2Control:RandomSpeak(array)
    if #array > 0 then
        local i = math.random(1, #array)
        return array[i]
    end
    return ""
end

function XPokerGuessing2Control:GetActivityConfig()
    local activityId = self._Model:GetActivityId()
    local activityConfig = self._Model:GetPokerGuessing2ActivityConfigById(activityId)
    return activityConfig
end

function XPokerGuessing2Control:UpdateTime()
    local activityConfig = self:GetActivityConfig()
    if activityConfig then
        local timeId = activityConfig.TimeId
        local currentTime = XTime.GetServerNowTimestamp()
        self._Main.Time = math.max(0, XFunctionManager.GetEndTimeByTimeId(timeId) - currentTime)
    end
    if self._Main.Time <= 0 then
        XUiManager.RunMain()
        XUiManager.TipText("ActivityAlreadyClose")
    end
    XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_TIME)
end

function XPokerGuessing2Control:GetUiSelectRole()
    local data = self._SelectCharacter
    ---@class XPokerGuessing2UiCharacter
    local role = {
        Name = "",
        CharacterId = 0,
        Icon = nil,
        Id = 0,
    }
    return data
end

function XPokerGuessing2Control:Confirm()
    if self._Game:IsOver() then
        XLog.Warning("[XPokerGuessing2Control] 游戏已结束")
        return
    end

    local card = self._Game:GetPlayerCard()
    if not card then
        XUiManager.TipText("PokerGuessing2PleaseSelectCard")
        return
    end
    if not card:IsSelected() then
        XUiManager.TipText("PokerGuessing2PleaseSelectCard")
        return
    end
    ---@param res ActionPokerGuessing2Response
    XMVCA.XPokerGuessing2:ActionPokerGuessing2Request(card, function(res)
        self._Game:RemoveCardFromPlayer(card:GetUid())
        self._Main.EnemyCardIndex = self._Game:SetEnemyCardAndRemoveFromList(res.RobotCard)

        if res.GoodList then
            self._Settlement.Rewards = res.GoodList
        else
            if not XTool.IsTableEmpty(self._Settlement.Rewards) then
                self._Settlement.Rewards = {}
            end
        end

        self._Game:SetEnemyScore(res.RobotScore)
        self._Game:SetPlayerScore(res.PlayerScore)

        local state = res.State
        local roundState = res.RoundState

        if state == XPokerGuessing2Enum.State.GameWin
                or state == XPokerGuessing2Enum.State.GameLose
        then
            local isWin = state == XPokerGuessing2Enum.State.GameWin
            self._Settlement.IsWin = isWin
            self._Game:SetIsOver(true)
            if isWin then
                self._Model:SetStagePassed(self._GameStageId)
            end
            self:SetCurrentStageId(nil, nil)
        else
            self._Game:SetRound(self._Game:GetRound() + 1)
            XMVCA.XPokerGuessing2:SetCurrentRound(self._Game:GetRound())
        end
        XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_CONFIRM_RESULT, state, roundState)
        if state == XPokerGuessing2Enum.State.GameWin then
            self:MoveToRightStage()
        end
    end)
end

function XPokerGuessing2Control:UseTips()
    if self._Game:IsOver() then
        XLog.Warning("[XPokerGuessing2Control] 游戏已结束")
        return
    end
    if self._Game:GetTipsAmount() > 0 then
        XMVCA.XPokerGuessing2:UseTips2Request(function(res)
            self._Game:SetTipsAmount(self._Game:GetTipsAmount() - 1)
            self._Game:SetTipsCard(res.RobotCard)
            XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_TIPS)
        end)
    else
        XUiManager.TipText("PokerGuessing2HelpOver")
    end
end

function XPokerGuessing2Control:GetTipsAmount()
    local tipsAmount = self._Game:GetTipsAmount()
    local maxTipsAmount = self._Game:GetMaxTipsAmount()
    return tipsAmount, maxTipsAmount
end

function XPokerGuessing2Control:GetTipsCardSpeak()
    local tipsCard = self._Game:GetTipsCard()
    if tipsCard and not tipsCard:IsEmpty() then
        local characterConfig = self._Model:GetPokerGuessing2CharacterConfig(self._SelectedCharacterId)
        if characterConfig then
            local text = string.format(characterConfig.LineTips, tipsCard:GetName(self._Model))
            return text
        end
    end
end

function XPokerGuessing2Control:GetEnemy()
    local cardData
    local enemyCard = self._Game:GetEnemyCard()
    if enemyCard and not enemyCard:IsEmpty() then
        cardData = enemyCard:GetUiData(self._Model)
    end

    local enemyCards = self._Game:GetEnemyCards()
    local cards = {}
    for i = 1, #enemyCards do
        cards[i] = enemyCards[i]:GetUiData(self._Model)
    end

    local previewCards = {}
    for i = 1, #enemyCards do
        previewCards[i] = enemyCards[i]:GetUiData(self._Model, true)
    end

    local stageConfig = self:GetStageConfig()
    ---@class XUiPokerGuessing2CharacterData
    local enemy = {
        Name = stageConfig.NpcName,
        Icon = stageConfig.Icon,
        Card = cardData,
        Cards = cards,
        PreviewCards = previewCards,
        TimeId = stageConfig.TimeId,
        IsLock = not self._Model:IsStageCanChallenge(self._Main.StageId),
        IsLock4Time = not self._Model:IsStageOnTime(self._Main.StageId),
    }
    self._Main.Enemy = enemy
    return enemy
end

function XPokerGuessing2Control:GetPlayer()
    local cardData
    local playerCard = self._Game:GetPlayerCard()
    if not playerCard:IsEmpty() then
        cardData = playerCard:GetUiData(self._Model)
    end
    local playerCards = self._Game:GetPlayerCards()
    local cards = {}
    for i = 1, #playerCards do
        cards[i] = playerCards[i]:GetUiData(self._Model)
    end
    if XMVCA.XCharacter:GetModelCharacterConfigById(self._SelectedCharacterId) then
        local character = self:GetCharacterConfig()
        local player = {
            Name = XMVCA.XCharacter:GetCharacterName(self._SelectedCharacterId),
            Icon = character.Icon,
            Card = cardData,
            Cards = cards
        }
        self._Main.Player = player
    end
    return self._Main.Player
end

function XPokerGuessing2Control:GetStageConfig()
    return self._Model:GetPokerGuessing2StageConfigById(self._Main.StageId)
end

function XPokerGuessing2Control:GetCharacterConfig()
    return self._Model:GetPokerGuessing2CharacterConfig(self._SelectedCharacterId)
end

---@param data XUiPokerGuessing2CardData
function XPokerGuessing2Control:SetSelectedCard(data)
    if not data then
        self._Game:SetPlayerCard(nil)
        return
    end
    self._Game:SetPlayerCard(data.Uid)
end

---@param data XUiPokerGuessing2CardData
function XPokerGuessing2Control:IsSelectedCard(data)
    if data then
        ---@type XPokerGuessing2Card
        local playerCard = self._Game:GetPlayerCard()
        if playerCard and not playerCard:IsEmpty() then
            return playerCard:GetUid() == data.Uid
        end
    end
    return false
end

function XPokerGuessing2Control:SetSelectedCharacter(id)
    local characterConfig = self._Model:GetPokerGuessing2CharacterConfig(id)
    if characterConfig then
        self._SelectedCharacterId = id
        XSaveTool.SaveData("PokerGuessing2CharacterId" .. XPlayer.Id, id)
    end
end

function XPokerGuessing2Control:GetTime()
    return self._Main.Time
end

function XPokerGuessing2Control:GetRewards()
    local stageConfig = self:GetStageConfig()
    local rewards = XRewardManager.GetRewardList(stageConfig.RewardId)
    return rewards
end

function XPokerGuessing2Control:GetStageCards()
    local stageConfig = self:GetStageConfig()
    local icons = stageConfig.CardIcon
    local cards = {}
    for i = 1, #icons do
        local data = {
            Icon = icons[i],
        }
        table.insert(cards, data)
    end
    return cards
end

function XPokerGuessing2Control:MoveToLeftStage()
    local stageIndex = self._Main.StageIndex
    local stageList = self:GetStageList()
    if stageIndex > 1 then
        local stageConfig = stageList[stageIndex - 1]
        self._Main.StageId = stageConfig.Id
        self._Main.StageIndex = stageIndex - 1
    end
end

function XPokerGuessing2Control:MoveToRightStage()
    local stageIndex = self._Main.StageIndex
    local stageList = self:GetStageList()
    if stageIndex < #stageList then
        local stageConfig = stageList[stageIndex + 1]
        self._Main.StageId = stageConfig.Id
        self._Main.StageIndex = stageIndex + 1
    end
end

function XPokerGuessing2Control:GetSelectedCharacterId()
    return self._SelectedCharacterId
end

function XPokerGuessing2Control:GetCharacterList()
    local characters = self._Model:GetAllCharacters()
    local list = {}
    for i = 1, #characters do
        local character = characters[i]
        if XMVCA.XCharacter:GetModelCharacterConfigById(character.Id) then
            local isUse = self._SelectedCharacterId == character.Id
            ---@class XUiPokerGuessing2PopupSelectRoleGridData
            local data = {
                Id = character.Id,
                Icon = character.CircularIcon,
                Name = XMVCA.XCharacter:GetCharacterName(character.Id),
                IsUse = isUse,
                IsSelected = isUse
            }
            table.insert(list, data)
        end
    end
    return list
end

function XPokerGuessing2Control:GetTaskGroupIds()
    local activityConfig = self:GetActivityConfig()
    return activityConfig.TaskGroupId
end

function XPokerGuessing2Control:GetActivityEndTime()
    local activityConfig = self:GetActivityConfig()
    return XFunctionManager.GetEndTimeByTimeId(activityConfig.TimeId)
end

function XPokerGuessing2Control:GetActivityTimerId()
    local activityConfig = self:GetActivityConfig()
    return activityConfig.TimeId
end

function XPokerGuessing2Control:GetRound()
    return self._Game:GetRound()
end

function XPokerGuessing2Control:IsGameOver()
    return self._Game:IsOver()
end

function XPokerGuessing2Control:GetSettlement()
    local settlement = self._Settlement
    settlement.Round = self._Game:GetRound()
    return settlement
end

---@param data XUiPokerGuessing2StoryGridData
function XPokerGuessing2Control:PlayStory(data)
    XSaveTool.SaveData("PokerGuessing2StoryPlayed" .. XPlayer.Id .. data.StoryId, true)
    XDataCenter.MovieManager.PlayMovie(data.StoryId)
end

---@param data XUiPokerGuessing2StoryGridData
function XPokerGuessing2Control:UnlockStory(data)
    local itemAmount = XDataCenter.ItemManager.GetCount(data.TicketId)
    if itemAmount < data.TicketCost then
        XUiManager.TipText("PokerGuessing2StoryInviteNoEnoughTicket")
        return
    end
    local sureCallback = function()
        XMVCA.XPokerGuessing2:UnlockStoryPokerGuessing2Request(data.Id, function()
            self._Model:SetStoryUnlock(data.Id)
            XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_STORY)
            self:PlayStory(data)
        end)
    end

    local key = "XPokerGuessing2Invite" .. XPlayer.Id
    local updateTime = XSaveTool.GetData(key)
    local isShowToday = false
    if updateTime then
        isShowToday = XTime.GetServerNowTimestamp() < updateTime
    end
    if isShowToday then
        sureCallback()
        return
    end
    local title = XUiHelper.GetText("PokerGuessing2StoryInviteTitle")
    local content = XUiHelper.GetText("PokerGuessing2StoryInviteContent")
    local content2 = ""
    local closeCallback = nil
    local hintInfo = {
        SetHintCb = function(isSelect)
            if not isSelect then
                XSaveTool.RemoveData(key)
            else
                XSaveTool.SaveData(key, XTime.GetSeverTomorrowFreshTime())
            end
        end,
        Status = isShowToday
    }
    XUiManager.DialogHintTip(title, content, content2, closeCallback, sureCallback, hintInfo)
end

function XPokerGuessing2Control:GetStoryList()
    local configs = self._Model:GetPokerGuessing2StoryConfigs()
    local list = {}
    for id, config in pairs(configs) do
        local storyId = config.StoryId
        local characterId = config.CharacterId
        local name = XMVCA.XCharacter:GetCharacterName(characterId)
        ---@class XUiPokerGuessing2StoryGridData
        local data = {
            Id = config.Id,
            Name = name,
            Icon = config.Icon,
            IsUnlock = self._Model:IsStoryUnlock(config.Id),
            StoryId = storyId,
            TicketId = config.UnlockItemId,
            TicketCost = config.Cost,
            IsPlayed = XSaveTool.GetData("PokerGuessing2StoryPlayed" .. XPlayer.Id .. storyId) or false
        }
        table.insert(list, data)
    end
    table.sort(list, function(a, b)
        return a.Id < b.Id
    end)
    return list
end

function XPokerGuessing2Control:IsStageOnTime()
    local stageId = self._Main.StageId
    return self._Model:IsStageOnTime(stageId)
end

function XPokerGuessing2Control:IsPreStagePassed()
    local stageId = self._Main.StageId
    return self._Model:IsPreStagePassed(stageId)
end

function XPokerGuessing2Control:SetCurrentStageId(stageId, round)
    XMVCA.XPokerGuessing2:SetCurrentStageId(stageId)
    XMVCA.XPokerGuessing2:SetCurrentRound(round)
end

return XPokerGuessing2Control