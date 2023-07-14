local tableInsert = table.insert

XNoticeManagerCreator = function()
    local Json = require("XCommon/Json")
    local pcall = pcall
    local XNoticeManager = {}

    local NoticePicList = {}

    local NowTextNotice = nil
    local NowPicNotice = nil

    local InGameNoticeReadList = {}
    local InGameNoticeMap = {}
    local InGameNoticeReadKey = "_InGameNoticeReadKey"

    local SubMenuNoticeReadList = {}
    local SubMenuNoticeMap = {}
    local SubMenuNoticeReadKey = "_SubMenuNoticeReadKey"

    local ScrollCountList = {}
    local ScrollCountSaveKey = "_NoticeScrollCountList"

    local LoginNotice = nil
    local LoginNoticeTimeInfo = {}
    local LoginNoticeCacheKey = "LoginNotice"

    local TextNoticeHideCache = {}
    local TextNoticeHideCacheKey = "_TextNotice"
    ------------------------------------------------------
    local NoticeRequestTimer = nil
    -- 向服务端请求数据的最小间隔周期（秒）
    local NoticeRequestTimerInterval = 10
    local NoticeRequestTimeOut = 30
    
    local DefaultTextScrollInterval = 10

    local ScreenShotFlag = false

    -- local XNoticeStatus =   {
    --     -- 未发布
    --     Unpublished = 0,
    --     -- 等待发布
    --     PublishWait = 1,
    --     -- 发布成功
    --     Published = 2,
    --     -- 发布失败
    --     PublishFail = 3,
    --     -- 过期
    --     OverTime = 4,
    -- }

    local XNoticeType = {
        -- 顶部文字滚动公告
        ScrollText = 0,
        -- 主界面广告图
        ScrollPic = 1,
        -- 游戏内公告
        InGame = 2,
        -- 登陆公告
        Login = 3,
        -- 主界面二级菜单
        SubMenu = 4,
    }

    -- 自动向服务端请求数据的间隔周期（秒）
    local RequestInterval = {
        [XNoticeType.ScrollText] = 30,
        [XNoticeType.ScrollPic] = 60,
        [XNoticeType.InGame] = 120,
        [XNoticeType.Login] = 0,
        [XNoticeType.SubMenu] = 120,
    }

    local LastRequestTime = {
        [XNoticeType.ScrollText] = 0,
        [XNoticeType.ScrollPic] = 0,
        [XNoticeType.InGame] = 0,
        [XNoticeType.SubMenu] = 0,
    }

    local NoticeRequestHandler = {
        [XNoticeType.ScrollText] = function(notice) XNoticeManager.HandleRequestScrollTextNotice(notice) end,
        [XNoticeType.ScrollPic] = function(notice) XNoticeManager.HandleRequestScrollPicNotice(notice) end,
        [XNoticeType.InGame] = function(notice) XNoticeManager.HandleRequestInGameNotice(notice) end,
        [XNoticeType.SubMenu] = function(notice) XNoticeManager.HandleRequestSubMenuNotice(notice) end,
    }

    local NoticeRequestFailHandler = {
        [XNoticeType.ScrollText] = function() XNoticeManager.HandleRequestScrollTextNotice() end,
        [XNoticeType.ScrollPic] = function() XNoticeManager.HandleRequestScrollPicNoticeFail() end,
        [XNoticeType.InGame] = function() XNoticeManager.HandleRequestInGameNotice() end,
        [XNoticeType.SubMenu] = function() XNoticeManager.HandleRequestSubMenuNotice() end,
    }

    -- local NoticeData = {
    --     [XNoticeType.ScrollText] = nil,
    --     [XNoticeType.ScrollPic] = nil,
    --     [XNoticeType.InGame] = nil,
    -- }

    ----------------------------------初始化公告cdn路径 beg----------------------------------
    local NoticeCdnUrl = {}
    local NoticeFileName = {
        [XNoticeType.ScrollText] = "ScrollTextNotice.json",
        [XNoticeType.ScrollPic] = "ScrollPicNotice.json",
        [XNoticeType.InGame] = "GameNotice.json",
        [XNoticeType.Login] = "LoginNotice.json",
        [XNoticeType.SubMenu] = "SecondMenuNotice.json",
    }

    function XNoticeManager.GetNoticeUrl(noticeType)
        return NoticeCdnUrl[noticeType]
    end

    function XNoticeManager.InitNoticeCdnUrl()
        local noticePathPrefix = CS.XGame.ClientConfig:GetString("NoticePathPrefix")
        for k, v in pairs(NoticeFileName) do
            NoticeCdnUrl[k] = noticePathPrefix .. CS.XInfo.Identifier .. "/" .. CS.XRemoteConfig.ApplicationVersion .. "/" .. v
        end
    end
    ----------------------------------初始化公告cdn路径 end----------------------------------
    ----------------------------------获取公网ip地址 beg----------------------------------
    local Ip = ""
    local IpUrlIndex = 0
    local IpUrls = {
        "https://ipv4.icanhazip.com/",
        "https://api.ipify.org/"
    }

    function XNoticeManager.RequestIp()
        IpUrlIndex = IpUrlIndex + 1
        if IpUrlIndex > #IpUrls then
            return
        end

        local request = CS.UnityEngine.Networking.UnityWebRequest.Get(IpUrls[IpUrlIndex])
        local requestEnd = function()
            if request.isNetworkError or request.isHttpError then
                XNoticeManager.RequestIp()
            end

            Ip = request.downloadHandler.text

            request:Dispose()
        end

        CS.XTool.WaitNativeCoroutine(request:SendWebRequest(), requestEnd)
    end

    function XNoticeManager.GetIp()
        return Ip
    end
    ----------------------------------获取公网ip地址 end----------------------------------
    --------------------------cache beg--------------------------
    function XNoticeManager.ReadTextNoticeHideCache()
        local cache = CS.UnityEngine.PlayerPrefs.GetString(tostring(XPlayer.Id) .. TextNoticeHideCacheKey)
        if string.IsNilOrEmpty(cache) then
            return
        end

        TextNoticeHideCache = Json.decode(cache)

        for k, v in pairs(TextNoticeHideCache) do
            if XTime.GetServerNowTimestamp() > v.EndTime then
                TextNoticeHideCache[k] = nil
            end
        end

    end

    function XNoticeManager.SaveTextNoticeHideCache()
        if not TextNoticeHideCache then
            return
        end

        CS.UnityEngine.PlayerPrefs.SetString(tostring(XPlayer.Id) .. TextNoticeHideCacheKey, Json.encode(TextNoticeHideCache))
        CS.UnityEngine.PlayerPrefs.Save()
    end
    
    function XNoticeManager.GetInGameNoticeReadKey()
        return tostring(XPlayer.Id) .. InGameNoticeReadKey
    end

    function XNoticeManager.SaveInGameNoticeReadList()
        if not InGameNoticeReadList then return end

        local saveContent = ""
        local splitMark = "\n"
        for _, v in pairs(InGameNoticeReadList) do
            local list = {}
            tableInsert(list, v.Id)
            tableInsert(list, v.Index)
            tableInsert(list, (v.IsRead and 1 or 0))
            tableInsert(list, v.EndTime)
            tableInsert(list, v.ModifyTime)

            local tempStr = table.concat(list, "\t")
            saveContent = string.format("%s%s%s", tempStr, splitMark, saveContent)
        end

        CS.UnityEngine.PlayerPrefs.SetString(XNoticeManager.GetInGameNoticeReadKey(), saveContent)
        CS.UnityEngine.PlayerPrefs.Save()

        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_NOTICE_READ_CHANGE)
    end

    function XNoticeManager.ReadInGameNoticeReadList()
        InGameNoticeReadList = {}
        if not CS.UnityEngine.PlayerPrefs.HasKey(XNoticeManager.GetInGameNoticeReadKey()) then
            return
        end

        local dataStr = CS.UnityEngine.PlayerPrefs.GetString(XNoticeManager.GetInGameNoticeReadKey())

        local msgTab = string.Split(dataStr, '\n')
        if not msgTab or #msgTab <= 0 then
            return
        end

        for _, content in ipairs(msgTab) do
            if (not string.IsNilOrEmpty(content)) then
                local tab = string.Split(content, '\t')
                if tab then
                    local readInfo = {
                        Id = tostring(tab[1]),
                        Index = tonumber(tab[2]),
                        IsRead = tonumber(tab[3]) > 0,
                        EndTime = tonumber(tab[4]),
                        ModifyTime = tonumber(tab[5]),
                    }
                    if readInfo.ModifyTime and readInfo.EndTime and readInfo.EndTime > XTime.GetServerNowTimestamp() then
                        local dataKey = XNoticeManager.GetGameNoticeReadDataKey(readInfo, readInfo.Index)
                        InGameNoticeReadList[dataKey] = readInfo
                    end
                end
            end
        end
    end

    function XNoticeManager.GetSubMenuNoticeReadKey()
        return tostring(XPlayer.Id) .. SubMenuNoticeReadKey
    end

    function XNoticeManager.SaveSubMenuNoticeReadList()
        if not SubMenuNoticeReadList then return end

        local saveContent = ""
        local splitMark = "\n"
        for _, v in pairs(SubMenuNoticeReadList) do
            local list = {}
            tableInsert(list, v.Id)
            tableInsert(list, v.EndTime)
            tableInsert(list, v.TipResetTime)
            tableInsert(list, v.LastReadTime)

            local tempStr = table.concat(list, "\t")
            saveContent = string.format("%s%s%s", tempStr, splitMark, saveContent)
        end
        -- XLog.Warning("save",saveContent)
        CS.UnityEngine.PlayerPrefs.SetString(XNoticeManager.GetSubMenuNoticeReadKey(), saveContent)
        CS.UnityEngine.PlayerPrefs.Save()

        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_SUBMENU_READ_CHANGE)
    end

    function XNoticeManager.ReadSubMenuNoticeReadList()
        SubMenuNoticeReadList = {}
        if not CS.UnityEngine.PlayerPrefs.HasKey(XNoticeManager.GetSubMenuNoticeReadKey()) then
            return
        end

        local dataStr = CS.UnityEngine.PlayerPrefs.GetString(XNoticeManager.GetSubMenuNoticeReadKey())

        local msgTab = string.Split(dataStr, '\n')
        if not msgTab or #msgTab <= 0 then
            return
        end

        for _, content in ipairs(msgTab) do
            if (not string.IsNilOrEmpty(content)) then
                local tab = string.Split(content, '\t')
                if tab then
                    local readInfo = {
                        Id = tostring(tab[1]),
                        EndTime = tonumber(tab[2]),
                        TipResetTime = tonumber(tab[3]),
                        LastReadTime = tonumber(tab[4]),
                    }
                    if readInfo.EndTime and readInfo.EndTime > XTime.GetServerNowTimestamp() then
                        SubMenuNoticeReadList[readInfo.Id] = readInfo
                    end
                end
            end
        end
        --XLog.Warning("ReadSubMenuNoticeReadList",SubMenuNoticeReadList)
    end

    function XNoticeManager.GetScrollCountSaveKey()
        return tostring(XPlayer.Id) .. ScrollCountSaveKey
    end

    function XNoticeManager.SaveScrollCountList()
        if not ScrollCountList then
            return
        end
        local saveContent = ''
        for _, v in pairs(ScrollCountList) do
            saveContent = saveContent .. v.id .. '\t'
            saveContent = saveContent .. v.maxCount .. '\t'
            saveContent = saveContent .. v.nowCount .. '\t'
            saveContent = saveContent .. v.overTime .. '\n'
        end

        CS.UnityEngine.PlayerPrefs.SetString(XNoticeManager.GetScrollCountSaveKey(), saveContent)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    function XNoticeManager.ReadScrollCountList()
        ScrollCountList = {}
        if not CS.UnityEngine.PlayerPrefs.HasKey(XNoticeManager.GetScrollCountSaveKey()) then
            return
        end
        local dataStr = CS.UnityEngine.PlayerPrefs.GetString(XNoticeManager.GetScrollCountSaveKey())
        local msgTab = string.Split(dataStr, '\n')
        if not msgTab or #msgTab <= 0 then
            return
        end

        for _, content in ipairs(msgTab) do
            if (not string.IsNilOrEmpty(content)) then
                local tab = string.Split(content, '\t')
                if tab then
                    local countInfo = {
                        id = tostring(tab[1]),
                        maxCount = tonumber(tab[2]),
                        nowCount = tonumber(tab[3]),
                        overTime = tonumber(tab[4]),
                    }
                    if countInfo.overTime and countInfo.overTime > XTime.GetServerNowTimestamp() then
                        ScrollCountList[countInfo.id] = countInfo
                    end
                end
            end
        end
    end
    --------------------------cache end--------------------------
    --------------------------text beg--------------------------
    function XNoticeManager.HandleRequestScrollTextNotice(notice)
        -- XLog.Warning("new text notice",notice)
        NowTextNotice = notice

        if not XNoticeManager.CheckTextNoticeValid(notice) then
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_NOTICE_CLOSE_TEXT_NOTICE)
        else
            XLuaUiManager.Open("UiNoticeTips")
        end

        if NowTextNotice then
            local key = XNoticeManager.GetTextNoticeKey(NowTextNotice)
            if not ScrollCountList or not ScrollCountList[key] then
                XNoticeManager.CreateDefaultScrollCountData(NowTextNotice)
            end
        end
    end

    function XNoticeManager.GetTextNoticeKey(notice)
        return notice.Id .. "_" .. notice.ModifyTime
    end

    function XNoticeManager.CreateDefaultScrollCountData(notice)
        local key = XNoticeManager.GetTextNoticeKey(notice)
        local countInfo = {
            id = key,
            maxCount = notice.ScrollTimes,
            nowCount = 0,
            overTime = notice.EndTime,
        }
        ScrollCountList[key] = countInfo
    end

    function XNoticeManager.CheckTextNoticeValid(notice)
        notice = notice or NowTextNotice

        if not XNoticeManager.CheckNoticeValid(notice) then
            return false
        end

        if not XNoticeManager.CheckTextNoticeHideCache(notice) then
            return false
        end

        if notice.ShowInFight < 1 and not CS.XFight.IsOutFight then
            return false
        end

        if notice.ShowInPhotograph < 1 and ScreenShotFlag then
            return false
        end

        local key = XNoticeManager.GetTextNoticeKey(notice)
        if ScrollCountList[key]
            and ScrollCountList[key].nowCount > ScrollCountList[key].maxCount then

            return false
        end

        return true
    end

    function XNoticeManager.GetTextNoticeContent()
        if not NowTextNotice then
            return
        end
        return NowTextNotice.Content
    end

    function XNoticeManager.AddTextNoticeCount()
        if not NowTextNotice then
            return
        end

        local key = XNoticeManager.GetTextNoticeKey(NowTextNotice)

        if not ScrollCountList[key] then
            XNoticeManager.CreateDefaultScrollCountData(NowTextNotice)
        end

        ScrollCountList[key].nowCount = ScrollCountList[key].nowCount + 1

        XNoticeManager.SaveScrollCountList()
    end

    function XNoticeManager.GetTextNoticeScrollInterval()
        if not NowTextNotice then
            return DefaultTextScrollInterval
        end
        return tonumber(NowTextNotice.ScrollInterval) or DefaultTextScrollInterval
    end


    function XNoticeManager.ChangeTextNoticeHideCache(notice)
        notice = notice or NowTextNotice
        if not notice then
            return
        end

        local key = XNoticeManager.GetTextNoticeKey(notice)
        if not TextNoticeHideCache[key] then
            TextNoticeHideCache[key] = {
                Id = key,
                IsHide = 1,
                EndTime = notice.EndTime
            }
        else
            TextNoticeHideCache[key].IsHide = not TextNoticeHideCache[key].IsHide
        end

        XNoticeManager.SaveTextNoticeHideCache()
    end


    function XNoticeManager.CheckTextNoticeHideCache(notice)
        notice = notice or NowTextNotice
        if not notice then
            return false
        end

        local key = XNoticeManager.GetTextNoticeKey(notice)
        if not TextNoticeHideCache[key] then
            return true
        end

        return TextNoticeHideCache[key].IsHide < 0
    end
    --------------------------text end--------------------------
    ----------------------Scroll Pic beg----------------------

    function XNoticeManager.HandleRequestScrollPicNoticeFail()
        if not NowPicNotice then
            return
        end

        NowPicNotice = nil

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_NOTICE_PIC_CHANGE)
    end

    function XNoticeManager.HandleRequestScrollPicNotice(notice)
        if not notice then
            return
        end

        if NowPicNotice and NowPicNotice.Id == notice.Id and NowPicNotice.ModifyTime == notice.ModifyTime then
            return
        end

        NowPicNotice = notice

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_NOTICE_PIC_CHANGE)
    end

    function XNoticeManager.GetScrollPicList()
        XNoticeManager.RequestNoticeByType(XNoticeType.ScrollPic, true)
        if not NowPicNotice then
            return
        end

        local scrollPicList = {}
        for _, v in ipairs(NowPicNotice.Content) do
            local isOpen = true

            if not v.BeginTime or not v.EndTime or not v.AppearanceDay or not v.AppearanceTime
                    or not v.DisappearanceCondition or not v.AppearanceCondition then
                isOpen = false
            end

            if isOpen then
                isOpen = false
                if XTime.GetServerNowTimestamp() >= tonumber(v.BeginTime) and XTime.GetServerNowTimestamp() < tonumber(v.EndTime) then--是否在开放区间内（日期）
                    isOpen = true
                end
            end

            if isOpen then
                isOpen = false
                if #v.AppearanceDay > 0 then
                    for _, day in ipairs(v.AppearanceDay) do
                        if day == XDataCenter.FubenDailyManager.GetNowDayOfWeekByRefreshTime() then--是否位于可以显示的周目
                            isOpen = true
                        end
                    end
                else
                    isOpen = true
                end
            end

            if isOpen then
                isOpen = false
                if #v.AppearanceTime > 0 then
                    for _, time in ipairs(v.AppearanceTime) do
                        if XTime.GetServerNowTimestamp() - XTime.GetTodayTime(0, 0, 0) >= time[1] and XTime.GetServerNowTimestamp() - XTime.GetTodayTime(0, 0, 0) < time[2] then--是否位于可以显示的时间段
                            isOpen = true
                        end
                    end
                else
                    isOpen = true
                end
            end

            if isOpen then
                if #v.DisappearanceCondition > 0 then
                    for _, condition in ipairs(v.DisappearanceCondition) do--是否符合不显示的条件
                        if XConditionManager.CheckCondition(condition) then
                            isOpen = false
                        end
                    end
                end
            end

            if isOpen then
                if #v.AppearanceCondition > 0 then
                    for _, condition in ipairs(v.AppearanceCondition) do
                        if not XConditionManager.CheckCondition(condition) then--是否不符合显示条件
                            isOpen = false
                        end
                    end
                end
            end

            if isOpen then
                if not XNoticeManager.IsWhiteIp(v.WhiteLists) then
                    isOpen = false
                end
            end

            if isOpen then
                v.Interval = tonumber(v.Interval)
                table.insert(scrollPicList, v)
            end
        end

        return scrollPicList
    end
    ----------------------Scroll Pic end----------------------
    ----------------------InGame Notice beg----------------------
    function XNoticeManager.HandleRequestInGameNotice(notice)
        InGameNoticeMap = {}
        if not notice then
            return
        end

        if type(notice) ~= "table" then
            XLog.Error("InGame notice invalid format: " .. tostring(notice))
            return
        end

        for _, v in ipairs(notice) do
            if XNoticeManager.CheckNoticeValid(v) then
                if not InGameNoticeMap[v.Type] then
                    InGameNoticeMap[v.Type] = {}
                end

                local content = {}
                for _, item in ipairs(v.Content) do
                    if XNoticeManager.IsWhiteIp(item.WhiteLists) then
                        table.insert(content, item)
                    end
                end

                if #content > 0 then
                    v.Content = content
                    table.insert(InGameNoticeMap[v.Type], v)
                end
            end
        end

        for _, v in pairs(InGameNoticeMap) do
            XNoticeManager.InitInGameReadList(v)

            local sortFunc = function(l, r)
                return l.Order > r.Order
            end
            table.sort(v, sortFunc)
        end
    end

    function XNoticeManager.GetInGameNoticeMap(type)
        return InGameNoticeMap[type]
    end

    function XNoticeManager.CheckHaveNotice(type)
        XNoticeManager.RequestNoticeByType(XNoticeType.InGame, true)
        if not InGameNoticeMap then
            return false
        end

        if not InGameNoticeMap[type] or not next(InGameNoticeMap[type]) then
            return false
        end

        return true
    end
    
    function XNoticeManager.CheckInGameNoticeRedPoint(type)
        if not InGameNoticeMap or not InGameNoticeMap[type] then
            return false
        end

        for _, notice in pairs(InGameNoticeMap[type]) do
            for i, _ in ipairs(notice.Content) do
                if XNoticeManager.CheckInGameNoticeRedPointIndividual(notice, i) then
                    return true
                end
            end
        end
        return false
    end

    function XNoticeManager.InitInGameReadList(noticeList)
        if not noticeList then
            return
        end

        if not InGameNoticeReadList then
            InGameNoticeReadList = {}
        end

        for _, noticeData in pairs(noticeList) do
            for i, _ in pairs(noticeData.Content) do
                local dataKey = XNoticeManager.GetGameNoticeReadDataKey(noticeData, i)
                if not InGameNoticeReadList[dataKey] then
                    InGameNoticeReadList[dataKey] = {}
                    InGameNoticeReadList[dataKey].Id = noticeData.Id
                    InGameNoticeReadList[dataKey].EndTime = noticeData.EndTime
                    InGameNoticeReadList[dataKey].Index = i
                    InGameNoticeReadList[dataKey].IsRead = false
                    InGameNoticeReadList[dataKey].ModifyTime = noticeData.ModifyTime
                end
            end
        end

        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_NOTICE_READ_CHANGE)
    end

    function XNoticeManager.GetGameNoticeReadDataKey(noticeData, index)
        return noticeData.Id .. "_" .. noticeData.ModifyTime .. "_" .. index
    end

    function XNoticeManager.CheckInGameNoticeRedPointIndividual(notice, index)
        if not InGameNoticeReadList then
            return false
        end

        local redPointKey = XNoticeManager.GetGameNoticeReadDataKey(notice, index)
        if not InGameNoticeReadList[redPointKey] then
            return false
        end

        return not InGameNoticeReadList[redPointKey].IsRead
    end

    function XNoticeManager.ChangeInGameNoticeReadStatus(dataKey, isRead)
        if not InGameNoticeReadList then
            return
        end

        InGameNoticeReadList[dataKey].IsRead = isRead
        XNoticeManager.SaveInGameNoticeReadList()
    end
    ----------------------InGame Notice end----------------------
    -------------------------Sub Menu beg------------------------
    --[[ 二级菜单配置 json数据格式
            {"Id":每次生成配置时的唯一标识,
           "ModifyTime":配置最后修改时间,
           "Content":配置具体内容，可以包含多个按钮 [
           "Id":唯一按钮Id,
           "Title":按钮名称,
           "SubTitle":按钮描述（显示在第二行）,
           "JumpType":1表示网址，2表示游戏内跳转,
           "JumpAddr":跳转地址,
           "BeginTime":开始显示时间,
           "EndTime":结束显示时间,
           "AppearanceDay":一周内出现的日子，不填则为全部出现,
           "AppearanceTime":每天出现的时间段，不填则为全天出现,
           "TipResetTime":红点重置时间,
           "ModifyTime":最后修改时间 ] * N }
     --]]
   function XNoticeManager.HandleRequestSubMenuNotice(notice)
       SubMenuNoticeMap = {}
       if not notice then
           return
       end

       if type(notice) ~= "table" then
           XLog.Error("SubMenu notice invalid format: " .. tostring(notice))
           return
       end

       for _, v in ipairs(notice.Content) do
           if XNoticeManager.CheckNoticeValid(v) then
               table.insert(SubMenuNoticeMap, v)
           end
       end

       XNoticeManager.InitSubMenuReadList(notice)
   end 
    
   function XNoticeManager.GetMainUiSubMenu()
       XNoticeManager.RequestNoticeByType(XNoticeType.SubMenu, true)
        if not SubMenuNoticeMap then
            return
        end

        --XLog.Warning("start",SubMenuNoticeMap)

        local subMenuList = {}
        for _, v in ipairs(SubMenuNoticeMap) do
            local isOpen = true

            if not v.BeginTime or not v.EndTime or not v.AppearanceDay or not v.AppearanceTime then
                isOpen = false
            end

            if isOpen then
                isOpen = false
                if XTime.GetServerNowTimestamp() >= tonumber(v.BeginTime) and XTime.GetServerNowTimestamp() < tonumber(v.EndTime) then--是否在开放区间内（日期）
                    isOpen = true
                end
            end

            if isOpen then
                isOpen = false
                if #v.AppearanceDay > 0 then
                    for _, day in ipairs(v.AppearanceDay) do
                        if day == XDataCenter.FubenDailyManager.GetNowDayOfWeekByRefreshTime() then--是否位于可以显示的周目
                            isOpen = true
                        end
                    end
                else
                    isOpen = true
                end
            end

            if isOpen then
                isOpen = false
                if #v.AppearanceTime > 0 then
                    for _, time in ipairs(v.AppearanceTime) do
                        if XTime.GetServerNowTimestamp() - XTime.GetTodayTime(0, 0, 0) >= time[1] and XTime.GetServerNowTimestamp() - XTime.GetTodayTime(0, 0, 0) < time[2] then--是否位于可以显示的时间段
                            isOpen = true
                        end
                    end
                else
                    isOpen = true
                end
            end

            if isOpen then
                if v.DisappearanceCondition and #v.DisappearanceCondition > 0 then
                    for _, condition in ipairs(v.DisappearanceCondition) do--是否符合不显示的条件
                        if XConditionManager.CheckCondition(condition) then
                            isOpen = false
                        end
                    end
                end
            end

            if isOpen then
                if v.AppearanceCondition and #v.AppearanceCondition > 0 then
                    for _, condition in ipairs(v.AppearanceCondition) do
                        if not XConditionManager.CheckCondition(condition) then--是否不符合显示条件
                            isOpen = false
                        end
                    end
                end
            end

            if isOpen then
                if not XNoticeManager.IsWhiteIp(v.WhiteLists) then
                    isOpen = false
                end
            end

            if isOpen then
                table.insert(subMenuList, v)
            end
        end

        return subMenuList
    end
    
   function XNoticeManager.CheckSubMenuRedPoint()
       if not SubMenuNoticeMap then return false end
       
       for _, data in pairs(SubMenuNoticeMap) do
           if XNoticeManager.CheckSubMenuRedPointIndividual(data.Id) then
               return true
           end
       end
       return false
   end
   
   function XNoticeManager.InitSubMenuReadList(notice)
       if not notice then
           return
       end

       if not SubMenuNoticeReadList then
           SubMenuNoticeReadList = {}
       end

       for _, noticeData in pairs(notice.Content) do
           local dataKey = noticeData.Id
           if not SubMenuNoticeReadList[dataKey] then
               SubMenuNoticeReadList[dataKey] = {}
               SubMenuNoticeReadList[dataKey].Id = noticeData.Id
               SubMenuNoticeReadList[dataKey].LastReadTime = 0
           end
           SubMenuNoticeReadList[dataKey].EndTime = noticeData.EndTime
           SubMenuNoticeReadList[dataKey].TipResetTime = noticeData.TipResetTime or 0
       end

       XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_SUBMENU_READ_CHANGE)
       -- CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_SUBMENU_READ_CHANGE)
   end

   function XNoticeManager.CheckSubMenuRedPointIndividual(id)
       if not SubMenuNoticeReadList then
           return false
       end

       local data = SubMenuNoticeReadList[id]
       if not data then
           return false
       end
       
       if data.TipResetTime > XTime.GetServerNowTimestamp() then return false end
       return data.LastReadTime < data.TipResetTime
   end

   function XNoticeManager.ChangeSubMenuReadStatus(dataKey, time)
       if not SubMenuNoticeReadList then
           return
       end

       SubMenuNoticeReadList[dataKey].LastReadTime = time or XTime.GetServerNowTimestamp()
       --XLog.Warning("ChangeSubMenuReadStatus",SubMenuNoticeReadList)
       XNoticeManager.SaveSubMenuNoticeReadList()
   end
   -------------------------Sub Menu end------------------------

    ----------------------------------------login beg----------------------------------------

    function XNoticeManager.RequestLoginNotice(cb)
        local requestCb = function(notice)
            local valid = XNoticeManager.CheckNoticeValid(notice, os.time())
            if not valid then
                if cb then
                    cb(valid)
                end

                local msgtab = {}
                msgtab.error = valid
                CS.XRecord.Record(msgtab, "24000", "RequestLoginNoticeError")
                return
            end

            if LoginNotice and LoginNotice.Id == notice.Id and LoginNotice.ModifyTime == notice.ModifyTime then
                if cb then
                    cb(valid)
                end

                local msgtab = {}
                msgtab.error = valid
                CS.XRecord.Record(msgtab, "24006", "RequestLoginNoticeError")
                return
            end

            LoginNotice = notice
            local openNotice = false
            if XNoticeManager.CheckLoginNoticeDailyAutoShow(LoginNotice) then
                 openNotice = true
            end
            CS.XRecord.Record("24005", "RequestLoginNoticeEnd")
            if cb then
                cb(valid, openNotice)
            end
        end
        CS.XRecord.Record("24004", "RequestLoginNoticeStart")
        XNoticeManager.RequestNotice(XNoticeType.Login, requestCb, requestCb, RequestInterval[XNoticeType.Login])
    end
    
    function XNoticeManager.AutoOpenLoginNotice()
        if XNoticeManager.CheckLoginNoticeDailyAutoShow(LoginNotice) then
            if not XNoticeManager.CheckNoticeValid(LoginNotice, os.time()) then
                return
            end

            XLuaUiManager.Open("UiLoginNotice", LoginNotice)
            XNoticeManager.RefreshLoginNoticeTime()
        end
    end
    
   function XNoticeManager.OpenLoginNotice()
       if not LoginNotice then
           XNoticeManager.RequestLoginNotice(function(isValid)
               if isValid then
                   XLuaUiManager.Open("UiLoginNotice", LoginNotice)
                   XNoticeManager.RefreshLoginNoticeTime()
                   return true
               end
           end)
       else
           if not XNoticeManager.CheckNoticeValid(LoginNotice, os.time()) then
               return false
           end

           XLuaUiManager.Open("UiLoginNotice", LoginNotice)
           XNoticeManager.RefreshLoginNoticeTime()
           return true
       end
       return false
   end

   function XNoticeManager.ReadLoginNoticeTime()
       local cache = CS.UnityEngine.PlayerPrefs.GetString(LoginNoticeCacheKey)
       if string.IsNilOrEmpty(cache) then
           return
       end

       LoginNoticeTimeInfo = Json.decode(cache)
   end

   function XNoticeManager.CheckLoginNoticeDailyAutoShow(notice)
       if not notice then
           return
       end

       local id = notice.Id .. notice.ModifyTime
       local resetTime = CS.XReset.GetNextDailyResetTime() - CS.XDateUtil.ONE_DAY_SECOND
       if LoginNoticeTimeInfo[id] and LoginNoticeTimeInfo[id].Time > resetTime then
           return false
       end

       return true
   end

   function XNoticeManager.RefreshLoginNoticeTime()
       if not LoginNotice then
           return
       end

       local id = LoginNotice.Id .. LoginNotice.ModifyTime
       LoginNoticeTimeInfo[id] = {
           Id = id,
           -- 此处有可能无法获取到真实时间（尚未与服务端同步时间）
           Time = XTime.GetServerNowTimestamp()
       }

       CS.UnityEngine.PlayerPrefs.SetString(LoginNoticeCacheKey, Json.encode(LoginNoticeTimeInfo))
       CS.UnityEngine.PlayerPrefs.Save()
   end

    ----------------------------------------login end----------------------------------------
    ----------------------------image process beg----------------------------
    function XNoticeManager.LoadPicFromLocal(url, successCb)
        if NoticePicList and NoticePicList[url] then
            if successCb then
                successCb(NoticePicList[url])
            end
            return NoticePicList[url]
        end

        local fileName = XNoticeManager.GetImgNameByUrl(url)
        CS.XTool.LoadLocalNoticeImg(fileName, function(texture)
            if not texture then
                XNoticeManager.LoadPic(url, successCb)
            else
                NoticePicList[url] = texture
                if successCb then
                    successCb(texture)
                end
            end
        end)
    end

    function XNoticeManager.LoadPic(url, successCb)
        local request = CS.XUriPrefixRequest.Get(url, function()
            return CS.UnityEngine.Networking.DownloadHandlerTexture(true)
        end, NoticeRequestTimeOut, false)

        CS.XTool.WaitCoroutine(request:SendWebRequest(), function()
            if request.isNetworkError or request.isHttpError then
                return
            end

            local texture = request.downloadHandler.texture;
            if not texture then
                return
            end

            local fileName = XNoticeManager.GetImgNameByUrl(url)
            CS.XTool.SaveNoticeImg(fileName, texture)

            NoticePicList[url] = texture
            if successCb then
                successCb(texture)
            end

            request:Dispose()
        end)
    end

    function XNoticeManager.GetImgNameByUrl(url)
        local _, _, _, fileName = url:find("(.+)/(.+)")
        return fileName
    end
    ----------------------------image process end----------------------------

   --function XNoticeManager.UrlDecode(s)
   --    s = string.gsub(s, '%%(%x%x)', function(h)
   --        return string.char(tonumber(h, 16))
   --    end)
   --    return s
   --end

   function XNoticeManager.CheckNoticeValid(notice, nowTime)
       if not notice then
           return false
       end

       nowTime = nowTime or XTime.GetServerNowTimestamp()
       if nowTime < notice.BeginTime then
           return false
       end

       if nowTime > notice.EndTime then
           return false
       end

       if not XNoticeManager.IsWhiteIp(notice.WhiteLists) then
           return false
       end

       return true
   end

   function XNoticeManager.IsWhiteIp(whiteList)
       if not whiteList then
           return true
       end

       if string.IsNilOrEmpty(Ip) then
           return false
       end

       for _, whiteIp in pairs(whiteList) do
           if string.find(Ip, whiteIp) then
               return true
           end
       end

       return false
   end

    function XNoticeManager.RequestNoticeByType(noticeType, proactiveRequest)
        local successCb = NoticeRequestHandler[noticeType]
        local failCb = NoticeRequestFailHandler[noticeType]
        local interval = proactiveRequest and NoticeRequestTimerInterval or RequestInterval[noticeType]
        -- XLog.Warning("RequestNoticeByType", NoticeRequestTimerInterval, "type", RequestInterval[noticeType], "主动", proactiveRequest)
        XNoticeManager.RequestNotice(noticeType, successCb, failCb, interval)
    end
    
   function XNoticeManager.RequestNotice(noticeType, successCb, failCb, interval)
       if not noticeType then
           return
       end

       local nowTime = XTime.GetServerNowTimestamp()
       --if ((not nowTime) or (not noticeType) or (not interval)) then
       --    XLog.Warning("XNoticeManager nowTime", nowTime,"noticeType", noticeType,"LastRequestTime", LastRequestTime[noticeType],"interval", interval)
       --end
       if LastRequestTime[noticeType] and LastRequestTime[noticeType] > 0
           and nowTime - LastRequestTime[noticeType] < interval then
           return
       end
       LastRequestTime[noticeType] = nowTime

       local url = XNoticeManager.GetNoticeUrl(noticeType)
       if string.IsNilOrEmpty(url) then
           return
       end

       local request = CS.XUriPrefixRequest.Get(url, nil, NoticeRequestTimeOut, false, true)
       CS.XTool.WaitCoroutine(request:SendWebRequest(), function()
           if not request then
               if failCb then
                   failCb()
               end
               return
           end

           if request.isNetworkError or request.isHttpError then
               if failCb then
                   failCb()
               end
               return
           end

           if not request.downloadHandler then
               if failCb then
                   failCb()
               end
               return
           end

           if string.IsNilOrEmpty(request.downloadHandler.text) then
               if failCb then
                   failCb()
               end
               return
           end

           local ok, notice = pcall(Json.decode, request.downloadHandler.text)
           if not ok then
               XLog.Error("XNoticeManager json 解码失败. 数据是：", request.downloadHandler.data)
               if failCb then
                   failCb()
               end
               return
           end

           if not notice then
               if failCb then
                   failCb()
               end
               return
           end

           if successCb then
               successCb(notice)
           end

           request:Dispose()
       end)
   end
    
   function XNoticeManager.InitTimer()
       if NoticeRequestTimer then
           return
       end

       for noticeType, _ in pairs(RequestInterval) do
           XNoticeManager.RequestNoticeByType(noticeType)
       end

       NoticeRequestTimer = XScheduleManager.ScheduleForever(function()
           for noticeType, _ in pairs(RequestInterval) do
               XNoticeManager.RequestNoticeByType(noticeType)
           end
       end, NoticeRequestTimerInterval * 1000)
   end

   function XNoticeManager.OnLogin()
       XNoticeManager.ReadScrollCountList()
       XNoticeManager.ReadInGameNoticeReadList()
       XNoticeManager.ReadTextNoticeHideCache()
       XNoticeManager.ReadSubMenuNoticeReadList()
       
       XNoticeManager.InitTimer()
   end

   function XNoticeManager.OnLogout()
       if NoticeRequestTimer then
           XScheduleManager.UnSchedule(NoticeRequestTimer)
           NoticeRequestTimer = nil
       end

       for _, v in pairs(NoticePicList) do
           if v and v:Exist() then
               CS.UnityEngine.Object.Destroy(v)
           end
       end
       NoticePicList = {}
   end

   function XNoticeManager.Init()
       XNoticeManager.InitNoticeCdnUrl()
       XNoticeManager.RequestIp()
       XNoticeManager.ReadLoginNoticeTime()

       XEventManager.AddEventListener(XEventId.EVENT_USER_LOGOUT, XNoticeManager.OnLogout)
       XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, XNoticeManager.OnLogin)
       XEventManager.AddEventListener(XEventId.EVENT_PHOTO_ENTER, function()
           ScreenShotFlag = true
       end)
       XEventManager.AddEventListener(XEventId.EVENT_PHOTO_LEAVE, function()
           ScreenShotFlag = false
       end)
   end

   XNoticeManager.Init()
   return XNoticeManager
end