local XRobot = require("XEntity/XRobot/XRobot")
local XSuperTowerRole = require("XEntity/XSuperTower/Role/XSuperTowerRole")
local XSuperTowerRoleManager = XClass(nil, "XSuperTowerRoleManager")

-- groupId : XRoomCharFilterTipsConfigs.EnumFilterTagGroup
-- tagValue : XCharacterConfigs.GetCharDetailTemplate(char.Id)
local FilterJudge = function(groupId, tagValue, superTowerRole)
    local characterViewModel = superTowerRole:GetCharacterViewModel()
    -- 职业筛选
    if groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Career then
        if tagValue == characterViewModel:GetCareer() then
            return true
        end
    -- 能量元素筛选
    elseif groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Element then
        local obtainElementList = characterViewModel:GetObtainElements()
        for _, element in pairs(obtainElementList) do
            if element == tagValue then
                return true
            end
        end
    else
        XLog.Error(string.format("XUiRoomCharacter:Filter函数错误，没有处理排序组：%s的逻辑", groupId))
        return false
    end
end

function XSuperTowerRoleManager:Ctor()
    -- XSuperTowerRole
    self.RoleDic = {}
    -- XSuperTowerRole
    self.Roles = {}
    -- 超限角色服务器数据(Id & Level & Exp & PluginId)
    self.TransfiniteRoleDataDic = {}
    -- 角色/机器人爬塔数据
    self.TierRoleHpLeftDic = {}
    -- 缓存已发放的机器人数据
    self.GrantedRobotDic = {}
    -- 排序方法
    self.IsAscendOrder = true
    self.SortFunctionDic = {
        [XRoomCharFilterTipsConfigs.EnumSortTag.SuperLevel] = function(roleA, roleB)
            local characterViewModelA = roleA:GetCharacterViewModel()
            local characterViewModelB = roleB:GetCharacterViewModel()
            local dultWeightA = roleA:GetIsInDult() and 10000 or 0
            local dultWeightB = roleB:GetIsInDult() and 10000 or 0
            if self.IsAscendOrder then
                dultWeightA = dultWeightA * -1
                dultWeightB = dultWeightB * -1
            end
            local aWeight = characterViewModelA:GetId() / 10000000 + roleA:GetSuperLevel() * 100 + dultWeightA
            local bWeight = characterViewModelB:GetId() / 10000000 + roleB:GetSuperLevel() * 100 + dultWeightB
            if self.IsAscendOrder then
                return aWeight < bWeight
            else
                return aWeight > bWeight
            end
        end,
        [XRoomCharFilterTipsConfigs.EnumSortTag.Quality] = function(roleA, roleB)
            local characterViewModelA = roleA:GetCharacterViewModel()
            local characterViewModelB = roleB:GetCharacterViewModel()
            local dultWeightA = roleA:GetIsInDult() and 10000 or 0
            local dultWeightB = roleB:GetIsInDult() and 10000 or 0
            if self.IsAscendOrder then
                dultWeightA = dultWeightA * -1
                dultWeightB = dultWeightB * -1
            end
            local aWeight = characterViewModelA:GetId() / 10000000 + characterViewModelA:GetQuality() * 100 + dultWeightA
            local bWeight = characterViewModelB:GetId() / 10000000 + characterViewModelB:GetQuality() * 100 + dultWeightB
            if self.IsAscendOrder then
                return aWeight < bWeight
            else
                return aWeight > bWeight
            end
        end,
        [XRoomCharFilterTipsConfigs.EnumSortTag.Ability] = function(roleA, roleB)
            local dultWeightA = roleA:GetIsInDult() and 1000000 or 0
            local dultWeightB = roleB:GetIsInDult() and 1000000 or 0
            if self.IsAscendOrder then
                dultWeightA = dultWeightA * -1
                dultWeightB = dultWeightB * -1
            end
            local aWeight = roleA:GetCharacterId() / 10000000 + roleA:GetAbility() * 10 + dultWeightA
            local bWeight = roleB:GetCharacterId() / 10000000 + roleB:GetAbility() * 10 + dultWeightB
            if self.IsAscendOrder then
                return aWeight < bWeight
            else
                return aWeight > bWeight
            end
        end,
    }
    self:RegisterEvents()
