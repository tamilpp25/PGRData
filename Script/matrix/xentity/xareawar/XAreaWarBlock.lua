local XAreaWarRank = require("XEntity/XAreaWar/XAreaWarRank")

local type = type
local pairs = pairs
local tableInsert = table.insert
local tableUnpack = table.unpack

--[[    
public class AreaWarBlockInfo
{
    public int BlockId;

    //净化度
    public long Purification;
    
    //世界boss参与人数
    public long FightCount;

    //常规区块净化排行，10个人
    public List<XAreaWarRankInfo> NormalBlockRank = new List<XAreaWarRankInfo>();
}
]]
local Default = {
    _Id = 0,
    _SelfPurification = 0, --我的净化度
    _Purification = 0, --净化度
    _RequirePurification = 0, -- 目标净化度
    _FightCount = 0, --世界Boss参与人数
    _Rank = {}, --常规区块净化排行，10个人
    _Visible = false, --区块是否可见
    _BossBlockUnlockTimestamp = 0 --区块世界Boss解锁时间
}

local XAreaWarBlock = XClass(nil, "XAreaWarBlock")

function XAreaWarBlock:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Id = id
    self._RequirePurification = XAreaWarConfigs.GetBlockRequirePurification(id)
    self._Rank = XAreaWarRank.New()
end

function XAreaWarBlock:UpdateData(data)
    self._Purification = data.Purification or self._Purification
    self._FightCount = data.FightCount or self._FightCount
    self._BossBlockUnlockTimestamp = data.BossBlockUnlockTimestamp or self._BossBlockUnlockTimestamp
    self._Rank:UpdateData(data.NormalBlockRank)
end

function XAreaWarBlock:UpdateBlockSelfPurification(purification)
    self._SelfPurification = purification or self._SelfPurification
end

function XAreaWarBlock:GetPurification()
    return self._Purification
end

function XAreaWarBlock:GetRank()
    return self._Rank
end

function XAreaWarBlock:GetWorldBossOpenTime()
    return self._BossBlockUnlockTimestamp or 0
end

function XAreaWarBlock:GetRequirePurification()
    return self._RequirePurification
end

--获取净化进度（小数）
function XAreaWarBlock:GetProgress()
    if not XTool.IsNumberValid(self._RequirePurification) then
        return 0
    end
    return self._Purification / self._RequirePurification
end

function XAreaWarBlock:GetFightCount()
    return self._FightCount
end

function XAreaWarBlock:GetSelfPurification()
    return self._SelfPurification or 0
end

--获取区块展示奖励物品列表
function XAreaWarBlock:GetRewardItems()
    local rewardItems = {}
    local rewardId = XAreaWarConfigs.GetBlockShowRewardId(self._Id)
    if XTool.IsNumberValid(rewardId) then
        rewardItems = XRewardManager.GetRewardList(rewardId)
    end
    return XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
end

function XAreaWarBlock:SetPurificationMax()
    self._Purification = self:GetRequirePurification()
end

--被灯塔点亮
function XAreaWarBlock:LightUp()
    self._Visible = true
end

function XAreaWarBlock:IsVisible()
    return self._Visible
end

return XAreaWarBlock
