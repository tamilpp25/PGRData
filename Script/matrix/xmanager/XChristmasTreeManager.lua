local tableInsert = table.insert
local tableSort = table.sort

XChristmasTreeManagerCreator = function ()
    local XChristmasTreeManager = {}
    local ActivityInfo = nil
    local OrnamentsPos = {}
    local TempOrnamentsPos = {}
    local PosChangeList = {}
    local OrnamentsInfo = {}
    local OrnamentsReadList = {}
    local OrnamentsReadKey = "ChristmasTreeOrnamentRead"
    local OpenKey = "ChristmasTreeOpen"

    local ACTIVITY_PROTO = {
        ChristmasTreeActivityDataRequest = "ChristmasTreeActivityDataRequest",
        ActiveOrnamentsRequest = "ActiveOrnamentsRequest",
        ChangeOrnamentsRequest = "ChangeOrnamentsRequest",
    }
    
    local function GetKey(keyword)
        if not ActivityInfo then return end
        return string.format("%d_%s_%d", XPlayer.Id, keyword, ActivityInfo.Id)
    end
    
    function XChristmasTreeManager.Init()
        local activityTemplates = XChristmasTreeConfig.GetActivityTemplates()
        local nowTime = XTime.GetServerNowTimestamp()
        for _, template in pairs(activityTemplates) do
            local TimeId = template.TimeId
            local startTime, endTime = XFunctionManager.GetTimeByTimeId(TimeId)
            if nowTime > startTime and nowTime < endTime then
                if not ActivityInfo then
                    ActivityInfo = XChristmasTreeConfig.GetActivityTemplateById(template.Id)
                end
            end
        end

        if ActivityInfo then
            XChristmasTreeManager.RequestData()
            for _,ornament in pairs(XChristmasTreeConfig.GetOrnamentCfg()) do
                XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. ornament.SubItemId, XChristmasTreeManager.OnSubItemCountChange)
            end
            OrnamentsReadList = XSaveTool.GetData(GetKey(OrnamentsReadKey)) or OrnamentsReadList
        end
    end
    
    function XChristmasTreeManager.RequestData()
        XNetwork.Call(ACTIVITY_PROTO.ChristmasTreeActivityDataRequest, {ActId = ActivityInfo.Id}, function (res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XChristmasTreeManager.HandleData(res)
        end)
    end
    
    function XChristmasTreeManager.Reset(actId)
        if actId then
            ActivityInfo = XChristmasTreeConfig.GetActivityTemplateById(actId)
        end
        XChristmasTreeManager.ResetChange()
        return ActivityInfo
    end

    function XChristmasTreeManager.HandleData(data)
        if data == nil then return end
        
        OrnamentsPos = data.Tree
        for _, id in pairs(OrnamentsPos) do
            if id and id ~= 0 then
                OrnamentsReadList[id] = true
            end
        end
        XChristmasTreeManager.SetOrnamentRead()
        
        OrnamentsInfo = {}
        for _,id in ipairs(data.Ornaments) do
            OrnamentsInfo[id] = true
        end
    end
    
    -- 获得临时布局位置（刚进入时获得已保存的位置）
    function XChristmasTreeManager.GetCurrentOrnamentPos()
        if not next(PosChangeList) then
            return OrnamentsPos
        end
        
        if not next(TempOrnamentsPos) then
            TempOrnamentsPos = XTool.Clone(OrnamentsPos)
        end
        for partId, ornamentId in pairs(PosChangeList) do
            TempOrnamentsPos[partId] = ornamentId
        end
        
        return TempOrnamentsPos
    end

    function XChristmasTreeManager.PutOrnament(partId ,ornamentId)
        local isValid = false
        for _, v in ipairs(XChristmasTreeConfig.GetOrnamentById(ornamentId).PartId) do
            if v == partId then
                isValid = true
                break;
            end
        end
        if isValid then
            PosChangeList[partId] = ornamentId
            XChristmasTreeManager.SetOrnamentRead(ornamentId)
            return true
        end
        return false
    end

    function XChristmasTreeManager.SwapOrnamentPos(partId1 ,partId2)
        if XChristmasTreeConfig.GetGrpIdByTreePart(partId1) == XChristmasTreeConfig.GetGrpIdByTreePart(partId2) then
            local tempPos = XChristmasTreeManager.GetCurrentOrnamentPos()
            PosChangeList[partId1] = tempPos[partId2] or 0
            PosChangeList[partId2] = tempPos[partId1] or 0
            return true
        end
        return false
    end

    function XChristmasTreeManager.RemoveOrnament(partId)
        XChristmasTreeManager.SetOrnamentRead(PosChangeList[partId])
        PosChangeList[partId] = 0
        return true
    end

    function XChristmasTreeManager.RemoveOrnamentGrp(grpId)
        local partCount, partGrpCount = XChristmasTreeConfig.GetTreePartCount()
        if not grpId or grpId > partGrpCount then
            for partId = 1, partCount do
                
                PosChangeList[partId] = 0
            end
        else
            local partGrp = XChristmasTreeConfig.GetTreePartByGroup(grpId)
            for _, part in ipairs(partGrp) do
                PosChangeList[part.Id] = 0
            end
        end
        return true
    end

    function XChristmasTreeManager.CheckPartGrpEmpty(grpId)
        local _, partGrpCount = XChristmasTreeConfig.GetTreePartCount()
        local tempPos = XChristmasTreeManager.GetCurrentOrnamentPos()
        if not grpId or grpId > partGrpCount then
            for _, v in pairs(tempPos) do
                if v and v ~= 0 then
                    return false
                end
            end
        else
            local partGrp = XChristmasTreeConfig.GetTreePartByGroup(grpId)
            for _, part in ipairs(partGrp) do
                if tempPos[part.Id] and tempPos[part.Id] ~= 0 then
                    return false
                end
            end
        end
        return true
    end

    function XChristmasTreeManager.CheckOrnamentGrpUnread(grpId)
        if not ActivityInfo then return end

        local _, partGrpCount = XChristmasTreeConfig.GetTreePartCount()
        if not grpId or grpId > partGrpCount then
            for _, ornament in pairs(XChristmasTreeConfig.GetOrnamentCfg()) do
                local id = ornament.Id
                if XChristmasTreeManager.CheckOrnamentOwn(id) and not OrnamentsReadList[id] then
                    return true
                end
            end
        else
            --XLog.Warning("CheckOrnamentGrpUnread",OrnamentsInfo,grpId, OrnamentsReadList)
            for _, ornament in pairs(XChristmasTreeConfig.GetOrnamentByGroup(grpId)) do
                local id = ornament.Id
                if XChristmasTreeManager.CheckOrnamentOwn(id) and not OrnamentsReadList[id] then
                    -- XLog.Warning("<color=green> true" .. grpId .. "</color>")
                    return true
                end
                --XLog.Warning("single",grpId, XChristmasTreeManager.CheckOrnamentOwn(id), OrnamentsReadList[id])
            end
        end
        --XLog.Warning("<color=red> false" .. grpId .. "</color>")
        return false
    end

    function XChristmasTreeManager.CheckOrnamentUnread(id)
        return XChristmasTreeManager.CheckOrnamentOwn(id) and not OrnamentsReadList[id]
    end

    function XChristmasTreeManager.SetOrnamentRead(id)
        if id then
            if OrnamentsReadList[id] or not OrnamentsInfo[id] then return end
            OrnamentsReadList[id] = true
        end
        XSaveTool.SaveData(GetKey(OrnamentsReadKey), OrnamentsReadList)
        XEventManager.DispatchEvent(XEventId.EVENT_CHRISTMAS_TREE_ORNAMENT_READ)
    end

    function XChristmasTreeManager.CheckChange()
        return next(PosChangeList) ~= nil
    end
    
    function XChristmasTreeManager.SubmitChange(cb)
        if not PosChangeList or not next(PosChangeList) then 
            XUiManager.TipMsg("No changes made")
            return
        end
        local tempOrnamentsPos = XChristmasTreeManager.GetCurrentOrnamentPos()
        XMessagePack.MarkAsTable(tempOrnamentsPos)
        XNetwork.Call(ACTIVITY_PROTO.ChangeOrnamentsRequest, {Changes = tempOrnamentsPos}, function (res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if res.Changes and next(res.Changes) then
                XChristmasTreeManager.ApplyChange(res.Changes)
                XChristmasTreeManager.ResetChange()
                XEventManager.DispatchEvent(XEventId.EVENT_CHRISTMAS_TREE_GOT_REWARD)
            end
            if cb then 
                cb() 
            end
        end)
    end

    function XChristmasTreeManager.ApplyChange(changes)
        for partId, ornamentId in pairs(changes) do
            OrnamentsPos[partId] = ornamentId
            OrnamentsReadList[ornamentId] = true
        end
        XChristmasTreeManager.SetOrnamentRead()
    end

    function XChristmasTreeManager.ResetChange()
        PosChangeList = {}
        TempOrnamentsPos = {}
    end

    function XChristmasTreeManager.GetAttrName(index)
        if ActivityInfo then
            if index then
                return ActivityInfo.AttrName[index]
            else
                return ActivityInfo.AttrName
            end
        end
        return {}
    end
    
    function XChristmasTreeManager.GetAttrDeltaValue()
        local delta = {}
        for i in ipairs(XChristmasTreeManager.GetAttrName()) do
            delta[i] = 0
        end
        
        for partId, ornamentId in pairs(PosChangeList) do
            local oldItem = XChristmasTreeConfig.GetOrnamentById(OrnamentsPos[partId])
            local newItem = XChristmasTreeConfig.GetOrnamentById(ornamentId)
            if oldItem then
                for i, v in ipairs(oldItem.Attr) do
                    delta[i] = delta[i] - v
                end
            end
            if newItem then
                for i, v in ipairs(newItem.Attr) do
                    delta[i] = delta[i] + v
                end
            end
        end
        
        return delta
    end

    function XChristmasTreeManager.GetAttrValue()
        local value = {}
        local countIndex = #ActivityInfo.AttrName + 1
        for i = 1, countIndex do
            value[i] = 0
        end
        for _, ornamentId in pairs(OrnamentsPos) do
            local item = XChristmasTreeConfig.GetOrnamentById(ornamentId)
            if item then
                for i, v in ipairs(item.Attr) do
                    value[i] = value[i] + v
                    value[countIndex] = value[countIndex] + v
                end
            end
        end
        return value
    end

    function XChristmasTreeManager.GetTempItemData(id)
        local ornamentData = XChristmasTreeConfig.GetOrnamentById(id)
        local itemId = ornamentData.ItemId

        -- 获取属性总分文本
        local attrHead = CS.XTextManager.GetText("ChristmasTreeOrnamentDescHead",
                "\t\t\t", "  ", XChristmasTreeConfig.GetAttrCount(ornamentData.Id))
        local list = {attrHead}
        -- 获取单项属性文本
        for i, name in ipairs(XChristmasTreeManager.GetAttrName()) do
            local attrInfo = string.format("%s  %d", name, ornamentData.Attr[i])
            tableInsert(list, attrInfo)
        end
        -- 合并各属性文本
        local attrFull = table.concat(list, "\n\t\t\t\t\t")
        
        local data = XTool.Clone(XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId))
        data.IsTempItemData = true
        data.Count =  XChristmasTreeManager.CheckOrnamentOwn(id) and "1" or "0"
        data.Description = XGoodsCommonManager.GetGoodsDescription(itemId)
        -- attrFull = string.gsub(attrFull, "\\t", "\t")
        -- 合并世界观描述与属性描述文本
        data.WorldDesc = string.format("%s\n%s", XGoodsCommonManager.GetGoodsWorldDesc(itemId), attrFull)
        return data
    end
    

    --排序
    local getSortFunc = function (sortType)
        if not sortType or sortType == 0 then
            return function(a, b)
                return a.Id < b.Id
            end
        else
            return function(a, b)
                if a.Attr[sortType] ~= b.Attr[sortType] then
                    -- 按属性从大到小排序
                    return a.Attr[sortType] > b.Attr[sortType]
                else
                    -- 其次按 Id 从小到大排序
                    return a.Id < b.Id
                end
            end
        end
    end
    
    function XChristmasTreeManager.GetAvailableOrnaments(grpId, sortType)
        local list = {}
        local rawData = nil
        --if not grpId or grpId > PartGrpCount then
        --    rawData = XChristmasTreeConfig.GetOrnamentCfg()
        --else
            rawData = XChristmasTreeConfig.GetOrnamentByGroup(grpId) or {}
        --end
        
        for _, item in pairs(rawData) do
            -- XChristmasTreeManager.CheckOrnamentOwn(item.Id) and
            if XChristmasTreeManager.GetOrnamentAvailability(item.Id) then
                tableInsert(list, item)
            end
        end
        
        if next(list) then
            tableSort(list ,getSortFunc(sortType))
        end

         --XLog.Warning(grpId, sortType, list, OrnamentsInfo)
        return list
    end

    function XChristmasTreeManager.CheckOrnamentOwn(id)
        return OrnamentsInfo[id]
    end

    function XChristmasTreeManager.GetOrnamentAvailability(id)
        for _, v in pairs(XChristmasTreeManager.GetCurrentOrnamentPos()) do
            if v == id then
                return false
            end
        end
        return true
    end

    function XChristmasTreeManager.GetActivityInfo()
        return ActivityInfo
    end

    function XChristmasTreeManager.CheckCanGetOrnament()
        if not ActivityInfo then return false end
        local minItemCount = XMath.IntMax()
        local minItemId = nil
        local isFull = true
        for _, ornament in pairs(XChristmasTreeConfig.GetOrnamentCfg()) do
            if not OrnamentsInfo[ornament.Id] then
                if XDataCenter.ItemManager.CheckItemCountById(ornament.SubItemId, ornament.SubItemCount) then
                    return true, ornament.SubItemId, ornament.SubItemCount
                elseif ornament.SubItemCount < minItemCount then
                    minItemCount = ornament.SubItemCount
                    minItemId = ornament.SubItemId
                    isFull = false
                end
            end
        end
        if isFull then 
            return false, XChristmasTreeConfig.GetOrnamentById(1).SubItemId, 0
        end
        return false, minItemId, minItemCount
    end
    
    function XChristmasTreeManager.OnSubItemCountChange()
        XEventManager.DispatchEvent(XEventId.EVENT_CHRISTMAS_TREE_ORNAMENT_ACTIVE)
    end
    
    function XChristmasTreeManager.CheckOrnamentFull()
        for _,ornament in pairs(XChristmasTreeConfig.GetOrnamentCfg()) do
            if not OrnamentsInfo[ornament.Id] then
                return false
            end
        end
        return true
    end

    function XChristmasTreeManager.GetOrnamentCount()
        local own, count = 0, 0
        for _,ornament in pairs(XChristmasTreeConfig.GetOrnamentCfg()) do
            count = count + 1
            if OrnamentsInfo[ornament.Id] then
                own = own + 1
            end
        end
        return own, count
    end

    function XChristmasTreeManager.ActiveOrnament(id, cb)
        XNetwork.Call(ACTIVITY_PROTO.ActiveOrnamentsRequest, {OrnamentId = id}, function (res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 本地构造
            local rewardGoodsList = {{TemplateId = XChristmasTreeConfig.GetOrnamentById(res.OrnamentId).ItemId , RewardType = XRewardManager.XRewardType.Item, Count = 1}}
            XUiManager.OpenUiObtain(rewardGoodsList)
            OrnamentsInfo[res.OrnamentId] = true
            XEventManager.DispatchEvent(XEventId.EVENT_CHRISTMAS_TREE_ORNAMENT_READ)
            if cb then
                cb()
            end
        end)
    end

    --- 获取完成的挑战任务数与总数
    function XChristmasTreeManager.GetTaskProgress()
        local taskIds = ActivityInfo.TaskId
        local totalTaskNum = #taskIds
        local finishNum = 0
        
        if taskIds == nil or next(taskIds) == nil then
            return
        end
        
        for _, id in pairs(taskIds) do
            if XDataCenter.TaskManager.CheckTaskFinished(id) then
                finishNum = finishNum + 1
            end
        end

        return finishNum, totalTaskNum
    end

    --- 检查任务是否全部领取奖励
    function XChristmasTreeManager.CheckTaskAllFinish()
        local taskIds = ActivityInfo.TaskId
        
        if taskIds == nil or next(taskIds) == nil then
            return
        end

        for _, id in pairs(taskIds) do
            if not XDataCenter.TaskManager.CheckTaskFinished(id) then
                return false
            end
        end

        return true
    end

    --- 检查是否有奖励可以领取
    function XChristmasTreeManager.HasTaskReward()
        if not ActivityInfo then return end
        local taskIds = ActivityInfo.TaskId

        if taskIds == nil or next(taskIds) == nil then
            return false
        end

        for _, id in pairs(taskIds) do
            -- XLog.Warning("HasTaskReward", id, XDataCenter.TaskManager.GetTaskDataById(id))
            if XDataCenter.TaskManager.CheckTaskAchieved(id) then
                 return true
            end
        end

        return false
    end

    -- 判断是否为指定时间点后第一次打开
    function XChristmasTreeManager.CheckFirstOpen()
        if not ActivityInfo then return end
        local nowTime = XTime.GetServerNowTimestamp()
        local lastOpen = XSaveTool.GetData(GetKey(OpenKey)) or 0
        local currentOpen = lastOpen + 1
        if lastOpen < #ActivityInfo.Time and nowTime > XTime.ParseToTimestamp(ActivityInfo.Time[currentOpen]) then
            return true, currentOpen, ActivityInfo.StoryId[currentOpen]
        else
            return false
        end
    end

    -- 设置第一次打开
    function XChristmasTreeManager.SetOpen(currentOpen)
        XSaveTool.SaveData(GetKey(OpenKey), tonumber(currentOpen))
    end
    
    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, function()
        XChristmasTreeManager.Init()
    end)
    
    return XChristmasTreeManager
end