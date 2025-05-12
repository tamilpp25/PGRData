local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiPracticeRoleDetailProxy = XClass(XUiBattleRoomRoleDetailDefaultProxy,"XUiPracticeRoleDetailProxy")

function XUiPracticeRoleDetailProxy:Ctor(stageId, team)
    self.StageId = stageId
    self.Team = team
end

function XUiPracticeRoleDetailProxy:GetEntities()
    local entities = XMVCA.XCharacter:GetOwnCharacterList()

    -- 加入活动的机器人
    if XMVCA.XSimulateTrain:IsActivityOpen() then
        local monsterId = XPracticeConfigs.GetSimulateTrainMonsterId(self.StageId)
        local bossId = XMVCA.XSimulateTrain:GetBossIdByMonsterId(monsterId)
        local robotIds = XMVCA.XSimulateTrain:GetBossRobotIds(bossId)
        for _, robotId in ipairs(robotIds) do
            local entity = XRobotManager.GetRobotById(robotId)
            table.insert(entities, entity)
        end
    end
    
    return entities
end

return XUiPracticeRoleDetailProxy