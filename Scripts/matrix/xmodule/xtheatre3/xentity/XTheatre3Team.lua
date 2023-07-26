local XTeam = require("XEntity/XTeam/XTeam")
---@class XTheatre3Team : XTeam
local XTheatre3Team = XClass(XTeam, "XTheatre3Team")

function XTheatre3Team:Ctor()
    if self:GetIsEmpty() then
        self.FirstFightPos = 2
        self.CaptainPos = 2
    end
end

function XTheatre3Team:UpdateCardIdsAndRobotIds(cardIds, robotIds)
    for i = 1, 3 do -- 三个槽位
        local id = 0
        if XTool.IsNumberValid(cardIds[i]) then
            id = cardIds[i]
        elseif XTool.IsNumberValid(robotIds[i]) then
            id = robotIds[i]
        end
        self:UpdateEntityTeamPos(id, i, true)
    end
end

function XTheatre3Team:Clear()
    self.EntitiyIds = {0, 0, 0}
    self.FirstFightPos = 2
    self.CaptainPos = 2
    self:Save()
end

return XTheatre3Team