end

-- data : List<StTransfiniteCharacterInfo>(Id & Level & Exp & PluginId)
function XSuperTowerRoleManager:InitWithServerData(data)
     for _, transfiniteCharacterInfo in ipairs(data) do
        self.TransfiniteRoleDataDic[transfiniteCharacterInfo.Id] = transfiniteCharacterInfo
     end
end

-- 更新爬塔角色声明数据
-- tierCharacterInfos : StTierCharacterInfo array
function XSuperTowerRoleManager:UpdateTierRoleHpLeftData(tierCharacterInfos)
    if tierCharacterInfos == nil then return end
    for _, tierCharacterInfo in ipairs(tierCharacterInfos) do
        if tierCharacterInfo.Id > 0 then
            self.TierRoleHpLeftDic[tierCharacterInfo.Id] = tierCharacterInfo.HpLeft
        elseif tierCharacterInfo.RobotId > 0 then
            self.TierRoleHpLeftDic[tierCharacterInfo.RobotId] = tierCharacterInfo.HpLeft
        end
    end
end

function XSuperTowerRoleManager:UpdateCharacterLevel(characterId, level)
    self.TransfiniteRoleDataDic[characterId] = self.TransfiniteRoleDataDic[characterId] or {}
    self.TransfiniteRoleDataDic[characterId].Level = level
end

function XSuperTowerRoleManager:UpdateCharacterPlugin(characterId, pluginId)
    self.TransfiniteRoleDataDic[characterId] = self.TransfiniteRoleDataDic[characterId] or {}
    self.TransfiniteRoleDataDic[characterId].PluginId = pluginId
end

function XSuperTowerRoleManager:UpdateCharacterExp(characterId, exp)
    self.TransfiniteRoleDataDic[characterId] = self.TransfiniteRoleDataDic[characterId] or {}
    self.TransfiniteRoleDataDic[characterId].Exp = exp
end

-- 获取当前激活的特典角色配置信息
function XSuperTowerRoleManager:GetCurrentInDultConfig()
    local configs = XSuperTowerConfigs.GetAllCharacterInDultConfigs()
    for _, config in pairs(configs) do
        if XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            return config
        end
    end
    return nil
end

-- 获取能够参战的角色数据
-- return : XSuperTowerRole array
-- characterType : XCharacterConfigs.CharacterType
function XSuperTowerRoleManager:GetCanFightRoles(characterType)
    if self:CheckHasNewRobotGrant() or XTool.IsTableEmpty(self.Roles) then
        self:GenerateRoleData()
    end
    if characterType == nil then
        return self.Roles
    end
    local result = {}
    for _, role in ipairs(self.Roles) do
        if role:GetCharacterType() == characterType then
            table.insert(result, role)
        end
    end
    return result
end

-- id : XCharacter | XRobot
-- return : XSuperTowerRole
function XSuperTowerRoleManager:GetRole(id)
    if self:CheckHasNewRobotGrant() or XTool.IsTableEmpty(self.RoleDic) then
        self:GenerateRoleData()
    end
    return self.RoleDic[id]
end

function XSuperTowerRoleManager:GetTransfiniteLevel(characterId)
    local data = self.TransfiniteRoleDataDic[characterId]
    if not data then return 1 end 
    return data.Level or 1
end

function XSuperTowerRoleManager:GetTransfiniteExp(characterId)
    local data = self.TransfiniteRoleDataDic[characterId]
    if not data then return 0 end 
    return data.Exp or 0
end

