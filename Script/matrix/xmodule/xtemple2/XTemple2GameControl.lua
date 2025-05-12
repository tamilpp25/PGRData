local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")
local RULE = XTemple2Enum.RULE
local SCORE_TYPE = XTemple2Enum.SCORE_TYPE

---@class XTemple2GameControl : XControl
---@field private _Model XTemple2Model
---@field private _MainControl XTemple2Control
local XTemple2GameControl = XClass(XControl, "XTemple2GameControl")

function XTemple2GameControl:OnInit()
    ---@type XTemple2Game
    self._Game = false

    ---@type XTemple2Game
    self._GamePreview = false
    self._IsGamePreviewInsertBlock = false

    ---@type XTemple2Chat
    self._Chat = require("XModule/XTemple2/Game/XTemple2Chat").New()

    self._SelectedStageId = 0
    self._SelectedMapId = 0

    self._UiData = {
        ---@type XTempleEditorUiDataGrid[]
        StageList = false,
        Map = {
            X = 0,
            Y = 0,
            Grids = {},
        },
        Operation = {
            Grids = {},
            IsRed = false
        },
        ---@type XUiTemple2EditorEditBlockGridData[]
        Blocks = {},
        Score = {
            Total = 0,
            Grid = 0,
            Path = 0,
            Like = 0,
            Task = 0,
        },
        Bg = {
            Image = false,
            Width = 0,
            Height = 0,
            OffsetX = 0,
            OffsetY = 0,
        }
    }

    --编辑地图时用到的地块
    ---@type XUiTemple2GameBlockOptionData[]
    self._BlockOptions = false

    ---@type XTemple2Block
    self._Block2EditMap = false

    self._IsModeScore = XSaveTool.GetData(XTemple2Enum.SAVE_KEY_MODE_SCORE .. XPlayer.Id) == true

    self._Color1 = {
        [XTemple2Enum.COLOR.None] = XUiHelper.Hexcolor2Color("FFB98DB2"),
        [XTemple2Enum.COLOR.RED] = XUiHelper.Hexcolor2Color("FF4042B2"),
        [XTemple2Enum.COLOR.YELLOW] = XUiHelper.Hexcolor2Color("FFB91DB2"),
        [XTemple2Enum.COLOR.BLUE] = XUiHelper.Hexcolor2Color("60B7FFB2"),
    }
    self._Color2 = {
        [XTemple2Enum.COLOR.None] = XUiHelper.Hexcolor2Color("FFB98D"),
        [XTemple2Enum.COLOR.RED] = XUiHelper.Hexcolor2Color("FF4042"),
        [XTemple2Enum.COLOR.YELLOW] = XUiHelper.Hexcolor2Color("FFB91D"),
        [XTemple2Enum.COLOR.BLUE] = XUiHelper.Hexcolor2Color("60B7FF"),
    }
    self._Color3 = {
        [XTemple2Enum.COLOR.None] = XUiHelper.Hexcolor2Color("FFB98D"),
        [XTemple2Enum.COLOR.RED] = XUiHelper.Hexcolor2Color("FF4042"),
        [XTemple2Enum.COLOR.YELLOW] = XUiHelper.Hexcolor2Color("FFB91D"),
        [XTemple2Enum.COLOR.BLUE] = XUiHelper.Hexcolor2Color("60B7FF"),
    }
    self._Path = {}
end

function XTemple2GameControl:OnRelease()
    self:ClearGame()
end

function XTemple2GameControl:ClearGame()
    self._Game = false
    self._GamePreview = false
end

---@return XTemple2Game
function XTemple2GameControl:GetGame()
    if not self._Game then
        self._Game = require("XModule/XTemple2/Game/XTemple2Game").New()
    end
    return self._Game
end

function XTemple2GameControl:GetGamePreview()
    if not self._GamePreview then
        self._GamePreview = self._Game:Clone()
    end
    return self._GamePreview
end

function XTemple2GameControl:SaveRecord()
    --if self._Game then
    --    self._TempRecord = self._Game:GetOperations()
    --end
end

function XTemple2GameControl:RestoreRecord(record)
    if record then
        -- todo by zlb 种子设置未处理
        --record.Seed
        local game = self._Game
        if game then
            game:SetSeed(record.StartTime)
            --game:SetNpcId(record.CharacterId)
            game:SetOperations(record.OperatorRecords)
            if not record.StartTime then
                XLog.Error("[XTemple2GameControl] 要恢复的纪录没有纪录开始时间，有问题")
            end
        else
            XLog.Error("[XTemple2GameControl] 没有进行中的游戏，但是试图恢复纪录")
        end
    end
    self:UpdatePathAndScore()
end

