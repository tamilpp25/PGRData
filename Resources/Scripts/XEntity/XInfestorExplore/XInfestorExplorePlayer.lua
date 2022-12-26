local DefaultSign = CS.XTextManager.GetText("CharacterSignTip")

local XInfestorExplorePlayer = XClass(nil, "XInfestorExplorePlayer")

--[[{
    // 玩家id
    public int Id;
    // 等级
    public int Level;
    // 名字
    public string Name;
    // 签名
    public string Sign;
    // 头像
    public int HeadPortraitId;
    // 分数
    public int Score;
    // 所在章节id
    public int ChapterId;
    // 所在格子id
    public int GridId;
}]]
local Default = {
    Id = 0,
    Level = 0,
    Name = "",
    Sign = "",
    HeadPortraitId = 0,
    HeadFrameId = 0,
    Score = 0,
    ChapterId = 0,
    GridId = 0,
    GroupId = 0,
    Diff = 0,
}

function XInfestorExplorePlayer:Ctor()
    for key, value in pairs(Default) do
        self[key] = value
    end
end

function XInfestorExplorePlayer:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XInfestorExplorePlayer:GetPlayerId()
    return self.Id
end

function XInfestorExplorePlayer:SetScore(score)
    self.Score = score
end

function XInfestorExplorePlayer:GetScore()
    return self.Score
end

function XInfestorExplorePlayer:GetHeadPortraitId()
    return self.HeadPortraitId
end

function XInfestorExplorePlayer:GetHeadFrameId()
    return self.HeadFrameId
end

function XInfestorExplorePlayer:GetChapterId()
    return self.ChapterId
end

function XInfestorExplorePlayer:GetGridId()
    return self.GridId
end

function XInfestorExplorePlayer:GetName()
    return self.Name
end

function XInfestorExplorePlayer:GetLevel()
    return self.Level
end

function XInfestorExplorePlayer:GetSign()
    local str = self.Sign
    return not string.IsNilOrEmpty(str) and str or DefaultSign
end

function XInfestorExplorePlayer:GetHeadIcon()
    return XDataCenter.HeadPortraitManager.GetHeadPortraitImgSrcById(self.HeadPortraitId)
end

function XInfestorExplorePlayer:GetHeadEffectPath()
    return XDataCenter.HeadPortraitManager.GetHeadPortraitEffectById(self.HeadPortraitId)
end

function XInfestorExplorePlayer:GetHeadFrame()
    return XDataCenter.HeadPortraitManager.GetHeadPortraitImgSrcById(self.HeadFrameId)
end

function XInfestorExplorePlayer:GetHeadFrameEffectPath()
    return XDataCenter.HeadPortraitManager.GetHeadPortraitEffectById(self.HeadFrameId)
end

function XInfestorExplorePlayer:GetDiffName()
    local groupId = self.GroupId
    local diff = self.Diff
    if groupId > 0 and diff > 0 then
        return XFubenInfestorExploreConfigs.GetDiffName(groupId, diff)
    end
end

function XInfestorExplorePlayer:GetDiffIcon()
    local groupId = self.GroupId
    local diff = self.Diff
    if groupId > 0 and diff > 0 then
        return XFubenInfestorExploreConfigs.GetDiffIcon(groupId, diff)
    end
end

return XInfestorExplorePlayer