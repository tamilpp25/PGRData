
local XRedPointConditionBlackRockStage = {}

function XRedPointConditionBlackRockStage.Check()
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_ACTIVITY_FESTIVAL, XEnumConst.BLACK_ROCK.STAGE.FESTIVAL_ACTIVITY_ID)
end

return XRedPointConditionBlackRockStage
