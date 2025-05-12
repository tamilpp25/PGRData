local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantGame = require("XModule/XLuckyTenant/Game/XLuckyTenantGame")
local GameState = XLuckyTenantEnum.GameState

---@class XLuckyTenantControl : XControl
---@field private _Model XLuckyTenantModel
local XLuckyTenantControl = XClass(XControl, "XLuckyTenantControl")

function XLuckyTenantControl:OnInit()
    ---@type XLuckyTenantGame
    self._Game = false

    self._UiData = {
        HelpKey = self._Model:GetHelpKey(),
        GameState = 0,
        Round = 0,
        Score = 0,
        AddScore = 0,
        QuestCompletedAmount = 0,
        QuestTotalAmount = 0,
        QuestDesc = "",
        PiecesAmount = 0,
        Chessboard = {},
        StageName = "",

        ---@type XLuckyTenantAnimationGroup[]
        AnimationGroups = false,

        IsDirty = false,
        IsNormalClear = false,
        SelectPiecesData = {
            Pieces = {},
        },
        ---@type XUiLuckyTenantChessBagGroupData[]
        Bag = {},
        ---@type XUiLuckyTenantChessBagGridData
        SelectedBagPiece = false,
        IsBagDirty = false,
        IsPropDirty = false,
        Prop = {},
        DeletePiece = {
            Desc = "",
            Piece = false
        },
        QuestRewards = {},
        Settlement = {
            Score = 0,
            QuestTotalAmount = 0,
            QuestCompletedAmount = 0,
            Round = 0,
            IsPerfectClear = false,
            IsFail = false,
            IsNormalClear = false,
            IsNewRecord = false,
        },
        IsShowDeleteOption = false,
        FreeRefreshTimes = 0,
        RemainTime = 0,
        ---@type XUiLuckyTenantMainStageGridData[]
        Stages = {},
        StageDetail = {
            Id = 0,
            Name = "",
            BestScore = 0,
            BestRound = 0,
            IsMax = false,
            RoundsToPerfectClear = 0,
            QuestAmount = 0,
            Desc = "",
            ---@type XUiLuckyTenantChessGridData[]
            Pieces = {},
            IsPlaying = false,
            IsChallengeStage = false,
        },
        Tag = {},
        Icon4Animation = {},
    }

    local XLuckyTenantPiece = require("XModule/XLuckyTenant/Game/XLuckyTenantPiece")
    ---@type XLuckyTenantPiece
    self._TempPiece = XLuckyTenantPiece.New()
end

function XLuckyTenantControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    self:UpdateActivityTimeLeft()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateActivityTimeLeft()
        self:CheckInTime()
    end, XScheduleManager.SECOND)
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT_SET_TEST_CASE, self._SetTestCase, self)
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT_CLEAR_BAG, self._TestClearBag, self)
end

function XLuckyTenantControl:RemoveAgencyEvent()
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT_SET_TEST_CASE, self._SetTestCase, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT_CLEAR_BAG, self._TestClearBag, self)
end

function XLuckyTenantControl:OnRelease()
    self._Game = false
end

function XLuckyTenantControl:ClearGame()
    self._Game = false
    self._UiData.SelectPiecesData.Pieces = {}
    self._UiData.SelectedBagPiece = false
    XMVCA.XLuckyTenant:Print("清空游戏")
end

function XLuckyTenantControl:StartGame(stageId, seed, isFirstTimeEntering, record)
    XMVCA.XLuckyTenant:Print("游戏开始", stageId)
    self:SetStageHasPlayed(stageId)
    self._Game = XLuckyTenantGame.New()
    local isResumeGame = false
    if record then
        if record.Bag and next(record.Bag) then
            isResumeGame = true
        else
            XMVCA.XLuckyTenant:Print("恢复游戏，但是背包为空，在第一回合还没开始的阶段就退出了游戏，重新开始整局游戏")
        end
    end
    self._Game:Init(self._Model, stageId, seed, isFirstTimeEntering, isResumeGame)
    if record then
        self._Game:Resume(self._Model, record)
    end
    if not record or not record.ChessBoard then
        self._Game:ResetChessBoard(self._Model)
    end

    local stageConfig = self._Model:GetLuckyTenantStageConfigById(stageId)
    if stageConfig.ShowDeleteOption then
        self._UiData.IsShowDeleteOption = true
    else
        self._UiData.IsShowDeleteOption = false
    end

    self:UpdateUiData(true)
    -- 第一次看到棋盘，不显示回合数
    if self._Game:GetRound() == 1 then
        for i = 1, #self._UiData.Chessboard do
            local data = self._UiData.Chessboard[i]
            data.Round = false
        end
    end
    for i = 1, #self._UiData.Chessboard do
        local pieceData = self._UiData.Chessboard[i]
        if pieceData.Round and pieceData.RoundInFact then
            if pieceData.RoundInFact > pieceData.Round then
                pieceData.Round = false
            end
        end
    end
end

