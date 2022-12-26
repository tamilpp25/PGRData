local XNameplate = require("XEntity/XNameplate/XNameplate")
XMedalManagerCreator = function()
    local tableInsert = table.insert

    local XMedalManager = {}

    local METHOD_NAME = {
        ScoreTitleShowSetRequest = "ScoreTitleShowSetRequest",
        CollectionShowSetRequest = "CollectionShowSetRequest",
        WearNameplateRequest = "WearNameplateRequest",
    }

    XMedalManager.InType = { Normal = 1, GetMedal = 2, OtherPlayer = 3 }

    XMedalManager.MedalStroyId = CS.XGame.ClientConfig:GetInt("MedalStoryId")

    local NewMedalId = nil

    local ScoreTitleUnLockList = {}     -- 收藏品ID为索引，存放服务器下发的解锁收藏品

    local MedalList = {}
    local ScoreTitleList = {}           -- Type索引数组，数组存放收藏品配置
    local ScoreTitleDataList = {}       -- 收藏品ID为索引，存放收藏品配置
    local ScoreTitleShowStateList = {}
    local NewCollectionList = {}
    local QualityUpCollectionList = {}
    local IsCanCheckQualityUp

    local BaseIconWidth                 -- 基准图标宽度
    local DEFAULT_BASE_ICON_WIDHT = 160 -- 默认基准图标宽度(玩家信息的收藏品页签中的格子)

    function XMedalManager.Init()
        XMedalManager.InitScoreTitleList()
        XMedalManager.InitMedalList()
        IsCanCheckQualityUp = true
    end

    function XMedalManager.GetMedals()
        table.sort(MedalList, function(headA, headB)
            local weightA = headA.IsLock and 0 or 1
            local weightB = headB.IsLock and 0 or 1
            if weightA == weightB then
                return headA.Priority > headB.Priority
            end
            return weightA > weightB
        end)
        return MedalList
    end

    function XMedalManager.GetMedalById(id)
        for _, medal in pairs(MedalList) do
            if medal.Id == id then
                return medal
            end
        end
        return nil
    end

    function XMedalManager.InitMedalList()
        local meadalsCfg = XMedalConfigs.GetMeadalConfigs()
        for _, meadal in pairs(meadalsCfg or {}) do

            local tmp = {}
            for k, v in pairs(meadal) do
                tmp[k] = v
            end
            tmp["Type"] = XMedalConfigs.MedalType.Normal
            tmp["IsLock"] = true
            tmp["Time"] = 0
            tmp["Num"] = 0
            table.insert(MedalList, tmp)
        end
    end

    function XMedalManager.CreateOtherPlayerMedalList(medalInfos)
        if not medalInfos then
            return {}
        end
        local meadalsCfg = XMedalConfigs.GetMeadalConfigs()
        local othermedalList = {}
        for _, Info in pairs(medalInfos) do
            local cfg = meadalsCfg[Info.Id]
            if cfg then
                local tmp = {}
                for k, v in pairs(cfg) do
                    tmp[k] = v
                end
                tmp["Type"] = XMedalConfigs.MedalType.Normal
                tmp["IsLock"] = false
                tmp["Time"] = Info.Time
                tmp["Num"] = Info.Num
                othermedalList[tmp.Id] = tmp
            end
        end
        return othermedalList
    end

    function XMedalManager.UpdateMedalList()
        for _, medal in pairs(MedalList) do
            local medalInfo = XPlayer.UnlockedMedalInfos[medal.Id]
            if medalInfo then
                medal.IsLock = false
                medal.Time = medalInfo.Time
                medal.Num = medal.Num
            end
        end
    end

    function XMedalManager.GetMeadalInfoById(Id)
        return XPlayer.UnlockedMedalInfos[Id]
    end

    function XMedalManager.GetMeadalMaxCount()
        local maxCount = 0
        local medalsList = XMedalConfigs.GetMeadalConfigs()
        for _, _ in pairs(medalsList or {}) do
            maxCount = maxCount + 1
        end
        return maxCount
    end

    function XMedalManager.CheckMedalStoryIsPlayed()
        if XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "MedalStoryIsPlayed")) then
            return true
        end
        return false
    end

    function XMedalManager.MarkMedalStory()
        if not XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "MedalStoryIsPlayed")) then
            XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "MedalStoryIsPlayed"), "MedalStoryIsPlayed")
        end
    end

    function XMedalManager.CheckHaveNewMedal()
        local meadals = XMedalConfigs.GetMeadalConfigs()
        if not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Medal) then
            if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Medal) then
                for _, v in pairs(meadals) do
                    if XSaveTool.GetData(string.format("%d%s%d%d", XPlayer.Id, "NewMeadal", v.Id, XMedalConfigs.MedalType.Normal)) then
                        return true
                    end
                end
            end
        end
        if not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Collection) then
            if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Collection) then
                for _, v in pairs(ScoreTitleDataList) do
                    if XSaveTool.GetData(string.format("%d%s%d%d", XPlayer.Id, "NewMeadal", v.Id, v.Type)) then
                        return true
                    end
                end
            end
        end

        if XMedalManager.CkeckHaveNewNameplate() then
            return true
        end
        return false
    end

    function XMedalManager.CheckHaveNewMedalByType(type)
        local meadals = XMedalConfigs.GetMeadalConfigs()
        if type == XMedalConfigs.ViewType.Medal then
            if not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Medal) then
                if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Medal) then
                    for _, v in pairs(meadals) do
                        if XSaveTool.GetData(string.format("%d%s%d%d", XPlayer.Id, "NewMeadal", v.Id, XMedalConfigs.MedalType.Normal)) then
                            return true
                        end
                    end
                end
            end
        else
            if not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Collection) then
                if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Collection) then
                    for _, v in pairs(ScoreTitleDataList) do
                        if XSaveTool.GetData(string.format("%d%s%d%d", XPlayer.Id, "NewMeadal", v.Id, v.Type)) then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    function XMedalManager.CheckIsNewMedalById(Id, type)
        if XSaveTool.GetData(string.format("%d%s%d%d", XPlayer.Id, "NewMeadal", Id, type)) then
            return true
        end
        return false
    end

    function XMedalManager.SetMedalForOld(Id, type)
        if XSaveTool.GetData(string.format("%d%s%d%d", XPlayer.Id, "NewMeadal", Id, type)) then
            XSaveTool.RemoveData(string.format("%d%s%d%d", XPlayer.Id, "NewMeadal", Id, type))
            XEventManager.DispatchEvent(XEventId.EVENT_MEDAL_REDPOINT_CHANGE)
        end
    end

    function XMedalManager.AddNewMedal(Id, type)
        if not XSaveTool.GetData(string.format("%d%s%d%d", XPlayer.Id, "NewMeadal", Id, type)) then
            XSaveTool.SaveData(string.format("%d%s%d%d", XPlayer.Id, "NewMeadal", Id, type), Id)
        end
    end

    function XMedalManager.ShowUnlockTips()
        if NewMedalId then
            XLuaUiManager.Open("UiMedalUnlockTips", NewMedalId)
            NewMedalId = nil
            return true
        end
        return false
    end

    function XMedalManager.SetNewMedalId(id)
        NewMedalId = id
    end

    ------------------------------------------计分徽章--------------------------------->>>
    function XMedalManager.InitScoreTitleList()
        local scoreTitlesCfg = XMedalConfigs.GetScoreTitlesConfigs()
        for _, scoreTitle in pairs(scoreTitlesCfg or {}) do

            if not ScoreTitleList[scoreTitle.Type] then
                ScoreTitleList[scoreTitle.Type] = {}
            end

            local tmp = {}
            for k, v in pairs(scoreTitle) do
                tmp[k] = v
            end

            tmp["IsLock"] = true
            tmp["Quality"] = scoreTitle.InitQuality
            tmp["Score"] = 0
            tmp["Time"] = 0

            table.insert(ScoreTitleList[scoreTitle.Type], tmp)

        end
        for _, type in pairs(ScoreTitleList) do
            XMedalConfigs.SortByPriority(type)
            for _, scoreTitle in pairs(type) do
                ScoreTitleDataList[scoreTitle.Id] = scoreTitle
                if not ScoreTitleShowStateList[scoreTitle.Type] then
                    ScoreTitleShowStateList[scoreTitle.Type] = {}
                    ScoreTitleShowStateList[scoreTitle.Type].Type = scoreTitle.Type
                    ScoreTitleShowStateList[scoreTitle.Type].Hide = XMedalConfigs.Hide.OFF
                end
            end
        end
    end

    function XMedalManager.CreateOtherPlayerScoreTitleList(titleInfos)
        if not titleInfos then
            return {}
        end
        local scoreTitlesCfg = XMedalConfigs.GetScoreTitlesConfigs()
        local otherScoreTitleList = {}
        for _, Info in pairs(titleInfos) do
            local cfg = scoreTitlesCfg[Info.Id]
            if cfg then
                local tmp = {}
                for k, v in pairs(cfg) do
                    tmp[k] = v
                end
                tmp["IsLock"] = false
                tmp["Quality"] = Info.Quality
                tmp["Score"] = Info.Score
                tmp["Time"] = Info.Time
                if Info.ExpandInfo then
                    tmp["ExpandInfo"] = Info.ExpandInfo
                end
                table.insert(otherScoreTitleList, tmp)
            end
        end
        return XMedalConfigs.SortByPriority(otherScoreTitleList)
    end

    function XMedalManager.CreateOtherPlayerScoreTitle(titleInfo)
        if not titleInfo then
            return
        end

        local scoreTitlesCfg = XMedalConfigs.GetScoreTitlesConfigs()
        local cfg = scoreTitlesCfg[titleInfo.Id]
        if cfg then
            local tmp = {}
            for k, v in pairs(cfg) do
                tmp[k] = v
            end
            tmp["IsLock"] = false
            tmp["Quality"] = titleInfo.Quality
            tmp["Score"] = titleInfo.Score
            tmp["Time"] = titleInfo.Time
            if titleInfo.ExpandInfo then
                tmp["ExpandInfo"] = titleInfo.ExpandInfo
            end
            return tmp
        end
    end

    function XMedalManager.GetScoreTitle(type)
        local list = {}

        if type then
            local titleList = ScoreTitleList[type]
            if titleList then
                for _, scoreTitle in pairs(titleList) do
                    if not scoreTitle.IsLock or scoreTitle.ShowType ~= 0 then
                        table.insert(list, scoreTitle)
                    end
                end
            end
            return list
        end

        for _, tmpType in pairs(ScoreTitleList) do
            for _, scoreTitle in pairs(tmpType) do
                if not scoreTitle.IsLock or scoreTitle.ShowType ~= 0 then
                    tableInsert(list, scoreTitle)
                end
            end
        end

        return XMedalConfigs.SortByPriority(list)
    end

    function XMedalManager.GetScoreTitleByScreenType(screenType)
        local list = {}
        for _, tmpType in pairs(ScoreTitleList) do
            for _, scoreTitle in pairs(tmpType) do
                if (not scoreTitle.IsLock or scoreTitle.ShowType ~= 0) then
                    local isHasScreenType = screenType and screenType > 0
                    local isSameScreenType = scoreTitle.ScreenType == screenType
                    if not isHasScreenType or (isHasScreenType and isSameScreenType) then
                        tableInsert(list, scoreTitle)
                    end
                end
            end
        end

        local resultList = XMedalManager.UpgradeCollection(list)
        return XMedalConfigs.SortByPriority(resultList)
    end

    function XMedalManager.GetScoreTitleById(id)
        for _, tmpType in pairs(ScoreTitleList) do
            for _, scoreTitle in pairs(tmpType) do
                if scoreTitle.Id == id then
                    return scoreTitle
                end
            end
        end
    end

    ---==========================================
    --- 检查传入的 ‘oriList’数组 是否有需要升级的收藏品
    --- 更高级收藏品是一个独立的收藏品，有自己的收藏品Id
    --- 更高级收藏品会覆盖低级收藏品，需要把低级收藏品隐藏(去除)
    ---@return table
    ---==========================================
    function XMedalManager.UpgradeCollection(oriList)
        if oriList == nil or next(oriList) == nil then
            return oriList
        end

        local resultList = {}
        local groupIdIndex = {} -- GroupId做索引，存放相应的收藏品组

        -- 区分需要升级与不需要升级的收藏品
        for _, scoreTitle in pairs(oriList) do
            if scoreTitle.GroupId == 0 or scoreTitle.GroupId == nil then
                -- 收藏品不可以升级，不需要判断显隐
                tableInsert(resultList, scoreTitle)
            else
                -- 相同组的收藏品放在同一个GroupId表
                if groupIdIndex[scoreTitle.GroupId] == nil then
                    groupIdIndex[scoreTitle.GroupId] = {}
                end
                tableInsert(groupIdIndex[scoreTitle.GroupId], scoreTitle)
            end
        end

        -- 选出每个Group中最高级的收藏品
        for _, group in pairs(groupIdIndex) do
            table.sort(group, function(scoreTitle1, scoreTitle2)
                if scoreTitle1.GroupLv == nil then
                    XLog.Error("XMedalManager.UpgradeCollection函数错误，收藏品" .. scoreTitle1.Id .. "的GroupLv为空")
                    return
                elseif scoreTitle2.GroupLv == nil then
                    XLog.Error("XMedalManager.UpgradeCollection函数错误，收藏品" .. scoreTitle2.Id .. "的GroupLv为空")
                    return
                end

                -- 按GroupLv降序排序
                return scoreTitle1.GroupLv > scoreTitle2.GroupLv
            end)

            -- 将最高级的收藏品放入返回结果中
            tableInsert(resultList, group[1])
        end

        return resultList
    end

    function XMedalManager.GetMedalData(scoreTitleId)
        local scoreTitleData = ScoreTitleDataList[scoreTitleId]
        return scoreTitleData
    end

    function XMedalManager.GetMedalImg(scoreTitleId)
        local scoreTitleData = ScoreTitleDataList[scoreTitleId]
        return scoreTitleData and scoreTitleData.MedalImg
    end

    function XMedalManager.GetScore(scoreTitleId)
        local scoreTitleData = ScoreTitleDataList[scoreTitleId]
        return scoreTitleData and scoreTitleData.Score or 0
    end

    function XMedalManager.GetMedalType(scoreTitleId)
        local scoreTitleData = ScoreTitleDataList[scoreTitleId]
        return scoreTitleData and scoreTitleData.Type or 0
    end

    function XMedalManager.GetQuality(scoreTitleId)
        local scoreTitleData = ScoreTitleDataList[scoreTitleId]
        return scoreTitleData and (scoreTitleData.Quality or scoreTitleData.InitQuality) or 0
    end

    function XMedalManager.GetIsLock(scoreTitleId)
        local scoreTitleData = ScoreTitleDataList[scoreTitleId]
        return scoreTitleData and scoreTitleData.IsLock or false
    end

    ---
    --- 获取'minQuality'与'maxQuality'(包括min与max)区间品质的收藏品id数组
    --- 如果只有一个参数，则获取这个品质的收藏品id数组
    ---@param minQuality number
    ---@param maxQuality number
    ---@return table
    function XMedalManager.GetScoreTitleByQuality(minQuality, maxQuality)
        local list = {}
        if not minQuality and not maxQuality then
            XLog.Error("XMedalManager.GetScoreTitleByQuality函数错误，参数不能全部都为 nil")
            return
        end

        -- 解锁的收藏品配置
        local unLockList = {}
        for _, scoreTitle in pairs(ScoreTitleDataList) do
            if (not scoreTitle.IsLock) then
                tableInsert(unLockList, scoreTitle)
            end
        end
        -- 合并同一个组的收藏品
        local upgradeList = XMedalManager.UpgradeCollection(unLockList)

        for _, scoreTitle in pairs(upgradeList) do
            if maxQuality then
                if (scoreTitle.Quality or scoreTitle.InitQuality) <= maxQuality
                and (scoreTitle.Quality or scoreTitle.InitQuality) >= minQuality then
                    table.insert(list, scoreTitle)
                end
            else
                if (scoreTitle.Quality or scoreTitle.InitQuality) == minQuality then
                    table.insert(list, scoreTitle)
                end
            end
        end

        return list
    end

    function XMedalManager.GetLevelIcon(scoreTitleId, curQuality)
        local collectionLevel = XMedalConfigs.GetCollectionDefaultLevelConfigs()
        local ScoreTitles = XMedalConfigs.GetScoreTitlesConfigs()
        local levelIcon = nil
        local curIndex = 0
        local qualities = ScoreTitles[scoreTitleId].Qualities
        if qualities and #qualities > 0 then
            for index, quality in pairs(qualities) do
                if quality == curQuality then
                    curIndex = index
                end
                for _, level in pairs(collectionLevel) do
                    if level.CurLevel == curIndex and level.MaxLevel == #qualities then
                        levelIcon = level.Icon
                        break
                    end
                end
            end
        end
        return levelIcon
    end

    function XMedalManager.GetScoreTitleShowState()
        return XTool.Clone(ScoreTitleShowStateList)
    end

    function XMedalManager.GetScoreTitleUnLockList()
        return XTool.Clone(ScoreTitleUnLockList)
    end

    function XMedalManager.CheckCanGetNewCollection()
        if #NewCollectionList == 0 then
            return false
        else
            local list = {}
            for _, collectionId in pairs(NewCollectionList) do
                tableInsert(list, XRewardManager.CreateRewardGoods(collectionId))
            end
            XLuaUiManager.Open("UiObtainCollection", list)
            XMedalManager.ClearCollectionList()
            return true
        end
    end

    function XMedalManager.CheckQualityUpCollection()
        if not QualityUpCollectionList or not next(QualityUpCollectionList) or not IsCanCheckQualityUp then
            return
        else
            IsCanCheckQualityUp = false
            local key, value = next(QualityUpCollectionList)
            if key then
                XLuaUiManager.Open("UiUpgradeCollection", key, value, function()
                    IsCanCheckQualityUp = true
                    XMedalManager.ClearQualityUpCollectionById(key)
                    XMedalManager.CheckQualityUpCollection()
                end)
            end
        end
    end

    function XMedalManager.ClearCollectionList()
        NewCollectionList = {}
    end

    function XMedalManager.GetScoreTitleIconById(id)
        if not id then
            return nil
        end
        return ScoreTitleDataList[id] and ScoreTitleDataList[id].MedalIcon or nil
    end

    function XMedalManager.CheckScoreTitleIsShow(type)
        local state = ScoreTitleShowStateList[type]
        if not state then
            return false
        end
        return state.Hide == XMedalConfigs.Hide.OFF
    end

    function XMedalManager.CheckScoreTitleIsHaveById(id)
        return ScoreTitleUnLockList[id] and true or false
    end

    function XMedalManager.CheckHaveScoreTitleType(type)
        return ScoreTitleList[type] and true or false
    end

    function XMedalManager.CheckScoreTitleInTimeByType(type)
        local scoreTitle = ScoreTitleList[type]
        if not scoreTitle then
            return false
        end
        for _, title in pairs(scoreTitle) do
            local nowTime = XTime.GetServerNowTimestamp()
            local beginTime, endTime = XFunctionManager.GetTimeByTimeId(title.TimeId)
            if nowTime > beginTime and nowTime < endTime then
                return true
            end
        end
        return false
    end

    function XMedalManager.UpdateScoreTitle()
        for _, scoreTitle in pairs(ScoreTitleUnLockList) do
            local scoreTitleData = ScoreTitleDataList[scoreTitle.Id]
            if scoreTitleData then
                scoreTitleData.IsLock = false
                scoreTitleData.Quality = scoreTitle.Quality
                scoreTitleData.Score = scoreTitle.Score
                scoreTitleData.Time = scoreTitle.Time
                if scoreTitle.ExpandInfo then
                    scoreTitleData.ExpandInfo = scoreTitle.ExpandInfo
                end
            end
        end
    end

    function XMedalManager.UpdateScoreTitleShowState(hideTypes)
        for _, hideType in pairs(hideTypes or {}) do
            local scoreTitleShowState = ScoreTitleShowStateList[hideType]
            if scoreTitleShowState then
                scoreTitleShowState.Hide = XMedalConfigs.Hide.ON
            end
        end
    end

    function XMedalManager.SetScoreTitleUnLockList(scoreTitleInfoList)
        for _, scoreTitle in pairs(scoreTitleInfoList or {}) do
            ScoreTitleUnLockList[scoreTitle.Id] = scoreTitle
        end
    end

    function XMedalManager.AddScoreTitleUnLockList(titles, IsLogined)
        for _, scoreTitleInfo in pairs(titles) do
            local scoreTitleData = ScoreTitleDataList[scoreTitleInfo.Id]
            if scoreTitleData then
                local scoreTitleUnLock = ScoreTitleUnLockList[scoreTitleInfo.Id]
                if not scoreTitleUnLock then
                    scoreTitleUnLock = scoreTitleInfo
                    XDataCenter.MedalManager.AddNewMedal(scoreTitleInfo.Id, scoreTitleData.Type)
                    if scoreTitleData.IsNotShowGetTip ~= 1 then
                        table.insert(NewCollectionList, scoreTitleInfo.Id)
                    end
                    ScoreTitleUnLockList[scoreTitleInfo.Id] = scoreTitleUnLock
                else
                    scoreTitleUnLock.Score = scoreTitleInfo.Score
                    if scoreTitleUnLock.Quality ~= scoreTitleInfo.Quality then

                        if scoreTitleData.ShowQualityUpTip == XMedalConfigs.ShowScore.ON then
                            local qualityUpCollection = QualityUpCollectionList[scoreTitleInfo.Id]
                            if not qualityUpCollection then
                                qualityUpCollection = {}
                                qualityUpCollection.BeforeQuality = scoreTitleUnLock.Quality
                                qualityUpCollection.AfterQuality = scoreTitleInfo.Quality
                                QualityUpCollectionList[scoreTitleInfo.Id] = qualityUpCollection
                            else
                                qualityUpCollection.AfterQuality = scoreTitleInfo.Quality
                            end
                        end
                        scoreTitleUnLock.Quality = scoreTitleInfo.Quality
                        XDataCenter.MedalManager.AddNewMedal(scoreTitleInfo.Id, scoreTitleData.Type)
                    end
                end
            else
                XLog.Error("Share/ScoreTitle/ScoreTitle.tab 表中不存在 ScoreTitleId: " .. scoreTitleInfo.Id)
            end
        end

        if #NewCollectionList > 0 and IsLogined then
            XEventManager.DispatchEvent(XEventId.EVENT_SCORETITLE_NEW)
        end
    end

    function XMedalManager.ClearQualityUpCollectionById(id)
        if QualityUpCollectionList[id] then
            QualityUpCollectionList[id] = nil
        end
    end

    function XMedalManager.SetScoreTitleShowData(list)
        for _, showSetInfo in pairs(list or {}) do
            local scoreTitleShowState = ScoreTitleShowStateList[showSetInfo.Type]
            if scoreTitleShowState then
                scoreTitleShowState.Hide = showSetInfo.Hide
            end
        end
    end

    function XMedalManager.SetScoreTitleShow(list, cb)
        XNetwork.Call(METHOD_NAME.ScoreTitleShowSetRequest, { ScoreTitleShowSetInfos = list }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XMedalManager.SetScoreTitleShowData(list)
            if cb then
                cb()
            end
        end)
    end

    -- 设置基准图标宽度
    function XMedalManager.SetBaseIconWidth(baseIconWidth)
        BaseIconWidth = baseIconWidth
    end

    -- 获取基准图标宽度
    function XMedalManager.GetBaseIconWidth()
        return BaseIconWidth or DEFAULT_BASE_ICON_WIDHT
    end

    ---==========================================
    --- 根据'score'的位数和图标宽度‘iconWidth’来得到相应字号
    ---@param score number
    ---@param iconWidth number
    ---@return number
    ---==========================================
    function XMedalManager.GetScoreSize(score, iconWidth)
        if score == nil or score == 0 then
            return nil
        end

        local digit = math.floor(math.log(score, 10) + 1)
        if digit > #XMedalConfigs.EnumCollectionScoreTextSize then
            XLog.Warning("XMedalManager.GetScoreSize函数警告,分数" .. tostring(score) .. "位数大于ClientConfig配置的位数字号")
        end

        -- 得到基准图标宽度和基准位数字号，基准位数字号通过配表读取
        local baseIconWidth = XMedalManager.GetBaseIconWidth()
        local baseScoreSize = XMedalConfigs.EnumCollectionScoreTextSize[digit]
        or XMedalConfigs.EnumCollectionScoreTextSize[#XMedalConfigs.EnumCollectionScoreTextSize]

        if baseIconWidth == 0 then
            XLog.Error("XMedalManager.GetScoreSize函数错误,baseIconWidth为0")
            return nil
        end

        -- 根据比例来算出当前图标宽度对应的字号大小
        return math.floor((baseScoreSize * iconWidth) / baseIconWidth)
    end

    ---
    --- 设置特定收藏品的最大分数
    --- 把'13006500'机械扭蛋收藏品的最大分数限制为100
    --- 【1.21分支之后优化此代码】
    function XMedalManager.SetSpecificMaxScore(titleInfos)
        if titleInfos then
            for _, titleInfo in pairs(titleInfos) do
                if titleInfo.Id == 13006500 then
                    if titleInfo.Score >= 100 then
                        titleInfo.Score = 100
                    end
                end
                if titleInfo.Id == 13007500 then
                    if titleInfo.Score >= 50 then
                        titleInfo.Score = 50
                    end
                end
            end
        end
    end

    ------------------------------------------计分徽章---------------------------------<<<
    ------------------------------------------铭牌--------------------------------------
    local NameplateIdDic = {}
    local NameplateGroupDic = {}
    local NameplateSaveDic = {}
    local NameplateRedPointDic = {}
    local NameplateLastEqu = {}
    local CurWearNameplate = 0 --当前穿戴的铭牌
    local UiNameplateIsOpen = false
    --登陆下推
    function XMedalManager.AsyncNameplateLogin(data)
        CurWearNameplate = data.CurrentWearNameplate
        XMedalManager.InitNameplateSaveRedDic()
        NameplateSaveDic = {}
        for _, info in ipairs(data.UnlockNameplates) do
            XMedalManager.UpdateNameplate(info, true)
            NameplateSaveDic[info.Id] = true
        end
        --登陆时对红点的处理
        local redChange = false
        local tmpNameplatePoint = {}
        for nameplateId, _ in pairs(NameplateRedPointDic) do
            if not NameplateIdDic[nameplateId] or NameplateIdDic[nameplateId]:IsNamepalteExpire() then
                tmpNameplatePoint[nameplateId] = nil
                if tmpNameplatePoint[nameplateId] then
                    redChange = true
                end
            else
                if not tmpNameplatePoint[nameplateId] then
                    redChange = true
                end
                tmpNameplatePoint[nameplateId] = true
            end
        end

        if redChange then
            NameplateRedPointDic = tmpNameplatePoint 
            XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "NameplateRedPointDic"), NameplateRedPointDic)
        end
        
        XEventManager.DispatchEvent(XEventId.EVENT_NAMEPLATE_CHANGE)
    end

    --服务端下推处理 铭牌更新
    function XMedalManager.AsyncUpateNameplate(data)
        --XLog.Debug("AsyncUpateNameplate", data)
        XMedalManager.UpdateNameplate(data)
    end

    --服务端下推处理（真实处理数据）
    function XMedalManager.UpdateNameplate(data, isLogin)
        local nameplateData, lastNameplateData
        local redChange = false
        local haveNameplateUp = false
        local isGetNameplateNew = false
        local NameplateGroupId = XMedalConfigs.GetNameplateGroup(data.Id)
        if not NameplateGroupDic[NameplateGroupId] then
            nameplateData = XNameplate.New(data)
            haveNameplateUp = true
        else
            lastNameplateData = NameplateGroupDic[NameplateGroupId]
            if isLogin then
                XLog.Error("铭牌数据异常,请服务端检查:", "LastId: " ,lastNameplateData:GetNameplateId(), "Id: ", data.Id, "GroupId: ", NameplateGroupId)
            end
            if lastNameplateData:GetNameplateId() == data.Id then
                if lastNameplateData:IsNamepalteExpire() then --如果过期的刷新时间 可以重新激活红点
                    isGetNameplateNew = true
                    if CurWearNameplate and CurWearNameplate == lastNameplateData:GetNameplateId() then--如果当前存储的已佩戴铭牌过期 重新设置缓存
                        CurWearNameplate = 0
                    end
                end
                nameplateData = NameplateGroupDic[NameplateGroupId]
                nameplateData:UpdateData(data)
            else
                if lastNameplateData:IsNamepalteExpire() then --如果当前存储的已佩戴铭牌过期 重新设置缓存
                    if CurWearNameplate and CurWearNameplate == lastNameplateData:GetNameplateId() then
                        CurWearNameplate = 0
                    end
                end
                nameplateData = XNameplate.New(data)
                --if lastNameplateData:GetNameplateQuality() < nameplateData:GetNameplateQuality() then
                    if nameplateData:GetNameplateUpgradeType() == XMedalConfigs.NameplateGetType.TypeFour then --如果铭牌类型是转换道具 暂时不删除信息 帮助转换道具的下推保存数据

                    else
                        NameplateIdDic[lastNameplateData:GetNameplateId()] = nil --如果铭牌发生变化，清理上一次的更新
                    end
                    if lastNameplateData:GetNameplateId() == CurWearNameplate then
                        CurWearNameplate = nameplateData:GetNameplateId()
                    end

                    if NameplateRedPointDic[lastNameplateData:GetNameplateId()] then
                        NameplateSaveDic[lastNameplateData:GetNameplateId()] = true
                        NameplateRedPointDic[lastNameplateData:GetNameplateId()] = nil
                        redChange = true
                    end
                    haveNameplateUp = true
                -- else
                --     NameplateSaveDic[data.Id] = true
                -- end
            end
        end

        --铭牌发生替换时 处理保存的逻辑
        if haveNameplateUp then
            NameplateIdDic[data.Id] = nameplateData
            NameplateGroupDic[NameplateGroupId] = nameplateData
        end


        if not isLogin then
            if not NameplateSaveDic[data.Id] or isGetNameplateNew then --如果本地没有存储过这个铭牌的信息或者是新获得的记录红点
                if not NameplateRedPointDic[data.Id] then
                    redChange = true
                end
                NameplateRedPointDic[data.Id] = true
            end

            if (not nameplateData:IsNamepalteExpire() and nameplateData:GetNameplateUpgradeType() ~= XMedalConfigs.NameplateGetType.TypeFour)  --如果获得的铭牌没有过期，并且不是转换道具的铭牌 进入弹窗逻辑
            or ((haveNameplateUp or isGetNameplateNew) and nameplateData:GetNameplateUpgradeType() == XMedalConfigs.NameplateGetType.TypeFour) --如果是转换道具的铭牌并且铭牌是新获得或者升级 进入弹窗逻辑
            then
                if isGetNameplateNew then
                    lastNameplateData = nil
                end
                XLuaUiManager.Open("UiObtainNameplate", nameplateData, lastNameplateData)
                UiNameplateIsOpen = true
            end

            if redChange then
                XEventManager.DispatchEvent(XEventId.EVENT_NAMEPLATE_CHANGE)
                XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "NameplateRedPointDic"), NameplateRedPointDic)
            end
        end

    end

    --服务端下推处理 铭牌转换道具
    function XMedalManager.NameplateConvertItem(data)
        local nameplateData = NameplateIdDic[data.NameplateId]
        NameplateIdDic[data.NameplateId] = nil
        if not nameplateData then
            local groupId = XMedalConfigs.GetNameplateGroup(data.NameplateId)
            local dataByGroup = NameplateGroupDic[groupId]
            local tmpData = {}
            tmpData.Id = data.NameplateId
            tmpData.Exp = 0
            tmpData.EndTime = dataByGroup and dataByGroup:GetNamepalteEndTime() or 0
            tmpData.GetTime = dataByGroup and dataByGroup:GetNamepalteGetTime() or 0
            nameplateData = XNameplate.New(tmpData)
        end
        XLuaUiManager.Open("UiObtainNameplate", nameplateData, false, data.ConvertItem, data.ConvertCount)

        -- if UiNameplateIsOpen then
        --     local tmpData = {}
        --     tmpData.NameplateData = nameplateData
        --     tmpData.ConvertItem = data.ConvertItem
        --     tmpData.ConvertCount = data.ConvertCount
        --     table.insert(NameplateLastEqu, tmpData)
        -- else
        --     if not nameplateData then
        --         local tmpData = {}
        --         tmpData.Id = data.NameplateId
        --         tmpData.Exp = 0
        --         tmpData.EndTime = 0
        --         tmpData.GetTime = 0
        --         nameplateData = XNameplate.New(tmpData)
        --     end
        --     XLuaUiManager.Open("UiObtainNameplate", nameplateData, false, data.ConvertItem, data.ConvertCount)
        --     UiNameplateIsOpen = true
        -- end 
    end

    --获取铭牌数据列表（真实数据信息
    function XMedalManager.GetNameplateGroupList()
        local nameplateGroup = {}
        for _, data in pairs(NameplateGroupDic) do
            table.insert(nameplateGroup, data)
        end
        table.sort(nameplateGroup, function(a, b)
            if a:IsNameplateNew() and not b:IsNameplateNew() then
                return true
            elseif a:IsNameplateNew() == b:IsNameplateNew() then
                if a:IsNameplateDress() and not b:IsNameplateDress() then
                    return true
                elseif a:IsNameplateDress() == b:IsNameplateDress() then
                    -- if not a:IsNamepalteExpire() and b:IsNamepalteExpire() then
                    --     return true
                    -- elseif a:IsNamepalteExpire() == b:IsNamepalteExpire() then
                    --     return a:GetNameplateId() < b:GetNameplateId()
                    -- end
                    if a:IsNamepalteForever() and not b:IsNamepalteForever() then
                        return true
                    elseif a:IsNamepalteForever() == b:IsNamepalteForever() then
                        if a:GetNamepalteLeftTime() > b:GetNamepalteLeftTime() then
                            return true
                        elseif a:GetNamepalteLeftTime() == b:GetNamepalteLeftTime() then
                            return a:GetNameplateId() < b:GetNameplateId()
                        end
                    end
                end
            end
            return false
        end)
        return nameplateGroup
    end

    --打开获取铭牌界面（栈方式 暂时废弃
    function XMedalManager.OpenNextUiObtainNameplate()
        UiNameplateIsOpen = false
        if #NameplateLastEqu > 0 then
            local tmpData = table.remove(NameplateLastEqu, 1)
            XLuaUiManager.Open("UiObtainNameplate", tmpData.NameplateData, false, tmpData.ConvertItem, tmpData.ConvertCount)
        end
    end

    --根据GroupId获取服务端推送的铭牌实体数据
    function XMedalManager.CheckNameplateGroupUnluck(group)
        return NameplateGroupDic[group]
    end

    --获取当前装备的铭牌
    function XMedalManager.GetNameplateCurId()
        return CurWearNameplate
    end

    --检查是不是新获得的铭牌（红点）
    function XMedalManager.CheckNameplateNew(id)
        if not NameplateRedPointDic[id] then
            return false
        end
        return true
    end

    --初始化本地持久化数据的红点信息
    function XMedalManager.InitNameplateSaveRedDic()
        --NameplateSaveDic = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "NameplateSaveDic")) or {}
        NameplateRedPointDic = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "NameplateRedPointDic")) or {}
    end

    --根据规则处理红点的隐藏
    function XMedalManager.SetNameplateRedPointDic(id)
        local needChangeRed = false
        if not id then
            for _, nameplateData in pairs(NameplateGroupDic) do
                if NameplateRedPointDic[nameplateData:GetNameplateId()] then
                    needChangeRed = true
                end
                NameplateSaveDic[nameplateData:GetNameplateId()] = true
                NameplateRedPointDic[nameplateData:GetNameplateId()] = nil
            end
        else
            if NameplateRedPointDic[id] then
                NameplateSaveDic[id] = true
                NameplateRedPointDic[id] = nil
                needChangeRed = true
            end
        end

        if needChangeRed then
            --XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "NameplateSaveDic"), NameplateSaveDic)
            XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "NameplateRedPointDic"), NameplateRedPointDic)
            XEventManager.DispatchEvent(XEventId.EVENT_NAMEPLATE_CHANGE)
        end
    end

    function XMedalManager.CheckHaveNewNameplateById(id)
        return NameplateRedPointDic[id]
    end

    --检查是否有新的铭牌
    function XMedalManager.CkeckHaveNewNameplate()
        if not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Nameplate) then
            if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Nameplate) then
                for _, data in pairs(NameplateGroupDic) do
                    if data:IsNameplateNew() then
                        return true
                    end
                end
            end
        end
        return false
    end

    --佩戴铭牌请求
    function XMedalManager.WearNameplate(nameplateId, cb)
        XNetwork.Call(METHOD_NAME.WearNameplateRequest, { NameplateId = nameplateId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            CurWearNameplate = nameplateId
            if cb then
                cb()
            end
            XEventManager.DispatchEvent(XEventId.EVENT_NAMEPLATE_CHANGE)
        end)
    end

    ------------------------------------------铭牌--------------------------------------
    XMedalManager.Init()
    return XMedalManager
end

XRpc.NotifyMedalData = function(data)
    if not data then
        return
    end
    XPlayer.AsyncMedalIds(data.MedalInfos, false)
    XDataCenter.MedalManager.UpdateMedalList()
end

XRpc.NotifyUpdateMedalData = function(data)
    if not data then
        return
    end
    XPlayer.AsyncMedalIds(data.UpdateInfo, true)
    XDataCenter.MedalManager.SetNewMedalId(data.UpdateInfo.Id)
    XDataCenter.MedalManager.UpdateMedalList()
    --CheckPoint: APPEVENT_BADGE
    XAppEventManager.MedalAppLogEvent(data.UpdateInfo.Id)
    XEventManager.DispatchEvent(XEventId.EVENT_MEDAL_NOTIFY)
end

XRpc.NotifyScoreTitleData = function(data)
    XDataCenter.MedalManager.SetSpecificMaxScore(data.TitleInfos)
    XDataCenter.MedalManager.SetScoreTitleUnLockList(data.TitleInfos)
    XDataCenter.MedalManager.UpdateScoreTitleShowState(data.HideTypes)
    XDataCenter.MedalManager.UpdateScoreTitle()

    -- 全部已解锁的收藏品墙与装饰品数据
    XDataCenter.CollectionWallManager.SyncWallEntityData(data.WallInfos)
    XDataCenter.CollectionWallManager.SyncDecorationData(data.UnlockedDecorationIds)
end

XRpc.NotifyScoreTitleInfo = function(data)
    XDataCenter.MedalManager.SetSpecificMaxScore(data.Titles)
    XDataCenter.MedalManager.AddScoreTitleUnLockList(data.Titles, data.IsLogined)
    XDataCenter.MedalManager.UpdateScoreTitle()
    XEventManager.DispatchEvent(XEventId.EVENT_SCORETITLE_CHANGE)
end

--铭牌登陆下推
XRpc.NotifyNameplateLoginData = function(data)
    XDataCenter.MedalManager.AsyncNameplateLogin(data)
end

--铭牌信息改变下推
XRpc.NotifyNameplateInfo = function(data)
    if data.Nameplate then
        XDataCenter.MedalManager.AsyncUpateNameplate(data.Nameplate)
    end
end

--铭牌信息改变下推
XRpc.NotifyNameplateConvertItem = function(data)
    XDataCenter.MedalManager.NameplateConvertItem(data)
end