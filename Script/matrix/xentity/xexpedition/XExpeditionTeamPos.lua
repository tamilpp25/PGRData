-- 虚像地平线招募位置对象
local XExpeditionTeamPos = XClass(nil, "XExpeditionTeamPos")
--================
--构造函数
--================
function XExpeditionTeamPos:Ctor(teamPosId)
    self.TeamPosId = teamPosId
end
--================
--获取是否解锁
--================
function XExpeditionTeamPos:GetIsUnLock()
    return true
end
--================
--获取条件描述
--================
function XExpeditionTeamPos:GetConditionDes()
    return ""
end
--================
--获取位置Id
--================
function XExpeditionTeamPos:GetTeamPosId()
    return self.TeamPosId
end
return XExpeditionTeamPos