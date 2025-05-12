local UPDATE_INTERVAL = 33 -- 33毫秒更新的间隔(约30帧)
local UPDATE_INTERVAL_SEC = UPDATE_INTERVAL / 1000
local READY_TIME = 3 -- 3秒 准备时间

---@class XNonogramControl : XControl
---@field private _Model XNonogramModel
---@field private _Agency XNonogramAgency
local XNonogramControl = XClass(XControl, "XNonogramControl")
function XNonogramControl:OnInit()
    --初始化内部变量
    self:GetAgency()

    self._GameState = XEnumConst.Nonogram.NonogramStageGameStatus.None
    self._CurGameUnlockCGItemCount = 0 -- 当前章节总获得的物品数量
    self._CurGameRemainTime = 0 -- 当前章节游戏剩余时间
    self._CurGameReadyRemainTime = 0 -- 当前章节游戏剩余准备时间
    self._UpdaterId = 0
    self._CurGameGridMap = {} -- 当句游戏格子地图
    self._CurGameGridOpenMap = {} -- 打开的格子索引字典
    self._CurGameRightIndexMap = {} -- 正确的格子的索引字典 {["1|1"] = { RowIndex = 1, ColumnIndex = 1 }}
    self._LastPausedStatus = nil -- 暂停前的状态
    self._CurDisplayTipGridKeyStr = nil -- 当前显示的提示格子的坐标Key值
    self._CurChapterShowTipCD = 0 -- 配置的当前章节的提示CD
    self._CurChapterShowTipErrorHitTimes = 0 -- 配置的当前章节的提示错误命中次数
    self._CurGameRemainTipGridTime = 0 -- 当局游戏剩余提示冷却时间
    self._CurGameCumNumOfError = 0 -- 当局游戏累计错误次数
    self._IsStageFirstUpdate = false -- 是否是stage生成后的第一次刷新
end

function XNonogramControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XNonogramControl:RemoveAgencyEvent()

end

function XNonogramControl:OnRelease()
    self._GameState = XEnumConst.Nonogram.NonogramStageGameStatus.None
    self._CurGameUnlockCGItemCount = 0
    self._CurGameRemainTime = 0
    self._CurGameReadyRemainTime = 0
    self:_StopUpdater()
    self._CurGameGridMap = nil
    self._CurGameGridOpenMap = nil
    self._CurGameRightIndexMap = nil
    self._LastPausedStatus = nil
    self._CurDisplayTipGridKeyStr = nil
    self._CurChapterShowTipCD = 0
    self._CurChapterShowTipErrorHitTimes = 0
    self._CurGameRemainTipGridTime = 0
    self._CurGameCumNumOfError = 0
    self._IsStageFirstUpdate = nil
end

--region 公共接口

function XNonogramControl:GetCurActivityTitle()
    local curActivityId = self._Agency:GetCurActivityId()
    if XTool.IsNumberValid(curActivityId) then
        return self._Model:GetActivityNameById(curActivityId)
    end

    return ""
end

function XNonogramControl:GetEndTime()
    local curActivityId = self._Agency:GetCurActivityId()
    if XTool.IsNumberValid(curActivityId) then
        local timeId = self._Model:GetActivityTimeIdById(curActivityId)
        if XTool.IsNumberValid(timeId) then
            return XFunctionManager.GetEndTimeByTimeId(timeId)
        end
    end

    return 0
end

function XNonogramControl:HandleActivityEndTime()
    XLuaUiManager.RunMain()
    XUiManager.TipText("ActivityAlreadyOver")
end

function XNonogramControl:GetChapterIds()
    local curActivityId = self._Agency:GetCurActivityId()
    if XTool.IsNumberValid(curActivityId) then
        local chapterIds = self._Model:GetActivityChapterIdsById(curActivityId)
        --local rebrushChapterId = self._Model:GetActivityRebrushChapterById(curActivityId)
        --if XTool.IsNumberValid(rebrushChapterId) then
        --    table.insert(chapterIds,rebrushChapterId)
        --end
        return chapterIds
    end
    
    return {}
end

function XNonogramControl:GetChapterIdByIndex(index)
    return self:GetChapterIds()[index]
end

-- 获取当前进度的章节索引（当前玩到哪一章了）
function XNonogramControl:GetCurChapterIndexAndId()
    return self._Agency:GetCurChapterIndexAndId()
end

function XNonogramControl:GetCurChapterId()
    return self._Model:GetCurGameChapterId()
end

function XNonogramControl:GetBtnChapterImagePath(chapterId)
    return self._Model:GetBtnChapterImagePathById(chapterId)
end

function XNonogramControl:GetChapterName(chapterId)
    return self._Model:GetChapterNameById(chapterId)
end

function XNonogramControl:GetChapterState(chapterId)
    return self._Agency:GetChapterState(chapterId)
end

function XNonogramControl:GetCGImagePath(chapterId)
    return self._Model:GetCGTexturePathById(chapterId)
end

function XNonogramControl:GetUnlockItemNeedCount(chapterId)
    return self._Model:GetChapterUnlockItemNumById(chapterId)
end

function XNonogramControl:GetCGDetail(chapterId)
    return self._Model:GetCGDetailById(chapterId)
end

function XNonogramControl:GetUnlockCgItemId(chapterId)
    return self._Model:GetChapterUnlockCgItemIdById(chapterId)
end

function XNonogramControl:GetUnlockCgItemNum(chapterId)
    return self._Model:GetChapterUnlockCgItemNumById(chapterId)
end

function XNonogramControl:GetPlayTips(chapterId)
    return self._Model:GetPlayTipsById(chapterId)
end

function XNonogramControl:GetChapterRewardId(chapterId)
    return self._Model:GetChapterCgRewardIdById(chapterId)
end

function XNonogramControl:GetChapterTimeLimit(chapterId)
    return self._Model:GetChapterTimeLimitById(chapterId)
end

function XNonogramControl:GetCurGameStageId()
    return self._Model:GetCurGameStageId()
end

-- 动态字段
function XNonogramControl:GetGameStatus()
    return self._GameState
end

function XNonogramControl:SetGameStatus(value)
    self._GameState = value
end

function XNonogramControl:AddOneGameUnlockCGItemCount(value)
    self._CurGameUnlockCGItemCount = self._CurGameUnlockCGItemCount + value
end

function XNonogramControl:GetOneGameUnlockCGItemCount()
    return self._CurGameUnlockCGItemCount
end

function XNonogramControl:ResetOneGameUnlockCGItemCount()
    self._CurGameUnlockCGItemCount = 0
end

function XNonogramControl:GetGameRemainTime()
    return self._CurGameRemainTime
end

function XNonogramControl:GetGameRemainTimeProgress()
    local curGameChapterId = self._Model:GetCurGameChapterId()
    if not XTool.IsNumberValid(curGameChapterId) then
        return 0
    end

    if self._CurGameRemainTime > 0 then
        return self._CurGameRemainTime / self:GetChapterTimeLimit(curGameChapterId)
    else
        return 0
    end
end

function XNonogramControl:GetGameReadyRemainTime()
    return self._CurGameReadyRemainTime
end

function XNonogramControl:GetCurGameGridMap()
    return self._CurGameGridMap
end

function XNonogramControl:GetOneGamePlayMapCount()
    local curChapterId = self._Model:GetCurGameChapterId()
    if not XTool.IsNumberValid(curChapterId) then
        return 0
    end

    ---@type XNonogramChapter
    local chapterData = self._Model:GetChapterData(curChapterId)
    if not chapterData then
        return 0
    end

    return XTool.GetTableCount(chapterData:GetStageList())
end

--检查函数
function XNonogramControl:CheckChapterUnLock(chapterId)
    return self._Agency:CheckChapterUnLock(chapterId)
end

function XNonogramControl:CheckChapterUnlockCg(chapterId)
    return self._Agency:CheckChapterUnlockCg(chapterId)
end

function XNonogramControl:CheckCanSelectChapter(index)
    local curChapterId = self:GetChapterIdByIndex(index)
    if not XTool.IsNumberValid(curChapterId) then
        return false
    end

    local preChapterId = self._Model:GetChapterPreChapterIdById(curChapterId)
    if not XTool.IsNumberValid(preChapterId) then
        return true
    end

    return self:CheckChapterUnlockCg(preChapterId)
end

function XNonogramControl:CheckGameStatus(status)
    return self._GameState == status
end

function XNonogramControl:CheckGridBlockRight(rowIndex, colIndex)
    if not self._CurGameGridMap[rowIndex] then
        return false
    end

    if not self._CurGameGridMap[rowIndex][colIndex] then
        return false
    end

    return self._CurGameGridMap[rowIndex][colIndex] == 1
end

function XNonogramControl:CheckStageFinish()
    if XTool.IsTableEmpty(self._CurGameGridMap) then
        return false
    end

    for rowIndex, colData in ipairs(self._CurGameGridMap) do
        for colIndex, value in ipairs(colData) do
            if value == 1 then
                if not self._CurGameGridOpenMap[rowIndex] or not self._CurGameGridOpenMap[rowIndex][colIndex] or
                        self._CurGameGridOpenMap[rowIndex][colIndex] == 0
                then
                    return false
                end
            end
        end
    end

    return true
