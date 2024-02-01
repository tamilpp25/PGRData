local XGoldenMinerHideTaskInfo = require("XModule/XGoldenMiner/Data/Settle/XGoldenMinerHideTaskInfo")

--关卡结算数据
---@class XGoldenMinerSettlementInfo
local XGoldenMinerSettlementInfo = XClass(nil, "XGoldenMinerSettlementInfo")

function XGoldenMinerSettlementInfo:Ctor()
    self:Init()
end

function XGoldenMinerSettlementInfo:Init()
    self._Scores = 0                --当前关卡得分
    self._CostTime = 0              --消耗的时间
    self._MoveCount = 0             --玩家移动次数，2.0运营提出的记录需求
    self._LaunchingClawCount = 0    --发射钩爪次数
    ---@type XGoldenMinerItemChangeInfo[]
    self._SettlementItems = {}      --结算后的道具产出消耗状态
    ---@type XGoldenMinerGrabDataInfo[]
    self._GrabDataInfos = {}        --抓取物获取数
    ---@type XGoldenMinerHideTaskInfo[]
    self._HideTaskInfoList = {}     --隐藏任务，3.0运营提出的记录需求
end

--region Setter
function XGoldenMinerSettlementInfo:SetScores(scores)
    self._Scores = scores
end

---@param itemChangeInfo XGoldenMinerItemChangeInfo
function XGoldenMinerSettlementInfo:InsertSettlementItem(itemChangeInfo)
    table.insert(self._SettlementItems, itemChangeInfo)
end

function XGoldenMinerSettlementInfo:AddLaunchingClawCount()
    self._LaunchingClawCount = self._LaunchingClawCount + 1
end

function XGoldenMinerSettlementInfo:SetCostTime(costTime)
    self._CostTime = costTime
end

function XGoldenMinerSettlementInfo:SetMoveCount(moveCount)
    self._MoveCount = moveCount
end

---@param data XGoldenMinerGrabDataInfo[]
function XGoldenMinerSettlementInfo:UpdateGrabDataInfos(data)
    self._GrabDataInfos = data
end

---@param hideTaskInfoList XGoldenMinerHideTaskInfo[]
function XGoldenMinerSettlementInfo:UpdateHideTaskInfoList(hideTaskInfoList)
    ---@type XGoldenMinerHideTaskInfo[]
    self._HideTaskInfoList = {}
    if XTool.IsTableEmpty(hideTaskInfoList) then
        return
    end
    for _, hideTaskInfo in ipairs(hideTaskInfoList) do
        ---@type XGoldenMinerHideTaskInfo[]
        local info = XGoldenMinerHideTaskInfo.New(hideTaskInfo:GetId())
        info:SetCurProgress(hideTaskInfo:GetCurProgress())
        self._HideTaskInfoList[#self._HideTaskInfoList + 1] = info
    end
end
--endregion


--region Getter
function XGoldenMinerSettlementInfo:GetScores()
    return math.floor(self._Scores)
end

---@return XGoldenMinerItemChangeInfo[]
function XGoldenMinerSettlementInfo:GetSettlementItems()
    return self._SettlementItems
end

function XGoldenMinerSettlementInfo:GetLaunchingClawCount()
    return self._LaunchingClawCount
end

function XGoldenMinerSettlementInfo:GetCostTime()
    return self._CostTime
end

function XGoldenMinerSettlementInfo:GetGrabDataInfos()
    return self._GrabDataInfos
end

function XGoldenMinerSettlementInfo:GetHideTaskInfoList()
    return self._HideTaskInfoList
end

function XGoldenMinerSettlementInfo:GetMoveCount()
    return self._MoveCount
end

--获得转换后发给后端的数据
function XGoldenMinerSettlementInfo:GetReqServerData()
    local settlementInfoTemp = {}
    settlementInfoTemp.Scores = self:GetScores()
    settlementInfoTemp.LaunchingClawCount = self:GetLaunchingClawCount()
    settlementInfoTemp.CostTime = self:GetCostTime()
    settlementInfoTemp.MoveCount = self:GetMoveCount()

    settlementInfoTemp.SettlementItems = {}
    for i, itemChangeInfo in ipairs(self:GetSettlementItems()) do
        settlementInfoTemp.SettlementItems[i] = {}
        settlementInfoTemp.SettlementItems[i].ItemId = itemChangeInfo:GetItemId()
        settlementInfoTemp.SettlementItems[i].Status = itemChangeInfo:GetStatus()
        settlementInfoTemp.SettlementItems[i].GridIndex = itemChangeInfo:GetGridIndex()
    end

    settlementInfoTemp.GrabDataInfos = {}
    for _, grabDataInfo in pairs(self:GetGrabDataInfos()) do
        local grabDataInfoTemp = {}
        grabDataInfoTemp.ItemId = grabDataInfo:GetItemId()
        grabDataInfoTemp.Scores = grabDataInfo:GetScores()
        grabDataInfoTemp.Count = grabDataInfo:GetCount()
        grabDataInfoTemp.AdditionalItem = grabDataInfo:GetAdditionalItem()
        table.insert(settlementInfoTemp.GrabDataInfos, grabDataInfoTemp)
    end

    settlementInfoTemp.UpdateTaskInfo = {}
    for _, hideTaskInfo in pairs(self:GetHideTaskInfoList()) do
        local taskInfo = {}
        taskInfo.Id = hideTaskInfo:GetId()
        taskInfo.Progress = hideTaskInfo:GetCurProgress()
        table.insert(settlementInfoTemp.UpdateTaskInfo, taskInfo)
    end

    return settlementInfoTemp
end
--endregion

return XGoldenMinerSettlementInfo