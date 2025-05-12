
local XRedPointConditionRestaurantEntrance = {}

function XRedPointConditionRestaurantEntrance.Check()
    return XMVCA.XRestaurant:CheckEntranceRedPoint()
end

return XRedPointConditionRestaurantEntrance