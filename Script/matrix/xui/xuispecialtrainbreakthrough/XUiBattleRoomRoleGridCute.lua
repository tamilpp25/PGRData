---@class XUiBattleRoomRoleGridCuteCute
local XUiBattleRoomRoleGridCute = XClass(nil, "XUiBattleRoomRoleGridCute")

function XUiBattleRoomRoleGridCute:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

---@param team XTeam
---@param entity XRobot
function XUiBattleRoomRoleGridCute:SetData(entity, team, stageId, pos)
    local characterId = entity:GetCharacterId()
    self.RImgHeadIcon:SetRawImage(XCharacterCuteConfig.GetCuteModelSmallHeadIcon(characterId))

    self.TextName1.text = XEntityHelper.GetCharacterName(characterId)
    self.TextName2.text = XEntityHelper.GetCharacterTradeName(characterId)

    local currentEntityId = team:GetEntityIdByTeamPos(pos)
    self:SetCurrentStatus(currentEntityId == entity:GetId())
end

function XUiBattleRoomRoleGridCute:SetSelectStatus(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end

function XUiBattleRoomRoleGridCute:SetInSameStatus(value)
    -- self.PanelSameRole.gameObject:SetActiveEx(value)
end

function XUiBattleRoomRoleGridCute:SetCurrentStatus(value)
    self.ImgSpecify.gameObject:SetActiveEx(value)
end

return XUiBattleRoomRoleGridCute
