---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by heyupeng.
--- DateTime: 2024/6/3 17:08
---

local XSucceedBossCharacterInfoData = require("XModule/XSucceedBoss/DataEntity/XSucceedBossCharacterInfoData")

---@class XSucceedBossBattleResultData
local XSucceedBossBattleResultData = XClass(nil, "XSucceedBossBattleResultData")

function XSucceedBossBattleResultData:Ctor()
    self.StageId = 0
    self.MonsterId = 0
    self.StageIndex = 0
    self.MonsterLevel = 0
    self.SucceedBossCharacterInfo = {}
end

function XSucceedBossBattleResultData:UpdateData(data)
    self.StageId = data.StageId
    self.MonsterId = data.MonsterId
    self.StageIndex = data.StageIndex
    self.MonsterLevel = data.MonsterLevel
    self.SucceedBossCharacterInfo = XSucceedBossCharacterInfoData.New()
    self.SucceedBossCharacterInfo:UpdateData(data.CharacterResultList)
end

function XSucceedBossBattleResultData:GetStageId()
    return self.StageId
end

function XSucceedBossBattleResultData:GetMonsterId()
    return self.MonsterId
end

function XSucceedBossBattleResultData:GetStageIndex()
    return self.StageIndex
end

function XSucceedBossBattleResultData:GetMonsterLevel()
    return self.MonsterLevel
end

function XSucceedBossBattleResultData:GetSucceedBossCharacterInfo()
    return self.SucceedBossCharacterInfo
end

return XSucceedBossBattleResultData