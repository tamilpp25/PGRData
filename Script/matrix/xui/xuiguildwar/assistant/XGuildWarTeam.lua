local XTeam = require("XEntity/XTeam/XTeam")
local XGuildWarMember = require("XUi/XUiGuildWar/Assistant/XGuildWarMember")

---@class XGuildWarTeam:XTeam@refer to XTeam and XStrongholdTeam
local XGuildWarTeam = XClass(XTeam, "XGuildWarTeam")

function XGuildWarTeam:Ctor(id)
    self.Id = id

    -- 刻意把entityId置空, 用到的地方就会报错, 方便重写
    self.EntitiyIds = nil

    ---@type XGuildWarMember[] @为了支持其他玩家支援的角色, 需要记录下playerId, 故使用member来代替entityId, 并在member中实现获取fashion,partner等方法
    self.Members = {}

    self:LoadTeamData()
end

function XGuildWarTeam:LoadTeamData()
    local initData = XSaveTool.GetData(self:GetSaveKey())
    if not initData then
        return
    end
    for key, value in pairs(initData) do
        self[key] = value
    end
    -- member
    self.Members = {}
    for pos, memberData in pairs(initData.Members or {}) do
        self:UpdateEntityTeamPos(memberData, pos, true)
    end
    
end

function XGuildWarTeam:UpdateEntityTeamPos(memberData, teamPos, isJoin)
    if isJoin then
        if self.Members[teamPos] then
            self:UpdateGenernalSkillsByMemberData(self.Members[teamPos], true, true)
            self.Members[teamPos]:SetData(memberData)
        else
            self.Members[teamPos] = XGuildWarMember.New(memberData)
        end
        if memberData then
            -- 踢除重复的角色
            for pos, member in pairs(self.Members) do
                if pos ~= teamPos and member:GetEntityId() == memberData.EntityId then
                    self:UpdateGenernalSkillsByMemberData(member, true, true)
                    self:UpdateEntityTeamPos(false, pos, false)
                end
            end
            
            -- 剔除另一个支援角色 (支援角色只能有一个)
            if memberData.PlayerId and memberData.PlayerId ~= XPlayer.Id and memberData.PlayerId > 0 then
                for pos, member in pairs(self.Members) do
                    if pos ~= teamPos and member:IsAssitant() then
                        XUiManager.TipText("StrongholdBorrowCountOver")
                        self:UpdateGenernalSkillsByMemberData(member, true, true)
                        self:UpdateEntityTeamPos(false, pos, false)
                    end
                end
            end

            self:UpdateGenernalSkillsByMemberData(memberData, false, true)

        end
    else
        if teamPos then
            self.Members[teamPos] = nil

        elseif memberData then
            for pos, memberInTeam in pairs(self.Members) do
                if memberInTeam:Equals(memberData) then
                    self.Members[pos] = nil
                    break
                end
            end
            self:UpdateGenernalSkillsByMemberData(memberData, true, true)
        end
    end
    self:Save()
end

function XGuildWarTeam:SwitchEntityPos(posA, posB)
    local memberA = self.Members[posA]
    local memberB = self.Members[posB]
    self.Members[posB] = memberA
    self.Members[posA] = memberB
    self:Save()
end

--region 数据获取
--获取所有成员
---@return XGuildWarMember[]
function XGuildWarTeam:GetMembers()
    return self.Members
end

---@return XGuildWarMember
function XGuildWarTeam:GetMember(pos)
    local member = self.Members[pos]
    return member
end

---@return XGuildWarMember
function XGuildWarTeam:GetMemberByEntityId(entityId)
    for pos, member in pairs(self.Members) do
        if entityId == member:GetEntityId() then
            return member
        end
    end
    return nil
end



function XGuildWarTeam:GetEntityIds()
    local entityIds = { 0, 0, 0 }
    for pos, member in pairs(self.Members) do
        entityIds[pos] = member:GetEntityId()
    end
    return entityIds
end

function XGuildWarTeam:GetEntityIdByTeamPos(pos)
    local member = self.Members[pos]
    return (member and member:GetEntityId()) or 0
end

function XGuildWarTeam:GetCaptainPosEntityId()
    local member = self:GetMember(self.CaptainPos)
    if member then
        return member:GetEntityId()
    end
    return 0
end

function XGuildWarTeam:GetFirstFightPosEntityId()
    local member = self:GetMember(self.FirstFightPos)
    if member then
        return member:GetEntityId()
    end
    return 0
end

function XGuildWarTeam:GetIsEmpty()
    return not next(self.Members)
end

function XGuildWarTeam:GetIsFullMember()
    return #self.Members == XFubenBabelTowerConfigs.MAX_TEAM_MEMBER
end

function XGuildWarTeam:Clear()
    XGuildWarTeam.Super.Clear()
    self.EntitiyIds = nil
    self.Members = {}
end

function XGuildWarTeam:ClearEntityIds()
    XGuildWarTeam.Super.ClearEntityIds()
    self.EntitiyIds = nil
    self.Members = {}
end

function XGuildWarTeam:_Save()
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
                CaptainPos = self.CaptainPos,
                SelectedGeneralSkill = self.SelectedGeneralSkill
            }
        )
    end
    if self.SaveCallback then
        self.SaveCallback(self)
    end
end

--获得队伍总战力
function XGuildWarTeam:GetAbility()
    local addAbility = 0
    for pos, member in pairs(self.Members) do
        addAbility = addAbility + member:GetAbility()
    end
    return addAbility
end

