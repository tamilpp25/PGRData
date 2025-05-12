local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")

---@class XLuckyTenantAgency : XAgency
---@field private _Model XLuckyTenantModel
local XLuckyTenantAgency = XClass(XFubenActivityAgency, "XLuckyTenantAgency")

function XLuckyTenantAgency:OnInit()
    self:RegisterActivityAgency()
    self._IsDebugLog = XMain.IsEditorDebug
    --初始化一些变量
    if self._IsDebugLog then
        self._Log = {}
    end
    self._IsRequesting = false
    self._IsOffline = false
    self._IsPlaying = false
end

function XLuckyTenantAgency:InitRpc()
    --实现服务器事件注册
    XRpc.LuckyTenantStagesNotify = Handler(self, self.LuckyTenantStagesNotify)
end

function XLuckyTenantAgency:ClearAfterLeavingTheGame()
    if self._IsRequesting then
        XLog.Error("[XLuckyTenantAgency] 强制解除请求中状态，有问题")
    end
    self._IsRequesting = false
end

function XLuckyTenantAgency:InitEvent()
    self._IsRequesting = false
end

function XLuckyTenantAgency:Print(...)
    if self._IsDebugLog then
        local params = { ... }
        local log = table.concat(params, " ")
        self._Log[#self._Log + 1] = log
        XLog.Debug(log)
    end
end

function XLuckyTenantAgency:Error(...)
    if self._IsDebugLog then
        XLog.Error(...)
    end
end

function XLuckyTenantAgency:ClearLog()
    if self._IsDebugLog then
        self._Log = {}
    end
end

function XLuckyTenantAgency:LogHistory()
    if self._IsDebugLog then
        local str = table.concat(self._Log, "\n")
        XLog.Debug("以下为日志:", str)
    end
end

function XLuckyTenantAgency:SetTestCase(id)
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_SET_TEST_CASE, id)
end

function XLuckyTenantAgency:TestClearBag()
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_CLEAR_BAG)
end

function XLuckyTenantAgency:ExCheckInTime()
    return true
end

local function Median(tbl)
    -- 首先，检查表是否为空
    if #tbl == 0 then
        return nil -- 或者返回其他值，表示无中位数
    end

    -- 对表进行排序
    table.sort(tbl)

    local len = #tbl
    if len % 2 == 1 then
        -- 如果元素数量是奇数，中位数是中间的元素
        return tbl[math.ceil(len / 2)]
    else
        -- 如果元素数量是偶数，中位数是中间两个元素的平均值
        local mid1 = tbl[len / 2]
        local mid2 = tbl[len / 2 + 1]
        return (mid1 + mid2) / 2
    end
end

