local XInfestorExploreCharacter = XClass(nil, "XInfestorExploreCharacter")

--[[{
    // 玩家id
    public int CharacterId;
    // 血量百分比
    public int HpPer;
    // 上阵位置
    public int TeamPos;
    // 是否是队长
    public bool IsCaptain;
    // 是否是第一个出场
    public bool IsFirstFight
}]]
local Default = {
    CharacterId = 0,
    HpPer = 100,
    TeamPos = 0,
    IsCaptain = nil,
    IsFirstFight = nil,
}

function XInfestorExploreCharacter:Ctor()
    for key, value in pairs(Default) do
        self[key] = value
    end
end

function XInfestorExploreCharacter:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XInfestorExploreCharacter:GetCharacterId()
    return self.CharacterId
end

function XInfestorExploreCharacter:GetHpPercent()
    return self.HpPer
end

function XInfestorExploreCharacter:GetTeamPos()
    return self.TeamPos
end

function XInfestorExploreCharacter:IsMeCaptain()
    return self.IsCaptain and true or false
end

function XInfestorExploreCharacter:IsMeFirstFight()
    return self.IsFirstFight and true or false
end

function XInfestorExploreCharacter:SetTeamInfo(teamPos, isCaptain, isFirstFight)
    self.TeamPos = teamPos
    self.IsCaptain = isCaptain and true or nil
    self.IsFirstFight = isFirstFight
end

function XInfestorExploreCharacter:ClearTeamInfo()
    self.TeamPos = 0
    self.IsCaptain = nil
    self.IsFirstFight = nil
end

return XInfestorExploreCharacter