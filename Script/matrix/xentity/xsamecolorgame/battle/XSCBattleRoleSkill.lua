local XSCRoleSkill = require("XEntity/XSameColorGame/Skill/XSCRoleSkill")
---@class XSCBattleRoleSkill:XSCRoleSkill
local XSCBattleRoleSkill = XClass(XSCRoleSkill, "XSCBattleRoleSkill")

function XSCBattleRoleSkill:Ctor(groupId)
    self.GroupId = groupId
    self.CurCountDown = 0 
    self.UsedCount = 0
    self.BallRemoveCount = 0
end

function XSCBattleRoleSkill:SetCountDown(leftCd)
    self.CurCountDown = leftCd
end

function XSCBattleRoleSkill:GetCountDown()
    return self.CurCountDown
end

function XSCBattleRoleSkill:GetUsedCount()
    return self.UsedCount
end

function XSCBattleRoleSkill:AddUsedCount()
    self.UsedCount = self.UsedCount + 1
end

function XSCBattleRoleSkill:ClearUsedCount()
    self.UsedCount = 0
end

function XSCBattleRoleSkill:IsInUsed()
    return XTool.IsNumberValid(self.UsedCount)
end

-- 增加技能消球次数
function XSCBattleRoleSkill:AddBallRemoveCount(count)
    self.BallRemoveCount = self.BallRemoveCount + count
    return self.BallRemoveCount
end

-- 清除技能消球次数
function XSCBattleRoleSkill:ClearBallRemoveCount()
    self.BallRemoveCount = 0
end

-- 清除技能
function XSCBattleRoleSkill:Clear()
    self:ClearUsedCount()
    self:ClearBallRemoveCount()
end

return XSCBattleRoleSkill