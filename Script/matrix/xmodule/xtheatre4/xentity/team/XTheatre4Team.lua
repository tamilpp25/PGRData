local XTeam = require("XEntity/XTeam/XTeam")
---@class XTheatre4Team : XTeam
local XTheatre4Team = XClass(XTeam, "XTheatre4Team")

-- 根据服务端数据更新队伍信息
---@param data XTheatre4TeamData
function XTheatre4Team:UpdateTeamData(data)
    if not data then
        self:Clear()
        return
    end
    self:UpdateCaptainPos(data:GetCaptainPos())
    self:UpdateFirstFightPos(data:GetFirstFightPos())
    self:UpdateCardIdsAndRobotIds(data:GetCardIds(), data:GetRobotIds())
    self:SetEnterCgIndex(data:GetEnterCgIndex())
    self:SetSettleCgIndex(data:GetSettleCgIndex())
end

-- 更新角色Id和机器人Id
---@param cardIds number[]
---@param robotIds number[]
function XTheatre4Team:UpdateCardIdsAndRobotIds(cardIds, robotIds)
    local result = { 0, 0, 0 }
    for i = 1, 3 do -- 三个槽位
        local id = 0
        if XTool.IsNumberValid(cardIds[i]) then
            id = cardIds[i]
        elseif XTool.IsNumberValid(robotIds[i]) then
            id = robotIds[i]
        end
        result[i] = id
    end
    self:UpdateEntityIds(result)
end

-- 获取队伍数据
---@return { CaptainPos:number, FirstFightPos:number, CardIds:number[], RobotIds:number[], GeneralSkill:number, EnterCgIndex:number, SettleCgIndex:number }
function XTheatre4Team:GetTeamData()
    local cardIds = {}
    local robotIds = {}
    for pos, id in pairs(self.EntitiyIds) do
        if XRobotManager.CheckIsRobotId(id) then
            cardIds[pos] = 0
            robotIds[pos] = id
        else
            cardIds[pos] = id
            robotIds[pos] = 0
        end
    end
    local data = {
        CaptainPos = self:GetCaptainPos(),
        FirstFightPos = self:GetFirstFightPos(),
        CardIds = cardIds,
        RobotIds = robotIds,
        GeneralSkill = self:GetCurGeneralSkill(),
        EnterCgIndex = self:GetEnterCgIndex(),
        SettleCgIndex = self:GetSettleCgIndex(),
    }
    return data
end

return XTheatre4Team
