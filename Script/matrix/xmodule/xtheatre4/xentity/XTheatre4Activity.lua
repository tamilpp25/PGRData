-- 活动数据
---@class XTheatre4Activity
local XTheatre4Activity = XClass(nil, "XTheatre4Activity")

function XTheatre4Activity:Ctor()
    -- 活动id
    self.ActivityId = 0
    -- 当前冒险
    ---@type XTheatre4Adventure
    self.AdventureData = nil
    -- 上一次冒险结算数据
    ---@type XTheatre4AdventureSettle
    self.PreAdventureSettleData = nil
    -- 科技点
    self.TechPoint = 0
    -- 已解锁科技
    ---@type number[]
    self.Techs = {}
    -- 藏品图鉴
    ---@type number[]
    self.ItemsAtlas = {}
    -- 天赋图鉴
    ---@type number[]
    self.TalentAtlas = {}
    -- 地图图鉴
    ---@type number[]
    self.MapAtlas = {}
    -- 已通关难度Id
    ---@type table<number, number>
    self.Difficultys = {}
    -- Bp总经验
    self.TotalBattlePassExp = 0
    -- Bp已获得奖励Id
    ---@type number[]
    self.BattlePassGotRewardIds = {}
    -- 通关词缀次数记录
    ---@type table<number, number>
    self.PassAffixCounts = {}
    -- 通关地图路线集
    ---@type number[]
    self.PassMapBuildprints = {}
    -- 通关结局集
    ---@type table<number, number>
    self.Endings = {}
    -- 最大通关章节数记录
    self.MaxPassChapterCount = 0
    -- 历史最高分
    self.MaxScore = 0
    -- 外循环完成事件记录
    ---@type table<number, number>
    self.GlobalFinishEventIds = {}
end

-- 服务端通知
function XTheatre4Activity:NotifyActivityData(data)
    self.ActivityId = data.ActivityId or 0
    self:UpdateAdventureData(data.AdventureData)
    self:UpdatePreAdventureSettleData(data.PreAdventureSettleData)
    self.TechPoint = data.TechPoint or 0
    self.Techs = data.Techs or {}
    self.ItemsAtlas = data.ItemsAtlas or {}
    self.TalentAtlas = data.TalentAtlas or {}
    self.MapAtlas = data.MapAtlas or {}
    self.Difficultys = data.Difficultys or {}
    self.TotalBattlePassExp = data.TotalBattlePassExp or 0
    self.BattlePassGotRewardIds = data.BattlePassGotRewardIds or {}
    self.PassAffixCounts = data.PassAffixCounts or {}
    self.PassMapBuildprints = data.PassMapBuildprints or {}
    self.Endings = data.Endings or {}
    self.MaxPassChapterCount = data.MaxPassChapterCount or 0
    self.MaxScore = data.MaxScore or 0
    self.GlobalFinishEventIds = data.GlobalFinishEventIds or {}
end

-- 更新冒险数据
function XTheatre4Activity:UpdateAdventureData(data)
    if not data then
        self.AdventureData = nil
        return
    end
    if not self.AdventureData then
        self.AdventureData = require("XModule/XTheatre4/XEntity/XTheatre4Adventure").New()
    end
    self.AdventureData:NotifyAdventureData(data)
end

-- 更新上一次冒险结算数据
function XTheatre4Activity:UpdatePreAdventureSettleData(data)
    if not data then
        self.PreAdventureSettleData = nil
        return
    end
    if not self.PreAdventureSettleData then
        self.PreAdventureSettleData = require("XModule/XTheatre4/XEntity/XTheatre4AdventureSettle").New()
    end
    self.PreAdventureSettleData:NotifyPreAdventureSettleData(data)
end

-- 设置Bp总经验
function XTheatre4Activity:SetTotalBattlePassExp(exp)
    self.TotalBattlePassExp = exp
end

-- 获取活动id
function XTheatre4Activity:GetActivityId()
    return self.ActivityId
end

-- 获取冒险数据
---@return XTheatre4Adventure
function XTheatre4Activity:GetAdventureData()
    return self.AdventureData
end

-- 获取上一次冒险结算数据
---@return XTheatre4AdventureSettle
function XTheatre4Activity:GetPreAdventureSettleData()
    return self.PreAdventureSettleData
end

-- 获取Bp总经验
function XTheatre4Activity:GetTotalBattlePassExp()
    return self.TotalBattlePassExp
end

-- 获取Bp已获得奖励Id
---@return number[]
function XTheatre4Activity:GetBattlePassGotRewardIds()
    return self.BattlePassGotRewardIds
end

-- 更新Bp已获得奖励Id
function XTheatre4Activity:SetBattlePassGotRewardIds(rewardIds)
    self.BattlePassGotRewardIds = rewardIds
end

-- 更新Bp已获得奖励Id
function XTheatre4Activity:AddBattlePassGotRewardId(rewardId)
    if XTool.IsTableEmpty(self.BattlePassGotRewardIds) then
        self.BattlePassGotRewardIds = { rewardId }
    else
        for _, reward in pairs(self.BattlePassGotRewardIds) do
            if rewardId == reward then
                return
            end
        end

        table.insert(self.BattlePassGotRewardIds, rewardId)
    end
end

-- 获取已解决科技
---@return number[]
function XTheatre4Activity:GetTechs()
    return self.Techs
end

-- 添加已解锁科技
function XTheatre4Activity:AddTechs(techId)
    if XTool.IsTableEmpty(self.Techs) then
        self.Techs = { techId }
    else
        for _, tech in pairs(self.Techs) do
            if techId == tech then
                return
            end
        end

        table.insert(self.Techs, techId)
    end
end

-- 获取结局通过次数
function XTheatre4Activity:GetEndingPassCount(endingId)
    return self.Endings[endingId] or 0
end

-- 获取通关结局集
---@return table<number, number>
function XTheatre4Activity:GetEndings()
    return self.Endings
end

function XTheatre4Activity:SetEndings(data)
    self.Endings = data
end

-- 获取已通关难度Id
---@return table<number, number>
function XTheatre4Activity:GetDifficultys()
    return self.Difficultys
end

function XTheatre4Activity:SetDifficultys(data)
    self.Difficultys = data
end

-- 获取历史最高分
function XTheatre4Activity:GetMaxScore()
    return self.MaxScore
end

-- 获取外循环完成事件记录
---@param eventId number 事件Id
---@return number 次数
function XTheatre4Activity:GetGlobalFinishEventTimes(eventId)
    return self.GlobalFinishEventIds[eventId] or 0
end

-- 设置外循环完成事件记录
function XTheatre4Activity:SetGlobalFinishEventIds(eventIds)
    self.GlobalFinishEventIds = eventIds
end

return XTheatre4Activity
