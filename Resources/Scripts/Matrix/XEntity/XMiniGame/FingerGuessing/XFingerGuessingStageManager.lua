-- 猜拳小游戏关卡管理器
local XFingerGuessingStageManager = XClass(nil, "XFingerGuessingStageManager")

local SortStagesByStageId = function(stage1, stage2)
    return stage1:GetStageId() < stage2:GetStageId()
end

function XFingerGuessingStageManager:Ctor(gameController)
    self.GameController = gameController
    self:InitStages()
end
--================
--初始化关卡
--================
function XFingerGuessingStageManager:InitStages()
    self.Stages = {}
    local XStage = require("XEntity/XMiniGame/FingerGuessing/XFingerGuessingStage")
    local stageConfigs = XFingerGuessingConfig.GetAllStageConfig()
    for _, config in pairs(stageConfigs) do
        self.Stages[config.StageId] = XStage.New(config, self.GameController)
    end
end
--=======================
--刷新活动数据
--@param data: 
--    List<FingerGuessingStageInfo> FingerGuessingStageData //已开启的关卡信息
--=======================
--FingerGuessingStageInfo
--    int StageId // 关卡Id
--    int ChallengeTimes // 挑战次数
--    int StageStatus // 关卡状态
--    int HighScore // 最高分
--    List<FingerGuessingRobotTricks> RobotTricksList // 机器人行动列表
--    bool IsCheating // 是否开启天眼
--    List<int> SelectRobotTricks // 天眼预测的行动种类
--=======================
function XFingerGuessingStageManager:RefreshStageList(data)
    for _, stageInfo in pairs(data) do
        local stage = self:GetStageByStageId(stageInfo.StageId)
        if stage then
            stage:RefreshStageInfo(stageInfo)
        end
    end
end

function XFingerGuessingStageManager:RefreshCurrentStage(data)
    local stage = self:GetStageByStageId(data.StageId)
    if stage then
        stage:RefreshCurrent(data)
    end
end
--================
--获取所有关卡对象
--================
function XFingerGuessingStageManager:GetAllStages()
    local stageList = {}
    for _, stage in pairs(self.Stages) do
        table.insert(stageList, stage)
    end
    table.sort(stageList, SortStagesByStageId)
    return stageList
end
--================
--根据关卡Id获取关卡对象
--@param stageId:关卡Id
--================
function XFingerGuessingStageManager:GetStageByStageId(stageId)
    return self.Stages[stageId]
end

function XFingerGuessingStageManager:GetLastStageId()
    local stageList = self:GetAllStages()
    for _, stage in pairs(stageList) do
        
    end
end
return XFingerGuessingStageManager