function XSuperTowerRoleManager:GetTransfinitePluginId(characterId)
    local data = self.TransfiniteRoleDataDic[characterId]
    if not data then return nil end 
    if data.PluginId == nil or data.PluginId <= 0 then return nil end
    return data.PluginId
end

-- 获取超级爬塔角色生命百分比
function XSuperTowerRoleManager:GetTierRoleHpLeft(roleId)
    return self.TierRoleHpLeftDic[roleId] or 100
end

-- 获取角色是否属于特典中
function XSuperTowerRoleManager:GetCharacterIsInDultAndConfig(id)
    local configs = XSuperTowerConfigs.GetCharacterInDultConfigs(id)
    if not configs then return false end
    for _, config in ipairs(configs) do
        if XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            return true, config
        end
    end
    return false, nil
end

-- 角色请求镶嵌插件
function XSuperTowerRoleManager:RequestMountPlugin(characterId, pluginId, callback)
    local requestData = {
        CharacterId = characterId,
        PluginId = pluginId
    }
    -- res : StMountPluginResponse(PluginCount)
    XNetwork.Call("StMountPluginRequest", requestData, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:UpdateCharacterPlugin(characterId, pluginId)
        if callback then callback() end
    end)
end

function XSuperTowerRoleManager:RequestUpgradeCharacter(characterId, pluginDic, callback)
    local requestData = {
        CharacterId = characterId,
        PluginDic = pluginDic
    }
    XMessagePack.MarkAsTable(requestData.PluginDic)
    -- res : StUpgradeCharacterResponse(Level, Exp)
    XNetwork.Call("StUpgradeCharacterRequest", requestData, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 更新角色等级和经验
        self:UpdateCharacterLevel(characterId, res.Level)
        self:UpdateCharacterExp(characterId, res.Exp)
        if callback then
            callback()
        end
    end)
end

function XSuperTowerRoleManager:RefreshTierRoleData(tierCharacterInfos)
    self:UpdateTierRoleHpLeftData(tierCharacterInfos)
end

function XSuperTowerRoleManager:ResetTierRoleData()
    self.TierRoleHpLeftDic = {}
end

-- sortTagType : XRoomCharFilterTipsConfigs.EnumSortTag
function XSuperTowerRoleManager:SortRoles(roles, sortTagType, isAscendOrder)
    if isAscendOrder == nil then isAscendOrder = self.IsAscendOrder end
    self.IsAscendOrder = not isAscendOrder
    if sortTagType == XRoomCharFilterTipsConfigs.EnumSortTag.Default then
        sortTagType = XRoomCharFilterTipsConfigs.EnumSortTag.Ability
    end
    local characterRoles = {}
    local characterIdDic = {}
    local robotRoles = {}
    for _, role in ipairs(roles) do
        if XEntityHelper.GetIsRobot(role:GetId()) then
            table.insert(robotRoles, role)
        else
            table.insert(characterRoles, role)
            characterIdDic[role:GetId()] = role
        end
    end
    table.sort(characterRoles, self.SortFunctionDic[sortTagType])
    table.sort(robotRoles, self.SortFunctionDic[sortTagType])
    local robotRole, sameCharacterRole
    for i = #robotRoles, 1, -1 do
        robotRole = robotRoles[i]
        sameCharacterRole = characterIdDic[robotRole:GetCharacterId()]
        -- 存在相同本地角色
        if sameCharacterRole ~= nil then
            -- 对比排序值，升序放在前面，降序放在后面
            if self:GetRoleSortValue(robotRole, sortTagType) >= self:GetRoleSortValue(sameCharacterRole, sortTagType) then
                local index = table.indexof(characterRoles, sameCharacterRole)
                table.insert(characterRoles, index, robotRole)
                table.remove(robotRoles, i)
            end
        end
    end
    return appendArray(characterRoles, robotRoles)
end

function XSuperTowerRoleManager:GetFilterJudge()
    return FilterJudge
end

--######################## 红点检查 ########################

