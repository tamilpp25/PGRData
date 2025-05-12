local type = type

--动作塔防队伍配置数据
local XDoubleTowerTeamDb = XClass(nil, "XDoubleTowerTeamDb")

local Default = {
    _RoleId = 0, --角色Id
    _RoleBasePluginId = 0, --配置的SlotPluginType为0时为PluginLevelId，否则为PluginId
    _RolePluginList = {},
    _GuardIdIndex = -1, --NPCId与GuardBaseId 的下标
    _GuardBasePluginId = 0, --配置的SlotPluginType为0时为PluginLevelId，否则为PluginId
    _GuardPluginList = {},
}

local GetDefaultRoleId = function()
    local charList = XMVCA.XCharacter:GetOwnCharacterList(XEnumConst.CHARACTER.CharacterType.Normal)
    return charList[1]:GetId()
end

function XDoubleTowerTeamDb:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XDoubleTowerTeamDb:UpdateData(data)
    self:SetRoleId(data.RoleId)
    self:SetRoleBasePluginId(data.RoleBasePluginLevelId)
    self:SetRolePluginList(data.RolePluginList)
    self:SetGuardPluginList(data.GuardPluginList)
    self:RefreshGuardIndex(data.GuardIndex + 1) -- 守卫下标，需要加1，lua与C# 起始下标不一致 
end

function XDoubleTowerTeamDb:SetRoleId(roleId)
    self._RoleId = roleId
end

function XDoubleTowerTeamDb:GetRoleId()
    return self._RoleId
end

function XDoubleTowerTeamDb:SetRoleBasePluginId(roleBasePluginId)
    self._RoleBasePluginId = XTool.IsNumberValid(roleBasePluginId) and roleBasePluginId 
            or XDoubleTowersConfigs.GetDefaultRoleBaseId()
end

function XDoubleTowerTeamDb:GetRoleBasePluginId()
    return self._RoleBasePluginId
end

--获得角色基础插件的图标
function XDoubleTowerTeamDb:GetRoleBasePluginIcon()
    local basePluginId = self:GetRoleBasePluginId()
    return XDoubleTowersConfigs.GetRoleIconByPluginLevelId(basePluginId)
end

function XDoubleTowerTeamDb:IsRoleBasePluginId(pluginId)
    return self:GetRoleBasePluginId() == pluginId
end

function XDoubleTowerTeamDb:SetRolePluginList(rolePluginList)
    self._RolePluginList = rolePluginList
end

function XDoubleTowerTeamDb:SetRolePluginId(index, pluginId)
    local rolePluginMaxCount = XDoubleTowersConfigs.GetRolePluginMaxCount()
    for i = 1, rolePluginMaxCount do
        if not self._RolePluginList[i] then
            self._RolePluginList[i] = 0
        end
        if i == index then
            self._RolePluginList[i] = pluginId
        end
    end
end

function XDoubleTowerTeamDb:RemoveRolePlugin(index)
    if not (self._RolePluginList and self._RolePluginList[index]) then
        return false
    end
    local defaultId = XDoubleTowersConfigs.GetRoleDefaultPluginId()
    local removeId = self._RolePluginList[index]
    local list = self:GetRolePluginList()
    local count = 0
    for i, pId in pairs(list) do
        if XTool.IsNumberValid(pId) then
            count = count + 1
        end
    end
    if defaultId == removeId and count == 1 then
        XUiManager.TipText("DoubleTowersMustLeftOne")
        return false
    end
    self._RolePluginList[index] = 0
    return true
end

function XDoubleTowerTeamDb:GetRolePluginId(index)
    return self._RolePluginList[index]
end

function XDoubleTowerTeamDb:GetRolePluginList()
    --如果为空，则填入默认值
    local validCount = 0
    for i, pId in pairs(self._RolePluginList) do
        if XTool.IsNumberValid(pId) then
            validCount = validCount + 1
        end
    end
    if XTool.IsTableEmpty(self._RolePluginList) or validCount ==0 then
        self._RolePluginList = { XDoubleTowersConfigs.GetRoleDefaultPluginId() } 
    end
    return self._RolePluginList
end

function XDoubleTowerTeamDb:SetGuardPluginList(guardPluginList)
    self._GuardPluginList = guardPluginList
end

function XDoubleTowerTeamDb:SetGuardPluginId(index, pluginId)
    local guardPluginMaxCount = XDoubleTowersConfigs.GetGuardPluginMaxCount()
    for i = 1, guardPluginMaxCount do
        if not self._GuardPluginList[i] then
            self._GuardPluginList[i] = 0
        end
        if i == index then
            self._GuardPluginList[i] = pluginId
        end
    end
end

function XDoubleTowerTeamDb:RemoveGuardPlugin(index)
    if not (self._GuardPluginList and self._GuardPluginList[index]) then
        return false
    end

    self._GuardPluginList[index] = 0
    return true
