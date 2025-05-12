local XLineArithmeticEnum = require("XModule/XLineArithmetic/Game/XLineArithmeticEnum")

---@class XLineArithmeticControl : XControl
---@field private _Model XLineArithmeticModel
local XLineArithmeticControl = XClass(XControl, "XLineArithmeticControl")
function XLineArithmeticControl:OnInit()
    ---@type XLineArithmeticGame
    self._Game = nil
    self._UiData = {
        MapEmptyData = {},

        ---@type XLineArithmeticControlMapData[]
        MapData = false,

        ---@type XLineArithmeticControlLineData[]
        LineData = false,

        ---@type XLineArithmeticControlDataEventDesc[]
        EventDescData = false,

        ---@type XLineArithmeticControlDataStarDesc[]
        StarDescData = false,

        Time = "",

        ---@type XLineArithmeticControlChapterData[]
        Chapter = false,

        ---@type XLineArithmeticControlStageData[]
        Stage = false,

        ChapterTitleImg = false,

        RewardOnMainUi = false,

        --CurrentChapterName = "",
        CurrentChapterStar = "",

        IsCanManualSettle = false,

        IsDefaultSelectDirty = false,
        DefaultSelectStageIndex = false,

        ---@type XLineArithmeticControlMapData[]
        HelpMapData = false,

        ---@type XLineArithmeticControlLineData[]
        HelpLineData = false,
    }
    self._StageId = 0

    self._GridSize = { Width = 150, Height = 150 }

    self._GridBgSize = { Width = 750, Height = 600 }

    self._TouchMovePos = XLuaVector2.New(0, 0)

    if XMain.IsEditorDebug and rawget(_G, "TestFile") then
        self._StageId = 1001
    end

    self._CurrentChapterId = false

    self._IsShowHelpBtn = false

    ---@type XLineArithmeticHelpGame
    self._HelpGame = nil
    self._HelpActionDuration = 0.6
    self._HelpActionTime = 0
    self._HelpActionIndex = 1

    self._Timer = false
end

function XLineArithmeticControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    XEventManager.AddEventListener(XEventId.EVENT_LINE_ARITHMETIC_CLICK_GRID, self.OnClickPos, self)
    XEventManager.AddEventListener(XEventId.EVENT_LINE_ARITHMETIC_CONFIRM, self.ConfirmTouch, self)

    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            if not self._Model:CheckInTime() then
                XUiManager.TipText("FubenRepeatNotInActivityTime")
                self:CloseThisModule()
            end
        end, 0)
    end
end

function XLineArithmeticControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_LINE_ARITHMETIC_CLICK_GRID, self.OnClickPos, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LINE_ARITHMETIC_CONFIRM, self.ConfirmTouch, self)

    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XLineArithmeticControl:OnRelease()
    self:ClearGame()
end

function XLineArithmeticControl:GetGame()
    if not self._Game then
        self._Game = require("XModule/XLineArithmetic/Game/XLineArithmeticGame").New()
    end
    return self._Game
end

function XLineArithmeticControl:ClearGame()
    self._Game = nil
end

