
local XRedPointConditionRestaurantEntrance = {}

function XRedPointConditionRestaurantEntrance.Check()
    return XDataCenter.RestaurantManager.CheckEntranceRedPoint()
end

return XRedPointConditionRestaurantEntrance