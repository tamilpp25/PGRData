local XTeam = require("XEntity/XTeam/XTeam")
local XGuildWarMember = require("XUi/XUiGuildWar/Assistant/XGuildWarMember")

---@class XGuildWarAreaTeam:XTeam@refer to XTeam and XStrongholdTeam
local XGuildWarAreaTeam = XClass(XTeam, "XGuildWarAreaTeam")
function XGuildWarAreaTeam:Ctor(cacheId)
    self.Id = cacheId
    -- 刻意把entityId置空, 用到的地方就会报错, 方便重写
    self.EntitiyIds = nil
    ---@type XGuildWarMember[] @为了支持其他玩家支援的角色, 需要记录下playerId, 故使用member来代替entityId, 并在member中实现获取fashion,partner等方法
    --memberData = {
    --    EntityId
    --    PlayerId
    --}
    self.Members = {}
    --是否固定队伍数据
    self.DataType = XGuildWarConfig.AreaTeamDataType.Uninit
end

-- 设置队伍人数
function XGuildWarAreaTeam:SetMemberNumber(memberNumber)
    local member = {}
    for pos=1, memberNumber do
        if self.Members[pos] then
            member[pos] = self.Members[pos]
        else
            member[pos] = XGuildWarMember.New()
        end
    end
    self.Members = member
end

-- 清空队伍
function XGuildWarAreaTeam:CleanUpMembers()
    for pos, member in pairs(self.Members or {}) do
        member:SetEmpty()
    end
end

-- 加载缓存数据(当前关卡没被锁定时读取)
function XGuildWarAreaTeam:LoadTeamByCache()
    self:CleanUpMembers()
    local initData = XSaveTool.GetData(self:GetSaveKey())
    if not initData then
        self.DataType = XGuildWarConfig.AreaTeamDataType.Custom
        return
    end
    self.CaptainPos = initData.CaptainPos
    self.FirstFightPos = initData.FirstFightPos
    -- 更新成员数据
    for pos, memberData in pairs(initData.Members or {}) do
        if self.Members[pos] then
            self.Members[pos]:SetData(memberData)
        else
            self.Members[pos] = XGuildWarMember.New(memberData)
        end
    end
    self.DataType = XGuildWarConfig.AreaTeamDataType.Custom
end