function XLuckyTenantControl:UpdateChessboardSize(amount)
    local dataChessboard = self._UiData.Chessboard
    if amount ~= #self._UiData.Chessboard then
        for i = amount + 1, #dataChessboard do
            dataChessboard[i] = nil
        end
        for i = 1, amount do
            if dataChessboard[i] == nil then
                dataChessboard[i] = {}
            end
        end
    end
end

function XLuckyTenantControl:UpdateGameState()
    local state = self._Game:GetState()
    if state ~= self._UiData.GameState then
        self._UiData.GameState = state
        self._UiData.IsDirty = true
        self:UpdateInfo()
    end
end

function XLuckyTenantControl:NextGameState()
    self._Game:NextState(self._Model)
    self:UpdateGameState()
end

function XLuckyTenantControl:Roll()
    local animationGroups = {}
    self._Game:ResetChessBoard(self._Model)
    self._UiData.AnimationGroups = animationGroups
    -- 保存开始roll之前的棋盘
    self:UpdateUiData(false)
    self:UpdateIcon4Animation()
    self._Game:CalculateScore(self._Model, animationGroups)
    self:InsertRollAnimation(animationGroups)
    self:NextGameState()
    XMVCA.XLuckyTenant:RequestUpdateScore(self._Game)
end

-- 等待x秒, 播放roll动画, 并在播放结束后更新棋盘
function XLuckyTenantControl:InsertRollAnimation(animationGroups)
    local XLuckyTenantAnimationGroup = require("XModule/XLuckyTenant/Game/Animation/XLuckyTenantAnimationGroup")
    ---@type XLuckyTenantAnimationGroup
    local animationGroup = XLuckyTenantAnimationGroup.New()
    table.insert(animationGroups, 1, animationGroup)
    -- notice:这不是按照插入顺序播放的，是按照枚举大小播放的
    animationGroup:SetAnimation({
        Type = XLuckyTenantEnum.Animation.PlayRollAnimation,
    })
    animationGroup:SetAnimation({
        Type = XLuckyTenantEnum.Animation.Wait,
        Duration = 2.19 --130帧
    })
    animationGroup:SetAnimation({
        Type = XLuckyTenantEnum.Animation.UpdateChessboard,
    })
end

function XLuckyTenantControl:SetUiDataDirty(isDirty)
    local uiData = self._UiData
    uiData.IsDirty = isDirty
    uiData.IsBagDirty = isDirty
    uiData.IsPropDirty = isDirty
end

