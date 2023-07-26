local XRedPointConditionMonsterCombatNewChapter = {}

function XRedPointConditionMonsterCombatNewChapter.Check()
    -- 开启
    if not XDataCenter.MonsterCombatManager.IsOpen(true) then
        return false
    end
    -- 新解锁章节
    if XDataCenter.MonsterCombatManager.CheckNewUnlockChapterRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionMonsterCombatNewChapter