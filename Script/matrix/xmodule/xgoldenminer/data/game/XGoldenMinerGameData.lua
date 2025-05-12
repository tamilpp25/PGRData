---@class XGoldenMinerGrabReportInfo
---@field Count number
---@field Score number
---@field ExScore number

--游戏内数据
---@class XGoldenMinerGameData
local XGoldenMinerGameData = XClass(nil, "XGoldenMinerGameData")

function XGoldenMinerGameData:Ctor(mapId)
    self._MapId = mapId
    self._MapScore = 0
    self._AllScore = 0
    self._ChangeScore = 0
    self._CurCharacterId = 0
    self._CurPassStageList = {}
    self._Time = 0
    self._TimeScore = 0
    self._UsedTime = 0
    self._PartnerRadarScore = 0 -- 掘金者雷达结算分数
    self._HookTypeList = {}
    ---@type XGoldenMinerMapStoneData[]
    self._MapStoneDataList = {}
    ---@type XGoldenMinerHideTaskInfo[]
    self._HideTaskInfoList = {}
    self._InitBuffIdList = {}

    ---@type table<number, XGoldenMinerGrabReportInfo> key = stoneType
    self._ReportGrabStoneDataDir = {}
    ---@type table<number, XGoldenMinerGrabDataInfo> key = stoneId
    self._SettleGrabStoneDataDir = {}
    self._SlotScoreHandleCountMap = {
        [XEnumConst.GOLDEN_MINER.SLOT_SCORE_TYPE.Diff] = 0,
        [XEnumConst.GOLDEN_MINER.SLOT_SCORE_TYPE.Double] = 0,
        [XEnumConst.GOLDEN_MINER.SLOT_SCORE_TYPE.Triple] = 0,
    }
end

function XGoldenMinerGameData:OnRelease()
    self._CurPassStageList = nil
    self._HookTypeList = nil
    self._MapStoneDataList = nil
    self._HideTaskInfoList = nil
    self._InitBuffIdList = nil
    self._ReportGrabStoneDataDir = nil
    self._SettleGrabStoneDataDir = nil
    self._SlotScoreHandleCountMap = nil
end

--region Setter
function XGoldenMinerGameData:SetMapStoneDataList(dataList)
    self._MapStoneDataList = dataList
end

function XGoldenMinerGameData:SetMapScore(mapScore)
    self._ChangeScore = mapScore - self._MapScore
    self._MapScore = mapScore
end

function XGoldenMinerGameData:SetAllScore(allScore)
    self._AllScore = allScore
end

function XGoldenMinerGameData:SetTime(time)
    if time < 0 then
        self._Time = 0
    else
        self._Time = time
    end
end

function XGoldenMinerGameData:SetTimeScore(value)
    self._TimeScore = value
end

function XGoldenMinerGameData:SetUsedTime(time)
    self._UsedTime = time
end

function XGoldenMinerGameData:SetPartnerRadarScore(value)
    self._PartnerRadarScore = value
end

function XGoldenMinerGameData:SetHookTypeList(hookTypeList)
    self._HookTypeList = hookTypeList
end

function XGoldenMinerGameData:SetCurPassStageList(curPassStageList)
    self._CurPassStageList = curPassStageList
end

function XGoldenMinerGameData:SetCurCharacterId(curCharacterId)
    self._CurCharacterId = curCharacterId
end

function XGoldenMinerGameData:SetHideTaskInfoList(hideTaskInfoList)
    self._HideTaskInfoList = hideTaskInfoList
end

function XGoldenMinerGameData:SetInitBuffIdList(initBuffIdList)
    self._InitBuffIdList = initBuffIdList
end

function XGoldenMinerGameData:AddReportGrabStoneData(stoneType, score, exScore)
    if not self._ReportGrabStoneDataDir[stoneType] then
        self._ReportGrabStoneDataDir[stoneType] = {}
        self._ReportGrabStoneDataDir[stoneType].Score = 0
        self._ReportGrabStoneDataDir[stoneType].Count = 0
        self._ReportGrabStoneDataDir[stoneType].ExScore = 0
    end
    self._ReportGrabStoneDataDir[stoneType].Count = self._ReportGrabStoneDataDir[stoneType].Count + 1
    self._ReportGrabStoneDataDir[stoneType].Score = self._ReportGrabStoneDataDir[stoneType].Score + score
    self._ReportGrabStoneDataDir[stoneType].ExScore = self._ReportGrabStoneDataDir[stoneType].ExScore + exScore
end

function XGoldenMinerGameData:AddSettleGrabStoneData(stoneId, data)
    self._SettleGrabStoneDataDir[stoneId] = data
end

function XGoldenMinerGameData:AddSlotScoreHandleCount(slotScoreType)
    self._SlotScoreHandleCountMap[slotScoreType] = self._SlotScoreHandleCountMap[slotScoreType] + 1
end
--endregion

--region Getter
function XGoldenMinerGameData:GetMapId()
    return self._MapId
end

function XGoldenMinerGameData:GetMapScore()
    return self._MapScore
end

---本关前总分数
function XGoldenMinerGameData:GetAllScore()
    return self._AllScore
end

function XGoldenMinerGameData:GetChangeScore()
    return self._ChangeScore
end

function XGoldenMinerGameData:GetOldScore()
    return self:GetCurScore() - self._ChangeScore
end

function XGoldenMinerGameData:GetTime()
    return self._Time
end

function XGoldenMinerGameData:GetTimeScore()
    return self._TimeScore
end

function XGoldenMinerGameData:GetUsedTime()
    return self._UsedTime
end

function XGoldenMinerGameData:GetPartnerRadarScore()
    return self._PartnerRadarScore
end

function XGoldenMinerGameData:GetHookTypeList()
    return self._HookTypeList
end

function XGoldenMinerGameData:GetCurPassStageList()
    return self._CurPassStageList
end

function XGoldenMinerGameData:GetCurCharacterId()
    return self._CurCharacterId
end

function XGoldenMinerGameData:GetInitBuffIdList()
    return self._InitBuffIdList
end

---当前地图所得分数
function XGoldenMinerGameData:GetCurScore()
    return self._MapScore + self._AllScore
end

---@return XGoldenMinerMapStoneData[]
function XGoldenMinerGameData:GetMapStoneDataList()
    return self._MapStoneDataList
end

---@return XGoldenMinerMapStoneData
function XGoldenMinerGameData:GetMapStoneDataByIndex(index)
    return self._MapStoneDataList[index]
end

function XGoldenMinerGameData:GetFinishStageCount()
    local finishStageCount = 0
    for _ in pairs(self._CurPassStageList) do
        finishStageCount = finishStageCount + 1
    end
    return finishStageCount
end

function XGoldenMinerGameData:GetHideTaskInfoList()
    return self._HideTaskInfoList
end

function XGoldenMinerGameData:GetReportGrabStoneDataDir()
    return self._ReportGrabStoneDataDir
end

function XGoldenMinerGameData:GetSettleGrabStoneData(stoneId)
    return self._SettleGrabStoneDataDir[stoneId]
end

function XGoldenMinerGameData:GetSettleGrabStoneDataDir()
    return self._SettleGrabStoneDataDir
end

function XGoldenMinerGameData:GetSlotScoreHandleCountMap()
    return self._SlotScoreHandleCountMap
end
--endregion

--region Check
function XGoldenMinerGameData:IsTimeOut()
    return self._Time <= 0
end
--endregion

return XGoldenMinerGameData