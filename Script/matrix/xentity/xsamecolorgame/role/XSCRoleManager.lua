local XSCRole = require("XEntity/XSameColorGame/Role/XSCRole")

local XSCRoleManager = XClass(nil, "XSCRoleManager")

function XSCRoleManager:Ctor()
    self.RoleDic = {}
    -- -- 已获得的角色id数据
    -- self.ReceivedRoleIdDic = {}
end

-- function XSCRoleManager:InitWithServerData(data)
    
-- end

-- function XSCRoleManager:AddReceivedRoleId(roleId)
--     self.ReceivedRoleIdDic[roleId] = true
-- end

-- function XSCRoleManager:CheckRoleIsReceived(roleId)
--     return self.ReceivedRoleIdDic[roleId] or false
-- end

-- 获取初始角色
function XSCRoleManager:GetInitRoles()
    if self.__InitRoles == nil then
        self.__InitRoles = {}
        local roleIds = XDataCenter.SameColorActivityManager.GetInitRoleIds()
        for _, id in ipairs(roleIds) do
            table.insert(self.__InitRoles, self:GetRole(id))
        end
    end
    return self.__InitRoles
end

function XSCRoleManager:GetRoles()
    local roleConfigDic = XSameColorGameConfigs.GetRoleConfigDic()
    local result = {}
    for id, config in pairs(roleConfigDic) do
        table.insert(result, self:GetRole(id))
    end
    -- 默认选定的 已拥有的 已解锁 未解锁
    table.sort(result, function(roleA, roleB)
        -- 是否已拥有
        local hasA = roleA:GetIsReceived() and 1000000 or 0
        local hasB = roleB:GetIsReceived() and 1000000 or 0
        -- 是否已解锁
        local isUnlockA = roleA:GetIsInUnlockTime() and 100000 or 0
        local isUnlockB = roleB:GetIsInUnlockTime() and 100000 or 0
        -- 权重
        local weightA = hasA + isUnlockA + (99 - roleA:GetId())
        local weightB = hasB + isUnlockB + (99 - roleB:GetId())
        return weightA > weightB
    end)
    return result
end

function XSCRoleManager:GetRole(id)
    local result = self.RoleDic[id]
    if result == nil then
        result = XSCRole.New(id)
        self.RoleDic[id] = result
    end
    return result
end

return XSCRoleManager