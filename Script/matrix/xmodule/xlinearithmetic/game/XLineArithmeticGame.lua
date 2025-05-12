local XLineArithmeticAction = require("XModule/XLineArithmetic/Game/XLineArithmeticAction")
local XLineArithmeticEnum = require("XModule/XLineArithmetic/Game/XLineArithmeticEnum")
local XLineArithmeticGrid = require("XModule/XLineArithmetic/Game/XLineArithmeticGrid")
local XLineArithmeticEvent = require("XModule/XLineArithmetic/Game/XLineArithmeticEvent")
local XLineArithmeticAnimation = require("XModule/XLineArithmetic/Game/XLineArithmeticAnimation")

---@class XLineArithmeticGame
local XLineArithmeticGame = XClass(nil, "XLineArithmeticGame")

function XLineArithmeticGame:Ctor()
    ---@type XLineArithmeticGrid[][]
    self._Map = {}

    self._MapSize = { X = 0, Y = 0 }

    ---@type XLineArithmeticGrid[]
    self._LineCurrent = {}

    ---@type XQueue
    self._ActionList = XQueue.New()

    ---@type XQueue
    self._AnimationList = XQueue.New()

    self._AmountOfUnfinishedFinialGrids = 0
    self._TotalAmountOfFinalGrids = 0

    self._Record = {}
    self._EventExecuted = {}
    self._AllCondition = {}

    self._IncreaseUid = 0

    ---@type XLineArithmeticEvent[]
    self._EventOnValid = {}

    self._IsOnline = true
    self._StageId = 0

    self._IsRequestSettle = false

    self._GameStartTime = 0

    self._UseHelp = false

    self._IsSend = {}
end

---@param pos XLuaVector2
function XLineArithmeticGame:GetGrid(pos)
    local x = pos.x
    local y = pos.y
    local line = self._Map[y]
    if not line then
        return false
    end
    return line[x]
end

---@param pos XLuaVector2
function XLineArithmeticGame:OnClickPos(pos)
    ---@type XLineArithmeticAction
    local action = XLineArithmeticAction.New()
    action:SetData(XLineArithmeticEnum.ACTION.CLICK, pos)
    self:EnqueueAction(action)
end

function XLineArithmeticGame:OnClickDrag(pos)
    ---@type XLineArithmeticAction
    local action = XLineArithmeticAction.New()
    action:SetData(XLineArithmeticEnum.ACTION.DRAG, pos)
    self:EnqueueAction(action)
end

function XLineArithmeticGame:ConfirmAction()
    ---@type XLineArithmeticAction
    local action = XLineArithmeticAction.New()
    action:SetData(XLineArithmeticEnum.ACTION.CONFIRM)
    self:EnqueueAction(action)
end

function XLineArithmeticGame:EnqueueAction(action)
    self._ActionList:Enqueue(action)
end

---@param grid XLineArithmeticGrid
function XLineArithmeticGame:IsOnLine(grid)
    if not grid then
        return false
    end
    for i = 1, #self._LineCurrent do
        local gridOnLine = self._LineCurrent[i]
        if gridOnLine:Equals(grid) then
            return true, i
        end
    end
    return false
end

