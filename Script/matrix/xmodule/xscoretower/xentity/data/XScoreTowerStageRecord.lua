---@class XScoreTowerStageRecord
local XScoreTowerStageRecord = XClass(nil, "XScoreTowerStageRecord")

function XScoreTowerStageRecord:Ctor()
    -- 配置表ID
    self.StageCfgId = 0
    -- 分数记录
    ---@type number[]
    self.ScoreRecord = {}
    -- 编队记录
    ---@type XScoreTowerTeam
    self.StageTeamData = nil
end

function XScoreTowerStageRecord:NotifyScoreTowerStageRecordData(data)
    self.StageCfgId = data.StageCfgId or 0
    self.ScoreRecord = data.ScoreRecord or {}
    self:UpdateTeamData(data.StageTeamData)
end

--region 数据更新

function XScoreTowerStageRecord:UpdateTeamData(data)
    if not data then
        self.StageTeamData = nil
        return
    end
    if not self.StageTeamData then
        self.StageTeamData = require("XModule/XScoreTower/XEntity/Data/XScoreTowerTeam").New()
    end
    self.StageTeamData:NotifyScoreTowerTeamData(data)
end

--endregion

--region 数据获取

function XScoreTowerStageRecord:GetStageCfgId()
    return self.StageCfgId
end

function XScoreTowerStageRecord:GetScoreRecord()
    return self.ScoreRecord
end

function XScoreTowerStageRecord:GetTeamData()
    return self.StageTeamData
end

--endregion

return XScoreTowerStageRecord
