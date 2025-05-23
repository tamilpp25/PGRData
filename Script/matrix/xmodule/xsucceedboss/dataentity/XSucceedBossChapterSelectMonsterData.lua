---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by heyupeng.
--- DateTime: 2024/6/28 15:29
---

---@class XSucceedBossChapterSelectMonsterData
local XSucceedBossChapterSelectMonsterData = XClass(nil, "XSucceedBossChapterSelectMonsterData")

function XSucceedBossChapterSelectMonsterData:Ctor()
    self.StageIndex = 0
    self.MonsterLevel = 0
end

function XSucceedBossChapterSelectMonsterData:UpdateData(data)
    self.StageIndex = data.StageIndex
    self.MonsterLevel = data.MonsterLevel
end

function XSucceedBossChapterSelectMonsterData:GetStageIndex()
    return self.StageIndex
end

function XSucceedBossChapterSelectMonsterData:GetMonsterLevel()
    return self.MonsterLevel
end

return XSucceedBossChapterSelectMonsterData