end

function XNonogramControl:CheckPassAllStage()
    local curStageId = self._Model:GetCurGameStageId()
    ---@type XNonogramChapter
    local curChapterData = self._Model:GetChapterData(self._Model:GetCurGameChapterId())
    if curChapterData then
        return curChapterData:GetChapterStatus() == XEnumConst.Nonogram.NonogramChapterStatus.Init and not XTool.IsNumberValid(curStageId)
    end

    return not XTool.IsNumberValid(curStageId)
end

function XNonogramControl:CheckChapterCanUnLockCG(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return false
    end

    local chapterData = self._Model:GetChapterData(chapterId)
    if not chapterData then
        return false
    end

    if chapterData:GetChapterStatus() == XEnumConst.Nonogram.NonogramChapterStatus.Init then
        local unlockCgItemId = self._Model:GetChapterUnlockCgItemIdById(chapterId)
        local unlockCgNeedCount = self._Model:GetChapterUnlockCgItemNumById(chapterId)
        return XDataCenter.ItemManager.CheckItemCountById(unlockCgItemId, unlockCgNeedCount)
    end

    return false
end

function XNonogramControl:CheckChapterIsRebrushById(chapterId)
    return self._Model:CheckChapterIsRebrushById(chapterId)
end

--操作
function XNonogramControl:StartCountDown()
    self._CurGameReadyRemainTime = READY_TIME
    self._GameState = XEnumConst.Nonogram.NonogramStageGameStatus.Ready
end

function XNonogramControl:PauseGame()
    if self._GameState == XEnumConst.Nonogram.NonogramStageGameStatus.Playing or
            self._GameState == XEnumConst.Nonogram.NonogramStageGameStatus.Ready
    then
        self._LastPausedStatus = self._GameState
        self._GameState = XEnumConst.Nonogram.NonogramStageGameStatus.Pause
    end
end

function XNonogramControl:ResumeGame()
    if self._GameState == XEnumConst.Nonogram.NonogramStageGameStatus.Pause then
        if self._LastPausedStatus then
            self._GameState = self._LastPausedStatus
            self._LastPausedStatus = nil
        else
            self._GameState = XEnumConst.Nonogram.NonogramStageGameStatus.Ready
        end
    end
end

function XNonogramControl:OnGridBlockClick(rowIndex, colIndex)
    if not self._CurGameGridOpenMap[rowIndex] then
        return
    end

    if not self._CurGameGridOpenMap[rowIndex][colIndex] then
        return
    end

    if self._CurGameGridOpenMap[rowIndex][colIndex] == 1 then
        return
    end

    self._CurGameGridOpenMap[rowIndex][colIndex] = 1
    
    local isRight = self:CheckGridBlockRight(rowIndex, colIndex)

    if isRight then
        local displayTipGridKeyStr = rowIndex .. "|" .. colIndex
        self._CurGameRightIndexMap[displayTipGridKeyStr] = nil
        if not string.IsNilOrEmpty(self._CurDisplayTipGridKeyStr) and displayTipGridKeyStr == self._CurDisplayTipGridKeyStr then
            self._CurDisplayTipGridKeyStr = nil
            self._CurGameCumNumOfError = 0
        end
        XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_GRID_BLOCK_OPEN, rowIndex, colIndex, isRight)
        self:_HandleRowAndColumnFinish(rowIndex, colIndex)
    else
        if not self._CurDisplayTipGridKeyStr then
            self._CurGameCumNumOfError = self._CurGameCumNumOfError + 1
        end
        local deductTime = self._Model:GetChapterDeductTimeById(self._Model:GetCurGameChapterId())
        if XTool.IsNumberValid(deductTime) then
            self._CurGameRemainTime = self._CurGameRemainTime - deductTime
            XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_GRID_BLOCK_OPEN, rowIndex, colIndex, isRight, deductTime)
        else
            XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_GRID_BLOCK_OPEN, rowIndex, colIndex, isRight)
        end
    end
    
    self:_ResetCurGameRemainTipGridTime()
    self:_ShowTipGridByErrorTimes()
    
    if self:CheckStageFinish() then
        self:RequestFinishStage(self._Model:GetCurGameChapterId(), self:GetCurGameStageId(), self._CurGameGridOpenMap, self._CurGameRemainTime, function(rewardGoodsList)
            local unlockCGItemId = self:GetUnlockCgItemId(self:GetCurChapterId())
            if XTool.IsNumberValid(unlockCGItemId) then
                for _, rewardGoods in pairs(rewardGoodsList) do
                    if rewardGoods.TemplateId == unlockCGItemId then
                        self:AddOneGameUnlockCGItemCount(rewardGoods.Count)
                    end
                end
            end
            XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_STAGE_FINISH)
        end)
    end
