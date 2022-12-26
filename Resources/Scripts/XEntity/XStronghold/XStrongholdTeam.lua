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
}

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

    self._Id = id
    self:InitPlugins()
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

function XStrongholdTeam:GetMember(pos)
    if not IsNumberValid(pos) then return end
    local member = self._TeamMemberDic[pos]
    if not member then
        member = XStrongholdTeamMember.New(pos)
        self._TeamMemberDic[pos] = member
    end
    return member
end

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

--检查队伍中是否已经存在其他类型的角色（构造体/授格者）
function XStrongholdTeam:ExistDifferentCharacterType(characterType)
    for _, member in pairs(self._TeamMemberDic) do
        if not member:IsEmpty() then
            local inCharacterType = member:GetCharacterType()
            if inCharacterType and characterType and inCharacterType ~= characterType then
                return true
            end
        end
    end
    return false
end

function XStrongholdTeam:InitPlugins()
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

--队伍内成员战力 = 成员战力 + 已激活插件额外增加战力
function XStrongholdTeam:GetTeamMemberAbility(pos)
    local extraAbility = self:GetPluginAddAbility()
    local member = self:GetMember(pos)
    return extraAbility + member:GetAbility()
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

--剔除已经失效的援助角色
function XStrongholdTeam:KickOutInvalidMembers()
    for _, member in pairs(self._TeamMemberDic) do
        if not member:CheckValid() then
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
    return XTool.IsNumberValid(self._RuneId)
    and XTool.IsNumberValid(self._SubRuneId)
end

--是否装备该符文大类
function XStrongholdTeam:IsRuneUsing(runeId)
    return XTool.IsNumberValid(self._RuneId)
    and self._RuneId == runeId
end

--获取符文描述
function XStrongholdTeam:GetRuneDesc()
    local runeId = self._RuneId
    if not XTool.IsNumberValid(runeId) then return "" end
    return XStrongholdConfigs.GetRuneBrief(runeId)
end

--获取符文颜色
function XStrongholdTeam:GetRuneColor()
    local runeId = self._RuneId
    if not XTool.IsNumberValid(runeId) then return "" end
    return XStrongholdConfigs.GetRuneColor(runeId)
end

return XStrongholdTeam