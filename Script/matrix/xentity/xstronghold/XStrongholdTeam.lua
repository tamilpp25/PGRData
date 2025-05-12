local XStrongholdTeamMember = require("XEntity/XStronghold/XStrongholdTeamMember")
local XStrongholdPlugin = require("XEntity/XStronghold/XStrongholdPlugin")

local type = type
local pairs = pairs
local ipairs = ipairs
local IsNumberValid = XTool.IsNumberValid
local tableInsert = table.insert
local clone = XTool.Clone

local Default = {
    _Id = 0, --队伍Id
    _CaptainPos = 1, --队长位
    _FirstPos = 1, --首发位
    _RuneId = 0, --符文Id
    _SubRuneId = 0, --子符文Id
    _TeamMemberDic = {}, --上阵成员信息
    _PluginDic = {}, --插件信息
    _ElementId = 0, --队伍属性
}

---@class XStrongholdTeam
---@field _TeamMemberDic XStrongholdTeamMember[]
local XStrongholdTeam = XClass(nil, "XStrongholdTeam")

function XStrongholdTeam:Ctor(id)
    self:Init(id)
end

function XStrongholdTeam:Init(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self:SetId(id)
    self:InitPlugins()
end

function XStrongholdTeam:SetId(id)
    self._Id = id
end

function XStrongholdTeam:GetId()
    return self._Id
end

function XStrongholdTeam:SetCaptainPos(captainPos)
    self._CaptainPos = captainPos or self._CaptainPos
end

function XStrongholdTeam:GetCaptainPos()
    return self._CaptainPos
end

function XStrongholdTeam:SetFirstPos(firstPos)
    self._FirstPos = firstPos or self._FirstPos
end

function XStrongholdTeam:GetFirstPos()
    return self._FirstPos
end

function XStrongholdTeam:CheckHasCaptain()
    return not self:CheckPosEmpty(self._CaptainPos)
end

function XStrongholdTeam:CheckHasFirstPos()
    return not self:CheckPosEmpty(self._FirstPos)
end

function XStrongholdTeam:GetCaptainSkillDesc()
    if not self:CheckHasCaptain() then return "" end
    local captainMember = self:GetMember(self._CaptainPos)
    return captainMember and captainMember:GetCaptainSkillDesc() or ""
end

function XStrongholdTeam:SetMemberForce(pos, member)
    if not IsNumberValid(pos) then return end
    member:SetPos(pos)
    self._TeamMemberDic[pos] = member
end

---@return XStrongholdTeamMember
function XStrongholdTeam:GetMember(pos)
    if not IsNumberValid(pos) then return end
    local member = self._TeamMemberDic[pos]
    if not member then
        member = XStrongholdTeamMember.New(pos)
        self._TeamMemberDic[pos] = member
    end
    return member
end

---@type XStrongholdTeamMember[]
function XStrongholdTeam:GetAllMembers()
    local members = {}
    for _, member in pairs(self._TeamMemberDic) do
        tableInsert(members, member)
    end
    return members
end

function XStrongholdTeam:GetInTeamMemberCount()
    local count = 0
    for _, member in pairs(self._TeamMemberDic) do
        if not member:IsEmpty() then
            count = count + 1
        end
    end
    return count
end

function XStrongholdTeam:IsCharacterAssitant(characterId)
    for _, member in pairs(self._TeamMemberDic) do
        if not member:IsEmpty() then
            if member:GetRoleId() == characterId then
                return member:IsAssitant(), member:GetPlayerId()
            end
        end
    end
    return false
end

function XStrongholdTeam:GetShowCharacterIds()
    local characterIds = {}
    for pos, member in pairs(self._TeamMemberDic) do
        local showCharacterId = member:GetShowCharacterId()
        if IsNumberValid(showCharacterId) then
            tableInsert(characterIds, showCharacterId)
        end
    end
    return characterIds
end

--是否已上阵相同型号角色
function XStrongholdTeam:GetSameCharacterPos(characterId)
    if not IsNumberValid(characterId) then return false end
    characterId = XRobotManager.GetCharacterId(characterId)

    for pos, member in pairs(self._TeamMemberDic) do
        local showCharacterId = member:GetShowCharacterId()
        if showCharacterId == characterId then
            return pos
        end
    end
end

--是否已上阵支援角色
function XStrongholdTeam:CheckExistAssitantCharacter()
    for _, member in pairs(self._TeamMemberDic) do
        if member:IsAssitant() then
            return true
        end
    end

    return false
end

function XStrongholdTeam:CheckInTeam(characterId, playerId)
    if not IsNumberValid(characterId) then return false end
    for _, member in pairs(self._TeamMemberDic) do
        if member:IsInTeam(characterId, playerId) then
            return true, member:GetPos()
        end
    end
    return false, 0
end

function XStrongholdTeam:GetInTeamMemberByCharacterId(characterId, playerId)
    if not IsNumberValid(characterId) then return end
    for _, member in pairs(self._TeamMemberDic) do
        if member:IsInTeam(characterId, playerId) then
            return member
        end
    end
end

function XStrongholdTeam:GetInTeamMemberIndex(characterId, playerId)
    if not IsNumberValid(characterId) then return end
    for memberIndex, member in pairs(self._TeamMemberDic) do
        if member:IsInTeam(characterId, playerId) then
            return memberIndex
        end
    end
end

function XStrongholdTeam:GenarateTeamCharacterList(requireMemberNum)
    local characterIdList = { 0, 0, 0 }
    local characterIdToIsIsAssitantDic = {}
    requireMemberNum = requireMemberNum or #characterIdList
    for pos in pairs(characterIdList) do
        if pos <= requireMemberNum then
            local member = self:GetMember(pos)
            local inTeamCharacterId = member and member:GetInTeamCharacterId() or 0
            characterIdList[pos] = inTeamCharacterId
            characterIdToIsIsAssitantDic[inTeamCharacterId] = member:IsAssitant()
        end
    end
    return characterIdList, characterIdToIsIsAssitantDic
end

function XStrongholdTeam:SetMember(pos, characterId, playerId, robotId, ability)
    if not IsNumberValid(pos) then return end

    local member = self:GetMember(pos)
    if IsNumberValid(robotId) then
        member:SetRobotId(robotId)
    else
        member:SetCharacterId(characterId, playerId)--服务端他非要发kt.
    end
    member:SetAbility(ability)
end

--不检查队伍中是否已经存在其他类型的角色，目前支持混编
function XStrongholdTeam:ExistDifferentCharacterType(characterType)
    --for _, member in pairs(self._TeamMemberDic) do
    --    if not member:IsEmpty() then
    --        local inCharacterType = member:GetCharacterType()
    --        if inCharacterType and characterType and inCharacterType ~= characterType then
    --            return true
    --        end
    --    end
    --end
    return false
end

function XStrongholdTeam:InitPlugins()
    ---@type XStrongholdPlugin[]
    self._PluginDic = {}
    local pluginIds = XStrongholdConfigs.GetPluginIds()
    for _, pluginId in ipairs(pluginIds) do
        self._PluginDic[pluginId] = XStrongholdPlugin.New(pluginId)
    end
end

function XStrongholdTeam:GetAllPlugins()
    local plugins = {}
    for _, plugin in pairs(self._PluginDic) do
        tableInsert(plugins, plugin)
    end
    return plugins
end

---@return XStrongholdPlugin
function XStrongholdTeam:GetPlugin(pluginId)
    local plugin = self._PluginDic[pluginId]
    if not plugin then
        XLog.Error("XStrongholdTeam:GetPlugin error: 插件Id与服务端不同步, pluginId is: ", pluginId, self._PluginDic)
        return
    end
    return plugin
end

function XStrongholdTeam:SetPlugin(pluginId, count)
    local plugin = self:GetPlugin(pluginId)
    plugin:SetCount(count)
end

function XStrongholdTeam:IsAllPluginEmpty()
    for _, plugin in pairs(self._PluginDic) do
        if not plugin:IsEmpty() then
            return false
        end
    end
    return true
end

function XStrongholdTeam:GetUseElectricEnergy()
    local useElectric = 0
    for _, plugin in pairs(self._PluginDic) do
        useElectric = useElectric + plugin:GetCostElectric()
    end
    return useElectric
end

function XStrongholdTeam:GetUseCount()
    local count = 0
    for _, plugin in pairs(self._PluginDic) do
        count = count + plugin:GetCount()
    end
    return count
end

--获取已上阵成员总战力
function XStrongholdTeam:GetTeamAbility()
    local addAbility = 0
    for pos in pairs(self._TeamMemberDic) do
        addAbility = addAbility + self:GetTeamMemberAbility(pos)
    end
    return addAbility
end

--获取已激活插件额外增加战力
function XStrongholdTeam:GetPluginAddAbility()
    local addAbility = 0
    for _, plugin in pairs(self._PluginDic) do
        addAbility = addAbility + plugin:GetAddAbility()
    end
    return addAbility
end

--队伍内成员战力 = 成员战力
function XStrongholdTeam:GetTeamMemberAbility(pos)
    local member = self:GetMember(pos)
    return member:GetAbility()
end

function XStrongholdTeam:CheckPosEmpty(pos)
    local member = self:GetMember(pos)
    return member:IsEmpty()
end

function XStrongholdTeam:CheckTeamEveryMemberAbility(requireAbility, requireTeamMemberNum)
    requireTeamMemberNum = requireTeamMemberNum or 0
    for pos = 1, requireTeamMemberNum do
        local ability = self:GetTeamMemberAbility(pos)
        if ability < requireAbility then
            return false
        end
    end
    return true
end

--按照队伍要求人数裁剪多余的队员
function XStrongholdTeam:ClipMembers(requireTeamMember)
    local inTeamCount = 0
    local tmpMembers = {}
    for pos, member in pairs(self._TeamMemberDic) do
        if not member:IsEmpty() then
            inTeamCount = inTeamCount + 1
        end

        if pos > requireTeamMember then
            -- if inTeamCount > requireTeamMember then
            --队伍人数超出上限，直接裁员
            self._TeamMemberDic[pos] = nil
            -- else
            --队伍人数未超出上限，记录下来并移动到前面空的位置
            -- tableInsert(tmpMembers, member)
            -- self._TeamMemberDic[pos] = nil
            -- end
        end

    end

    --将未超出上限但位置不对的队员移动到前面空的位置
    -- local nextEmptyPos = 0
    -- for pos = 1, requireTeamMember do
    --     local member = self._TeamMemberDic[pos]
    --     if not member or member:IsEmpty() then
    --         nextEmptyPos = pos
    --         break
    --     end
    -- end
    -- if IsNumberValid(pos) then
    --     for _, member in pairs(tmpMembers) do
    --         self._TeamMemberDic[nextEmptyPos] = member
    --         member:SetPos(nextEmptyPos)
    --         nextEmptyPos = nextEmptyPos + 1
    --     end
    -- end
    --如队长/首发位为空，默认设置为1号位
    -- if self:CheckPosEmpty(self._CaptainPos) then
    --     self._CaptainPos = 1
    -- end
    -- if self:CheckPosEmpty(self._FirstPos) then
    --     self._FirstPos = 1
    -- end
end

--剔除不属于自己拥有角色的队员
function XStrongholdTeam:KickOutOtherMembers()
    for _, member in pairs(self._TeamMemberDic) do
        if not member:IsOwn() then
            member:ResetCharacters()
        end
    end
end

--剔除已经失效的援助角色和试玩角色
function XStrongholdTeam:KickOutInvalidMembers(canUseRobotIdDic)
    for _, member in pairs(self._TeamMemberDic) do
        if not member:CheckValid() then
            member:ResetCharacters()
        elseif (canUseRobotIdDic) and (member:IsRobot() and not canUseRobotIdDic[member:GetRobotId()]) then
            member:ResetCharacters()
        end
    end
end

--清空队伍
function XStrongholdTeam:Clear()
    for _, member in pairs(self._TeamMemberDic) do
        member:ResetCharacters()
    end
end

function XStrongholdTeam:Reset()
    local oldId = self._Id
    self:Init(oldId)
end

function XStrongholdTeam:Compare(cTeam)
    if not cTeam then return false end

    if self:GetCaptainPos() ~= cTeam:GetCaptainPos() then
        return false
    end

    if self:GetFirstPos() ~= cTeam:GetFirstPos() then
        return false
    end

    if self:GetCurGeneralSkill() ~= cTeam:GetCurGeneralSkill() then
        return false
    end
    
    local runeId, subRuneId = self:GetRune()
    local cRuneId, cSubRuneId = cTeam:GetRune()
    if runeId ~= cRuneId
    or subRuneId ~= cSubRuneId
    then
        return false
    end

    for pos, member in pairs(self._TeamMemberDic) do
        local cMember = cTeam:GetMember(pos)
        if not member:Compare(cMember) then
            return false
        end
    end

    for pluginId, plugin in pairs(self._PluginDic) do
        local cPlugin = cTeam:GetPlugin(pluginId)
        if not plugin:Compare(cPlugin) then
            return false
        end
    end

    return true
end

--设置符文
function XStrongholdTeam:SetRune(runeId, subRuneId)
    local oldRuneId, oldSubRuneId = 0, 0
    if XTool.IsNumberValid(runeId) then
        oldRuneId = self._RuneId
        self._RuneId = runeId
    end
    if XTool.IsNumberValid(subRuneId) then
        oldSubRuneId = self._SubRuneId
        self._SubRuneId = subRuneId
    end
    XDataCenter.StrongholdManager.TakeOffRune(oldRuneId, oldSubRuneId)
    XDataCenter.StrongholdManager.UseRune(runeId, subRuneId, self._Id)
end

--清空符文
function XStrongholdTeam:ClearRune()
    XDataCenter.StrongholdManager.TakeOffRune(self._RuneId, self._SubRuneId)
    self._RuneId = 0
    self._SubRuneId = 0
end

--获取符文
function XStrongholdTeam:GetRune()
    return self._RuneId, self._SubRuneId
end

--是否装备符文
function XStrongholdTeam:HasRune()
    return XDataCenter.StrongholdManager.IsCurActivityRune(self._RuneId) or XDataCenter.StrongholdManager.IsCurActivityRune(self._SubRuneId)
end

--是否装备该符文大类
function XStrongholdTeam:IsRuneUsing(runeId)
    return XTool.IsNumberValid(self._RuneId)
    and self._RuneId == runeId
end

--是否装备符文
function XStrongholdTeam:IsRune()
    return XTool.IsNumberValid(self._RuneId)
end

--获取符文描述
function XStrongholdTeam:GetRuneDesc()
    local runeId = self._RuneId
    if not XTool.IsNumberValid(runeId) then return "" end
    return XStrongholdConfigs.GetRuneBrief(runeId)
end

function XStrongholdTeam:GetRuneName()
    local runeId = self._RuneId
    if not XTool.IsNumberValid(runeId) then return "" end
    return XStrongholdConfigs.GetRuneName(runeId)
end

--获取符文颜色
function XStrongholdTeam:GetRuneColor()
    local runeId = self._RuneId
    if not XTool.IsNumberValid(runeId) then return "" end
    return XStrongholdConfigs.GetRuneColor(runeId)
end

function XStrongholdTeam:SetElementId(element)
    self._ElementId = element
end

function XStrongholdTeam:GetElementId()
    return self._ElementId
end

--兼容旧编队系统
---@return XTeam
function XStrongholdTeam:CreateTempTeam()
    local teamData = {}
    teamData.FirstFightPos = self._FirstPos
    teamData.CaptainPos = self._CaptainPos
    teamData.TeamData = {}
    for pos, member in pairs(self._TeamMemberDic) do
        teamData.TeamData[pos] = member:GetRoleId()
    end
    teamData.SelectedGeneralSkill = self.SelectedGeneralSkill
    teamData.EnterCgIndex = self:GetEnterCgIndex()
    teamData.SettleCgIndex = self:GetSettleCgIndex()
    ---@type XTeam
    local xTeam = XDataCenter.TeamManager.CreateTeam(self._Id)
    xTeam:UpdateAutoSave(true)
    xTeam:UpdateLocalSave(false)
    xTeam:Clear()
    xTeam:UpdateFromTeamData(teamData)
    xTeam:RefreshGeneralSkills()
    xTeam:UpdateSaveCallback(function(inTeam)
        self:SetCaptainPos(xTeam:GetCaptainPos())
        self:SetFirstPos(xTeam:GetFirstFightPos())
        local members = XTool.Clone(self:GetAllMembers())
        for pos, id in pairs(xTeam.EntitiyIds) do
            local newMember = nil
            for _, member in pairs(members) do
                if member:GetRoleId() == id then
                    newMember = member
                    break
                end
            end
            if newMember then
                self:SetMember(pos, newMember:GetCharacterId(), newMember:GetPlayerId(), newMember:GetRobotId(), newMember:GetAbility())
            end
        end
        -- 继承XTeam的效应技能选择数据
        self.SelectedGeneralSkill = xTeam:GetCurGeneralSkill()
        self:SetEnterCgIndex(xTeam:GetEnterCgIndex())
        self:SetSettleCgIndex(xTeam:GetSettleCgIndex())
    end)
    xTeam:Save()

    return xTeam
end

--region 角色效应技能相关
function XStrongholdTeam:GetGeneralSkillList()
    local list = {}

    for id, characters in pairs(self._GenernalSkills) do
        table.insert(list,{Id = id, Characters = characters})
    end

    return list
end

function XStrongholdTeam:GetCurGeneralSkill()
    return self.SelectedGeneralSkill or 0
end

function XStrongholdTeam:CheckHasGeneralSkills()
    return not XTool.IsTableEmpty(self._GenernalSkills)
end

---技能汇总表仅加载时缓存，不会存储到本地
function XStrongholdTeam:UpdateGenernalSkillsByEntityId(entityId, isRemove)
    if not XTool.IsNumberValid(entityId) then
        return
    end

    local fixedEntityId = entityId

    --如果是机器人则需要转变一下
    local characterId = XMVCA.XCharacter:CheckIsCharOrRobot(fixedEntityId) and XRobotManager.GetCharacterId(fixedEntityId) or fixedEntityId
    -- 获取角色已激活的效应技能列表（自机和机器人）
    local skillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(characterId)

    if XTool.IsTableEmpty(skillIds) then
        return
    end

    if self._GenernalSkills == nil then
        self._GenernalSkills = {}
    end

    for index, value in ipairs(skillIds) do
        if isRemove then
            if not XTool.IsTableEmpty(self._GenernalSkills[value]) then
                self._GenernalSkills[value][characterId] = nil
            end

            if XTool.IsTableEmpty(self._GenernalSkills[value]) then
                self._GenernalSkills[value] = nil
                if self.SelectedGeneralSkill == value then
                    self:UpdateSelectGeneralSkill(0)
                end
            end
        else
            if self._GenernalSkills[value] == nil then
                self._GenernalSkills[value] = {}
            end
            self._GenernalSkills[value][characterId] = true
        end

        :: continue ::
    end
end

function XStrongholdTeam:AutoSelectGeneralSkill(defaultSkillIds)
    if not XTool.IsTableEmpty(defaultSkillIds) then
        local aimSkillId = 0
        for index, value in ipairs(defaultSkillIds) do
            if not XTool.IsTableEmpty(self._GenernalSkills[value]) then
                if aimSkillId == 0 then
                    aimSkillId = value
                else
                    local newCount = XTool.GetTableCount(value)
                    local oldCount = XTool.GetTableCount(self._GenernalSkills[aimSkillId])
                    if newCount > oldCount then -- 如果新的技能角色数最多，则选新技能
                        aimSkillId = value
                    end
                end
            end
        end
        if XTool.IsNumberValid(aimSkillId) then
            self:UpdateSelectGeneralSkill(aimSkillId)
            return
        end
    end

    if XTool.IsTableEmpty(self._GenernalSkills) then
        return
    end
    --找出关联角色最多且Id最小的技能
    local aimSkillId = 0
    for key, value in pairs(self._GenernalSkills) do
        if aimSkillId == 0 then
            aimSkillId = key
        else
            local newCount = XTool.GetTableCount(value)
            local oldCount = XTool.GetTableCount(self._GenernalSkills[aimSkillId])
            if newCount > oldCount then -- 如果新的技能角色数最多，则选新技能
                aimSkillId = key
            elseif newCount == oldCount then -- 如果两个技能角色数量相等，则选Id小的那一个
                if key < aimSkillId then
                    aimSkillId = key
                end
            end
        end
    end
    self:UpdateSelectGeneralSkill(aimSkillId)
end

--- 矿区编队特殊处理，防止遗漏数据
function XStrongholdTeam:RefreshGeneralSkillOption()
    -- 刷新需要保证已经选择的效应不被重置（还存在的情况下）
    local lastSelectGeneralSkill = self.SelectedGeneralSkill or 0

    self._GenernalSkills = nil
    self.SelectedGeneralSkill = 0
    for pos, member in pairs(self._TeamMemberDic) do
        self:UpdateGenernalSkillsByEntityId(member:GetRoleId())
    end

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

    if not XTool.IsNumberValid(self.SelectedGeneralSkill) then
        self:AutoSelectGeneralSkill()
    end
end

function XStrongholdTeam:UpdateSelectGeneralSkill(skillId)
    self.SelectedGeneralSkill = skillId
end
--endregion

--region 入场结算动画角色自选

function XStrongholdTeam:GetEnterCgIndex()
    return self.EnterCgIndex or 0
end

function XStrongholdTeam:GetSettleCgIndex()
    return self.SettleCgIndex or 0
end

function XStrongholdTeam:SetEnterCgIndex(index)
    self.EnterCgIndex = index
end

function XStrongholdTeam:SetSettleCgIndex(index)
    self.SettleCgIndex = index
end

--endregion

return XStrongholdTeam