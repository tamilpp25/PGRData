local type = type
local pairs = pairs
local ipairs = ipairs
local tableInsert = table.insert
local IsNumberValid = XTool.IsNumberValid
local clone = XTool.Clone

local Default = {
    _Pos = 0, --队伍中的位置
    _CharacterId = 0, --角色Id
    _RobotId = 0, --机器人Id
    _PlayerId = 0, --玩家Id（援助角色）
    _OthersAbility = 0 --角色战力（援助角色）
}

local XStrongholdTeamMember = XClass(nil, "XStrongholdTeamMember")

function XStrongholdTeamMember:Ctor(pos)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Pos = pos
end

function XStrongholdTeamMember:GetPos()
    return self._Pos
end

function XStrongholdTeamMember:SetPos(pos)
    if not IsNumberValid(pos) then
        return
    end
    self._Pos = pos
end

function XStrongholdTeamMember:GetCharacterId()
    return self._CharacterId
end

function XStrongholdTeamMember:GetRobotId()
    return self._RobotId
end

function XStrongholdTeamMember:GetPlayerId()
    return self._PlayerId
end

function XStrongholdTeamMember:GetOthersPlayerId()
    if self._PlayerId == XPlayer.Id then
        return 0
    end
    return self:GetPlayerId()
end

function XStrongholdTeamMember:GetCaptainSkillDesc()
    if self:IsEmpty() then
        return ""
    end

    if self:IsAssitant() then
        return XDataCenter.CharacterManager.GetCaptainSkillDesc(self._CharacterId, true)
    elseif self:IsRobot() then
        return XRobotManager.GetRobotCaptainSkillDesc(self._RobotId)
    else
        return XDataCenter.CharacterManager.GetCaptainSkillDesc(self._CharacterId)
    end
end

--获取队伍中实际上阵的CharacterId/RobotId
function XStrongholdTeamMember:GetInTeamCharacterId()
    if self:IsAssitant() then
        return self:GetCharacterId()
    elseif self:IsRobot() then
        return self:GetRobotId()
    else
        return self:GetCharacterId()
    end
end

--获取展示用的CharacterId(RobotId自转换)
function XStrongholdTeamMember:GetShowCharacterId()
    if self:IsAssitant() then
        return self:GetCharacterId()
    elseif self:IsRobot() then
        return XRobotManager.GetCharacterId(self:GetRobotId())
    else
        return self:GetCharacterId()
    end
end

function XStrongholdTeamMember:GetCharacterType()
    local showCharacterId = self:GetShowCharacterId()
    if not IsNumberValid(showCharacterId) then
        return
    end
    return XCharacterConfigs.GetCharacterType(showCharacterId)
end

--上阵
function XStrongholdTeamMember:SetInTeam(characterId, playerId)
    if XRobotManager.CheckIsRobotId(characterId) then
        self:SetRobotId(characterId)
    else
        self:SetCharacterId(characterId, playerId)
    end
end

--下阵
function XStrongholdTeamMember:KickOutTeam()
    self:ResetCharacters()
end

function XStrongholdTeamMember:SetCharacterId(characterId, playerId)
    if not characterId then
        return
    end

    --清空其他角色信息
    self:ResetCharacters()

    self._CharacterId = characterId or 0
    self._PlayerId = IsNumberValid(playerId) and playerId or XPlayer.Id

    if playerId ~= XPlayer.Id then
        self._OthersAbility = XDataCenter.StrongholdManager.GetAssistantPlayerAbiility(playerId)
    end
end

function XStrongholdTeamMember:SetRobotId(robotId)
    if not robotId then
        return
    end

    --清空其他角色信息
    self:ResetCharacters()

    self._RobotId = robotId
end

function XStrongholdTeamMember:SetAbility(ability)
    self._OthersAbility = ability or self._OthersAbility
end

function XStrongholdTeamMember:GetAbility()
    if self:IsEmpty() then
        return 0
    end

    local ability = 0
    if self:IsAssitant() then
        ability = self._OthersAbility
    elseif self:IsRobot() then
        ability = XRobotManager.GetRobotAbility(self._RobotId)
    else
        ability = XDataCenter.CharacterManager.GetCharacterAbilityById(self._CharacterId)
    end

    return math.ceil(ability)
end

--是否为援助角色
function XStrongholdTeamMember:IsAssitant()
    if self:IsEmpty() then
        return false
    end
    return self._PlayerId ~= 0 and self._PlayerId ~= XPlayer.Id
end

--是否为试玩角色
function XStrongholdTeamMember:IsRobot()
    if self:IsEmpty() then
        return false
    end
    return self._RobotId ~= 0
end

--是否为自己拥有的角色
function XStrongholdTeamMember:IsOwn()
    if self:IsEmpty() then
        return false
    end
    return not self:IsRobot() and not self:IsAssitant()
end

--是否为授格者
function XStrongholdTeamMember:IsIsomer()
    if self:IsEmpty() then
        return false
    end

    if self:IsAssitant() then
        return false
    elseif self:IsRobot() then
        return XRobotManager.IsIsomer(self._RobotId)
    else
        return XCharacterConfigs.IsIsomer(self._CharacterId)
    end
end

--援助角色是否有效
function XStrongholdTeamMember:CheckAssitantValid()
    if not self:IsAssitant() then
        return true
    end
    return XDataCenter.StrongholdManager.CheckAssitantValid(self._PlayerId, self._CharacterId)
end

--角色是否有效
function XStrongholdTeamMember:CheckValid()
    if self:IsAssitant() then
        return self:CheckAssitantValid()
    end
    return true
end

--是否为空
function XStrongholdTeamMember:IsEmpty()
    return self._CharacterId == 0 and self._RobotId == 0
end

function XStrongholdTeamMember:IsInTeam(characterId, playerId)
    if not IsNumberValid(characterId) then
        return false
    end
    if not self:CheckPlayerId(playerId) then
        return false
    end
    return self:GetInTeamCharacterId() == characterId
end

function XStrongholdTeamMember:CheckPlayerId(playerId)
    if self:IsRobot() then
        return true
    end
    playerId = IsNumberValid(playerId) and playerId or XPlayer.Id
    return self._PlayerId == playerId
end

function XStrongholdTeamMember:ResetCharacters()
    self._CharacterId = 0
    self._RobotId = 0
    self._PlayerId = 0
end

function XStrongholdTeamMember:GetSmallHeadIcon()
    if self:IsEmpty() then
        return ""
    end

    if self:IsAssitant() then
        return XDataCenter.CharacterManager.GetCharSmallHeadIcon(self._CharacterId)
    elseif self:IsRobot() then
        return XRobotManager.GetRobotSmallHeadIcon(self._RobotId)
    else
        return XDataCenter.CharacterManager.GetCharSmallHeadIcon(self._CharacterId)
    end
end

function XStrongholdTeamMember:GetCharacterName()
    if self:IsEmpty() then
        return ""
    end

    if self:IsAssitant() then
        return XCharacterConfigs.GetCharacterName(self._CharacterId)
    elseif self:IsRobot() then
        local characterId = XRobotManager.GetCharacterId(self._RobotId)
        return XCharacterConfigs.GetCharacterName(characterId)
    else
        return XCharacterConfigs.GetCharacterName(self._CharacterId)
    end
end

function XStrongholdTeamMember:Compare(cMember)
    if not cMember then
        return false
    end

    return self._CharacterId == cMember:GetCharacterId() and self._RobotId == cMember:GetRobotId() and
        self._PlayerId == cMember:GetPlayerId() and
        self._Pos == cMember:GetPos()
end

return XStrongholdTeamMember
