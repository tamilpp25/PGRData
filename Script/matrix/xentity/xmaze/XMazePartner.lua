---@class XMazePartner
local XMazePartner = XClass(nil, "XMazePartner")

function XMazePartner:Ctor()
    self._RobotId = 0
end

function XMazePartner:SetRobotId(id)
    self._RobotId = id
end

function XMazePartner:GetModelName()
    return "QR2LuolanMd010011TX"
end

return XMazePartner