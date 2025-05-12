local XDrawActivityTargetInfo = require("XEntity/XDraw/XDrawActivityTargetInfo")

XDrawManagerCreator = function()
    ---@class XDrawManager
    local XDrawManager = {}

    local tableInsert = table.insert
    local tableSort = table.sort

    local GET_DRAW_DATA_INTERVAL = 15

    --region Data Config
    local DrawCombinations = {}
    local DrawProbs = {}
    local DrawGroupRule = {}
    local DrawShow = {}
    local DrawShowCharacter = {}
    local DrawCamera = {}
    local DrawTabs = {}
    --endregion

    local DrawGroupInfos = {}
    local DrawInfos = {}
    local LastGetGroupInfoTime = 0
    local LastGetDropInfoTimes = {}
    
    ---@type table<number, XDrawActivityTargetInfo> key = activityId
    local _DrawActivityTargetInfoDir = {}
    ---@type table<number, number> key = groupId value = activityId
    local _DrawGroupActivityTargetDir = {}
    
    local ActivityDrawList = {}
    local ActivityDrawListByTag = {}
    local FreeDrawTicket = {}
    local DrawActivityCount = 0
    local IsHasNewActivityDraw = false
    local CurSelectTabInfo = nil
    local LostSelectDrawGroupId = 0
    local LostSelectDrawType = 0
    local DrawNewGroupIds = nil
    local DrawDiscountGroupIds = nil
    local DrawDevilMayCryGroupIds = nil

    XDrawManager.DrawEventType = { Normal = 0, NewHand = 1, Activity = 2, OldActivity = 3 }

    function XDrawManager.Init()
        DrawCombinations = XDrawConfigs.GetDrawCombinations()
        DrawGroupRule = XDrawConfigs.GetDrawGroupRule()
        DrawShow = XDrawConfigs.GetDrawShow()
        DrawShowCharacter = XDrawConfigs.GetDrawShowCharacter()
        DrawCamera = XDrawConfigs.GetDrawCamera()
        DrawTabs = XDrawConfigs.GetDrawTabs()
        DrawProbs = XDrawConfigs.GetDrawProbs()
    end

    --region Ui
    function XDrawManager.OpenDrawUi(ruleType, groupId, defaultDrawId, isPop,groupPool)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DrawCard) then
            return
        end
        XDrawManager.GetDrawGroupList(function()
            if isPop then
                XLuaUiManager.PopThenOpen("UiNewDrawMain", ruleType, groupId, defaultDrawId,groupPool)
            else
                XLuaUiManager.Open("UiNewDrawMain", ruleType, groupId, defaultDrawId,groupPool)
            end
        end)
    end
    --endregion

    function XDrawManager.GetFreeTicketIdByGroupId(groupId)
        local tickets = XDrawManager.GetTicketsByGroupId(groupId)
        local expireTime = math.huge
        local ticketId = 0
        -- 存在多个时，找出关联卡池数最少、剩余时间最少、Id最小的免费券
        local minDrawAssociate = 999
        local cfgId = math.maxinteger

        for _, ticketInfo in pairs(tickets) do
            if XTool.IsNumberValid(ticketInfo.ExpireTime) and ticketInfo.Count > 0 then
                local ticketCfg = XDrawConfigs.GetDrawTicketCfg(ticketInfo.CfgId)
                local drawGroupCount = #ticketCfg.DrawGroupIds

                -- 优先选卡池数最少的
                if drawGroupCount < minDrawAssociate then
                    minDrawAssociate = drawGroupCount
                    ticketId = ticketInfo.Id
                    expireTime = ticketInfo.ExpireTime
                elseif drawGroupCount == minDrawAssociate then
                    -- 其次选剩余时间最少的
                    if ticketInfo.ExpireTime < expireTime then
                        ticketId = ticketInfo.Id
                        expireTime = ticketInfo.ExpireTime
                    elseif ticketInfo.ExpireTime == expireTime then
                        -- 最后选Id最小的
                        if ticketInfo.CfgId < cfgId then
                            ticketId = ticketInfo.Id
                            cfgId = ticketInfo.CfgId
                        end
                    end
                end
            end
        end
        return ticketId
    end
    
    -- 获取该卡池中有效免费券中最少的剩余时间及数量
    ---@return @TicketId: 并列集中的代表， expireTime:剩余时间，count：所有相同最小剩余时间的免费券之和
    function XDrawManager.GetLeastExpireTimeFreeTicketIdByGroupId(groupId)
        local count = 0
        local expireTime = math.huge
        local representTicketId = 0
        
        local stack = {}
        local stackCount = 0

        local tickets = XDrawManager.GetTicketsByGroupId(groupId)

        for _, ticketInfo in pairs(tickets) do
            if XTool.IsNumberValid(ticketInfo.ExpireTime) and ticketInfo.Count > 0 then
                if ticketInfo.ExpireTime < expireTime then
                    expireTime = ticketInfo.ExpireTime
                    -- 清空栈
                    if stackCount > 0 then
                        for i = 1, stackCount do
                            stack[i] = nil
                        end
                    end
                    -- 入栈
                    stackCount = 1
                    stack[1] = ticketInfo.Count
                    representTicketId = ticketInfo.Id
                elseif ticketInfo.ExpireTime == expireTime then
                    -- 入栈
                    stackCount = stackCount + 1
                    stack[stackCount] = ticketInfo.Count
                end
            end
        end
        
        -- 出栈
        if stackCount > 0 then
            for i = stackCount, 1, -1 do
                count = count + stack[i]
                stack[i] = nil
            end
        end
        
        return representTicketId, expireTime, count
    end
    
    ---@return @param1:指定ticketId的数据, param2:是否有新的数据, param3... 多个新的数据
    function XDrawManager.GetTicketInfoForExpireTimeDisplay(ticketId, groupId)
        local ticketInfo = XDrawManager.GetTicketInfoById(ticketId)

        if ticketInfo and XTool.IsNumberValid(ticketInfo.ExpireTime) then
            return ticketInfo
        else
            -- 尝试查找新的最少剩余时间的免费券
            local representTicketId, expireTime, count = XDrawManager.GetLeastExpireTimeFreeTicketIdByGroupId(groupId)

            if XTool.IsNumberValid(representTicketId) then
                return nil, true, representTicketId, expireTime, count
            end
        end
    end

    function XDrawManager.GetTicketInfoById(id)
        return FreeDrawTicket[id]
    end

    function XDrawManager.GetTicketsByGroupId(groupId)
        local tickets = {}
        for _, ticketInfo in pairs(FreeDrawTicket) do
            local cfg = XDrawConfigs.GetDrawTicketCfg(ticketInfo.CfgId)
            if cfg then
                for _, gId in pairs(cfg.DrawGroupIds) do
                    if gId == groupId then
                        table.insert(tickets, ticketInfo)
                    end
                end
            end
        end
        return tickets
    end

    function XDrawManager.CheckHasFreeTicket(groupId)
        local now = XTime.GetServerNowTimestamp()
        local tickets = XDrawManager.GetTicketsByGroupId(groupId)
        local isHasTicket = false
        local groupInfo = XDrawManager.GetDrawGroupInfoByGroupId(groupId)
        if groupInfo then
            if now < groupInfo.StartTime or now > groupInfo.EndTime and groupInfo.EndTime ~= 0 then
                return false
            end
        end
        for _, ticketInfo in pairs(tickets) do
            if ticketInfo.Count > 0 or ticketInfo.ExpireTime > now then
                isHasTicket = true
                break
            end
        end
        return isHasTicket
    end
    
    function XDrawManager.GetFreeTicketCount(groupId)
        local count = 0
        
        local now = XTime.GetServerNowTimestamp()
        local tickets = XDrawManager.GetTicketsByGroupId(groupId)
        local isHasTicket = false
        local groupInfo = XDrawManager.GetDrawGroupInfoByGroupId(groupId)
        if groupInfo then
            if now < groupInfo.StartTime or now > groupInfo.EndTime and groupInfo.EndTime ~= 0 then
                return count
            end
        end
        for _, ticketInfo in pairs(tickets) do
            if ticketInfo.Count > 0 and ticketInfo.ExpireTime > now then
                count = count + ticketInfo.Count
            end
        end
        
        return count
    end
    
    function XDrawManager.CheckDrawFreeTicketTag()
        local now = XTime.GetServerNowTimestamp()
        for _, ticketInfo in pairs(FreeDrawTicket) do
            local cfg = XDrawConfigs.GetDrawTicketCfg(ticketInfo.CfgId)
            local isInTime = true
            if cfg then
                for _, gId in pairs(cfg.DrawGroupIds) do
                    local groupInfo = XDrawManager.GetDrawGroupInfoByGroupId(gId)
                    isInTime = isInTime and groupInfo and (now > groupInfo.StartTime and now < groupInfo.EndTime or groupInfo.EndTime == 0)
                end
            end
            if ticketInfo.Count > 0 and isInTime then
                return true
            end
        end
        return false
    end

    function XDrawManager.GetDrawPreview(drawId)
        return XDrawConfigs.GetDrawPreviews(drawId)
    end

    function XDrawManager.GetDrawCombination(drawId)
        return DrawCombinations[drawId]
    end

    function XDrawManager.GetDrawProb(drawId)
        return DrawProbs[drawId]
    end

    function XDrawManager.GetDrawGroupRule(groupId)
        return DrawGroupRule[groupId]
    end

    function XDrawManager.GetDrawShow(type)
        return DrawShow[type - 1]
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
        for _, v in pairs(DrawGroupInfos) do
            if orderId < v.Order then
                orderId = v.Order
                groupId = v.Id
            end
        end
        return groupId
    end

    function XDrawManager.GetGroupIdWithFreeTicket()
        local max = -1
        local groupIdList = {}
        local ticketCountDic = {}
        for _, ticketInfo in pairs(FreeDrawTicket) do
            if not ticketCountDic[ticketInfo.CfgId] then
                ticketCountDic[ticketInfo.CfgId] = ticketInfo.Count
            else
                ticketCountDic[ticketInfo.CfgId] = ticketCountDic[ticketInfo.CfgId] + ticketInfo.Count
            end
        end

        for cfgId, count in pairs(ticketCountDic) do
            local cfg = XDrawConfigs.GetDrawTicketCfg(cfgId)
            if count > max then
                max = count
                groupIdList = {}
                for _,groupId in pairs(cfg.DrawGroupIds) do
                    table.insert(groupIdList,groupId)
                end
            elseif count == max then
                for _,groupId in pairs(cfg.DrawGroupIds) do
                    table.insert(groupIdList,groupId)
                end
            end
        end
        
        local order = -1
        local groupId
        for _, gId in pairs(groupIdList) do
            local groupInfo = XDrawManager.GetDrawGroupInfoByGroupId(gId)
            if groupInfo and groupInfo.Order > order then
                order = groupInfo.Order
                groupId = gId
            end
        end
        return groupId
    end

    function XDrawManager.GetDrawTicketCountByTemplateId(templateId)
        local count = 0

        if not XTool.IsTableEmpty(FreeDrawTicket) then
            for i, v in pairs(FreeDrawTicket) do
                if v.CfgId == templateId then
                    count = count + v.Count
                end
            end
        end
        
        return count
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

    function XDrawManager.GetActivityDrawMarkId(Id)
        --获取当前卡池ID的卡池在记录队列中的位置ID
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

    function XDrawManager.MarkActivityDraw()
        --记录当前开放的活动卡池
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

    function XDrawManager.UnMarkOldActivityDraw(list)
        --消除已关闭卡池的记录
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

    function XDrawManager.SetNewActivityDraw(list)
        --记录是否有新卡池开启
        IsHasNewActivityDraw = false
        for _, v in pairs(list or {}) do
            IsHasNewActivityDraw = IsHasNewActivityDraw or (not XDrawManager.GetActivityDrawMarkId(v))
        end
    end

    function XDrawManager.CheckNewActivityDraw()
        --检查是否有新卡池开启
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

    function XDrawManager.IsCanAutoOpenAimGroupSelect(time, groupId)
        --判断time时间以内是否可以自动打开狙击池组合选择界面
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

    function XDrawManager.IsShowNewTag(time, ruleType, groupId)
        --判断time时间以内是否显示新标签
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

    function XDrawManager.MarkNewTag(time, ruleType, groupId)
        --标记新标签
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
                local purchaseData = XDataCenter.PurchaseManager.GetPurchaseDataById(purchaseId)
                if purchaseData then
                    tableInsert(drawPurchase, purchaseData)
                end
            end
        end

        return drawPurchase
    end
    
    --region ActivityTarget 狙击目标
    ---@return XDrawActivityTargetInfo
    function XDrawManager.GetDrawActivityTargetInfo(activityId)
        if _DrawActivityTargetInfoDir[activityId] and XTool.IsNumberValid(_DrawActivityTargetInfoDir[activityId]:GetTargetCount()) then
            return _DrawActivityTargetInfoDir[activityId]
        end
        return false
    end

    function XDrawManager.DebugActivityTargetInfo(groupId)
        if not XTool.IsNumberValid(groupId) then
            XLog.Error("[XUiDrawOptional]groupId为空.")
            return
        end
        local activityId = _DrawGroupActivityTargetDir[groupId]
        if not XTool.IsNumberValid(activityId) then
            XLog.Error("[XUiDrawOptional]活动Id为空.")
            return
        end
        local data = _DrawActivityTargetInfoDir[activityId]
        if not data then
            XLog.Error(string.format("[XUiDrawOptional]DrawActivityTargetInfoDir里找不到数据 activity=%s", activityId))
            return
        end
        if not XTool.IsNumberValid(data:GetTargetCount()) then
            XLog.Error(string.format("[XUiDrawOptional]AdjustTimes=%s TargetTimes=%s", data._AdjustTimes, data._TargetTimes))
            return
        end
    end

    ---@return number
    function XDrawManager.GetDrawActivityTargetIdByGroupId(groupId)
        return _DrawGroupActivityTargetDir[groupId]
    end

    ---@return XDrawActivityTargetInfo
    function XDrawManager.GetDrawGroupActivityTargetInfo(groupId)
        local activityId = _DrawGroupActivityTargetDir[groupId]
        if not activityId then
            return false
        end
        return XDrawManager.GetDrawActivityTargetInfo(activityId)
    end

    ---@return table
    function XDrawManager.GetDrawGroupActivityTargetInfoDir()
        return _DrawGroupActivityTargetDir
    end
    
    function XDrawManager._InitDrawGroupActivityTargetData()
        _DrawActivityTargetInfoDir = {}
        _DrawGroupActivityTargetDir = {}
    end
    
    ---更新指定抽奖校准
    function XDrawManager._UpdateDrawActivityTargetInfos(activityTargetInfoList)
        if XTool.IsTableEmpty(activityTargetInfoList) then
            return
        end
        XDrawManager._InitDrawGroupActivityTargetData()
        -- 保留并更新已有的
        for _, data in ipairs(activityTargetInfoList) do
            XDrawManager._TryToAddDrawActivityTargetInfo(data)
            _DrawActivityTargetInfoDir[data.ActivityId]:UpdateData(data)
        end
    end

    ---更新抽奖次数
    function XDrawManager._UpdateDrawActivityTimes(data)
        if XTool.IsTableEmpty(data) then
            return
        end
        -- 保留并更新已有的
        if _DrawActivityTargetInfoDir[data.ActivityId] then
            _DrawActivityTargetInfoDir[data.ActivityId]:SetTargetTimes(data.TargetTimes)
        end
    end

    ---@param infoList table
    function XDrawManager._UpdateDrawActivityStatus(infoList)
        if XTool.IsTableEmpty(infoList) then
            return
        end
        local tipType = 0
        local isHaveChange = false
        for _, data in ipairs(infoList) do
            if XTool.IsNumberValid(data.ActivityStatus) then
                if tipType < data.ActivityStatus then
                    tipType = data.ActivityStatus
                end
                if data.ActivityStatus == 2 then
                    XDrawManager._TryToRemoveDrawActivityTargetInfo(data)
                else
                    XDrawManager._TryToAddDrawActivityTargetInfo(data)
                end
                isHaveChange = true
            end
        end

        -- 如果不在抽卡相关界面不提示不踢回主界面
        if not XLuaUiManager.IsUiLoad("UiNewDrawMain") then
            return
        end
        -- 如果意外跳转其他ui直接踢回主界面
        if XLuaUiManager.IsUiShow("UiDrawLog") 
                or XLuaUiManager.IsUiShow("UiDrawOptional")
                or XLuaUiManager.IsUiShow("UiNewDrawMain")
                or XLuaUiManager.IsUiShow("UiDrawNew")
                or XLuaUiManager.IsUiShow("UiDrawShowNew")
        then
            if isHaveChange then
                XEventManager.DispatchEvent(XEventId.EVENT_DRAW_TARGET_ACTIVITY_CHANGE, tipType)
            end
            return
        end

        XLuaUiManager.RunMain()
        if tipType == XDrawConfigs.DrawTargetTipType.Open then
            XUiManager.TipErrorWithKey("DrawTargetActivityOpen")
        elseif tipType == XDrawConfigs.DrawTargetTipType.Close then
            XUiManager.TipErrorWithKey("DrawTargetActivityClose")
        elseif tipType == XDrawConfigs.DrawTargetTipType.Update then
            XUiManager.TipErrorWithKey("DrawTargetActivityUpdate")
        end
    end
    
    function XDrawManager._TryToAddDrawActivityTargetInfo(data)
        if XTool.IsNumberValid(data.ActivityId) and XTool.IsNumberValid(data.DrawGroupId) then
            -- 数据不存在则添加
            if not _DrawActivityTargetInfoDir[data.ActivityId] then
                _DrawActivityTargetInfoDir[data.ActivityId] = XDrawActivityTargetInfo.New()
                _DrawActivityTargetInfoDir[data.ActivityId]:UpdateData(data)
                _DrawGroupActivityTargetDir[data.DrawGroupId] = data.ActivityId
                return true
            end
            -- 数据存在则更新
            _DrawActivityTargetInfoDir[data.ActivityId]:UpdateData(data)
            _DrawGroupActivityTargetDir[data.DrawGroupId] = data.ActivityId
        end
        return false
    end

    function XDrawManager._TryToRemoveDrawActivityTargetInfo(data)
        if _DrawActivityTargetInfoDir[data.ActivityId] then
            _DrawActivityTargetInfoDir[data.ActivityId] = nil
        end
        if _DrawGroupActivityTargetDir[data.DrawGroupId] then
            _DrawGroupActivityTargetDir[data.DrawGroupId] = nil
        end
        return not _DrawGroupActivityTargetDir[data.DrawGroupId] and not _DrawActivityTargetInfoDir[data.ActivityId]
    end
    --endregion

    --region v2.14 活动新卡池

    function XDrawManager:CheckIsNewDraw(groupId)
        if not DrawNewGroupIds then
            DrawNewGroupIds = {}
            local ids = XDrawConfigs.GetDrawClientConfigs("DrawNewGroupIds")
            for _, v in pairs(ids) do
                DrawNewGroupIds[tonumber(v)] = true
            end
        end
        return DrawNewGroupIds[groupId]
    end

    function XDrawManager:CheckIsShowDiscount(groupId)
        if not DrawDiscountGroupIds then
            DrawDiscountGroupIds = {}
            local ids = XDrawConfigs.GetDrawClientConfigs("DrawDiscountGroupIds")
            for _, v in pairs(ids) do
                DrawDiscountGroupIds[tonumber(v)] = true
            end
        end
        return DrawDiscountGroupIds[groupId]
    end

    function XDrawManager:CheckIsDevilMayCryGroupId(groupId)
        if not DrawDevilMayCryGroupIds then
            DrawDevilMayCryGroupIds = {}
            local ids = XDrawConfigs.GetDrawClientConfigs("DrawDevilMayCryGroupIds")
            for _, v in pairs(ids) do
                DrawDevilMayCryGroupIds[tonumber(v)] = true
            end
        end
        return DrawDevilMayCryGroupIds[groupId]
    end

    -- 可领次数，指立即点击按钮可领但是还没领的
    function XDrawManager:CheckIsCanReceiveCharacterByDrawId(drawId)
        local cfg = XDrawConfigs.GetDevilMayCryActivityCfgByDrawId(drawId)
        if not cfg then
            return
        end

        local taskGroupId = cfg.TaskGroupId
        local taskDataList = XDataCenter.TaskManager.GetTaskByTypeAndGroup(XDataCenter.TaskManager.TaskType.DevilMayCryDraw, taskGroupId)
        if XTool.IsTableEmpty(taskDataList) then
            return
        end
        
        local leftCount = 0 -- 剩余可领次数(已完成未领取)
        local taskList = {}
        for _, v in pairs(taskDataList) do
            if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                leftCount = leftCount + 1
                table.insert(taskList, v.Id)
            end
        end

        return leftCount, taskList
    end

    -- 剩余次数，指还可以领取的次数，包括不能立即领取的和还没触发完成的
    function XDrawManager:GetLeftCanGetDevilCharacterCount(drawId)
        local cfg = XDrawConfigs.GetDevilMayCryActivityCfgByDrawId(drawId)
        if not cfg then
            return
        end

        local taskGroupId = cfg.TaskGroupId
        local taskDataList = XDataCenter.TaskManager.GetTaskByTypeAndGroup(XDataCenter.TaskManager.TaskType.DevilMayCryDraw, taskGroupId)
        if XTool.IsTableEmpty(taskDataList) then
            return
        end
        
        local leftCount = #taskDataList
        local taskList = {}
        for _, v in pairs(taskDataList) do
            if v.State == XDataCenter.TaskManager.TaskState.Finish then
                leftCount = leftCount - 1
                table.insert(taskList, v.Id)
            end
        end

        return leftCount, taskList
    end
    --endregion
    
    --region ServerDataUpdate
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
    
    --- ticketInfo
    --- Id 
    --- CfgId 
    --- ExpireTime 
    --- Count
    function XDrawManager.UpdateDrawTicket(data, isClear)
        if isClear then
            FreeDrawTicket = {}
        end
        for _, ticketInfo in pairs(data) do
            FreeDrawTicket[ticketInfo.Id] = ticketInfo
        end
        XEventManager.DispatchEvent(XEventId.EVENT_DRAW_FREE_TICKET_UPDATE)
    end
    --endregion
    
    --region Proto
    -- 查询相关end --
    -- 消息相关begin --
    function XDrawManager.GetDrawInfoList(groupId, cb, IsNotDoCoolDown)
        local now = XTime.GetServerNowTimestamp()
        if LastGetDropInfoTimes[groupId] and now - LastGetDropInfoTimes[groupId] <= GET_DRAW_DATA_INTERVAL and not IsNotDoCoolDown then
            if cb then
                cb()
            end
            return
        end
        XNetwork.Call("DrawGetDrawInfoListRequest", { GroupId = groupId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.UpdateDrawInfos(res.DrawInfoList)
            LastGetDropInfoTimes[groupId] = now
            if cb then
                cb()
            end
        end)
    end
    
    function XDrawManager.GetDrawGroupList(cb)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DrawCard) then
            return
        end

        local now = XTime.GetServerNowTimestamp()
        if now - LastGetGroupInfoTime <= GET_DRAW_DATA_INTERVAL then
            if cb then
                cb()
            end
            return
        end
        XNetwork.Call("DrawGetDrawGroupListRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.UpdateDrawGroupInfos(res.DrawGroupInfoList)
            XDrawManager._UpdateDrawActivityTargetInfos(res.DrawAdjustActivityInfoList)
            LastGetGroupInfoTime = now
            if cb then
                cb()
            end
        end)
    end

    function XDrawManager.DrawCard(drawId, count, freeTicketId, cb)
        XDataCenter.KickOutManager.Lock(XEnumConst.KICK_OUT.LOCK.DRAW)
        XNetwork.Call("DrawDrawCardRequest", { DrawId = drawId, Count = count, UseDrawTicketId = freeTicketId }, function(res)
            if res.Code ~= XCode.Success then
                XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.DRAW, true)
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.UpdateDrawInfo(res.ClientDrawInfo)
            XDrawManager.UpdateDrawGroupByInfo(res.ClientDrawInfo)
            XDrawManager._UpdateDrawActivityTimes(res.DrawAdjustData)
            local drawInfo = XDrawManager.GetDrawInfo(res.ClientDrawInfo.Id)
            if cb then
                cb(drawInfo, res.RewardGoodsList, res.ExtraRewardList)
            else
                XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.DRAW, true)
            end
        end)
    end

    function XDrawManager.SaveDrawAimId(drawId, groupId, cb)
        --保存狙击目标
        XNetwork.Call("DrawSetUseDrawIdRequest", { DrawId = drawId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.GetDrawGroupInfoByGroupId(groupId).UseDrawId = drawId
            XDrawManager.GetDrawGroupInfoByGroupId(groupId).SwitchDrawIdCount = res.SwitchDrawIdCount
            if cb then
                cb()
            end
        end)
    end
    
    function XDrawManager.RequestSelectTargetActivity(activityId, targetId, cb)
        local reqBody = {
            ActivityId = activityId;
            TargetId = targetId;
        }
        XNetwork.Call("DrawAdjustTargetRequest", reqBody, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.GetDrawActivityTargetInfo(activityId):SetTargetId(targetId)
            if cb then
                cb()
            end
        end)
    end
    
    --- 获取指定卡池组的历史记录
    function XDrawManager.RequestDrawGroupGetHistory(groupId, successCb, errorCb)
        XNetwork.Call("DrawGroupGetHistoryRequest", { GroupId = groupId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)

                if errorCb then
                    errorCb()
                end
                return
            end

            if successCb then
                successCb(res)
            end
        end)
    end
    
    --- 获取开放记录抽卡组列表
    function XDrawManager.RequestDrawGetHistoryGroupList(successCb, errorCb)
        XNetwork.Call("DrawGetHistoryGroupListRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)

                if errorCb then
                    errorCb()
                end
                return
            end

            if successCb then
                successCb(res.HistoryGroups)
            end
        end)
    end

    --endregion

    function XDrawManager.CheckIsShowOptionDraw(drawGroupRuleId)
        local ids = XDrawConfigs.GetDrawClientConfigs("NotShowChooseDrawGroupRuleId")

        for _, id in pairs(ids) do
            if tonumber(id) == drawGroupRuleId then
                return false
            end
        end

        return true
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

XRpc.NotifyDrawTicketData = function(data)
    XDataCenter.DrawManager.UpdateDrawTicket(data.DrawTicketInfos, true)
end

XRpc.NotifyUpdateDrawTicketData = function(data)
    XDataCenter.DrawManager.UpdateDrawTicket({ data.DrawTicketInfo }, false)
end

---刷新抽卡狙击瞄准规则
XRpc.NotifyDrawAdjustActivity = function(data)
    XDataCenter.DrawManager._UpdateDrawActivityStatus(data.DrawAdjustActivityInfoList)
end