function XGuildWarTeam:GetEntityIdIsInTeam(entityId)
    for pos, member in pairs(self.Members) do
        if member:GetEntityId() == entityId then
            return true, pos
        end
    end
    return false, -1
end

--剔除已经失效的援助角色
function XGuildWarTeam:KickOutInvalidMembers()
    for pos, member in pairs(self.Members) do
        if not member:CheckValid() then
            self:UpdateEntityTeamPos(false, pos, false)
        end
    end
end

function XGuildWarTeam:CheckHasSameMember(memberData, pos)
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

function XGuildWarTeam:GoPartnerCarry(pos)
    local member = self.Members[pos]
    if member:IsMyCharacter() then
        XDataCenter.PartnerManager.GoPartnerCarry(member:GetEntityId(), false)
    end
end

function XGuildWarTeam:KickOut(entityId)
    for pos, member in pairs(self.Members) do
        if member:GetEntityId() == entityId then
            self:UpdateGenernalSkillsByMemberData(member, true, true)
            self:UpdateEntityTeamPos(false, pos, false)
            break
        end
    end
end

function XGuildWarTeam:GetTeamInfo()
    local characterInfo = {}
    for i = 1, 3 do
        local member = self.Members[i]
        if member then
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
    return {
        CaptainPos = self.CaptainPos,
        FirstFightPos = self.FirstFightPos,
        CharacterInfos = characterInfo
    }
end

-- 转换回旧队伍数据，为了兼容旧系统
function XGuildWarTeam:SwithToOldTeamData()
    local teamData = { 0, 0, 0 }
    for pos, member in pairs(self.Members or {}) do
        teamData[pos] = member:GetEntityId()
    end
    return {
        TeamData = teamData,
        CaptainPos = self.CaptainPos,
        FirstFightPos = self.FirstFightPos,
        TeamId = self.Id,
        SelectedGeneralSkill = self.SelectedGeneralSkill,
    }
end

-- teamData : 旧系统的队伍数据
function XGuildWarTeam:UpdateFromTeamData(teamData)
    self.FirstFightPos = teamData.FirstFightPos
    self.CaptainPos = teamData.CaptainPos
    for pos, characterId in ipairs(teamData.TeamData) do
        if characterId > 0 and XMVCA.XCharacter:IsOwnCharacter(characterId) then
            self:UpdateEntityTeamPos({ EntityId = characterId, PlayerId = XPlayer.Id }, pos, true)
        end
    end
    self.TeamName = teamData.TeamName
    self.SelectedGeneralSkill = teamData.SelectedGeneralSkill
    self:RefreshGeneralSkills(true)
    self:Save()
end

--region 角色效应相关

-- 技能汇总表仅加载时缓存，不会存储到本地。在该重写版本中参数是memberData
---@param autoSave @传递参数控制是否保存效应选择（如果发生成员变动，成员变动本身会触发一次保存）
function XGuildWarTeam:UpdateGenernalSkillsByMemberData(memberData, isRemove, noAutoSave)
    if XTool.IsTableEmpty(memberData) then
        return
    end
    
    if memberData.PlayerId == XPlayer.Id then
        -- 自机还是按照父类的方式处理
        return self:UpdateGenernalSkillsByEntityId(memberData.EntityId, isRemove, noAutoSave)
    else
        -- 其他角色的Id需要特殊处理
        local skillIds = nil
        local npcData = XDataCenter.GuildWarManager.GetAssistantCharacterData(memberData.EntityId, memberData.PlayerId)
        if not XTool.IsTableEmpty(npcData) then
            skillIds = XMVCA.XCharacter:GetCharacterActiveGeneralSkillIdListFromNpcFightData(npcData.FightNpcData)
        end

        if not XTool.IsTableEmpty(skillIds) then
            self:SetGeneralSkills(memberData.EntityId, skillIds, isRemove, noAutoSave)
        end
    end
end

---@overload
---@param keepOldData @是否需要保持旧数据，如果没有发生成员变动，这时可能是需要检查成员新解锁的效应，数据只增不减，可以选择不清空数据
function XGuildWarTeam:RefreshGeneralSkills(autoSelect, keepOldData)
    -- 刷新需要保证已经选择的效应不被重置（还存在的情况下）
    local lastSelectGeneralSkill = self.SelectedGeneralSkill or 0
    self:UpdateGenernalSkillsByMemberDatas(self.Members, keepOldData)
    -- 判断刷新过后，当前队伍的效应技能里还有没有之前选择的
    local hasLastSelecedGeneralSkill = false
    if not XTool.IsTableEmpty(self._GenernalSkills) then
        for generalSkillId, linkCharaList in pairs(self._GenernalSkills) do
            if generalSkillId == lastSelectGeneralSkill then
                hasLastSelecedGeneralSkill = true
                break
            end
        end
    end

    if hasLastSelecedGeneralSkill then
        self.SelectedGeneralSkill = lastSelectGeneralSkill
    end

    if not XTool.IsNumberValid(self.SelectedGeneralSkill) and autoSelect then
        self:AutoSelectGeneralSkill()
    end
end

--- 刷新队伍的效应技能
function XGuildWarTeam:UpdateGenernalSkillsByMemberDatas(memberDatas, keepOldData)
    if XTool.IsTableEmpty(memberDatas) then
        return
    end

    if not keepOldData then
        self:ClearGeneralSkill()
    end

    for index, value in ipairs(memberDatas) do
        self:UpdateGenernalSkillsByMemberData(value)
    end
end
--endregion

function XGuildWarTeam:GetObservationActiveCareer()
    -- 该派生类结构不一样，先重载方法防止报错
    return 0, 0
end

return XGuildWarTeam
