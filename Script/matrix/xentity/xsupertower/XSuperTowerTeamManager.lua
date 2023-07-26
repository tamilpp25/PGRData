local XSuperTowerPluginSlotManager = require("XEntity/XSuperTower/XSuperTowerPluginSlotManager")
local XTeam = require("XEntity/XTeam/XTeam")
local XSuperTowerTeamManager = XClass(nil, "XSuperTowerTeamManager")

function XSuperTowerTeamManager:Ctor()
    -- key : id, value : XTeam
    self.TeamDic = nil
    self.TeamDic = {}
end

local CreateRealTeamId = function(teamId, index)
    return string.format("%sSuperTower%s_%s_%s",XPlayer.Id, XDataCenter.SuperTowerManager.GetActivityId(), teamId, index or 1)
end

function XSuperTowerTeamManager:GetTeamById(teamId, index)--单队伍类型时不需要设置关卡序号（有且仅有1），默认为1
    local teamId = CreateRealTeamId(teamId, index)
    local result = self.TeamDic[teamId]
    if not result then
        result = XTeam.New(teamId)
        result:UpdateExtraData(XSuperTowerPluginSlotManager.New())
        --result:UpdateSaveCallback(function(team)
            --self:HandleTeamSaveCallback(team)
        --end)
        self.TeamDic[teamId] = result
    end
    return result
end

function XSuperTowerTeamManager:ClearTeam(teamId, index)--单队伍类型时不需要设置关卡序号（有且仅有1），默认为1
    local teamId = CreateRealTeamId(teamId, index)
    local team = self.TeamDic[teamId]
    if team then
        team:Clear()
    end
end
--[[
    teamId：队伍类型ID（XSuperTowerManager.TeamId）
    teamCount：本关队伍数量
    entityId：成员ID
    检查某个成员是否在队伍/其他队伍中，返回队伍编号,如果没有在任何队伍则返回0
]]
function XSuperTowerTeamManager:CheckMemberIsInTeam(teamId, teamCount, entityId)
    for index = 1, teamCount do
        local teamId = CreateRealTeamId(teamId, index)
        if teamId then
            local team = self.TeamDic[teamId]
            local entityList = team and team:GetEntityIds() or {}
            for _,id in pairs(entityList) do
                if id == entityId then
                    return index, team
                end
            end
        end
    end
    return 0
end

function XSuperTowerTeamManager:GetTeamsByIdAndCount(teamId, teamCount)
    local result = {}
    for index = 1, teamCount do
        local teamId = CreateRealTeamId(teamId, index)
        if teamId then
            local team = self.TeamDic[teamId]
            if team then
                table.insert(result, team)
            end
        end
    end
    return result
end

--[[
    没有任何插件，给提示
    有插件，但不是合适的插件，并且当前是空状态，给提示
    有插件，但不是合适的插件，不是空状态，不给提示
]]
-- return : 是否一键上阵了插件，true为有上阵，false为无上阵
function XSuperTowerTeamManager:AutoSelectPlugins2Teams(teams)
    local plugins = XDataCenter.SuperTowerManager.GetBagManager():GetPlugins()
    if not plugins or not next(plugins) then
        XUiManager.TipText("STNoPlugin")
        return false
    end 
    -- 所有队伍的插件状态是否都是空的
    local isEmptyStatus = true
    -- 队伍已经使用的插件
    local usedPluginDic = {}
    local teamPlugins, pluginId
    -- 将队伍正在使用的插件拿出来
    for _, team in ipairs(teams) do
        teamPlugins = team:GetExtraData():GetPlugins(true)
        for _, plugin in ipairs(teamPlugins) do
            if plugin ~= 0 then
                pluginId = plugin:GetId()
                usedPluginDic[pluginId] = usedPluginDic[pluginId] or 0
                usedPluginDic[pluginId] = usedPluginDic[pluginId] + 1
                isEmptyStatus = false
            end
        end
    end
    local plugin
    -- 和背包作比较，拿剩下的做自动选择
    for i = #plugins, 1, -1 do
        plugin = plugins[i]
        pluginId = plugin:GetId()
        if usedPluginDic[pluginId] ~= nil and usedPluginDic[pluginId] > 0 then
            table.remove(plugins, i)
            usedPluginDic[pluginId] = usedPluginDic[pluginId] - 1
        end
    end
    local oldCount = #plugins
    if oldCount <= 0 then return false end
    for _, team in ipairs(teams) do
        plugins = self:AutoSelectPlugins2Team(team, plugins)
    end
    if isEmptyStatus and oldCount == #plugins then
        XUiManager.TipText("STNoPlugin")
        return false
    end
    return true