---@param data XTemple2EditorUiDataGrid
function XTemple2GameControl:SetSelectedStage(data)
    self:RemoveBlock2EditMap()

    self:ClearGame()
    self._BlockOptions = false
    self._SelectedStageId = data.StageId
    self._SelectedMapId = data.MapId
    local game = self:GetGame()

    if data.NpcId then
        game:SetNpcId(data.NpcId)
    end
    if #game:GetAllBlock() == 0 then
        local allBlockConfigs = self._Model:GetAllBlocks()
        if allBlockConfigs then
            game:InitBlocks(allBlockConfigs, self._Model)
        end
    end

    ---@type XTable.XTableTemple2Stage
    local config = self._Model:GetStageGameConfig(data.MapId)
    if config then
        if data.Seed then
            game:SetSeed(data.Seed)
        end

        local mapConfig = self._Model:GetMapConfig(data.MapId)
        game:InitGame(config, self._Model, mapConfig)
        self:UpdatePathAndScore()
        self._Chat:Init(self._Model, game)
        return true
    end
    XLog.Error("[XTemple2GameControl] 关卡对应的配置不存在:", data.MapId)
    game:ClearPool()
    self:ResetMap()
    self:UpdatePathAndScore()
    self._Chat:Clear()
    return false
end

function XTemple2GameControl:GetUiData()
    return self._UiData
end

function XTemple2GameControl:GetBgData()
    local config = self._Model:GetMapConfig(self._SelectedMapId)
    if config then
        local bgData = self._UiData.Bg
        bgData.Image = config.Bg
        bgData.Width = config.BgWidth
        bgData.Height = config.BgHeight
        bgData.OffsetX = config.BgOffsetX
        bgData.OffsetY = config.BgOffsetY
        return bgData
    end
end

function XTemple2GameControl:UpdatePathAndScore()
    local game = self:GetGame()

    -- 更新分数
    local path = game:UpdatePathAndScore()
    if path then
        self._UiData.Score.Grid = game:GetScore(SCORE_TYPE.GRID_SCORE)
        self._UiData.Score.Path = game:GetScore(SCORE_TYPE.PATH_SCORE)
        self._UiData.Score.Like = game:GetScore(SCORE_TYPE.LIKE_SCORE)
        self._UiData.Score.Task = game:GetScore(SCORE_TYPE.TASK_SCORE)
        self._UiData.Score.Total = game:GetScore(SCORE_TYPE.TOTAL_SCORE)
        self._Path = path
    else
        self._Chat:CheckEvent(XTemple2Enum.CHAT_TYPE.PATH_FAIL)
        self._UiData.Score.Grid = game:GetScore(SCORE_TYPE.GRID_SCORE)
        self._UiData.Score.Path = game:GetScore(SCORE_TYPE.PATH_SCORE)
        self._UiData.Score.Like = game:GetScore(SCORE_TYPE.LIKE_SCORE)
        self._UiData.Score.Task = game:GetScore(SCORE_TYPE.TASK_SCORE)
        self._UiData.Score.Total = game:GetScore(SCORE_TYPE.TOTAL_SCORE)
        self._Path = {}
    end

    self._Chat:CheckCondition(game)

    self:UpdateScorePreview()
end