function XLineArithmeticControl:StartGame(restart)
    if not restart then
        if not self._Model:IsPlaying() then
            XMVCA.XLineArithmetic:RequestStart(self._StageId)
        end
    end

    self:ClearGame()
    local game = self:GetGame()
    local configs = self._Model:GetMapByStageId(self._StageId)
    game:InitFromConfig(self._Model, configs, self._StageId)

    -- condition
    local stageId = self._StageId
    local starCondition = self._Model:GetStageStarCondition(stageId)
    local conditions = {}
    for i = 1, #starCondition do
        local conditionId = starCondition[i]
        local condition = XConditionManager.GetConditionTemplate(conditionId)
        conditions[#conditions + 1] = condition
    end
    game:SetCondition(conditions)

    local currentGameData = self._Model:GetCurrentGameData()
    if currentGameData then
        local recordStageId = currentGameData.StageId
        if recordStageId ~= self._StageId then
            XLog.Error("[XLineArithmeticControl] 记录出错, 服务端stageId与本地不一致")
        end
        game:SetOffline()
        local operatorRecords = currentGameData.OperatorRecords
        for i = 1, #operatorRecords do
            local operation = operatorRecords[i]
            local points = operation.Points
            for j = 1, #points do
                local point = points[j]
                game:OnClickPos({ x = point.X, y = point.Y })
                game:Update(self._Model)
            end
        end
        -- 快进不需要动画
        game:ClearAnimation()
        game:SetOnline()
    end

    local isStagePassed = self._Model:IsStagePassed(stageId)
    self:SetShowHelpBtn(isStagePassed)
    self:SetCurrentGameStageId()
end

function XLineArithmeticControl:GetUiData()
    return self._UiData
end

---@param game XLineArithmeticGame
function XLineArithmeticControl:UpdateGameMapData(mapData, game)
    local gridSize = self._GridSize
    local bgSize = self._GridBgSize

    local iconEmoOfFinalGrid
    local lineCurrent = game:GetLineCurrent()
    local totalScore = 0
    for i = 1, #lineCurrent do
        local grid = lineCurrent[i]
        if grid:IsCrossEventGrid() then
            iconEmoOfFinalGrid = grid:GetEmoIcon()
        end
        if grid:IsNumberGrid() then
            local numberPreview = grid:GetNumberPreview()
            local number = grid:GetNumber4NumberGrid()
            totalScore = totalScore + number + numberPreview
        end
    end
    local headGrid = lineCurrent[1]

    local map = game:GetMap()
    for y, line in pairs(map) do
        for x, grid in pairs(line) do
            if grid then
                local pos = grid:GetPos()
                local isNormal = grid:IsNumberGrid()
                local isEvent = grid:IsEventGrid()
                local isFinal = grid:IsFinalGrid()
                local isSelected = game:IsOnLine(grid)
                local number = grid:GetNumber4Ui()
                local isBuff = nil
                local icon
                --数字为0，进入完成状态，且被忽略；
                --选中格子时， 所有终点格进入睡觉状态；
                --取消选中， 所有终点格进入清醒状态
                local isSleep = false
                if grid:IsFinalGrid() then
                    if grid:IsFinish() then
                        icon = grid:GetIconFinish()
                    else
                        if game:IsEditingLine() then
                            icon = grid:GetIconSleep()
                            isSleep = true
                        else
                            icon = grid:GetIconAwake()
                        end
                    end
                else
                    icon = grid:GetIcon()
                end
                --grid:GetIcon()

                if grid:IsCrossEventGrid() then
                    local eventType = grid:GetEventType()
                    if eventType == XLineArithmeticEnum.EVENT.PASS_EASY
                            or eventType == XLineArithmeticEnum.EVENT.FINAL_EASY
                    then
                        isBuff = true

                    elseif eventType == XLineArithmeticEnum.EVENT.PASS_HARD
                            or eventType == XLineArithmeticEnum.EVENT.FINAL_HARD
                    then
                        isBuff = false

                    end
                end

                local emoIcon
                if isFinal and not grid:IsFinish() then
                    emoIcon = iconEmoOfFinalGrid
                end

                local uiX, uiY = self:GetGridUiPos(pos.x, pos.y, gridSize, bgSize)

                ---@class XLineArithmeticControlMapData
                local gridData = {
                    Uid = grid:GetUid(),
                    X = uiX,
                    Y = uiY,
                    UiName = "Grid" .. math.floor(pos.x) .. "_" .. math.floor(pos.y),
                    Icon = icon,
                    IsNormal = isNormal,
                    IsEvent = isEvent,
                    IsFinal = isFinal,
                    Number = number,
                    NumberOnPreview = grid:GetNumberPreview(),
                    IsSelected = isSelected,
                    IsSleep = isSleep,
                    EmoIcon = emoIcon,
                    TotalNumber = nil,
                    IsEmpty = grid:IsEmpty(),
                    IsBuff = isBuff,
                }

                if headGrid and grid:Equals(headGrid) then
                    gridData.TotalNumber = totalScore
                end

                mapData[#mapData + 1] = gridData
            end
        end
    end
end

function XLineArithmeticControl:GetGridUiPos(x, y, gridSize, bgSize)
    return gridSize.Width * (x - 0.5) - bgSize.Width / 2, gridSize.Height * (y - 0.5) - bgSize.Height / 2
end

function XLineArithmeticControl:UpdateEmptyData()
    local gridSize = self._GridSize
    local bgSize = self._GridBgSize
    local mapSize = self._Game:GetMapSize()
    local emptyData = {}
    self._UiData.MapEmptyData = emptyData
    for x = 1, mapSize.X do
        for y = 1, mapSize.Y do
            local uiX, uiY = self:GetGridUiPos(x, y, gridSize, bgSize)
            local data = {
                X = uiX,
                Y = uiY
            }
            table.insert(emptyData, data)
        end
    end
end

function XLineArithmeticControl:UpdateMap()
    local mapData = {}
    self._UiData.MapData = mapData

    local game = self:GetGame()
    self:UpdateGameMapData(mapData, game)

    --if XMain.IsEditorDebug then
    --    local str = ""
    --    for i = 1, #lineCurrent do
    --        local grid = lineCurrent[i]
    --        local pos = grid:GetPos()
    --        local strPos = string.format("(%d,%d)", pos.x, pos.y)
    --        str = str .. "," .. strPos
    --    end
    --    XLog.Debug(str)
    --end

    if game:IsFinishSomeFinalGrids() then
        self._UiData.IsCanManualSettle = true
    else
        self._UiData.IsCanManualSettle = false
    end
end

function XLineArithmeticControl:GetUiLineData(lineCurrent)
    local lineData = {}
    for i = 1, #lineCurrent do
        local grid1 = lineCurrent[i]
        local grid2 = lineCurrent[i + 1]
        if grid2 then
            local pos1
            local pos2
            if grid1.IsPosData then
                pos1 = grid1
            else
                pos1 = grid1:GetPos()
            end
            if grid2.IsPosData then
                pos2 = grid2
            else
                pos2 = grid2:GetPos()
            end

            local rotation = false
            if pos2.y > pos1.y and pos1.x == pos2.x then
                rotation = 90
            elseif pos2.y < pos1.y and pos1.x == pos2.x then
                rotation = -90
            elseif pos2.y == pos1.y and pos1.x > pos2.x then
                rotation = 180
            elseif pos2.y == pos1.y and pos1.x < pos2.x then
                rotation = 0
            else
                XLog.Error("[XLineArithmeticControl] 连线存在未定义的情况")
            end
            if rotation then
                local x = (pos1.x + pos2.x - 1) / 2 * self._GridSize.Width
                local y = (pos1.y + pos2.y - 1) / 2 * self._GridSize.Height

                x = x - self._GridBgSize.Width / 2
                y = y - self._GridBgSize.Height / 2

                ---@class XLineArithmeticControlLineData
                local line = {
                    X = x,
                    Y = y,
                    Rotation = rotation,
                    -- 逆序, 方便动画使用
                    Index = #lineCurrent - i + 1,
                }
                lineData[#lineData + 1] = line
            end
        end
    end
    return lineData
end

function XLineArithmeticControl:UpdateLine(line)
    local game = self:GetGame()
    line = line or game:GetLineCurrent()
    local lineData = self:GetUiLineData(line)
    self._UiData.LineData = lineData
end

function XLineArithmeticControl:GetGridXY(x, y)
    -- 改成相当左下角
    x = x + self._GridBgSize.Width / 2
    y = y + self._GridBgSize.Height / 2

    local gridX = math.floor(x / self._GridSize.Width) + 1
    local gridY = math.floor(y / self._GridSize.Height) + 1
    return gridX, gridY
end

function XLineArithmeticControl:SetTouchPosOnDrag(x, y)
    local gridX, gridY = self:GetGridXY(x, y)
    if self._TouchMovePos.x == gridX and self._TouchMovePos.y == gridY then
        return
    end
    self._TouchMovePos.x = gridX
    self._TouchMovePos.y = gridY
    self._Game:OnClickDrag(XLuaVector2.New(gridX, gridY))
end

function XLineArithmeticControl:SetTouchPosOnBegin(x, y)
    local gridX, gridY = self:GetGridXY(x, y)

    -- 如果处于选中状态, 支持拖动时, 恢复选中
    local pos = XLuaVector2.New(gridX, gridY)
    local game = self:GetGame()
    local grid = game:GetGrid(pos)
    if not game:IsOnLine(grid) then
        self._TouchMovePos.x = gridX
        self._TouchMovePos.y = gridY
    end
    self._Game:OnClickPos(pos)
end

function XLineArithmeticControl:ConfirmTouch()
    self._Game:ConfirmAction()
end

function XLineArithmeticControl:ClearTouchPos()
    self._TouchMovePos.x = 0
    self._TouchMovePos.y = 0
end

function XLineArithmeticControl:UpdateGame()
    return self._Game:Update(self._Model)
end

function XLineArithmeticControl:OnClickReset()
    XMVCA.XLineArithmetic:RequestRestart(self._StageId)
    self._Model:SetCurrentGameData(false)
    self:ClearGame()
    self:StartGame(true)
    self:SetShowHelpBtn(true)
end

function XLineArithmeticControl:GetAnimation()
    return self._Game:GetAnimation()
end

function XLineArithmeticControl:UpdateEventGridDesc()
    local eventDescData = {}
    self._UiData.EventDescData = eventDescData

    local stageId = self._StageId
    local cellIds = self._Model:GetStageEventCellId(stageId)
    for i = 1, #cellIds do
        local cellId = cellIds[i]
        local gridConfig = self._Model:GetGridById(cellId)
        ---@class XLineArithmeticControlDataEventDesc
        local dataEvent = {
            Name = gridConfig.CellName,
            Desc = gridConfig.CellDesc,
            Icon = gridConfig.CellIcon[1],
        }
        eventDescData[#eventDescData + 1] = dataEvent
    end
end

function XLineArithmeticControl:UpdateStarTarget()
    local starDescData = {}
    self._UiData.StarDescData = starDescData
    local game = self:GetGame()

    local stageId = self._StageId
    local starCondition = self._Model:GetStageStarCondition(stageId)
    local starDesc = self._Model:GetStageStarConditionDesc(stageId)

    for i = 1, #starCondition do
        local conditionId = starCondition[i]
        local condition = XConditionManager.GetConditionTemplate(conditionId)
        local isFinish, strProgress = game:IsMatchCondition(condition, true)

        local isValid = true

        -- 隐藏星
        if condition.Type == XLineArithmeticEnum.CONDITION.ALL_NUMBER_GRID then
            if not isFinish then
                isValid = false
            end
        end

        if isValid then
            -- 关卡进行中时不显示完成状态
            if condition.Type == XLineArithmeticEnum.CONDITION.OPERATION_AMOUNT
                    and not game:IsFinish()
                    and not game:IsRequestSettle()
            then
                isFinish = false
            end

            local desc = starDesc[i]
            if strProgress then
                desc = desc .. strProgress
            end
            ---@class XLineArithmeticControlDataStarDesc
            local data = {
                IsFinish = isFinish,
                Desc = desc,
                Index = i,
            }
            starDescData[#starDescData + 1] = data
        end
    end
end

function XLineArithmeticControl:CheckFinish()
    local game = self:GetGame()
    if game:IsFinish() then
        self:SetShowHelpBtn(true)
        game:RequestSettle()
    end
end

function XLineArithmeticControl:UpdateTime()
    local remainTime = self._Model:GetActivityRemainTime()
    if remainTime < 0 then
        remainTime = 0
    end
    if remainTime == 0 then
        self:CloseThisModule()
        return false
    end
    local text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
    self._UiData.Time = text
    return true
end

function XLineArithmeticControl:CloseThisModule()
    XLuaUiManager.SafeClose("UiLineArithmeticMain")
    XLuaUiManager.SafeClose("UiLineArithmeticChapter")
    XLuaUiManager.SafeClose("UiLineArithmeticTask")
    XLuaUiManager.SafeClose("UiLineArithmeticGame")
    XLuaUiManager.SafeClose("UiLineArithmeticTargetPopup")
    XLuaUiManager.SafeClose("UiLineArithmeticTips")
    XLuaUiManager.SafeClose("UiLineArithmeticTargetPopupTips")
    XLuaUiManager.SafeClose("UiHelp")
end

function XLineArithmeticControl:UpdateChapter()
    local chapterData = {}
    self._UiData.Chapter = chapterData

    local chapters = self._Model:GetAllChaptersCurrentActivity()
    local currentGameData = self._Model:GetCurrentGameData()
    local currentGameChapterId
    if currentGameData then
        local currentGameStageId = currentGameData and currentGameData.StageId
        currentGameChapterId = self._Model:GetChapterIdByStageId(currentGameStageId)
    end

    for i, chapterConfig in pairs(chapters) do
        --local name = chapterConfig.Name
        local chapterId = chapterConfig.Id
        local isOpen = self._Model:IsChapterOpen(chapterId)
        --local isRunning = currentGameChapterId == chapterId
        local isNewChapter
        if isOpen then
            isNewChapter = self._Model:IsNewChapter(chapterId)
        end
        local starAmount = self._Model:GetStarAmount(chapterId)
        local maxStarAmount = self._Model:GetMaxStarAmount(chapterId)
        local txtLock
        if not isOpen then
            txtLock = self:GetChapterLockTips(chapterId)
        end
        ---@class XLineArithmeticControlChapterData
        local chapter = {
            TxtStar = starAmount .. "/" .. maxStarAmount,
            --Name = name,
            IsOpen = isOpen,
            --isRunning = isRunning,
            IsNew = isNewChapter,
            ChapterId = chapterId,
            TxtLock = txtLock,
        }
        chapterData[#chapterData + 1] = chapter
    end
    table.sort(chapterData, function(a, b)
        return a.ChapterId < b.ChapterId
    end)
end

function XLineArithmeticControl:SetChapterId(chapterId)
    self:SetDefaultSelectDirty(true)
    self._UiData.DefaultSelectStageIndex = false
    self._CurrentChapterId = chapterId
    self._Model:SetNotNewChapter(chapterId)
end

function XLineArithmeticControl:SetDefaultSelectDirty(isDirty)
    self._UiData.IsDefaultSelectDirty = isDirty
end

function XLineArithmeticControl:OpenChapterUi(chapterId)
    --local currentGameData = self._Model:GetCurrentGameData()
    --if currentGameData then
    --    local currentStageId = currentGameData.StageId
    --    local currentChapterId = self._Model:GetChapterIdByStageId(currentStageId)
    --    if currentChapterId ~= chapterId then
    --        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("LineArithmeticGoOnStage"), nil, nil, function()
    --            --self._StageId = currentStageId
    --            --XLuaUiManager.Open("UiLineArithmeticGame")
    --            self:SetChapterId(currentChapterId)
    --            XLuaUiManager.Open("UiLineArithmeticChapter", chapterId)
    --        end)
    --        return
    --    end
    --end
    self:SetChapterId(chapterId)
    XLuaUiManager.Open("UiLineArithmeticChapter", chapterId)
end

function XLineArithmeticControl:OpenStageUi(stageId)
    local currentGameData = self._Model:GetCurrentGameData()
    if currentGameData then
        local currentStageId = currentGameData.StageId
        if currentStageId ~= stageId then
            XUiManager.TipText(XUiHelper.GetText("LineArithmeticHasUnpassedGame"))
            return
        end
    end
    self._StageId = stageId
    XLuaUiManager.Open("UiLineArithmeticGame")
end

function XLineArithmeticControl:ChallengeNextStage()
    local currentStageId = self._StageId
    if not currentStageId then
        XLuaUiManager.SafeClose("UiLineArithmeticTargetPopup")
        XLuaUiManager.SafeClose("UiLineArithmeticGame")
        XLog.Error("[XLineArithmeticControl] 当前关卡有问题:", currentStageId)
        return
    end
    local stages = self._Model:GetAllStage()
    local isFind = false
    for i, config in pairs(stages) do
        if config.PreStageId == currentStageId then
            isFind = true
            -- 可能跨章节
            if self._Model:IsChapterOpen(config.ChapterId) then
                self._StageId = config.Id
                self:SetChapterId(config.ChapterId, false)
                break
            else
                -- 未开放
                XUiManager.TipText("LineArithmeticChapterLock")
                XLuaUiManager.SafeClose("UiLineArithmeticTargetPopup")
                XLuaUiManager.SafeClose("UiLineArithmeticChapter")
                XLuaUiManager.SafeClose("UiLineArithmeticGame")
                return
            end
        end
    end
    if not isFind then
        local chapterId = self._Model:GetNextChapterId(self._CurrentChapterId)
        if chapterId then
            -- 可能跨章节
            if self._Model:IsChapterOpen(chapterId) then
                isFind = self:SetFirstStageByChapterId(chapterId)
            else
                -- 未开放
                XUiManager.TipText("LineArithmeticChapterLock")
                XLuaUiManager.SafeClose("UiLineArithmeticTargetPopup")
                XLuaUiManager.SafeClose("UiLineArithmeticChapter")
                XLuaUiManager.SafeClose("UiLineArithmeticGame")
                return
            end
        end
    end
    if not isFind then
        XUiManager.TipText("LineArithmeticPassAll")
        XLuaUiManager.SafeClose("UiLineArithmeticTargetPopup")
        XLuaUiManager.SafeClose("UiLineArithmeticChapter")
        XLuaUiManager.SafeClose("UiLineArithmeticGame")
        return
    end
    self:StartGame()
    XEventManager.DispatchEvent(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_GAME)
    XLuaUiManager.SafeClose("UiLineArithmeticTargetPopup")
end

function XLineArithmeticControl:SetFirstStageByChapterId(chapterId)
    local nextChapterStages = self._Model:GetStageByChapter(chapterId)
    local firstStage = nextChapterStages[1]
    if firstStage then
        self._StageId = firstStage.Id
        self:SetChapterId(chapterId, false)
        self._UiData.DefaultSelectStageIndex = 1
        return true
    end
    return false
end

function XLineArithmeticControl:AbandonCurrentGameData()
    local currentGameData = self._Model:GetCurrentGameData()
    if currentGameData then
        --XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("LineArithmeticAbandon"), nil, nil, function()
        local stageId = currentGameData.StageId
        XMVCA.XLineArithmetic:RequestAbandon(stageId)
        --end)
    end
end

function XLineArithmeticControl:UpdateReward()
    local rewards = self._Model:GetRewardOnMainUi()
    self._UiData.RewardOnMainUi = rewards
end

function XLineArithmeticControl:UpdateStage()
    ---@type XLineArithmeticControlStageData[]
    local stageData = {}
    self._UiData.Stage = stageData
    local currentGameData = self._Model:GetCurrentGameData()
    local currentStageId
    if currentGameData then
        currentStageId = currentGameData.StageId
    end

    local stages = self._Model:GetStageByChapter(self._CurrentChapterId)
    local chapterStarAmount = 0
    local maxChapterStarAmount = 0
    for i, stageConfig in pairs(stages) do
        local stageId = stageConfig.Id
        local starAmount = self._Model:GetStarAmountByStageId(stageId)
        local maxStarAmount = self._Model:GetMaxStarAmountByStageId(stageId)
        --local isRunning = currentStageId == stageId
        local preStageId = stageConfig.PreStageId
        local isLock
        if preStageId and preStageId ~= 0 then
            local isPassed = self._Model:IsStagePassed(preStageId)
            if not isPassed then
                isLock = true
            end
        end
        chapterStarAmount = chapterStarAmount + starAmount
        maxChapterStarAmount = maxChapterStarAmount + maxStarAmount
        ---@class XLineArithmeticControlStageData
        local chapter = {
            StarAmount = starAmount,
            MaxStarAmount = maxStarAmount,
            Name = stageConfig.Name,
            --IsRunning = isRunning,
            StageId = stageId,
            IsLock = isLock,
        }
        stageData[#stageData + 1] = chapter
    end
    table.sort(stageData, function(a, b)
        return a.StageId < b.StageId
    end)

    local currentChapterId = self._CurrentChapterId
    local chapterConfig = self._Model:GetChapterConfig(currentChapterId)
    local chapterName = chapterConfig.Name
    self._UiData.CurrentChapterName = chapterName
    self._UiData.CurrentChapterStar = chapterStarAmount .. "/" .. maxChapterStarAmount

    -- 默认选中的关卡
    if not self._UiData.DefaultSelectStageIndex then
        local index
        --for i = 1, #stageData do
        --    local stage = stageData[i]
        --    if stage.IsRunning then
        --        index = i
        --        break
        --    end
        --end
        if not index then
            for i = #stageData, 1, -1 do
                local stage = stageData[i]
                if not stage.IsLock then
                    index = i
                    break
                end
            end
        end
        if not index then
            index = 1
        end
        self._UiData.DefaultSelectStageIndex = index
    end
end

function XLineArithmeticControl:RequestManualSettle()
    self._Game:RequestSettle()
end

function XLineArithmeticControl:ClearHelpGame()
    self._HelpGame = nil
    self._HelpActionTime = 0
    self._HelpActionIndex = 1
end

function XLineArithmeticControl:GetHelpGame()
    if not self._HelpGame then
        self._HelpGame = require("XModule/XLineArithmetic/Game/XLineArithmeticHelpGame").New()
    end
    return self._HelpGame
end

function XLineArithmeticControl:StartHelpGame()
    self:ClearHelpGame()
    local game = self:GetHelpGame()
    local configs = self._Model:GetMapByStageId(self._StageId)
    game:InitFromConfig(self._Model, configs, self._StageId)
end

function XLineArithmeticControl:GetHelpGameActionRecord()
    local configs = self._Model:GetStageHelpConfig(self._StageId)
    local record = {}
    local action
    for i = 1, #configs do
        local config = configs[i]
        if action then
            if action.Round ~= config.Round then
                action = nil
            end
        end
        if not action then
            action = {
                Round = config.Round,
                Points = {}
            }
            record[#record + 1] = action
        end
        action.Points[#action.Points + 1] = { X = config.X, Y = config.Y }
    end
    return record
end

function XLineArithmeticControl:UpdateHelpGame()
    local deltaTime = CS.UnityEngine.Time.deltaTime
    self._HelpActionTime = self._HelpActionTime + deltaTime
    if self._HelpActionTime > self._HelpActionDuration then
        self._HelpActionTime = 0

        local game = self:GetHelpGame()
        local record = self:GetHelpGameActionRecord()
        local operatorRecords = record
        local index = 0
        local isValid = false
        for i = 1, #operatorRecords do
            local operation = operatorRecords[i]
            local points = operation.Points
            for j = 1, #points do
                index = index + 1
                if index == self._HelpActionIndex then
                    local point = points[j]
                    game:OnClickPos({ x = point.X, y = point.Y })
                    game:Update(self._Model)
                    isValid = true
                    break
                end
                if j == #points then
                    index = index + 1
                    if index == self._HelpActionIndex then
                        isValid = true
                        game:ExecuteEat(self._Model)
                    end
                    break
                end
            end
            if isValid then
                break
            end
        end

        if isValid then
            self._HelpActionIndex = self._HelpActionIndex + 1
            return true
        else
            --if XMain.IsEditorDebug then
            --    XLog.Error("[XLineArithmeticControl] 连线图文已结束:", self._HelpActionIndex)
            --end
            self:StartHelpGame()
            return false
        end
        return true
    end
    return false
end

function XLineArithmeticControl:UpdateHelpMap()
    ---@type XLineArithmeticControlMapData[]
    local mapData = {}
    self._UiData.HelpMapData = mapData

    local game = self:GetHelpGame()
    self:UpdateGameMapData(mapData, game)

    -- 移除特效表情之类的
    --for i = 1, #mapData do
    --    local gridData = mapData[i]
    --    gridData.EmoIcon = false
    --    gridData.NumberOnPreview = 0
    --    gridData.IsNormal = true
    --end
end

function XLineArithmeticControl:UpdateHelpLine()
    local game = self:GetHelpGame()
    local lineCurrent = game:GetLineCurrent()
    local lineData = self:GetUiLineData(lineCurrent)
    self._UiData.HelpLineData = lineData
end

function XLineArithmeticControl:IsShowHelpBtn()
    return self._IsShowHelpBtn and self._Model:IsUnlockHelpBtn()
end

function XLineArithmeticControl:MarkOpenUiHelp()
    local game = self:GetGame()
    game:MarkUseHelp()
end

function XLineArithmeticControl:IsGameDirty()
    local game = self:GetGame()
    return game:IsHasRecord() or #game:GetLineCurrent() > 0
end

function XLineArithmeticControl:IsGameSettle()
    return self:GetGame():IsRequestSettle()
end

function XLineArithmeticControl:SetShowHelpBtn(value)
    -- 有缓存取缓存
    local valueCache = XSaveTool.GetData("LineArithmeticShowHelp" .. XPlayer.Id .. self._StageId, value)
    if valueCache ~= nil then
        value = valueCache
    end
    if self._IsShowHelpBtn ~= value then
        self._IsShowHelpBtn = value
        if value then
            XSaveTool.SaveData("LineArithmeticShowHelp" .. XPlayer.Id .. self._StageId, true)
        end
    end
end

function XLineArithmeticControl:GetCurrentStageName()
    local stageId = self._StageId
    return self._Model:GetStageName(stageId)
end

function XLineArithmeticControl:UpdateChapterTitleImage()
    local chapterId = self._CurrentChapterId
    local titleImg = self._Model:GetChapterTitleImg(chapterId)
    self._UiData.ChapterTitleImg = titleImg
end

function XLineArithmeticControl:GetChapterLockTips(chapterId)
    local timeId = self._Model:GetChapterTimeId(chapterId)
    if XFunctionManager.CheckInTimeByTimeId(timeId) then
        XUiHelper.GetText("LineArithmeticChapterLock")
        return
    end
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = startTime - currentTime
    if remainTime >= 0 then
        local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.DAY_HOUR_2)
        return XUiHelper.GetText("LineArithmeticUnlockChapter", timeStr)
    end
    XLog.Error("[XLineArithmeticControl] 不明情况导致上锁")
    return XUiHelper.GetText("LineArithmeticChapterLock")
end

---@param data XLineArithmeticControlChapterData
function XLineArithmeticControl:OnClickChapter(data)
    local chapterId = data.ChapterId
    if not data.IsOpen then
        XUiManager.TipMsg(self:GetChapterLockTips(chapterId))
        return
    end
    self:OpenChapterUi(chapterId)
end

function XLineArithmeticControl:SetCurrentGameStageId()
    self._Model:SetCurrentGameStageId(self._StageId)
end

function XLineArithmeticControl:ClearCurrentGameStageId()
    self._Model:SetCurrentGameStageId(false)
end

function XLineArithmeticControl:OnClickPos(gridX, gridY)
    local pos = XLuaVector2.New(tonumber(gridX), tonumber(gridY))
    self._Game:OnClickPos(pos)
end

function XLineArithmeticControl:IsRequesting()
    return self._Model:IsRequesting()
end

return XLineArithmeticControl