---@class XConnectingLineControl : XControl
---@field private _Model XConnectingLineModel
local XConnectingLineControl = XClass(XControl, "XConnectingLineControl")

function XConnectingLineControl:OnInit()
    self._UiState = XEnumConst.CONNECTING_LINE.UI_STATUS.CHAPTER
    self._ChapterId = false
end

function XConnectingLineControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XConnectingLineControl:RemoveAgencyEvent()

end

function XConnectingLineControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

---@return XConnectingLineGame
function XConnectingLineControl:GetGame()
    return self._Model:GetGame()
end

---@return XConnectingLineGame
function XConnectingLineControl:InitGame(gridX, gridY)
    self._Model:InitGame(gridX, gridY)
    local game = self._Model:GetGame()
    return game
end

---@param game XConnectingLineGame
function XConnectingLineControl:TestExecute(game, operationList)
    local OPERATION_TYPE = XEnumConst.CONNECTING_LINE.OPERATION_TYPE
    local gridSize = game:GetGridSize()
    for i = 1, #operationList do
        local data = operationList[i]

        ---@type XConnectingLineOperation
        local operation = require("XModule/XConnectingLine/XEntity/XConnectingLineOperation").New()
        operation:SetPos(data.X * gridSize.X - gridSize.X / 2, data.Y * gridSize.Y - gridSize.Y / 2)
        if i == 1 then
            operation.Type = OPERATION_TYPE.POINT_DOWN
        elseif i == #operationList then
            operation.Type = OPERATION_TYPE.POINT_UP
        else
            operation.Type = OPERATION_TYPE.POINT_MOVE
        end
        game:Execute(operation)
        game:LogBuffer()
    end
end

function XConnectingLineControl:GetUiData()
    return self._Model:GetUiData()
end

function XConnectingLineControl:Update()
    self._Model:Update()
end

function XConnectingLineControl:UpdateTime()
    self._Model:UpdateTime()
end

function XConnectingLineControl:UpdateGameInfo()
    self._Model:UpdateGameInfo()
end

function XConnectingLineControl:InitStage()
    self._Model:InitStage()
end

function XConnectingLineControl:IsLastStage()
    return self._Model:IsLastStage()
end

function XConnectingLineControl:IsGameInit()
    return self._Model:GetGame() and true or false
end

function XConnectingLineControl:IsActivityOpen()
    return self._Model:IsActivityOpen()
end

function XConnectingLineControl:IsCanStartGame()
    local itemId = self:GetCoinItemId()
    if not itemId then
        return true
    end
    local itemAmount = XDataCenter.ItemManager.GetCount(itemId)
    local uiData = self:GetUiData()
    local needAmount = uiData.NeedMoney or 0
    return itemAmount >= needAmount
end

function XConnectingLineControl:GetStatus()
    return self._Model:GetStatus()
end

function XConnectingLineControl:RequestFinish()
    local game = self:GetGame()
    if game then
        game:SetHasRequested(true)
    end
    XNetwork.Call("ConnectingLineStageCompleteRequest", {}, function(res)
        if res.Code ~= XCode.Success then
            if game then
                game:SetHasRequested(false)
            end
            XUiManager.TipCode(res.Code)
            return
        end
        local data = res.ConnectingLineData
        if data.Status ~= XEnumConst.CONNECTING_LINE.STAGE_STATUS.COMPLETE then
            XLog.Error("[XConnectingLineControl] request finish success, but status is incorrect", data.Status)
        end
        self._Model:SetDataFromServer(data)
    end)
end

