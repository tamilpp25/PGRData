local XTempleConfigControl = require("XModule/XTemple/XTempleConfigControl")
local XTempleAction = require("XEntity/XTemple/Action/XTempleAction")
local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local ACTION = XTempleEnumConst.ACTION
local TIME_OF_DAY = XTempleEnumConst.TIME_OF_DAY
local GRID = XTempleEnumConst.GRID

---@class XTempleGameControl:XTempleConfigControl
---@field private _Model XTempleModel
---@field private _MainControl XTempleControl
local XTempleGameControl = XClass(XTempleConfigControl, "XTempleGameControl")

function XTempleGameControl:Ctor()
    --todo by zlb
    self._GridWidth = 80
    self._GridHeight = 80

    ---@type XTempleGame
    self._Game = nil

    --以下全为数据, 非Entity
    self._Rule = {}

    self._Grids = {}

    ---@type XTempleUiDataBlockOption[]
    self._BlockOption2Select = {}

    self._Operation = {}

    self._Progress = {
        Score = 0,
        RoundData = {},
        Star = 0,
        TimeOfDayData = {}
    }

    ---@type XTempleMap
    self._PreviewMap = nil

    ---@type XTempleMap
    self._PreviewMap2 = nil

    --self._IsNewRotation = true
end

function XTempleGameControl:OnInit()
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_REQUEST_ACTION, self._RequestAction, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_SETTLE, self._OnGameSettle, self)
end

function XTempleGameControl:OnRelease()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_REQUEST_ACTION, self._RequestAction, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_SETTLE, self._OnGameSettle, self)
    self:ClearGame()
end

function XTempleGameControl:InitGame()
    self:ClearGame()
    local XTempleGame = require("XEntity/XTemple/XTempleGame")
    self._Game = self:AddEntity(XTempleGame)
end

function XTempleGameControl:IsGameExist()
    return self._Game and true or false
end

function XTempleGameControl:StartGame(stageId)
    self._StageId = stageId
    self:InitGame()
    local gameConfig = self._Model:GetStageGameConfig(stageId)
    self._Game:InitFromGameConfig(gameConfig)
    self._Game:Start()

    if not self._Game:IsEditor() then
        self:LoadActionRecord2Continue()
    end
end

function XTempleGameControl:RestartGame()
    self:StartGame(self._StageId)
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
end

function XTempleGameControl:OnClickRestartGame()
    if not self._Game:IsEditor() then
        XMVCA.XTemple:RequestRestart(function()
            self:RestartGame()
        end)
        return
    end
    self:RestartGame()
end

local function SortRule(a, b)
    if a.IsActive ~= b.IsActive then
        return a.IsActive
    end
    if a.IsExpire ~= b.IsExpire then
        return b.IsExpire
    end
    return a.Id < b.Id
end

