local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
---@class XGDSyncToServerComponent : XGDComponet
local XGDSyncToServerComponent = XClass(XGDComponet, "XGDSyncToServerComponent")

---@param role XGuildDormRole
---@param room XGuildDormRoom
function XGDSyncToServerComponent:Ctor(role, room)
    self.Role = role
    self.Room = room
end

function XGDSyncToServerComponent:Init()
    XGDSyncToServerComponent.Super.Init(self)
    self:SetUpdateIntervalTime(self.Room:GetSyncTime())
end

function XGDSyncToServerComponent:Update(dt)
    -- 交互中自己触发逻辑，不需要跑这里
    if self.Role:GetIsInteracting() then
        return
    end
    self.Role:SyncToServer()
end

return XGDSyncToServerComponent