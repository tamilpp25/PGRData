--===========================
--超限乱斗排行榜管理器
--模块负责：吕天元
--===========================
local XSmashBRankingManager = {}
--=============
--排位列表
--XSuperSmashBrosRankPlayer
--int PlayerId
--string Name
--int Head
--int Frame
--int Level
--string Sign
--int Score
--int WinCount
--int SpendTime
--List<int> CharacterIdList
--=============
local RankingList
local MyRankInfo
local MyRank
local TotalRankMemberCount
local GetRankFlag
--local GetMyRankFlag
--=============
--初始化管理器
--=============
function XSmashBRankingManager.Init()
    RankingList = {}
    MyRankInfo = {}
    MyRank = {}
    TotalRankMemberCount = 0
    GetRankFlag = {}
    --GetMyRankFlag = false
end
--=============
--刷新后台推送排行榜数据
--=============
function XSmashBRankingManager.RefreshRankingData(career, rankData)
    local data = rankData.Rank
    RankingList[career] = data.RankPlayer
    MyRankInfo[career] = {}
    MyRank[career] = rankData.Ranking
    TotalRankMemberCount = rankData.MemberCount
    for ranking, info in pairs(RankingList[career] or {}) do
        if info.PlayerId == XPlayer.Id then
            MyRankInfo[career] = info
        end
    end
end
--=============
--获取排行榜数据
--=============
function XSmashBRankingManager.GetRankingList(career, cb)
    if not GetRankFlag[career] then
        XDataCenter.SuperSmashBrosManager.GetRankingInfo(career, function()
                GetRankFlag[career] = true
                XSmashBRankingManager.GetRankingList(career, cb)
            end)
        return
    end
    GetRankFlag[career] = false
    if cb then
        cb(RankingList[career])
    end
end
--=============
--获取排行榜排位特殊图标
--=============
function XSmashBRankingManager.GetRankingSpecialIcon(ranking)
    local rankIcons = XDataCenter.SuperSmashBrosManager.GetRankingIcons()
    local maxNum = rankIcons and #rankIcons or 0
    return maxNum > 0 and rankIcons[ranking] or nil
end
--=============
--获取自己的排位队伍第一个成员的图标
--=============
function XSmashBRankingManager.GetRankingCaptainIcon(career)
    local charaId = MyRankInfo and MyRankInfo[career] and MyRankInfo[career].CharacterIdList and MyRankInfo[career].CharacterIdList[1].Id
    local chara = XDataCenter.SuperSmashBrosManager.GetRoleById(charaId)
    return chara and chara:GetBigHeadIcon()
end
--=============
--获取玩家自己的排位(缓存在本地的，之前需要先跟后端获取)
--=============
function XSmashBRankingManager.GetMyRank(career)
    local myRank = MyRank[career] or 0
    if not myRank or myRank == 0 then return 0 end
    if myRank <= 100 then return myRank end
    local percent = myRank / TotalRankMemberCount
    local result = math.ceil(percent * 100)
    return string.format("%d%s", (result > 99 and 99 or result), "%")
end
--=============
--跟后端获取玩家自己的排位
-- -------------------- abandon ----------------
--=============
--function XSmashBRankingManager.GetMyRankByNet(cb)
--    if not GetMyRankFlag then
--        XDataCenter.SuperSmashBrosManager.GetRankingInfo(function()
--                GetMyRankFlag = true
--                XSmashBRankingManager.GetMyRankByNet(cb)
--            end)
--        return
--    end
--    GetMyRankFlag = false
--    if cb then
--        cb(XSmashBRankingManager.GetMyRank())
--    end
--end

return XSmashBRankingManager