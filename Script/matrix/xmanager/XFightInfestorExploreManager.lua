XFightInfestorExploreManagerCreator = function()
    local XFightInfestorExploreManager = {}

    local math = math
    local RULER_PAGE_NUM = CS.XGame.ClientConfig:GetInt("FightInfestorScoreRulerMinCount")
    local SCORE_GAP = CS.XGame.ClientConfig:GetFloat("FightInfestorPanelScoreGap")
    local PLAYER_SCORE_LIMIT = CS.XGame.ClientConfig:GetFloat("FightInfestorPlayerScoreLimit")

    local MyScore = 0
    local BaseScore = 0
    local StageId = 0
    local ScoreRule = nil
    local DamageMaxScore = nil
    local HpMaxScore = nil
    local UseTimeMaxScore = nil
    local TotalMaxScore = nil

    XFightInfestorExploreManager.COLLECT_SCORE_TIME = 1000 -- 列表刷新时间(ms)

    function XFightInfestorExploreManager.Init()
        CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FIGHT_EXIT, XFightInfestorExploreManager.OnFightExit)
    end

    function XFightInfestorExploreManager.OnFightExit()
        XLuaUiManager.Remove("UiFightInfestorExplore")
    end

    -- CS CALL
    function XFightInfestorExploreManager.ShowPanel(active, stageId)
        if active then
            if XFightInfestorExploreManager.InitData(stageId) then
                XLuaUiManager.Open("UiFightInfestorExplore")
            end
        else
            XLuaUiManager.Close("UiFightInfestorExplore")
        end
    end

    function XFightInfestorExploreManager.InitData(stageId)
        if not CS.XFight.Instance then
            XLog.Error("不在战斗中,无法打开UiFightInfestorExplore" )
            return false
        end
        StageId = stageId or CS.XFight.Instance.FightData.StageId
        ScoreRule =  XFubenInfestorExploreConfigs.GetScoreRuleConfig(StageId)
        if not ScoreRule then
            return false
        end
        DamageMaxScore = ScoreRule.DamageMaxScore > 0 and ScoreRule.DamageMaxScore or XMath.IntMax()
        HpMaxScore = ScoreRule.HpMaxScore > 0 and ScoreRule.HpMaxScore or XMath.IntMax()
        UseTimeMaxScore = ScoreRule.UseTimeMaxScore > 0 and ScoreRule.UseTimeMaxScore or XMath.IntMax()
        TotalMaxScore = ScoreRule.TotalMaxScore > 0 and ScoreRule.TotalMaxScore or XMath.IntMax()

        SCORE_GAP = XDataCenter.FubenInfestorExploreManager.GetDiffShowScoreGap()
        PLAYER_SCORE_LIMIT = XDataCenter.FubenInfestorExploreManager.GetDiffShowScoreLimit()

        local myTotalScore = XDataCenter.FubenInfestorExploreManager.GetPlayerScore(XPlayer.Id)
        local stageScore = XDataCenter.FubenInfestorExploreManager.GetChapter2StageScore(StageId)
        BaseScore = myTotalScore - stageScore
        MyScore = BaseScore
        if BaseScore < 0 then
            XLog.Error("初始化分数<0 stageId:" .. StageId .. ", stageScore:" .. tostring(stageScore))
        end
        return true
    end

    function XFightInfestorExploreManager.GetScore()
        return MyScore
    end

    function XFightInfestorExploreManager.SetScore(score)
        MyScore = score
    end

    function XFightInfestorExploreManager.CalcScore(score)
        local fightInstance = CS.XFight.Instance
        if not fightInstance then
            score = score + 1000
        else
            local totalDamage = fightInstance.Result:CollectTotalDamage()
            local leftHpRate = fightInstance.Result:CollectLeftHpRate()
            local usedTime = fightInstance.Result:CollectUsedTime()

            local damageScore = math.min(totalDamage * ScoreRule.DamageFactor, DamageMaxScore)
            local hpScore = math.min(leftHpRate * ScoreRule.HpFactor, HpMaxScore)
            local useTimeScore = math.min(usedTime * ScoreRule.UseTimeFactor, UseTimeMaxScore)
            score = BaseScore + math.min(math.ceil(damageScore + hpScore + useTimeScore), TotalMaxScore)
            -- XLog.Debug(" scoreData =  " .. score, {leftHpRate, totalDamage, usedTime, damageScore, hpScore, useTimeScore})
        end
        return score
    end

    function XFightInfestorExploreManager.GetScoreGap()
        return SCORE_GAP
    end

    function XFightInfestorExploreManager.GetScoreFloor(score)
        score = score or XFightInfestorExploreManager.GetScore()
        local leftScore = score % SCORE_GAP
        return score - leftScore
    end

    function XFightInfestorExploreManager.GetScoreStr(score)
        score = score or XFightInfestorExploreManager.GetScore()
        return CS.XTextManager.GetText("InfestorFightScoreName") .. XFightInfestorExploreManager.NomalizeScoreStr(score) -- "当前讨伐值:"
    end

    function XFightInfestorExploreManager.NomalizeScoreStr(score)
        if score >= 10000 then
            return math.floor(score / 1000) / 10 .. "W"
        end
        return score
    end

    function XFightInfestorExploreManager.GetRulerList(playerList)
        local rulerList = {}
        local scoreFloor = XFightInfestorExploreManager.GetScoreFloor()
        local maxScore = 0
        for _, data in ipairs(playerList) do
            if data:GetScore() > maxScore then
                maxScore = data:GetScore()
            end
        end
        local rulerNum = math.ceil((maxScore -scoreFloor) / SCORE_GAP) + 1
        rulerNum = math.max(rulerNum, RULER_PAGE_NUM)
        for i = rulerNum, 1, -1 do
            local score = scoreFloor + SCORE_GAP * i
            local scoreStr = XFightInfestorExploreManager.NomalizeScoreStr(score)
            table.insert(rulerList, scoreStr)
        end
        return rulerList
    end

    -----------  玩家数据 begin-----------
    local PlayerData = XClass(nil, "PlayerData")

    function PlayerData:Ctor(index, infestorExplorePlayer)
        self.index = index
        self.name = infestorExplorePlayer:GetName()
        local shortName = string.Utf8Sub(self.name, 1, 4)
        if self.name ~= shortName then
            self.name = shortName .. "..."
        end
        self.score = infestorExplorePlayer:GetScore()
        self.Icon = infestorExplorePlayer:GetHeadIcon()
        self.posRate = 0 -- 刻度倍数（以最小刻度开始）
    end
    function PlayerData:GetName() return self.name end
    function PlayerData:GetScore() return self.score end
    function PlayerData:GetScoreStr() return XFightInfestorExploreManager.NomalizeScoreStr(self.score) end
    function PlayerData:GetPosRate() return self.posRate end
    function PlayerData:SetPosRate(rate) self.posRate = rate end
    function PlayerData:GetIcon() return self.Icon end

    function XFightInfestorExploreManager.GetPlayerList()
        local playerList = {}
        local indexList = XDataCenter.FubenInfestorExploreManager.GetPlayerRankIndexList()
        local list = {}
        local playerId = XPlayer.Id
        for _, index in ipairs(indexList) do
            local infestorExplorePlayer = XDataCenter.FubenInfestorExploreManager.GetPlayerRankData(index)
            if infestorExplorePlayer then
                if infestorExplorePlayer:GetPlayerId() ~= playerId and 
                        infestorExplorePlayer:GetScore() >= PLAYER_SCORE_LIMIT then
                    table.insert(list, infestorExplorePlayer)
                end
            end
        end

        for _, infestorExplorePlayer in ipairs(list) do
            table.insert(playerList, PlayerData.New(index, infestorExplorePlayer))
        end
        -- 计算位置数据
        local score = XFightInfestorExploreManager.GetScore()
        local scoreFloor = XFightInfestorExploreManager.GetScoreFloor()
        for _, data in ipairs(playerList) do
            if data:GetScore() > score then
                local posRate = (data:GetScore() - scoreFloor) / SCORE_GAP
                data:SetPosRate(posRate)
            end
        end
        return playerList
    end
    ----------- 玩家数据 end

    XFightInfestorExploreManager.Init()
    return XFightInfestorExploreManager
end