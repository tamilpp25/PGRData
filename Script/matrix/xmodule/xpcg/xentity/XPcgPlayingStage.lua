---@class XPcgPlayingStage
local XPcgPlayingStage = XClass(nil, "XPcgPlayingStage")

function XPcgPlayingStage:Ctor()
    -- 关卡是否结束
    ---@type boolean
    self.IsStageFinished = false
    -- 关卡Id
    ---@type number
    self.Id = 0
    -- 当前回合数
    ---@type number
    self.Round = 0
    -- 当前怪物轮次
    ---@type number
    self.MonsterLoop = 0
    -- 当前积分
    ---@type number
    self.Score = 0
    -- 指挥官
    ---@type XPcgCommander
    self.Commander = nil
    -- 队伍角色, [1]=出战位置, [2]=左, [3]=右, 2/3位置可为0
    ---@type XPcgCharacter[]
    self.Characters = {}
    -- 怪物角色
    ---@type XPcgMonster[]
    self.Monsters = {}
    ---@type table<number, XPcgMonster>
    self.MonsterDic = {}
    -- 手牌堆
    ---@type number[]
    self.HandPool = {}
    -- 抽牌堆数量
    ---@type number
    self.DrawPoolNum = 0
    -- 弃牌堆数量
    ---@type number
    self.DropPoolNum = 0
end

-- 刷新卡关数据
function XPcgPlayingStage:RefreshData(data)
    self.IsStageFinished = data.IsStageFinished or false
    self.Id = data.Id or 0
    self.Round = data.Round or 0
    self.MonsterLoop = data.MonsterLoop or 0
    self.Score = data.Score or 0
    self:RefreshCommanderData(data.Commander)
    self:RefreshCharactersData(data.Characters)
    self:RefreshMonstersData(data.Monsters)
    self:RefreshHandPool(data.HandPool)
    self.DrawPoolNum = data.DrawPoolNum or 0
    self.DropPoolNum = data.DropPoolNum or 0
end

-- 刷新指挥官数据
function XPcgPlayingStage:RefreshCommanderData(commanderData)
    if not self.Commander then
        local XPcgCommander = require("XModule/XPcg/XEntity/XPcgCommander")
        self.Commander = XPcgCommander.New()
    end
    self.Commander:RefreshData(commanderData)
end

-- 刷新角色列表数据
function XPcgPlayingStage:RefreshCharactersData(characterDatas)
    self.Characters = {}
    if not characterDatas or #characterDatas == 0 then return end

    local XPcgCharacter = require("XModule/XPcg/XEntity/XPcgCharacter")
    for _, charData in ipairs(characterDatas) do
        ---@type XPcgCharacter
        local character = XPcgCharacter.New()
        character:RefreshData(charData)
        table.insert(self.Characters, character)
    end
end

-- 刷新怪物列表数据
function XPcgPlayingStage:RefreshMonstersData(monsterDatas)
    self.Monsters = {}
    self.MonsterDic = {}
    if not monsterDatas or #monsterDatas == 0 then return end

    local XPcgMonster = require("XModule/XPcg/XEntity/XPcgMonster")
    for _, monsterData in ipairs(monsterDatas) do
        ---@type XPcgMonster
        local monster = XPcgMonster.New()
        monster:RefreshData(monsterData)
        table.insert(self.Monsters, monster)
        self.MonsterDic[monster:GetIdx()] = monster
    end
end

-- 刷新手牌
function XPcgPlayingStage:RefreshHandPool(handPool)
    self.HandPool = handPool or {}
end

-- 设置关卡结束
function XPcgPlayingStage:SetStageFinished()
    self.IsStageFinished = true
end

-- 获取关卡是否结束
function XPcgPlayingStage:GetIsStageFinished()
    return self.IsStageFinished
end

-- 获取关卡Id
function XPcgPlayingStage:GetId()
    return self.Id
end

-- 获取当前回合数
function XPcgPlayingStage:GetRound()
    return self.Round
end

-- 获取当前怪物轮次
function XPcgPlayingStage:GetMonsterLoop()
    return self.MonsterLoop
end

-- 获取当前积分
function XPcgPlayingStage:GetScore()
    return self.Score
end

-- 获取角色列表
function XPcgPlayingStage:GetCharacters()
    return self.Characters
end

-- 获取角色
function XPcgPlayingStage:GetCharacter(idx)
    return self.Characters[idx]
end

-- 获取当前出战角色Id
function XPcgPlayingStage:GetAttackCharacterId()
    return self.Characters[1]:GetId()
end

-- 获取怪物列表
function XPcgPlayingStage:GetMonsters()
    return self.Monsters
end

-- 获取怪物
function XPcgPlayingStage:GetMonster(idx)
    return self.MonsterDic[idx]
end

-- 获取手牌堆
function XPcgPlayingStage:GetHandPool()
    return self.HandPool
end

-- 获取手牌数量
function XPcgPlayingStage:GetHandPoolCount()
    return #self.HandPool
end

-- 获取指挥官
function XPcgPlayingStage:GetCommander()
    return self.Commander
end


return XPcgPlayingStage
