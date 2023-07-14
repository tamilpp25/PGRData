local type = type
local pairs = pairs

--[[    
public class XAreaWarRankInfo
{
    //排名
    public int Rank;

    //玩家id
    public int PlayerId;

    //名字
    public string Name;

    //头像
    public int HeadPortraitId;

    //头像框
    public int HeadFrameId;

    //积分
    public int Score;

    //排行榜总人数
    public long MemberCount;
}
]]
local Default = {
    Rank = 0, --排名
    PlayerId = 0, --玩家Id
    Name = "", --名字
    HeadPortraitId = 0, --头像
    HeadFrameId = 0, --头像框
    Score = 0, --积分
    MemberCount = 0 --排行榜总人数
}

local XAreaWarRankItem = XClass(nil, "XAreaWarRankItem")

function XAreaWarRankItem:Ctor(rank)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XAreaWarRankItem:UpdateData(data)
    self.Rank = data.Rank or self.Rank
    self.PlayerId = data.PlayerId or self.PlayerId
    self.Name = data.Name or self.Name
    self.HeadPortraitId = data.HeadPortraitId or self.HeadPortraitId
    self.HeadFrameId = data.HeadFrameId or self.HeadFrameId
    self.Score = data.Score or self.Score
    self.MemberCount = data.MemberCount or self.MemberCount
end

return XAreaWarRankItem