end

function XDoubleTowerTeamDb:GetGuardPluginList()
    return self._GuardPluginList
end

--==============================
 ---@desc 刷新守卫下标
 ---@guardIndex 守卫下标
--==============================
function XDoubleTowerTeamDb:RefreshGuardIndex(guardIndex)
    self._GuardIdIndex = guardIndex > 0 and guardIndex or XDoubleTowersConfigs.GetDefaultGuardIndex()
    self._GuardBasePluginId = XDoubleTowersConfigs.GetGuardPluginLevelId(self._GuardIdIndex)
end

function XDoubleTowerTeamDb:GetGuardBasePluginId()
    return self._GuardBasePluginId
end

--获得守卫基础插件的图标
 function XDoubleTowerTeamDb:GetGuardBasePluginIcon()

     local basePluginId = self:GetGuardBasePluginId()
     return XDoubleTowersConfigs.GetGuardIconByPluginLevelId(basePluginId)
 end

function XDoubleTowerTeamDb:IsGuardBasePluginId(pluginId)
    return self:GetGuardBasePluginId() == pluginId
end

--是否装备了插件
function XDoubleTowerTeamDb:IsEquipPlugin(pluginId)
    local guardPluginList = self:GetGuardPluginList()
    for slotIndex, guardPluginId in ipairs(guardPluginList) do
        if guardPluginId == pluginId then
            return true, slotIndex
        end
    end

    local rolePluginList = self:GetRolePluginList()
    for slotIndex, rolePluginId in ipairs(rolePluginList) do
        if rolePluginId == pluginId then
            return true, slotIndex
        end
    end
end

--==============================
 ---@desc 获取基础插件id
 ---@pluginType 插件类型 
 ---@return number BasePluginId
--==============================
function XDoubleTowerTeamDb:GetBasePluginId(pluginType)
    if pluginType == XDoubleTowersConfigs.ModuleType.Role then
        return self:GetRoleBasePluginId()
    elseif pluginType == XDoubleTowersConfigs.ModuleType.Guard then
        return self:GetGuardBasePluginId()
    end
end

--==============================
 ---@desc 获取装备的插件列表
 ---@pluginType 插件类型
 ---@return table pluginList
--==============================
function XDoubleTowerTeamDb:GetPluginList(pluginType)
    if pluginType == XDoubleTowersConfigs.ModuleType.Role then
        return self:GetRolePluginList()
    elseif pluginType == XDoubleTowersConfigs.ModuleType.Guard then
        return self:GetGuardPluginList()
    end
end

--==============================
 ---@desc 根据模块类型装备插件
 ---@moduleType 插件类型
 ---@index      插槽位置
 ---@pluginId   插件ID
 ---@return     nil
--==============================
function XDoubleTowerTeamDb:EquipPlugin(moduleType, index, pluginId)
    if moduleType == XDoubleTowersConfigs.ModuleType.Role then
        self:SetRolePluginId(index, pluginId)
    elseif moduleType == XDoubleTowersConfigs.ModuleType.Guard then
        self:SetGuardPluginId(index, pluginId)
    end
end

--==============================
 ---@desc 根据模块类型清空插槽
 ---@moduleType 插件类型
--==============================
function XDoubleTowerTeamDb:ResetPlugin(moduleType)
    if moduleType == XDoubleTowersConfigs.ModuleType.Role then
        self:SetRolePluginList({})
    elseif moduleType == XDoubleTowersConfigs.ModuleType.Guard then
        self:SetGuardPluginList({})
    end
end

--==============================
 ---@desc 据模块类型卸下插件
 ---@moduleType 插件类型
 ---@index      插槽位置 
 ---@return     boolean
--==============================
function XDoubleTowerTeamDb:UnloadPlugin(moduleType, index)
    if moduleType == XDoubleTowersConfigs.ModuleType.Role then
        return self:RemoveRolePlugin(index)
    elseif moduleType == XDoubleTowersConfigs.ModuleType.Guard then
        return self:RemoveGuardPlugin(index)
    end
end

--获得发给后端设置插件的数据
function XDoubleTowerTeamDb:GetRequestDoubleTowerSetTeam()
    local roleBasePluginLevelId = self:GetRoleBasePluginId()
    local roleId = self:GetRoleId()
    return {
        --未设置出战队员时，取玩家身上的成员
        RoleId = XTool.IsNumberValid(roleId) and roleId or GetDefaultRoleId(),
        RoleBasePluginLevelId = self:GetRoleBasePluginId(),
        RolePluginList = self:GetRolePluginList(),
        GuardIndex = self._GuardIdIndex - 1, --服务器下标0开始
        GuardPluginList = self:GetGuardPluginList()
    }
end

return XDoubleTowerTeamDb