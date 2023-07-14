local XRedPointConditionActivityFestivalMain = {}

function XRedPointConditionActivityFestivalMain.Check()
    local allFestivalsId = XDataCenter.FubenFestivalActivityManager.GetAllAvailableFestivalsId()
    for _, sectionId in pairs(allFestivalsId) do
        if XDataCenter.FubenFestivalActivityManager.CheckFesticalAcitvityTimeIsOpen(sectionId) and XRedPointConditionActivityFestival.Check(sectionId) then
            return true
        end
    end
    return false
end

return XRedPointConditionActivityFestivalMain