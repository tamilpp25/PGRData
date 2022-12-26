XEntityHelper = XEntityHelper or {}

XEntityHelper.TEAM_MAX_ROLE_COUNT = 3

-- entityId : CharacterId or RobotId
function XEntityHelper.GetCharacterIdByEntityId(entityId)
    if XRobotManager.CheckIsRobotId(entityId) then
        return XRobotManager.GetRobotTemplate(entityId).CharacterId
    else
        return entityId
    end
end

function XEntityHelper.GetIsRobot(entityId)
    return XRobotManager.CheckIsRobotId(entityId)
end

function XEntityHelper.GetCharacterName(entityId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    local config = XCharacterConfigs.GetCharacterTemplate(characterId)
    if not config then return "none" end
    return config.Name
end

function XEntityHelper.GetCharacterTradeName(entityId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    local config = XCharacterConfigs.GetCharacterTemplate(characterId)
    if not config then return "none" end
    return config.TradeName
end

function XEntityHelper.GetCharacterSmallIcon(entityId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    return XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId, 0, true)
end