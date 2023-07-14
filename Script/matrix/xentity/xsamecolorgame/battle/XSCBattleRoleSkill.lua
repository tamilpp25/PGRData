local XSCRoleSkill = require("XEntity/XSameColorGame/Skill/XSCRoleSkill")
local XSCBattleRoleSkill = XClass(XSCRoleSkill, "XSCBattleRoleSkill")

function XSCBattleRoleSkill:Ctor(groupId)
    self.GroupId = groupId
    self.CurCountDown = 0 
    self.UsedCount = 0
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

return XSCBattleRoleSkill