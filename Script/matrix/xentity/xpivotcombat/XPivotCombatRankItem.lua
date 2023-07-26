
local XPivotCombatRankItem = XClass(nil, "XPivotCombatRankItem")
local TOP_MAX = 3 --特殊显示最大的名次
local TOP_MIN = 1 --特殊显示最小的名次
local MAX_TEAM_MEMBER = 3 --最大队员数量
--[[
rankData = {
    // 玩家id
    public int Id;
    
    // 玩家名字
    public string Name;
    
    // 头像
    public int HeadPortraitId;
    
    // 头像框
    public int HeadFrameId;
    
    // 分数
    public int Score;
    
    // 通关时间积分
    public int FightTimeScore;
    
    // 使用的角色信息
    public List<XPivotCombatRankPlayerFightCharacterInfo> CharacterInfoList = new List<XPivotCombatRankPlayerFightCharacterInfo>();
}

public sealed class XPivotCombatRankPlayerFightCharacterInfo()
{
    // 角色id
    public int CharacterId;
    // 解放等级
    public int LiberateLv;
    // 头像信息
    public XCharacterHeadInfo CharacterHeadInfo = new XCharacterHeadInfo()
}
]]

--初始化
function XPivotCombatRankItem:Ctor(rankData, ranking, totalCount)
    self:Refresh(rankData, ranking, totalCount)
end 

function XPivotCombatRankItem:Refresh(rankData, ranking, totalCount)
    self.RankData = rankData or {}
    self.Ranking = ranking
    self.TotalCount = totalCount or 1 --至少有玩家一个人，保证不除0
end

--玩家Id
function XPivotCombatRankItem:GetPlayerId()
    return self.RankData.Id or 0
end 

--玩家名字
function XPivotCombatRankItem:GetName()
    return self.RankData.Name or ""
end 

--玩家头像
function XPivotCombatRankItem:GetHeadPortraitId()
    return self.RankData.HeadPortraitId or 0
end 

--玩家头像框
function XPivotCombatRankItem:GetHeadFrameId()
    return self.RankData.HeadFrameId or 0
end 

--玩家通关时的分数
function XPivotCombatRankItem:GetScore()
    return self.RankData.Score or 0
end 

--==============================
 ---@desc 服务端发过来的分数  score = base + timeScore
--==============================
function XPivotCombatRankItem:GetScoreWithoutTimeScore()
    local score = self.RankData.Score
    local timeScore = self.RankData.FightTimeScore
    return score - timeScore
end

--玩家通关时使用的角色信息列表
function XPivotCombatRankItem:GetPassedCharacterIds()
    return self.RankData.CharacterInfoList
end 

--获取排名
function XPivotCombatRankItem:GetRanking()
    return self.Ranking
end

--获取排名(百分比)
function XPivotCombatRankItem:GetRankingPercentage()
    --表示还未参与活动
    if self.Ranking <= 0 then
        return CS.XTextManager.GetText("None")
    end
    return string.format("%s%%", math.floor((self.Ranking / self.TotalCount) * 100))
end

--是否上榜
function XPivotCombatRankItem:GetIsOnTheList()
    local maxMember = XDataCenter.PivotCombatManager.GetMaxRankMember()
    return self.Ranking <= maxMember and self.Ranking > 0
end

--是否是榜上前几名
function XPivotCombatRankItem:IsTopOnTheList()
    return self.Ranking >= TOP_MIN and self.Ranking <= TOP_MAX
end

--刷新通关角色头像
function XPivotCombatRankItem:RefreshHeadList(headList)
    --通关队伍信息
    local characterInfos = self.RankData.CharacterInfoList
    local headGridIndex = 1
    for idx = 1, MAX_TEAM_MEMBER do
        local info = characterInfos[idx]
        if info then
            local charId = info.CharacterId
            local headInfo = info.CharacterHeadInfo
            if XTool.IsNumberValid(charId) then
                local headFashionId
                local headFashionType
                if headInfo then
                    headFashionId = headInfo.HeadFashionId
                    headFashionType = headInfo.HeadFashionType
                end
                local icon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(charId, true, headFashionId, headFashionType)
                headList[headGridIndex]:SetRawImage(icon)
                headList[headGridIndex].gameObject:SetActiveEx(true)
                headGridIndex = headGridIndex + 1
            end
        end
    end

    for i = headGridIndex, #headList do
        headList[i].gameObject:SetActiveEx(false)
    end
end

--通关时间
function XPivotCombatRankItem:GetFightTime()
    return XDataCenter.PivotCombatManager.GetFightTime(self.RankData.FightTimeScore)
end

return XPivotCombatRankItem