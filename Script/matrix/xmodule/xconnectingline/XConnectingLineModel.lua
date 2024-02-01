local TableKey = {
    ConnectingLineGrid = { DirPath = XConfigUtil.DirectoryType.Client },
    ConnectingLineHead = { DirPath = XConfigUtil.DirectoryType.Client },
    ConnectingLineActivity = {},
    ConnectingLineStage = { CacheType = XConfigUtil.CacheType.Normal },
    ConnectingLineBubble = { DirPath = XConfigUtil.DirectoryType.Client },
}

---@class XConnectingLineModel : XModel
local XConnectingLineModel = XClass(XModel, "XConnectingLineModel")

function XConnectingLineModel:OnInit()

    ---@type XConnectingLineGame
    self._Game = false

    self._ConfigUtil:InitConfigByTableKey("MiniActivity/ConnectingLine", TableKey)

    self._UiData = {
        TextTime = false,
        TextLink = false,
        TextLightGrid = false,
        Reward = false,
        Progress = false,
        HairPicture = false,
        FacePicture = false,
        BodyPicture = false,
        IsEnableReset = false,
        IconMoney = false,
        TextMoney = false,
        NeedMoney = 0,
        IsRewardReceived = false,
        ---@type XConnectingLineModelBubble[]
        BubbleDataSource = {},
        TextStageName = false,
        TextReward = false,
        PlayAnimationGridLoop = false,
    }

    self._UiDataReward = {
        TextArray = false,
    }

    ---@type XTable.XTableConnectingLineStage[]
    self._StageList = nil

    self._ActivityId = 0
    self._CurrentStageId = 0
    self._Status = XEnumConst.CONNECTING_LINE.STAGE_STATUS.LOCK
end

function XConnectingLineModel:ClearPrivate()
    --这里执行内部数据清理
    self._UiData = {}
    self._Game = false
end

function XConnectingLineModel:ResetAll()
    --这里执行重登数据清理
    self._ActivityId = 0
    self._CurrentStageId = 0
    self._StageList = nil
    self._Status = XEnumConst.CONNECTING_LINE.STAGE_STATUS.LOCK
end

----------public start----------
---XConnectingLineData
function XConnectingLineModel:SetDataFromServer(data, sendEvent)
    if self._ActivityId ~= data.ActivityId then
        self._StageList = nil
    end
    self._ActivityId = data.ActivityId or 0
    self._CurrentStageId = data.StageId
    self:SetStatus(data.Status)
    if sendEvent == true or sendEvent == nil then
        XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_UPDATE)
    end
end

function XConnectingLineModel:InitGame(gridX, gridY)
    local stageId = self._CurrentStageId
    ---@type XConnectingLineGame
    local game = require("XModule/XConnectingLine/XEntity/XConnectingLineGame").New()
    self._Game = game

    local gridsConfig = self._ConfigUtil:GetByTableKey(TableKey.ConnectingLineGrid)
    local avatarConfig = self._ConfigUtil:GetByTableKey(TableKey.ConnectingLineHead)
    game:SetGridSize(gridX, gridY)
    game:SetStageId(stageId)
    game:InitGrids(gridsConfig, avatarConfig)
    --game:SetDragOffset()
    --game:LogMap()
    self:UpdateMoney()
end

---@return XConnectingLineGame
function XConnectingLineModel:GetGame()
    return self._Game
end

function XConnectingLineModel:IsActivityOpen()
    if self._ActivityId > 0 then
        local timeId = self:GetTimerId()
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end
    return false
end

function XConnectingLineModel:GetUiData()
    return self._UiData
end

function XConnectingLineModel:InitStage()
    if not self._StageList then
        local stageConfigs = self._ConfigUtil:GetByTableKey(TableKey.ConnectingLineStage)
        self._StageList = {}
        for i, stageConfig in pairs(stageConfigs) do
            if stageConfig.ActivityId == self._ActivityId then
                self._StageList[#self._StageList + 1] = stageConfig
            end
        end
        table.sort(self._StageList, function(a, b)
            return a.Id < b.Id
        end)
    end
end

function XConnectingLineModel:UpdateGameInfo()
    local uiData = self._UiData

    local isFinish = self:IsFinish()

    local linkedAmount
    local avatarCount = self._Game:GetAvatarAmount()
    if isFinish then
        linkedAmount = avatarCount
    else
        linkedAmount = self._Game:GetLinkedAmount()
    end
    uiData.TextLink = linkedAmount .. "/" .. avatarCount
    uiData.IsEnableReset = linkedAmount > 0 and not isFinish

    local lightGridAmount
    local gridAmount = self._Game:GetGridAmount()
    if isFinish then
        lightGridAmount = gridAmount
    else
        lightGridAmount = self._Game:GetLightGridAmount()
    end
    uiData.TextLightGrid = lightGridAmount .. "/" .. gridAmount

    if linkedAmount == avatarCount and not isFinish then
        uiData.PlayAnimationGridLoop = true
    else
        uiData.PlayAnimationGridLoop = false
    end
end

function XConnectingLineModel:GetTimerId()
    local activityConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ConnectingLineActivity, self._ActivityId)
    if activityConfig then
        local timeId = activityConfig.TimeId
        return timeId
    end
    return false
