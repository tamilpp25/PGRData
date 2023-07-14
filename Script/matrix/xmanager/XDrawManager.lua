XDrawManagerCreator = function()

    local XDrawManager = {}

    local tableInsert = table.insert
    local tableSort = table.sort

    local GET_DRAW_DATA_INTERVAL = 15

    local DrawGroupInfos = {}
    local DrawInfos = {}
    local LastGetGroupInfoTime = 0
    local LastGetDropInfoTimes = {}

    local DrawPreviews = {}
    local DrawCombinations = {}
    local DrawProbs = {}
    local DrawGroupRule = {}
    local DrawShow = {}
    local DrawNewYearShow = {}
    local DrawShowCharacter = {}
    local DrawCamera = {}
    local DrawTabs = {}
    local ActivityDrawList = {}
    local ActivityDrawListByTag = {}
    local DrawActivityCount = 0
    local IsHasNewActivityDraw = false
    local CurSelectTabInfo = nil
    local LostSelectDrawGroupId = 0
    local LostSelectDrawType = 0

    XDrawManager.DrawEventType = { Normal = 0, NewHand = 1, Activity = 2, OldActivity = 3 }

    function XDrawManager.Init()
        DrawCombinations = XDrawConfigs.GetDrawCombinations()
        DrawGroupRule = XDrawConfigs.GetDrawGroupRule()
        DrawShow = XDrawConfigs.GetDrawShow()
        DrawNewYearShow = XDrawConfigs.GetDrawNewYearShow()
        DrawShowCharacter = XDrawConfigs.GetDrawShowCharacter()
        DrawCamera = XDrawConfigs.GetDrawCamera()
        DrawTabs = XDrawConfigs.GetDrawTabs()
        DrawPreviews = XDrawConfigs.GetDrawPreviews()
        DrawProbs = XDrawConfigs.GetDrawProbs()
    end

    function XDrawManager.GetDrawPreview(drawId)
        return DrawPreviews[drawId]
    end

    function XDrawManager.GetDrawCombination(drawId)
        return DrawCombinations[drawId]
    end

    function XDrawManager.GetDrawProb(drawId)
        local cfgs = DrawProbs[drawId] or {}
        table.sort(cfgs, function(a, b)
                return a.Sort < b.Sort
            end)
        return cfgs
    end

    function XDrawManager.GetDrawGroupRule(groupId)
        return DrawGroupRule[groupId]
    end

    function XDrawManager.GetDrawShow(type)
        return DrawShow[type - 1]
    end

    function XDrawManager.GetDrawNewYearShow(type)
        return DrawNewYearShow[type - 1]
    end
    
    function XDrawManager.GetDrawCamera(id)
        return DrawCamera[id]
    end

    function XDrawManager.GetDrawInfo(drawId)
        return DrawInfos[drawId]
    end

    function XDrawManager.GetDrawShowCharacter(id)
        return DrawShowCharacter[id]
    end
    
    function XDrawManager.GetLostSelectDrawGroupId()
        return LostSelectDrawGroupId
    end

    function XDrawManager.SetLostSelectDrawGroupId(groupId)
        LostSelectDrawGroupId = groupId
    end

    function XDrawManager.GetLostSelectDrawType()
        return LostSelectDrawType
    end

    function XDrawManager.SetLostSelectDrawType(type)
        LostSelectDrawType = type
    end
    
    function XDrawManager.GetDrawInfoListByGroupId(groupId)
        local list = {}
        local drawAimProbability = XDrawConfigs.GetDrawAimProbability()

        for _, info in pairs(DrawInfos) do
            if info.GroupId == groupId then
                tableInsert(list, info)
            end
        end

        tableSort(list, function(a, b)
            local PriorityA = drawAimProbability[a.Id] and drawAimProbability[a.Id].Priority or 0
            local PriorityB = drawAimProbability[b.Id] and drawAimProbability[b.Id].Priority or 0

            if PriorityA == PriorityB then
                return a.Id < b.Id
            else
                return PriorityA > PriorityB
            end
        end)

        return list
    end

    function XDrawManager.GetUseDrawInfoByGroupId(groupId)
        local groupInfo = DrawGroupInfos[groupId]
        local UseDrawInfo = groupInfo.UseDrawId > 0 and XDrawManager.GetDrawInfo(groupInfo.UseDrawId) or nil

        if UseDrawInfo then
            return UseDrawInfo
        else
            local list = XDrawManager.GetDrawInfoListByGroupId(groupId)
            return list[1]
        end
    end

    function XDrawManager.GetDrawGroupInfoByGroupId(groupId)
        return DrawGroupInfos[groupId]
    end

    function XDrawManager.CheckDrawIsTimeOver(drawId)
        if not DrawInfos[drawId] then
            return true
        end
        if DrawInfos[drawId].EndTime == 0 then
            return false
        end
        local nowTime = XTime.GetServerNowTimestamp()
        return DrawInfos[drawId].EndTime - nowTime <= 0
    end

    -- 查询相关begin --
    function XDrawManager.GetDrawGroupInfos()
        local list = {}

        for _, v in pairs(DrawGroupInfos) do
            tableInsert(list, v)
        end

        tableSort(list, function(a, b)
            return a.Priority > b.Priority
        end)
        --检测如果有过期的，下次请求跳过时间间隔检测
        for _, v in pairs(list) do
            if v.EndTime > 0 and v.EndTime - XTime.GetServerNowTimestamp() <= 0 then
                LastGetGroupInfoTime = 0
                CurSelectTabInfo = nil
            end
        end
        return list
    end
    
    function XDrawManager.GetGroupIdWithMaxOrder()
        local orderId = -1
        local groupId = -1
        for _,v in pairs(DrawGroupInfos) do
            if orderId < v.Order then
                orderId = v.Order
                groupId = v.Id
            end
        end
        return groupId
    end

    function XDrawManager.UpdateDrawGroupInfos(groupInfoList)
        DrawGroupInfos = {}

        local isExpired = true

        for _, info in pairs(groupInfoList) do
            DrawGroupInfos[info.Id] = info
            DrawGroupInfos[info.Id].BottomTimes = DrawGroupInfos[info.Id].MaxBottomTimes - DrawGroupInfos[info.Id].BottomTimes
            if CurSelectTabInfo then
                if info.Id == CurSelectTabInfo.Id then
                    isExpired = false
                end
            end
        end

        if isExpired then
            CurSelectTabInfo = nil
        end
    end

    function XDrawManager.UpdateDrawInfos(drawInfoList)
        --每次更新一组info之前清空之前相同GroupId的信息
        local deleteKey = {}
        for k, v in pairs(DrawInfos) do
            if v.GroupId == drawInfoList[1].GroupId then
                deleteKey[k] = true
            end
        end
        for k, _ in pairs(deleteKey) do
            DrawInfos[k] = nil
        end

        for _, info in pairs(drawInfoList) do
            XDrawManager.UpdateDrawInfo(info)
        end
    end

    function XDrawManager.UpdateDrawInfo(drawInfo)
        DrawInfos[drawInfo.Id] = XTool.Clone(drawInfo)
        DrawInfos[drawInfo.Id].BottomTimes = DrawInfos[drawInfo.Id].MaxBottomTimes - DrawInfos[drawInfo.Id].BottomTimes
    end
    -- 查询相关end --
    -- 消息相关begin --
    function XDrawManager.GetDrawInfoList(groupId, cb, IsNotDoCoolDown)
        local now = XTime.GetServerNowTimestamp()
        if LastGetDropInfoTimes[groupId] and now - LastGetDropInfoTimes[groupId] <= GET_DRAW_DATA_INTERVAL and not IsNotDoCoolDown then
            if cb then cb() end
            return
        end
        XNetwork.Call("DrawGetDrawInfoListRequest", { GroupId = groupId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.UpdateDrawInfos(res.DrawInfoList)
            LastGetDropInfoTimes[groupId] = now
                if cb then cb() end
        end)
    end

    function XDrawManager.GetDrawGroupList(cb)
        local now = XTime.GetServerNowTimestamp()
        if now - LastGetGroupInfoTime <= GET_DRAW_DATA_INTERVAL then
            if cb then cb() end
            return
        end
        XNetwork.Call("DrawGetDrawGroupListRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.UpdateDrawGroupInfos(res.DrawGroupInfoList)
            LastGetGroupInfoTime = now
                if cb then cb() end
        end)
    end

    --==============================--
    --desc: 打乱奖励顺序，防止因规则造成顺序可循
    --@rewardGoodsList: 奖励列表
    --@return 处理后奖励列表
    --==============================--
    -- local function UpsetRewardGoodsList(rewardGoodsList)
    --     local list = {}

    --     local len = #rewardGoodsList
    --     if len <= 1 then
    --         return rewardGoodsList
    --     end

    --     for i = 1, len do
    --         local index = math.random(1, len)
    --         if index ~= i then
    --             local tmp = rewardGoodsList[i]
    --             rewardGoodsList[i] = rewardGoodsList[index]
    --             rewardGoodsList[index] = tmp
    --         end
    --     end

    --     return rewardGoodsList
    -- end

    function XDrawManager.DrawCard(drawId, count, cb, failCb)
        XNetwork.Call("DrawDrawCardRequest", { DrawId = drawId, Count = count }, function(res)
            if res.Code ~= XCode.Success then
                if failCb then
                   failCb()
                end
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.UpdateDrawInfo(res.ClientDrawInfo)
            XDrawManager.UpdateDrawGroupByInfo(res.ClientDrawInfo)
            local drawInfo = XDrawManager.GetDrawInfo(res.ClientDrawInfo.Id)
            if cb then cb(drawInfo, res.RewardGoodsList, res.ExtraRewardList) end
        end)
    end
    function XDrawManager.SaveDrawAimId(drawId, groupId, cb)--保存狙击目标
        XNetwork.Call("DrawSetUseDrawIdRequest", { DrawId = drawId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.GetDrawGroupInfoByGroupId(groupId).UseDrawId = drawId
            XDrawManager.GetDrawGroupInfoByGroupId(groupId).SwitchDrawIdCount = res.SwitchDrawIdCount
            if cb then cb() end
        end)
    end
    -- 消息相关end --
    -- Wind --
    function XDrawManager.GetDrawTab(tabID)
        for _, tab in pairs(DrawTabs) do
            if tab.Id == tabID then
                return tab
            end
        end

        XLog.Error("XDrawManager.GetDrawTab ： Client/Draw/DrawTabs.tab 表中不存在 tabID：" .. tabID .. "检查参数或者配置表项")
        return nil
    end

    function XDrawManager.GetCurSelectTabInfo()
        return CurSelectTabInfo
    end

    function XDrawManager.SetCurSelectTabInfo(info)
        CurSelectTabInfo = info
    end

    function XDrawManager.UpdateDrawGroupByInfo(clientDrawInfo)
        for _, v in pairs(DrawGroupInfos) do
            if v.UseDrawId == clientDrawInfo.Id then
                v.BottomTimes = clientDrawInfo.MaxBottomTimes - clientDrawInfo.BottomTimes
            end
        end
    end

    function XDrawManager.GetActivityDrawMarkId(Id)--获取当前卡池ID的卡池在记录队列中的位置ID
        local countMax = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "ActivityDrawCountMax"))
        if countMax then
            for i = 1, countMax do
                local drawId = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "NewActivityDraw", i))
                if drawId then
                    if drawId == Id then
                        return i
                    end
                end
            end
        end
        return nil
    end

    function XDrawManager.MarkActivityDraw()--记录当前开放的活动卡池
        for _, Id in pairs(ActivityDrawList or {}) do
            if not XDrawManager.GetActivityDrawMarkId(Id) then
                local count = 1
                while true do
                    if not XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "NewActivityDraw", count)) then
                        XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "NewActivityDraw", count), Id)
                        local countMax = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "ActivityDrawCountMax"))
                        if (not countMax) or (countMax and countMax < count) then
                            XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "ActivityDrawCountMax"), count)
                        end
                        break
                    end
                    count = count + 1
                end
            end
        end
        IsHasNewActivityDraw = false
    end

    function XDrawManager.UnMarkOldActivityDraw(list)--消除已关闭卡池的记录
        local countMax = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "ActivityDrawCountMax"))
        if countMax then
            for i = 1, countMax do
                local drawId = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "NewActivityDraw", i))
                if drawId then
                    local IsInList = false
                    for _, v in pairs(list or {}) do
                        if drawId == v then
                            IsInList = true
                        end
                    end
                    if not IsInList then
                        XSaveTool.RemoveData(string.format("%d%s%d", XPlayer.Id, "NewActivityDraw", i))
                    end
                end
            end
        end
    end

    function XDrawManager.SetNewActivityDraw(list)--记录是否有新卡池开启
        IsHasNewActivityDraw = false
        for _, v in pairs(list or {}) do
            IsHasNewActivityDraw = IsHasNewActivityDraw or (not XDrawManager.GetActivityDrawMarkId(v))
        end
    end

    function XDrawManager.CheckNewActivityDraw()--检查是否有新卡池开启
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DrawCard) then
            return false
        end
        return IsHasNewActivityDraw
    end

    function XDrawManager.UpdateDrawActivityCount(count)
        DrawActivityCount = count
    end

    function XDrawManager.UpdateActivityDrawList(list)
        ActivityDrawList = list
    end

    function XDrawManager.UpdateActivityDrawListByTag(lnfoList)
        for _, v in pairs(lnfoList) do
            if not ActivityDrawListByTag[v.Tag] then
                ActivityDrawListByTag[v.Tag] = {}
            end
            local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(v.Id)
            table.insert(ActivityDrawListByTag[v.Tag], drawInfo.Id)
        end
    end

    function XDrawManager.CheckDrawActivityCount()
        return DrawActivityCount > 0
    end

    function XDrawManager.IsCanAutoOpenAimGroupSelect(time, groupId) --判断time时间以内是否可以自动打开狙击池组合选择界面
        local data = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "AimAutoOpenState", groupId))
        if data then
            if time > data then
                XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "AimAutoOpenState", groupId), time)
                return true
            else
                return false
            end
        else
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "AimAutoOpenState", groupId), time)
            return true
        end
    end
    
    function XDrawManager.IsShowNewTag(time, ruleType, groupId) --判断time时间以内是否显示新标签
        local data = XSaveTool.GetData(string.format("%d%s%d%d", XPlayer.Id, "DrawShowNewTag", ruleType, groupId))
        if data then
            if time > data then
                return true
            else
                return false
            end
        else
            return true
        end
    end
    
    function XDrawManager.MarkNewTag(time, ruleType, groupId) --标记新标签
        local data = XSaveTool.GetData(string.format("%d%s%d%d", XPlayer.Id, "DrawShowNewTag", ruleType, groupId))
        if data then
            if time > data then
                XSaveTool.SaveData(string.format("%d%s%d%d", XPlayer.Id, "DrawShowNewTag", ruleType, groupId), time)
            end
        else
            XSaveTool.SaveData(string.format("%d%s%d%d", XPlayer.Id, "DrawShowNewTag", ruleType, groupId), time)
        end
    end

    function XDrawManager.GetDrawPurchase(drawId)
        local drawInfo = XDataCenter.DrawManager.GetDrawInfo(drawId)
        if not drawInfo then
            return {}
        end

        local purchaseIds = drawInfo.PurchaseId
        local drawPurchase = {}
        if purchaseIds and next(purchaseIds) then
            for _, purchaseId in ipairs(purchaseIds) do
                local purchaseData = XDataCenter.PurchaseManager.GetPurchaseDataById( purchaseId)
                if purchaseData then
                    tableInsert(drawPurchase, purchaseData)
                end
            end
        end

        return drawPurchase
    end

    -- WindEnd --
    XDrawManager.Init()
    return XDrawManager
end


XRpc.NotifyActivityDrawGroupCount = function(data)
    XDataCenter.DrawManager.UpdateDrawActivityCount(data.Count)
    XEventManager.DispatchEvent(XEventId.EVENT_DRAW_ACTIVITYCOUNT_CHANGE)
end

XRpc.NotifyActivityDrawList = function(data)
    XDataCenter.DrawManager.UpdateActivityDrawList(data.DrawIdList)
    XDataCenter.DrawManager.SetNewActivityDraw(data.DrawIdList)
    XDataCenter.DrawManager.UnMarkOldActivityDraw(data.DrawIdList)
    XEventManager.DispatchEvent(XEventId.EVENT_DRAW_ACTIVITYDRAW_CHANGE)
end