function XTempleGameControl:_UpdateRule(includeHideRule)
    self._Rule = {}
    local rules = self._Game:GetPublicRules()
    local time = self._Game:GetCurrentTime()
    for i = 1, #rules do
        local rule = rules[i]
        if self._Game:IsEditor() or not rule:GetIsHide() or includeHideRule then
            local ruleType = rule:GetType()
            local blockId = self._Model:GetRuleBlockId(ruleType)

            ---@class XTempleGameUiDataRule
            local data = {
                Id = rule:GetId(),
                Text = rule:GetText(),
                IsActive = rule:IsActive(),
                Score = rule:GetScore(),
                Name = rule:GetName(),
                Time = rule:GetTextTimeOfDay(time),
                Block = self._Game:GetMap():GetBlockById(blockId),
                Bg = self._Model:GetRuleBg(i),
                TextColor = self._Model:GetRuleBgTextColor(i),
                IsExpire = rule:IsExpire(time),
                UiName = "TempleRule_" .. i
            }
            self._Rule[#self._Rule + 1] = data
        end
    end
    if not self._MainControl:IsEditor() then
        table.sort(self._Rule, SortRule)
    end

    if includeHideRule then
        for i = 1, #self._Rule do
            local timeData = self._Rule[i].Time
            if timeData then
                for j = 1, #timeData do
                    timeData[j].IsActive = true
                end
            end
        end
    end
end

function XTempleGameControl:OnClickRotate()
    ---@type XTempleAction
    local action = XTempleAction.New()
    action:SetData({
        Type = ACTION.ROTATE,
    })
    self._Game:EnqueueAction(action)
end

function XTempleGameControl:OnClickConfirm()
    ---@type XTempleAction
    local action = XTempleAction.New()
    action:SetData({
        Type = ACTION.CONFIRM,
    })
    self._Game:EnqueueAction(action)
end

function XTempleGameControl:OnClickCancel()
    if self._MainControl:IsCoupleChapter() then
        self:Skip()
        return
    end

    ---@type XTempleAction
    local action = XTempleAction.New()
    action:SetData({
        Type = ACTION.CANCEL,
    })
    self._Game:EnqueueAction(action)
end

function XTempleGameControl:GetRule(includeHideRule, isDirty)
    if isDirty ~= false then
        self:_UpdateRule(includeHideRule)
    end
    return self._Rule
end

function XTempleGameControl:IsShowOperation()
    if self._Game:IsEditingBlock() then
        return true
    end
    return false
end

function XTempleGameControl:IsShowSkip()
    local options = self._Game:GetCurrentOptions()
    if not options then
        return false
    end
    local option = options[1]
    if not option then
        return false
    end
    if option:IsSkip() then
        return true
    end
    return false
end

function XTempleGameControl:UpdateGrids()
    local map = self._Game:GetMap()
    local x = map:GetColumnAmount()
    local y = map:GetRowAmount()
    self._Grids = {}
    for j = 1, y do
        for i = 1, x do
            local grid = map:GetGrid(i, j)
            if grid then
                local icon = grid:GetFusionIcon(map)
                ---@class XTempleUiDataGrid
                local t = {
                    Icon = icon,
                    Rotation = grid:GetRotation(),
                    Hide = false,
                    X = i,
                    Y = j,
                    Score = grid:GetScore(),
                    UiName = "TempleGrid_" .. i .. "_" .. j,
                    Red = false,
                }
                self._Grids[#self._Grids + 1] = t
            end
        end
    end
end

function XTempleGameControl:GetGrids()
    self:UpdateGrids()
    return self._Grids
end

---@param block XTempleBlock
---@param option XTempleOption
function XTempleGameControl:GetBlock4UiOption(block, option)
    if not block then
        return {
            Time = 0,
            Score = 0,
            Grids = {},
            ConstraintCount = 0,
            BlockId = 0,
            BlockName = "",
        }
    end
    local grids = {}
    local x = block:GetColumnAmount()
    local y = block:GetRowAmount()
    for j = 1, y do
        for i = 1, x do
            local grid = block:GetGrid(i, j)
            if grid and not grid:IsEmpty() then
                ---@type XTempleUiDataGrid
                local t = {
                    Icon = grid:GetIcon(),
                    Rotation = grid:GetRotation(),
                    Hide = grid:IsEmpty(),
                }
                grids[#grids + 1] = t
            else
                ---@type XTempleUiDataGrid
                local t = {
                    Icon = false,
                    Hide = true
                }
                grids[#grids + 1] = t
            end
        end
    end
    ---@class XTempleUiDataBlockOption
    local t = {
        Time = option and option:GetSpend() or 0,
        Score = option and option:GetScore(self._Game:GetCurrentTime()) or 0,
        Grids = grids,
        ConstraintCount = x,
        BlockId = block:GetId(),
        Name = block:GetName(),
    }
    return t
end

function XTempleGameControl:UpdateBlockOption()
    self._BlockOption2Select = {}
    ---@type XTempleOption[]
    local options = self._Game:GetCurrentOptions()
    if options then
        for k = 1, #options do
            local option = options[k]
            local blockId = option:GetBlockId()
            local block = self._Game:GetMap():GetBlockById(blockId)
            if blockId >= 0 then
                local dataBlockOption = self:GetBlock4UiOption(block, option)
                self._BlockOption2Select[#self._BlockOption2Select + 1] = dataBlockOption
            end
        end
    end
end

function XTempleGameControl:GetBlockOption()
    self:UpdateBlockOption()
    return self._BlockOption2Select
end

---@param block XTempleBlock
---@param option XTempleOption
function XTempleGameControl:SelectBlockOption(block, option)
    if block then
        ---@type XTempleAction
        local action = XTempleAction.New()
        action:SetData({
            Type = ACTION.PUT_DOWN,
            BlockId = block:GetId(),
            OptionId = option and option:GetId()
        })
        self._Game:EnqueueAction(action)
    end
end

function XTempleGameControl:OnClickBlockOption(index)
    ---@type XTempleOption[]
    local options = self._Game:GetCurrentOptionsExceptSkip()
    local option = options[index]
    local block = self._Game:GetMap():GetBlockById(option:GetBlockId())
    self:SelectBlockOption(block, option)
end

--todo by zlb repeat
function XTempleGameControl:UpdateBlockOperation()
    local block = self._Game:GetEditingBlock()

    ---@type XLuaVector2
    local operationPosition = XLuaVector2.New()
    local position = block:GetPosition()
    local blockX = block:GetColumnAmount()
    local blockY = block:GetRowAmount()
    local blockCenterX = blockX / 2
    local blockCenterY = blockY / 2
    local anchorPosition = block:GetAnchorPosition()
    local x2Block = anchorPosition.x - blockCenterX
    local y2Block = anchorPosition.y - blockCenterY

    local gridWidth = self._GridWidth
    local gridHeight = self._GridHeight
    local map = self._Game:GetMap()
    local centerX = map:GetColumnAmount() / 2
    local centerY = map:GetRowAmount() / 2
    local xOnMap = position.x - centerX
    local yOnMap = position.y - centerY
    local x = (xOnMap - x2Block) * gridWidth
    local y = (yOnMap - y2Block) * gridHeight
    operationPosition:Update(x, y)

    local isRed = false
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

    local grids = {}
    for j = 1, yAmount do
        for i = 1, xAmount do
            local grid = block:GetGrid(i, j)
            if grid and not grid:IsEmpty() then
                ---@type XTempleUiDataGrid
                local t = {
                    Icon = grid:GetIcon(),
                    Rotation = grid:GetRotation(),
                    Hide = grid:IsEmpty(),
                    Red = isRed,
                }
                grids[#grids + 1] = t
            else
                ---@type XTempleUiDataGrid
                local t = {
                    Icon = false,
                    Rotation = 0,
                    Hide = true,
                    Red = false,
                }
                grids[#grids + 1] = t
            end
        end
    end

    ---@class XTempleUiDataOperation
    local t = {
        Grids = grids,
        ConstraintCount = xAmount,
        Position = operationPosition,
        IsRed = isRed
    }
    self._Operation = t
end

function XTempleGameControl:GetBlockOperation()
    self:UpdateBlockOperation()
    return self._Operation
end

function XTempleGameControl:SetBlockOperationPosition(x, y)
    local gridWidth = self._GridWidth
    local gridHeight = self._GridHeight
    x = x / gridWidth
    y = y / gridHeight

    local block = self._Game:GetEditingBlock()
    local blockX = block:GetColumnAmount()
    local blockY = block:GetRowAmount()
    local blockCenterX = blockX / 2
    local blockCenterY = blockY / 2
    local anchorPosition = block:GetAnchorPosition()
    local x2Block = anchorPosition.x - blockCenterX
    local y2Block = anchorPosition.y - blockCenterY

    local offsetX = x - x2Block
    local offsetY = y - y2Block
    local position = block:GetPosition()
    local xOnMap = position.x + offsetX
    local yOnMap = position.y + offsetY

    --local toLeft = anchorPosition.x
    --local toDown = anchorPosition.y
    --local toRight = map:GetColumnAmount() - (block:GetColumnAmount() - anchorPosition.x)
    --local toUp = map:GetRowAmount() - (block:GetRowAmount() - anchorPosition.y)
    --
    --xOnMap = XMath.Clamp(xOnMap, toLeft, toRight)
    --yOnMap = XMath.Clamp(yOnMap, toDown, toUp)
    xOnMap, yOnMap = self._Game:ClampBlockPosition(block, xOnMap, yOnMap)

    xOnMap = XMath.ToInt(xOnMap)
    yOnMap = XMath.ToInt(yOnMap)
    self:OnClickDrag(xOnMap, yOnMap)
end

function XTempleGameControl:Skip()
    ---@type XTempleAction
    local action = XTempleAction.New()
    action:SetData({
        Type = ACTION.SKIP,
    })
    self._Game:EnqueueAction(action)
end

function XTempleGameControl:UpdateProgress()
    local isFinish = false
    ---@type XTempleTimeOfDay
    local time = self._Game:GetCurrentTime()
    if not time then
        isFinish = true
        time = self._Game:GetTailTime()
        if not time then
            return
        end
    end
    local timeOfDayData = {}
    local timeArray = self._Game:GetTimeArray()
    for i = 1, #timeArray do
        local timeOfDay = timeArray[i]
        local type = timeOfDay:GetType()
        ---@class XTempleUiDataTimeWithScore
        local data = {
            Name = self:GetTimeOfDayName(type),
            Score = self._Game:GetScore(type),
            IsActive = time:IsTimeActive(timeOfDay:GetBinCode()),
            UiName = "TempleRound_" .. i
        }
        timeOfDayData[i] = data
    end
    local timeDuration = time:GetDuration()
    local spendTime
    if isFinish then
        spendTime = time:GetDuration()
    else
        spendTime = self._Game:GetSpendTime()
    end
    local star = 0
    local roundData = {}
    for i = 1, timeDuration do
        ---@class XTempleUiDataSmallRound
        local data = {
            IsActive = i <= spendTime,
        }
        roundData[i] = data
    end
    local t = {
        Score = self:GetRealTimeScore(),
        --Round = round,
        --TotalRound = totalRoundOfThisTime,
        RoundData = roundData,
        Star = star,
        TimeOfDayData = timeOfDayData,
    }
    self._Progress = t
end

function XTempleGameControl:GetProgress()
    self:UpdateProgress()
    return self._Progress
end

function XTempleGameControl:GetTimeArray()
    return self._Game:GetTimeArray()
end

function XTempleGameControl:GetMaxTime()
    return TIME_OF_DAY.END - 1
end

function XTempleGameControl:OnClickDrag(x, y)
    ---@type XTempleAction
    local action = XTempleAction.New()
    action:SetData({
        Type = ACTION.DRAG,
        Position = XLuaVector2.New(x, y)
    })
    self._Game:EnqueueAction(action)
end

-- 注意事项, 配置生成数组时, 中间为空项会被跳过, 必须填值
function XTempleGameControl:GenerateGrids(map)
    local grids = {}
    for y = 1, #map do
        local list = map[y]
        local countX = #list
        for x = 1, countX do
            local encodeInfo = list[x]
            ---@type XTempleGrid
            local grid = self._Game:AddGrid()
            grids[x] = grids[x] or {}
            grids[x][y] = grid
            grid:SetEncodeInfo(encodeInfo)
            grid:SetPosition(x, y)

            -- 向前遍历, 填满空格
            for i = y - 1, 1, -1 do
                if grids[x][i] == nil then
                    local emptyGrid = self:AddGrid()
                    grids[x][i] = emptyGrid
                    emptyGrid:SetType(GRID.EMPTY)
                    emptyGrid:SetPosition(x, i)
                else
                    break
                end
            end
        end
    end
    return grids
end

function XTempleGameControl:GetGridType(gridId)
    return self._Model:GetGridType(gridId)
end

function XTempleGameControl:IsShowPreviewScore()
    return self._Game:IsEditingBlock()
end

function XTempleGameControl:GetPreviewScore()
    if not self._PreviewMap then
        local XTempleMap = require("XEntity/XTemple/Grid/XTempleMap")
        self._PreviewMap = self:AddEntity(XTempleMap)
    end
    if not self._PreviewMap2 then
        local XTempleMap = require("XEntity/XTemple/Grid/XTempleMap")
        self._PreviewMap2 = self:AddEntity(XTempleMap)
    end
    local editingBlock = self._Game:GetEditingBlock()

    self._PreviewMap:CloneFrom(self._Game:GetMap())
    if not self._PreviewMap:InsertBlock(editingBlock) then
        return {}
    end
    self._PreviewMap2:CloneFrom(self._Game:GetMap())

    local data = {}

    local rules = self._Game:GetPublicRules()
    for i = 1, #rules do
        local rule = rules[i]
        local oldScore = rule:Execute(self._PreviewMap2, self._Game:GetCurrentTime(), true)
        local score = rule:Execute(self._PreviewMap, self._Game:GetCurrentTime(), true)
        local diffScore = score - oldScore
        if diffScore ~= 0 then
            ---@class XTempleGameControlPreviewScore
            local t = {
                Name = rule:GetName(),
                Score = diffScore
            }
            data[#data + 1] = t
        end
    end

    return data
end

function XTempleGameControl:IsLockUpdateUi()
    return self._Game:IsSimulating()
end

function XTempleGameControl:GetStageName()
    local stageId = self._StageId
    local name = self._Model:GetStageName(stageId)
    return name
end

function XTempleGameControl:GetCurrentScore4Settle()
    if self._MainControl:IsCoupleChapter() then
        return self:GetRealTimeScore()
    end
    return self._Game:GetScore()
end

function XTempleGameControl:GetRealTimeScore()
    return self._Game:GetRealTimeScore()
end

function XTempleGameControl:RestartAfterSettle(callback)
    self._MainControl:OpenNewGame(self._StageId, callback)
end

function XTempleGameControl:GetDataSettleStar()
    local score = self:GetCurrentScore4Settle()
    return self:GetDataStar(score)
end

function XTempleGameControl:GetDataStar(score)
    score = score or self:GetStageBestScore()
    local data = {}
    local star = self._Model:GetStarByScore(self._StageId, score)
    local starConfig = self._Model:GetStageStarConfig(self._StageId)
    for i = 1, #starConfig do
        local starScore = starConfig[i]
        ---@class XTempleGameControlSettleStar
        local t = {
            Text = XUiHelper.GetText("TempleScore", starScore),
            IsOn = star >= i
        }
        data[i] = t
    end
    return data
end

function XTempleGameControl:GetCurrentStar()
    local score = self:GetRealTimeScore()
    local star = self._Model:GetStarByScore(self._StageId, score)
    return star
end

-- 星星是均等分，导致进度条不均等
local function GetProgressValue(starArray, score)
    local amount = 3
    local progress = 0
    local scoreEachPart = 0.333
    local lastStar = 0
    for i = 1, amount do
        local star = starArray[i]
        if score > star then
            progress = progress + scoreEachPart
        else
            local diff = score - lastStar
            if diff > 0 then
                progress = progress + diff / (star - lastStar) * scoreEachPart
            end
        end
        lastStar = star
    end
    return progress
end

function XTempleGameControl:GetStarFillAmount()
    local score = self:GetRealTimeScore()
    local starArray = self._Model:GetStageStarArray(self:GetStageId())
    local fillAmount = GetProgressValue(starArray, score)
    fillAmount = XMath.Clamp(fillAmount, 0, 1)
    return fillAmount
end

function XTempleGameControl:_RequestAction()
    if not self._Game then
        return
    end
    local game = self._Game
    if game:IsEditor() then
        return
    end
    local record = self._Game:GetLastestActionRecord()
    if not record then
        return
    end
    if not game:IsSimulating() then
        local score = self._Game:GetRealTimeScore()
        local scoreDetail = self._Game:GetRealTimeScoreDetail()

        local characterId = 0
        if self:IsCoupleChapter() then
            characterId = self:GetCurrentCharacterId()
        end
        XMVCA.XTemple:RequestOperation(record, score, scoreDetail, characterId)
    end
end

function XTempleGameControl:_OnGameSettle()
    if self._Game:IsEditor() then
        return
    end
    local score = self:GetCurrentScore4Settle()
    local picData = self._Game:GetEncodeMap()
    local characterId = self:GetCurrentCharacterId()
    XMVCA.XTemple:RequestSuccess(score, picData, characterId, function()
        XLuaUiManager.Open("UiTempleSettlement")
        local uiName = self._MainControl:GetGameUiName(self._StageId)
        XLuaUiManager.SafeClose(uiName)
    end)
end

function XTempleGameControl:GetCurrentCharacterId()
    local characterId = self._Model:GetNpcId(self._StageId)
    return characterId
end

function XTempleGameControl:LeaveGameUi()
    if self._Game then
        if not self._Game:IsEditor() and self._Game:IsPlaying() then
            self._Model:SaveStageDataFromClient(self._StageId, self._Game)
        end
        self:ClearGame()
    end
end

function XTempleGameControl:LoadActionRecord2Continue()
    local activityData = self._Model:GetActivityData()
    if activityData and activityData:HasStage2Continue(self._MainControl:GetChapter()) then
        local data = activityData:GetStage2Continue(self._MainControl:GetChapter())
        if self._StageId == data.StageId then
            local actionRecord = data.OperatorRecords
            local game = self._Game
            game:SetActionRecords(actionRecord)
            game:SimulateActionRecord()
        end
    end
end

function XTempleGameControl:ClearGame()
    if self._Game then
        self._Game:Stop()
        self._Game = nil
    end
end

function XTempleGameControl:IsCoupleChapter()
    return false
end

function XTempleGameControl:GetStageDesc()
    return self._Model:GetStageDesc(self._StageId)
end

function XTempleGameControl:GetStageBestScore()
    return self._Model:GetStageScore(self._StageId)
end

function XTempleGameControl:GetStageDetailBg()
    return self._Model:GetStageDetailBg(self._StageId)
end

function XTempleGameControl:GetStageEnterText()
    return self._Model:GetTalkByStageId(self._StageId, XTempleEnumConst.NPC_TALK.STAGE_ENTER, self:IsCoupleChapter())
end

function XTempleGameControl:GetStageId()
    return self._StageId
end

---@param block XTempleBlock
function XTempleGameControl:GetBlockGrids4Rule(block, ruleId)
    if not block then
        return {}
    end
    local rule = self._Game:GetRuleById(ruleId)
    local grids = {}
    local x = block:GetColumnAmount()
    local y = block:GetRowAmount()
    for j = 1, y do
        for i = 1, x do
            local grid = block:GetGrid(i, j)
            if grid then
                -- 取巧的
                local index = grid:GetId()
                local paramsGridId = rule:GetParamsGridId(index)
                if paramsGridId == nil then
                    paramsGridId = index
                end

                ---@type XTempleUiDataGrid
                local t = {
                    Icon = self._Model:GetGridIcon(paramsGridId),
                    Rotation = grid:GetRotation(),
                    --Hide = grid:IsEmpty(),
                    Hide = false
                }
                grids[#grids + 1] = t
            else
                ---@type XTempleUiDataGrid
                local t = {
                    Icon = self._Model:GetGridIcon(XTempleEnumConst.GRID.EMPTY),
                    Hide = false
                }
                grids[#grids + 1] = t
            end
        end
    end
    return grids
end

function XTempleGameControl:GetTalkData(type)
    if not self._Game then
        return
    end
    if self._Game:IsSimulating() then
        return
    end
    if self._Game:IsEditor() then
        return
    end
    local text, body = self._Model:GetTalkByStageId(self._StageId, type, self:IsCoupleChapter())
    local data = {
        Text = text,
        ImageCharacter = body,
    }
    return data
end

function XTempleGameControl:GetGridRuleText(gridX, gridY)
    local grid = self._Game:GetMap():GetGrid(gridX, gridY)
    if grid and grid:GetScore() ~= 0 then
        local rule = grid:GetRule()
        if rule then
            local text = rule:GetName() .. "\n" .. rule:GetText()
            return text
        end
    end
    return false
end

function XTempleGameControl:IsCanQuickPass()
    return self._Model:IsCanQuickPass(self._StageId)
end

function XTempleGameControl:QuickPass()
    self._Game:SetEnd()
end

function XTempleGameControl:IsChallengeSuccess()
    local score = self:GetCurrentScore4Settle()
    local star = self._Model:GetStarByScore(self._StageId, score)
    return star > 0
end

function XTempleGameControl:GetTextSettlement()
    local isCouple = self:IsCoupleChapter()
    if isCouple then
        local npcId = self:GetCurrentCharacterId()
        return self._Model:GetTalkText(npcId, XTempleEnumConst.NPC_TALK.SUCCESS, isCouple)
    end

    local npcIndex = self._Model:GetNpcIndex(self:GetStageId())
    if self:IsChallengeSuccess() then
        return self._Model:GetTalkText(npcIndex, XTempleEnumConst.NPC_TALK.SUCCESS, isCouple)
    end
    return self._Model:GetTalkText(npcIndex, XTempleEnumConst.NPC_TALK.FAIL, isCouple)
end

function XTempleGameControl:GetChapterId(stageId)
    return self._Model:GetChapterId(stageId)
end

function XTempleGameControl:GetStageBg()
    return self._Model:GetStageBg(self._StageId)
end

function XTempleGameControl:SaturationInit()
    if not self._Game then
        self:StartGame(self._StageId)
    end
end

function XTempleGameControl:GetTimePromptText(time)
    return self._Model:GetTimeText(time)
end

function XTempleGameControl:GetTimePromptBg()
    local time = self._Game:GetCurrentTime()
    if time then
        return self._Model:GetTimeBg(time:GetType())
    end
    return false
end

function XTempleGameControl:GetTimeIndex()
    local time = self._Game:GetCurrentTime()
    if time then
        local timeArray = self._Game:GetTimeArray()
        for i = 1, #timeArray do
            if timeArray[i] == time then
                return i
            end
        end
    end
    return 1
end

--function XTempleGameControl:IsNewRotation()
--    return self._IsNewRotation
--end

function XTempleGameControl:IsPlayMusicChangeTime()
    if self._Game:IsEditor() then
        return false
    end
    local currentTime = self._Game:GetCurrentTime()
    if currentTime and currentTime:GetType() > 1 then
        return true
    end
    return false
end

function XTempleGameControl:PlayMusicChangeTime()
    XSoundManager.PlaySoundByType(self._Model:GetMusicChangeTime(), XSoundManager.SoundType.Sound)
end

function XTempleGameControl:PlayMusicSettle()
    XSoundManager.PlaySoundByType(self._Model:GetMusicSuccess(), XSoundManager.SoundType.Sound)
end

function XTempleGameControl:PlayMusicInsertFail()
    XSoundManager.PlaySoundByType(self._Model:GetMusicFail(), XSoundManager.SoundType.Sound)
end

function XTempleGameControl:PlayMusicScore(score)
    if score <= 0 then
        return
    end
    XSoundManager.PlaySoundByType(self._Model:GetMusicScore(score), XSoundManager.SoundType.Sound)
end

return XTempleGameControl
