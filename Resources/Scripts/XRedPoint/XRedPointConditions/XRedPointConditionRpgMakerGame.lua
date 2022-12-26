
local XRedPointConditionRpgMakerGame = {}

function XRedPointConditionRpgMakerGame.Check()
    if XDataCenter.RpgMakerGameManager.CheckRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionRpgMakerGame