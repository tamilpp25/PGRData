local XReformStageTime = require("XEntity/XReform/StageTime/XReformStageTime")
local XReformStageTimeGroup = XClass(nil, "XReformStageTimeGroup")

function XReformStageTimeGroup:Ctor(config)
    self.Config = config
    self.StageTimeDic = {}
    self.CurrentChallengeScore = 0
end

function XReformStageTimeGroup:GetStageTimes()
    local result = { }
    for _, id in ipairs(self.Config.SubId) do
        table.insert(result, self:GetStageTimeById(id))
    end
    return result
end

function XReformStageTimeGroup:GetStageTimeById(id)
    if id <= 0 then return nil end
    local result = self.StageTimeDic[id]
    if result == nil then
        result = XReformStageTime.New(id)
        self.StageTimeDic[id] = result
    end
    return result
end

function XReformStageTimeGroup:UpdateChallengeScore(id)
    if id <= 0 then
        self.CurrentChallengeScore = 0
        return 
    end
    self.CurrentChallengeScore = 
        XReformConfigs.GetCfgByIdKey(XReformConfigs.TableKey.ReformTimeEnvSource, id).AddScore
end

function XReformStageTimeGroup:GetChallengeScore()
    return self.CurrentChallengeScore
end

function XReformStageTimeGroup:GetMaxChallengeScore()
    if self.__MaxChallengeScore == nil then
        self.__MaxChallengeScore = 0
        for _, id in ipairs(self.Config.SubId) do
            self.__MaxChallengeScore = math.max(self.__MaxChallengeScore
                , XReformConfigs.GetCfgByIdKey(XReformConfigs.TableKey.ReformTimeEnvSource, id).AddScore)
        end
    end
    return self.__MaxChallengeScore
end

return XReformStageTimeGroup