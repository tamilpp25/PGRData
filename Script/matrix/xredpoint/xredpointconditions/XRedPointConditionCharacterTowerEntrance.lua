local XRedPointConditionCharacterTowerEntrance = {}

function XRedPointConditionCharacterTowerEntrance.Check(id)
    if not XTool.IsNumberValid(id) then
        return false
    end
    local chapterIds = XFubenCharacterTowerConfigs.GetChapterIdsById(id)
    for _, chapterId in pairs(chapterIds) do
        local hasRedPoint = XDataCenter.CharacterTowerManager.CheckRedPointByChapterId(chapterId)
        if hasRedPoint then
            return true
        end
    end
    return false
end

return XRedPointConditionCharacterTowerEntrance