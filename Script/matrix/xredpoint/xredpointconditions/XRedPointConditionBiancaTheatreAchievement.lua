--有可领取的任务奖励
local XRedPointConditionBiancaTheatreAchievement = {}

function XRedPointConditionBiancaTheatreAchievement.Check()
    return XDataCenter.BiancaTheatreManager.CheckAchievementTaskCanAchieved()
end

return XRedPointConditionBiancaTheatreAchievement