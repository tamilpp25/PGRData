---@class XScoreTowerTeam
local XScoreTowerTeam = XClass(nil, "XScoreTowerTeam")

function XScoreTowerTeam:Ctor()
    -- 编队的1,2,3位置，分别使用了什么角色，记录的是角色位置
    ---@type number[]
    self.PosIds = {}
    self.CaptainIndex = 0
    -- 首次下场位置
    self.FirstFightPos = 0
    -- 入场NPC索引
    self.EnterCgIndex = 0
    -- 结算NPC索引
    self.SettleCgIndex = 0
    -- 效应技能
    self.GeneralSkill = 0
end

function XScoreTowerTeam:NotifyScoreTowerTeamData(data)
    self.PosIds = data.PosIds or {}
    self.CaptainIndex = data.CaptainIndex or 0
    self.FirstFightPos = data.FirstFightPos or 0
    self.EnterCgIndex = data.EnterCgIndex or 0
    self.SettleCgIndex = data.SettleCgIndex or 0
    self.GeneralSkill = data.GeneralSkill or 0
end

--region 数据获取

function XScoreTowerTeam:GetPosIds()
    return self.PosIds
end

function XScoreTowerTeam:GetCaptainIndex()
    return self.CaptainIndex
end

function XScoreTowerTeam:GetFirstFightPos()
    return self.FirstFightPos
end

function XScoreTowerTeam:GetEnterCgIndex()
    if self.EnterCgIndex < 0 then
        return 0
    end
    --return self.EnterCgIndex
    return 0
end

function XScoreTowerTeam:GetSettleCgIndex()
    if self.SettleCgIndex < 0 then
        return 0
    end
    --return self.SettleCgIndex
    return 0
end

function XScoreTowerTeam:GetGeneralSkill()
    return self.GeneralSkill
end

--endregion

return XScoreTowerTeam
