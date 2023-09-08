local XRedPointConditionActivityFestival = require("XRedPoint/XRedPointConditions/XRedPointConditionActivityFestival")

local XRedPointConditionBlackRockStage = {}

function XRedPointConditionBlackRockStage:Check()
    return XRedPointConditionActivityFestival.Check(XEnumConst.BLACK_ROCK.STAGE.FESTIVAL_ACTIVITY_ID)
end

return XRedPointConditionBlackRockStage
