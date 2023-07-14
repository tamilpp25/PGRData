---@class XUiBattleRoomRoleGrid
local XUiBattleRoomRoleGrid = XClass(nil, "XUiBattleRoomRoleGrid")

function XUiBattleRoomRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

---@param team XTeam
---@param entity XRobot
function XUiBattleRoomRoleGrid:SetData(entity, team, stageId, pos)
    local characterId = entity:GetCharacterId()
    self.RImgHeadIcon:SetRawImage(XFubenSpecialTrainConfig.GetCuteModelSmallHeadIcon(characterId))

    self.TextName1.text = XEntityHelper.GetCharacterName(characterId)
    self.TextName2.text = XEntityHelper.GetCharacterTradeName(characterId)

    local currentEntityId = team:GetEntityIdByTeamPos(pos)
    self:SetCurrentStatus(currentEntityId == entity:GetId())
end

function XUiBattleRoomRoleGrid:SetSelectStatus(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end

function XUiBattleRoomRoleGrid:SetInSameStatus(value)
    -- self.PanelSameRole.gameObject:SetActiveEx(value)
end

function XUiBattleRoomRoleGrid:SetCurrentStatus(value)
    self.ImgSpecify.gameObject:SetActiveEx(value)
end

return XUiBattleRoomRoleGrid