end

--######################## 私有方法 ########################

-- team : XTeam
function XSuperTowerTeamManager:SetTargetFightTeam(teamList, stageId, callback)
    local teamInfos = {}
    for teamIndex,team in pairs(teamList or {}) do
        local pluginSlotManager = team:GetExtraData()

        -- 消耗的插件数据
        local pluginInfos = {}
        for _, plugin in pairs(pluginSlotManager:GetPluginsNotSplit()) do
            table.insert(pluginInfos, {
                    Id = plugin:GetId(),
                    Count = plugin:GetCount()
                })
        end
        -- 成员数据
        local characterInfos = {}
        for index, entityId in ipairs(team:GetEntityIds()) do
            characterInfos[index] = {}
            local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
            local role = roleManager:GetRole(entityId)
            if not role then
                characterInfos[index].Id = 0
                characterInfos[index].RobotId = 0
            elseif role:GetIsRobot() then
                characterInfos[index].Id = role:GetCharacterId()
                characterInfos[index].RobotId = entityId
            else
                characterInfos[index].Id = entityId
                characterInfos[index].RobotId = 0
            end
        end
        
        teamInfos[teamIndex] = {}
        teamInfos[teamIndex].Id = teamIndex
        teamInfos[teamIndex].CaptainPos = team:GetCaptainPos()
        teamInfos[teamIndex].FirstPos = team:GetFirstFightPos()
        teamInfos[teamIndex].PluginInfos = pluginInfos
        teamInfos[teamIndex].CharacterInfos = characterInfos
    end
    
    self:RequestSetTargetFightTeam(stageId, teamInfos, callback)
end

-- StTargetFightTeamInfo array
-- { Id, CaptainPos, FirstPos }
function XSuperTowerTeamManager:RequestSetTargetFightTeam(stageId, teamInfos, callback)
    if not stageId then return end
    local requestData = {
        TargetId = XDataCenter.SuperTowerManager.GetTargetStageIdByStageId(stageId),
        TeamInfos = teamInfos
    }
    
    XNetwork.Call("StSetTargetFightTeamRequest", requestData, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then callback() end
    end)
end

-- team : XTeam
function XSuperTowerTeamManager:AutoSelectPlugins2Team(team, plugins)
    if plugins == nil then plugins = XDataCenter.SuperTowerManager.GetBagManager():GetPlugins() end
    local characterContainValueDic = {}
    local entityIds = team:GetEntityIds()
    local characterId
    local teamCharacterIdDic = {}
    for pos, entityId in ipairs(entityIds) do
        if entityId ~= 0 then
            characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
            -- 位置越前权重越大
            characterContainValueDic[characterId] = 10 - pos
            teamCharacterIdDic[characterId] = true
        end
    end
    table.sort(plugins, function(pluginA, pluginB)
        local containValueA = characterContainValueDic[pluginA:GetCharacterId()]
        local containValueB = characterContainValueDic[pluginB:GetCharacterId()]
        -- 根据位置设置插件权重
        local characterWeightA = containValueA and containValueA * 1000000000 or 0
        local characterWeightB = containValueB and containValueB * 1000000000 or 0
        local sortWeightA = pluginA:GetId() + pluginA:GetQuality() * 100000000 + characterWeightA + pluginA:GetPriority()
        local sortWeightB = pluginB:GetId() + pluginB:GetQuality() * 100000000 + characterWeightB + pluginB:GetPriority()
        return sortWeightA < sortWeightB
    end)
    local pluginSlotManager = team:GetExtraData()
    local maxCapacity = pluginSlotManager:GetMaxCapacity()
    local plugin, pluginCharacterId
    for i = #plugins, 1, -1 do
        plugin = plugins[i]
        -- 如果插件是角色专属插件，同时又是不属于本队伍角色，一律不上
        pluginCharacterId = plugin:GetCharacterId()
        -- 属于通用插件、插件专属角色id是否在队伍里和排除掉所有角色专属槽插件
        if not XSuperTowerConfigs.GetPluginIdIsCharacterSlot(plugin:GetId()) 
            and (pluginCharacterId <= 0 or teamCharacterIdDic[pluginCharacterId]) then
            pluginSlotManager:AddPlugin(plugin)
            table.remove(plugins, i)
            if pluginSlotManager:GetCurrentCapacity() >= maxCapacity then
                break
            end
        end
    end
    return plugins
end

return XSuperTowerTeamManager