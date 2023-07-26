XMazeConfig = XMazeConfig or {}

---@type XConfig
local _ConfigActivity

---@type XConfig
local _ConfigStage

---@type XConfig
local _ConfigGrade

---@type XConfig
local _ConfigAction

local _ActivityConfigId = 1

function XMazeConfig.Init()
    _ConfigActivity = XConfig.New("Share/Fuben/Maze/MazeActivity.tab", XTable.XTableMazeActivity, "Id")
    _ConfigStage = XConfig.New("Share/Fuben/Maze/MazeStage.tab", XTable.XTableMazeStage, "StageId")
    _ConfigGrade = XConfig.New("Client/Fuben/Maze/MazeGrade.tab", XTable.XTableMazeGrade, "Id")
    _ConfigAction = XConfig.New("Client/Fuben/Maze/MazeRandomAction.tab", XTable.XTableMazeRandomAction, "Id")
    for i, config in pairs(_ConfigActivity:GetConfigs()) do
        _ActivityConfigId = config.Id
    end
end

function XMazeConfig.SetActivityId(value)
    if value > 0 then
        _ActivityConfigId = value
    end
end

function XMazeConfig.GetTaskId()
    return _ConfigActivity:GetProperty(_ActivityConfigId, "TimeLimitTaskId")
end

function XMazeConfig.GetName()
    return _ConfigActivity:GetProperty(_ActivityConfigId, "Name")
end

function XMazeConfig.GetTimeId()
    return _ConfigActivity:GetProperty(_ActivityConfigId, "TimeId")
end

function XMazeConfig.GetStoryId()
    return _ConfigActivity:GetProperty(_ActivityConfigId, "StoryId")
end

function XMazeConfig.GetStoryIcon()
    return _ConfigActivity:GetProperty(_ActivityConfigId, "StoryIcon")
end

function XMazeConfig.GetPlayerModelName()
    return _ConfigActivity:GetProperty(_ActivityConfigId, "PlayerModel")
end

function XMazeConfig.GetTicketItemId()
    return _ConfigActivity:GetProperty(_ActivityConfigId, "TicketItemId")
end

function XMazeConfig.GetStageId(robotId)
    local allConfig = _ConfigStage:GetConfigs()
    for _, config in pairs(allConfig) do
        if config.RobotId == robotId then
            return config.StageId
        end
    end
    return false
end

function XMazeConfig.GetPassStageAmount2QuickPass()
    return _ConfigActivity:GetProperty(_ActivityConfigId, "FastPassParam")
end

local function SortRobot(a, b)
    return a.Priority < b.Priority
end

local _AllRobot = false
function XMazeConfig.GetAllPartnerRobot()
    if _AllRobot then
        return _AllRobot
    end
    local allConfig = _ConfigStage:GetConfigs()
    local configArray = {}
    for _, config in pairs(allConfig) do
        configArray[#configArray + 1] = config
    end
    table.sort(configArray, SortRobot)
    local result = {}
    for i = 1, #configArray do
        result[i] = configArray[i].RobotId
    end
    _AllRobot = result
    return result
end

function XMazeConfig.GetHelpKey()
    return "Maze"
end

local _AllStage = false
function XMazeConfig.GetAllStageConfig()
    if _AllStage then
        return _AllStage
    end
    local allConfig = _ConfigStage:GetConfigs()
    local configArray = {}
    for _, config in pairs(allConfig) do
        configArray[#configArray + 1] = config
    end
    table.sort(configArray, SortRobot)
    _AllStage = configArray
    return configArray
end

function XMazeConfig.GetGradeIconByScore(score)
    local maxIndex = 1
    local maxScore = 0
    for id, config in pairs(_ConfigGrade:GetConfigs()) do
        local configScore = config.Score or 0
        if score >= configScore and configScore >= maxScore then
            maxScore = configScore
            maxIndex = id
        end
    end
    local config = _ConfigGrade:GetConfig(maxIndex)
    if not config then
        XLog.Error("[XMazeConfig] 评价配置有问题")
        return ""
    end
    return config.Icon
end

function XMazeConfig.GetRandomTimeline(modelName)
    local result = {}
    for i, config in pairs(_ConfigAction:GetConfigs()) do
        if config.ModelName == modelName then
            result[#result + 1] = config.Timeline
        end
    end
    return result
end

function XMazeConfig.GetSettleBg(robotId)
    local allConfig = _ConfigStage:GetConfigs()
    for _, config in pairs(allConfig) do
        if config.RobotId == robotId then
            return config.SettleBg
        end
    end
    return false
end