function XLuckyTenantAgency:TestRandomSelect(stageId, round, times, seed)
    local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
    local GameState = XLuckyTenantEnum.GameState

    local time = os.clock()
    self._IsDebugLog = false
    seed = seed or os.time()
    local recordScore = {}
    local recordSeed = {}
    local recordRound = {}
    local recordSelect = {}
    if not times then
        local roundsToPerfectClear = round or self._Model:GetRoundsToPerfectClear(stageId)
        if roundsToPerfectClear and roundsToPerfectClear > 0 then
            times = roundsToPerfectClear ^ 2 * 40
        end
    end
    if not times then
        times = 1000
    end
    local animationGroups = {}
    for i = 1, times do
        seed = seed + i
        math.randomseed(seed)
        local XLuckyTenantGame = require("XModule/XLuckyTenant/Game/XLuckyTenantGame")
        ---@type XLuckyTenantGame
        local game = XLuckyTenantGame.New()
        game:Init(self._Model, stageId, seed, false)
        game:SetState(GameState.SelectPiece)
        for j = 1, 99 do
            game:GetOptionsThisRound(self._Model)
            if game:GetState() == GameState.Roll then
                game:ResetChessBoard(self._Model)
                game:CalculateScore(self._Model, animationGroups)
                game:NextState(self._Model)
            end
            if game:GetState() == GameState.CheckQuestCompletionStatus then
                game:NextState(self._Model)
                if game:IsPerfectClear() or game:IsGameOver() then
                    break
                end
                if round then
                    if game:GetRound() == round then
                        break
                    end
                end
            end
            if game:GetState() == GameState.ShowNextQuestGoals then
                game:NextState(self._Model)
            end
            if game:GetState() == GameState.Animation then
                game:NextState(self._Model)
            end
            if game:GetState() == GameState.SelectPiece then
                game:NextRound(self._Model)
                local success, piece = game:SelectPiece(self._Model, math.random(1, 3))
                if success then
                    recordSelect[i] = recordSelect[i] or {}
                    recordSelect[i][#recordSelect[i] + 1] = piece:GetName()
                end
            end
        end
        local score = game:GetTotalScore()
        recordScore[i] = score
        recordSeed[i] = seed
        recordRound[i] = game:GetRound()
    end
    local minScore = math.huge
    local minSeed = 0
    local minRound = 0
    local minSelect = false
    local tempScore = 0
    for i = 1, #recordScore do
        tempScore = recordScore[i]
        if tempScore < minScore then
            minScore = tempScore
            minSeed = recordSeed[i]
            minRound = recordRound[i]
            minSelect = recordSelect[i]
        end
    end
    XLog.Error("最低分:" .. minScore .. "/中位数" .. Median(recordScore) .. "/回合数是:" .. minRound, ",随机种子是" .. tostring(minSeed) .. ":运行" .. times .. "次")
    self._IsDebugLog = true
    XLog.Error("每回合的选择是:", table.concat(minSelect, ","))
    XLog.Error("耗时:" .. os.clock() - time)
end

function XLuckyTenantAgency:LuckyTenantStagesNotify(data)
    self._Model:SetDataFromServer(data)
end

function XLuckyTenantAgency:CheckRequestingAndOffline(callback)
    if self._IsRequesting then
        XLog.Warning("[XLuckyTenantAgency] request too frequently")
        return true
    end
    if self._IsOffline then
        if callback then
            callback()
        end
        return true
    end
    return false
end

function XLuckyTenantAgency:RequestStart(stageId, callback)
    if self:CheckRequestingAndOffline(callback) then
        return
    end
    self._IsRequesting = true
    XNetwork.Call("LuckyTenantStageBeginRequest", {
        StageId = stageId,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetPlayingStageId(stageId)
        self._Model:SetPlayingStageRound(1)
        if callback then
            callback(res.PlayingStage)
        end
    end, nil, function()
        self:SetRequesting(false)
    end)
end

--- 补充棋子的选项
---@param game XLuckyTenantGame
function XLuckyTenantAgency:RequestSupplyPieces(game, useProp)
    if self:CheckRequestingAndOffline() then
        return
    end

    local stageId = game:GetStageId()
    local options = game:GetOptionsThisRound(self._Model)
    local pieces = {}
    for i = 1, #options do
        local pieceId = options[i]:GetId()
        pieces[#pieces + 1] = pieceId
    end

    local refreshChess
    if useProp then
        local piece = game:GetBag():GetProp(XLuckyTenantEnum.Item.RefreshProp)
        if piece then
            refreshChess = piece:GetEncodeMessage()
            XMVCA.XLuckyTenant:Print("刷新道具剩余数量:" .. piece:GetAmount())
        else
            XLog.Error("[XLuckyTenantAgency] 刷新棋子道具不存在")
        end
    end

    -- 在第一回合, 需要发送初始背包内容
    local message
    if game:GetRound() == 1 then
        message = {}
        local log
        if XMain.IsEditorDebug then
            log = {}
        end
        message = game:GetBag():GetEncodeMessage(log)
        if log then
            XLog.Debug("打印LuckyTenantSuppleChessRequest", {
                StageId = stageId,
                SuppleChess = pieces,
                Chess = refreshChess,
                Grids = log,
            })
        end
    end

    self._IsRequesting = true
    XNetwork.Call("LuckyTenantSuppleChessRequest", {
        StageId = stageId,
        SuppleChess = pieces,
        Chess = refreshChess,
        Grids = message,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end, nil, function()
        self:SetRequesting(false)
    end)
end

--- 下回合开始
---@param game XLuckyTenantGame
function XLuckyTenantAgency:RequestNextRound(game)
    if self:CheckRequestingAndOffline() then
        return
    end
    self._IsRequesting = true

    local stageId = game:GetStageId()
    local logGrids
    if self._IsDebugLog then
        logGrids = {}
    end
    local grids = game:GetBag():GetEncodeMessage(logGrids)
    if logGrids then
        XLog.Debug("打印LuckyTenantRoundBeginRequest", {
            StageId = stageId,
            Grids = logGrids,
        })
    end
    --XMessagePack.MarkAsTable(grids)
    XNetwork.Call("LuckyTenantRoundBeginRequest", {
        StageId = stageId,
        Grids = grids,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end, nil, function()
        self:SetRequesting(false)
    end)
end

--- 分数变化
---@param game XLuckyTenantGame
function XLuckyTenantAgency:RequestUpdateScore(game)
    if self:CheckRequestingAndOffline() then
        return
    end
    self._IsRequesting = true

    local stageId = game:GetStageId()
    local logGrids
    if self._IsDebugLog then
        logGrids = {}
    end

    local record = game:GetRecord4Server()
    local suppleChess = record.SelectPiece
    record.SelectPiece = {}
    local deleteChess = record.DeletePiece
    record.DeletePiece = {}

    local chessboard = game:GetChessboard():GetEncodeMessage()
    local grids = game:GetBag():GetEncodeMessage(logGrids)
    if logGrids then
        XLog.Debug("打印LuckyTenantRoundEndRequest", {
            StageId = stageId,
            AddScore = game:GetScoreThisRound(),
            Grids = logGrids,
            ChessBoard = chessboard,
            SuppleChess = suppleChess,
            DeleteChess = deleteChess,
        })
    end
    --XMessagePack.MarkAsTable(grids)
    local score = game:GetScoreThisRound()
    --if XMain.IsZlbDebug then
    --    score = 0
    --end
    local round = game:GetRound()
    XNetwork.Call("LuckyTenantRoundEndRequest", {
        StageId = stageId,
        AddScore = score,
        Grids = grids,
        ChessBoard = chessboard,
        SuppleChess = suppleChess,
        DeleteChess = deleteChess,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 服务端结算，需要清空游戏中纪录
        if res.RoundFin == 2 or res.RoundFin == 1 then
            if game:GetRound() > round then
                XLog.Error("[XLuckyTenantAgency] 服务端认为已经结束了，但是客户端还在游戏中，强制终止")
                if res.RoundFin == 1 then
                    game:SetState(XLuckyTenantEnum.GameState.PerfectClear)
                elseif res.RoundFin == 2 then
                    game:SetState(XLuckyTenantEnum.GameState.GameOver)
                end
            end
            game:SetRoundFin(res.RoundFin)
            self._Model:ClearPlayingStage()
        end
    end, nil, function()
        self:SetRequesting(false)
    end)
end

--- 结算
function XLuckyTenantAgency:RequestSettle(stageId)
    if self:CheckRequestingAndOffline() then
        return
    end
    self._IsRequesting = true
    --local stageId = game:GetStageId()
    XNetwork.Call("LuckyTenantStageEndRequest", {
        StageId = stageId,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        res.Record.StageId = stageId
        self._Model:OnStagePassed(res.Record)
        self._Model:ClearPlayingStage()
        XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_UPDATE_STAGE)
    end, nil, function()
        self:SetRequesting(false)
    end)
end

--- 重开
---@param game XLuckyTenantGame
function XLuckyTenantAgency:RequestRestart(game, callback)
    if self:CheckRequestingAndOffline(callback) then
        return
    end
    self._IsRequesting = true

    local stageId = game:GetStageId()
    XNetwork.Call("LuckyTenantStageRestartRequest", {
        StageId = stageId,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        res.Record.StageId = stageId
        self._Model:OnStagePassed(res.Record)
        if callback then
            callback()
        end
    end, nil, function()
        self:SetRequesting(false)
    end)
end

function XLuckyTenantAgency:IsOffline()
    return self._IsOffline
end

function XLuckyTenantAgency:IsShowRedDot()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.LuckyTenant, false, true) then
        return false
    end
    if self:IsShowRedDotTask() then
        return true
    end
    local stages = self._Model:GetStages()
    for i = 1, #stages do
        local stage = stages[i]
        if self:IsShowRedDotStage(stage.Id) then
            return true
        end
    end
    return false
end

function XLuckyTenantAgency:IsShowRedDotStage(stageId)
    local stageConfig = self._Model:GetLuckyTenantStageConfigById(stageId)
    if XFunctionManager.CheckInTimeByTimeId(stageConfig.TimeId)
            and (stageConfig.PreStage == 0 or self._Model:IsStagePassed(stageConfig.PreStage))
    then
        if XSaveTool.GetData(self:GetKeyHasPlayed(stageConfig.Id)) == nil then
            return true
        end
    end
end

function XLuckyTenantAgency:IsShowRedDotTask()
    local activityConfig = self._Model:GetActivityConfig()
    if activityConfig then
        local taskGroups = activityConfig.TaskGroup
        for i = 1, #taskGroups do
            local groupId = taskGroups[i]
            if XDataCenter.TaskManager.CheckLimitTaskList(groupId) then
                return true
            end
        end
    end
    return false
end

function XLuckyTenantAgency:IsAllTaskFinish()
    local activityConfig = self._Model:GetActivityConfig()
    if activityConfig then
        local taskGroups = activityConfig.TaskGroup
        for i = 1, #taskGroups do
            local groupId = taskGroups[i]
            if not XDataCenter.TaskManager.CheckLimitTaskList(groupId) then
                return false
            end
        end
    end
    return true
end

function XLuckyTenantAgency:GetKeyHasPlayed(stageId)
    return "LuckyTenantNewStage" .. stageId .. "_" .. XPlayer.Id
end

function XLuckyTenantAgency:DebugClearStageRecord(stageId)
    self._Model:DebugClearStageRecord(stageId)
end

function XLuckyTenantAgency:IsInStageAndRound(stageId, round)
    --if not XLuaUiManager.IsUiLoad("UiLuckyTenantGame") then
    --    return false
    --end
    if not self._IsPlaying then
        return false
    end

    local playingStageId = self._Model:GetPlayingStageId()
    local playingRound = self._Model:GetPlayingStageRound()

    local isInStage = (stageId == 0 and playingStageId and playingStageId > 0) or (stageId ~= 0 and playingStageId == stageId)
    local isInRound = (round == 0 and playingRound and playingRound > 0) or (round ~= 0 and playingRound == round)

    return isInStage and isInRound
end

--- 重开
---@param game XLuckyTenantGame
---@param deletePieces XLuckyTenantPiece[]
---@param updatePieces XLuckyTenantPiece[]
function XLuckyTenantAgency:RequestDeleteOrUpdateChess(game, deletePieces, updatePieces, callback)
    if self:CheckRequestingAndOffline() then
        return
    end
    self._IsRequesting = true

    local toDelete
    if deletePieces and #deletePieces > 0 then
        toDelete = {}
        for i = 1, #deletePieces do
            local piece = deletePieces[i]
            toDelete = piece:GetEncodeMessage()
        end
    end

    local toUpdate
    if updatePieces and #updatePieces > 0 then
        toUpdate = {}
        for i = 1, #updatePieces do
            local piece = updatePieces[i]
            toUpdate = piece:GetEncodeMessage()
        end
    end

    XNetwork.Call("LuckyTenantDeleteUpdateChessRequest", {
        DeleteChess = toDelete,
        UpdateChess = toUpdate,
        StageId = game:GetStageId(),
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback()
        end
    end, nil, function()
        self:SetRequesting(false)
    end)
end

function XLuckyTenantAgency:SetPlaying(value)
    self._IsPlaying = value
end

function XLuckyTenantAgency:OpenMain()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.LuckyTenant, false, true) then
        return false
    end
    if not self._Model:IsActivityOpen() then
        XUiManager.TipText("ActivityBranchNotOpen")
        return
    end
    XLuaUiManager.Open("UiLuckyTenantMain")
end

function XLuckyTenantAgency:IsRequesting()
    return self._IsRequesting
end

function XLuckyTenantAgency:SetRequesting(value)
    --if XMain.IsZlbDebug then
    --    return
    --end
    self._IsRequesting = value
end

return XLuckyTenantAgency