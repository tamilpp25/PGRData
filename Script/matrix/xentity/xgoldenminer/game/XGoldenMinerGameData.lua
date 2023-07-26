local XGoldenMinerMapStoneData = require("XEntity/XGoldenMiner/Game/XGoldenMinerMapStoneData")
local XGoldenMinerHideTaskInfo = require("XEntity/XGoldenMiner/Settle/XGoldenMinerHideTaskInfo")
--游戏内数据
---@class XGoldenMinerGameData
local XGoldenMinerGameData = XClass(nil, "XGoldenMinerGameData")

local Default = {
    _MapId = 0,
    _MapScore = 0,
    _AllScore = 0,
    _ChangeScore = 0,
    _CurCharacterId = 0,
    _CurPassStageList = {},
    _Time = 0,
    _UsedTime = 0,
    _HookTypeList = {},
    _MapStoneDataList = {},
    _HideTaskInfoList = {},
}

function XGoldenMinerGameData:Ctor(mapId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self._MapId = mapId
    ---@type XGoldenMinerMapStoneData[]
    self._MapStoneDataList = {}
    ---@type XGoldenMinerHideTaskInfo[]
    self._HideTaskInfoList = {}

    --XGoldenMinerConfigs.DebugLog("本关地图:mapId="..self._MapId)
    for i, stoneId in ipairs(XGoldenMinerConfigs.GetMapStoneId(self._MapId)) do
        ---@type XGoldenMinerMapStoneData
        local stoneData = XGoldenMinerMapStoneData.New(stoneId)
        stoneData:SetMapIndex(i)
        stoneData:SetXPosPercent(XGoldenMinerConfigs.GetMapXPosPercent(self._MapId, i))
        stoneData:SetYPosPercent(XGoldenMinerConfigs.GetMapYPosPercent(self._MapId, i))
        stoneData:SetRotationZ(XGoldenMinerConfigs.GetMapRotationZ(self._MapId, i))
        stoneData:SetScale(XGoldenMinerConfigs.GetMapScale(self._MapId, i))
        self._MapStoneDataList[#self._MapStoneDataList + 1] = stoneData
    end
    -- 隐藏任务
    if XTool.IsTableEmpty(XGoldenMinerConfigs.GetMapHideTask(self._MapId)) then
        return
    end
    for _, hideTaskId in ipairs(XGoldenMinerConfigs.GetMapHideTask(self._MapId)) do
        --XGoldenMinerConfigs.DebugLog("本关隐藏任务:hideTaskId="..hideTaskId)
        self._HideTaskInfoList[#self._HideTaskInfoList + 1] = XGoldenMinerHideTaskInfo.New(hideTaskId)
    end
end

--region Setter
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

function XGoldenMinerGameData:SetUsedTime(time)
    self._UsedTime = time
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

function XGoldenMinerGameData:GetUsedTime()
    return self._UsedTime
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
--endregion

--region Check
function XGoldenMinerGameData:IsTimeOut()
    return self._Time <= 0
end
--endregion

return XGoldenMinerGameData