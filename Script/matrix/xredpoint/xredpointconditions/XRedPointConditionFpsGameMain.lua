local XRedPointConditionFpsGameMain = {}

function XRedPointConditionFpsGameMain.Check()
    return XMVCA.XFpsGame:CheckActivityRedPoint()
end

return XRedPointConditionFpsGameMain