local XRedPointConditionRiftActivityTag = {}

function XRedPointConditionRiftActivityTag.Check()
    return XDataCenter.RiftManager.CheckIsHasFightLayerRedPoint()
end

return XRedPointConditionRiftActivityTag