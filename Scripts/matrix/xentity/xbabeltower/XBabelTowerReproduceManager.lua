local XBabelTowerStageData = require("XEntity/XBabelTower/XBabelTowerStageData")
local XBabelTowerReproduceManager = XClass(nil, "XBabelTowerReproduceManager")

function XBabelTowerReproduceManager:Ctor()
    self.FubenBabelTowerManager = XDataCenter.FubenBabelTowerManager
    self.Config = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(
            self.FubenBabelTowerManager.GetExtraActivityId())
    -- 最大分数
    self.MaxScore = 0
    self.RankLevel = 0
end

function XBabelTowerReproduceManager:InitWithServerData(data)
    self.MaxScore = data.MaxScore
    self.RankLevel = data.RankLevel
end

function XBabelTowerReproduceManager:UpdateMaxScore(value)
    self.MaxScore = value
end

function XBabelTowerReproduceManager:GetIsOpen(showTip)
    -- 未满足开放时间
    if not self:GetIsInTime() then
        if showTip then
            XUiManager.TipError(CS.XTextManager.GetText("FunctionNotDuringOpening"))
        end
        return false
    end
    return true
end

-- 获取活动是否在开启时间内
function XBabelTowerReproduceManager:GetIsInTime()
    return XFunctionManager.CheckInTimeByTimeId(self.Config.ActivityTimeId)
end

-- 获取活动距离开启时间描述
function XBabelTowerReproduceManager:GetStartTimeDes()
    return XUiHelper.GetTime(self:GetStartTime() - XTime.GetServerNowTimestamp()
        , XUiHelper.TimeFormatType.ACTIVITY)
end

function XBabelTowerReproduceManager:GetStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self.Config.ActivityTimeId)
end

function XBabelTowerReproduceManager:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self.Config.ActivityTimeId)
end

function XBabelTowerReproduceManager:GetId()
    return self.Config.Id
end

-- 获取是否展示排行榜
function XBabelTowerReproduceManager:GetIsShowRank()
    return self.Config.RankType ~= XFubenBabelTowerConfigs.RankType.NoRank
end

function XBabelTowerReproduceManager:GetMaxScore()
    return self.MaxScore
end

function XBabelTowerReproduceManager:GetCurrentScore()
    local currentScore = 0
    for _, stageData in ipairs(self:GetAllStageDatas()) do
        currentScore = currentScore + stageData:GetTotalScore()
    end
    return currentScore
end

function XBabelTowerReproduceManager:GetStageData(id)
    return self.FubenBabelTowerManager.GetStageDataById(id)
end

function XBabelTowerReproduceManager:GetAllStageDatas()
    local result = {}
    for _, stageId in ipairs(self.Config.StageId) do
        table.insert(result, self:GetStageData(stageId))
    end
    return result
end

function XBabelTowerReproduceManager:GetStageIds()
    return self.Config.StageId
end


function XBabelTowerReproduceManager.HandleActivityEndTime()
    XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerNoneOpen"))
    XLuaUiManager.RunMain()
end

function XBabelTowerReproduceManager:GetRewardId()
    return XFubenBabelTowerConfigs.GetActivityRewardId(self.Config.Id)
end

return XBabelTowerReproduceManager