local XInfestorExploreTeam = XClass(nil, "XInfestorExploreTeam")

local Default = {
    TeamType = 0,
    CaptainPos = 1,
    FirstFightPos = 1,
    MemberNum = 0,
    CharacterIds = { 0, 0, 0 },
    IsSyn = false, --是否与服务端同步过
}

function XInfestorExploreTeam:Ctor(teamType)
    for key, value in pairs(Default) do
        self[key] = value
    end
    self.TeamType = teamType
end

function XInfestorExploreTeam:IsSyned()
    return self.IsSyn
end

function XInfestorExploreTeam:Syn()
    self.IsSyn = true
end

function XInfestorExploreTeam:SetCaptainPos(captainPos)
    self.CaptainPos = captainPos
end

function XInfestorExploreTeam:SetFirstFightPos(firstFightPos)
    self.FirstFightPos = firstFightPos
end

function XInfestorExploreTeam:GetCaptainPos()
    return self.CaptainPos
end

function XInfestorExploreTeam:GetFirstFightPos()
    return self.FirstFightPos
end

function XInfestorExploreTeam:SetCharacterIds(characterIds)
    self.CharacterIds = characterIds

    local memeberNum = 0
    for _, characterId in pairs(characterIds) do
        if characterId > 0 then
            memeberNum = memeberNum + 1
        end
    end
    self.MemberNum = memeberNum
end

function XInfestorExploreTeam:GetCharacterIds()
    return XTool.Clone(self.CharacterIds)
end

function XInfestorExploreTeam:IsEmpty()
    return self.MemberNum == 0
end

function XInfestorExploreTeam:IsCaptainExist()
    local captainCharacterId = self.CharacterIds[self.CaptainPos]
    return captainCharacterId and captainCharacterId > 0
end

function XInfestorExploreTeam:IsFirstFightExist()
    local firstFightCharacterId = self.CharacterIds[self.FirstFightPos]
    return firstFightCharacterId and firstFightCharacterId > 0
end

return XInfestorExploreTeam