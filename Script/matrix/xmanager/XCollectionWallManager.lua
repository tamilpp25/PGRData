local XCollectionWall = require("XEntity/XCollectionWall/XCollectionWall")

XCollectionWallManagerCreator = function()
    local XCollectionWallManager = {}

    local METHOD_NAME = {
        RequestEditCollectionWall = "EditCollectionWallRequest",                -- 保存墙编辑
        RequestEditCollectionWallIsShow = "EditCollectionWallIsShowRequest",    -- 保存展示设置
    }

    local WallEntity = {}               -- 所有收藏品墙的数据，Id做索引
    local BackgroundIsUnLock = {}       -- 墙面是否解锁，Id做索引
    local PedestalIsUnLock = {}         -- 底座是否解锁，Id做索引

    local LocalCaptureCache = {}    -- 本地截图缓存

    function XCollectionWallManager.Init()
        -- 构建WallEntity
        local collectionWallIdList = XCollectionWallConfigs.GetCollectionWallIdList()
        for _, id in ipairs(collectionWallIdList) do
            local collectionWall = XCollectionWall.New(id)
            WallEntity[id] = collectionWall
        end


        -- 获取配置表数据，按种类来初始化饰品数据
        local backgroundDecorationList = XCollectionWallConfigs.GetColDecCfgListByType(XCollectionWallConfigs.EnumDecorationType.Background)
        local pedestalDecorationList = XCollectionWallConfigs.GetColDecCfgListByType(XCollectionWallConfigs.EnumDecorationType.Pedestal)

        -- 全部初始化为未解锁
        for _, data in ipairs(backgroundDecorationList) do
            BackgroundIsUnLock[data.Id] = false
        end
        for _, data in ipairs(pedestalDecorationList) do
            PedestalIsUnLock[data.Id] = false
        end
    end

    ---
    --- 使用服务器下发的数据来更新收藏品墙
    function XCollectionWallManager.SyncWallEntityData(dataList)
        if dataList == nil then
            XLog.Error("XCollectionWallManager.SyncWallEntityData函数错误，参数dataList为 nil")
            return
        end

        for _, data in pairs(dataList) do
            -- 更新收藏品墙的状态
            XCollectionWallManager.UpdateWallEntityList(data.Id, data)
        end
    end

    ---
    --- 使用服务器下发的数据来更新装饰品
    function XCollectionWallManager.SyncDecorationData(decorationsList)
        if decorationsList == nil then
            XLog.Error("XCollectionWallManager.SyncDecorationData函数错误，参数decorationsList为 nil")
            return
        end

        for _, id in pairs(decorationsList) do
            local type = XCollectionWallConfigs.GetColDecType(id)
            if type == XCollectionWallConfigs.EnumDecorationType.Background then
                BackgroundIsUnLock[id] = true
            elseif type == XCollectionWallConfigs.EnumDecorationType.Pedestal then
                PedestalIsUnLock[id] = true
            else
                XLog.Error("XCollectionWallManager.SyncDecorationData函数错误，type不是XCollectionWallConfigs.EnumDecorationType类型的值")
            end
        end
    end

    ---
    --- 根据'data'的key来更新'wallId'收藏品墙数据实体(XCollectionWall)对应的属性
    --- 需要注意的是两者的key名称需要保持一致
    --- @param data table
    function XCollectionWallManager.UpdateWallEntityList(wallId, data)
        if WallEntity[wallId] == nil then
            XLog.Error(string.format("XCollectionWallManager.GetWallEntityData函数错误,没有Id:%的收藏品实体数据", wallId))
            return
        end

        if data == nil then
            XLog.Error("XCollectionWallManager.GetWallEntityData函数错误,参数data为 nil")
            return
        end
        WallEntity[wallId]:UpdateDate(data)

        if data.CollectionSetInfos then
            local state
            if  next(data.CollectionSetInfos) == nil then
                state = XCollectionWallConfigs.EnumWallState.None
            else
                state = XCollectionWallConfigs.EnumWallState.Normal
            end
            WallEntity[wallId]:UpdateDate({ State = state })
        end
    end

    ---
    --- 按Rank值排序'data',存放的值是XCollectionWall数据实体
    ---@param data table
    function XCollectionWallManager.SortWallEntityByRank(data)
        table.sort(data, function(a, b)
            return a:GetRank() < b:GetRank()
        end)
    end

    ---
    --- 获取所有收藏品墙的数据数组
    --- 按配置表Rank值排序
    ---@return table
    function XCollectionWallManager.GetWallEntityList()
        local result = {}

        if WallEntity == nil then
            XLog.Error("XCollectionWallManager:GetWallEntityList函数错误：WallEntity为 nil")
            return result
        end

        for _, v in pairs(WallEntity) do
            table.insert(result, v)
        end

        XCollectionWallManager.SortWallEntityByRank(result)
        return result
    end

    ---
    --- 获取已解锁并摆放了收藏品的收藏品墙数据数组
    --- 按配置表Rank值排序
    ---@return table
    function XCollectionWallManager.GetNormalWallEntityList()
        local result = {}

        if WallEntity == nil then
            XLog.Error("XCollectionWallManager:GetNormalWallEntityList函数错误：WallEntity为 nil")
            return result
        end

        for _, v in pairs(WallEntity) do
            if v.State == XCollectionWallConfigs.EnumWallState.Normal then
                table.insert(result, v)
            end
        end

        XCollectionWallManager.SortWallEntityByRank(result)
        return result
    end

    ---
    --- 获取'wallId'收藏品墙数据实体
    --- @param wallId number
    function XCollectionWallManager.GetWallEntityData(wallId)
        if WallEntity[wallId] == nil then
            XLog.Error(string.format("XCollectionWallManager.GetWallEntityData函数错误,没有Id:%的收藏品实体数据", wallId))
            return nil
        end
        return WallEntity[wallId]
    end

    ---
    --- 根据'data'上的数据来获取对应的‘selectType’的数据数组
    ---'data'是当前墙上数据来生成的
    ---
    --- 收藏品不显示正在使用与未解锁的，装饰品有使用与未解锁的状态
    --- 装饰品返回的结构：{ index = { Id, IsUnlock } }
    --- 收藏品返回的是Id数组
    ---@param data table
    ---@param selectType number
    ---@return table
    function XCollectionWallManager.GetItemList(data, selectType)
        local result = {}
        local isDecoration
        if selectType == XCollectionWallConfigs.EnumSelectType.BACKGROUND then
            isDecoration = true
            for id,isUnlock in pairs(BackgroundIsUnLock) do
                local temp = {}
                temp.Id = id
                temp.IsUnlock = isUnlock
                table.insert(result, temp)
            end
        elseif selectType == XCollectionWallConfigs.EnumSelectType.PEDESTAL then
            isDecoration = true
            for id,isUnlock in pairs(PedestalIsUnLock) do
                local temp = {}
                temp.Id = id
                temp.IsUnlock = isUnlock
                table.insert(result, temp)
            end
        elseif selectType == XCollectionWallConfigs.EnumSelectType.BIG then
            -- 质量为6的收藏品
            isDecoration = false
            local list = XDataCenter.MedalManager.GetScoreTitleByQuality(6)
            result = XCollectionWallManager.FilterUseCollection(data.CollectionSetInfos,list)
        elseif selectType == XCollectionWallConfigs.EnumSelectType.MIDDLE then
            -- 质量为5的收藏品
            isDecoration = false
            local list = XDataCenter.MedalManager.GetScoreTitleByQuality(5)
            result = XCollectionWallManager.FilterUseCollection(data.CollectionSetInfos,list)
        elseif selectType == XCollectionWallConfigs.EnumSelectType.LITTL then
            -- 质量为2、3、4的收藏品
            isDecoration = false
            local list = XDataCenter.MedalManager.GetScoreTitleByQuality(2,4)
            result = XCollectionWallManager.FilterUseCollection(data.CollectionSetInfos,list)
        end

        if isDecoration then
            table.sort(result, function(a, b)
                local aRank = XCollectionWallConfigs.GetColDecRank(a.Id)
                local bRank = XCollectionWallConfigs.GetColDecRank(b.Id)
                if aRank == bRank then
                    return a.Id < b.Id
                else
                    return aRank < bRank
                end
            end)
        else
            -- 过滤掉其他收藏品墙正在使用的收藏品
            result = XCollectionWallManager.FilterOtherUseCollection(data.Id, result)

            table.sort(result, function(a, b)
                local aPriority = XMedalConfigs.GetCollectionPriorityById(a)
                local bPriority = XMedalConfigs.GetCollectionPriorityById(b)

                if aPriority == bPriority then
                    return a < b
                else
                    return aPriority < bPriority
                end
            end)
        end

        return result
    end

    ---
    --- 过滤掉'collectionSetInfo'中使用的收藏品
    ---@param collectionSetInfo table
    ---@param filterList table
    ---@return table
    function XCollectionWallManager.FilterUseCollection(collectionSetInfo, filterList)
        local result = {}

        local useDic = {}    -- id字典
        local useGroup = {}  -- 组id字典，同一个组的收藏品视为同一个收藏品

        for _, data in pairs(collectionSetInfo) do
            useDic[data.Id] = true
            local groupId = XMedalConfigs.GetCollectionGroupById(data.Id)
            if groupId ~= 0 and not useGroup[groupId] then
                useGroup[groupId] = data.Id
            end
        end

        -- 过滤掉使用着的收藏品
        for _, filter in pairs(filterList) do
            if not useDic[filter.Id] then
                local groupId = XMedalConfigs.GetCollectionGroupById(filter.Id)
                if not useGroup[groupId] then
                    table.insert(result, filter.Id)
                end
            end
        end

        return result
    end

    ---
    --- 过滤掉其他收藏品墙正在使用的收藏品
    --- 'filterList'为等待过滤的列表
    ---@param curWallDataId table
    ---@param filterList table
    ---@return table
    function XCollectionWallManager.FilterOtherUseCollection(curWallDataId, filterList)
        local result = {}

        local useDic = {}    -- id字典
        local useGroup = {}  -- 组id字典，同一个组的收藏品视为同一个收藏品

        for _, wallData in pairs(WallEntity) do
            if wallData:GetId() ~= curWallDataId then
                local collectionInfo = wallData:GetCollectionSetInfos()
                for _, info in pairs(collectionInfo) do
                    if useDic[info.Id] then
                        XLog.Error(string.format("XCollectionWallManager.FilterOtherUseCollection函数错误，有相同Id的收藏品被多个墙重复使用，ID:%s", info.Id))
                    end
                    useDic[info.Id] = info

                    local groupId = XMedalConfigs.GetCollectionGroupById(info.Id)
                    if groupId ~= 0 and not useGroup[groupId] then
                        useGroup[groupId] = info.Id
                    end
                end
            end
        end

        -- 过滤掉使用着的收藏品
        for _, id in pairs(filterList) do
            if not useDic[id] then
                local groupId = XMedalConfigs.GetCollectionGroupById(id)
                if not useGroup[groupId] then
                    table.insert(result, id)
                end
            end
        end

        return result
    end

    ---
    --- 通过中心本地坐标获取左下角格子坐标
    --- GridPos = (CenterLocalPos - ItemSize/2) / GridSize
    function XCollectionWallManager.GetGridPosByLocalPos(localPos, gridSize)
        -- 利用中心本地坐标算出左下角本地坐标
        local leftBottomLocalPos = CS.UnityEngine.Vector2(localPos.x - gridSize / 2, localPos.y - gridSize / 2)

        -- 0.5是格子大小一半的偏移，使坐标的计算区域称向中心区域(超出这个区域，gridPos就换成其他坐标)
        local gridPos = CS.UnityEngine.Vector2Int(math.floor((leftBottomLocalPos.x) / XCollectionWallConfigs.CellSize + 0.5),
                math.floor(leftBottomLocalPos.y / XCollectionWallConfigs.CellSize + 0.5));
        return gridPos
    end

    ---
    --- 通过左下角格子坐标获取中心本地坐标
    --- CenterLocalPos = GirdPos * GridSize + ItemSize/2
    function XCollectionWallManager.GetLocalPosByGridPos(gridPos, gridSize)
        local localPos

        -- 左下角本地坐标为格子坐标*格子长度
        local leftBottomLocalPos = CS.UnityEngine.Vector2(gridPos.x * XCollectionWallConfigs.CellSize, gridPos.y * XCollectionWallConfigs.CellSize)

        -- 中心本地坐标相对左下角本地坐标的偏移为物体尺寸的一半
        localPos = CS.UnityEngine.Vector2(leftBottomLocalPos.x + gridSize / 2, leftBottomLocalPos.y + gridSize / 2)

        return localPos
    end

    function XCollectionWallManager.IsNeedSave(wallDataId, curWallData)
        local wallData = XCollectionWallManager.GetWallEntityData(wallDataId)
        local lastCollectionSetInfo = wallData:GetCollectionSetInfos()

        if #curWallData.CollectionSetInfos ~= #lastCollectionSetInfo then
            return true
        end

        -- 墙面与底面
        if curWallData.BackgroundId ~= wallData:GetBackgroundId()
                or curWallData.PedestalId ~= wallData:GetPedestalId() then
            return true
        end

        -- 摆放的收藏品
        local curCollectionSetInfoDic = {}
        for _, v in pairs(curWallData.CollectionSetInfos) do
            curCollectionSetInfoDic[v.Id] = v
        end
        for _, v in pairs(lastCollectionSetInfo) do
            local curCollection = curCollectionSetInfoDic[v.Id]
            if curCollection == nil then
                return true
            end

            if v.X ~= curCollection.X or v.Y ~= curCollection.Y or v.SizeId ~= curCollection.SizeId then
                return true
            end
        end

        return false
    end

    function XCollectionWallManager.GetCaptureImgName(wallDataId)
        return string.format("%s%s", tostring(XPlayer.Id), tostring(wallDataId))
    end

    function XCollectionWallManager.GetLocalCaptureCache(id)
        local texture = LocalCaptureCache[id]
        return texture or nil
    end

    function XCollectionWallManager.SetLocalCaptureCache(id, texture)
        LocalCaptureCache[id] = texture
    end

    function XCollectionWallManager.ClearLocalCaptureCache()
        for _, texture in pairs(LocalCaptureCache) do
            if not XTool.UObjIsNil(texture) then
                CS.UnityEngine.Object.Destroy(texture)
            end
        end
        LocalCaptureCache = {}
    end

    function XCollectionWallManager.CaptureCamera(imgName, cb)
        if not imgName then
            return nil
        end

        CS.XScreenCapture.ScreenCaptureWithCallBack(CS.XUiManager.Instance.UiCamera,function(texture)
            CS.XTool.SaveCaptureImg(imgName, texture);
            XCollectionWallManager.SetLocalCaptureCache(imgName, texture)
            if cb then
                cb()
            end
        end)
    end

    function XCollectionWallManager.GetShowWallList()
        local result = {}
        for _, wallData in pairs(WallEntity) do
            if wallData:GetIsShow() then
                local collectionInfo = wallData:GetCollectionSetInfos()

                if next(collectionInfo) then
                    table.insert(result, wallData)
                end
            end
        end
        return result
    end

    ------------------------------------------------------------------ 请求协议 -------------------------------------------------------

    ---
    --- 请求保存收藏品墙的展示设置
    --- 'isShowInfos' = { Id， IsShow }
    ---@param isShowInfos table
    ---@param cb function
    function XCollectionWallManager.RequestEditCollectionWallIsShow(isShowInfos, cb)
        XNetwork.Call(METHOD_NAME.RequestEditCollectionWallIsShow, { CollectionWallIsShowInfos = isShowInfos }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            for _, showInfo in pairs(isShowInfos) do
                XCollectionWallManager.UpdateWallEntityList(showInfo.Id, { IsShow = showInfo.IsShow })
            end

            if cb then
                cb()
            end
        end)
    end

    ---
    --- 请求编辑收藏品墙，'wallId'是收藏品墙Id，'pedestalId'是底座Id，'backgroundId'是背景Id
    --- 'setInfo'是收藏品信息，结构为{ Id, X, Y, SizeId }
    ---@param wallId number
    ---@param pedestalId number
    ---@param backgroundId number
    ---@param setInfo table
    ---@param cb function
    ---@param errorCb function
    function XCollectionWallManager.RequestEditCollectionWall(wallId, pedestalId, backgroundId, setInfo, cb, errorCb)
        local req = { Id = wallId, PedestalId = pedestalId, BackgroundId = backgroundId, CollectionSetInfos = setInfo }

        local state
        if next(setInfo) == nil then
            state = XCollectionWallConfigs.EnumWallState.None
        else
            state = XCollectionWallConfigs.EnumWallState.Normal
        end

        XNetwork.Call(METHOD_NAME.RequestEditCollectionWall, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if errorCb then
                    errorCb()
                end
                return
            end
            XCollectionWallManager.UpdateWallEntityList(wallId,
                    { PedestalId = pedestalId, BackgroundId = backgroundId, State = state, CollectionSetInfos = setInfo })
            if cb then
                cb()
            end
        end)
    end

    XCollectionWallManager.Init()
    return XCollectionWallManager
end

-- 解锁底座或背景时推送(数据包括之前解锁的饰品)
XRpc.NotifyWallDecoration = function(data)
    XDataCenter.CollectionWallManager.SyncDecorationData(data.UnlockedDecorationIds)
end

-- 解锁收藏品墙时推送(数据只有新解锁的墙)
XRpc.NotifyWallInfo = function(data)
    XDataCenter.CollectionWallManager.SyncWallEntityData(data.Walls)
end