function XSuperTowerRoleManager:CheckRoleShowRedDot(roleId)
    return self:CheckRolesSuperLevelUpShowRedDot(roleId) 
        or self:CheckRolePluginShowRedDot(roleId)
end

function XSuperTowerRoleManager:CheckRolesSuperLevelUpShowRedDot(roleId)
    local superTowerManager = XDataCenter.SuperTowerManager
    -- 活动没开启不处理
    if superTowerManager.GetIsEnd() then return false end
    -- 超限特权没开放，不需要显示
    if not superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.Transfinite) then
        return false
    end
    local roles
    if roleId == nil then
        roles = self:GetCanFightRoles()
    else
        roles = { self:GetRole(roleId) }
    end
    local bagManager = superTowerManager.GetBagManager()
    local star = XSuperTowerConfigs.GetClientBaseConfigByKey("RoleTransfiniteRedDotPluginStarLevel") or 0
    for _, role in ipairs(roles) do
        -- 未满级并有指定的插件材料，给红点提示
        if role:GetSuperLevel() < role:GetMaxSuperLevel() 
            and bagManager:CheckHasPluginWithStarFilter(star) then
            return true
        end
    end
    return false
end

function XSuperTowerRoleManager:CheckRolePluginShowRedDot(roleId)
    local superTowerManager = XDataCenter.SuperTowerManager
    -- 活动没开启不处理
    if superTowerManager.GetIsEnd() then return false end
    -- 专属槽权限没开启不需要处理
    if not superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.Exclusive) then
        return false
    end
    local roles
    if roleId == nil then
        roles = self:GetCanFightRoles()
    else
        roles = { self:GetRole(roleId) }
    end
    local bagManager = superTowerManager.GetBagManager()
    for _, role in ipairs(roles) do
        if not role:GetTransfinitePluginIsActive() and bagManager:GetIsHaveData(role:GetTransfinitePluginId()) then
            return true
        end
    end
    return false
end

function XSuperTowerRoleManager:CheckRoleInDultShowRedDot()
    local superTowerManager = XDataCenter.SuperTowerManager
    -- 活动没开启不处理
    if superTowerManager.GetIsEnd() then return false end
    -- 特典权限没开启不需要处理
    if not superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.BonusChara) then
        return false
    end
    local currentConfig = self.GetCurrentInDultConfig()
    -- 没有任何一个特典在开放时间内，不显示
    if currentConfig == nil then return false end
    local inDultHistoryId = self:GetInDultHistoryId()
    -- 没有记录说明没打开过，显示
    if inDultHistoryId == nil then return true end
    -- 历史打开的记录与最新开放的记录不相同，显示，相同则不显示
    return inDultHistoryId ~= currentConfig.Id
end

function XSuperTowerRoleManager:GetInDultHistoryId()
    if self.InDultHistoryId == nil then
        local superTowerManager = XDataCenter.SuperTowerManager
        self.InDultHistoryId = 
            XSaveTool.GetData("XSuperTowerRoleManager.InDultHistoryId" .. XPlayer.Id .. superTowerManager.GetActivityId())
    end
    return self.InDultHistoryId
end

function XSuperTowerRoleManager:SetInDultHistoryId(id)
    if id == nil then 
        local currentConfig = self.GetCurrentInDultConfig()
        if currentConfig == nil then return end
        id = currentConfig.Id
    end
    self.InDultHistoryId = id
    XSaveTool.SaveData("XSuperTowerRoleManager.InDultHistoryId" 
        .. XPlayer.Id .. XDataCenter.SuperTowerManager.GetActivityId(), self.InDultHistoryId)
end

--######################## 私有方法 ########################

