local type = type
local pairs = pairs
local ipairs = ipairs
local tableInsert = table.insert
local IsNumberValid = XTool.IsNumberValid
local clone = XTool.Clone

local Default = {
    _Pos = 0, --队伍中的位置
    _CharacterId = 0, --角色或机器人Id
}

--队伍中的角色
local XAdventureTeamMember = XClass(nil, "XAdventureTeamMember")

function XAdventureTeamMember:Ctor(pos)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Pos = pos
end

function XAdventureTeamMember:GetPos()
    return self._Pos
end

function XAdventureTeamMember:SetPos(pos)
    if not IsNumberValid(pos) then return end
    self._Pos = pos
end

function XAdventureTeamMember:GetCharacterId()
    return self._CharacterId
end

function XAdventureTeamMember:GetCaptainSkillDesc()
    if self:IsEmpty() then return "" end

    local charId = self:GetCharacterId()
    return XRobotManager.CheckIsRobotId(charId) and XRobotManager.GetRobotCaptainSkillDesc(charId) or XDataCenter.CharacterManager.GetCaptainSkillDesc(charId)
end

function XAdventureTeamMember:GetAbility()
    if self:IsEmpty() then return 0 end

    local charId = self:GetCharacterId()
    local ability = XRobotManager.CheckIsRobotId(charId) and XRobotManager.GetRobotAbility(charId) or XDataCenter.CharacterManager.GetCharacterAbilityById(charId)
    return math.ceil(ability)
end

function XAdventureTeamMember:GetSmallHeadIcon()
    if self:IsEmpty() then return "" end

    local charId = self:GetCharacterId()
    return XRobotManager.CheckIsRobotId(charId) and XRobotManager.GetRobotSmallHeadIcon(charId) or XDataCenter.CharacterManager.GetCharSmallHeadIcon(charId)
end

function XAdventureTeamMember:GetCharacterName()
    if self:IsEmpty() then return "" end

    local charId = self:GetCharacterId()
    return XRobotManager.CheckIsRobotId(charId) and XMVCA.XCharacter:GetCharacterName(XRobotManager.GetCharacterId(charId)) or XMVCA.XCharacter:GetCharacterName(charId)
end

--是否为空
function XAdventureTeamMember:IsEmpty()
    local charId = self:GetCharacterId()
    return not IsNumberValid(charId)
end

return XAdventureTeamMember