---@param grid XLineArithmeticGrid
function XLineArithmeticGame:AddGrid2Line(grid)
    self:AddGridEvent(grid)
    self._LineCurrent[#self._LineCurrent + 1] = grid
end

function XLineArithmeticGame:UpdateEventEffect()
    for i = 1, #self._EventOnValid do
        local event = self._EventOnValid[i]
        event:Do(self)
    end
end

function XLineArithmeticGame:AddGridEvent(grid)
    local event = self:GetEventByGrid(grid)
    if event then
        self._EventOnValid[#self._EventOnValid + 1] = event
    end
end

---@param event XLineArithmeticEvent
function XLineArithmeticGame:RemoveEvent(event)
    if event then
        event:UndoOnEventRemove(self)
        for i = #self._EventOnValid, 1, -1 do
            local eventOnValid = self._EventOnValid[i]
            if eventOnValid:Equals(event) then
                table.remove(self._EventOnValid, i)
            end
        end
    end
end

function XLineArithmeticGame:RemoveGridEvent(grid)
    local event = self:GetEventByGrid(grid)
    self:RemoveEvent(event)
end

function XLineArithmeticGame:RemoveGridOnLineFromIndex(index)
    -- todo by zlb 其实用事件会更好, 减少遍历次数
    -- 先undo事件, 再移除事件
    for i = 1, #self._EventOnValid do
        local event = self._EventOnValid[i]
        for i = #self._LineCurrent, index, -1 do
            local grid = self._LineCurrent[i]
            event:UndoOnGridRemoveFromLineCurrent(grid)
        end
    end
    -- 先移除事件, 再移除格子
    for i = #self._LineCurrent, index, -1 do
        local grid = self._LineCurrent[i]
        self:RemoveGridEvent(grid)
    end
    for i = #self._LineCurrent, index, -1 do
        table.remove(self._LineCurrent, i)
    end
end

---@param model XLineArithmeticModel
function XLineArithmeticGame:Update(model)
    ---@type XLineArithmeticAction
    local action = self._ActionList:Dequeue()
    if not action then
        return false
    end
    action:Execute(self, model)
    return true
end

function XLineArithmeticGame:GetTailGrid()
    return self._LineCurrent[#self._LineCurrent]
end

function XLineArithmeticGame:IsFinish()
    return self._AmountOfUnfinishedFinialGrids == 0
end

function XLineArithmeticGame:IsRequestSettle()
    return self._IsRequestSettle
end

function XLineArithmeticGame:IsFinishSomeFinalGrids()
    return self._AmountOfUnfinishedFinialGrids < self._TotalAmountOfFinalGrids
end

-- 检查游戏进度
---@param model XLineArithmeticModel
function XLineArithmeticGame:Execute(model)
    -- 结束
    if self:IsFinish() then
        return false
    end

    local tailGrid = self:GetTailGrid()
    if not tailGrid then
        return false
    end

    -- 更新事件
    self:UpdateEventEffect()

    -- 拆分
    if tailGrid:IsFinalGrid() or tailGrid:IsStayEventGrid() then
        return true
    end
    return false
end

---@param model XLineArithmeticModel
function XLineArithmeticGame:ExecuteEat(model)
    local tailGrid = self:GetTailGrid()
    if not tailGrid then
        return
    end

    -- 终点
    if tailGrid:IsFinalGrid() then
        self:EatFinalGrid(model, tailGrid)
        self:UpdateAmountOfUnfinishedFinalGrid()
        self:RequestOperation(model)
        return
    end

    if tailGrid:IsStayEventGrid() then
        -- 停留事件格 替换成 其他格子
        self:EatStayGrid(model, tailGrid)
        self:UpdateAmountOfUnfinishedFinalGrid()
        local changeGridId = tailGrid:GetParams()[1]
        local pos = tailGrid:GetPos()
        self:CreateGridByGridId(model, changeGridId, pos.x, pos.y)
        -- 创建格子后，再结算
        self:RequestOperation(model)
        return
    end
end

function XLineArithmeticGame:GetMap()
    return self._Map
end

---@return XLineArithmeticGrid[]
function XLineArithmeticGame:GetAllFinalGrids()
    local grids = {}
    for y, line in pairs(self._Map) do
        for x, grid in pairs(line) do
            if grid and grid:IsFinalGrid() then
                grids[#grids + 1] = grid
            end
        end
    end
    return grids
end

---@param model XLineArithmeticModel
function XLineArithmeticGame:MakeRecord(model)
    local gridsRecord = {}
    for i = 1, #self._LineCurrent do
        local grid = self._LineCurrent[i]
        local pos = grid:GetPos()
        local gridRecord = {
            X = math.floor(pos.x),
            Y = math.floor(pos.y)
        }
        gridsRecord[#gridsRecord + 1] = gridRecord
    end

    local startScore = -1
    if #self._LineCurrent > 0 then
        local tailGrid = self._LineCurrent[#self._LineCurrent]
        startScore = tailGrid:GetNumber4Ui()
    end

    local round = #self._Record + 1
    local record = {
        Round = round,
        Points = gridsRecord,
        StartScore = startScore,
        EatEventGrid = {}
    }
    self._Record[round] = record
    --XLog.Error(record)
    return record
end

---@param tailGrid XLineArithmeticGrid
function XLineArithmeticGame:MarkRecordGridScore(tailGrid)
    local lastRecord = self._Record[#self._Record]
    lastRecord.EndScore = tailGrid:GetNumber4Ui()
end

---@param model XLineArithmeticModel
---@param tailGrid XLineArithmeticGrid@停留格
function XLineArithmeticGame:EatStayGrid(model, tailGrid)
    local record = self:MakeRecord(model)

    ---@class XLineArithmeticAnimationDataEatStayGrid
    local animationData = {
        EatGrids = {},
        Grids = {},
        ---@type XLineArithmeticGameKeepGridData[]
        KeepGrids = {},
        AwakeGrids = {},
    }

    ---@type XLineArithmeticGrid[]
    local reverseLine = {}
    for i = #self._LineCurrent, 1, -1 do
        local grid = self._LineCurrent[i]
        reverseLine[#reverseLine + 1] = grid
    end

    local posList = {}
    for i = 1, #reverseLine do
        local grid = reverseLine[i]
        posList[i] = grid:GetPosClone()
        local uid = grid:GetUid()
        animationData.Grids[#animationData.Grids + 1] = uid
    end

    local map = self:GetMap()
    for y, line in pairs(map) do
        for x, grid in pairs(line) do
            if grid then
                -- 将未完成的格子改回清醒状态
                if grid:IsFinalGrid() and not grid:IsFinish() and (not self:IsOnLine(grid)) then
                    local uid = grid:GetUid()
                    animationData.AwakeGrids[#animationData.AwakeGrids + 1] = {
                        Uid = uid,
                        Icon = grid:GetIconAwake(),
                        IsSleep = false,
                        IsAwake = false,
                    }
                end
            end
        end
    end

    local savePos = 2

    for i = 2, #reverseLine do
        local grid = reverseLine[i]
        local uid = grid:GetUid()

        if grid:IsNumberGrid() then
            local pos = grid:GetPos()
            self:SetGridByPos(false, pos)
            animationData.EatGrids[#animationData.EatGrids + 1] = uid

        elseif grid:IsEventGrid() then
            -- 移除事件, 保留事件格
            local event = self:GetEventByGrid(grid)
            event:UndoOnEventRemove(self)
            self:RemoveEvent(event)
            ---@type XLineArithmeticGameKeepGridData
            local keepGridData = {
                Uid = uid,
                PosIndex = i
            }
            animationData.KeepGrids[#animationData.KeepGrids + 1] = keepGridData
            savePos = savePos + 1
        else
            XLog.Error("[XLineArithmeticGame] 未定义的情况, 有问题")
            savePos = savePos + 1
        end

        -- 将后面的格子前移
        table.remove(posList, #posList)

        for j = savePos, #posList do
            local gridOnLine = reverseLine[i + j - 1]
            local posAfterMove = posList[j]
            if posAfterMove then
                self:SetGridByPos(false, gridOnLine:GetPos())
                self:SetGridByPos(gridOnLine, posAfterMove)
            else
                XLog.Error("[XLineArithmeticGame] , 格子前移逻辑有问题")
            end
        end
    end

    self:MarkEventExecuted(tailGrid)

    -- 收集事件结算后的数字显示
    local dictScoreAfterEvent = {}
    for y, line in pairs(map) do
        for x, grid in pairs(line) do
            if grid then
                local uid = grid:GetUid()
                dictScoreAfterEvent[uid] = grid:GetNumber4Ui()
            end
        end
    end
    for i = 1, #animationData.AwakeGrids do
        local awakeGrid = animationData.AwakeGrids[i]
        local score = dictScoreAfterEvent[awakeGrid.Uid]
        awakeGrid.ScoreAfterEvent = score
    end

    ---@type XLineArithmeticAnimation
    local animation = XLineArithmeticAnimation.New()
    animation:SetType(XLineArithmeticEnum.ANIMATION.EAT_STAY_GRID)
    animation:SetData(animationData)
    self._AnimationList:Enqueue(animation)
    self._LineCurrent = {}

    self:MarkRecordGridScore(tailGrid)
end

---@param model XLineArithmeticModel
---@param tailGrid XLineArithmeticGrid@结算格
function XLineArithmeticGame:EatFinalGrid(model, tailGrid)
    local record = self:MakeRecord(model)

    ---@class XLineArithmeticAnimationDataEatFinalGrid
    local animationData = {
        GridsRemove4Event = {},
        ---@type XLineArithmeticGameKeepGridData[]
        KeepGrids = {},
        Grids = {},
        ---@type XLineArithmeticControlMapData[]
        MapDataAfterEvent = {},
        AwakeGrids = {},
        RemoveEmoGrids = {},
        IsFinalGridPlayAwake = false,
        LineGrids = {}
    }
    local dictScoreAfterEvent = {}
    local dictScore4FinalGrid = {}
    local dictEventRemove = {}
    local dictEat = {}
    local posList = {}
    local posList4UpdateLine = {}
    local pos2Remove = {}

    -- 操作时, 结算格在队尾, 为了方便, 将格子顺序反转, 结算格作为队首
    ---@type XLineArithmeticGrid[]
    local reverseLine = {}
    for i = #self._LineCurrent, 1, -1 do
        local grid = self._LineCurrent[i]
        reverseLine[#reverseLine + 1] = grid
    end

    local animationGrids = animationData.Grids
    for i = 1, #reverseLine do
        local grid = reverseLine[i]
        animationGrids[#animationGrids + 1] = grid:GetUid()
    end

    for i = 1, #reverseLine do
        local grid = reverseLine[i]
        local pos = grid:GetPosClone()
        posList[i] = pos
        posList4UpdateLine[i] = pos
    end

    -- 结算事件
    local countEvent2Remove = 0
    for i = 1, #reverseLine do
        local grid = reverseLine[i]
        if grid:IsCrossEventGrid() then
            -- 移除事件, 再移除格子
            local event = self:GetEventByGrid(grid)
            if event then
                event:UndoOnEventRemove(self)
                event:Confirm(self)
                self:MarkEventExecuted(grid)
                self:RemoveEvent(event)
            end
            -- 记录 事件格
            local uid = grid:GetUid()
            animationData.GridsRemove4Event[#animationData.GridsRemove4Event + 1] = uid
            dictEventRemove[uid] = true
            dictEat[uid] = true
            -- 收集数字后再移除队尾空格
            pos2Remove[#pos2Remove + 1] = posList[#posList - countEvent2Remove]
            countEvent2Remove = countEvent2Remove + 1
            record.EatEventGrid[#record.EatEventGrid + 1] = grid:GetId()
        end
    end

    -- 收集事件结算后的数字显示
    local map = self:GetMap()
    local mapDataAfterEvent = {}
    for y, line in pairs(map) do
        for x, grid in pairs(line) do
            if grid then
                local uid = grid:GetUid()
                ---@type XLineArithmeticControlMapData
                local mapData = {
                    Uid = uid,
                    Number = grid:GetNumber4Ui(),
                    NumberOnPreview = grid:IsNumberOnPreviewChanged() and 1 or 0,
                }
                mapDataAfterEvent[#mapDataAfterEvent + 1] = mapData
                dictScoreAfterEvent[uid] = mapData.Number

                -- 将未完成的格子改回清醒状态
                if grid:IsFinalGrid() and (not self:IsOnLine(grid)) then
                    if grid:IsFinish() then
                        animationData.RemoveEmoGrids[#animationData.RemoveEmoGrids + 1] = {
                            Uid = uid,
                            Icon = grid:GetIconSleep(),
                            IsSleep = true,
                            IsAwake = false,
                            IsFinish = true,
                        }
                    else
                        animationData.AwakeGrids[#animationData.AwakeGrids + 1] = {
                            Uid = uid,
                            Icon = grid:GetIconAwake(),
                            IsSleep = false,
                            IsAwake = false,
                        }
                    end
                end
            end
        end
    end
    animationData.MapDataAfterEvent = mapDataAfterEvent

    for i = 1, #pos2Remove do
        local pos = pos2Remove[i]
        self:SetGridByPos(false, pos)
        table.remove(posList, #posList)
    end

    for i = 2, #reverseLine do
        local grid = reverseLine[i]
        local uid = grid:GetUid()
        if not dictEat[uid] then
            local number = grid:GetNumberAfterConfirm()

            -- 确认得分
            tailGrid:SetNumberExecuted(number)
            local needNumber = tailGrid:GetNumber4Final()
            dictScore4FinalGrid[uid] = needNumber

            if needNumber < 0 then
                -- 分数还有剩余的格子, 要留下来
                local remainNumber = math.abs(needNumber)
                -- 这会导致无法回溯
                grid:SetNumber(remainNumber)
                grid:ClearNumberOnConfirm()
                break
            end

            local pos = grid:GetPos()
            self:SetGridByPos(false, pos)

            -- 将后面的格子前移
            self:SetGridByPos(false, posList[#posList])
            table.remove(posList, #posList)
            dictEat[uid] = true

            if needNumber == 0 then
                break
            end
        end
    end

    -- 移除被事件扣到0的格子
    for i = 1, #reverseLine do
        local grid = reverseLine[i]
        if grid:IsNumberGrid() and grid:GetNumberAfterConfirm() <= 0 then
            if not dictEat[grid:GetUid()] then
                local uid = grid:GetUid()
                dictEat[uid] = true
                dictEventRemove[uid] = true
                animationData.GridsRemove4Event[#animationData.GridsRemove4Event + 1] = uid
                if #posList > 0 then
                    self:SetGridByPos(false, posList[#posList])
                else
                    XLog.Error("[XLineArithmeticGame] 移除队尾错误")
                end
                table.remove(posList, #posList)
            end
        end
    end

    -- 移除被事件扣到0的格子(目前只影响连线中的格子)
    --for y, line in pairs(map) do
    --    for x, grid in pairs(line) do
    --        if grid then
    --            if grid:IsNumberGrid() and grid:GetNumberAfterConfirm() <= 0 then
    --                self:SetGridByPos(false, grid:GetPos())
    --                local uid = grid:GetUid()
    --                dictEat[uid] = true
    --                dictEventRemove[uid] = true
    --                animationData.EventGrids[#animationData.EventGrids + 1] = uid
    --            end
    --        end
    --    end
    --end

    -- 将格子前移
    local validIndex = 1
    for i = 2, #reverseLine do
        local grid = reverseLine[i]
        if not dictEat[grid:GetUid()] then
            validIndex = validIndex + 1
            local pos = posList[validIndex]
            if pos then
                self:SetGridByPos(grid, pos)
            else
                XLog.Error("[XLineArithmeticGame] 格子前移逻辑有问题", validIndex)
            end
        end
    end

    -- 记录 受事件影响的数字格
    for i = 1, #reverseLine do
        local grid = reverseLine[i]
        local uid = grid:GetUid()
        if not dictEventRemove[uid] and not grid:IsFinalGrid() then
            ---@class XLineArithmeticGameKeepGridData
            local numberData = {
                Uid = uid,
                Score = grid:IsNumberGrid() and dictScoreAfterEvent[uid] or false,
                PosIndex = i,
                CanEat = dictEat[uid],
                Score4FinalGrid = dictScore4FinalGrid[uid],
                ScorePreview = grid:IsNumberOnPreviewChanged() and 1 or 0,
            }
            animationData.KeepGrids[#animationData.KeepGrids + 1] = numberData
        end
    end

    -- 画线，需要展示终点
    local index
    for i = #reverseLine, 1, -1 do
        index = i
        local grid = reverseLine[i]
        if dictEat[grid:GetUid()] then
            index = index - 1
            break
        end
    end
    for i = index, 1, -1 do
        local pos = posList4UpdateLine[i]
        if posList4UpdateLine then
            animationData.LineGrids[#animationData.LineGrids + 1] = {
                x = pos.x,
                y = pos.y,
                IsPosData = true
            }
        end
    end

    ---@type XLineArithmeticAnimation
    local animation = XLineArithmeticAnimation.New()
    animation:SetType(XLineArithmeticEnum.ANIMATION.EAT_FINAL_GRID)
    animation:SetData(animationData)
    self._AnimationList:Enqueue(animation)

    local finalGrid = reverseLine[1]
    if finalGrid then
        if finalGrid:IsFinalGrid() and not finalGrid:IsFinish() then
            animationData.IsFinalGridPlayAwake = true
        end
    end

    self._LineCurrent = {}

    self:MarkRecordGridScore(tailGrid)
end

---@param model XLineArithmeticModel
function XLineArithmeticGame:CreateGridByGridId(model, gridId, x, y)
    local config
    if gridId ~= 0 then
        config = model:GetGridById(gridId)
    end

    ---@type XLineArithmeticGrid
    local grid = XLineArithmeticGrid.New()
    if config then
        grid:SetDataFromConfig(config)
    end

    self:SetGridByPos(grid, XLuaVector2.New(x, y))

    local uid = "(" .. x .. "," .. y .. ") configId:" .. gridId .. "/" .. self:GetIncreaseUid()
    grid:SetUid(uid)
    return grid
end

---@param grid XLineArithmeticGrid
---@return XLineArithmeticEvent
function XLineArithmeticGame:GetEventByGrid(grid)
    ---@type XLineArithmeticEvent
    local event = grid:GetEvent()
    if not event and grid:IsCrossEventGrid() then
        event = XLineArithmeticEvent.New()
        local uid = self:GetIncreaseUid()
        event:SetUid(uid)
        event:SetEventType(grid:GetEventType())
        event:SetScore(grid:GetParams2())
        event:SetFromGrid(grid)
        grid:SetEvent(event)
    end
    return event
end

function XLineArithmeticGame:GetIncreaseUid()
    self._IncreaseUid = self._IncreaseUid + 1
    return self._IncreaseUid
end

---@param grid XLineArithmeticGrid
function XLineArithmeticGame:SetGridByPosXY(grid, x, y)
    local line = self._Map[y]
    if not line then
        line = {}
        self._Map[y] = line
    end
    line[x] = grid
    if grid then
        grid:SetPosByXY(x, y)
    end
end

---@param grid XLineArithmeticGrid
function XLineArithmeticGame:SetGridByPos(grid, pos)
    if not pos then
        XLog.Error("[XLineArithmeticGame] pos为空")
        return
    end
    local x = pos.x
    local y = pos.y
    self:SetGridByPosXY(grid, x, y)
end

---@param model XLineArithmeticModel
function XLineArithmeticGame:InitFromConfig(model, configs, stageId)
    self._StageId = stageId
    local rowAmount = #configs

    local mapX, mapY = 0, rowAmount

    for i = 1, #configs do
        local config = configs[i]
        for j = 1, #config.ColumnCell do
            local gridId = config.ColumnCell[j]
            local x = j

            -- 0 代表空格
            if gridId ~= 0 then
                local y = rowAmount - config.Line + 1
                local grid = self:CreateGridByGridId(model, gridId, x, y)
                if grid:IsFinalGrid() then
                    self._AmountOfUnfinishedFinialGrids = self._AmountOfUnfinishedFinialGrids + 1
                end
            end
            if x > mapX then
                mapX = x
            end
        end
    end
    self._TotalAmountOfFinalGrids = self._AmountOfUnfinishedFinialGrids

    self._GameStartTime = XTime.GetServerNowTimestamp()

    self._MapSize.X = mapX
    self._MapSize.Y = mapY
end

function XLineArithmeticGame:GetLineCurrent()
    return self._LineCurrent
end

function XLineArithmeticGame:GetTailGridOfLineCurrent()
    return self._LineCurrent[#self._LineCurrent]
end

function XLineArithmeticGame:GetAllNumberGrid()
    local list = {}
    for y, line in pairs(self._Map) do
        for x, grid in pairs(line) do
            if grid and grid:IsNumberGrid() then
                list[#list + 1] = grid
            end
        end
    end
    return list
end

function XLineArithmeticGame:GetAnimation()
    local animation = self._AnimationList:Dequeue()
    return animation
end

function XLineArithmeticGame:IsEditingLine()
    return #self._LineCurrent > 0
end

function XLineArithmeticGame:GetStrProgress(value, max)
    return '(' .. value .. '/' .. max .. ')'
end

function XLineArithmeticGame:IsMatchCondition(condition, needProgress)
    -- 事件格
    if condition.Type == XLineArithmeticEnum.CONDITION.EVENT_GRID then
        if needProgress then
            local strProgress = nil
            local amount = 0
            local max = #condition.Params
            for i = 1, max do
                local eventGridId = condition.Params[i]
                if self._EventExecuted[eventGridId] then
                    amount = amount + 1
                end
            end
            strProgress = self:GetStrProgress(amount, max)
            return amount == max, strProgress
        else
            for i = 1, #condition.Params do
                local eventGridId = condition.Params[i]
                if not self._EventExecuted[eventGridId] then
                    return false
                end
            end
        end
        return true
    end
    if condition.Type == XLineArithmeticEnum.CONDITION.FINAL_GRID then
        local params1 = condition.Params[1]
        if params1 == 1 then
            --达成任意终点格
            if self._AmountOfUnfinishedFinialGrids < self._TotalAmountOfFinalGrids then
                local strProgress = nil
                if needProgress then
                    strProgress = self:GetStrProgress(1, 1)
                end
                return true, strProgress
            else
                local strProgress = nil
                if needProgress then
                    strProgress = self:GetStrProgress(0, 1)
                end
                return false, strProgress
            end
        elseif params1 == 2 then
            --达成所有终点格
            local strProgress = nil
            if needProgress then
                local value = self._TotalAmountOfFinalGrids - self._AmountOfUnfinishedFinialGrids
                value = XMath.Clamp(value, 0, self._TotalAmountOfFinalGrids)
                strProgress = self:GetStrProgress(value, self._TotalAmountOfFinalGrids)
            end
            if self._AmountOfUnfinishedFinialGrids == 0 then
                return true, strProgress
            else
                return false, strProgress
            end
        end
        return false
    end
    -- 操作次数
    if condition.Type == XLineArithmeticEnum.CONDITION.OPERATION_AMOUNT then
        local needAmount = condition.Params[1]
        local recordAmount = #self._Record
        local strProgress = nil
        if needProgress then
            strProgress = self:GetStrProgress(recordAmount, needAmount)
        end
        return recordAmount <= needAmount, strProgress
    end
    if condition.Type == XLineArithmeticEnum.CONDITION.ALL_NUMBER_GRID then
        local map = self:GetMap()
        for y, line in pairs(map) do
            for x, grid in pairs(line) do
                if grid then
                    if grid:IsNumberGrid() then
                        return false
                    end
                end
            end
        end
        return true
    end
end

---@param grid XLineArithmeticGrid
function XLineArithmeticGame:MarkEventExecuted(grid)
    self._EventExecuted[grid:GetId()] = true
end

---@param model XLineArithmeticModel
function XLineArithmeticGame:RequestOperation(model)
    if self._IsOnline then
        local record = self._Record[#self._Record]
        if not record then
            XLog.Error("[XLineArithmeticGame] 记录发送错误")
            return
        end
        if self._IsSend[record.Round] then
            XLog.Error("[XLineArithmeticGame] 重复请求operation")
            return
        end
        local amount = self:GetCompleteConditionAmount()
        record.Condition = amount
        XMVCA.XLineArithmetic:RequestOperation(self._StageId, record.Round, amount, record.Points)
        self._IsSend[record.Round] = true

        local gameData = {
            StageId = self._StageId,
            StageStartTime = self._GameStartTime,
            OperatorRecords = self._Record
        }
        model:SetCurrentGameData(gameData)
    end
end

function XLineArithmeticGame:GetCompleteConditionAmount(isGetByteCode)
    local amount = 0
    local byteCode = 0
    for i = 1, #self._AllCondition do
        local condition = self._AllCondition[i]
        if self:IsMatchCondition(condition) then
            amount = amount + 1
            if isGetByteCode then
                byteCode = byteCode + (10 ^ (i - 1))
            end
        end
    end
    return amount, byteCode
end

function XLineArithmeticGame:SetCondition(conditions)
    self._AllCondition = conditions
end

function XLineArithmeticGame:GetAllCondition()
    return self._AllCondition
end

function XLineArithmeticGame:RequestSettle()
    if not self._IsOnline then
        return
    end
    if self._IsRequestSettle then
        XLog.Error("[XLineArithmeticGame] 重复请求结算")
        return
    end
    self._IsRequestSettle = true
    local starAmount, byteCode = self:GetCompleteConditionAmount(true)
    local operationCount = #self._Record
    local Json = require("XCommon/Json")
    local jsonRecord = Json.encode({
        Record = self._Record,
        StarByte = byteCode,
    })
    XMVCA.XLineArithmetic:RequestSettle(self._StageId, starAmount, operationCount, self._UseHelp, jsonRecord, byteCode)
end

function XLineArithmeticGame:ClearAnimation()
    self._AnimationList:Clear()
end

function XLineArithmeticGame:SetOffline()
    self._IsOnline = false
end

function XLineArithmeticGame:SetOnline()
    self._IsOnline = true
end

function XLineArithmeticGame:UpdateAmountOfUnfinishedFinalGrid()
    -- 因为终点格会受事件影响，所以得更新棋盘上所有终点格的分数才准确
    local amount = 0
    for y, line in pairs(self._Map) do
        for x, grid in pairs(line) do
            if grid and grid:IsFinalGrid() then
                if not grid:IsFinish() then
                    amount = amount + 1
                end
            end
        end
    end
    self._AmountOfUnfinishedFinialGrids = amount
end

function XLineArithmeticGame:MarkUseHelp()
    self._UseHelp = true
end

function XLineArithmeticGame:IsHasRecord()
    return #self._Record > 0
end

function XLineArithmeticGame:GetMapSize()
    return self._MapSize
end

return XLineArithmeticGame