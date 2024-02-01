local ParseToTimestamp = XTime.ParseToTimestamp

XHeadPortraitManagerCreator = function()

    local XHeadPortraitManager = {}
    local HeadPortraitQuality = CS.XGame.Config:GetInt("HeadPortraitQuality")

    local HeadPortraitsTemplates = {}
    local UnlockHeadInfos = {}

    local SameGroupShowId = {}
    local SameGroupInitId = {}
    local METHOD_NAME = {
        SetHeadPortraitRequest = "SetHeadPortraitRequest",
        SetHeadFrameRequest = "SetHeadFrameRequest",
    }

    function XHeadPortraitManager.Init()
        HeadPortraitsTemplates = XHeadPortraitConfigs.GetHeadPortraitsCfg()
        XHeadPortraitManager.InitSameGroupShowId()
        XEventManager.AddEventListener(XEventId.EVENT_AUTO_WINDOW_STOP,XHeadPortraitManager.DisplayRewardRestock)
    end

    function XHeadPortraitManager.InitSameGroupShowId()
        local oldPriority
        for _, template in pairs(HeadPortraitsTemplates) do
            if template.GroupId ~= 0 then
                local sameGroupList = SameGroupShowId[template.Type]
                local sameGroupInitList = SameGroupInitId[template.Type]
                if not sameGroupList then
                    sameGroupList = {}
                    SameGroupShowId[template.Type] = sameGroupList
                end

                if not sameGroupInitList then
                    sameGroupInitList = {}
                    SameGroupInitId[template.Type] = sameGroupInitList
                end

                if oldPriority then
                    if oldPriority > template.Priority then
                        sameGroupList[template.GroupId] = template.Id
                        sameGroupInitList[template.GroupId] = template.Id
                        oldPriority = template.Priority
                    end
                else
                    sameGroupList[template.GroupId] = template.Id
                    sameGroupInitList[template.GroupId] = template.Id
                    oldPriority = template.Priority
                end
            end
        end
    end

    function XHeadPortraitManager.UpdateSameGroupShowId(Id)
        local templates = HeadPortraitsTemplates[Id]
        local groupId = templates and templates.GroupId or 0

        if groupId ~= 0 then
            local type = templates.Type
            local oldId = SameGroupShowId[type][groupId]
            XHeadPortraitManager.SetHeadPortraitForOld(oldId)
            XHeadPortraitManager.RemoveHeadPortraitInfo({ oldId })
            SameGroupShowId[type][groupId] = Id

            local currId = 0
            if type == XHeadPortraitConfigs.HeadType.HeadPortrait then
                currId = XPlayer.CurrHeadPortraitId or 0
            elseif type == XHeadPortraitConfigs.HeadType.HeadFrame then
                currId = XPlayer.CurrHeadFrameId or 0
            end
            if currId ~= 0 then
                local currTemplates = HeadPortraitsTemplates[currId]
                if currTemplates.GroupId == groupId and currTemplates.Id ~= Id then
                    XDataCenter.HeadPortraitManager.ChangeHeadFrame(Id)
                end
            end
        end
    end

    function XHeadPortraitManager.RestSameGroupShowId(Ids)
        for _, id in pairs(Ids) do
            local templates = HeadPortraitsTemplates[id]
            local groupId = templates and templates.GroupId or 0

            if groupId ~= 0 then
                local type = templates.Type
                SameGroupShowId[type][groupId] = SameGroupInitId[type][groupId]
            end
        end
    end

    function XHeadPortraitManager.CheckIsNewHeadPortrait(type)
        local IsHaveNew = false
        local HeadPortraitIds = XHeadPortraitManager.GetUnlockedHeadPortraitIds(type)
        for _, v in pairs(HeadPortraitIds) do
            if XHeadPortraitManager.CheckIsNewHeadPortraitById(v.Id) then
                IsHaveNew = true
            end
        end

        return IsHaveNew
    end

    function XHeadPortraitManager.CheckIsHideTime(id)
        local template = HeadPortraitsTemplates[id]
        if not template then
            return false
        end

        local showTime = ParseToTimestamp(template.ShowTimeStr)
        if not showTime then
            return false
        end
        return XTime.GetServerNowTimestamp() < showTime
    end

    function XHeadPortraitManager.CheckIsNewHeadPortraitById(Id)
        local IsHaveNew = false

        if XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "NewHeadPortrait", Id)) then
            IsHaveNew = true
        end

        if not XHeadPortraitManager.IsHeadPortraitValid(Id) then
            IsHaveNew = false
        end

        return IsHaveNew
    end

    function XHeadPortraitManager.SetHeadPortraitForOld(Id)
        if XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "NewHeadPortrait", Id)) then
            XSaveTool.RemoveData(string.format("%d%s%d", XPlayer.Id, "NewHeadPortrait", Id))
        end
    end

    function XHeadPortraitManager.AddNewHeadPortrait(Id)
        if not XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "NewHeadPortrait", Id)) then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "NewHeadPortrait", Id), Id)
        end
    end

    function XHeadPortraitManager.ChangeHeadPortrait(id, cb)
        XNetwork.Call(METHOD_NAME.SetHeadPortraitRequest, { Id = id }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end

            XPlayer.SetHeadPortrait(id)
            if cb then cb() end
        end)
    end

    function XHeadPortraitManager.ChangeHeadFrame(id, cb)
        XNetwork.Call(METHOD_NAME.SetHeadFrameRequest, { Id = id }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end

            XPlayer.SetHeadFrame(id)
            if cb then cb() end
        end)
    end

    function XHeadPortraitManager.GetUnlockedHeadPortraitIds(type)
        local list = {}
        for id, v in pairs(HeadPortraitsTemplates) do
            if not XHeadPortraitManager.CheckIsHideTime(id) then
                if not type or v.Type == type then
                    if v.GroupId == 0 then
                        table.insert(list, v)
                    else
                        if SameGroupShowId[v.Type][v.GroupId] == v.Id then
                            table.insert(list, v)
                        end
                    end
                end
            end
        end

        table.sort(list, function(headA, headB)
            local weightA = XHeadPortraitManager.IsHeadPortraitValid(headA.Id) and 1 or 0
            local weightB = XHeadPortraitManager.IsHeadPortraitValid(headB.Id) and 1 or 0
            if weightA == weightB then
                return headA.Priority < headB.Priority
            end
            return weightA > weightB
        end)

        return list
    end

    function XHeadPortraitManager.IsHeadPortraitValid(headId)
        local template = HeadPortraitsTemplates[headId]
        if not template then
            return false
        end

        local headInfo = UnlockHeadInfos[headId]
        if not headInfo then
            return false
        end

        if template.LimitType == XHeadPortraitConfigs.HeadTimeLimitType.Forever then
            return true
        elseif template.LimitType == XHeadPortraitConfigs.HeadTimeLimitType.Duration then
            return XTime.GetServerNowTimestamp() - headInfo.BeginTime < headInfo.LeftCount * template.Duration
        elseif template.LimitType == XHeadPortraitConfigs.HeadTimeLimitType.FixedTime then
            return XTime.GetServerNowTimestamp() > XHeadPortraitManager.GetBeginTimestamp(headId)
            and XTime.GetServerNowTimestamp() < XHeadPortraitManager.GetEndTimestamp(headId)
        end

        return false
    end

    function XHeadPortraitManager.AsyncHeadPortraitInfos(heads, IsAddNew)
        if not UnlockHeadInfos then
            UnlockHeadInfos = {}
        end

        for _, v in pairs(heads or {}) do
            XHeadPortraitManager.UpdateSameGroupShowId(v.Id)
            UnlockHeadInfos[v.Id] = v
            if IsAddNew then
                XHeadPortraitManager.AddNewHeadPortrait(v.Id)
            end
        end
    end
    
    function XHeadPortraitManager.CheckIsUnLockHead(headId)
        return UnlockHeadInfos[headId] and true or false
    end

    function XHeadPortraitManager.GetHeadPortraitData()
        return HeadPortraitsTemplates
    end

    function XHeadPortraitManager.GetHeadPortraitInfoById(id)
        return id and HeadPortraitsTemplates[id]
    end

    function XHeadPortraitManager.GetHeadPortraitNumById(id, type)
        local num = 0
        local Ids = XHeadPortraitManager.GetUnlockedHeadPortraitIds(type)
        local IsHave = false
        for _, v in pairs(Ids) do
            num = num + 1
            if v.Id == id then
                IsHave = true
                break
            end
        end

        return IsHave and num or 0
    end

    function XHeadPortraitManager.GetHeadPortraitQualityById(id)
        local templates = HeadPortraitsTemplates[id]
        return templates and templates.Quality or 1
    end

    function XHeadPortraitManager.GetHeadPortraitNameById(id)
        if not HeadPortraitsTemplates[id] then
            return ""
        end

        return HeadPortraitsTemplates[id].Name
    end

    function XHeadPortraitManager.GetHeadPortraitImgSrcById(id)
        if not HeadPortraitsTemplates[id] then
            return
        end

        return HeadPortraitsTemplates[id].ImgSrc
    end


    function XHeadPortraitManager.GetHeadPortraitEffectById(id)
        if not HeadPortraitsTemplates[id] then
            return
        end

        return HeadPortraitsTemplates[id].Effect
    end

    function XHeadPortraitManager.GetHeadPortraitLockDescId(id)
        if not HeadPortraitsTemplates[id] then
            return ""
        end

        return HeadPortraitsTemplates[id].LockDescId
    end

    function XHeadPortraitManager.GetHeadPortraitDescriptionById(id)
        if not HeadPortraitsTemplates[id] then
            return ""
        end

        return HeadPortraitsTemplates[id].Description
    end

    function XHeadPortraitManager.GetHeadPortraitWorldDescById(id)
        if not HeadPortraitsTemplates[id] then
            return ""
        end

        return HeadPortraitsTemplates[id].WorldDesc
    end

    function XHeadPortraitManager.GetBeginTimestamp(id)
        if not HeadPortraitsTemplates[id] then
            return 0
        end

        return XFunctionManager.GetStartTimeByTimeId(HeadPortraitsTemplates[id].TimeId) or 0
    end

    function XHeadPortraitManager.GetEndTimestamp(id)
        if not HeadPortraitsTemplates[id] then
            return 0
        end

        return XFunctionManager.GetEndTimeByTimeId(HeadPortraitsTemplates[id].TimeId) or 0
    end

    function XHeadPortraitManager.GetHeadLeftTime(id)
        local template = HeadPortraitsTemplates[id]
        if not template then
            return ""
        end

        local headInfo = UnlockHeadInfos[id]
        if not headInfo then
            return ""
        end

        local duration = template.Duration * headInfo.LeftCount
        local leftTime = duration - (XTime.GetServerNowTimestamp() - headInfo.BeginTime)

        return CS.XTextManager.GetText("HeadLeftTimeText", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.HEADPORTRAIT))
    end

    function XHeadPortraitManager.GetHeadValidDuration(id)
        local template = HeadPortraitsTemplates[id]
        if not template then
            return ""
        end

        return CS.XTextManager.GetText("HeadValidTimeText", XUiHelper.GetTime(template.Duration, XUiHelper.TimeFormatType.HEADPORTRAIT))
    end

    function XHeadPortraitManager.RemoveHeadPortraitInfo(ids)
        if not UnlockHeadInfos then
            return
        end

        for _, id in pairs(ids) do
            UnlockHeadInfos[id] = nil
        end
    end
    
    --region 2.10
    local rewardRestockCachce = nil
    
    function XHeadPortraitManager.SetRewardRestockCache(data)
        rewardRestockCachce = data
    end
    
    function XHeadPortraitManager.DisplayRewardRestock()
        if not XTool.IsTableEmpty(rewardRestockCachce) then
            XUiManager.OpenUiObtain(rewardRestockCachce)
            rewardRestockCachce = nil
        end
    end
    --endregion

    XHeadPortraitManager.Init()
    return XHeadPortraitManager
end

XRpc.NotifyHeadPortraitInfos = function(data)
    if not data then
        return
    end

    XDataCenter.HeadPortraitManager.AsyncHeadPortraitInfos(data.Heads, true)
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_NOTIFY)
end

XRpc.NotifyHeadTimeout = function(data)
    XPlayer.SetHeadPortrait(data.CurrHeadPortraitId)
    XPlayer.SetHeadFrame(data.CurrHeadFrameId)

    XDataCenter.HeadPortraitManager.SetHeadPortraitForOld(data.CurrHeadPortraitId)
    XDataCenter.HeadPortraitManager.SetHeadPortraitForOld(data.CurrHeadFrameId)

    XDataCenter.HeadPortraitManager.RemoveHeadPortraitInfo(data.TimeoutIds)
    XDataCenter.HeadPortraitManager.RestSameGroupShowId(data.TimeoutIds)
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_NOTIFY)
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_TIMEOUT)
end

--region 2.10
XRpc.FashionLoginGiftNotify = function(data)
    XDataCenter.HeadPortraitManager.SetRewardRestockCache(data.GoodList)
end
--endregion