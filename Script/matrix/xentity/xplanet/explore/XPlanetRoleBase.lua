local XPlanetBuff = require("XEntity/XPlanet/Explore/XPlanetBuff")

---@class XPlanetRoleBase
local XPlanetRoleBase = XClass(nil, "XPlanetRoleBase")

function XPlanetRoleBase:Ctor()
    self._Uid = false
    self._Camp = XPlanetExploreConfigs.CAMP.NONE

    -- 是否探索中
    self._IsAlive = false
end

function XPlanetRoleBase:GetUid()
    return self._Uid
end

function XPlanetRoleBase:SetUid(value)
    self._Uid = value
end

function XPlanetRoleBase:GetIcon()
    return ""
end

function XPlanetRoleBase:GetCamp()
    return self._Camp
end

function XPlanetRoleBase:SetAlive(value)
    self._IsAlive = value
end

function XPlanetRoleBase:IsAlive()
    return self._IsAlive
end

function XPlanetRoleBase:GetName()
    return ""
end

function XPlanetRoleBase:GetAttr()
    if self._IsAlive then
        local attribute = XDataCenter.PlanetManager.GetExploreAttr(self)
        return attribute
    end
    return self:_GetAttr()
end

function XPlanetRoleBase:_GetAttr()
    return {}
end

function XPlanetRoleBase:GetBuff()
    local buffList
    local debuffList
    if self._IsAlive then
        buffList = {}
        debuffList = {}
        local eventDict = XDataCenter.PlanetManager.GetStageData():GetAddEvents(self:GetCamp(), self:GetIdFromServer())

        for eventId, amount in pairs(eventDict) do
            ---@type XPlanetBuff
            local buff = XPlanetBuff.New()
            buff:SetEventId(eventId)
            buff:SetAmount(amount)
            if buff:IsIncrease() then
                buffList[#buffList + 1] = buff
            else
                debuffList[#debuffList + 1] = buff
            end
        end
    else
        buffList, debuffList = self:_GetBuff()
    end
    -- 过滤show
    if not XTool.IsTableEmpty(buffList) then
        for i = #buffList, 1, -1 do
            if not buffList[i]:IsShow() then
                table.remove(buffList, i)
            end
        end
    end
    if not XTool.IsTableEmpty(debuffList) then
        for i = #debuffList, 1, -1 do
            if not debuffList[i]:IsShow() then
                table.remove(debuffList, i)
            end
        end
    end
    return buffList, debuffList
end

function XPlanetRoleBase:_GetBuff()
    return {}, {}
end

function XPlanetRoleBase:RequestUpdateAttr()
end

function XPlanetRoleBase:IsPlayer()
    return self._Camp == XPlanetExploreConfigs.CAMP.PLAYER
end

function XPlanetRoleBase:IsBoss()
    return self._Camp == XPlanetExploreConfigs.CAMP.BOSS
end

function XPlanetRoleBase:GetIdFromServer()
    return false
end

return XPlanetRoleBase