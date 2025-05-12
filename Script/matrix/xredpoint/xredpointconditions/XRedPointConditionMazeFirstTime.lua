local XRedPointConditionMazeFirstTime = {}

function XRedPointConditionMazeFirstTime.Check()
    if not XDataCenter.MazeManager.IsOpen() then
        return false
    end
    if XDataCenter.MazeManager.IsFirstTime() then
        return true
    end
    return false
end

return XRedPointConditionMazeFirstTime