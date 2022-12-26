--虚像地平线活动对象
local XExpeditionActivity = XClass(nil, "XExpeditionActivity")
local XChapter = require("XEntity/XExpedition/XExpeditionChapter")
--================
--构造函数
--================
function XExpeditionActivity:Ctor()
    self:Init()
end
--================
--初始化
--================
function XExpeditionActivity:Init()
    self.CurrentChapterOrderId = 1
    self.RecruitLevel = 1 --招募等级
    self.RecruitTimes = 0 --剩余时间回复的可招募的次数
    self.NextRecruitAddTime = 0 --下一次自然恢复招募点时间
    self.ExtraDrawTimes = 0 --额外可招募的次数
    self.RecruitNum = 0 --已经招募过的次数
    self.ResetTime = 0 --重置时间
    self.DailyLikeCount = 0 --每天留言板可点赞次数，功能暂时已弃用
    self.Wave = 0
    self.ActivityCfg = XExpeditionConfig.GetExpeditionConfigById() --不填ID表示取默认最新
end
--================
--设置活动ID
--@param activityId:活动ID
--================
function XExpeditionActivity:SetActivityId(activityId)
    self.ActivityCfg = XExpeditionConfig.GetExpeditionConfigById(activityId)
end
--================
--刷新活动参数
--@param data:服务器通知的活动参数
--================
function XExpeditionActivity:RefreshActivity(data)
    self.ResetTime = data.ResetTime
    self.DailyLikeCount = data.DailyLikeCount
    self:UpdateRecruitTimes(data)
end
--================
--刷新招募相关参数
--================
function XExpeditionActivity:UpdateRecruitTimes(data, checkLevel)
    self.RecruitTimes = data.CanRefreshTimes or 0
    self.NextRecruitAddTime = data.RefreshTimesRecoveryTime or 0
    self.BuyRecruitTime = data.BuyRefreshTimes or 0
    self.ExtraDrawTimes = data.ExtraRefreshTimes or 0
    self.RecruitNum = data.RefreshTimes or 0
    self.Wave = data.NpcGroup or self.Wave
    local isRecruitLevelUp = false
    if checkLevel then
        isRecruitLevelUp = self.RecruitLevel < data.RecruitLevel
    end
    self.RecruitLevel = data.RecruitLevel or 0
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_EXPEDITION_RECRUITTIME_REFRESH, isRecruitLevelUp)
end
--================
--获取时间ID
--================
function XExpeditionActivity:GetActivityTimeId()
    return self.ActivityCfg and self.ActivityCfg.TimeId
end
--================
--获取活动名称
--================
function XExpeditionActivity:GetActivityName()
    return self.ActivityCfg and self.ActivityCfg.Name
end
--================
--获取活动入口图片路径
--================
function XExpeditionActivity:GetBannerTexturePath()
    return self.ActivityCfg and self.ActivityCfg.BannerTexturePath
end
--================
--设置现在的章节Id并刷新
--@param chapterId:现在的章节序号
--================
function XExpeditionActivity:SetChapterOrderId(chapterId)
    self.CurrentChapterOrderId = chapterId
    self:RefreshChapter()
    XDataCenter.ExpeditionManager.GetTeam():InitTeamPos(chapterId or 1)
end
--================
--获取现在的章节Id
--================
function XExpeditionActivity:GetCurrentChapterId()
    local chapterIds = self.ActivityCfg.ChapterIds
    if not chapterIds then return end
    if not chapterIds[self.CurrentChapterOrderId] then return chapterIds[1] end
    return chapterIds[self.CurrentChapterOrderId]
end
--================
--刷新章节
--================
function XExpeditionActivity:RefreshChapter()
    if not self.Chapter then
        self.Chapter = XChapter.New(self:GetCurrentChapterId())
        self.Chapter:SetNightMareWave(self.Wave)
    else
        self.Chapter:RefreshChapter(self:GetCurrentChapterId())
        self.Chapter:SetNightMareWave(self.Wave)
    end
end
--================
--获取章节对象
--================
function XExpeditionActivity:GetCurrentChapter()
    return self.Chapter
end
--================
--获取玩家螺母购买招募机会的购买次数
--================
function XExpeditionActivity:GetBuyRecruitTimes()
    return self.BuyRecruitTime or 0
end
--================
--获取下次自然恢复时间点
--================
function XExpeditionActivity:GetNextRecruitAddTime()
    return self.NextRecruitAddTime or 0
end
--================
--获取招募数量
--================
function XExpeditionActivity:GetRecruitNum()
    return self.RecruitNum or 0
