
local type = type
local pairs = pairs

--[[    
public class XKillZoneStageDb
{
    public int Id;
    
    /// <summary>
    /// 星级统计
    /// </summary>
    public int Star { get; set; }
    
    /// <summary>
    /// 胜利次数
    /// </summary>
    public int WinCount;

    /// <summary>
    /// 击败敌人数目
    /// </summary>
    public int KillEnemyCount;
}
]]
local Default = {
    _Id = 0, --关卡Id
    _Star = 0, --星级统计
    _WinCount = 0, --胜利次数
    _KillEnemyCount = 0, --击败敌人数目
    _RandomFightEventId = 0, -- 携带buff
    _MaxScore = 0, -- 最高分数
}

---@class XKillZoneStage
local XKillZoneStage = XClass(nil, "XKillZoneStage")

function XKillZoneStage:Ctor(id)
    self:Init(id)
end

function XKillZoneStage:Init(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Id = id
end

function XKillZoneStage:UpdateData(info)
    self._Star = info.Star or self._Star
    self._WinCount = info.WinCount or self._WinCount
    self._KillEnemyCount = info.KillEnemyCount or self._KillEnemyCount
    self._RandomFightEventId = info.RandomFightEventId or self._RandomFightEventId
    self._MaxScore = info.MaxScore or self._MaxScore
end

function XKillZoneStage:GetId()
    return self._Id
end

function XKillZoneStage:GetKillEnemyCount()
    return self._KillEnemyCount
end

function XKillZoneStage:GetStar()
    return self._Star
end

function XKillZoneStage:GetMaxStar()
    return XKillZoneConfigs.GetStageMaxStar(self._Id)
end

function XKillZoneStage:GetRandomFightEventId()
    return self._RandomFightEventId
end

function XKillZoneStage:GetMaxScore()
    return self._MaxScore
end

function XKillZoneStage:IsFinishedPerfect()
     return self:GetStar() == self:GetMaxStar()
end

function XKillZoneStage:IsFinished()
    return self._WinCount > 0
end

return XKillZoneStage