--加载固定数据(当前关卡被锁定时读取)
-- CharacterInfos:XGuildWarTeamCharacterInfo(C#)
function XGuildWarAreaTeam:LoadTeamByData(characterInfos)
    self:CleanUpMembers()
    for index, XGuildWarTeamCharacterInfo in pairs(characterInfos or {}) do
        local memberData = {
            EntityId = XGuildWarTeamCharacterInfo.Id,
            PlayerId = XGuildWarTeamCharacterInfo.PlayerId
        }
        local pos = XGuildWarTeamCharacterInfo.Pos
        if self.Members[pos] then
            self.Members[pos]:SetData(memberData)
        else
            self.Members[pos] = XGuildWarMember.New(memberData)
        end
    end
    self.DataType = XGuildWarConfig.AreaTeamDataType.Locked
end

--!!!仅限!!!快速组队界面使用(XUiGuildWarDeployPanelFormation)
function XGuildWarAreaTeam:SetMembers(members)
    self.Members = members
end

--设置角色成员
--由Build调用，设置角色时只检查本队伍的队伍限制，Build的限制由Build自己处理。
--memberData 修改成员数据
--teamPos 修改队伍位置
--isJoin 是否增加或修改队伍 false的话则是移除成员
function XGuildWarAreaTeam:SetUpEntity(memberData, teamPos, isJoin)
    if not (self.DataType == XGuildWarConfig.AreaTeamDataType.Custom) then return false end
    if isJoin then
        if self.Members[teamPos] then
            self.Members[teamPos]:SetData(memberData)
        else
            self.Members[teamPos] = XGuildWarMember.New(memberData)
        end
        if memberData then
            -- 踢除重复的角色
            for pos, member in pairs(self.Members) do
                if pos ~= teamPos and member:GetEntityId() == memberData.EntityId then
                    self:UpdateEntityTeamPos(false, pos, false)
                end
            end
            -- 剔除另一个支援角色 (支援角色只能有一个)
            if memberData.PlayerId and memberData.PlayerId ~= XPlayer.Id and memberData.PlayerId > 0 then
                for pos, member in pairs(self.Members) do
                    if pos ~= teamPos and member:IsAssitant() then
                        XUiManager.TipText("StrongholdBorrowCountOver")
                        self:UpdateEntityTeamPos(false, pos, false)
                    end
                end
            end
        end
    else
        if teamPos then
            self.Members[teamPos]:SetEmpty()
        elseif memberData then
            for pos, memberInTeam in pairs(self.Members) do
                if memberInTeam:Equals(memberData) then
                    self.Members[pos]:SetEmpty()
                    goto SET_UP_SUCCESS
                end
            end
            return false
        end
    end
    :: SET_UP_SUCCESS ::
    self:Save()
    return true
end

--region 数据操作
--交换角色成员位置
function XGuildWarAreaTeam:SwitchEntityPos(posA, posB)
    if not (self.DataType == XGuildWarConfig.AreaTeamDataType.Custom) then return false end
    local memberA = self.Members[posA]
    local memberB = self.Members[posB]
    self.Members[posB] = memberA
    self.Members[posA] = memberB
    self:Save()
    return true
end

--剔除指定角色
function XGuildWarAreaTeam:KickOut(entityId)
    for pos, member in pairs(self.Members) do
        if member:GetEntityId() == entityId then
            self:SetUpEntity(false, pos, false)
            break
        end
    end
end

--清空指定位置
function XGuildWarAreaTeam:KickOutPos(pos)
    return self:SetUpEntity(false, pos, false)
end

--检查角色有效性 并纠正
function XGuildWarAreaTeam:CheckAndFixedTeamMember()
    if not (self.DataType == XGuildWarConfig.AreaTeamDataType.Custom) then return false end
    --检查重复角色 和 多支援角色
    local entityIdHashSet = {}
    local hasAssistant = false
    for pos, member in pairs(self.Members) do
        if not member then goto CONTINUE end
        --检查重复角色
        if entityIdHashSet[member.EntityId] then
            self:SetUpEntity(false, pos, false)
        else
            entityIdHashSet[member.EntityId] = true
        end
        --检查多支援角色
        if member:IsAssitant() then
            --检查支援角色可用性
            if not member:CheckValid() then
                self:SetUpEntity(false, pos, false)
                goto CONTINUE
            end
            if hasAssistant then
                self:SetUpEntity(false, pos, false)
            else
                hasAssistant = true
            end
        end
        :: CONTINUE ::
    end
    self:_Save()
end

--存储队伍数据
function XGuildWarAreaTeam:_Save()
    --锁定的队伍不写入缓存
    if not (self.DataType == XGuildWarConfig.AreaTeamDataType.Custom) then return false end
    if self.LocalSave then
        local membersData = {}
        for pos, member in pairs(self.Members) do
            membersData[pos] = member:GetData()
        end

        -- 默认本地缓存，后面可扩展使用原本的服务器保存方式
        XSaveTool.SaveData(
                self:GetSaveKey(),
                {
                    Id = self.Id,
                    Members = membersData,
                    FirstFightPos = self.FirstFightPos,
                    CaptainPos = self.CaptainPos
                }
        )
    end
    if self.SaveCallback then
        self.SaveCallback(self)
    end
end

--剔除已经失效的援助角色
function XGuildWarAreaTeam:KickOutInvalidMembers()
    for pos, member in pairs(self.Members) do
        if not member:CheckValid() then
            self:UpdateEntityTeamPos(false, pos, false)
        end
    end
end
--endregion

--region 数据获取
--获取所有成员
---@return XGuildWarMember[]
function XGuildWarAreaTeam:GetMembers()
    return self.Members
end
--获取单个成员
---@return XGuildWarMember
function XGuildWarAreaTeam:GetMember(pos)
    return self.Members[pos]
end

---@return XGuildWarMember
function XGuildWarAreaTeam:GetMemberByEntityId(entityId)
    for pos, member in pairs(self.Members) do
        if entityId == member:GetEntityId() then
            return member
        end
    end
    return nil
end

--获取所有成员ID
function XGuildWarAreaTeam:GetEntityIds()
    local entityIds = { 0, 0, 0 }
    for pos, member in pairs(self.Members) do
        entityIds[pos] = member:GetEntityId()
    end
    return entityIds
end

--获取某位置成员ID
function XGuildWarAreaTeam:GetEntityIdByTeamPos(pos)
    local member = self.Members[pos]
    return (member and member:GetEntityId()) or 0
end

--获取队长ID
function XGuildWarAreaTeam:GetCaptainPosEntityId()
    local member = self:GetEntityIdByTeamPos(self.CaptainPos)
    if member then
        return member:GetEntityId()
    end
    return 0
end

--获取队长技能描述
function XGuildWarAreaTeam:GetCaptainSkillDesc()
    if not self:CheckHasCaptain() then return "" end
    local captainMember = self:GetMember(self.CaptainPos)
    return captainMember and captainMember:GetCaptainSkillDesc() or ""
end

--获得首战位成员ID
function XGuildWarAreaTeam:GetFirstFightPosEntityId()
    local member = self:GetEntityIdByTeamPos(self.FirstFightPos)
    if member then
        return member:GetEntityId()
    end
    return 0
end

--是否空队伍
function XGuildWarAreaTeam:GetIsEmpty()
    return not next(self.Members)
end

--队伍是否满员
function XGuildWarAreaTeam:GetIsFullMember()
    return #self.Members == 3
end

--获取队伍是否可编辑
function XGuildWarAreaTeam:GetTeamIsCustom()
    return self.DataType == XGuildWarConfig.AreaTeamDataType.Custom
end

--获得队伍总战力
function XGuildWarAreaTeam:GetAbility()
    local addAbility = 0
    for pos, member in pairs(self.Members) do
        addAbility = addAbility + member:GetAbility()
    end
    return addAbility
end

--检查位置是否空缺
function XGuildWarAreaTeam:CheckPosEmpty(pos)
    local member = self:GetMember(pos)
    return member:IsEmpty()
end

--查询是否有队长
function XGuildWarAreaTeam:CheckHasCaptain()
    return not self:CheckPosEmpty(self.CaptainPos)
end

--查询是否有首战队员
function XGuildWarAreaTeam:CheckHasFirstPos()
    return not self:CheckPosEmpty(self.self.FirstFightPos)
end

--查询是否存在同样的成员
function XGuildWarAreaTeam:CheckHasSameMember(memberData, pos)
    if pos then
        local member = self.Members[pos]
        return member and member:Equals(memberData)
    end
    for pos, member in pairs(self.Members) do
        if member:Equals(memberData) then
            return true
        end
    end
    return false
end

--获取某个角色是否在队伍
function XGuildWarAreaTeam:GetEntityIdIsInTeam(entityId)
    for pos, member in pairs(self.Members) do
        if member:GetEntityId() == entityId then
            return true, pos
        end
    end
    return false, -1
end

--获取是否有助战角色
function XGuildWarAreaTeam:GetHasAssistant()
    for pos, member in pairs(self.Members) do
        if member:IsAssitant() then
            return true
        end
    end
    return false
end

--转换成服务器需要的数据
--return XGuildWarTeamCharacterInfo[](C#)
function XGuildWarAreaTeam:GetXGuildWarTeamCharacterInfos()
    local characterInfo = {}
    for i = 1, 3 do
        local member = self.Members[i]
        if member and member:GetEntityId() and (member:GetEntityId() > 0) then
            local playerId = member:GetPlayerId() or 0
            characterInfo[i] = {
                Id = member:GetEntityId() or 0,
                PlayerId = playerId,
                RobotId = 0,
                Pos = i
            }
        else
            characterInfo[i] = {
                Id = 0,
                PlayerId = XPlayer.Id,
                RobotId = 0,
                Pos = i
            }
        end
    end
    return characterInfo
end

--转换成出战数据
function XGuildWarAreaTeam:GetXFightTeamData()
    local data = {
        CaptainPos = self.CaptainPos,
        FirstFightPos = self.FirstFightPos,
        CharacterInfos = self:GetXGuildWarTeamCharacterInfos()
    }
    if not next(data.CharacterInfos) then
        data.CaptainPos = 0
        data.FirstFightPos = 0
    end
    return data
end
--endregion

--跳转到携带宠物
function XGuildWarAreaTeam:GoPartnerCarry(pos)
    local member = self.Members[pos]
    if member:IsMyCharacter() then
        XDataCenter.PartnerManager.GoPartnerCarry(member:GetEntityId(), false)
    end
end

--region 清理数据
function XGuildWarAreaTeam:Clear()
    XGuildWarAreaTeam.Super.Clear()
    self.EntitiyIds = nil
    self.Members = {}
end
function XGuildWarAreaTeam:ClearEntityIds()
    XGuildWarAreaTeam.Super.ClearEntityIds()
    self.EntitiyIds = nil
    self.Members = {}
end
--endregion
--region 旧系统兼容
-- 转换回旧队伍数据，为了兼容旧系统
function XGuildWarAreaTeam:SwithToOldTeamData()
    local teamData = { 0, 0, 0 }
    for pos, member in pairs(self.Members or {}) do
        teamData[pos] = member:GetEntityId()
    end
    return {
        TeamData = teamData,
        CaptainPos = self.CaptainPos,
        FirstFightPos = self.FirstFightPos,
        TeamId = self.Id
    }
end

-- teamData : 旧系统的队伍数据
function XGuildWarAreaTeam:UpdateFromTeamData(teamData)
    self.FirstFightPos = teamData.FirstFightPos
    self.CaptainPos = teamData.CaptainPos
    for pos, characterId in ipairs(teamData.TeamData) do
        if characterId > 0 and XMVCA.XCharacter:IsOwnCharacter(characterId) then
            self:UpdateEntityTeamPos({ EntityId = characterId, PlayerId = XPlayer.Id }, pos, true)
        end
    end
    self.TeamName = teamData.TeamName
    self:Save()
end
--endregion
return XGuildWarAreaTeam
