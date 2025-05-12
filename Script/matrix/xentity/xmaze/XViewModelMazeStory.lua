---@class XViewModelMazeStory
local XViewModelMazeStory = XClass(nil, "XViewModelMazeStory")

function XViewModelMazeStory:Ctor()
end

function XViewModelMazeStory:GetProgress(dataSource)
    dataSource = dataSource or self:GetDataSource()
    local progress, maxProgress = 0, 0
    for i = 1, #dataSource do
        local data = dataSource[i]
        if data.IsPass then
            progress = progress + 1
        end
        maxProgress = maxProgress + 1
    end
    return progress, maxProgress
end

local function SortStage(a, b)
    if a.IsPass ~= b.IsPass then
        if a.IsPass then
            return true
        end
        return false
    end
    return a.Priority < b.Priority
end

function XViewModelMazeStory:GetDataSource()
    local result = {}

    local allStageConfig = XMazeConfig.GetAllStageConfig()
    for i = 1, #allStageConfig do
        local stageConfig = allStageConfig[i]
        local stageId = stageConfig.StageId
        local robotId = stageConfig.RobotId
        local characterId = XRobotManager.GetCharacterId(robotId)
        local name = XMVCA.XCharacter:GetCharacterName(characterId)
        local isPass = XDataCenter.MazeManager.IsStagePassed(stageId)
        local dataBegin = {
            Name = XUiHelper.ReadTextWithNewLine("MazeStoryStart", name),
            NamePartner = name,
            IsPass = isPass,
            Priority = stageConfig.Priority * 2 - 1,
            StoryId = XFubenConfigs.GetBeginStoryId(stageId),
            Icon = XCharacterCuteConfig.GetCuteModelSmallHeadIconByRobotId(robotId)
        }
        result[#result + 1] = dataBegin

        local dataEnd = {
            Name = XUiHelper.ReadTextWithNewLine("MazeStoryEnd", name),
            NamePartner = name,
            IsPass = isPass,
            Priority = stageConfig.Priority * 2,
            StoryId = XFubenConfigs.GetEndStoryId(stageId),
            Icon = XCharacterCuteConfig.GetCuteModelSmallHeadIconByRobotId(robotId)
        }
        result[#result + 1] = dataEnd
    end
    table.sort(result, SortStage)

    ---@class XMazeStoryData@开场剧情
    local dataBegin = {
        Name = XUiHelper.ReadTextWithNewLine("MazeStoryBegin"),
        NamePartner = "",
        IsPass = true,
        Priority = 0,
        StoryId = XMazeConfig.GetStoryId(),
        Icon = XMazeConfig.GetStoryIcon()
    }
    table.insert(result, 1, dataBegin)

    return result
end

return XViewModelMazeStory