end

function XConnectingLineModel:UpdateTime()
    local uiData = self._UiData
    local timeId = self:GetTimerId()
    if timeId then
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        local currentTime = XTime.GetServerNowTimestamp()
        local remainTime = endTime - currentTime
        remainTime = math.max(0, remainTime)
        uiData.TextTime = XUiHelper.GetTime(remainTime)
    end
end

function XConnectingLineModel:GetCurrentStageConfig()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ConnectingLineStage, self._CurrentStageId)
end

function XConnectingLineModel:Update()
    local uiData = self._UiData

    local stageConfig = self:GetCurrentStageConfig()
    local rewardId = stageConfig.RewardId
    if rewardId and rewardId > 0 then
        uiData.Reward = XRewardManager.GetRewardList(rewardId)
    else
        uiData.Reward = {}
    end

    local activityConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ConnectingLineActivity, self._ActivityId)
    local progress = 1
    if activityConfig then
        --local valueMax = activityConfig.StageNum
        for i = 1, #self._StageList do
            local stage = self._StageList[i]
            if stage.Id == self._CurrentStageId then
                progress = i
            end
        end
        uiData.BodyPicture = activityConfig.NpcPic
        uiData.HairPicture = activityConfig.HairPic
    end
    uiData.TextStageName = XUiHelper.GetText("ConnectingLineStage", progress, stageConfig.Name)
    --uiData.TextReward = XUiHelper.GetText("ConnectingLineTextReward", progress, #self._StageList)
    uiData.TextReward = XUiHelper.GetText("ConnectingLineTextReward")

    if self:GetStatus() == XEnumConst.CONNECTING_LINE.STAGE_STATUS.REWARD then
        uiData.IsRewardReceived = true
    else
        uiData.IsRewardReceived = false
    end
end

function XConnectingLineModel:GetNextStage()
    for i = 1, #self._StageList do
        local stageConfig = self._StageList[i]
        if stageConfig.Id == self._CurrentStageId then
            local nextStage = self._StageList[i + 1]
            if nextStage then
                return nextStage.Id
            end
        end
    end
end

function XConnectingLineModel:GetCostItemNum(stageId)
    local stageConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ConnectingLineStage, stageId)
    if not stageConfig then
        return 0
    end
    return stageConfig.CostItemNum
end

function XConnectingLineModel:IsNextStageCanChallenge()
    if self:IsFinish() then
        return false
    end
    if self:GetStatus() == XEnumConst.CONNECTING_LINE.STAGE_STATUS.UNLOCK then
        return true
    end

    local stageId = self._CurrentStageId
    if stageId and stageId > 0 then
        local cost = self:GetCostItemNum(stageId)
        local itemId = XDataCenter.ItemManager.ItemId.ConnectingLine
        return XDataCenter.ItemManager.CheckItemCountById(itemId, cost)
    end
    return false
end

function XConnectingLineModel:UpdateMoney()
    local uiData = self._UiData
    local itemId = XDataCenter.ItemManager.ItemId.ConnectingLine
    uiData.IconMoney = XDataCenter.ItemManager.GetItemIcon(itemId)
    local stageConfig = self:GetCurrentStageConfig()
    uiData.TextMoney = "x" .. stageConfig.CostItemNum
    uiData.NeedMoney = stageConfig.CostItemNum
end

function XConnectingLineModel:IsLastStage()
    local lastStage = self._StageList[#self._StageList]
    if lastStage then
        return lastStage.Id == self._CurrentStageId
    end
    return false
end

function XConnectingLineModel:SetStatus(status)
    self._Status = status
end

function XConnectingLineModel:GetStatus()
    return self._Status
end

function XConnectingLineModel:IsFinish()
    return self:IsLastStage() and self:GetStatus() == XEnumConst.CONNECTING_LINE.STAGE_STATUS.REWARD
end

function XConnectingLineModel:InitBubble()
    self._UiData.BubbleDataSource = {}
    local configs = self._ConfigUtil:GetByTableKey(TableKey.ConnectingLineBubble)
    for i, config in pairs(configs) do
        if config.ActivityId == self._ActivityId then
            local type = config.Type
            for j = 1, #config.Text do
                ---@class XConnectingLineModelBubble
                local bubble = {
                    Text = config.Text[j],
                    Face = config.Face,
                    Duration = config.Duration,
                    Type = type
                }
                self._UiData.BubbleDataSource[type] = self._UiData.BubbleDataSource[type] or {}
                table.insert(self._UiData.BubbleDataSource[type], bubble)
            end
        end
    end
end

function XConnectingLineModel:UpdateRewardText()
    local currentStage = self:GetCurrentStageConfig()
    if currentStage then
        self._UiDataReward.TextArray = currentStage.RewardText
    else
        self._UiDataReward.TextArray = {}
    end
end

function XConnectingLineModel:GetUiDataReward()
    return self._UiDataReward
end

return XConnectingLineModel