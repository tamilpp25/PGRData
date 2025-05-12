local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
---@class XUiTheatre4BattleRoomRoleDetail : XUiBattleRoomRoleDetailDefaultProxy
local XUiTheatre4BattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiTheatre4BattleRoomRoleDetail")

---@param team XTheatre4Team
function XUiTheatre4BattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
end

function XUiTheatre4BattleRoomRoleDetail:GetEntities(characterType)
    local entities = XMVCA.XTheatre4:GetCharacterList(characterType)
    return entities
end

function XUiTheatre4BattleRoomRoleDetail:GetGridProxy()
    return require("XUi/XUiTheatre4/BattleRoom/XUiTheatre4RoleGrid")
end

function XUiTheatre4BattleRoomRoleDetail:GetFilterControllerConfig()
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    return characterAgency:GetModelCharacterFilterController()["UiTheatre4BattleRoomDetail"]
end

return XUiTheatre4BattleRoomRoleDetail
