---理器
---
XFurnitureManagerCreator = function()
    ---@class XFurnitureManager 家具管理器
    local XFurnitureManager = {}

    ---@type table<number, XHomeFurnitureData>
    local FurnitureDatas = {}               -- 家具数据 table = {id = XHomeFurnitureData}
    local OtherFurnitureDatas = {}          -- 家具数据(其他人的) table = {id = XHomeFurnitureData}
    local FurnitureCategoryTypes = {}       -- 家具类型 table = {FurnitureTypeId = {ids}}
    local FurnitureSingleUnUse = {}         -- ConfigId家具未使用列表 table = {FurnitureConfigId = {ids}}
    local FurnitureCreateDatas = {}         -- 家具创建列表
    local CollectNoneRoomFurnitureList = {} -- 空收藏场景表
    local FurnitureDatasCount = 0           -- 擁有家具总数
    local IsInReforming = false             -- 是否在家具摆放中
    local NewSuitFurnitureData = {}         -- 新套装家具数据
    local MaxFurnitureRecordMap             -- 最高分家具记录
    local ShowDetailData = {
        ConfigId = 0,
        IsOwn = false
    }

    local function GetCookieKey(key)
        return string.format("DORM_CACHE_UID_%s_NEW_HINT_%s", tostring(XPlayer.Id), key)
    end
    
    local FurnitureRequest = {
        DecomposeFurniture      = "DecomposeFurnitureRequest",   --分解家具
        CreateFurniture         = "CreateFurnitureRequest",      --建造家具
        CheckCreateFurniture    = "CheckCreateFurnitureRequest", --领取家具
        RemouldFurniture        = "RemouldFurnitureRequest",     --改造家具
        PutFurniture            = "PutFurnitureRequest",         --家具摆放
        FurnitureRemake         = "FurnitureRemakeRequest",      --重新建造家具
        SetFurnitureLock        = "SetFurnitureOptLockRequest",  --锁定或解锁家具
    }
    
    local HandleUiMap = { 
        UiFurnitureObtain = true,
        UiFurnitureDetail = true,
    }
    
    --- 界面可操作
    ---@param evt string 事件名
    ---@param args System.Object[]
    --------------------------
    local function OnUiOpenDone(evt, args)
        ---@type XGameUi
        local ui = args[0]
        if not ui or not ui.UiData then
            return
        end
        local uiName = ui.UiData.UiName
        if not HandleUiMap[uiName] then
            return
        end
        
        if XTool.IsTableEmpty(NewSuitFurnitureData) then
            return
        end
        
        local showSuitId
        --展示了不是自己已有的家具
        if uiName == "UiFurnitureDetail" then
            if not ShowDetailData.IsOwn then
                return
            end
            for suid, configId2IdMap in pairs(NewSuitFurnitureData) do
                if configId2IdMap[ShowDetailData.ConfigId] then
                    showSuitId = suid
                    break
                end
            end
            if not showSuitId then
                return
            end
        end
        
        local targetUiName = "UiDormArchiveUnlock"
        if XLuaUiManager.IsUiShow(targetUiName) 
                or XLuaUiManager.IsUiLoad(targetUiName) then
            return
        end
        
        local asyncOpenArchive = asynTask(function(suitId, furnitureIds, cb) 
            XLuaUiManager.Open(targetUiName, suitId, furnitureIds, cb)
        end)
        
        RunAsyn(function()
            local removeSuit = {}
            if showSuitId then
                asyncOpenArchive(showSuitId, NewSuitFurnitureData[showSuitId])
                table.insert(removeSuit, showSuitId)
            else
                for suid, configId2IdMap in pairs(NewSuitFurnitureData) do
                    asyncOpenArchive(suid, configId2IdMap)
                    table.insert(removeSuit, suid)
                end
            end
            
            for _, suid in pairs(removeSuit) do
                NewSuitFurnitureData[suid] = nil
            end
            
        end)
    end
    
    local function Init()
        CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_DONE, OnUiOpenDone)
        CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_DONE, OnUiOpenDone)
        --初始化记录
        local recordMap = XSaveTool.GetData(GetCookieKey("MAX_FURNITURE_RECORD")) or {}
        MaxFurnitureRecordMap = recordMap
        
    end

    function XFurnitureManager.InitFurnitureCreateList(response)
        if not response or not response.FurnitureCreateList then return end
        FurnitureCreateDatas = response.FurnitureCreateList
    end

    function XFurnitureManager.InitData(furnitureList)
        if not furnitureList or not next(furnitureList) then
            return
        end
        -- MinorType 加入全部类型
        FurnitureDatas = {}
        FurnitureCategoryTypes = {}
        FurnitureSingleUnUse = {}

        FurnitureCategoryTypes[XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID] = {}


        local furnitureDatasCount = 0
        for _, data in pairs(furnitureList) do
            if FurnitureDatas[data.Id] then
                XLog.Error("XFurnitureManager.InitData error:id is repeated, id = " .. data.Id)
            else
                FurnitureDatas[data.Id] = XHomeFurnitureData.New(data)
            end

            if data.DormitoryId <= 0 then
                XFurnitureManager.AddFurnitureSingleUnUse(data.ConfigId, data.Id)
            end

            local typeConfig = XFurnitureConfigs.GetFurnitureTypeCfgByConfigId(data.ConfigId)
            if not FurnitureCategoryTypes[typeConfig.Id] then
                FurnitureCategoryTypes[typeConfig.Id] = {}
            end

            table.insert(FurnitureCategoryTypes[typeConfig.Id], data.Id)
            table.insert(FurnitureCategoryTypes[XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID], data.Id)
            furnitureDatasCount = furnitureDatasCount + 1
        end

        FurnitureDatasCount = furnitureDatasCount
    end

    ---------------------start Data---------------------
    -- 本地管理的红点 -> 移除
    function XFurnitureManager.DeleteNewHint(ids)
        local needSave = false
        for _, id in ipairs(ids) do
            local key = XPrefs.DormNewHint .. tostring(XPlayer.Id) .. id
            if CS.UnityEngine.PlayerPrefs.HasKey(key) then
                CS.UnityEngine.PlayerPrefs.DeleteKey(key)
                needSave = true
            end
        end

        if needSave then
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    -- 本地管理的红点 -> 增加Id 表示此红点不再出现！
    function XFurnitureManager.AddNewHint(ids)
        local needSave = false
        for _, id in ipairs(ids) do
            local key = XPrefs.DormNewHint .. tostring(XPlayer.Id) .. id
            if not CS.UnityEngine.PlayerPrefs.HasKey(key) then
                CS.UnityEngine.PlayerPrefs.SetString(key, key)
                needSave = true
            end
        end

        if needSave then
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    -- 本地管理的红点 -> 检查是否需要显示红点
    -- 如果本地有存储 说明不需要显示
    function XFurnitureManager.CheckNewHint(id)
        local key = XPrefs.DormNewHint .. tostring(XPlayer.Id) .. id
        return not CS.UnityEngine.PlayerPrefs.HasKey(key)
    end
    
    --是否为首次获得
    function XFurnitureManager.IsFirstObtain(id)
        local key = GetCookieKey(id)
        if not XSaveTool.GetData(key) then
            return true
        end
        return false
    end
    
    --标记为已经获得
    function XFurnitureManager.MarkFirstObtain(id)
        local key = GetCookieKey(id)
        if XSaveTool.GetData(key) then
            return
        end
        XSaveTool.SaveData(key, true)
    end
    
    function XFurnitureManager.AddNewSuitFurnitureData(furnitureId)
        if not XTool.IsNumberValid(furnitureId) then
            return
        end

        local furniture = XFurnitureManager.GetFurnitureById(furnitureId)
        if not furniture then
            return
        end
        local configId = furniture:GetConfigId()
        if not XFurnitureManager.IsFirstObtain(configId) then
            return
        end
        local suitId = furniture:GetSuitId()
        NewSuitFurnitureData[suitId] = NewSuitFurnitureData[suitId] or {}
        NewSuitFurnitureData[suitId][configId] = furnitureId
    end
    
    function XFurnitureManager.DelNewSuitFurnitureData(furnitureId)
        if not XTool.IsNumberValid(furnitureId) then
            return
        end

        local furniture = XFurnitureManager.GetFurnitureById(furnitureId)
        if not furniture then
            return
        end
        local configId = furniture:GetConfigId()
        local suitId = furniture:GetSuitId()
        if not NewSuitFurnitureData[suitId] then
            return
        end
        NewSuitFurnitureData[suitId][configId] = nil
    end
    
    function XFurnitureManager.SetDetailData(isOwn, configId)
        ShowDetailData.IsOwn = isOwn
        ShowDetailData.ConfigId = configId
    end
    
    function XFurnitureManager.AddMaxRecord(furnitureId)
        if not XTool.IsNumberValid(furnitureId) then
            return
        end
        local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
        if not furniture then
            return
        end
        local configId = furniture:GetConfigId()
        local newScore = furniture:GetScore()
        local oldScore = MaxFurnitureRecordMap[configId]
    
        if oldScore and oldScore > newScore then --不必添加
            return
        else
            MaxFurnitureRecordMap[configId] = newScore
        end

        XSaveTool.SaveData(GetCookieKey("MAX_FURNITURE_RECORD"), MaxFurnitureRecordMap)
    end
    
    function XFurnitureManager.RemoveMaxRecord(configId)
        if not XTool.IsNumberValid(configId) then
            return
        end

        --不需要移除
        if not MaxFurnitureRecordMap[configId] then
            return
        end 

        MaxFurnitureRecordMap[configId] = nil

        XSaveTool.SaveData(GetCookieKey("MAX_FURNITURE_RECORD"), MaxFurnitureRecordMap)
    end


    function XFurnitureManager.CheckIsMaxScore(configId)
        return MaxFurnitureRecordMap[configId] ~= nil
    end

    function XFurnitureManager.CheckIsMaxScoreByConfigIds(configIds)
        if XTool.IsTableEmpty(configIds) then
            return false
        end
        for _, configId in pairs(configIds) do
            if XFurnitureManager.CheckIsMaxScore(configId) then
                return true
            end
        end
        return false
    end

    -- 通过家具唯一Id 获取家具ConfigId
    function XFurnitureManager.GetFurnitureConfigId(id, dormDataType)
        local t = XFurnitureManager.GetFurnitureById(id, dormDataType)
        return t.ConfigId
    end

    -- 获取家具配置表By 唯一Id
    function XFurnitureManager.GetFurnitureConfigByUniqueId(uniqueId, dormDataType)
        local t = XFurnitureManager.GetFurnitureById(uniqueId, dormDataType)
        return XFurnitureConfigs.GetFurnitureTemplateById(t.ConfigId)
    end

    --获取所有家具数据
    function XFurnitureManager.GetFurnitureDatas()
        return FurnitureDatas
    end
    
    --获取玩家是否拥有当前家具
    function XFurnitureManager.CheckFurnitureExist(furnitureId)
        return FurnitureDatas[furnitureId] ~= nil
    end

    --获取所擁有家具总数
    function XFurnitureManager.GetAllFurnitureCount()
        return FurnitureDatasCount
    end

    -- 获取家具
    function XFurnitureManager.GetFurnitureById(ids, dormDataType)
        local datas = FurnitureDatas
        if dormDataType == XDormConfig.DormDataType.Target then
            datas = OtherFurnitureDatas
        end

        local func = function(id)
            local t = datas[id]
            if not t and t ~= nil then
                XLog.Error("XFurnitureManager.GetFurnitureById error:id is not found, id = " .. id)
                return nil
            end

            return t
        end

        if type(ids) == "table" then
            local furnitureDatas = {}
            for _, id in ipairs(ids) do
                local furnitureData = func(id)
                table.insert(furnitureDatas, furnitureData)
            end
            return furnitureDatas
        else
            local furnitureData = func(ids)
            return furnitureData
        end
    end

    function XFurnitureManager.AddFurnitureSingleUnUse(configId, id)
        if not FurnitureSingleUnUse[configId] then
            FurnitureSingleUnUse[configId] = {}
        end

        table.insert(FurnitureSingleUnUse[configId], id)
    end

    function XFurnitureManager.RemoveFurnitureSingleUnUse(configId, id)
        if not FurnitureSingleUnUse[configId] then
            return
        end

        local index
        for i, v in ipairs(FurnitureSingleUnUse[configId]) do
            if id == v then
                index = i
                break
            end
        end

        if index then
            table.remove(FurnitureSingleUnUse[configId], index)
        end
    end

    --设置家具为使用状态
    function XFurnitureManager.SetFurnitureState(furnitureId, dormitoryId)
        local furniture = XFurnitureManager.GetFurnitureById(furnitureId)
        if furniture then
            furniture:SetUsedDormitoryId(dormitoryId)

            if dormitoryId > 0 then
                XFurnitureManager.RemoveFurnitureSingleUnUse(furniture.ConfigId, furniture.Id)
            else
                XFurnitureManager.AddFurnitureSingleUnUse(furniture.ConfigId, furniture.Id)
            end
        end
    end

    --查看家具是否在使用中
    function XFurnitureManager.CheckFurnitureUsing(furnitureId, dormDataType)
        local isUsing = false
        if XDormConfig.IsTemplateRoom(dormDataType) then
            return isUsing
        end

        local furniture = XFurnitureManager.GetFurnitureById(furnitureId, dormDataType)
        if furniture and furniture:CheckIsUsed() then
            isUsing = true
        end

        return isUsing
    end

    -- 获取未使用的家具列表
    function XFurnitureManager.GetUnusedFurnitureList()
        local list = {}
        for _, furniture in pairs(FurnitureDatas) do
            if furniture and furniture.DormitoryId > 0 then
                table.insert(list, furniture)
            end
        end

        return list
    end

    -- 获取CategoryType的家具的个数
    function XFurnitureManager.GetFurnitureCategoryCount(selectIds)
        local count = 0
        for _, selectId in ipairs(selectIds) do
            if FurnitureCategoryTypes[selectId] then
                count = count + #FurnitureCategoryTypes[selectId]
            end
        end

        return count
    end

    -- 获取不在使用中的家具通过ConfigId
    function XFurnitureManager.GetUnUseFurnitureById(configId)
        local list = FurnitureSingleUnUse[configId]
        return list or {}
    end

    function XFurnitureManager.GetUnUseFurniture()
        return FurnitureSingleUnUse or {}
    end

    local CheckSuit = function(selectSuitIds, furinitureId)
        if not selectSuitIds or #selectSuitIds <= 0 then
            return true
        end

        for _, suitId in ipairs(selectSuitIds) do
            if suitId == XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID then
                return true
            end

            local tempCfg = XFurnitureManager.GetFurnitureConfigByUniqueId(furinitureId)
            if tempCfg.SuitId == suitId then
                return true
            end
        end

        return false
    end

    -- 获取FurnitureTypeId的家具唯一Ids
    function XFurnitureManager.GetFurnitureCategoryIds(selectIds, selectSuitIds, isRemoveUsed, orderType, isRemoveUnuse, isRemoveLock)
        local ids = {}
        for _, selectId in ipairs(selectIds) do
            if FurnitureCategoryTypes[selectId] then
                for _, id in ipairs(FurnitureCategoryTypes[selectId]) do
                    if isRemoveUsed and XFurnitureManager.CheckFurnitureUsing(id) then
                        goto continue
                    end

                    if isRemoveUnuse and not XFurnitureManager.CheckFurnitureUsing(id) then
                        goto continue
                    end

                    if isRemoveLock and XFurnitureManager.GetFurnitureIsLocked(id) then
                        goto continue
                    end
 
                    if not CheckSuit(selectSuitIds, id) then
                        goto continue
                    end

                    table.insert(ids, id)
                    :: continue ::
                end
            end
        end

        table.sort(ids, function(a, b)
            -- 是否使用
            local usingA = XFurnitureManager.CheckFurnitureUsing(a)
            local usingB = XFurnitureManager.CheckFurnitureUsing(b)
            if usingA ~= usingB then
                return usingB
            end

            -- 判断积分
            local scoreA = XFurnitureManager.GetFurnitureScore(a)
            local scoreB = XFurnitureManager.GetFurnitureScore(b)
            if orderType == XFurnitureConfigs.FurnitureOrderType.LevelAsscend
                    or orderType == XFurnitureConfigs.FurnitureOrderType.LevelDescend then
                local furnitureTypeA = XFurnitureManager.GetFurnitureConfigByUniqueId(a).TypeId
                local levelA = XFurnitureConfigs.GetFurnitureTotalAttrLevel(furnitureTypeA, scoreA)
                local furnitureTypeB = XFurnitureManager.GetFurnitureConfigByUniqueId(b).TypeId
                local levelB = XFurnitureConfigs.GetFurnitureTotalAttrLevel(furnitureTypeB, scoreB)
                if levelA ~= levelB then
                    if orderType == XFurnitureConfigs.FurnitureOrderType.LevelAsscend then
                        return levelA < levelB
                    else
                        return levelA > levelB
                    end
                end
            end
            if scoreA ~= scoreB then
                if orderType == XFurnitureConfigs.FurnitureOrderType.ScoreAsscend then
                    return scoreA < scoreB
                else
                    return scoreA > scoreB
                end
            end

            -- 判断类型
            local configIdA = XFurnitureManager.GetFurnitureConfigId(a)
            local minorA = XFurnitureConfigs.GetFurnitureTypeCfgByConfigId(configIdA).MinorType

            local configIdB = XFurnitureManager.GetFurnitureConfigId(b)
            local minorB = XFurnitureConfigs.GetFurnitureTypeCfgByConfigId(configIdB).MinorType

            if minorA ~= minorB then
                return minorA < minorB
            end

            return a < b
        end)

        return ids
    end
    
    --- 获取FurnitureTypeId的家具唯一Ids,不排序
    ---@param typeIds number[] 家具类型Id
    ---@param suitIds number[] 家具套装Id
    ---@param levelMap table<number,boolean> 过滤等级
    ---@param isRemoveUsed boolean 剔除使用中的
    ---@param isRemoveUnUse boolean 剔除未使用中的
    ---@param isRemoveLock boolean 剔除未解锁的
    ---@param onlyShowBase boolean 仅仅显示基础家具
    ---@return
    --------------------------
    function XFurnitureManager.GetFurnitureCategoryIdsNoSort(typeIds, suitIds, levelMap, isRemoveUsed, isRemoveUnUse, isRemoveLock, onlyShowBase, filterFurnitureIdMap)
        local ids = {}
        local checkLevel = not XTool.IsTableEmpty(levelMap)
        local suitMap = {}
        local checkSuit = not XTool.IsTableEmpty(suitIds)
        if checkSuit then
            for _, suitId in pairs(suitIds) do
                suitMap[suitId] = true
            end
        end
        local checkFilter = not XTool.IsTableEmpty(filterFurnitureIdMap)
        for _, typeId in ipairs(typeIds) do
            local furnitureIds = FurnitureCategoryTypes[typeId]
            if not XTool.IsTableEmpty(furnitureIds) then
                for _, id in ipairs(furnitureIds) do
                    local template = XFurnitureManager.GetFurnitureConfigByUniqueId(id)
                    --过滤家具(支持家具Id与配置Id)
                    if checkFilter and (filterFurnitureIdMap[id] or filterFurnitureIdMap[template.Id]) then
                        goto continue
                    end
                    --基础套件
                    if onlyShowBase and template.SuitId ~= XFurnitureConfigs.BASE_SUIT_ID then
                        goto continue
                    end
                    
                    --剔除使用中
                    if isRemoveUsed and XFurnitureManager.CheckFurnitureUsing(id) then
                        goto continue
                    end

                    --剔除未使用中
                    if isRemoveUnUse and not XFurnitureManager.CheckFurnitureUsing(id) then
                        goto continue
                    end

                    --剔除未解锁
                    if isRemoveLock and XFurnitureManager.GetFurnitureIsLocked(id) then
                        goto continue
                    end

                    --剔除等级
                    if checkLevel then
                        local furnitureData = XFurnitureManager.GetFurnitureById(id)
                        if not levelMap[furnitureData:GetFurnitureTotalAttrLevel()] then
                            goto continue
                        end
                    end
                    
                    --剔除套装
                    if checkSuit and not (suitMap[XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID] or suitMap[template.SuitId]) then
                        goto continue
                    end
                    
                    table.insert(ids, id)
                    :: continue ::
                end
            end
        end
        
        return ids
    end

    -- 获取已拥有的家具配置id列表
    function XFurnitureManager.GetTotalFurnitureIds()
        local configIds = {}
        local furnitureIds = XFurnitureManager.GetFurnitureCategoryIds({ XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID },
                                                                       { XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID }, false)
        for _, id in pairs(furnitureIds) do
            local furnitureData = XFurnitureManager.GetFurnitureConfigByUniqueId(id)
            if furnitureData then
                configIds[furnitureData.Id] = furnitureData.Id
            end
        end

        return configIds
    end

    -- 判断是否已经有的该图鉴
    function XFurnitureManager.IsFieldGuideHave(id)
        if not id then
            return false
        end

        local ids = XFurnitureManager.GetTotalFurnitureIds() or {}
        return ids[id] ~= nil
    end

    -- 获取家具得总积分
    function XFurnitureManager.GetFurnitureScore(furnitureId,dormDataType)
        local t = XFurnitureManager.GetFurnitureById(furnitureId,dormDataType)
        if not t then
            return 0
        end

        return t:GetScore()
    end

    function XFurnitureManager.GetFurnitureRedScore(furnitureId, dormDataType)
        local t = XFurnitureManager.GetFurnitureById(furnitureId, dormDataType)
        if t then
            return t:GetRedScore()
        end

        return 0
    end

    function XFurnitureManager.GetFurnitureYellowScore(furnitureId, dormDataType)
        local t = XFurnitureManager.GetFurnitureById(furnitureId, dormDataType)
        if t then
            return t:GetYellowScore()
        end

        return 0
    end

    function XFurnitureManager.GetFurnitureBlueScore(furnitureId, dormDataType)
        local t = XFurnitureManager.GetFurnitureById(furnitureId, dormDataType)
        if t then
            return t:GetBlueScore()
        end

        return 0
    end
    --===================
    --获取家具是否上锁
    --@param furnitureId:家具ID
    --=================== 
    function XFurnitureManager.GetFurnitureIsLocked(furnitureId)
        local t = XFurnitureManager.GetFurnitureById(furnitureId)
        if t then
            return t:GetIsLocked()
        end

        return false
    end
    -- 获取家具特殊效果描述
    function XFurnitureManager.GetFurnitureEffectDesc(furnitureId)
        local t = XFurnitureManager.GetFurnitureById(furnitureId)
        if t.Addition <= 0 then
            return CS.XTextManager.GetText("DormFurnitureEffectDescNull")
        end

        local addConfig = XFurnitureConfigs.GetAdditionAttrConfigById(t.Addition)
        return addConfig.Introduce
    end

    -- 分别获取家具三条属性总分(attrA, attrB, attrC)
    function XFurnitureManager.GetFurniturePartScore(furnitureIds,dormDataType)
        local attrA = 0
        local attrB = 0
        local attrC = 0

        if furnitureIds then
            for _, id in ipairs(furnitureIds) do
                local t = XFurnitureManager.GetFurnitureById(id,dormDataType)
                if t then
                    attrA = attrA + t:GetRedScore()
                    attrB = attrB + t:GetYellowScore()
                    attrC = attrC + t:GetBlueScore()
                end
            end
        end

        return attrA, attrB, attrC
    end

    -- 添加家具
    function XFurnitureManager.AddFurniture(furnitureData, dormDataType, isInUse)
        local datas
        if not dormDataType then
            dormDataType = XDormConfig.DormDataType.Self
        end
        if dormDataType == XDormConfig.DormDataType.Self then
            datas = FurnitureDatas
        else
            datas = OtherFurnitureDatas
        end


        if datas[furnitureData.Id] then
            XLog.Error("FurnitureDatas is already exist furniture id is" .. furnitureData.Id)
            return
        end

        if dormDataType == XDormConfig.DormDataType.Self then
            XDataCenter.DormManager.FurnitureUnlockList[furnitureData.ConfigId] = furnitureData.ConfigId
        end
        local furniture = XHomeFurnitureData.New(furnitureData)
        datas[furnitureData.Id] = furniture

        if not dormDataType or dormDataType == XDormConfig.DormDataType.Self then
            FurnitureDatasCount = FurnitureDatasCount + 1

            -- FurnitureCategoryTypes同时添加
            local configId = furnitureData.ConfigId
            local furnitureTypeId = XFurnitureConfigs.GetFurnitureTypeCfgByConfigId(configId).Id
            if not FurnitureCategoryTypes[furnitureTypeId] then
                FurnitureCategoryTypes[furnitureTypeId] = {}
            end

            if not FurnitureCategoryTypes[XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID] then
                FurnitureCategoryTypes[XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID] = {}
            end

            table.insert(FurnitureCategoryTypes[furnitureTypeId], furnitureData.Id)
            table.insert(FurnitureCategoryTypes[XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID], furnitureData.Id)

            if not isInUse then
                -- 家具ConfigList同时添加
                XFurnitureManager.AddFurnitureSingleUnUse(furnitureData.ConfigId, furnitureData.Id)
            end
            local roomId = furnitureData.DormitoryId
            if roomId > 0 then
                local roomData = XDataCenter.DormManager.GetRoomDataByRoomId(roomId)
                if roomData then
                    roomData:AddFurniture(furnitureData.Id, furnitureData.ConfigId, furnitureData.X, furnitureData.Y, furnitureData.Angle)
                end
            end
          
            -- 添加标记
            XFurnitureManager.AddNewSuitFurnitureData(furnitureData.Id)
        end
    end

    -- 移除家具(其他人的)
    function XFurnitureManager.RemoveFurnitureOther()
        OtherFurnitureDatas = {}
    end

    -- 移除家具
    function XFurnitureManager.RemoveFurniture(furnitureId)
        -- 先FurnitureCategoryTypes 同时移除
        local configId = XFurnitureManager.GetFurnitureConfigId(furnitureId)
        XFurnitureManager.RemoveMaxRecord(configId)
        local furnitureTypeId = XFurnitureConfigs.GetFurnitureTypeCfgByConfigId(configId).Id
        XFurnitureManager.RemoveFurnitureSingleUnUse(configId, furnitureId)
        XFurnitureManager.DelNewSuitFurnitureData(furnitureId)
        
        if FurnitureCategoryTypes[furnitureTypeId] then
            local index
            for i, v in ipairs(FurnitureCategoryTypes[furnitureTypeId]) do
                if furnitureId == v then
                    index = i
                    break
                end
            end

            if index then
                table.remove(FurnitureCategoryTypes[furnitureTypeId], index)
            end
        end

        if FurnitureCategoryTypes[XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID] then
            local index
            for i, v in ipairs(FurnitureCategoryTypes[XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID]) do
                if furnitureId == v then
                    index = i
                    break
                end
            end

            if index then
                table.remove(FurnitureCategoryTypes[XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID], index)
            end
        end

        if not FurnitureDatas[furnitureId] or FurnitureDatas[furnitureId] == nil then
            XLog.Error("FurnitureDatas is not exist furniture id is" .. furnitureId)
            return
        end
        local furniture = FurnitureDatas[furnitureId]
        local roomId = furniture:GetDormitoryId()
        if roomId > 0 then
            local roomData = XDataCenter.DormManager.GetRoomDataByRoomId(roomId)
            if roomData then
                roomData:RemoveFurniture(furnitureId, configId)
            end
        end
        if FurnitureDatasCount and FurnitureDatasCount > 0 then
            FurnitureDatasCount = FurnitureDatasCount - 1
        end
        
        FurnitureDatas[furnitureId] = nil
    end

    -- 服务器推送增加家具
    function XFurnitureManager.NotifyFurnitureOperate(data)
        if data == nil or #data <= 0 then
            return
        end

        for _, v in pairs(data) do
            if v.OperateType == XFurnitureConfigs.FurnitureOperate.Add then
                XFurnitureManager.AddFurniture(v.ClientFurniture)
            elseif v.OperateType == XFurnitureConfigs.FurnitureOperate.Delete then
                XFurnitureManager.RemoveFurniture(v.ClientFurniture.Id)
            end
        end
    end

    -- 获取家具等级奖励Id
    function XFurnitureManager.GetLevelRewardId(furnitureId)
        local allScore = XFurnitureManager.GetFurnitureScore(furnitureId)
        local configId = XFurnitureManager.GetFurnitureConfigId(furnitureId)
        local furnitureTypeId = XFurnitureConfigs.GetFurnitureTypeCfgByConfigId(configId).Id
        local levelConfigs = XFurnitureConfigs.GetFurnitureLevelTemplate(furnitureTypeId)
        local rewardId

        for _, levelConfig in pairs(levelConfigs) do
            if allScore >= levelConfig.MinScore and allScore < levelConfig.MaxScore then
                rewardId = levelConfig.ReturnId
                break
            end
        end

        return rewardId
    end
    
    -- 获取家具制作时的奖励Id
    function XFurnitureManager.GetBaseRewardId(furnitureId)
        local furniture = XFurnitureManager.GetFurnitureById(furnitureId)
        if not furniture then
            return 0
        end
        
        local baseScore = furniture:GetAttrTotal()
        local configId = XFurnitureManager.GetFurnitureConfigId(furnitureId)
        local furnitureTypeId = XFurnitureConfigs.GetFurnitureTypeCfgByConfigId(configId).Id
        local levelConfigs = XFurnitureConfigs.GetFurnitureLevelTemplate(furnitureTypeId)
        local rewardId

        for _, levelConfig in pairs(levelConfigs) do
            if baseScore >= levelConfig.MinScore and baseScore < levelConfig.MaxScore then
                rewardId = levelConfig.ReturnId
                break
            end
        end

        return rewardId
    end

    -- 获取家具品质
    function XFurnitureManager.GetLevelRewardQuality(furnitureId)
        local allScore = XFurnitureManager.GetFurnitureScore(furnitureId)
        local configId = XFurnitureManager.GetFurnitureConfigId(furnitureId)
        local furnitureTypeId = XFurnitureConfigs.GetFurnitureTypeCfgByConfigId(configId).Id
        local levelConfigs = XFurnitureConfigs.GetFurnitureLevelTemplate(furnitureTypeId)
        local quality
        for _, levelConfig in pairs(levelConfigs) do
            if allScore >= levelConfig.MinScore and allScore < levelConfig.MaxScore then
                quality = levelConfig.Quality
                break
            end
        end

        if not quality then
            XLog.Error("XFurnitureManager.GetLevelRewardQuality Error allScore is " .. allScore)
            return 1
        end
        return quality
    end

    -- 获得回收家具的奖励列表
    function XFurnitureManager.GetRecycleRewards(furnitureIds)
        local rewards = {}
        local rewardIds = {}
        local recycleRewards = {}

        for _, furnitureId in ipairs(furnitureIds) do
            local levelRewardId = XFurnitureManager.GetLevelRewardId(furnitureId)

            local configId = XFurnitureManager.GetFurnitureConfigId(furnitureId)
            local normalRewardId = XFurnitureConfigs.GetFurnitureReturnId(configId)

            if levelRewardId then
                table.insert(rewardIds, levelRewardId)
            end

            if normalRewardId then
                table.insert(rewardIds, normalRewardId)
            end
        end

        for _, rewardId in ipairs(rewardIds) do
            local rewardList = XRewardManager.GetRewardList(rewardId)
            for _, item in pairs(rewardList) do
                if rewards[item.TemplateId] then
                    rewards[item.TemplateId].Count = rewards[item.TemplateId].Count + item.Count
                else
                    rewards[item.TemplateId] = XRewardManager.CreateRewardGoodsByTemplate(item)
                end
            end
        end
        for _, reward in pairs(rewards) do
            table.insert(recycleRewards, reward)
        end

        if #recycleRewards > 0 then
            recycleRewards = XRewardManager.SortRewardGoodsList(recycleRewards)
        end

        return recycleRewards
    end
    
    -- 重置家具能获取到的奖励
    function XFurnitureManager.GetRemakeRewards(furnitureId)
        local levelRewardId = XFurnitureManager.GetLevelRewardId(furnitureId)
        local furniture = XFurnitureManager.GetFurnitureById(furnitureId)
        local costA, costB, costC = furniture:GetBaseAttr()
        local cost = costA + costB + costC

        if not XTool.IsNumberValid(levelRewardId) then
            local configId = furniture:GetConfigId()
            levelRewardId = XFurnitureConfigs.GetFurnitureReturnId(configId)
        end

        local function getRewardMap(rewardList)
            rewardList = rewardList or {}
            local rewards = {}
            for _, item in pairs(rewardList) do
                if rewards[item.TemplateId] then
                    rewards[item.TemplateId].Count = rewards[item.TemplateId].Count + item.Count
                else
                    rewards[item.TemplateId] = XRewardManager.CreateRewardGoodsByTemplate(item)
                end
            end

            return rewards
        end
        
        local rewardList = XRewardManager.GetRewardList(levelRewardId)
        local rewards = getRewardMap(rewardList)
        
        -- 如果回收的货币的数量 < 制作时的数量
        local recycleCount = rewards[XDataCenter.ItemManager.ItemId.FurnitureCoin] and rewards[XDataCenter.ItemManager.ItemId.FurnitureCoin].Count or 0
        if recycleCount >= cost then
            local baseRewardId = XFurnitureManager.GetBaseRewardId(furnitureId)
            rewardList = XRewardManager.GetRewardList(baseRewardId)
            rewards = getRewardMap(rewardList)
        end
        
        return rewards
    end

    -- 分解家具
    function XFurnitureManager.DecomposeFurniture(furnitureIds, cb)
        XNetwork.Call(FurnitureRequest.DecomposeFurniture, { FurnitureIds = furnitureIds }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb(res.RewardGoods, res.SuccessIds)
            end

            XEventManager.DispatchEvent(XEventId.EVENT_FURNITURE_ON_MODIFY)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FURNITURE_ON_MODIFY)
        end)
    end

    function XFurnitureManager.GetRewardFurnitureAttr(extraAttrId)
        local extraAttr = XFurnitureConfigs.GetFurnitureExtraAttrsById(extraAttrId)
        local total = XFurnitureConfigs.GetFurnitureBaseAttrValueById(extraAttr.BaseAttrId)
        total = total + XFurnitureConfigs.GetFurnitureBaseAttrValueById(extraAttr.RemakeExtraAttrId)

        local totalPercent = extraAttr.AttrIds[XFurnitureConfigs.AttrType.AttrA]
                            + extraAttr.AttrIds[XFurnitureConfigs.AttrType.AttrB]
                            + extraAttr.AttrIds[XFurnitureConfigs.AttrType.AttrC]

        local attrA = math.floor(extraAttr.AttrIds[XFurnitureConfigs.AttrType.AttrA] / totalPercent * total or 0)
        local attrB = math.floor(extraAttr.AttrIds[XFurnitureConfigs.AttrType.AttrB] / totalPercent * total or 0)
        local attrC = total - attrA - attrB

        return attrA, attrB, attrC
    end


    -- 获取奖励家具特殊属性id
    function XFurnitureManager.GetRewardFurnitureEffectId(furntiureRewardId)
        local template = XFurnitureConfigs.GetFurnitureReward(furntiureRewardId)
        if not template then
            return 0
        end

        return template.AdditionId
    end

    -- 获取奖励家具品质
    function XFurnitureManager.GetRewardFurnitureQuality(id)
        local template = XFurnitureConfigs.GetFurnitureReward(id)
        if not template then
            return 0
        end

        local attrScore = XFurnitureConfigs.GetFurnitureExtraAttrTotalValue(template.ExtraAttrId)
        local additionScore = XFurnitureConfigs.GetAdditionalAddScore(template.AdditionId)

        local allScore = attrScore + additionScore
        local furnitureTypeId = XFurnitureConfigs.GetFurnitureTypeCfgByConfigId(template.FurnitureId).Id
        local levelConfigs = XFurnitureConfigs.GetFurnitureLevelTemplate(furnitureTypeId)

        for _, levelConfig in ipairs(levelConfigs) do
            if allScore >= levelConfig.MinScore and allScore < levelConfig.MaxScore then
                return levelConfig.Quality
            end
        end

        return 0
    end

    -- 获取Extra家具总分
    function XFurnitureManager.GetRewardFurnitureScore(id)
        local template = XFurnitureConfigs.GetFurnitureReward(id)
        if not template then
            return 0
        end

        local attrScore = XFurnitureConfigs.GetFurnitureExtraAttrTotalValue(template.ExtraAttrId)
        local additionScore = XFurnitureConfigs.GetAdditionalAddScore(template.AdditionId)

        return attrScore + additionScore
    end

    function XFurnitureManager.SetCollectNoneFurniture(roomId, furnitureList)
        CollectNoneRoomFurnitureList[roomId] = furnitureList
    end

    function XFurnitureManager.GetCollectNoneFurniture(roomId)
        return CollectNoneRoomFurnitureList[roomId]
    end

    function XFurnitureManager.CheckCollectNoneFurniture(roomId)
        return CollectNoneRoomFurnitureList[roomId] ~= nil
    end

    function XFurnitureManager.IsFurnitureMatchType(id, targetType)
        local furnitureDatas = XFurnitureManager.GetFurnitureById(id)
        local furnitureTemplates = XFurnitureConfigs.GetFurnitureTemplateById(furnitureDatas.ConfigId)
        if furnitureTemplates then
            return furnitureTemplates.TypeId == targetType
        end
        return false
    end

    function XFurnitureManager.UpdateFurnitureCreateList(pos, endTime, furniture, count)
        for _, v in pairs(FurnitureCreateDatas) do
            if v.Pos == pos then
                v.EndTime = endTime
                v.Furniture = furniture
                v.Count = count
                return
            end
        end
        table.insert(FurnitureCreateDatas, {
            Pos = pos,
            EndTime = endTime,
            Furniture = furniture,
            Count = count,
        })
    end

    function XFurnitureManager.GetFurnitureCreateItemByPos(pos)
        if not FurnitureCreateDatas then
            return nil
        end

        for _, v in pairs(FurnitureCreateDatas) do
            if v.Pos == pos then
                return v
            end
        end
    end

    function XFurnitureManager.RemoveFurnitureCreateListByPos(pos)
        local key = nil
        for k, v in pairs(FurnitureCreateDatas) do
            if v.Pos == pos then
                key = k
                break
            end
        end
        if key then
            FurnitureCreateDatas[key] = nil
        end
    end

    function XFurnitureManager.HasCollectableFurniture()
        if not FurnitureCreateDatas then
            return false
        end
        local now = XTime.GetServerNowTimestamp()
        local canCollect = false
        for _, v in pairs(FurnitureCreateDatas) do
            if v.EndTime <= now then
                canCollect = true
                break
            end
        end
        return canCollect
    end

    function XFurnitureManager.GetFurnitureCreateList()
        return FurnitureCreateDatas
    end


    --判断坑位已满
    function XFurnitureManager.IsFurnitureCreatePosFull()
        local maxCreateNum = CS.XGame.Config:GetInt("DormFurnitureCreateNum")
        if not FurnitureCreateDatas then
            return false
        end

        local buildingNum = 0
        for _, _ in pairs(FurnitureCreateDatas) do
            buildingNum = buildingNum + 1
        end

        if buildingNum == maxCreateNum then
            return true
        end

        return false
    end
    
    --版本更新后，不再使用制作队列，兼容队列里还未领取的家具
    function XFurnitureManager.RequestCreateList(cb)
        if XTool.IsTableEmpty(FurnitureCreateDatas) then
            return
        end
        local timeOfNow = XTime.GetServerNowTimestamp()
        for _, data in pairs(FurnitureCreateDatas) do
            if timeOfNow >= data.EndTime then
                XFurnitureManager.CheckCreateFurniture(data.Pos, function(furnitureList, createCount)
                    local furnitureCount = #furnitureList
                    if furnitureCount == 1 then
                        XLuaUiManager.OpenSingleUi("UiFurnitureDetail", furnitureList[1].Id, furnitureList[1].ConfigId)
                    else
                        XLuaUiManager.OpenSingleUi("UiFurnitureObtain", XFurnitureConfigs.GainType.Remake, furnitureList)
                    end

                    if cb then cb() end
                end)
            end
        end
    end



    -- 获取所有MinorType类型的家具数量，需要过滤风格参数
    function XFurnitureManager.GetFurnitureCountByMinorTypeAndSuitId(roomId, furnitureCache, suitId, minorType)
        local totalDatas = furnitureCache or {}
        local totalCount = 0

        for _, v in pairs(totalDatas) do
            local furnitureTemplate = XFurnitureConfigs.GetFurnitureTemplateById(v.ConfigId)
            local currentTypeDatas = XFurnitureConfigs.GetFurnitureTypeById(furnitureTemplate.TypeId)
            local currentBaseDatas = XFurnitureConfigs.GetFurnitureBaseTemplatesById(v.ConfigId)
            local currentFurniture = XFurnitureManager.GetFurnitureById(v.Id)
            local isUsing = currentFurniture:CheckIsUsed() and currentFurniture.DormitoryId ~= roomId--不计算其他宿舍的

            if XFurnitureConfigs.IsAllSuit(suitId) then
                --全部
                if (not isUsing) and currentTypeDatas.MinorType == minorType then
                    totalCount = totalCount + 1
                end
            else
                if (not isUsing) and currentTypeDatas.MinorType == minorType and currentBaseDatas.SuitId == suitId then
                    totalCount = totalCount + 1
                end
            end
        end
        return totalCount
    end

    function XFurnitureManager.GetFurnitureCountByMinorAndCategoryAndSuitId(roomId, furnitureCache, suitId, minor, category)
        local furnitureList = furnitureCache or {}
        local totalCount = 0
        category = category or 0

        for _, list in pairs(furnitureList) do
            for _, v in pairs(list) do
                local furnitureTemplate = XFurnitureConfigs.GetFurnitureTemplateById(v.ConfigId)
                local currentTypeData = XFurnitureConfigs.GetFurnitureTypeById(furnitureTemplate.TypeId)
                local currentBaseData = XFurnitureConfigs.GetFurnitureBaseTemplatesById(v.ConfigId)
                local currentFurniture = XFurnitureManager.GetFurnitureById(v.Id)
                local isUsing = currentFurniture:CheckIsUsed() and currentFurniture.DormitoryId ~= roomId--不计算其他宿舍的
        
                if not isUsing then
                    if XFurnitureConfigs.IsAllSuit(suitId) then
                        if currentTypeData.MinorType == minor and currentTypeData.Category == category then
                            totalCount = totalCount + 1
                        end
                    else
                        if suitId == currentBaseData.SuitId and currentTypeData.MinorType == minor and currentTypeData.Category == category then
                            totalCount = totalCount + 1
                        end
                    end
                end
            end
        end

        return totalCount
    end
    
    --- 获取过滤的家具数据并合并ConfigId一致的家具
    ---@param suitId number 套装Id
    ---@param minorType number 家具次要类型
    ---@param categoryType number 家具类别类型
    ---@return XHomeFurnitureData[][]
    --------------------------
    function XFurnitureManager.FilterAndMergeDisplayFurnitureList(suitId, minorType, categoryType, needSort)
        local totalData = XDataCenter.FurnitureManager.GetFurnitureDatas()
        local map = {}
        --是否检查套装
        local checkSuit = suitId and not XFurnitureConfigs.IsAllSuit(suitId)

        for _, data in pairs(totalData) do
            local configId = data:GetConfigId()
            local furnitureTemplate = XFurnitureConfigs.GetFurnitureTemplateById(configId)
            local baseData = XFurnitureConfigs.GetFurnitureBaseTemplatesById(configId)
            local currentTypeData = XFurnitureConfigs.GetFurnitureTypeById(furnitureTemplate.TypeId)
            local isUsing = XFurnitureManager.CheckFurnitureUsing(data:GetInstanceID())

            --未使用 && （不检查套装 || 套装Id == 参数)
            if not isUsing and (not checkSuit or baseData.SuitId == suitId) then
                local list = map[configId] or {}
                if categoryType ~= nil and categoryType ~= 0 then
                    --不为空
                    if currentTypeData.MinorType == minorType and currentTypeData.Category == categoryType then
                        table.insert(list, data)
                    end
                else
                    if currentTypeData.MinorType == minorType then
                        table.insert(list, data)
                    end
                end
                map[configId] = list
            end 
        end
        local list = {}
        
      
        local sort = function(a, b) 
            local scoreA = a:GetScore()
            local scoreB = b:GetScore()
            if scoreA ~= scoreB then
                return scoreA > scoreB
            end
            return a:GetInstanceID() < b:GetInstanceID()
        end
        
        for _, temp in pairs(map) do
            if not XTool.IsTableEmpty(temp) then
                if needSort then
                    table.sort(temp, sort)
                end
                
                table.insert(list, temp)
            end
        end

        if needSort then
            table.sort(list, function(a, b)
                return sort(a[1], b[1])
            end)
        end
        
        return list
    end

    --- 获取过滤的家具数据
    ---@param suitId number 套装Id
    ---@param minorType number 家具次要类型
    ---@param categoryType number 家具类别类型
    ---@return XHomeFurnitureData[]
    --------------------------
    function XFurnitureManager.FilterDisplayFurnitureList(suitId, minorType, categoryType)
        local totalData = XDataCenter.FurnitureManager.GetFurnitureDatas()
        local list = {}
        --是否检查套装
        local checkSuit = suitId and not XFurnitureConfigs.IsAllSuit(suitId)
        -- 过滤
        for _, v in pairs(totalData) do
            local furnitureTemplate = XFurnitureConfigs.GetFurnitureTemplateById(v.ConfigId)
            local baseData = XFurnitureConfigs.GetFurnitureBaseTemplatesById(v.ConfigId)
            local currentTypeData = XFurnitureConfigs.GetFurnitureTypeById(furnitureTemplate.TypeId)
            local isUsing = XFurnitureManager.CheckFurnitureUsing(v.Id)

            --未使用 && （不检查套装 || 套装Id == 参数)
            if not isUsing and (not checkSuit or baseData.SuitId == suitId) then
                if categoryType ~= nil and categoryType ~= 0 then
                    --不为空
                    if currentTypeData.MinorType == minorType and currentTypeData.Category == categoryType then
                        table.insert(list, v)
                    end
                else
                    if currentTypeData.MinorType == minorType then
                        table.insert(list, v)
                    end
                end
            end
        end
        return list
    end

    -- 获取家具套装数量
    function XFurnitureManager.GetFurnitureCountBySuitId(cache, suitId)

        local allTypeTemplate = XFurnitureConfigs.GetAllFurnitureTypes()
        local totalCount = 0
        if XFurnitureConfigs.IsAllSuit(suitId) then --全部套装数量
            for _, data in pairs(allTypeTemplate) do
                local cacheKey = XFurnitureManager.GenerateCacheKey(data.MinorType, data.Category)
                local list = cache and cache[cacheKey] or {}
                for _, tempList in pairs(list) do
                    totalCount = totalCount + #tempList
                end
            end
        else -- 单个套装数量
            for _, data in pairs(allTypeTemplate) do
                local cacheKey = XFurnitureManager.GenerateCacheKey(data.MinorType, data.Category)
                local list = cache and cache[cacheKey] or {}
                for _, tempList in pairs(list) do
                    for _, furniture in pairs(tempList) do
                        local baseData = XFurnitureConfigs.GetFurnitureBaseTemplatesById(furniture.ConfigId)
                        if baseData.SuitId == suitId then
                            totalCount = totalCount + 1
                        end
                    end
                end
            end
        end
        return totalCount
    end

    function XFurnitureManager.GenerateCacheKey(baseType, subType)
        if not baseType then
            return
        end
        
        subType = subType or 0
        return baseType * 10000 + subType * 100 + 1
    end

    -- 摆放家具
    function XFurnitureManager.PutFurniture(dormitoryId, furnitureList, isBehavior, func)
        XNetwork.Call(FurnitureRequest.PutFurniture, {
            DormitoryId = dormitoryId,
            FurnitureList = furnitureList
        }, function(res)
            if res.Code ~= XCode.Success then
                if isBehavior and func then
                    func(false)
                end
                XUiManager.TipCode(res.Code)
                return
            end
            
            --摆放成功后删除红点
            for _, furniture in pairs(furnitureList) do
                XFurnitureManager.RemoveMaxRecord(XFurnitureManager.GetFurnitureConfigId(furniture.Id))
            end

            if func then
                func(true)
            end
        end)
    end
    
    local function FurnitureRemouldSuccessCb(furnitureList, func, refitCb, isCloseRecycle, isCloseRemake)
        if func then func(furnitureList) end

        if #furnitureList == 1 then
            XLuaUiManager.OpenSingleUi("UiFurnitureDetail", furnitureList[1].Id, furnitureList[1].ConfigId, nil, nil, isCloseRecycle, nil, isCloseRemake)
            return
        end
        
        XLuaUiManager.OpenSingleUi("UiFurnitureObtain", XFurnitureConfigs.GainType.Remake, furnitureList, refitCb, 0, isCloseRecycle, isCloseRemake)
    end

    -- 改造家具
    function XFurnitureManager.RemouldFurniture(remouldMap, func, refitCb, isCloseRecycle, isCloseRemake)
        if XTool.IsTableEmpty(remouldMap) then
            return
        end
        local params = {}
        for itemId, ids in pairs(remouldMap) do
            local param = {
                ItemId = itemId,
                FurnitureIds = ids
            }
            table.insert(params, param)
        end
        XNetwork.Call(FurnitureRequest.RemouldFurniture, { Params = params }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 清除消耗的家具
            local removeIds = {}
            local deleteIds = res.RemovedIds or {}
            for _, furnitureId in ipairs(deleteIds) do
                XFurnitureManager.RemoveFurniture(furnitureId)
                table.insert(removeIds, furnitureId)
            end

            -- 添加新增的家具
            local furnitureList = res.FurnitureList
            for _, furniture in ipairs(furnitureList) do
                XFurnitureManager.AddFurniture(furniture)
                table.insert(removeIds, furniture.Id)
                XFurnitureManager.AddMaxRecord(furniture.Id)
            end
            XFurnitureManager.DeleteNewHint(removeIds)

            if not XTool.IsTableEmpty(furnitureList) then
                FurnitureRemouldSuccessCb(furnitureList, func, refitCb, isCloseRecycle, isCloseRemake)
            else
                if func then
                    func(furnitureList)
                end
            end

           

            XEventManager.DispatchEvent(XEventId.EVENT_FURNITURE_ON_MODIFY)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FURNITURE_ON_MODIFY)
        end)
    end

    -- 领取家具,
    function XFurnitureManager.CheckCreateFurniture(pos, func)
        XNetwork.Call(FurnitureRequest.CheckCreateFurniture, { Pos = pos }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 清除FurnitureManager的创建家具列表数据
            XFurnitureManager.RemoveFurnitureCreateListByPos(pos)
            -- 将家具添加到List列表
            for _, furniture in ipairs(res.FurnitureList) do
                XFurnitureManager.AddFurniture(furniture)
            end

            if func then
                func(res.FurnitureList, res.Count)
            end

            XEventManager.DispatchEvent(XEventId.EVENT_FURNITURE_GET_FURNITURE)
        end)
    end

    local function FurnitureCreateSuccessCb(furnitureList, createCount, cb)
        if cb then cb(furnitureList, createCount) end
        
        local furnitureCount = #furnitureList
        if furnitureCount == 1 then
            XLuaUiManager.OpenSingleUi("UiFurnitureDetail", furnitureList[1].Id, furnitureList[1].ConfigId)
        else
            XLuaUiManager.OpenSingleUi("UiFurnitureObtain", XFurnitureConfigs.GainType.Remake, furnitureList, nil, createCount / furnitureCount)
        end
    end
    
    function XFurnitureManager.OnResponseCreateFurniture(furnitureList, count, func)
        local ids = {}
        furnitureList = furnitureList or {}
        for _, furniture in ipairs(furnitureList) do
            XFurnitureManager.AddFurniture(furniture)
            table.insert(ids, furniture.Id)
        end

        if not XTool.IsTableEmpty(furnitureList) then
            XUiManager.TipMsg(XUiHelper.GetText("FurnitureCreateSuccess"), XUiManager.UiTipType.Tip, function()
                FurnitureCreateSuccessCb(furnitureList, count, func)
            end)
        else
            if func then
                -- 刷新界面
                func(furnitureList, count)
            end
        end

        XEventManager.DispatchEvent(XEventId.EVENT_FURNITURE_GET_FURNITURE)
    end
    
    -- 建造家具
    function XFurnitureManager.CreateFurniture(typeIds, count, costA, costB, costC, func)
        XNetwork.Call(FurnitureRequest.CreateFurniture, {
            TypeIds = typeIds,
            Count = count,
            CostA = costA,
            CostB = costB,
            CostC = costC
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            XFurnitureManager.OnResponseCreateFurniture(res.FurnitureList, res.Count, func)
        end)
    end
    
    local function FurnitureRemakeSuccessCb(furnitureList, remakeCount, cb)
        if cb then cb(furnitureList, remakeCount) end
        
        local furnitureCount = #furnitureList
        if furnitureCount == 1 then
            XLuaUiManager.OpenSingleUi("UiFurnitureDetail", furnitureList[1].Id, furnitureList[1].ConfigId)
            return
        end
        XLuaUiManager.OpenSingleUi("UiFurnitureObtain", XFurnitureConfigs.GainType.Remake, furnitureList)
    end
    
    local function RequestRemakeFurniture(furnitureIds, costA, costB, costC, roomId, cb)
        if XTool.IsTableEmpty(furnitureIds) then
            XUiManager.TipText("FurnitureRemakeNone")
            return
        end
        if #furnitureIds > XFurnitureConfigs.MaxRemakeCount then
            XUiManager.TipText("DormBuildMaxCount", nil, nil, XFurnitureConfigs.MaxRemakeCount)
            return
        end
        
        local req = {
            FurnitureIds = furnitureIds,
            CostA = costA,
            CostB = costB,
            CostC = costC,
        }
        
        XNetwork.Call(FurnitureRequest.FurnitureRemake, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 将分解成功的家具从缓存中移除
            local deleteIds = res.RemovedIds or {}
            for _, id in ipairs(deleteIds) do
                XFurnitureManager.RemoveFurniture(id)
            end

            -- 删除红点
            XDataCenter.FurnitureManager.DeleteNewHint(furnitureIds)
            XRewardManager.MergeAndSortRewardGoodsList(res.RewardGoods)
            -- 将家具添加到List列表
            local ids = {}
            local isInUse = XTool.IsNumberValid(roomId)
            local furnitureList = res.FurnitureList or {}
            for _, furniture in ipairs(furnitureList) do
                XFurnitureManager.AddFurniture(furniture, nil, isInUse)
                table.insert(ids, furniture.Id)
                XFurnitureManager.AddMaxRecord(furniture.Id)
            end
            if isInUse then
                XHomeDormManager.UpdateFurnitureData(roomId, furnitureIds, furnitureList)
            end

            if not XTool.IsTableEmpty(furnitureList) then
                XUiManager.TipMsg(XUiHelper.GetText("FurnitureRemakeSuccess"), nil, function()
                    FurnitureRemakeSuccessCb(furnitureList, res.Count, cb)
                end)
            else
                if cb then cb(furnitureList, res.Count) end
            end

            XEventManager.DispatchEvent(XEventId.EVENT_FURNITURE_ON_MODIFY)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FURNITURE_ON_MODIFY)
        end)
    end
    
    function XFurnitureManager.FilterBeforeRemake(furnitureIds, cost)
        furnitureIds = furnitureIds or {}
        local pass, unPass = {}, {}
        for _, furnitureId in pairs(furnitureIds) do
            local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
            if not furniture then
                goto continue
            end
            local costA, costB, costC = furniture:GetBaseAttr()
            local total = costA + costB + costC
            if cost >= total and XFurnitureConfigs.CheckFurnitureRemake(furniture, cost) then
                table.insert(pass, furnitureId)
            else
                table.insert(unPass, furnitureId)
            end
            
            ::continue::
        end
        
        return pass, unPass
    end

    -- 重新建造家具
    function XFurnitureManager.FurnitureRemake(furnitureIds, costA, costB, costC, roomId, cb)
        
        local rejectIds
        furnitureIds, rejectIds = XFurnitureManager.FilterBeforeRemake(furnitureIds, costA + costB + costC)

        if XTool.IsTableEmpty(rejectIds) then
            RequestRemakeFurniture(furnitureIds, costA, costB, costC, roomId, cb)
        else
            XLuaUiManager.Open("UiFurnitureReCreateDetail", XUiHelper.GetText("FurnitureDontRemakeTip"), rejectIds, function()
                RequestRemakeFurniture(furnitureIds, costA, costB, costC, roomId, cb)
            end)
        end
    end
    --=====================
    --解锁/上锁家具
    --@param furnitureId:家具ID
    --@param isLocked:是否上锁
    --@param callBack:成功回调
    --=====================
    function XFurnitureManager.SetFurnitureLock(furnitureId, isLocked, callBack)
        XNetwork.Call(FurnitureRequest.SetFurnitureLock, {
                FurnitureId = furnitureId,
                IsLocked = isLocked
            }, function(reply)
            -- reply = {
            --  XCode Code,    
            --  int FurnitureId,
            --  bool IsLocked}
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                local furnitureData = XFurnitureManager.GetFurnitureById(reply.FurnitureId)
                if furnitureData then
                    furnitureData:SetIsLocked(isLocked)
                end
                if callBack then callBack() end
            end)
    end
    
    -- 根据家具属性获得贴图
    function XFurnitureManager.GetFurnitureMaterial(furnitureId, dormDataType)
        if not furnitureId then
            return
        end

        local furnitureData = XFurnitureManager.GetFurnitureById(furnitureId, dormDataType)
        if not furnitureData then
            return
        end
        
        local furnitureColour = XFurnitureConfigs.GetFurnitureColour(furnitureData.ConfigId)
        if not furnitureColour then
            return
        end
        
        if XDormConfig.IsTemplateRoom(dormDataType) then
            return furnitureColour.DefaultMaterial
        end
        
        local maxAttrKey = 0
        local maxAttrVal = 0
        -- local midAttrKey = 0
        local midAttrVal = 0

        for k, v in pairs(furnitureData.AttrList) do
            if v >= maxAttrVal then
                -- midAttrKey = maxAttrKey
                midAttrVal = maxAttrVal

                maxAttrKey = k
                maxAttrVal = v
            elseif v >= midAttrVal then
                -- midAttrKey = k
                midAttrVal = v
            end
        end

        -- 最高和第二高值一致，则返回默认
        if maxAttrVal == midAttrVal then
            return furnitureColour.DefaultMaterial
        end
        if midAttrVal == 0 then
            return furnitureColour.FurnitureMaterials[maxAttrKey]
        end

        local attrOverRate = (maxAttrVal - midAttrVal) / midAttrVal * 100
        if furnitureColour and attrOverRate >= furnitureColour.AttrIds[maxAttrKey] then
            return furnitureColour.FurnitureMaterials[maxAttrKey]
        end

        return furnitureColour.DefaultMaterial
    end

    -- 根据家具属性获得家具特效
    function XFurnitureManager.GetFurnitureFx(furnitureId, dormDataType)
        if not furnitureId then
            return
        end

        local furnitureData = XFurnitureManager.GetFurnitureById(furnitureId, dormDataType)
        if not furnitureData then
            return
        end

        local furnitureColour = XFurnitureConfigs.GetFurnitureColour(furnitureData.ConfigId)
        if not furnitureColour then
            return
        end

        if XDormConfig.IsTemplateRoom(dormDataType) then
            return furnitureColour.DefaultFurnitureFx
        end

        local maxAttrKey = 0
        local maxAttrVal = 0
        -- local midAttrKey = 0
        local midAttrVal = 0

        for k, v in pairs(furnitureData.AttrList) do
            if v >= maxAttrVal then
                -- midAttrKey = maxAttrKey
                midAttrVal = maxAttrVal

                maxAttrKey = k
                maxAttrVal = v
            elseif v >= midAttrVal then
                -- midAttrKey = k
                midAttrVal = v
            end
        end

        -- 最高和第二高值一致，则返回默认
        if maxAttrVal == midAttrVal then
            return furnitureColour.DefaultFurnitureFx
        end
        if midAttrVal == 0 then
            return furnitureColour.FurnitureFx[maxAttrKey]
        end

        local attrOverRate = (maxAttrVal - midAttrVal) / midAttrVal * 100
        if furnitureColour and attrOverRate >= furnitureColour.AttrIds[maxAttrKey] then
            return furnitureColour.FurnitureFx[maxAttrKey]
        end

        return furnitureColour.DefaultFurnitureFx
    end

    -- 读取家具表的Icon,不能获得家具的属性用这个接口
    function XFurnitureManager.GetFurnitureIconByConfigId(configId)
        local furnitureTemplates = XFurnitureConfigs.GetFurnitureBaseTemplatesById(configId)
        if not furnitureTemplates then
            return ""
        end
        return furnitureTemplates.Icon
    end

    -- 根据家具属性计算家具的Icon,能获得家具的属性用这个接口
    function XFurnitureManager.GetFurnitureIconById(furnitureId, dormDataType)
        if not furnitureId then
            return ""
        end

        local furnitureData = XFurnitureManager.GetFurnitureById(furnitureId, dormDataType)
        return XFurnitureManager.GetIconByFurniture(furnitureData)
    end

    function XFurnitureManager.GetIconByFurniture(furniture)
        if not furniture then
            return ""
        end

        local baseIcon = XFurnitureManager.GetFurnitureIconByConfigId(furniture.ConfigId)

        local furnitureColour = XFurnitureConfigs.GetFurnitureColour(furniture.ConfigId)
        if not furnitureColour then
            return baseIcon
        end

        local maxAttrKey = 0
        local maxAttrVal = 0
        -- local midAttrKey = 0
        local midAttrVal = 0

        for k, v in pairs(furniture.AttrList) do
            if v >= maxAttrVal then
                -- midAttrKey = maxAttrKey
                midAttrVal = maxAttrVal

                maxAttrKey = k
                maxAttrVal = v
            elseif v >= midAttrVal then
                -- midAttrKey = k
                midAttrVal = v
            end
        end

        local defaultIcon = (furnitureColour.DefaultFurnitureIcon == "") and baseIcon or furnitureColour.DefaultFurnitureIcon
        local chooseIcon = (furnitureColour.FurnitureIcons[maxAttrKey] == "") and defaultIcon or furnitureColour.FurnitureIcons[maxAttrKey]

        -- 最高和第二高值一致，则返回默认
        if maxAttrVal == midAttrVal then
            return defaultIcon
        end
        if midAttrVal == 0 then
            return chooseIcon
        end

        local attrOverRate = (maxAttrVal - midAttrVal) / midAttrVal * 100
        if furnitureColour and attrOverRate >= furnitureColour.AttrIds[maxAttrKey] then
            return chooseIcon
        end
        return defaultIcon
    end

    function XFurnitureManager.GetTemplateCount(templateId)
        local totalCount = 0
        for _, v in pairs(XFurnitureManager.GetFurnitureDatas()) do
            local isUsing = XFurnitureManager.CheckFurnitureUsing(v.Id)
            if (not isUsing) and v.ConfigId == templateId then
                totalCount = totalCount + 1
            end
        end
        return totalCount
    end

    function XFurnitureManager.SetInReform(isInReforming)
        IsInReforming = isInReforming
    end

    function XFurnitureManager.GetInReform()
        return IsInReforming
    end
    
    -- 检测家具是否溢出 true为溢出
    function XFurnitureManager.CheckFurnitureSlopLimit()
        local allCount = XFurnitureManager.GetAllFurnitureCount()
        if allCount > XFurnitureConfigs.MaxTotalFurnitureCount then
            return true
        end
        return false
    end
    
    --- 家具一键改装
    function XFurnitureManager.OpenFurnitureOrderBuild(roomId, templateRoomId, templateRoomType, title, subTitle)
        local percent = XDataCenter.DormManager.GetDormTemplatePercent(roomId, templateRoomId)
        if percent >= 100 then --已经完成，无需跳转制作
            XUiManager.TipText("DormTemplateTargetFinished")
            return
        end
        local uiName = "UiFurnitureOrderBuild"
        if XLuaUiManager.IsUiShow(uiName) or XLuaUiManager.IsUiLoad(uiName) then
            XLuaUiManager.Remove(uiName)
        end
        XLuaUiManager.Open(uiName, roomId, templateRoomId, templateRoomType, title, subTitle)
    end
    
    --- 跳转购买图纸
    ---@param furnitureConfigId number 需要购买图纸的家具id
    ---@param buyCount number 购买数量
    ---@param successCb function 购买成功回调
    ---@return void
    --------------------------
    function XFurnitureManager.JumpToBuyDrawing(furnitureConfigId, buyCount, successCb)
        local template = XFurnitureConfigs.GetFurnitureTemplateById(furnitureConfigId)
        if not template or not XTool.IsNumberValid(template.PicId) then
            return
        end
        
        local itemId = template.PicId
        local asset = XItemConfigs.GetBuyAssetTemplateById(itemId)
        if not asset then
            XUiManager.TipText("DormNotBuyDrawing")
            return
        end
        
        XUiManager.OpenBuyAssetPanel(itemId, successCb, nil, buyCount)
    end

    Init()
    return XFurnitureManager
end

XRpc.NotifyFurnitureOperate = function(data)
    XDataCenter.FurnitureManager.NotifyFurnitureOperate(data.OperateList)
end