-- sortTagType : XRoomCharFilterTipsConfigs.EnumSortTag
function XSuperTowerRoleManager:GetRoleSortValue(role, sortTagType)
    if sortTagType == XRoomCharFilterTipsConfigs.EnumSortTag.Default then
        sortTagType = XRoomCharFilterTipsConfigs.EnumSortTag.Ability
    end
    if sortTagType == XRoomCharFilterTipsConfigs.EnumSortTag.Ability then
        return role:GetAbility()
    elseif sortTagType == XRoomCharFilterTipsConfigs.EnumSortTag.SuperLevel then
        return role:GetSuperLevel()
    elseif sortTagType == XRoomCharFilterTipsConfigs.EnumSortTag.Quality then
        return role:GetCharacterViewModel():GetQuality()
    end
end

function XSuperTowerRoleManager:GenerateRoleData()
    local characters = XDataCenter.CharacterManager.GetOwnCharacterList()
    for _, character in ipairs(characters) do
        self:AddNewRole(character)
    end
    for _, robot in ipairs(self:GetCanFightRobots()) do
        self:AddNewRole(robot)
    end
end

-- roleData : XCharacter | XRobot
function XSuperTowerRoleManager:AddNewRole(roleData)
    -- 如果已经存在，直接不处理
    if self.RoleDic[roleData.Id] then return end
    local role = XSuperTowerRole.New(roleData)
    table.insert(self.Roles, role)
    self.RoleDic[role:GetId()] = role
end

function XSuperTowerRoleManager:GetCanFightRobots()
    local result = {}
    local config
    for id, v in pairs(self.GrantedRobotDic) do
        config = XSuperTowerConfigs.GetGrantRobotConfig(id)
        for _, robotId in ipairs(config.RobotId) do
            table.insert(result, XRobot.New(robotId))
        end
    end
    return result
end

function XSuperTowerRoleManager:CheckHasNewRobotGrant()
    local generateRobots = false
    local robotConfigs = XSuperTowerConfigs.GetGrantRobotConfigs()
    local nowTime = XTime.GetServerNowTimestamp()
    local startTime = 0
    local activityStartTime = XDataCenter.SuperTowerManager.GetActivityStartTime()
    local newGrantedRobotDic = {}
    local tmpGrantedRobotDic = {}
    -- 获取能够发送的配置表id
    for id, config in pairs(robotConfigs) do
        startTime = XUiHelper.GetTimeOfDelay(activityStartTime, config.OpenHour, XUiHelper.DelayType.Hour)
        if nowTime >= startTime then
            newGrantedRobotDic[id] = true
            tmpGrantedRobotDic[id] = true
        end
    end
    local newTableIsEmpty = XTool.IsTableEmpty(newGrantedRobotDic)
    local oldTableIsEmpty = XTool.IsTableEmpty(self.GrantedRobotDic)
    -- 都不为空，要对比一下数据是否有变化
    if not newTableIsEmpty and not oldTableIsEmpty then
        for id, _ in pairs(self.GrantedRobotDic) do
            if newGrantedRobotDic[id] then
                newGrantedRobotDic[id] = nil
                self.GrantedRobotDic[id] = nil
            end
        end
        -- 都是空表，说明一致，不需要重新生成
        if XTool.IsTableEmpty(newGrantedRobotDic) and XTool.IsTableEmpty(self.GrantedRobotDic) then
            generateRobots = false
        else
            generateRobots = true
        end
    else
        -- 如果都是空表，说明没有任何一个是可以发送的
        if oldTableIsEmpty and newTableIsEmpty then
            generateRobots = false
        -- 有新的发送
        elseif oldTableIsEmpty and not newTableIsEmpty then
            generateRobots = true
        -- 旧的发送都过期了
        elseif not oldTableIsEmpty and newTableIsEmpty then
            generateRobots = true
        end
    end
    self.GrantedRobotDic = tmpGrantedRobotDic
    return generateRobots
end

function XSuperTowerRoleManager:RegisterEvents()
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_ADD_SYNC, self.OnCharacterAdd, self)
end

function XSuperTowerRoleManager:OnCharacterAdd(character)
    if character == nil then return end
    if self.RoleDic[character.Id] then return end
    self:AddNewRole(character)
end

return XSuperTowerRoleManager