function XLuckyTenantControl:UpdateUiData(isDirty)
    local game = self._Game
    local uiData = self._UiData
    self:UpdateGameState()
    self:SetUiDataDirty(isDirty)

    local chessboard = game:GetChessboard()
    local pieces = chessboard:GetPieces()
    self:UpdateChessboardSize(#pieces)

    uiData.Score = game:GetTotalScore()
    uiData.AddScore = game:GetScoreThisRound()
    XMVCA.XLuckyTenant:Print("获得分数:", uiData.AddScore)
    self:UpdateChessboard()
    self:UpdateInfo()
end

function XLuckyTenantControl:UpdateInfo()
    local game = self._Game
    local uiData = self._UiData
    uiData.Round = game:GetRound()
    local questCompletedAmount, questTotalAmount = game:GetQuestProgress()
    uiData.QuestCompletedAmount = questCompletedAmount
    uiData.QuestTotalAmount = questTotalAmount
    uiData.IsNormalClear = game:IsNormalClear()

    self:UpdateBagAmount()
    uiData.AddScore = 0
    self:UpdateQuest()
end

function XLuckyTenantControl:UpdateBagAmount()
    local game = self._Game
    local uiData = self._UiData
    uiData.PiecesAmount = game:GetBag():GetPiecesAmount()
end

function XLuckyTenantControl:UpdateSelectPiece()
    local game = self._Game
    local pieces = game:GetOptionsThisRound(self._Model)
    local pieceData = self._UiData.SelectPiecesData.Pieces
    if #pieceData ~= #pieces then
        pieceData = {}
        self._UiData.SelectPiecesData.Pieces = pieceData
    end
    for i = 1, #pieces do
        local piece = pieces[i]
        ---@class XUiLuckyTenantChessGridData
        local data = pieceData[i]
        if not data then
            data = {}
            pieceData[i] = data
        end
        data.Id = piece:GetId()
        data.Name = piece:GetName()
        data.TypeName = self._Model:GetLuckyTenantChessTypeNameById(piece:GetPieceType())
        data.Amount = piece:GetAmount()
        data.Icon = piece:GetIcon()
        data.Value = piece:GetValue()
        data.ValueUponDeletion = piece:GetValueUponDeletion()
        data.Desc = piece:GetDesc(self._Model)
        local quality = piece:GetQuality()
        data.Quality = self._Model:GetQualityIconQuad(quality)
        data.QualityValue = quality
        data.Index = i
        data.IsCanDelete = piece:IsCanDelete()
        data.Tag = self:GetPieceTag(piece)
    end
    self._UiData.FreeRefreshTimes = game:GetFreeRefreshTimes()
end

function XLuckyTenantControl:UpdateChessboard()
    local game = self._Game
    local uiData = self._UiData
    local chessboard = game:GetChessboard()
    local pieces = chessboard:GetPieces()
    local dataChessboard = uiData.Chessboard
    for i = 1, #pieces do
        local piece = pieces[i]
        ---@class XUiLuckyTenantGameGridData
        local data = dataChessboard[i]
        local x, y = chessboard:GetXY(i)
        if piece then
            piece:GetUiData(self._Model, game, data)
            data.Desc = piece:GetDesc(self._Model)
            if XMain.IsEditorDebug then
                local x2, y2 = piece:GetPosition()
                if x2 ~= x or y2 ~= y then
                    XLog.Error("[XLuckyTenantControl] position和index计算错误:" .. piece:GetUid() .. piece:GetName() .. string.format("(%s,%s)", x, y) .. string.format("(%s,%s)", x2, y2))
                end
            end
        else
            data.Icon = false
            data.Uid = 0
            data.IsValid = false
        end
        data.X = x
        data.Y = y
        data.Position = i
    end
end

function XLuckyTenantControl:StopGame()
    self._Game = false
end

function XLuckyTenantControl:GetActivityEndTime()
    local config = self._Model:GetActivityConfig()
    if not config then
        return 0
    end
    local timeId = config.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    return endTime
end

function XLuckyTenantControl:UpdateActivityTimeLeft()
    local config = self._Model:GetActivityConfig()
    if not config then
        return
    end
    local timeId = config.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = endTime - currentTime
    remainTime = math.max(0, remainTime)
    self._UiData.RemainTime = remainTime
end

function XLuckyTenantControl:CheckInTime()
    if self._UiData.RemainTime <= 0 then
        XUiManager.TipText("ActivityMainLineEnd")
        XLuaUiManager.RunMain()
    end
end

--region 玩家可以做的操作
function XLuckyTenantControl:SelectPiece(index)
    if XMVCA.XLuckyTenant:IsRequesting() then
        return
    end
    self._Game:SelectPiece(self._Model, index)
    self:UpdateGameState()
    XLuaUiManager.Close("UiLuckyTenantChess")
    self._UiData.IsBagDirty = true
    XMVCA.XLuckyTenant:RequestNextRound(self._Game)
end

function XLuckyTenantControl:DeletePiece(uid)
    self._Game:DeletePieceByUid(uid)
end

function XLuckyTenantControl:ResetChessboard()
    self._Game:ResetChessBoard(self._Model)
end
--endregion 玩家可以做的操作

function XLuckyTenantControl:GetUiData()
    return self._UiData
end

---@param pieceData1 XUiLuckyTenantChessBagGridData
---@param pieceData2 XUiLuckyTenantChessBagGridData
local function SortPieces(pieceData1, pieceData2)
    if pieceData1.QualityValue ~= pieceData2.QualityValue then
        return pieceData1.QualityValue > pieceData2.QualityValue
    end
    return pieceData1.Id < pieceData2.Id
end

local function SortPieceType(type1, type2)
    return type1.Type < type2.Type
end

function XLuckyTenantControl:UpdateBag()
    -- 每次更新, 都清空选中, 防止残留
    if not self._UiData.IsBagDirty then
        return
    end
    local selectedPieceLastTime = self._UiData.SelectedBagPiece
    if selectedPieceLastTime then
        if not self._Game:GetBag():GetPiece(selectedPieceLastTime.Uid) then
            self._UiData.SelectedBagPiece = false
        end
    end

    self._UiData.IsBagDirty = false
    local uiData = self._UiData.Bag
    for i = #uiData, 1, -1 do
        uiData[i] = nil
    end
    local game = self._Game
    local bag = self._Game:GetBag()
    local pieces = bag:GetPieces()
    local dictionary = {}
    for i, piece in pairs(pieces) do
        local type = piece:GetPieceType()
        local array = dictionary[type]
        if not array then
            array = {}
            dictionary[type] = array
        end
        array[#array + 1] = piece
    end

    local currentTurns = game:GetRound()
    for type, piecesClassified in pairs(dictionary) do
        local piecesData = {}
        for i = 1, #piecesClassified do

            ---@type XLuckyTenantPiece
            local piece = piecesClassified[i]
            local round = piece:GetSkillEffectRemainingTurns(self._Model, currentTurns)
            ---@class XUiLuckyTenantChessBagGridData
            local pieceData = {
                Name = piece:GetName(),
                Icon = piece:GetIcon(),
                Value = piece:GetValue(),
                Desc = piece:GetDesc(self._Model),
                Quality = self._Model:GetQualityIconQuad(piece:GetQuality()),
                QualityValue = piece:GetQuality(),
                IsCanDelete = piece:IsCanDelete(),
                Uid = piece:GetUid(),
                Id = piece:GetId(),
                Round = round,
                IsDirty = true,
                IsSelected = false,
                ValueUponDeletion = piece:GetValueUponDeletion(),
                TypeName = self._Model:GetLuckyTenantChessTypeNameById(piece:GetPieceType()),
                Tag = self:GetPieceTag(piece)
            }
            piecesData[#piecesData + 1] = pieceData
        end
        table.sort(piecesData, SortPieces)
        local desc = self._Model:GetLuckyTenantChessTypeDescById(type)
        ---@class XUiLuckyTenantChessBagGroupData
        local data = {
            Type = type,
            TypeDesc = desc or "",
            ---@type XUiLuckyTenantChessBagGridData[]
            Pieces = piecesData,
        }
        uiData[#uiData + 1] = data
    end
    table.sort(uiData, SortPieceType)
    self._UiData.PiecesAmount = game:GetBag():GetPiecesAmount()
end

---@param data XUiLuckyTenantChessBagGridData
function XLuckyTenantControl:SelectBagPiece(data)
    if self._UiData.SelectedBagPiece then
        self._UiData.SelectedBagPiece.IsSelected = false
    end
    if not data then
        self._UiData.SelectedBagPiece = false
        return
    end
    data.IsSelected = true
    self._UiData.SelectedBagPiece = data
end

function XLuckyTenantControl:UpdateProp()
    if not self._UiData.IsPropDirty then
        return
    end
    self._UiData.IsPropDirty = false
    self:UpdatePropByIndex(1, XLuckyTenantEnum.Item.DeleteProp, XLuckyTenantEnum.PropId.DeleteProp)
    self:UpdatePropByIndex(2, XLuckyTenantEnum.Item.RefreshProp, XLuckyTenantEnum.PropId.RefreshProp)
end

function XLuckyTenantControl:UpdatePropByIndex(index, itemType, itemId)
    local bag = self._Game:GetBag()
    ---@class XUiLuckyTenantChessBagPropData
    local data = self._UiData.Prop[index]
    if not data then
        data = {
            Amount = 0,
            Icon = "",
            PieceId = 0,
            Desc = "",
        }
        self._UiData.Prop[index] = data
    end
    data.PieceId = itemId
    data.Amount = bag:GetPropAmount(itemType)
    data.Icon = self._Model:GetLuckyTenantChessIconById(itemId)
    data.Desc = self._Model:GetLuckyTenantChessDescById(itemId)[1]
end

function XLuckyTenantControl:DeletePieceSelectedOnBagUi()
    if XMVCA.XLuckyTenant:IsRequesting() then
        return
    end
    local pieceData = self._UiData.SelectedBagPiece
    if not pieceData then
        XLog.Error("[XLuckyTenantControl] 找不到选中要删除的棋子")
        return
    end
    if pieceData.IsCanDelete == 0 then
        XUiManager.TipText("LuckyTenantDeleteDenied")
        return
    end
    local uid = pieceData.Uid
    local bag = self._Game:GetBag()
    local piece = bag:GetPiece(uid)
    if not piece then
        XLog.Error("[XLuckyTenantControl] 找不到要删除的棋子")
        return
    end
    local props
    local isRequestNextRound = false
    if self._Game:GetState() == XLuckyTenantEnum.GameState.SelectPiece then
        -- 选棋可以免费删一个
        self._Game:SetHasSelectOrDelete(true)
        self._Game:NextState(self._Model)
        self:UpdateGameState()
        XLuaUiManager.Close("UiLuckyTenantDeleteDetail")
        XLuaUiManager.Close("UiLuckyTenantChess")
        isRequestNextRound = true
    else
        --需要道具
        local deletePropAmount = bag:GetPropAmount(XLuckyTenantEnum.Item.DeleteProp)
        if deletePropAmount <= 0 then
            XLog.Error("[XLuckyTenantControl] 删除道具数量不足")
            XUiManager.TipText("LuckyTenantPropNotEnough")
            return
        end
        bag:ReducePropAmount(XLuckyTenantEnum.Item.DeleteProp)
        props = { bag:GetProp(XLuckyTenantEnum.Item.DeleteProp) }
        XMVCA.XLuckyTenant:RequestDeleteOrUpdateChess(self._Game, {
            piece,
        }, props)
    end
    XLuaUiManager.Close("UiLuckyTenantDeleteDetail")
    self._Game:DeletePieceByUid(uid, true)
    if isRequestNextRound then
        XMVCA.XLuckyTenant:RequestNextRound(self._Game)
    end
    self._UiData.IsPropDirty = true
    self._UiData.IsBagDirty = true
    self._UiData.SelectedBagPiece = false
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_UPDATE_BAG)
end

function XLuckyTenantControl:RefreshSelectPiece(useProp)
    self._UiData.IsPropDirty = true
    self._Game:RefreshOptions(self._Model)
    self:UpdateSelectPiece()
    XMVCA.XLuckyTenant:RequestSupplyPieces(self._Game, useProp)
end

function XLuckyTenantControl:RefreshSelectPiecesByProp()
    local game = self._Game
    if game:GetFreeRefreshTimes() > 0 then
        game:ReduceFreeRefreshTimes()
        self:RefreshSelectPiece()
        return true
    end

    local bag = game:GetBag()
    local amount = bag:GetPropAmount(XLuckyTenantEnum.Item.RefreshProp)
    if amount > 0 then
        bag:ReducePropAmount(XLuckyTenantEnum.Item.RefreshProp)
        self:RefreshSelectPiece(true)
        return true
    end
    XMVCA.XLuckyTenant:Print("[XLuckyTenantControl] 刷新道具数量不足")
    XUiManager.TipText("LuckyTenantPropNotEnough")
    return false
end

function XLuckyTenantControl:UpdateDeletePieceDetail()
    local pieceToDelete = self._UiData.SelectedBagPiece
    if pieceToDelete then
        pieceToDelete.IsValid = true
        self._UiData.DeletePiece.Piece = pieceToDelete
        self._UiData.DeletePiece.Desc = pieceToDelete.Name
    end
end

function XLuckyTenantControl:UpdateQuest()
    local game = self._Game
    local quest = game:GetCurrentQuest()
    local uiData = self._UiData
    if not quest then
        uiData.QuestRewards = {}
        uiData.QuestDesc = ""
        return
    end
    uiData.QuestDesc = quest.Desc
    local questRewards = self._UiData.QuestRewards
    local rewardPieces = quest.RewardPieces
    if #questRewards ~= #rewardPieces then
        for i = #questRewards, 1, -1 do
            questRewards[i] = nil
        end
    end
    local rewardAmount = quest.RewardPiecesAmount
    for i = 1, #rewardPieces do
        local pieceId = rewardPieces[i]
        local amount = rewardAmount[i] or 1
        local data = questRewards[i]
        if not data then
            data = {
                Icon = "",
                Amount = 0,
                Desc = ""
            }
            questRewards[i] = data
        end
        data.Icon = self._Model:GetLuckyTenantChessIconById(pieceId)
        data.Amount = amount
        data.Icon = self._Model:GetLuckyTenantChessIconById(pieceId)
        data.Desc = self._Model:GetLuckyTenantChessDescById(pieceId)[1]
    end
end

function XLuckyTenantControl:UpdateSettlement()
    local settlement = self._UiData.Settlement
    local game = self._Game
    settlement.Round = game:GetRound()
    settlement.Score = game:GetTotalScore()
    local questCompletedAmount, questTotalAmount = game:GetQuestProgress()
    settlement.QuestCompletedAmount = questCompletedAmount
    settlement.QuestTotalAmount = questTotalAmount
    settlement.IsPerfectClear = game:IsPerfectClear()
    settlement.IsFail = game:IsGameOver()
    settlement.IsNormalClear = game:IsNormalClear()
    local record = self._Model:GetStageRecord(game:GetStageId())
    settlement.IsNewRecord = record.IsNewRecord
    XMVCA.XLuckyTenant:Print("创造了新纪录吗？", tostring(settlement.IsNewRecord))
end

function XLuckyTenantControl:_SetTestCase(id)
    id = tonumber(id)
    if id == 0 then
        self._Game:RemoveTestCase()
        XLog.Error("[XLuckyTenantControl] 移除测试用例")
        return
    end
    if not id then
        XLog.Error("[XLuckyTenantControl] id错误")
        return
    end
    local testCase = self._Model:GetTestCase(id)
    if not testCase then
        XLog.Error("[XLuckyTenantControl] 找不到用例配置")
        return
    end
    self._Game:SetTestCase(testCase)
    XLog.Error("[XLuckyTenantControl] 作弊成功")
end

function XLuckyTenantControl:_TestClearBag()
    local bag = self._Game:GetBag()
    local pieces = bag:GetPieces()
    local toDelete = {}
    for i, piece in pairs(pieces) do
        toDelete[#toDelete + 1] = piece:GetUid()
    end
    for i = 1, #toDelete do
        self:DeletePiece(toDelete[i])
    end
end

function XLuckyTenantControl:UpdateStageList()
    self._UiData.Stages = {}
    local stages = self._UiData.Stages
    ---@type XTable.XTableLuckyTenantStage[]
    local configs = self._Model:GetStages()
    for i = 1, #configs do
        local config = configs[i]
        local id = config.Id
        local record = self._Model:GetStageRecord(id)
        local bestScore = 0
        local bestRound = 0
        if record then
            bestScore = record.Score
            bestRound = record.Round
        end

        local roundsToNormalClear, scoreToNormalClear = self._Model:GetRoundsToNormalClear(id)
        local roundsToPerfectClear, scoreToPerfectClear = self._Model:GetRoundsToPerfectClear(id)
        local isClear = self._Model:IsStagePassed(id)
        local isNormalClear = bestRound >= roundsToNormalClear and bestScore >= scoreToNormalClear and isClear
        local isPerfectClear = bestRound >= roundsToPerfectClear and bestScore >= scoreToPerfectClear and isClear
        local isPlaying = false
        local playingRound = false
        local playingStageId = self._Model:GetPlayingStageId()
        local isOtherStagePlaying = false
        if playingStageId and playingStageId > 0 then
            if playingStageId == id then
                isPlaying = true
                playingRound = self._Model:GetPlayingStageRound() or 0
            else
                isOtherStagePlaying = true
            end
        end
        local isNew = false
        local key = XMVCA.XLuckyTenant:GetKeyHasPlayed(id)
        if XSaveTool.GetData(key) == nil then
            isNew = true
        end

        local isOnTime = true
        local timeId = config.TimeId
        if timeId > 0 then
            if not XFunctionManager.CheckInTimeByTimeId(timeId) then
                isOnTime = false
            end
        end
        local isPreStagePass = true
        local preStageId = config.PreStage
        if preStageId and preStageId > 0 then
            if not self._Model:IsStagePassed(preStageId) then
                isPreStagePass = false
            end
        end
        local isCanChallenge = isOnTime and isPreStagePass

        ---@class XUiLuckyTenantMainStageGridData
        local stage = {
            Id = id,
            Name = config.Name,
            BesScore = bestScore,
            BestRound = bestRound,
            IsPerfectClear = isPerfectClear,
            IsNormalClear = isNormalClear,
            PlayingRound = playingRound,
            IsNew = isNew and isCanChallenge,
            IsCanChallenge = isCanChallenge,
            IsOnTime = isOnTime,
            IsPreStagePass = isPreStagePass,
            IsPlaying = isPlaying,
            IsSelected = false,
            IsOtherStagePlaying = isOtherStagePlaying,
            TimeId = timeId,
            IsChallengeStage = config.IsChallenge,
            CoverImage = config.CoverImage,
        }
        stages[i] = stage
    end
    table.sort(stages, function(a, b)
        return a.Id < b.Id
    end)
end

function XLuckyTenantControl:SetStageHasPlayed(stageId)
    local key = XMVCA.XLuckyTenant:GetKeyHasPlayed(stageId)
    XSaveTool.SaveData(key, true)
end

---@param data XUiLuckyTenantMainStageGridData
function XLuckyTenantControl:GiveUpPlayingRecord(data)
    if not data then
        return
    end
    local playingStageId = self._Model:GetPlayingStageId()
    if not playingStageId then
        return false
    end
    XLuaUiManager.Open("UiLuckyTenantOverDetail", XLuckyTenantEnum.OverDetailUi.Over)
end

function XLuckyTenantControl:OpenGameUi(data)
    if self._Game then
        XLog.Error("[XLuckyTenantControl] 已经有一场游戏正在进行中")
        return
    end

    local isFirstTimeEntering = true
    if self._Model:IsStagePassed(data.Id) then
        isFirstTimeEntering = false
    end
    XMVCA.XLuckyTenant:RequestStart(data.Id, function(record)
        self._UiData.StageName = data.Name
        XMVCA.XLuckyTenant:SetPlaying(true)
        XLuaUiManager.Open("UiLuckyTenantGame", data.Id, nil, isFirstTimeEntering, record)
    end)
end

function XLuckyTenantControl:UpdateStageDetail(stageId)
    local data = self._UiData.StageDetail
    local bestScore = 0
    local bestRound = 0
    local record = self._Model:GetStageRecord(stageId)
    if record then
        bestScore = record.Score
        bestRound = record.Round
    end
    data.BestScore = bestScore
    data.BestRound = bestRound
    local roundsToPerfectClear = self._Model:GetRoundsToPerfectClear(stageId)
    data.IsMax = bestRound == roundsToPerfectClear
    data.IsPlaying = self._Model:GetPlayingStageId() == stageId
    if data.Id == stageId then
        return
    end

    ---@type XTable.XTableLuckyTenantStage
    local stageConfig = self._Model:GetLuckyTenantStageConfigById(stageId)
    data.RoundsToPerfectClear = roundsToPerfectClear
    data.QuestAmount = self._Model:GetQuestAmount(stageId)
    data.Id = stageConfig.Id
    data.Name = stageConfig.Name
    data.IsChallengeStage = stageConfig.IsChallenge
    data.Desc = stageConfig.Desc
    data.Pieces = {}
    local pieces = stageConfig.InitialPiece
    local dict = {}
    for i = 1, #pieces do
        local pieceId = pieces[i]
        dict[pieceId] = stageConfig.InitialPieceNum[i] or 1
    end
    for pieceId, amount in pairs(dict) do
        local pieceData = {}
        data.Pieces[#data.Pieces + 1] = pieceData
        self:GetPieceData(pieceId, pieceData, XLuckyTenantEnum.QualityIcon.Quad)
        pieceData.Amount = amount
        local pieceType = self._Model:GetLuckyTenantChessTypeById(pieceId)
        pieceData.TypeName = self._Model:GetLuckyTenantChessTypeNameById(pieceType)
        pieceData.Tag = self:GetDataPieceTagByTagArray(self._Model:GetLuckyTenantChessTagById(pieceId))
    end
    table.sort(data.Pieces, function(a, b)
        return a.Id < b.Id
    end)
end

---@param data XUiLuckyTenantChessBagGridData
function XLuckyTenantControl:GetPieceData(pieceId, data, qualityIconType)
    local config = self._Model:GetLuckyTenantChessConfigById(pieceId)
    self._TempPiece:SetConfigAndClear(config)
    local piece = self._TempPiece
    data.Name = piece:GetName()
    data.Icon = piece:GetIcon()
    data.Value = piece:GetValue()
    data.Desc = piece:GetDesc(self._Model)
    local quality = piece:GetQuality()
    data.Quality = self._Model:GetQualityIcon(quality, qualityIconType)
    data.QualityValue = quality
    data.IsCanDelete = piece:IsCanDelete()
    --data.Uid = piece:GetUid()
    data.Position = self._Game and piece:GetPositionIndex(self._Game) or 0
    data.Id = piece:GetId()
    --data.Round = 0
    data.IsDirty = true
    data.IsSelected = false
    data.ValueUponDeletion = piece:GetValueUponDeletion()
end

---@param data XUiLuckyTenantChessBagGridData
function XLuckyTenantControl:GetPieceDesc(data)
    if data.Position and data.Position > 0 then
        local piece = self._Game:GetChessboard():GetPieceByIndex(data.Position)
        if piece then
            data.Desc = piece:GetDesc(self._Model)
        end
    end
    return data.Desc
end

function XLuckyTenantControl:StartSelectPiece()
    if self._Game:HasSupplyChess() then
        self._Game:ClearHasSupplyChess()
        self._Model:SetPlayingStageRound(self._Game:GetRound())
        self._UiData.Round = self._Game:GetRound()
        XMVCA.XLuckyTenant:Print("恢复选棋，回合数是", self._UiData.Round)
        self:UpdateSelectPiece()
        XLuaUiManager.Open("UiLuckyTenantChess")
        return
    end
    self._Game:NextRound(self._Model)
    self._Model:SetPlayingStageRound(self._Game:GetRound())
    self._UiData.Round = self._Game:GetRound()
    XMVCA.XLuckyTenant:Print("开始选棋，回合数是", self._UiData.Round)
    self:UpdateSelectPiece()
    XLuaUiManager.Open("UiLuckyTenantChess")
    XMVCA.XLuckyTenant:RequestSupplyPieces(self._Game)
end

function XLuckyTenantControl:Restart(stageId, seed, isFirstTimeEntering)
    if self._Game:IsGameOver() or
            --self._Game:IsNormalClear() or
            self._Game:IsPerfectClear() then
        XMVCA.XLuckyTenant:RequestStart(stageId, function()
            self:StartGame(stageId, seed, isFirstTimeEntering)
        end)
        return
    end
    XMVCA.XLuckyTenant:RequestRestart(self._Game, function()
        self:StartGame(stageId, seed, isFirstTimeEntering)
    end)
end

function XLuckyTenantControl:RequestSettle()
    XMVCA.XLuckyTenant:RequestSettle(self._Game:GetStageId())
end

function XLuckyTenantControl:OnStagePassed()
    self._Model:OnStagePassed(self._Game:GetRecord())
    self._Model:ClearPlayingStage()
end

function XLuckyTenantControl:ManualSettle()
    if self._Game:IsPerfectClear() then
        XMVCA.XLuckyTenant:Print("[XLuckyTenantControl] 已经通关, 手动结算失败")
        XLuaUiManager.Close("UiLuckyTenantGame")
        return
    end
    XLuaUiManager.Open("UiLuckyTenantOverDetail", XLuckyTenantEnum.OverDetailUi.Over)
end

function XLuckyTenantControl:RequestOver()
    XLuaUiManager.Close("UiLuckyTenantOverDetail")
    if self._Game then
        if self._Game:IsNormalClear() then
            self._Game:SetState(GameState.NormalClear)
            self:UpdateGameState()
            self:RequestSettle()
            return
        end
        if self._Game:IsPerfectClear() then
            return
        end
        self._Game:SetState(GameState.GameOver)
        self:UpdateGameState()
        self:RequestSettle()
        --XLuaUiManager.Close("UiLuckyTenantGame")
    else
        local playingStageId = self._Model:GetPlayingStageId()
        if playingStageId then
            XMVCA.XLuckyTenant:RequestSettle(playingStageId)
        end
    end
end

function XLuckyTenantControl:GetTaskGroupIds()
    local activityConfig = self._Model:GetActivityConfig()
    if activityConfig then
        return activityConfig.TaskGroup
    end
    return {}
end

function XLuckyTenantControl:GetTaskReward4Show()
    local activityConfig = self._Model:GetActivityConfig()
    if activityConfig then
        return activityConfig.ShowReward
    end
    return {}
end

function XLuckyTenantControl:GetCurrentRound()
    return self._Game:GetRound()
end

function XLuckyTenantControl:FinishAnimation()
    XMVCA.XLuckyTenant:Print("播放动画结束")
    self._UiData.AnimationGroups = false
    self:NextGameState()
    self:UpdateUiData(true)
end

function XLuckyTenantControl:IsNormalClear()
    if self._Game then
        return self._Game:IsNormalClear()
    end
    local playingStageId = self._Model:GetPlayingStageId()
    if playingStageId then
        local round = self._Model:GetPlayingStageRound()
        local tasks = self._Model:GetStageTasks(playingStageId)
        for i = 1, #tasks do
            local task = tasks[i]
            if task.Round < round and task.NormalClear then
                return true
            end
        end
    end
    return false
end

function XLuckyTenantControl:HasEnoughPropToDelete()
    local amount = self._Game:GetBag():GetPropAmount(XLuckyTenantEnum.Item.DeleteProp)
    return amount >= XLuckyTenantEnum.Cost
end

---@param data XUiLuckyTenantGameGridData
function XLuckyTenantControl:UpdatePieceDataOnChessboard(data)
    local position = data.Position
    if position then
        local piece = self._Game:GetChessboard():GetPieceByIndex(position)
        if piece then
            piece:GetUiData(self._Model, self._Game, data)
            data.Tag = self:GetPieceTag(piece)
            data.TypeName = self._Model:GetLuckyTenantChessTypeNameById(piece:GetPieceType())
        else
            data.IsValid = true
        end
    end
end

function XLuckyTenantControl:GetRefreshPropIcon()
    local icon = self._Model:GetLuckyTenantChessIconById(XLuckyTenantEnum.PropId.RefreshProp)
    return icon
end

function XLuckyTenantControl:GetDeletePropIcon()
    local icon = self._Model:GetLuckyTenantChessIconById(XLuckyTenantEnum.PropId.DeleteProp)
    return icon
end

function XLuckyTenantControl:GetTag()
    local tags, isDirty = self._Game:GetBag():GetTag()
    if not isDirty then
        return self._UiData.Tag
    end
    self._UiData.Tag = {}
    local uiData = self._UiData.Tag
    for tag, amount in pairs(tags) do
        tag = tonumber(tag)
        ---@class XUiLuckyTenantTagData
        local tagData = {
            Tag = tag,
            Icon = self._Model:GetTagIcon(tag),
            Amount = amount
        }
        table.insert(uiData, tagData)
    end
    table.sort(uiData, function(a, b)
        if a.Amount ~= b.Amount then
            return a.Amount > b.Amount
        end
        return a.Tag < b.Tag
    end)
    return uiData
end

---@param piece XLuckyTenantPiece
function XLuckyTenantControl:GetPieceTag(piece)
    return self:GetDataPieceTagByTagArray(piece:GetTag())
end

function XLuckyTenantControl:GetDataPieceTagByTagArray(tags)
    local uiData = {}
    for _, tag in pairs(tags) do
        tag = tonumber(tag)
        ---@type XUiLuckyTenantTagData
        local tagData = {
            Tag = tag,
            Icon = self._Model:GetTagIcon(tag),
            Amount = 0
        }
        table.insert(uiData, tagData)
    end
    table.sort(uiData, function(a, b)
        if a.Amount ~= b.Amount then
            return a.Amount > b.Amount
        end
        return a.Tag < b.Tag
    end)
    return uiData
end

function XLuckyTenantControl:GetQualityIconCircle(qualityValue)
    return self._Model:GetQualityIconCircle(qualityValue)
end

function XLuckyTenantControl:UpdateIcon4Animation()
    self._UiData.Icon4Animation = {}
    local result = self._UiData.Icon4Animation
    local bag = self._Game:GetBag()
    local pieces = bag:GetPieces()
    for uid, piece in pairs(pieces) do
        result[#result + 1] = {
            Icon = piece:GetIcon(),
            QualityIcon = self._Model:GetQualityIconQuad(piece:GetQuality())
        }
    end
end

-- 随机选择函数
local function RandomSelect(t, amount)
    local selected = {}
    local count = #t

    -- 检查请求的数量是否大于table的长度
    if amount > count then
        amount = count
    end

    -- 创建一个用于标记已选元素的表
    local indices = {}
    for i = 1, count do
        indices[i] = i
    end

    -- 随机打乱索引
    for i = count, 2, -1 do
        local j = math.random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    -- 选择前amount个元素
    for i = 1, amount do
        table.insert(selected, t[indices[i]])
    end

    return selected
end

function XLuckyTenantControl:GetIcon4Animation(amount)
    local array = self._UiData.Icon4Animation
    local result = RandomSelect(array, amount)
    return result
end

return XLuckyTenantControl
