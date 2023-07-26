
local XRedPointConditionSkinVoteEntrance = {}

function XRedPointConditionSkinVoteEntrance.Check()
    return XDataCenter.SkinVoteManager.CheckVoteRedPoint() 
            or XDataCenter.SkinVoteManager.CheckViewPublicRedPoint()
end

return XRedPointConditionSkinVoteEntrance