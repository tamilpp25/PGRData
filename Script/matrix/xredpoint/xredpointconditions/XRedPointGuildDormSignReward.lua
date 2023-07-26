
----------------------------------------------------------------
--主线跑团所有区域红点检测
local XRedPointGuildDormSignReward = {}

function XRedPointGuildDormSignReward.Check()
    if not XDataCenter.GuildManager.IsJoinGuild() then
        return false
    end
    return not XDataCenter.GuildManager.IsGetSignRewardToday()
end

return XRedPointGuildDormSignReward