end
--================
--获取招募等级
--================
function XExpeditionActivity:GetRecruitLevel()
    return self.RecruitLevel or 1
end
--================
--获取当前招募次数
--================
function XExpeditionActivity:GetRecruitTimes()
    return self.RecruitTimes or 0
end
--================
--获取额外招募次数
--================
function XExpeditionActivity:GetExtraRecruitTimes()
    return self.ExtraDrawTimes or 0
end
--================
--获取当前招募次数
--================
function XExpeditionActivity:GetTotalRecruitTimes()
    return self:GetRecruitTimes() + self:GetExtraRecruitTimes()
end
--================
--获取当前招募上限次数
--================
function XExpeditionActivity:GetRecruitMaxTime()
    return self.ActivityCfg and self.ActivityCfg.RecruitMaxNum
end
--================
--获取当前招募次数展示字符串
--================
function XExpeditionActivity:GetRecruitTimesStr()
    return string.format("%d/%d", self:GetTotalRecruitTimes(), self:GetRecruitMaxTime())
end
--================
--获取本次活动一次招募的数量
--================
function XExpeditionActivity:GetRecruitDrawNum()
    return self.ActivityCfg and self.ActivityCfg.RecruitDrawNum
end
--================
--获取本次活动一次招募的数量
--================
function XExpeditionActivity:GetRecruitTimeFull()
    return self:GetRecruitTimes() >= self:GetRecruitMaxTime()
end
--================
--获取当前章节无尽关卡波数
--================
function XExpeditionActivity:GetWave()
    return self:GetCurrentChapter():GetNightMareWave()
end
--================
--设置当前章节无尽关卡波数
--@param wave:波数
--================
function XExpeditionActivity:SetWave(wave)
    self.Wave = wave
    self:GetCurrentChapter():SetNightMareWave(wave)
end
--================
--获取是否有招募次数
--================
function XExpeditionActivity:GetCanRecruit()
    return self:GetTotalRecruitTimes() > 0
end
--================
--获取能不能螺母买抽卡
--================
function XExpeditionActivity:GetCanBuyDraw()
    return self:GetBuyRecruitTimes() < XExpeditionConfig.GetBuyDrawMaxTime()
end
--================
--获取重置时间
--================
function XExpeditionActivity:GetResetTime()
    return self.ResetTime
end
--================
--获取TimeId
--================
function XExpeditionActivity:GetTimeId()
    return self.ActivityCfg and self.ActivityCfg.TimeId
end
--================
--获取每日点赞
--================
function XExpeditionActivity:GetDailyLikeMaxNum()
    return self.ActivityCfg and self.ActivityCfg.DailyLikeMaxNum
end
--================
--刷新排行榜数据
--================
function XExpeditionActivity:UpdateRankingData(rankingData)
    self.SelfRank = rankingData.Ranking
    self.TotalRankPlayers = rankingData.TotalCount
    self.RankingList = rankingData.RankList
end
--================
--刷新我的排行榜数据
--================
function XExpeditionActivity:UpdateMyRankingData(rankingData)
    self.SelfRank = rankingData.Ranking
    self.TotalRankPlayers = rankingData.TotalCount
end
--================
--获取自身排行数
--================
function XExpeditionActivity:GetSelfRank()
    return self.SelfRank or 0
end
--================
--获取排行榜总玩家数
--================
function XExpeditionActivity:GetTotalRankPlayers()
    return self.TotalRankPlayers > 0 and self.TotalRankPlayers or 1
end
--================
--获取自己排行数字符串
--================
function XExpeditionActivity:GetSelfRankStr()
    local selfR = self:GetSelfRank()
    if selfR == 0 then return CS.XTextManager.GetText("ExpeditionNoRanking") end
    if selfR ~= 0 and selfR <= 100 then return selfR end 
    local percent = selfR / self:GetTotalRankPlayers()
    local result = math.ceil(percent * 100)
    return string.format("%d%s", (result > 99 and 99 or result), "%")
end
--================
--获取前百排行榜数据
--================
function XExpeditionActivity:GetRankingList()
    return self.RankingList or {}
end
--================
--获取排位图片
--================
function XExpeditionActivity:GetRankSpecialIcon(ranking)
    if not self.ActivityCfg then return nil end
    local maxNum = self.ActivityCfg.RankIcon and #self.ActivityCfg.RankIcon or 0
    return maxNum > 0 and self.ActivityCfg.RankIcon[ranking] or nil
end
return XExpeditionActivity