function XTemple2GameControl:GetUiDataMap()
    local game = self:GetGame()
    --game:GetMap():PrintMap()
    local grids = game:GetGrids()
    local maxX, maxY = game:GetMap():GetSize()

    ---@type XUiTemple2CheckBoardData
    local map = self._UiData.Map
    map.X = maxX
    map.Y = maxY
    map.StageId = self._SelectedStageId

    local grid2Rule = game:GetGrid2Rule()

    ---@type XUiTemple2CheckBoardGridData[]
    local gridData = map.Grids
    self:GetDataGrids(gridData, grids, maxX, maxY, self._Color1, grid2Rule)

    -- 随机一部分格子放行人上去
    if game:IsAnimationPlaying() then
        math.randomseed(XTime.GetServerNowTimestamp())
        local maxNpcAmount = math.ceil(#gridData / 20)
        local minNpcAmount = math.max(15, maxNpcAmount)
        maxNpcAmount = math.max(minNpcAmount, maxNpcAmount)
        local npcAmount = math.random(minNpcAmount, maxNpcAmount)
        for i = 1, npcAmount do
            local index = math.random(1, #gridData)
            local data = gridData[index]
            if data and data.IsEmpty and not data.Path then
                data.IsShowNpc = true
            end
        end
    end

    -- 高亮有得分变化的格子
    if self._Block2EditMap then
        local gamePreview = self:GetGamePreview()
        local mapPreview = gamePreview:GetMap()
        local mapCurrent = game:GetMap()
        for i = 1, #gridData do
            local data = gridData[i]
            data.IsHighLight = false
            --data.Score
            local x, y = data.X, data.Y
            local grid = mapPreview:GetGrid(x, y)
            if grid and grid:IsValid() then
                local score = grid:GetTotalScore()
                local originalGrid = mapCurrent:GetGrid(x, y)
                local originalScore
                if originalGrid then
                    originalScore = originalGrid:GetTotalScore()
                end
                if score ~= originalScore and score and score ~= 0 then
                    data.IsHighLight = true
                    data.HighLightColor = self._Color3[grid:GetColor()]
                else
                    data.IsHighLight = false
                end
            else
                data.IsHighLight = false
            end
        end
    else
        for i = 1, #gridData do
            local data = gridData[i]
            data.IsHighLight = false
        end
    end

    local path = self._Path
    if path then
        local pathDict = {}
        ---@class XTemple2GameControlPathData
        local lastOne = {
            Pos = path[1],
            Index = 1,
            AnimationOffset = 0,
            IsPlay = not game:IsAnimationPlaying(),
        }
        for i = 2, #path do
            local current
            local pos = path[i]
            -- 终点不显示箭头
            if i ~= #path then
                current = {
                    Index = i,
                    Pos = path[i],
                    -- 延时播放动画
                    AnimationOffset = i * 0.3,
                    IsPlay = not game:IsAnimationPlaying(),
                }
                pathDict[pos.x] = pathDict[pos.x] or {}
                pathDict[pos.x][pos.y] = current
            end
            if lastOne then
                local direction = XLuaVector2.Sub(pos, lastOne.Pos)
                lastOne.Direction = direction
            end
            lastOne = current
        end
        for i = 1, #gridData do
            local data = gridData[i]
            if pathDict[data.X] and pathDict[data.X][data.Y] then
                data.Path = pathDict[data.X][data.Y]
            else
                data.Path = false
            end
        end

        -- 被替代的入口置灰
        local exit = path[#path]
        if exit then
            local exitGrid = game:GetMap():GetGrid(exit.x, exit.y)
            if exitGrid then
                for i = 1, #gridData do
                    local data = gridData[i]
                    if data.IsExit then
                        if exit.x ~= data.X or exit.y ~= data.Y then
                            data.MaskExit = true
                        end
                    end
                end
            end
        end
    else
        for i = 1, #gridData do
            local data = gridData[i]
            data.Path = false
        end
    end
    return map
end

function XTemple2GameControl:GetDataGrids(gridData, grids, maxX, maxY, color, grid2Rule, noPrefab)
    gridData = gridData or {}
    local index = maxX * maxY + 1
    for y = 1, maxY do
        for x = 1, maxX do
            index = index - 1

            ---@type XTemple2Grid
            local grid = grids[x][y]

            gridData[index] = gridData[index] or {}

            local data = gridData[index]
            gridData[index] = self:GetUiGridData(data, grid, x, y, color, grid2Rule, noPrefab)
        end
    end
    if #gridData ~= maxX * maxY then
        XLog.Warning("[XTemple2GameControl] 清空超出的格子")
        for i = maxX * maxY + 1, #gridData do
            gridData[i] = nil
        end
    end
    return gridData
end

---@param grid XTemple2Grid
function XTemple2GameControl:GetUiGridData(dataO, grid, x, y, color, grid2Rule, noPrefab)
    ---@type XUiTemple2CheckBoardGridData
    local data = dataO or {}
    data.X = x
    data.Y = y
    if grid then
        local isModeScore = self._IsModeScore

        local game = self:GetGame()
        if game:GetIsSettle() or game:IsAnimationPlaying() then
            isModeScore = false
        end
        if grid:IsEmpty() then
            data.IsEmpty = true
            data.IsShowLine = isModeScore
            data.IsExit = false
        else
            local icon = grid:GetIcon()
            if grid:IsObstacle() then
                data.IsShowLine = false
                icon = false
            else
                data.IsShowLine = isModeScore
            end
            local gridId = grid:GetId()
            data.Id = gridId
            data.IsEmpty = false
            data.Icon = icon
            local colorIndex = grid:GetColor()
            data.Color = color and color[colorIndex]
            data.ColorIndex = colorIndex
            data.RuleIcon = false
            data.IsExit = grid:IsEndPoint()
            if noPrefab then
                data.Prefab = false
            else
                local prefab = grid:GetPrefab()
                if prefab and prefab ~= "" then
                    data.Prefab = prefab
                else
                    data.Prefab = false
                end
            end
            data.Icon2Instantiate = false
            if grid2Rule and (self._IsModeScore or self._Block2EditMap) then
                ---@type XTemple2Rule[]
                local rules = grid2Rule[gridId]
                if rules then
                    for id, ruleId in pairs(rules) do
                        local rule = game:GetRule(ruleId)
                        if rule then
                            local gridIcon = rule:GetIconGrid()
                            if gridIcon and gridIcon ~= "" then
                                data.Icon2Instantiate = gridIcon
                            end
                        end
                    end
                end
            end
            if grid:IsRotateChangeAnchorPoint() then
                data.Rotation = grid:GetRotation()
            else
                data.Rotation = 0
            end
            if isModeScore then
                local totalScore = grid:GetTotalScore()
                local taskScore = grid:GetTaskScore()
                if taskScore > 0 then
                    data.Score = "*" .. totalScore .. ""
                elseif totalScore > 0 then
                    data.Score = totalScore
                else
                    data.Score = nil
                end
                data.TotalScore = totalScore
            else
                data.Score = nil
            end
        end
    else
        data.IsEmpty = true
        XLog.Error("[XTemple2GameControl] 棋盘存在空格")
    end
    data.MaskExit = false
    data.IsShowNpc = false
    return data
end

function XTemple2GameControl:GetUiDataBlockOptions()
    if self._BlockOptions then
        return self._BlockOptions
    end

    local priorityDict = {}
    local optionDict = {}
    ---@type XTable.XTableTemple2BlockOption
    local blockOptions = self._Model:GetBlockOptions()
    for _, config in pairs(blockOptions) do
        local nameList = config.NameList
        for i = 1, #nameList do
            local name = nameList[i]
            priorityDict[name] = (config.Type << 5) | i
        end
        optionDict[config.Name] = config
    end

    local game = self:GetGame()
    local blockDic = {}
    local blockPool = game:GetBlockPool()
    local blockRandomPool = game:GetBlockRandomPoolResult()
    self:AddBlockPool(blockDic, blockPool, priorityDict)
    self:AddBlockPool(blockDic, blockRandomPool, priorityDict)

    self._BlockOptions = {}
    for name, blockArray in pairs(blockDic) do
        table.sort(blockArray, function(a, b)
            local priorityA = priorityDict[a:GetName()] or 99999999
            local priorityB = priorityDict[b:GetName()] or 99999999
            return priorityA < priorityB
        end)

        ---@class XUiTemple2GameBlockOptionData
        local option = {
            Name = name,
            Desc = optionDict[name] and optionDict[name].Desc,
            BlockArray = blockArray,
        }
        self._BlockOptions[#self._BlockOptions + 1] = option
    end
    table.sort(self._BlockOptions, function(a, b)
        local priorityA = optionDict[a.Name] and optionDict[a.Name].Type or 99999999
        local priorityB = optionDict[b.Name] and optionDict[b.Name].Type or 99999999
        return priorityA < priorityB
    end)
    return self._BlockOptions
end

---@param blockPool XTemple2Block[]
function XTemple2GameControl:AddBlockPool(blockDict, blockPool)
    local game = self:GetGame()
    for i = 1, #blockPool do
        local block = blockPool[i]
        if block:CheckIsSelected4FavouriteRule(game, self._Model) then
            local name = block:GetTypeName()
            blockDict[name] = blockDict[name] or {}
            -- 去重
            local isExist = false
            local blockArray = blockDict[name]
            for j = 1, #blockArray do
                if blockArray[j]:Equals(block) then
                    isExist = true
                end
            end
            if not isExist then
                blockArray[#blockArray + 1] = block
            end
        end
    end
end

---@param block XTemple2Block
function XTemple2GameControl:SetBlock2EditMap(block)
    self._Block2EditMap = block:Clone()
    self:UpdateScorePreview()
end

---@param block XTemple2Block
function XTemple2GameControl:SetBlock2EditMapNoClone(block)
    self._Block2EditMap = block
    self:UpdateScorePreview()
end

---@param block XTemple2Block
---@param gridData XUiTemple2CheckBoardGridData[]
function XTemple2GameControl:UpdateWhetherBlockLegal(block, gridData)
    local isRed = false
    local map = self:GetGame():GetMap()
    local position = block:GetPosition()
    local anchorPosition = block:GetAnchorPosition()
    local xAmount = block:GetColumnAmount()
    local yAmount = block:GetRowAmount()
    for j = 1, yAmount do
        for i = 1, xAmount do
            local grid = block:GetGrid(i, j)
            if grid and not grid:IsEmpty() then
                local x2Block = position.x - anchorPosition.x + i
                local y2Block = position.y - anchorPosition.y + j
                local gridOnMap = map:GetGrid(x2Block, y2Block)
                isRed = (not gridOnMap) or (not gridOnMap:IsEmpty())
                if isRed then
                    break
                end
            end
        end
        if isRed then
            break
        end
    end
    for i = 1, #gridData do
        local gridUiData = gridData[i]
        if gridUiData.IsEmpty then
            gridUiData.IsRed = false
        else
            gridUiData.IsRed = isRed
        end
    end
end

---@param oldPosition XLuaVector2
function XTemple2GameControl:GetUiDataBlock2EditMap(oldPosition)
    local block = self._Block2EditMap
    if not block then
        return false
    end
    block:SetPositionXY(oldPosition.x, oldPosition.y)

    local grids = block:GetGrids()
    local maxX, maxY = block:GetColumnAmount(), block:GetRowAmount()
    ---@type XUiTemple2CheckBoardGridData[]
    local gridData = {}
    self:GetDataGrids(gridData, grids, maxX, maxY, self._Color2, self:GetGame():GetGrid2Rule(), true)
    self:UpdateWhetherBlockLegal(block, gridData)

    local data = {
        Grids = gridData,
        Position = block:GetPosition()
    }
    return data
end

function XTemple2GameControl:ConfirmBlock2EditMap(position)
    local block = self._Block2EditMap
    if not block then
        XLog.Error("[XTemple2GameControl] 确认地块失败")
        return
    end
    local game = self:GetGame()
    if position then
        block:SetPosition(position)
    end
    local isSuccess = game:InsertBlock(block)
    if isSuccess then

        local blockId = block:GetId()
        game:IncreaseCurrentEffectiveTimes(blockId)

        self:RemoveBlock2EditMap()

        local operations = game:GetOperations()
        local newOperation = operations[#operations]
        if newOperation then
            if not newOperation.IsSendRequest then
                newOperation.IsSendRequest = true
                XMVCA.XTemple2:Temple2OperatorRequest(self._SelectedStageId, XTemple2Enum.OPERATION_TYPE.ADD, newOperation.Round, newOperation.BlockId, newOperation.Rotation, newOperation.X, newOperation.Y)
            end
        end

        local score1 = game:GetScore(SCORE_TYPE.TOTAL_SCORE)
        self:UpdatePathAndScore()
        local score2 = game:GetScore(SCORE_TYPE.TOTAL_SCORE)
        self._Chat:CheckEvent(XTemple2Enum.CHAT_TYPE.PUT_DOWN_BLOCK_AND_SCORE, score2 - score1)
        --self._Chat:CheckEvent(XTemple2Enum.CHAT_TYPE.GAME_SCORE, score2, score1)
    else
        self._Chat:CheckEvent(XTemple2Enum.CHAT_TYPE.PUT_DOWN_BLOCK_FAIL)
    end
    return isSuccess
end

function XTemple2GameControl:RemoveBlock2EditMap()
    self._Block2EditMap = false
    self:UpdateScorePreview()
end

function XTemple2GameControl:RotateBlock2EditMap()
    local block = self._Block2EditMap
    if block then
        block:Rotate90()
        self:UpdatePathAndScore()
    else
        XLog.Warning("[XTemple2GameControl] 旋转不存在的地块")
    end
end

function XTemple2GameControl:IsCanPlay()
    local game = self:GetGame()
    if game:GetIsSettle() then
        return false
    end
    return true
end

function XTemple2GameControl:OnClickGrid(x, y)
    if self._Block2EditMap then
        return false
    end
    local game = self:GetGame()
    if not self:IsCanPlay() then
        return false
    end
    if game:IsAnimationPlaying() then
        return false
    end
    local map = game:GetMap()
    local grid = map:GetGrid(x, y)

    if not grid then
        XLog.Warning("[XTemple2GameControl] 点击无效区域")
        return false
    end
    if XMain.IsEditorDebug then
        XLog.Debug("[XTemple2GameControl] 点击地块id为:" .. grid:GetId())
    end
    if grid:IsEmpty() then
        return false
    end
    local isSuccess, block, operation = game:RemoveBlockByGridPosition(x, y)
    if isSuccess then
        if block then
            game:DecreaseCurrentEffectiveTimes(block:GetId())
            self:UpdatePathAndScore()
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_BLOCK_OPTION)
        end
        --self:SetBlock2EditMap(block)
        self:SetBlock2EditMapNoClone(block)
        block:SetPositionXY(operation.X, operation.Y)
        XMVCA.XTemple2:Temple2OperatorRequest(self._SelectedStageId, XTemple2Enum.OPERATION_TYPE.DELETE, operation.Round, operation.BlockId, operation.Rotation, operation.X, operation.Y)
        return true, operation
    end
    return false
end

function XTemple2GameControl:ResetMap()
    self._Game:GetMap():Clear()
end

function XTemple2GameControl:GetMapSize()
    return self:GetGame():GetMap():GetSize()
end

function XTemple2GameControl:_AddRuleList(animationDataList, rules, index, storyRepeatDict)
    local game = self:GetGame()
    for i = 1, #rules do
        ---@type XTemple2Rule
        local rule = rules[i]
        local bubbleId = rule:GetBubble()
        if bubbleId and bubbleId > 0 then
            if not storyRepeatDict[bubbleId] then
                storyRepeatDict[bubbleId] = true
                local bubbleConfig = self._Model:GetBubble(bubbleId)
                -- 角色对应剧情
                if rule:GetNpcId() == game:GetNpcId() then

                    -- 剧情只播放一次 表情一直播
                    if bubbleConfig.Type == XTemple2Enum.BUBBLE.EMOJI or not self._Model:IsStoryUnlock(bubbleId) then
                        ---@class XTemple2GameControlAnimationData
                        local animationData = {
                            Index = index,
                            -- 复制了一遍
                            Id = bubbleConfig.Id,
                            Type = bubbleConfig.Type,
                            StoryId = bubbleConfig.StoryId,
                            Desc = bubbleConfig.Desc,
                            Icon = bubbleConfig.Icon,
                        }
                        animationDataList[#animationDataList + 1] = animationData
                        game:SetTriggeredPlot(animationData.Id)
                    else
                        XLog.Warning("[XTemple2GameControl] 已播放过剧情:", bubbleId)
                    end
                end
            else
                XLog.Debug("[XTemple2GameControl] 剧情已经在本次游戏中播放过:", bubbleId)
            end
        end
    end
end

---@param grid XTemple2Grid
function XTemple2GameControl:_AddJumpScore(scoreDataList, grid, index)
    if not grid then
        return
    end
    if grid:IsEmpty() then
        return
    end
    local score = grid:GetTotalScore()
    if score ~= 0 then
        scoreDataList[index] = scoreDataList[index] or {}
        local position = grid:GetPosition()
        ---@class XTemple2GameControlAnimationScore
        local data = {
            x = position.x,
            y = position.y,
            Score = score
        }
        table.insert(scoreDataList[index], data)
    end
end

---@param grid XTemple2Grid
function XTemple2GameControl:_AddAnimationData(animationDataList, grid, index, storyRepeatDict)
    if not grid then
        return
    end
    if grid:IsEmpty() then
        return
    end
    if grid:IsHasTask() then
        local taskRules = grid:GetTaskRule()
        self:_AddRuleList(animationDataList, taskRules, index, storyRepeatDict)
    end

    local ruleIdArray = grid:GetRule()
    if #ruleIdArray > 0 then
        local game = self:GetGame()
        local rules = nil
        for i = 1, #ruleIdArray do
            local ruleId = ruleIdArray[i]
            local rule = game:GetRule(ruleId)
            local ruleType = rule:GetRuleType()
            if ruleType == RULE.LIKE or RULE.DISLIKE then
                rules = rules or {}
                rules[#rules + 1] = rule
            end
        end
        if rules then
            self:_AddRuleList(animationDataList, rules, index, storyRepeatDict)
        end
    end
end

function XTemple2GameControl:OnClickStart()
    if not self:IsCanPlay() then
        return false
    end

    if self._Block2EditMap then
        self:RemoveBlock2EditMap()
    end

    local game = self:GetGame()
    if not game:IsCanStart() then
        if not game:IsAnimationFinish() then
            self:SetNextTimeScale()
        end
        return false
    end

    local path = game:GetPath()
    if not path then
        XUiManager.TipText("Temple2PathFail")
        return false
    end
    local timeScale = XSaveTool.GetData("XTemple2GameSpeed" .. XPlayer.Id)
    if timeScale then
        self:SetTimeScale(timeScale)
    end

    local animationDataList = {
        Path = {},
        JumpScore = {},
    }
    local storyRepeatDict = {}
    for i = 1, #path do
        local map = game:GetMap()
        local pos = path[i]
        local x, y = pos.x, pos.y
        local grid = map:GetGrid(x, y)
        if grid then
            local up = map:GetGrid(x, y + 1)
            local down = map:GetGrid(x, y - 1)
            local left = map:GetGrid(x - 1, y)
            local right = map:GetGrid(x + 1, y)
            self:_AddAnimationData(animationDataList.Path, up, i, storyRepeatDict)
            self:_AddAnimationData(animationDataList.Path, down, i, storyRepeatDict)
            self:_AddAnimationData(animationDataList.Path, left, i, storyRepeatDict)
            self:_AddAnimationData(animationDataList.Path, right, i, storyRepeatDict)
            self:_AddJumpScore(animationDataList.JumpScore, up, i)
            self:_AddJumpScore(animationDataList.JumpScore, down, i)
            self:_AddJumpScore(animationDataList.JumpScore, left, i)
            self:_AddJumpScore(animationDataList.JumpScore, right, i)
        end
    end
    self:GetGame():StartWalk(path, animationDataList)
    return true
end

---@param model XTemple2Model
function XTemple2GameControl:GetBubbleToPlayOnSettle()
    local game = self:GetGame()
    local score = game:GetScore(XTemple2Enum.SCORE_TYPE.TOTAL_SCORE)
    local ruleConfigs = self._Model:GetAllRules()
    local bubbleId
    for i, ruleConfig in pairs(ruleConfigs) do
        if ruleConfig.RuleType == XTemple2Enum.RULE.PLAY_MOVIE_IF_EXCEED_A_CERTAIN_SCORE then
            if ruleConfig.NpcId == game:GetNpcId() then
                local needScore = ruleConfig.Params[1]
                if score >= needScore then
                    bubbleId = ruleConfig.Bubble
                    break
                end
            end
        end
    end
    if self._Model:IsStoryUnlock(bubbleId) then
        XLog.Warning("[XTemple2GameControl] 已播放过剧情:", bubbleId)
        return false
    end
    return bubbleId
end

function XTemple2GameControl:UpdateGame(ui)
    local game = self:GetGame()
    game:Update(ui)
    if game:IsAnimationFinish() and not game:GetIsSettle() then
        local bubbleId = self:GetBubbleToPlayOnSettle()
        if bubbleId then
            game:SetTriggeredPlot(bubbleId)
        end
        local plotId = game:GetTriggeredPlot()
        local callback = function()
            if bubbleId then
                local bubbleConfig = self._Model:GetBubble(bubbleId)
                if bubbleConfig then
                    if bubbleConfig.StoryId then
                        XMVCA.XTemple2:PlayMovie(bubbleConfig.StoryId)
                    end
                end
            end
        end
        XMVCA.XTemple2:Temple2SettleRequest(self._SelectedStageId, self._UiData.Score.Total, plotId, callback, self:GetJsonRecord())
        game:SetIsSettle()
    end

    self._Chat:Update()
end

-- 埋点用
---@param game XTemple2Game
function XTemple2GameControl:GetJsonRecord()
    local game = self:GetGame()
    local score4Rule = game:GetScore4Rule()
    local totalScoreDict = game:GetTotalScoreDict()

    local blockAmountDict = {}
    local blockScoreDict = {}
    local map = game:GetMap()
    local row = map:GetRowAmount()
    local column = map:GetColumnAmount()
    for x = 1, column do
        for y = 1, row do
            local grid = map:GetGrid(x, y)
            if grid:IsValid() then
                local id = tostring(grid:GetId())
                if grid:GetOperationUid() > 0 then
                    blockAmountDict[id] = blockAmountDict[id] or 0
                    blockAmountDict[id] = blockAmountDict[id] + 1
                end
                blockScoreDict[id] = blockScoreDict[id] or 0
                local taskScore = grid:GetTaskScore() or 0
                local ruleScore = grid:GetRuleScore() or 0
                blockScoreDict[id] = blockScoreDict[id] + taskScore + ruleScore
            end
        end
    end

    local path = game:GetPath()
    local pathLength = #path

    local score4RuleToString = {}
    for i, v in pairs(score4Rule) do
        score4RuleToString[tostring(i)] = v
    end

    local totalScoreDictToString = {}
    for i, v in pairs(totalScoreDict) do
        totalScoreDictToString[tostring(i)] = v
    end

    local result = {
        ScoreDetail = totalScoreDict,
        RuleScore = score4RuleToString,
        BlockAmount = blockAmountDict,
        BlockScore = blockScoreDict,
        PathLength = pathLength,
    }
    local Json = require("XCommon/Json")
    local str = Json.encode(result)
    return str
end

function XTemple2GameControl:UpdateGameReplay(ui)
    local game = self:GetGame()
    game:Update(ui)
    if game:IsAnimationFinish() and not game:GetIsSettle() then
        game:SetIsSettle()
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_SETTLE)
    end
end

function XTemple2GameControl:IsModeScore()
    return self._IsModeScore
end

function XTemple2GameControl:SetModeScore(value)
    self._IsModeScore = value
    XSaveTool.SaveData(XTemple2Enum.SAVE_KEY_MODE_SCORE .. XPlayer.Id, value)
end

function XTemple2GameControl:SetNextTimeScale()
    if CS.UnityEngine.Time.timeScale == 1 then
        self:SetTimeScale(2)
        return
    end
    if CS.UnityEngine.Time.timeScale == 2 then
        self:SetTimeScale(4)
        return
    end
    if CS.UnityEngine.Time.timeScale == 4 then
        self:SetTimeScale(1)
        return
    end
    self:SetTimeScale(1)
end

function XTemple2GameControl:SetTimeScale(value)
    CS.UnityEngine.Time.timeScale = value
    XSaveTool.SaveData("XTemple2GameSpeed" .. XPlayer.Id, value)
end

function XTemple2GameControl:GetText4StartBtn()
    local game = self:GetGame()
    if game:GetIsSettle() then
        return XUiHelper.GetText("Temple2End")
    end
    if game:IsCanStart() then
        return XUiHelper.GetText("Temple2Start")
    end
    return "X" .. math.floor(CS.UnityEngine.Time.timeScale)
end

function XTemple2GameControl:SetPositionOfBlock2EditMap(x, y)
    local block = self._Block2EditMap
    if block then
        return block:SetPositionXY(x, y)
    end
    return false
end

function XTemple2GameControl:IsSelectBlock()
    if self._Block2EditMap then
        return true
    end
    return false
end

---@param block XTemple2Block
function XTemple2GameControl:IsEditingBlock(block)
    return self._Block2EditMap:Equals(block)
end

function XTemple2GameControl:ClampBlockPosition(x, y)
    local block = self._Block2EditMap
    if not block then
        return x, y
    end
    return self:GetGame():ClampBlockPosition(block, x, y)
end

function XTemple2GameControl:GetChat()
    if self:GetGame():IsCanStart() then
        return self._Chat:GetChat()
    end
    return false
end

function XTemple2GameControl:UpdateScorePreview()
    local block = self._Block2EditMap
    if not block then
        return false
    end
    local game = self:GetGame()
    local gamePreview = self:GetGamePreview()
    gamePreview:CloneMap(game)
    local isSuccess = gamePreview:InsertBlock(block)
    gamePreview:UpdatePathAndScore()
    if not isSuccess then
        self._IsGamePreviewInsertBlock = false
        return false
    end
    self._IsGamePreviewInsertBlock = true
end

function XTemple2GameControl:GetScorePreview()
    local block = self._Block2EditMap
    if not block then
        return false
    end
    if not self._IsGamePreviewInsertBlock then
        return false
    end
    local data = {}
    local game = self:GetGame()
    local gamePreview = self:GetGamePreview()
    local score4RulePreview = gamePreview:GetScore4Rule()
    local score4Rule = game:GetScore4Rule()
    -- 填0
    for ruleId, score in pairs(score4Rule) do
        if not score4RulePreview[ruleId] then
            score4RulePreview[ruleId] = 0
        end
    end
    for ruleId, scorePreview in pairs(score4RulePreview) do
        local score = score4Rule[ruleId] or 0
        local scoreDiff = scorePreview - score
        if scoreDiff ~= 0 then
            local rule = game:GetRule(ruleId)
            if rule then
                ---@class XUiTemple2CheckBoardScorePreviewData
                local scoreData = {
                    Name = rule:GetName(),
                    Score = scoreDiff,
                    Id = rule:GetId(),
                    Icon2Instantiate = rule:GetIconRule(),
                    ColorIndex = block:GetColor()
                }
                data[#data + 1] = scoreData
            end
        end
    end
    table.sort(data, function(a, b)
        return a.Id < b.Id
    end)

    -- 寻路
    local pathScorePreview = gamePreview:GetScore(SCORE_TYPE.PATH_SCORE)
    local pathScore = game:GetScore(SCORE_TYPE.PATH_SCORE)
    local diffPathScore = pathScorePreview - pathScore
    if diffPathScore ~= 0 then
        local scoreData = {
            Name = XUiHelper.GetText("Temple2Path"),
            Score = diffPathScore,
            Id = 0,
        }
        table.insert(data, 1, scoreData)
    end

    -- 基础格子分
    local baseGridScorePreview = gamePreview:GetScore(SCORE_TYPE.BASE_GIRD_SCORE)
    local baseGridScore = game:GetScore(SCORE_TYPE.BASE_GIRD_SCORE)
    local diffBaseGridScore = baseGridScorePreview - baseGridScore
    if diffBaseGridScore ~= 0 then
        local scoreData = {
            Name = XUiHelper.GetText("Temple2Grid"),
            Score = diffBaseGridScore,
            Id = 0,
        }
        table.insert(data, 1, scoreData)
    end

    return data
end

function XTemple2GameControl:Replay()
    local stageId = self._SelectedStageId
    if not stageId then
        XLog.Error("[XTemple2GameControl] 未设置当前关卡")
        return
    end
    local npcId = self:GetGame():GetNpcId()
    if not npcId then
        XLog.Error("[XTemple2GameControl] 未设置当前角色")
        return
    end
    local startType = XTemple2Enum.START_TYPE.LAST
    XMVCA.XTemple2:Temple2StartRequest(stageId, npcId, startType, function()
        self._MainControl:OpenGame(stageId, npcId, true)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_AFTER_REPLAY)
    end)
end

function XTemple2GameControl:GetCharacterIcon()
    local npcId = self:GetGame():GetNpcId()
    ---@type XTable.XTableTemple2Npc
    local config = self._Model:GetCharacter(npcId)
    if config then
        return config.Icon
    end
end

function XTemple2GameControl:IsShowRotationIcon()
    if self._Block2EditMap then
        if self._Block2EditMap:GetNoRotate() == 1 then
            return false
        end
    end
    return true
end

---@param gridData XUiTemple2CheckBoardGridData[]
function XTemple2GameControl:GetDataGrids4BlockOption(gridData, grids)
    self:GetDataGrids(gridData, grids, XTemple2Enum.BLOCK_SIZE.X, XTemple2Enum.BLOCK_SIZE.Y, nil, nil, true)
    local gridAmount = 0
    for i = 1, #gridData do
        local data = gridData[i]
        if not data.IsEmpty then
            local gridId = data.Id
            local config = self._Model:GetGrid(gridId)
            if config and config.ShowOnStageDetail == 1 then
                gridAmount = gridAmount + 1
            end
        end
    end
    -- 在只有1到2个图片的情况下，把图片居中
    if gridAmount == 1 or gridAmount == 2 then
        for i = #gridData, 1, -1 do
            local data = gridData[i]
            if data.IsEmpty then
                table.remove(gridData, i)
            else
                local gridId = data.Id
                local config = self._Model:GetGrid(gridId)
                if config and config.ShowOnStageDetail ~= 1 then
                    table.remove(gridData, i)
                end
            end
        end
    end
end

function XTemple2GameControl:GetCharacterSettleDesc()
    local npcId = self:GetGame():GetNpcId()
    if npcId then
        ---@type XTable.XTableTemple2Npc
        local npcConfig = self._Model:GetCharacter(npcId)
        if npcConfig then
            return npcConfig.SettleDesc
        end
    end
    return ""
end

return XTemple2GameControl