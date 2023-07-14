local XGuildDormRole = require("XEntity/XGuildDorm/Role/XGuildDormRole")
---@class XGuildDormPlayerRole : XGuildDormRole
local XGuildDormPlayerRole = XClass(XGuildDormRole, "XGuildDormPlayerRole")

function XGuildDormPlayerRole:Ctor()
    self.PlayerId = nil
end

function XGuildDormPlayerRole:UpdateWithServerData(data) 
    XGuildDormPlayerRole.Super.UpdateWithServerData(self, data)
    self.PlayerId = data.PlayerId
    self:GetRLRole():UpdatePlayerId(self.PlayerId)
end

function XGuildDormPlayerRole:GetPlayerId()
    return self.PlayerId    
end

function XGuildDormPlayerRole:UpdateInteractStatus(value)
    self.InteractStatus = value
    if value == XGuildDormConfig.InteractStatus.End then
        if self:CheckIsSelfPlayer() then
            local currentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
            if currentRoom and currentRoom:CheckPlayerIsInteract(self.PlayerId) then
                XDataCenter.GuildDormManager.RequestFurnitureInteract(-1)
            end
        else
            local com = self:GetComponent("XGDSyncToClientComponent")
            if com == nil then return end
            -- 交互结束后自己更新一次，避免因为上次快速插值
            local transform = self:GetRLRole():GetTransform()
            com:UpdateCurrentSyncData(transform.position, transform.rotation
                , XGuildDormConfig.SyncState.None)
        end
        -- 记录上一次交互时间
        self.LastEndInteractTime = XTime.GetServerNowTimestamp()
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ROLE_INTERACT_STOP, self.PlayerId)
    end
end

function XGuildDormPlayerRole:CheckIsSelfPlayer()
    return self.PlayerId == XPlayer.Id
end


return XGuildDormPlayerRole