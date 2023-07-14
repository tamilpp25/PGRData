local XGoldenMinerGrabDataInfo = require("XEntity/XGoldenMiner/Settle/XGoldenMinerGrabDataInfo")

local type = type

--关卡结算数据
local XGoldenMinerSettlementInfo = XClass(nil, "XGoldenMinerSettlementInfo")

local Default = {
    _Scores = 0, --当前关卡得分
    _SettlementItems = {}, --结算后的道具产出消耗状态
    _LaunchingClawCount = 0, --发射钩爪次数
    _CostTime = 0, --消耗的时间
    _GrabDataInfos = {}, --抓取物获取数
}

function XGoldenMinerSettlementInfo:Ctor()
    self:Init()
end

function XGoldenMinerSettlementInfo:Init()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XGoldenMinerSettlementInfo:SetScores(scores)
    self._Scores = scores
end

function XGoldenMinerSettlementInfo:InsertSettlementItem(itemChangeInfo)
    table.insert(self._SettlementItems, itemChangeInfo)
end

function XGoldenMinerSettlementInfo:AddLaunchingClawCount()
    self._LaunchingClawCount = self._LaunchingClawCount + 1
end

function XGoldenMinerSettlementInfo:SetCostTime(costTime)
    self._CostTime = costTime
end

--goldenMinerObjectList：当前地图拉回物品列表
function XGoldenMinerSettlementInfo:UpdateGrabDataInfos(goldenMinerObjectList)
    local grabDataInfo
    local stoneId

    for i, goldenMinerObj in ipairs(goldenMinerObjectList) do
        stoneId = goldenMinerObj:GetId()
        grabDataInfo = self._GrabDataInfos[stoneId]
        if not grabDataInfo then
            grabDataInfo = XGoldenMinerGrabDataInfo.New(stoneId)
            self._GrabDataInfos[stoneId] = grabDataInfo
        end
        grabDataInfo:AddData(goldenMinerObj)
    end
end

function XGoldenMinerSettlementInfo:GetScores()
    return math.floor(self._Scores)
end

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

--获得转换后发给后端的数据
function XGoldenMinerSettlementInfo:GetReqServerData()
    local settlementInfoTemp = {}
    settlementInfoTemp.Scores = self:GetScores()
    settlementInfoTemp.LaunchingClawCount = self:GetLaunchingClawCount()
    settlementInfoTemp.CostTime = self:GetCostTime()

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

    return settlementInfoTemp
end

return XGoldenMinerSettlementInfo