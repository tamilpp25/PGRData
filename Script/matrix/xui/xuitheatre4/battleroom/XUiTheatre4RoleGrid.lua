local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
---@class XUiTheatre4RoleGrid : XUiBattleRoomRoleGrid
local XUiTheatre4RoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiTheatre4RoleGrid")

function XUiTheatre4RoleGrid:SetData(entity)
    self.Super.SetData(self, entity)
    local entityId = self.Character:GetId()
    if not XTool.IsNumberValid(entityId) then
        return
    end
    -- 角色颜色等级
    local colorLevels = XMVCA.XTheatre4:GetCharacterColorLevel(entityId)
    self:SetColorLevel(self.TxtLvNumRed, colorLevels[1])
    self:SetColorLevel(self.TxtLvNumYellow, colorLevels[2])
    self:SetColorLevel(self.TxtLvNumBlue, colorLevels[3])
    -- 角色星级
    self.PanelStar.text = XMVCA.XTheatre4:GetCharacterStar(entityId)
    -- 角色战力
    self:UpdateFight()
end

function XUiTheatre4RoleGrid:SetColorLevel(text, value)
    local isValid = XTool.IsNumberValid(value)
    text.transform.parent.gameObject:SetActiveEx(isValid)
    text.text = isValid and string.format("x%s", value) or ""
end

return XUiTheatre4RoleGrid
