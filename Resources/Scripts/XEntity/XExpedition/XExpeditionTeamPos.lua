-- 虚像地平线招募位置对象
local XExpeditionTeamPos = XClass(nil, "XExpeditionTeamPos")
--================
--构造函数
--================
function XExpeditionTeamPos:Ctor(teamPosId)
    self.TeamPosCfg = XExpeditionConfig.GetTeamPosCfgById(teamPosId)
end
--================
--获取是否解锁
--================
function XExpeditionTeamPos:GetIsUnLock()
    if not self.TeamPosCfg.ConditionId or self.TeamPosCfg.ConditionId == 0 then
        return true
    else
        return XConditionManager.CheckCondition(self.TeamPosCfg.ConditionId)
    end
end
--================
--获取条件描述
--================
function XExpeditionTeamPos:GetConditionDes()
    return self.TeamPosCfg and self.TeamPosCfg.ConditionDes
end
--================
--获取位置Id
--================
function XExpeditionTeamPos:GetTeamPosId()
    return self.TeamPosCfg and self.TeamPosCfg.Id
end
return XExpeditionTeamPos