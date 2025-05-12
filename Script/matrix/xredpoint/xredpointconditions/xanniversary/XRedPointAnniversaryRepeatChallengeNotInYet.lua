
local XRedPointAnniversaryRepeatChallengeNotInYet = {}


function XRedPointAnniversaryRepeatChallengeNotInYet.Check()
    local isOpen=XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.RepeatChallenge)
    return not XSaveTool.GetData(XMVCA.XAnniversary:GetHadInRepeatChallengeKey()) and isOpen
end

return XRedPointAnniversaryRepeatChallengeNotInYet