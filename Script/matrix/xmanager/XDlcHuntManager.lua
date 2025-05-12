local XExFubenSimulationChallengeManager = require("XEntity/XFuben/XExFubenSimulationChallengeManager")
local XDlcHuntChapter = require("XEntity/XDlcHunt/XDlcHuntChapter")
local XDlcHuntWorld = require("XEntity/XDlcHunt/XDlcHuntWorld")
local XDlcHuntSettle = require("XEntity/XDlcHunt/XDlcHuntSettle")
local XDlcHuntPlayerDetail = require("XEntity/XDlcHunt/XDlcHuntPlayerDetail")

XDlcHuntManagerCreator = function()
    local _Chapters = false
    local _Worlds = {}
    local _Rank = {}
    local _PassedWorld = {}
    local _GainAssistPoint = 0
    local _GainSocialAssistPoint = 0
    local _HasReceiveAssistPoint = false

    local RequestProto = {
        RankData = "DlcRankingRequest",
        PlayerDetail = "QueryPlayerDlcChipRequest",
        ReceiveAssistPoint = "DlcReceiveAssistPointRequest",
    }

    local config = XFubenConfigs.GetChapterBannerByType(XFubenConfigs.ChapterType.DlcHunt)
    ---@class XDlcHuntManager
    local XDlcHuntManager = XExFubenSimulationChallengeManager.New(XFubenConfigs.ChapterType.DlcHunt, config)

    function XDlcHuntManager.InitDataFromServer(data)
        if XDlcHuntManager.IsOpen() then
            XMVCA.XDlcRoom:InitFight()
        end
        -- expired
        if data.DlcPlayerData then
            XDlcHuntManager.SetDlcPlayerData(data.DlcPlayerData)
        end
        if data.DlcCharacterList then
            XDataCenter.DlcHuntCharacterManager.InitDataFromServer(data.DlcCharacterList)
        end

        if data.DlcChipList then
            XDataCenter.DlcHuntChipManager.InitDataFromServer(data.DlcChipList)
        end
    end

    function XDlcHuntManager.SetWorldPassed(worldId)
        _PassedWorld[worldId] = true
    end

    function XDlcHuntManager.SetDlcPlayerData(data)
        _PassedWorld = {}
        for i, worldId in pairs(data.PassWorldId) do
            XDlcHuntManager.SetWorldPassed(worldId)
        end

        _GainAssistPoint = data.GainAssistPoint or 0
        _GainSocialAssistPoint = data.GainSocialAssistPoint or 0
        _HasReceiveAssistPoint = data.HasReceiveAssistPoint or false
    end

    function XDlcHuntManager.IsGainAssistPointMax()
        return _GainAssistPoint >= XDlcHuntConfigs.GetWeekGainAssistLimit()
    end

    function XDlcHuntManager.IsGainSocialAssistPointMax()
        return _GainSocialAssistPoint >= XDlcHuntConfigs.GetWeekGainSocialAssistLimit()
    end

    function XDlcHuntManager.OpenMain()
        if not XDlcHuntManager.IsOpen() then
            XUiManager.TipText("CommonActivityNotStart")
            return
        end
        --活动分包资源检测
        if not XMVCA.XSubPackage:CheckSubpackage() then
            return
        end
        XLuaUiManager.Open("UiDlcHuntMain")
    end

    function XDlcHuntManager.OpenUiObtain(...)
        -- 等待父级ui中列表异步刷新完成，以保证弹窗的截图效果正常
        if XUiManager.IsTableAsyncLoading() then
            local params = { ... }
            XUiManager.WaitTableLoadComplete(function()
                XLuaUiManager.Open("UiDlcRwlTip", table.unpack(params))
            end)
        else
            XLuaUiManager.Open("UiDlcRwlTip", ...)
        end
    end

    function XDlcHuntManager.IsOpen()
        return XDlcHuntManager.ExCheckInTime(XDlcHuntManager)
    end

    function XDlcHuntManager.ExCheckInTime()
        local timeId = XDlcHuntConfigs.GetTimeId()
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    function XDlcHuntManager.IsShowRedDotTask()
        return true
    end

    function XDlcHuntManager.GetAllChapters()
        if not _Chapters then
            _Chapters = {}
            local allChapter = XDlcHuntWorldConfig.GetAllChapter()
            for chapterId, config in pairs(allChapter) do
                _Chapters[chapterId] = XDlcHuntChapter.New(chapterId)
            end
        end
        return _Chapters
    end

    ---@return XDlcHuntChapter
    function XDlcHuntManager.GetChapter(chapterId)
        return XDlcHuntManager.GetAllChapters()[chapterId]
    end

    ---@return XDlcHuntWorld
    function XDlcHuntManager.GetWorld(worldId)
        if not XDlcHuntWorldConfig.IsWorldExist(worldId) then
            return false
        end
        if not _Worlds[worldId] then
            _Worlds[worldId] = XDlcHuntWorld.New(worldId)
        end
        return _Worlds[worldId]
    end

    function XDlcHuntManager.IsPassed(worldId)
        return _PassedWorld[worldId]
    end

    function XDlcHuntManager.GetRankTab()
        local result = {}
        local difficultyConfigs = XDlcHuntWorldConfig.GetAllChapter()
        for chapterId, chapterConfig in pairs(difficultyConfigs) do
            local chapter = XDataCenter.DlcHuntManager.GetChapter(chapterId)
            if chapter:IsRank() then
                result[#result + 1] = {
                    ChapterId = chapterId,
                    Name = chapterConfig.Name
                }
            end
        end
        table.sort(result, function(a, b)
            return a.ChapterId < b.ChapterId
        end)
        return result
    end

    function XDlcHuntManager.GetRankData(chapterId)
        return _Rank[chapterId]
    end

    function XDlcHuntManager.RequestRank(chapterId)
        local rankData = XDlcHuntManager.GetRankData(chapterId)
        if rankData then
            if XTime.GetServerNowTimestamp() - rankData.RequestTime < 30 then
                return
            end
        end

        XNetwork.Call(RequestProto.RankData, {
            ChapterId = chapterId,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local rankInfo = res.BossRankInfo
            local list = {}
            local myData = false
            local myPlayerId = XPlayer.Id

            for key, teamData in pairs(rankInfo.RankTeamInfos) do
                local worldId = teamData.WorldId or 1
                local members = {}
                for i = 1, #teamData.PlayerInfo do
                    local player = teamData.PlayerInfo[i]
                    local npcId = player.CharacterId
                    local characterId = XDlcHuntCharacterConfigs.GetCharacterIdByNpcId(npcId)
                    members[#members + 1] = {
                        Name = player.Name,
                        Icon = characterId ~= 0 and XDlcHuntCharacterConfigs.GetCharacterIcon(characterId) or "",
                        PlayerId = player.Id,
                        IsLeader = player.TeamId > 0,
                    }
                end
                local data = {
                    Rank = teamData.Rank,
                    Time = XUiHelper.GetTime(teamData.FinishTime, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND),
                    DifficultyName = XDlcHuntWorldConfig.GetWorldDifficultyName(worldId),
                    Members = members
                }
                list[#list + 1] = data
            end
            table.sort(list, function(a, b)
                return a.Rank < b.Rank
            end)

            for i = 1, #list do
                local data = list[i]
                local isFind = false
                for j = 1, #data.Members do
                    local member = data.Members[j]
                    if member.PlayerId == myPlayerId then
                        myData = data
                        isFind = true
                        break
                    end
                end
                if isFind then
                    break
                end
            end

            _Rank[chapterId] = {
                List = list,
                MyData = myData,
                RequestTime = XTime.GetServerNowTimestamp(),
            }
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_RANK_UPDATE)
        end)
    end

    -- 预处理结算数据
    function XDlcHuntManager.OnNotifyFightSettle(result)
        if XLuaUiManager.IsUiShow("UiSet") then
            XLuaUiManager.Close("UiSet")
        else
            XLuaUiManager.Remove("UiSet")
        end

        ---@type XDlcHuntSettle
        local settle = XDlcHuntSettle.New()
        settle:SetData(result)
        if settle.IsWin then
            XDataCenter.DlcHuntManager.SetWorldPassed(settle.WorldId)

            if XLuaUiManager.IsUiShow("UiBiancaTheatreBlack") then
                XLuaUiManager.PopThenOpen("UiDlcHuntSettlement", settle)
            else
                XLuaUiManager.Open("UiDlcHuntSettlement", settle)
            end
        else
            if settle:IsFail4FightingPower() then
                if XLuaUiManager.IsUiShow("UiBiancaTheatreBlack") then
                    XLuaUiManager.PopThenOpen("UiDlcHuntPowerSettleLose", settle)
                else
                    XLuaUiManager.Open("UiDlcHuntPowerSettleLose", settle)
                end
            else
                if XLuaUiManager.IsUiShow("UiBiancaTheatreBlack") then
                    XLuaUiManager.PopThenOpen("UiDlcHuntSettleLose", settle)
                else
                    XLuaUiManager.Open("UiDlcHuntSettleLose", settle)
                end
            end
        end
    end

    function XDlcHuntManager.OpenPlayerDetail(playerId)
        if not playerId then
            return
        end
        playerId = tonumber(playerId)
        XNetwork.Call(RequestProto.PlayerDetail, {
            PlayerId = playerId,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            ---@type XDlcHuntPlayerDetail
            local dataDetail = XDlcHuntPlayerDetail.New()
            dataDetail:SetData(res)
            XLuaUiManager.Open("UiDlcHuntPlayerInfo", dataDetail)
        end)
    end

    function XDlcHuntManager.ReceiveAssistPointRequest()
        if _HasReceiveAssistPoint then
            return
        end
        if XDlcHuntManager.IsGainSocialAssistPointMax() then
            return
        end
        XNetwork.Call(RequestProto.ReceiveAssistPoint, {}, function(res)
            _HasReceiveAssistPoint = true
            if res.Code ~= XCode.Success then
                --XUiManager.TipCode(res.Code)
                return
            end
            --local itemData = XDataCenter.ItemManager.GetItemTemplate(res.ItemId)
            --local item = XItem.New(nil, itemData)
            --item:SetCount(res.ItemCount)
            --XLuaUiManager.Open("UiDlcHuntTip", item)
            local rewardGoodList = {
                {
                    RewardType = XRewardManager.XRewardType.Item,
                    TemplateId = res.ItemId,
                    Count = res.ItemCount
                }
            }
            XDlcHuntManager.OpenUiObtain(rewardGoodList, XUiHelper.GetText("DlcHuntAssistPointReward"))
        end)
    end

    return XDlcHuntManager
end

-- XRpc.DlcBossSettleResponse = function(res)
--     XDataCenter.DlcHuntManager.OnNotifyFightSettle(res.SettleData)
-- end

XRpc.NotifyDlcPlayerDataDb = function(res)
    XDataCenter.DlcHuntManager.SetDlcPlayerData(res.DlcPlayerData)
end