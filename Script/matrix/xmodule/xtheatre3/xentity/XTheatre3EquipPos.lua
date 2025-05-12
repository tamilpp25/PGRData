---@class XTheatre3EquipPos
local XTheatre3EquipPos = XClass(nil, "XTheatre3EquipPos")

function XTheatre3EquipPos:Ctor()
    ---槽位编号，1,2,3
    self.PosId = 0
    ---颜色Id(对应编队Key值)
    self.ColorId = 0
    -- 角色Id|机器人Id
    self.RoleId = 0
end

function XTheatre3EquipPos:UpdateEquipPosIdAndColorId(posId, colorId)
    self.PosId = posId
    self.ColorId = colorId
end

function XTheatre3EquipPos:UpdateEquipPosColorId(colorId)
    self.ColorId = colorId
end

function XTheatre3EquipPos:UpdateEquipPosRoleId(roleId)
    self.RoleId = roleId
end

function XTheatre3EquipPos:GetPos()
    return self.PosId
end

function XTheatre3EquipPos:GetColorId()
    return self.ColorId
end

function XTheatre3EquipPos:GetRoleId()
    return self.RoleId
end

function XTheatre3EquipPos:GetCharacterId()
    return XEntityHelper.GetCharacterIdByEntityId(self.RoleId)
end

function XTheatre3EquipPos:GetCardId()
    if not self:CheckIsRobot() then
        return self.RoleId
    end
    return 0
end

function XTheatre3EquipPos:GetRobotId()
    if self:CheckIsRobot() then
        return self.RoleId
    end
    return 0
end

function XTheatre3EquipPos:CheckIsRobot()
    return XRobotManager.CheckIsRobotId(self.RoleId)
end

function XTheatre3EquipPos:CheckIsHaveCharacter()
    return XTool.IsNumberValid(self.RoleId)
end

return XTheatre3EquipPos