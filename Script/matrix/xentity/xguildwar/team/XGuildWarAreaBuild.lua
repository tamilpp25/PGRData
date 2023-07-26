local XGuildWarMember = require("XUi/XUiGuildWar/Assistant/XGuildWarMember")

---@class XGuildWarAreaBuild
local XGuildWarAreaBuild = XClass(nil, "XGuildWarAreaBuild")
--多队伍攻略区域 队伍构建数据 包含多个子队伍(不限数量)
function XGuildWarAreaBuild:Ctor(xTeams)
    --多队伍攻略区域节点
    ---@type XGuildWarAreaTeam[]
    self.XTeams = xTeams
    --最大支援人数
    self.MaxAssistantNum = 2
end

--获取队伍数量
function XGuildWarAreaBuild:GetTeamNumber()
    return #self.XTeams
end

--获取所有XTeam
---@return XGuildWarAreaTeam[]
function XGuildWarAreaBuild:GetXTeams()
    return self.XTeams
end

--获取XTeam
--childIndex 子节点的索引
---@return XGuildWarAreaTeam
function XGuildWarAreaBuild:GetXTeam(childIndex)
    return self.XTeams[childIndex]
end

--获取队伍的索引
function XGuildWarAreaBuild:GetXTeamIndex(xTeam)
    for index, team in pairs(self.XTeams) do
        if team == xTeam then
            return index
        end
    end
    return 0
end

-- 获取角色所在队伍
-- 不传playerId时不区分援助角色
function XGuildWarAreaBuild:GetMemberTeamIndex(entityId, playerId)
    for teamIndex, team in pairs(self.XTeams) do
        for memberIndex, member in pairs(team:GetMembers()) do
            if entityId == member:GetEntityId() then
                if not playerId then
                    return teamIndex, member
                end
                if playerId == member:GetPlayerId() then
                    return teamIndex, member
                end
            end
        end
    end
    return nil
end

--设置角色成员
--由Build调用，设置角色时只检查本队伍的队伍限制，Build的限制由Build自己处理。
--memberData 修改成员数据
--teamPos 修改队伍位置
--forceChange 是否强行替换
function XGuildWarAreaBuild:SetUpEntity(teamIndex, memberData, teamPos, forceChange)
    if not self.XTeams[teamIndex] then 
        return false 
    end
    if not (self.XTeams[teamIndex].DataType == XGuildWarConfig.AreaTeamDataType.Custom) then 
        return false 
    end
    --判断加入的是否支援角色
    local IsAssitant = not (memberData.PlayerId == XPlayer.Id)
    --记录每位存在的角色
    local entityIdHashSet = {}
    --记录可变更角色的位置 Key:EntityId Value:{teamPos,memberPos}
    local unlockEntityTeamPos = {}
    --记录支援角色数量
    local hasAssistant = 0
    --记录可变更支援角色的位置 Value[]:{teamPos,memberPos}
    local unlockAssistantTeamPos = {}
    --记录数据
    for index,team in ipairs(self.XTeams) do
        for pos, member in pairs(team.Members) do
            entityIdHashSet[member.EntityId] = true
            if IsAssitant and member:IsAssitant() then
                hasAssistant = hasAssistant + 1
            end
            if team.DataType == XGuildWarConfig.AreaTeamDataType.Custom then
                unlockEntityTeamPos[member.EntityId] = {index, pos}
                if IsAssitant and member:IsAssitant() then
                    table.insert(unlockAssistantTeamPos,{index, pos})
                end
            end
        end
    end
    --如果有重复的角色 并都被锁定
    if entityIdHashSet[memberData.EntityId] and not unlockEntityTeamPos[memberData.EntityId] then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildWarTeamAreaMemberLocked"))
        return false
    end
    --如果可以使用的支援角色已经超过上限 并且都被锁定
    if IsAssitant and hasAssistant >= self.MaxAssistantNum and not next(unlockAssistantTeamPos) then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildWarTeamAreaMemberLocked"))
        return false
    end
    --踢除重复的角色
    if entityIdHashSet[memberData.EntityId] then
        if not forceChange then
            return false, CS.XTextManager.GetText("GuildWarTeamAreaSelfMemberChange", unlockEntityTeamPos[memberData.EntityId][1])
        end
        local kickMemberPosData = unlockEntityTeamPos[memberData.EntityId]
        local kickMember = self:GetXTeam(kickMemberPosData[1]):GetMember(kickMemberPosData[2])
        if IsAssitant and kickMember:IsAssitant() then
            hasAssistant = hasAssistant - 1
        end
        self:KickOutPos(kickMemberPosData[1],kickMemberPosData[2])
    end
    --踢除超出的支援角色
    if IsAssitant and hasAssistant >= self.MaxAssistantNum then
        --优先踢出同队成员
        table.sort(unlockAssistantTeamPos, function(a, b)
            if a[1] == teamIndex then
                return true
            end
            return a[1] < b[1]
        end)
        if not forceChange then
            return false, CS.XTextManager.GetText("GuildWarTeamAreaAssitantMemberChange", unlockAssistantTeamPos[1][1])
        end
        local kickMemberPosData = unlockAssistantTeamPos[1]
        local kickMember = self:GetXTeam(kickMemberPosData[1]):GetMember(kickMemberPosData[2])
        self:KickOutPos(kickMemberPosData[1],kickMemberPosData[2])
    end
    
    return self:GetXTeam(teamIndex):SetUpEntity(memberData, teamPos, true, forceChange)
end

--剔除指定角色
function XGuildWarAreaBuild:KickOut(teamIndex, entityId)
    self:GetXTeam(teamIndex):KickOut(entityId)
    return true
end

--剔除指定位置角色
function XGuildWarAreaBuild:KickOutPos(teamIndex, pos)
    return self:GetXTeam(teamIndex):KickOutPos(pos)
end

--检查队伍合法性 并修正
function XGuildWarAreaBuild:CheckAndFixedBuildMember()
    --每支队伍自我修正
    for index,team in ipairs(self.XTeams) do
        team:CheckAndFixedTeamMember()
    end
    --记录每位存在的角色
    local entityIdHashSet = {}
    --记录支援角色数量
    local hasAssistant = 0
    --先记录已经锁定的队伍 已经锁定的队伍无法修改
    for index,team in ipairs(self.XTeams) do
        if team.DataType == XGuildWarConfig.AreaTeamDataType.Locked then
            for pos, member in pairs(team.Members) do
                entityIdHashSet[member.EntityId] = true
                if member:IsAssitant() then
                    hasAssistant = hasAssistant + 1
                end
            end
        end
    end
    --检查自定义队伍并修正
    for index,team in ipairs(self.XTeams) do
        if team.DataType == XGuildWarConfig.AreaTeamDataType.Custom then
            for pos, member in pairs(team.Members) do
                --检查重复角色
                if entityIdHashSet[member.EntityId] then
                    team:KickOutPos(pos)
                else --修正
                    entityIdHashSet[member.EntityId] = true
                end
                --检查多支援角色
                if member:IsAssitant() then
                    if hasAssistant >= self.MaxAssistantNum then
                        team:KickOutPos(pos)
                    else
                        hasAssistant = hasAssistant + 1
                    end
                end
            end
        end
    end
end

return XGuildWarAreaBuild
