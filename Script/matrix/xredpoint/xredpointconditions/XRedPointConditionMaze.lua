local XRedPointConditionMaze = {}

function XRedPointConditionMaze.Check()
    if not XDataCenter.MazeManager.IsOpen() then
        return false
    end
    if XDataCenter.MazeManager.IsTaskCanGetReward() then
        return true
    end
    if XDataCenter.MazeManager.IsFirstTime() then
        return true
    end
    return false
end

return XRedPointConditionMaze