function XConnectingLineControl:RequestStartGame()
    XNetwork.Call("ConnectingLineStageUnlockRequest", {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local data = res.ConnectingLineData
        if data.Status ~= XEnumConst.CONNECTING_LINE.STAGE_STATUS.UNLOCK then
            XLog.Error("[XConnectingLineControl] request unlock success, but status is incorrect", data.Status)
        end
        self._Model:SetDataFromServer(data)
    end)
end

function XConnectingLineControl:RequestReward()
    XNetwork.Call("ConnectingLineStageAwardRequest", {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local data = res.ConnectingLineData
        if self._Model:IsLastStage() then
            if data.Status ~= XEnumConst.CONNECTING_LINE.STAGE_STATUS.REWARD then
                XLog.Error("[XConnectingLineControl] request reward success, but status is incorrect", data.Status)
            end
        else
            if data.Status ~= XEnumConst.CONNECTING_LINE.STAGE_STATUS.LOCK then
                XLog.Error("[XConnectingLineControl] request reward success, but status is incorrect", data.Status)
            end
        end
        self._Model:SetDataFromServer(data, false)

        if res.AwardList then
            XUiManager.OpenUiObtain(res.AwardList, nil, function()
                -- 延迟更新界面
                self:SetUiStatus(XEnumConst.CONNECTING_LINE.UI_STATUS.CHAPTER)
                XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_UPDATE)
            end)
        end
    end)
end

function XConnectingLineControl:InitBubble()
    self._Model:InitBubble()
end

function XConnectingLineControl:GetUiDataReward()
    self._Model:UpdateRewardText()
    return self._Model:GetUiDataReward()
end

function XConnectingLineControl:GetUiStatus()
    return self._UiState
end

function XConnectingLineControl:GetChapterList()
    local chapterList = self._Model:GetChapterList()
    local data = {}
    for i = 1, #chapterList do
        local config = chapterList[i]
        ---@class XConnectingLineChapterData
        local chapter = {
            Id = config.Id,
            Name = config.Name,
            ChapterId = config.Id,
            IsUnlock = false,
            IsShowRed = false,
            IsInTime = false,
            TimeId = 0,
        }
        self:UpdateChapterData(chapter)
        data[#data + 1] = chapter
    end
    return data
end

---@param chapterData XConnectingLineChapterData
function XConnectingLineControl:UpdateChapterData(chapterData)
    local config = self._Model:GetChapterConfig(chapterData.Id)
    local chapterId = config.Id
    local isUnlock = self._Model:IsChapterUnlock(chapterId)
    local timeId = self._Model:GetChapterTimeId(chapterId)
    local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId, true)
    chapterData.IsUnlock = isUnlock and isInTime
    chapterData.IsShowRed = isUnlock and isInTime and self._Model:IsChapterJustUnlock(chapterId)
    chapterData.IsInTime = isInTime
    chapterData.TimeId = timeId
end

function XConnectingLineControl:IsChapterPassed()
    return self._Model:IsChapterPassed(self._ChapterId)
end

function XConnectingLineControl:GetStageList()
    local data = {}

    local stageList = self._Model:GetStageListByChapterId(self._ChapterId)
    for i = 1, #stageList do
        local config = stageList[i]
        local rewardId = config.RewardId
        local rewardList = XRewardManager.GetRewardList(rewardId)
        local isPassed = self._Model:IsStagePassed(config.Id)
        ---@class XConnectingLineStageData
        local stage = {
            Name = config.Name,
            CostItemNum = config.CostItemNum,
            CG = isPassed and config.UnlockPic or config.LockPic,
            Reward = rewardList,
            IsUnlock = self._Model:IsStageUnlock(config.Id),
            IsPassed = isPassed,
            StageId = config.Id
        }
        data[#data + 1] = stage
    end

    return data
end

function XConnectingLineControl:SetChapterId(chapterId)
    self._ChapterId = chapterId
    self._Model:SetChapterNotJustUnlock(chapterId)
end

function XConnectingLineControl:OnClickStage(stageId)
    if stageId == self._Model:GetCurrentStageId() and not self._Model:IsFinish() then
        if self._Model:IsGameUnlock() then
            self:SetUiStatus(XEnumConst.CONNECTING_LINE.UI_STATUS.GAME)
        else
            if self:IsCanStartGame() then
                if self._Model:IsGameLock() then
                    self:RequestStartGame()
                end
                self:SetUiStatus(XEnumConst.CONNECTING_LINE.UI_STATUS.GAME)
            else
                XUiManager.TipMsg(XUiHelper.GetText("ConnectingLineMoney"))
            end
        end
    else
        if self._Model:IsStagePassed(stageId) then
            XUiManager.TipMsg(XUiHelper.GetText("ConnectingLineCompleteStage"))
        end
    end
end

function XConnectingLineControl:SetUiStatus(state)
    self._UiState = state
    XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_UPDATE)
end

function XConnectingLineControl:GetChapterCG()
    return self._Model:GetChapterCG(self._ChapterId)
end

function XConnectingLineControl:UpdateMoney()
    self._Model:UpdateMoney()
end

function XConnectingLineControl:IsPlaying()
    return self._UiState == XEnumConst.CONNECTING_LINE.UI_STATUS.GAME
end

function XConnectingLineControl:GetCoinItemId()
    return self._Model:GetCoinItemId()
end

return XConnectingLineControl