end

--endregion

--region 私有接口

function XNonogramControl:_InitCurGameData()
    self._GameState = XEnumConst.Nonogram.NonogramStageGameStatus.Init
    self._CurGameRemainTime = self:GetChapterTimeLimit(self._Model:GetCurGameChapterId())
    self._CurChapterShowTipCD = self._Model:GetShowTipCDById(self._Model:GetCurGameChapterId())
    self._CurChapterShowTipErrorHitTimes = self._Model:GetShowTipErrorHitTimesById(self._Model:GetCurGameChapterId())
    self._CurGameUnlockCGItemCount = 0

    self:_RefreshCurGameData()

    self:_StartUpdater()
end

function XNonogramControl:_RefreshCurGameData()
    self._CurGameReadyRemainTime = READY_TIME
    local curStageId = self._Model:GetCurGameStageId()
    if XTool.IsNumberValid(curStageId) then
        local stageTemplateId = self._Model:GetStageGridTemplateIdById(curStageId)
        self._CurGameGridMap = self._Model:GetGridMapByTemplateId(stageTemplateId)
    end

    self._CurGameGridOpenMap = {}
    self._CurGameRightIndexMap = {}
    for rowIndex, columnData in ipairs(self._CurGameGridMap) do
        if not self._CurGameGridOpenMap[rowIndex] then
            self._CurGameGridOpenMap[rowIndex] = {}
        end
        for columnIndex, value in ipairs(columnData) do
            self._CurGameGridOpenMap[rowIndex][columnIndex] = 0
            if value == 1 then
                self._CurGameRightIndexMap[rowIndex .. "|" .. columnIndex] = { RowIndex = rowIndex, ColumnIndex = columnIndex }
            end
        end
    end
    self:_ResetCurGameRemainTipGridTime()
    self._CurDisplayTipGridKeyStr = nil
    self._CurGameCumNumOfError = 0
    self._IsStageFirstUpdate = true
end

function XNonogramControl:_StartUpdater()
    self._UpdaterId = XScheduleManager.ScheduleForeverEx(handler(self, self._OnUpdate), UPDATE_INTERVAL)
end

function XNonogramControl:_StopUpdater()
    if XTool.IsNumberValid(self._UpdaterId) then
        XScheduleManager.UnSchedule(self._UpdaterId)
        self._UpdaterId = nil
    end
end

function XNonogramControl:_OnUpdate()
    if self._GameState == XEnumConst.Nonogram.NonogramStageGameStatus.Playing then
        self:_UpdateGameRemainTime()
        self:_UpdateGameTipGrid()
        self._IsStageFirstUpdate = false
    elseif self._GameState == XEnumConst.Nonogram.NonogramStageGameStatus.Ready then
        self:_UpdateGameReadyRemainTime()
    end
end

function XNonogramControl:_UpdateGameRemainTime()
    self._CurGameRemainTime = self._CurGameRemainTime - UPDATE_INTERVAL_SEC
    if self._CurGameRemainTime <= 0 then
        self._CurGameRemainTime = 0
        self._GameState = XEnumConst.Nonogram.NonogramStageGameStatus.Finish
        self:RequestChapterExit(self._Model:GetCurGameChapterId(), function()
            XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_GAME_FINISH)
        end)
    end
end

function XNonogramControl:_UpdateGameReadyRemainTime()
    self._CurGameReadyRemainTime = self._CurGameReadyRemainTime - UPDATE_INTERVAL_SEC
    if self._CurGameReadyRemainTime <= 0 then
        self._CurGameReadyRemainTime = 0
        XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_READY_END)
        self._GameState = XEnumConst.Nonogram.NonogramStageGameStatus.Playing
    end
end

function XNonogramControl:_UpdateGameTipGrid()
    if self._IsStageFirstUpdate then
        self:_ShowFirstStageTipGrid()
    end
    
    if not string.IsNilOrEmpty(self._CurDisplayTipGridKeyStr) then
        return
    end
    
    if self._CurGameRemainTipGridTime == 0 then
        return
    end

    self._CurGameRemainTipGridTime = self._CurGameRemainTipGridTime - UPDATE_INTERVAL_SEC
    if self._CurGameRemainTipGridTime <= 0 then
        self:_ShowTipGrid()
        self._CurGameRemainTipGridTime = 0
    end
