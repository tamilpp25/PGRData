---@class XScoreTowerTower
local XScoreTowerTower = XClass(nil, "XScoreTowerTower")

function XScoreTowerTower:Ctor()
    -- 塔层Id
    self.TowerId = 0
    -- 当前层ID
    self.CurFloorId = 0
    -- 当前塔分数
    self.CurPoint = 0
    -- 当前塔星级
    self.CurStar = 0
    -- 层数据
    ---@type XScoreTowerFloor[]
    self.FloorDatas = {}
    -- 关卡数据
    ---@type XScoreTowerStage[]
    self.StageDatas = {}
end

function XScoreTowerTower:NotifyScoreTowerTowerData(data)
    self.TowerId = data.TowerId or 0
    self.CurFloorId = data.CurFloorId or 0
    self.CurPoint = data.CurPoint or 0
    self.CurStar = data.CurStar or 0
    self:UpdateFloorDatas(data.FloorDatas)
    self:UpdateStageDatas(data.StageDatas)
end

--region 数据更新

function XScoreTowerTower:UpdateFloorDatas(data)
    self.FloorDatas = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddFloorData(v)
    end
end

function XScoreTowerTower:AddFloorData(data)
    if not data then
        return
    end
    local floorData = self.FloorDatas[data.FloorId]
    if not floorData then
        floorData = require("XModule/XScoreTower/XEntity/Data/XScoreTowerFloor").New()
        self.FloorDatas[data.FloorId] = floorData
    end
    floorData:NotifyScoreTowerFloor(data)
end

function XScoreTowerTower:UpdateStageDatas(data)
    self.StageDatas = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddStageData(v)
    end
end

function XScoreTowerTower:AddStageData(data)
    if not data then
        return
    end
    local stageData = self.StageDatas[data.CfgId]
    if not stageData then
        stageData = require("XModule/XScoreTower/XEntity/Data/XScoreTowerStage").New()
        self.StageDatas[data.CfgId] = stageData
    end
    stageData:NotifyScoreTowerStage(data)
end

--endregion

--region 数据获取

--- 获取塔层Id
---@return number
function XScoreTowerTower:GetTowerId()
    return self.TowerId
end

--- 获取当前层ID
---@return number
function XScoreTowerTower:GetCurFloorId()
    return self.CurFloorId
end

--- 获取当前所有的插件点数
---@return number
function XScoreTowerTower:GetTotalPlugInPoint()
    local totalPlugInPoint = 0
    for _, stageData in pairs(self.StageDatas) do
        if stageData:GetIsPass() then
            totalPlugInPoint = totalPlugInPoint + stageData:GetPlugInPoint()
        end
    end
    return totalPlugInPoint
end

--- 获取当前塔分数
---@return number
function XScoreTowerTower:GetCurPoint()
    return self.CurPoint
end

--- 获取当前塔星数
---@return number
function XScoreTowerTower:GetCurStar()
    return self.CurStar
end

--- 获取所有层数据
---@return XScoreTowerFloor[]
function XScoreTowerTower:GetFloorDatas()
    return self.FloorDatas
end

--- 获取层数据
---@param floorId number
---@return XScoreTowerFloor
function XScoreTowerTower:GetFloorData(floorId)
    return self.FloorDatas[floorId]
end

--- 获取所有关卡数据
---@return XScoreTowerStage[]
function XScoreTowerTower:GetStageDatas()
    return self.StageDatas
end

--- 获取关卡数据
---@param cfgId number ScoreTowerStage表ID
---@return XScoreTowerStage
function XScoreTowerTower:GetStageData(cfgId)
    return self.StageDatas[cfgId]
end

--endregion

return XScoreTowerTower
