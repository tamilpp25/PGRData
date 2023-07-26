
local XRedPointConditionSubpackageDownloadEntrance = {}

function XRedPointConditionSubpackageDownloadEntrance.Check()
    return XDataCenter.DlcManager.CheckRedPoint()
end

return XRedPointConditionSubpackageDownloadEntrance