end

function XNonogramControl:_ShowTipGrid(rowAndColumnIndexStr)
    if string.IsNilOrEmpty(rowAndColumnIndexStr) then
        local count = XTool.GetTableCount(self._CurGameRightIndexMap)
        if count > 0 then
            local randomIndex = math.random(1, count)
            local index = 1
            for keyStr, value in pairs(self._CurGameRightIndexMap) do
                if index == randomIndex then
                    local rowIndex = value.RowIndex
                    local columnIndex = value.ColumnIndex
                    self._CurDisplayTipGridKeyStr = keyStr
                    XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_GRID_BLOCK_TIP, rowIndex, columnIndex)
                end
                index = index + 1
            end
        end
    else
        if self._CurGameRightIndexMap[rowAndColumnIndexStr] then
            local rowIndex = self._CurGameRightIndexMap[rowAndColumnIndexStr].RowIndex
            local columnIndex = self._CurGameRightIndexMap[rowAndColumnIndexStr].ColumnIndex
            self._CurDisplayTipGridKeyStr = rowAndColumnIndexStr
            XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_GRID_BLOCK_TIP, rowIndex, columnIndex)
        end
    end
    self._CurGameCumNumOfError = 0
end

function XNonogramControl:_ResetCurGameRemainTipGridTime()
    self._CurGameRemainTipGridTime = self._CurChapterShowTipCD
end

function XNonogramControl:_ShowTipGridByErrorTimes()
    if not XTool.IsNumberValid(self._CurChapterShowTipErrorHitTimes) then
        return
    end

    if self._CurGameCumNumOfError > 0 then
        if self._CurGameCumNumOfError == self._CurChapterShowTipErrorHitTimes then
            self:_ShowTipGrid()
        end
    end
end

function XNonogramControl:_ShowFirstStageTipGrid()
    local firstTipIndexStr = self._Model:GetStageFirstTipIndexStrById(self._Model:GetCurGameStageId())
    if not string.IsNilOrEmpty(firstTipIndexStr) then
        self:_ShowTipGrid(firstTipIndexStr)
    end
end

function XNonogramControl:_HandleRowAndColumnFinish(rowIndex, columnIndex)
    local isAllRowGridsFinish = true
    local isAllColumnGridsFinish = true
    local allRowGrids = self._CurGameGridMap[rowIndex]
    
    for index, value in ipairs(allRowGrids) do
        if value == 1 and self._CurGameGridOpenMap[rowIndex][index] ~= 1 then
            isAllRowGridsFinish = false
            break
        end
    end

    for index, rowGrids in ipairs(self._CurGameGridMap) do
        if rowGrids[columnIndex] == 1 and self._CurGameGridOpenMap[index][columnIndex] ~= 1 then
            isAllColumnGridsFinish = false
            break
        end
    end
    
    if not isAllRowGridsFinish then rowIndex = 0 end
    if not isAllColumnGridsFinish then columnIndex = 0 end
    XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_ROW_COLUMN_FINISH, rowIndex, columnIndex)
end
--endregion

--region 协议转发

function XNonogramControl:RequestChapterUnlock(chapterId, cb)
    self._Agency:RequestChapterUnlock(chapterId, cb)
end

function XNonogramControl:RequestChapterStart(chapterId, cb)
    self._Agency:RequestChapterStart(chapterId, function()
        self:_InitCurGameData()
        if cb then
            cb()
        end
    end)
end

function XNonogramControl:RequestFinishStage(chapterId, stageId, grids, remainTime, cb)
    self:_StopUpdater()
    self._Agency:RequestFinishStage(chapterId, stageId, grids, remainTime, function(rewardGoodsList)
        if cb then
            cb(rewardGoodsList)
        end
        if self:CheckPassAllStage() then
            --self:_StopUpdater()
            self._GameState = XEnumConst.Nonogram.NonogramStageGameStatus.Finish
            XEventManager.DispatchEvent(XEventId.EVENT_NONOGRAM_GAME_FINISH)
        else
            self:_RefreshCurGameData()
            self:_StartUpdater()
        end
    end)
end

function XNonogramControl:RequestUnlockCg(chapterId, cb)
    self._Agency:RequestUnlockCg(chapterId, cb)
end

function XNonogramControl:RequestChapterExit(chapterId, cb)
    self._Agency:RequestChapterExit(chapterId, function()
        self:_StopUpdater()
        if cb then
            cb()
        end
    end)
end

--endregion

return XNonogramControl