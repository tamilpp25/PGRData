---
--- 宿舍业务管理器
---
XDormManagerCreator = function()
    local XDormManager = {}

    local CharacterData = {}  -- 构造体数据
    local DormitoryData = {}  -- 宿舍数据
    -- local VisitorData = {}  -- 宿舍访客数据
    local WorkListData = {} --打工数据(正在打工或者打完工但是奖励没有领)
    local WorkRefreshTime = -1 --打工刷新时间
    local RecommVisData = {} --推荐访问数据
    local RecommVisIds = {}
    local RecommVisFriendData = {}

    local LastSyncServerTime = 0 -- 爱抚水枪上一次请求时间
    local DormShowEventList = {}  -- 构造体客户端展示事件效果列表
    local IsPlayingShowEvent = false  -- 现在是否在播放展示事件
    local IsInTouch = false  -- 是否再爱抚中
    local SYNC_PUTFURNITURE_SECOND = 5       --摆放家具保护护时间
    local LastPutFurnitureTime = 0 --大厅个人玩家列表最后刷新时间

    local TargetDormitoryData = {}  --别人宿舍数据
    local TargetCharacterData = {} -- 构造体数据(访问其他人时)
    -- local TargetVisitorData = {} -- 宿舍访问数据(访问其他人时)

    local TempDormitoryData = {} -- 模板宿舍数据(包括收藏宿舍)
    local ProvisionalDormData = {} -- 导入的宿舍数据
    local LocalCaptureCache = {}    -- 本地截图缓存
    local DormRedTimer

    local SnapshotTimes = 0     -- 已使用的分享次数
    local LastShareTime = 0     -- 上一次分享的时间
    local CurrentDormId = -1    -- 最后停留的宿舍Id
    local DormitoryRequest = {
        DormitoryDataReq = "DormitoryDataRequest", -- 宿舍总数据请求
        ActiveDormItemReq = "ActiveDormItemRequest", --激活宿舍
        DormRenameReq = "DormRenameRequest", --房间改名
        PutFurnitureReq = "PutFurnitureRequest", --摆放家具请求
        DormSnapshotLayoutReq = "DormSnapshotLayoutRequest", --请求宿舍分享ID

        DormEnterReq = "DormEnterRequest", --进入宿舍通知
        DormExitReq = "DormOutRequest", --退出宿舍通知

        DormCharacterOperateReq = "DormCharacterOperateRequest", --构造体处理事件反馈
        DormRemoveCharacterReq = "DormRemoveCharacterRequest", --拿走构造体
        DormPutCharacterReq = "DormPutCharacterRequest", --放置构造体
        CheckCreateFurnitureReq = "CheckCreateFurnitureRequest", --请求刷新家具建造列表
        DormRecommendReq = "DormRecommendRequest", --推荐访问
        DormDetailsReq = "DormDetailsRequest", --宿舍访问时的详细信息
        DormVisitReq = "DormVisitRequest", --访问宿舍
        DormWorkReq = "DormWorkRequest", --宿舍打工
        DormWorkRewardReq = "DormWorkRewardRequest", --宿舍打工领取奖励

        FondleDataReq = "GetFondleDataRequest", -- 爱抚信息查询
        FondleReq = "DormDoFondleRequest", -- 爱抚请求

        DormWordDoneReq = "DormWordDoneRequest", -- 代工请求
        DormGetPlayerLayoutReq = "DormGetPlayerLayoutRequest", -- 通过ID导入他人宿舍模板
        DormBindLayoutReq = "DormBindLayoutRequest", -- 模板绑定宿舍
        DormUnBindLayoutReq = "DormUnBindLayoutRequest", -- 解除模板绑定宿舍
        DormCollectLayoutReq = "DormCollectLayoutRequest", -- 收藏宿舍请求
    }

    function XDormManager.InitOnlyOnce()
        if XDormManager.IsFirstInit then
            return
        end
        XDormManager.IsFirstInit = true

        DormitoryData = {}
        local dormitoryTemplates = XDormConfig.GetTotalDormitoryCfg()
        -- 宿舍布局数据
        for id, _ in pairs(dormitoryTemplates) do
            DormitoryData[id] = XHomeRoomData.New(id)
            DormitoryData[id]:SetPlayerId(XPlayer.Id)
        end

        local templateData = XDormConfig.GetDormTemplateData()
        for k, v in pairs(templateData) do
            TempDormitoryData[k] = v
        end

        IsPlayingShowEvent = false
    end

    -- 初始化宿舍小屋数据
    function XDormManager.InitDormitoryData(dormitoryList)
        if not dormitoryList or not next(dormitoryList) then
            return
        end
        for _, data in pairs(dormitoryList) do
            local roomData = DormitoryData[data.DormitoryId]
            if not roomData then
                local path = XDormConfig.GetDormitoryTablePath()
                XLog.Error("XDormManager.InitDormitoryData 错误:" .. path .. " 表中不存在DormitoryId: " .. data.DormitoryId .."检查配置表或者参数dormitoryList")
            else
                roomData:SetRoomUnlock(true)
                roomData:SetRoomName(data.DormitoryName)
            end
        end
    end

    -- 初始化宿舍小人数据
    function XDormManager.InitCharacterData(characterList)
        if not characterList or not next(characterList) then
            return
        end
        for _, data in ipairs(characterList) do
            CharacterData[data.CharacterId] = data
            if data.DormitoryId and data.DormitoryId > 0 then
                local roomData = DormitoryData[data.DormitoryId]
                if roomData then
                    roomData:AddCharacter(data)
                end
            end
        end
    end

    -- 初始化宿舍内部家具数据
    function XDormManager.InitFurnitureData(furnitureList)
        if not furnitureList or not next(furnitureList) then
            return
        end
        for _, data in pairs(furnitureList) do
            local roomData = DormitoryData[data.DormitoryId]
            if roomData then
                roomData:SetRoomUnlock(true)
                roomData:AddFurniture(data.Id, data.ConfigId, data.X, data.Y, data.Angle)
            end
        end
    end

    function XDormManager.InitdormCollectData(dormCollectList)
        if dormCollectList and next(dormCollectList) then
            for _, v in ipairs(dormCollectList) do
                TempDormitoryData[v.LayoutId] = XHomeRoomData.New(v.LayoutId)
                TempDormitoryData[v.LayoutId]:SetPlayerId(v.PlayerId)
                TempDormitoryData[v.LayoutId]:SetRoomName(v.Name)
                TempDormitoryData[v.LayoutId]:SetRoomUnlock(true)
                TempDormitoryData[v.LayoutId]:SetRoomDataType(XDormConfig.DormDataType.Collect)
                TempDormitoryData[v.LayoutId]:SetRoomCreateTime(v.CreateTime)

                for _, furniture in ipairs(v.FurnitureList) do
                    local id = XGlobalVar.GetIncId()
                    TempDormitoryData[v.LayoutId]:AddFurniture(id, furniture.ConfigId, furniture.X, furniture.Y, furniture.Angle)
                end
            end
        end
    end

    function XDormManager.InitbindRelationData(bindRelations)
        if bindRelations and next(bindRelations) then
            for _, bindRelation in ipairs(bindRelations) do
                if TempDormitoryData[bindRelation.LayoutId] then
                    TempDormitoryData[bindRelation.LayoutId]:SetConnectDormId(bindRelation.DormitoryId)
                end

                if DormitoryData[bindRelation.DormitoryId] then
                    DormitoryData[bindRelation.DormitoryId]:SetConnectDormId(bindRelation.LayoutId)
                end
            end
        end
    end

    -- 设置导入宿舍数据
    function XDormManager.SetDormProvisionalData(shareId, furnitureList)
        if not shareId or not furnitureList or #furnitureList <= 0 then
            return
        end

        if #ProvisionalDormData == XDormConfig.ProvisionalMaXCount then
            table.remove(ProvisionalDormData, 1)
        end

        local data = XHomeRoomData.New(shareId)
        data:SetRoomDataType(XDormConfig.DormDataType.Provisional)

        for _, furniture in ipairs(furnitureList) do
            local id = XGlobalVar.GetIncId()
            data:AddFurniture(id, furniture.ConfigId, furniture.X, furniture.Y, furniture.Angle)
        end

        table.insert(ProvisionalDormData, data)
    end

    -- 获取上一个导入宿舍数据
    function XDormManager.GetLastDormProvisionalData()
        if #ProvisionalDormData > 0 then
            table.remove(ProvisionalDormData, #ProvisionalDormData)
            if #ProvisionalDormData > 0 then
                return ProvisionalDormData[#ProvisionalDormData]
            end
        end

        return nil
    end

    -- 获取入宿舍数据
    function XDormManager.GetDormProvisionalData(roomId)
        for _, v in ipairs(ProvisionalDormData) do
            if v:GetRoomId() == roomId then
                return v
            end
        end

        return nil
    end

    -- 加载收藏宿舍的入口图片
    function XDormManager.LoacdCollectTxture()
        local datas = XDormManager.GetTemplateDormitoryData(XDormConfig.DormDataType.Collect)
        for _, v in ipairs(datas) do
            v:GetRoomPicture()
        end
    end

    -- 获取模板宿舍数据
    function XDormManager.GetTemplateDormitoryData(dormDataType, idList)
        if dormDataType == XDormConfig.DormDataType.Collect then
            local datas = {}

            for _, v in pairs(TempDormitoryData) do
                if v:GetRoomDataType() == XDormConfig.DormDataType.Collect then
                    table.insert(datas, v)
                end
            end

            table.sort(datas, function(a, b)
                return a:GetRoomCreateTime() < b:GetRoomCreateTime()
            end)

            return datas
        end

        if dormDataType == XDormConfig.DormDataType.Template then
            local datas = {}
            if idList and #idList > 0 then
                for _, id in ipairs(idList) do
                    local data = TempDormitoryData[id]
                    local isShow = XDormConfig.GetDormTemplateIsSwhoById(data:GetRoomId())
                    if isShow then
                        table.insert(datas, data)
                    end
                end
            else
                for _, v in pairs(TempDormitoryData) do
                    if v:GetRoomDataType() == XDormConfig.DormDataType.Template then
                        local isShow = XDormConfig.GetDormTemplateIsSwhoById(v:GetRoomId())
                        if isShow then
                            table.insert(datas, v)
                        end
                    end
                end
            end

            table.sort(datas, function(a, b)
                return a:GetRoomOrder() < b:GetRoomOrder()
            end)

            return datas
        end

        return nil
    end

    --获取所有宿舍数据
    function XDormManager.GetDormitoryData(dormDataType, senceId)
        if dormDataType == XDormConfig.DormDataType.Target then
            return TargetDormitoryData
        end

        if senceId then
            local data = {}
            for id, room in pairs(DormitoryData) do
                local cfgId = XDormConfig.GetDormitorySenceById(id)
                if cfgId == senceId then
                    data[id] = room
                end
            end
            return data
        end

        return DormitoryData
    end

    -- 获取指定宿舍数据
    function XDormManager.GetRoomDataByRoomId(roomId, dormDataType)
        local data, roomData
        if dormDataType == XDormConfig.DormDataType.Target then
            data = TargetDormitoryData
        elseif dormDataType == XDormConfig.DormDataType.Template or dormDataType == XDormConfig.DormDataType.Collect then
            data = TempDormitoryData
        elseif dormDataType == XDormConfig.DormDataType.Provisional then
            roomData = XDormManager.GetDormProvisionalData(roomId)
        else
            data = DormitoryData
        end

        if not roomData then
            roomData = data[roomId]
        end

        if not roomData then
            local tempStr = "XDormManager.GetRoomDataByRoomId无法根据roomId获得宿舍数据, 检查参数roomId : "
            XLog.Error(tempStr .. tostring(roomId) .. " 参数dormDataType：" .. dormDataType)
            return
        end

        return roomData
    end

    -- 入住排序方法
    local CharacterCheckInSortFunc = function(a, b)
        if a.DormitoryId < 0 or b.DormitoryId < 0 then
            return a.DormitoryId < b.DormitoryId
        elseif a.DormitoryId > 0 or b.DormitoryId > 0 then
            return a.CharacterId < b.CharacterId
        end

        return false
    end

    -- 取回入住人数据
    function XDormManager.GetCharactersSortedCheckInByDormId(dormId)
        if not CharacterData or not next(CharacterData) then
            return nil
        end

        local data = {}
        local d = {}

        for _, v in pairs(CharacterData) do
            if v.DormitoryId == dormId then
                table.insert(data, { CharacterId = v.CharacterId, DormitoryId = v.DormitoryId })
            else
                table.insert(d, { CharacterId = v.CharacterId, DormitoryId = v.DormitoryId })
            end
        end

        table.sort(d, CharacterCheckInSortFunc)
        for _, v in pairs(d) do
            table.insert(data, v)
        end
        return data
    end

    ---------------------start data---------------------
    --
    function XDormManager.GetCharacterDataByCharId(id)
        -- 没有数据下 直接返回nil
        if not CharacterData or not next(CharacterData) then
            return nil
        end
        local t = CharacterData[id]
        if not t then
            XLog.Error("XDormManager.GetCharacterDataByCharId 函数错误: 无法从服务端发回的数据characterList根据id找到对应的内容, Id = " .. tostring(id))
            return nil
        end

        return t
    end

    function XDormManager.CheckHaveDormCharacterByRewardId(id)
        local characterId = XDormConfig.GetDormCharacterRewardData(id).CharacterId
        return (CharacterData and CharacterData[characterId])
    end

    function XDormManager.CheckHaveDormCharacter(id)
        local result = CharacterData[id]
        if result then
            return true
        end
        return false
    end

    function XDormManager.GetTargetCharacterDataByCharId(id)
        -- 没有数据下 直接返回nil
        if not TargetCharacterData or not next(TargetCharacterData) then
            return nil
        end

        local t = TargetCharacterData[id]
        if not t then
            XLog.Error("XDormManager.GetTargetCharacterDataByCharId 函数错误: 无法从服务端发回的数据characterList根据id找到对应的内容, Id = " .. tostring(id))
            return nil
        end

        return t
    end

    -- 根据宿舍人员id---->CharacterId,获得角色大头像
    function XDormManager.GetCharBigHeadIcon(id)
        return XDataCenter.CharacterManager.GetCharBigHeadIcon(id)
    end

    -- 根据宿舍人员id---->CharacterId,获得角色小头像
    function XDormManager.GetCharSmallHeadIcon(id)
        return XDataCenter.CharacterManager.GetCharSmallHeadIcon(id)
    end

    -- 根据宿舍人员id---->CharacterId和类型,取回角色喜好Icon
    function XDormManager.GetCharacterLikeIconById(id, lt)
        if not id or not lt then
            return
        end

        local charStyleConfig = XDormConfig.GetCharacterStyleConfigById(id)

        if not charStyleConfig then
            return
        end

        local d = charStyleConfig[lt]
        if not d then
            return
        end

        local likeTypeConfig = XFurnitureConfigs.GetDormFurnitureType(d)
        return likeTypeConfig.TypeIcon
    end

    -- 根据宿舍人员id---->CharacterId和类型,取回角色喜好Name
    function XDormManager.GetCharacterLikeNameById(id, lt)
        if not id or not lt then
            return
        end

        local charStyleConfig = XDormConfig.GetCharacterStyleConfigById(id)
        if not charStyleConfig then
            return
        end
        local d = charStyleConfig[lt]
        if not d then
            return
        end

        local likeTypeConfig = XFurnitureConfigs.GetDormFurnitureType(d)
        return likeTypeConfig.TypeName
    end

    -- 根据宿舍人员id---->CharacterId,取回角色体力
    function XDormManager.GetVitalityById(id)
        local d = XDormManager.GetCharacterDataByCharId(id)
        if not d then
            return 0
        end

        return d.Vitality
    end

    -- 根据宿舍人员id---->CharacterId,取回角色心情值
    function XDormManager.GetMoodById(id)
        local d = XDormManager.GetCharacterDataByCharId(id)
        if not d then
            return 0
        end

        return d.Mood
    end

    -- 根据宿舍id--->DormitoryId,取回宿舍人员角色Icon圆头像
    function XDormManager.GetDormCharactersIcons(id, dormDataType)
        local icons = {}
        local d = XDormManager.GetRoomDataByRoomId(id, dormDataType)
        if not d then
            return icons
        end

        local characterList = d:GetCharacter()
        for k, v in pairs(characterList) do
            --获得角色圆头像
            local icon = XDataCenter.CharacterManager.GetCharRoundnessHeadIcon(v.CharacterId)
            icons[k] = icon
        end
        return icons
    end

    -- 根据宿舍id--->DormitoryId,取回宿舍人员Ids
    function XDormManager.GetDormCharactersIds(roomId, dormDataType)
        local ids = {}
        local d = XDormManager.GetRoomDataByRoomId(roomId, dormDataType)
        if not d then
            return ids
        end

        local list = d:GetCharacter()
        for _, v in pairs(list) do
            ids[v.CharacterId] = v.CharacterId
        end
        return ids
    end

    -- 根据宿舍id--->DormitoryId,取回宿舍人员中是否有事件
    function XDormManager.IsHaveDormCharactersEvent(roomId)
        local d = XDormManager.GetRoomDataByRoomId(roomId)
        local list = d:GetCharacter()
        for _, v in pairs(list) do
            local eventtemp = XHomeCharManager.GetCharacterEvent(v.CharacterId, true)
            if eventtemp then
                return true
            end
        end
        return false
    end

    -- 根据宿舍id--->DormitoryId,取回宿舍名字
    function XDormManager.GetDormName(id, dormDataType)
        local d = XDormManager.GetRoomDataByRoomId(id, dormDataType)
        if not d then
            return
        end

        return d:GetRoomName() or ""
    end

    -- 根据宿舍id--->DormitoryId,取回宿舍总评分
    function XDormManager.GetDormTotalScore(id, dormDataType)
        local totalScore = 0
        local d = XDormManager.GetRoomDataByRoomId(id, dormDataType)
        if d then
            local furnitureIdList = {}
            local dic = d:GetFurnitureDic()
            for furnitureId, _ in pairs(dic) do
                table.insert(furnitureIdList, furnitureId)
            end

            if furnitureIdList then
                for _, furnitureId in pairs(furnitureIdList) do
                    totalScore = totalScore + XDataCenter.FurnitureManager.GetFurnitureScore(furnitureId, dormDataType)
                end
            end
        end

        return XFurnitureConfigs.GetFurnitureTotalAttrLevelDescription(1, totalScore)
    end

    -- 获取房间地表实例Id
    function XDormManager.GetRoomPlatId(roomId, homePlatType, dormDataType)
        if homePlatType == nil then
            return nil
        end

        local dic
        if dormDataType == XDormConfig.DormDataType.Target then
            dic = TargetDormitoryData
        else
            dic = DormitoryData
        end

        local roomData = dic[roomId]
        if roomData == nil then
            return nil
        end

        local list = roomData:GetFurnitureDic()
        for _, v in pairs(list) do
            local cfg = XFurnitureConfigs.GetFurnitureTemplateById(v.ConfigId)
            if cfg then
                local typeCfg = XFurnitureConfigs.GetFurnitureTypeById(cfg.TypeId)
                if typeCfg then
                    if homePlatType == CS.XHomePlatType.Ground and typeCfg.MajorType == 1 and typeCfg.MinorType == 1 then
                        return v
                    end

                    if homePlatType == CS.XHomePlatType.Wall and typeCfg.MajorType == 1 and typeCfg.MinorType == 2 then
                        return v
                    end
                end
            end
        end

        return nil
    end

    function XDormManager.GetAllCharacterIds()
        local characterIds = {}
        if CharacterData and next(CharacterData) then
            for _, v in pairs(CharacterData) do
                local t = XDormConfig.GetCharacterStyleConfigById(v.CharacterId)
                if t then
                    table.insert(characterIds, v.CharacterId)
                end
            end
        else
            local characters = XDataCenter.CharacterManager.GetOwnCharacterList()
            for _, v in pairs(characters) do
                table.insert(characterIds, v.Id)
            end
        end
        return characterIds
    end

    function XDormManager.GetDormCharacterIds(...)
        local charactersIds = {}
        if CharacterData == nil then
            return charactersIds
        end

        local conditions = {...}
        for _, v in pairs(CharacterData) do
            local t = XDormConfig.GetCharacterStyleConfigById(v.CharacterId)
            if t then
                for _, charType in ipairs(conditions) do
                    if t.Type == charType then
                        table.insert(charactersIds, v.CharacterId)
                        goto GET_CHAR_IDS_BREAK
                    end
                end
                ::GET_CHAR_IDS_BREAK::
            end
        end

        return charactersIds
    end

    -- 构造体所在宿舍号
    function XDormManager.GetCharacterRoomNumber(charId)
        local t = XDormManager.GetCharacterDataByCharId(charId)
        if not t then
            return 0
        end

        if t.DormitoryId > 0 then
            return t.DormitoryId
        end

        return 0
    end

    -- 构造体是否在宿舍中
    function XDormManager.CheckCharInDorm(charId)
        local t = XDormManager.GetCharacterDataByCharId(charId)
        if not t then
            return false
        end
        return t.DormitoryId > 0
    end

    -- 获取构造体当前回复等级
    function XDormManager.GetCharRecoveryCurLevel(charId)
        local curLevelConfig = nil
        local curIndex = 0
        local charData = XDormManager.GetCharacterDataByCharId(charId)
        if not charData then
            return curLevelConfig, curIndex
        end
        local scoreA, scoreB, scoreC = XDormManager.GetDormitoryScore(charData.DormitoryId)
        local indexA = XFurnitureConfigs.AttrType.AttrA - 1
        local indexB = XFurnitureConfigs.AttrType.AttrB - 1
        local indexC = XFurnitureConfigs.AttrType.AttrC - 1

        local allFurnitureAttrs = XHomeDormManager.GetFurnitureScoresByUnsaveRoom(charData.DormitoryId)
        local allScores = allFurnitureAttrs.TotalScore

        local recoveryConfigs = XDormConfig.GetCharRecoveryConfig(charId)
        for index, recoveryConfig in pairs(recoveryConfigs) do
            if recoveryConfig.CompareType == XDormConfig.CompareType.Less then
                if scoreA <= (recoveryConfig.AttrCondition[indexA] or 0) and
                scoreB <= (recoveryConfig.AttrCondition[indexB] or 0) and
                scoreC <= (recoveryConfig.AttrCondition[indexC] or 0) and
                allScores <= recoveryConfig.AttrTotal then
                    curLevelConfig = recoveryConfig
                    curIndex = index
                end
            elseif recoveryConfig.CompareType == XDormConfig.CompareType.Equal then
                if scoreA == (recoveryConfig.AttrCondition[indexA] or 0) and
                scoreB == (recoveryConfig.AttrCondition[indexB] or 0) and
                scoreC == (recoveryConfig.AttrCondition[indexC] or 0) and
                allScores == recoveryConfig.AttrTotal then
                    curLevelConfig = recoveryConfig
                    curIndex = index
                end
            elseif recoveryConfig.CompareType == XDormConfig.CompareType.Greater then
                if scoreA >= (recoveryConfig.AttrCondition[indexA] or 0) and
                scoreB >= (recoveryConfig.AttrCondition[indexB] or 0) and
                scoreC >= (recoveryConfig.AttrCondition[indexC] or 0) and
                allScores >= recoveryConfig.AttrTotal then
                    curLevelConfig = recoveryConfig
                    curIndex = index
                end
            end
        end

        return curLevelConfig, curIndex
    end

    -- 获取构造体当前 下一个回复等级Config
    function XDormManager.GetCharRecoveryConfigs(charId)
        local curRecoveryConfig, curConfigIndex = XDormManager.GetCharRecoveryCurLevel(charId)
        local nextRecoveryConfig

        if curRecoveryConfig == nil then
            return nil, nil
        end

        local recoveryConfigs = XDormConfig.GetCharRecoveryConfig(charId)

        -- 当前已经是最大值 直接把当前作为Next返回 当前为nil
        if curConfigIndex >= #recoveryConfigs then
            return nil, curRecoveryConfig
        end

        nextRecoveryConfig = recoveryConfigs[curConfigIndex + 1]
        return curRecoveryConfig, nextRecoveryConfig
    end

    -- 获取某个宿舍的家具三个总分(attrA, attrB, attrC)
    function XDormManager.GetDormitoryScore(dormitoryId, dormDataType)
        local dic
        if dormDataType == XDormConfig.DormDataType.Target then
            dic = TargetDormitoryData
        else
            dic = DormitoryData
        end

        local data = dic[dormitoryId]
        if not data then
            return 0, 0, 0
        end

        local kv = data:GetFurnitureDic()
        local furnitureIds = {}
        for id, _ in pairs(kv) do
            table.insert(furnitureIds, id)
        end
        local scoreA, scoreB, scoreC = XDataCenter.FurnitureManager.GetFurniturePartScore(furnitureIds, dormDataType)
        return scoreA, scoreB, scoreC
    end

    local getScoreNamesSort = function(a, b)
        return a[2] > b[2]
    end

    -- 获取某个宿舍的家具三个总分对应名字
    function XDormManager.GetDormitoryScoreNames()
        local attrType = XFurnitureConfigs.AttrType
        local indexA = attrType.AttrA
        local indexB = attrType.AttrB
        local indexC = attrType.AttrC
        local a = XFurnitureConfigs.GetDormFurnitureTypeName(indexA)
        local b = XFurnitureConfigs.GetDormFurnitureTypeName(indexB)
        local c = XFurnitureConfigs.GetDormFurnitureTypeName(indexC)
        return a, b, c
    end

    -- 获取某个宿舍的家具三个总分(attrA, attrB, attrC)以及对应Icon
    function XDormManager.GetDormitoryScoreIcons(dormitoryId, dormDataType)
        local scoreA, scoreB, scoreC = XDormManager.GetDormitoryScore(dormitoryId, dormDataType)
        local data = {}
        local attrType = XFurnitureConfigs.AttrType
        local indexA = attrType.AttrA
        local indexB = attrType.AttrB
        local indexC = attrType.AttrC
        data[1] = { XFurnitureConfigs.GetDormFurnitureTypeIcon(indexA), scoreA, indexA }
        data[2] = { XFurnitureConfigs.GetDormFurnitureTypeIcon(indexB), scoreB, indexB }
        data[3] = { XFurnitureConfigs.GetDormFurnitureTypeIcon(indexC), scoreC, indexC }
        table.sort(data, getScoreNamesSort)
        return data
    end

    function XDormManager.GetDormitoryScoreLevelDes(dormitoryId, dormDataType)
        local scoreA, scoreB, scoreC = XDormManager.GetDormitoryScore(dormitoryId, dormDataType)
        local attrType = XFurnitureConfigs.AttrType
        local indexA = attrType.AttrA
        local indexB = attrType.AttrB
        local indexC = attrType.AttrC
        local a = XFurnitureConfigs.GetFurnitureAttrLevelDescription(1, indexA, scoreA)
        local b = XFurnitureConfigs.GetFurnitureAttrLevelDescription(1, indexB, scoreB)
        local c = XFurnitureConfigs.GetFurnitureAttrLevelDescription(1, indexC, scoreC)
        return a, b, c
    end

    -- 获得玩家访问其他宿舍时的角色id(暂时做成随机，二期做成可设置)
    function XDormManager.GetVisitorDormitoryCharacterId()
        local d = XDormManager.GetAllCharacterIds()
        if _G.next(d) == nil then
            return 0
        end

        local index = math.random(1, #d)
        return d[index]
    end

    -- 改名完成修正数据
    function XDormManager.RenameSuccess(dormitoryId, newName)
        local roomData = DormitoryData[dormitoryId]
        if roomData then
            roomData:SetRoomName(newName)
        end
    end

    -- 通知有人进入房间
    function XDormManager.NotifyDormVisitEnter()
    end

    -- 通知打工刷新时间
    function XDormManager.NotifyDormWorkRefreshTime(data)
        if WorkRefreshTime > 0 then
            XDormManager.NotifyDormWorkRefreshFlag = true
        end
        WorkRefreshTime = data.NextRefreshTime or -1
        --XDormManager.NotifyDormWorkRefreshFlag = true
        XEventManager.DispatchEvent(XEventId.EVENT_DORM_WORK_RESET)
    end

    function XDormManager.GetDormWorkRefreshTime()
        return WorkRefreshTime
    end

    -- 批量通知构造体心情值和体力值改变
    function XDormManager.NotifyCharacterAttr(data)
        for _, v in pairs(data.AttrList) do
            XDormManager.NotifyCharacterMood(v)
            XDormManager.NotifyCharacterVitality(v)
        end
    end

    -- 通知构造体心情值改变
    function XDormManager.NotifyCharacterMood(data)
        local t = XDormManager.GetCharacterDataByCharId(data.CharacterId)
        if not t then
            return
        end

        local changeValue = data.Mood - t.Mood
        t.Mood = data.Mood
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_MOOD_CHANGED, data.CharacterId, changeValue)
    end

    -- 通知构造体体力值改变
    function XDormManager.NotifyCharacterVitality(data)
        local t = XDormManager.GetCharacterDataByCharId(data.CharacterId)
        if not t then
            return
        end

        t.Vitality = data.Vitality
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_VITALITY_CHANGED, data.CharacterId)
    end

    -- 通知构造体体力/心情恢复速度改变
    function XDormManager.NotifyCharacterSpeedChange(data)
        for _, v in ipairs(data.Recoveries) do
            local t = XDormManager.GetCharacterDataByCharId(v.CharacterId)
            if not t then
                return
            end

            local moodChangeValue = v.MoodSpeed - t.MoodSpeed
            local vitalityChangeValue = v.VitalitySpeed - t.VitalitySpeed
            t.MoodSpeed = v.MoodSpeed
            t.VitalitySpeed = v.VitalitySpeed

            if data.ChangeType == XDormConfig.RecoveryType.PutFurniture then

                local moodEventId = moodChangeValue > 0 and XDormConfig.ShowEventId.MoodSpeedAdd or XDormConfig.ShowEventId.MoodSpeedCut
                local vitalityEventId = vitalityChangeValue > 0 and XDormConfig.ShowEventId.VitalitySpeedAdd
                or XDormConfig.ShowEventId.VitalitySpeedCut

                if moodChangeValue ~= 0 then
                    XDormManager.DormShowEventShowAdd(v.CharacterId, moodChangeValue, moodEventId)
                end

                if vitalityChangeValue ~= 0 then
                    XDormManager.DormShowEventShowAdd(v.CharacterId, vitalityChangeValue, vitalityEventId)
                end
            end
        end
    end

    -- 设置是否再爱抚中
    function XDormManager.SetInTouch(isInTouch)
        IsInTouch = isInTouch
    end

    -- 是否再爱抚中
    function XDormManager.CheckInTouch()
        return IsInTouch
    end

    function XDormManager.DormShowEventShowAdd(charId, changeValue, eventId)
        local dormShowEvent = {}
        dormShowEvent.CharacterId = charId
        dormShowEvent.ChangeValue = changeValue
        dormShowEvent.EventId = eventId
        table.insert(DormShowEventList, dormShowEvent)

        if not XLuaUiManager.IsUiShow("UiDormSecond") then
            return
        end

        if IsInTouch then
            return
        end

        if IsPlayingShowEvent then
            return
        end

        XDormManager.GetNextShowEvent()
    end

    function XDormManager.GetNextShowEvent()
        if #DormShowEventList <= 0 then
            IsPlayingShowEvent = false
            return
        end

        if not XLuaUiManager.IsUiShow("UiDormSecond") then
            return
        end

        if IsInTouch then
            return
        end

        IsPlayingShowEvent = true
        local firstData = table.remove(DormShowEventList, 1)
        XEventManager.DispatchEvent(XEventId.EVENT_DORM_SHOW_EVENT_CHANGE, firstData)
    end

    -- 通知构造有事件变更
    function XDormManager.NotifyDormCharacterAddEvent(data)
        if not data or not data.EventList then
            return
        end

        for _, v in ipairs(data.EventList) do
            local t = XDormManager.GetCharacterDataByCharId(v.CharacterId)
            if not t then
                return
            end

            t.EventList = t.EventList or {}
            for _, v2 in ipairs(v.EventList) do
                table.insert(t.EventList, v2)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_DORMMAIN_EVENT_NOTIFY, t.DormitoryId)
            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_ADD_EVENT_NOTIFY, v.CharacterId)
        end
    end

    -- 通知构造有事件变更
    function XDormManager.NotifyDormCharacterSubEvent(data)

        if not data or not data.EventList then
            return
        end

        for _, v in ipairs(data.EventList) do

            local t = XDormManager.GetCharacterDataByCharId(v.CharacterId)
            if not t then
                return
            end
            local idx = -1
            t.EventList = t.EventList or {}
            for index, var in ipairs(t.EventList) do
                if var.EventId == v.EventId then
                    idx = index
                end
            end

            if idx > 0 then
                table.remove(t.EventList, idx)
            end

            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_SUB_EVENT_NOTIFY, data.CharacterId)
        end

    end

    -- 取回玩家宿舍打工数据(正在打工或者奖励没有领)
    -- 保证工位小的在前面
    local DormWorkDataSort = function(a, b)
        return a.WorkPos < b.WorkPos
    end

    function XDormManager.GetDormWorkData()
        local listData = {}
        local d = WorkListData or {}
        for _, v in pairs(d) do
            if v then
                table.insert(listData, v)
            end
        end

        table.sort(listData, DormWorkDataSort)
        return listData
    end

    -- 取回玩家宿舍打工数据(能打工的)
    function XDormManager.GetDormNotWorkData()
        local listData = {}
        local ids = XDormManager.GetAllCharacterIds()
        for _, id in pairs(ids) do
            if XDormManager.CheckCharInDorm(id) and not XDormManager.IsWorking(id) then
                table.insert(listData, id)
            end
        end
        table.sort(listData, function(a, b)
            local vitalityA = XDormManager.GetVitalityById(a)
            local vitalityB = XDormManager.GetVitalityById(b)

            if vitalityA ~= vitalityB then
                return vitalityA > vitalityB
            end

            return a < b
        end)

        return listData
    end

    -- 是否在打工中
    function XDormManager.IsWorking(charId)
        local d = WorkListData or {}
        for _, v in pairs(d) do
            if v.CharacterId == charId then
                local f = v.WorkEndTime - XTime.GetServerNowTimestamp() > 0
                if f then
                    return true
                end
            end
        end

        return false
    end

    -- 取回玩家宿舍已经占了的工位
    function XDormManager.GetDormWorkPosData()
        local posList = {}
        local d = WorkListData or {}
        for _, v in pairs(d) do
            posList[v.WorkPos] = v.WorkPos
        end
        return posList
    end

    -- 当前拥有的宿舍
    function XDormManager.GetDormitoryCount()
        local count = 0
        for _, room in pairs(DormitoryData) do
            if room:WhetherRoomUnlock() then
                count = count + 1
            end
        end
        return count
    end

    -- 检查某个宿舍是否激活
    function XDormManager.IsDormitoryActive(dormitoryId)
        local room = DormitoryData[dormitoryId]
        if not room then return false end
        return room:WhetherRoomUnlock()
    end

    -- 当前已经激活的房间ID
    function XDormManager.GetDormitoryActiveIds()
        local ids = {}
        for dormitoryId, room in pairs(DormitoryData) do
            if room:WhetherRoomUnlock() then
                table.insert(ids, dormitoryId)
            end
        end
        return ids
    end

    --
    function XDormManager.GetDormitoryCount()
        local count = 0
        for _, room in pairs(DormitoryData) do
            if room:WhetherRoomUnlock() then
                count = count + 1
            end
        end
        return count
    end

    -- 如果拥有的数量超过配置的最大数量，就取最大数量。
    function XDormManager.GetWorkCfg(dormCount)
        local cfgWork = XDormConfig.GetDormCharacterWorkData() or {}
        local count = XDormManager.GetDormitoryCount()
        if dormCount then
            count = dormCount
        end

        local index = count
        local temple = #cfgWork

        if count > temple then
            index = temple
        end

        local data = XDormConfig.GetDormCharacterWorkById(index)
        return data
    end

    -- 获取宿舍与模板宿舍之间的达成百分比
    function XDormManager.GetDormTemplatePercent(tmeplateDormId, dormId)
        local templateData = TempDormitoryData[tmeplateDormId]
        local dormData = DormitoryData[dormId]

        if not templateData or not dormData then
            return 0
        end

        local dormFurnitureCount = 0
        local dormFurnitureConfigDic = dormData:GetFurnitureConfigDic()

        local templateFurnitureCount = 0
        local templateFurnitureConfigDic = templateData:GetFurnitureConfigDic()

        -- 模板宿舍家具数量
        for _, v in pairs(templateFurnitureConfigDic) do
            templateFurnitureCount = templateFurnitureCount + #v
        end

        -- 自己宿舍加家具达成数量
        for k, v in pairs(dormFurnitureConfigDic) do
            if templateFurnitureConfigDic[k] then
                if #v >= #templateFurnitureConfigDic[k] then
                    dormFurnitureCount = dormFurnitureCount + #templateFurnitureConfigDic[k]
                else
                    dormFurnitureCount = dormFurnitureCount + #v
                end
            end
        end

        if templateFurnitureCount <= 0 then
            return 0
        end

        return math.floor((dormFurnitureCount / templateFurnitureCount) * 100)
    end

    --==============================--
    --desc: 获取宿舍某个家具数量
    --@roomId: 房间ID
    --@dormDataType: 房间类型
    --@isIncludeUnUse: 是否加上背包未使用的家具
    --@return 数量
    --==============================--
    function XDormManager.GetFunritureCountInDorm(roomId, dormDataType, configId, isIncludeUnUse)
        local roomData = XDormManager.GetRoomDataByRoomId(roomId, dormDataType)
        local furnitureCount = #roomData:GetFurnitureConfigByConfigId(configId)
        if isIncludeUnUse then
            local unUseCount = #XDataCenter.FurnitureManager.GetUnuseFurnitueById(configId)
            furnitureCount = furnitureCount + unUseCount
        end

        return furnitureCount
    end

    function XDormManager.GetLocalCaptureCache(id)
        local texture = LocalCaptureCache[id]
        return texture or nil
    end

    function XDormManager.SetLocalCaptureCache(id, texture)
        LocalCaptureCache[id] = texture
    end

    function XDormManager.ClearLocalCaptureCache()
        for _, texture in pairs(LocalCaptureCache) do
            if not XTool.UObjIsNil(texture) then
                CS.UnityEngine.Object.Destroy(texture)
            end
        end
        LocalCaptureCache = {}
    end

    ---------------------end data---------------------
    ---------------------start net---------------------
    function XDormManager.UpdateDormData(roomId, roomData)
        local newRoomData = XHomeRoomData.New(roomId)
        newRoomData:SetPlayerId(XPlayer.Id)
        local furnitureList = roomData:GetFurnitureDic()
        for _, furniture in pairs(furnitureList) do
            local furnitureData = XDataCenter.FurnitureManager.GetFurnitureById(furniture.Id)
            if furnitureData then
                newRoomData:AddFurniture(furnitureData.Id, furnitureData.ConfigId, furnitureData.X, furnitureData.Y, furnitureData.Angle)
            end
        end

        DormitoryData[roomId] = newRoomData
    end

    function XDormManager.SetRoomDataDormitoryId(roomData, roomId)
        local furnitureList = roomData:GetFurnitureDic()

        for _, furniture in pairs(furnitureList) do
            XDataCenter.FurnitureManager.SetFurnitureState(furniture.Id, roomId)
        end
    end

    -- 房间家具摆放
    function XDormManager.RequestDecorationRoom(roomId, room, isBehavior, cb)
        if isBehavior then
            local now = XTime.GetServerNowTimestamp()
            if LastPutFurnitureTime + SYNC_PUTFURNITURE_SECOND >= now then
                if cb then
                    cb(true)
                end
                return
            end
            LastPutFurnitureTime = now
        end

        if not room then return end
        local roomData = room:GetData()
        if not roomData then return end

        local furnitureList = {}
        local furnitures = roomData:GetFurnitureDic()
        local roomDataType = roomData:GetRoomDataType()
        local roomUnsaveData = XDormManager.GetRoomDataByRoomId(roomId, roomDataType)
        local successCb = function(isSuccess)
            room:GenerateRoomMap()
            -- 提示成功
            if not isBehavior then
                XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureSaveSuccess"))
            end

            if roomDataType == XDormConfig.DormDataType.Self then
                -- 修改保存之前的家具为不属于这个房间
                XDormManager.SetRoomDataDormitoryId(roomUnsaveData, 0)
                -- 修改保存之后的家具为属于这个房间
                XDormManager.SetRoomDataDormitoryId(roomData, roomId)
                -- 将修改保存起来(直接替换旧数据)
                DormitoryData[roomId]:SetFurnitureDic(roomData:GetFurnitureDic())
            elseif roomDataType == XDormConfig.DormDataType.Collect then
                TempDormitoryData[roomId]:SetFurnitureDic(roomData:GetFurnitureDic())
                local imgName = tostring(XPlayer.Id) .. tostring(roomId)
                local texture = XHomeSceneManager.CaptureCamera(imgName, false)
                XDormManager.SetLocalCaptureCache(imgName, texture)
            elseif roomDataType == XDormConfig.DormDataType.Provisional then
                local provisionalRoom = XDormManager.GetDormProvisionalData(roomId)
                provisionalRoom:SetFurnitureDic(roomData:GetFurnitureDic())
            elseif roomDataType == XDormConfig.DormDataType.Template then
                TempDormitoryData[roomId]:SetFurnitureDic(roomData:GetFurnitureDic())
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FURNITURE_REFRESH)
            if cb then
                cb(isSuccess)
            end
        end

        for _, v in pairs(furnitures) do
            local data = {}
            if roomDataType == XDormConfig.DormDataType.Self then
                data.Id = v.Id
            else
                data.ConfigId = v.ConfigId
            end

            data.X = v.GridX
            data.Y = v.GridY
            data.Angle = v.RotateAngle
            table.insert(furnitureList, data)
        end

        if roomDataType == XDormConfig.DormDataType.Self then
            XDataCenter.FurnitureManager.PutFurniture(roomId, furnitureList, isBehavior, successCb)
        elseif roomDataType == XDormConfig.DormDataType.Collect then
            local name = roomData:GetRoomName()
            XDormManager.CollectPutFunitrue(roomId, name, furnitureList, successCb)
        else
            successCb(true)
        end
    end

    -- 请求宿舍分享ID
    function XDormManager.RequestDormSnapshotLayout(furnitureList, cb)
        if SnapshotTimes <= XDormConfig.MAX_SHARE_COUNT then
            local now = XTime.GetServerNowTimestamp()

            if LastShareTime + XDormConfig.GET_SHARE_ID_INTERVAL > now then
                -- 需要等待的时间比现在还晚
                local waitTime = (LastShareTime + XDormConfig.GET_SHARE_ID_INTERVAL) - now
                local tip = CS.XTextManager.GetText("DormShareWaitTime", waitTime)
                XUiManager.TipMsg(tip)
                return
            end
            LastShareTime = now

            table.sort(furnitureList, function(item1, item2)
                if item1.ConfigId ~= item2.ConfigId then
                    return item1.ConfigId < item2.ConfigId
                end

                if item1.X == nil or item2.X == nil then
                    return false
                elseif item1.X ~= item2.X then
                    return item1.X < item2.X
                end

                if item1.Y == nil or item2.Y == nil then
                    return false
                elseif  item1.Y ~= item2.Y then
                    return item1.Y < item2.Y
                end

                if item1.Angle == nil or item2.Angle ==nil then
                    return false
                else
                    return item1.Angle < item2.Angle
                end
            end)

            local req = { FurnitureList = furnitureList}
            XNetwork.Call(DormitoryRequest.DormSnapshotLayoutReq, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                -- 更新分享次数
                SnapshotTimes = res.SnapshotTimes

                if cb then
                    cb(res.ShareId)
                end
            end)
        else
            XUiManager.TipText("DormShareCountNotEnough")
        end
    end

    -- 获取构造体回复速度
    function XDormManager.GetDormitoryRecoverSpeed(charId, cb)
        local t = XDormManager.GetCharacterDataByCharId(charId)
        if not t then
            return nil
        end

        local moodSpeed = string.format("%.1f", t.MoodSpeed / 100)
        local vitalitySpeed = string.format("%.1f", t.VitalitySpeed / 100)

        if moodSpeed * 10 % 10 == 0 then
            moodSpeed = string.format("%d", moodSpeed)
        end

        if vitalitySpeed * 10 % 10 == 0 then
            vitalitySpeed = string.format("%d", vitalitySpeed)
        end


        if cb then
            cb(moodSpeed, vitalitySpeed, t)
        end
    end

    -- 激活宿舍
    function XDormManager.RequestDormitoryActive(dormitoryId, cb)
        XNetwork.Call(DormitoryRequest.ActiveDormItemReq, { DormitoryId = dormitoryId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XDormManager.ReqDormitoryActiveSuccess(res.DormitoryId, res.DormitoryName, res.FurnitureList)
            if cb then
                cb()
            end

            XUiManager.TipText("DormActiveSuccessTips")
            XEventManager.DispatchEvent(XEventId.EVENT_DORM_ROOM_ACTIVE_SUCCESS)
        end)
    end

    -- 激活宿舍成功修正数据
    function XDormManager.ReqDormitoryActiveSuccess(dormitoryId, dormitoryName, furnitureList)
        for _, v in pairs(furnitureList) do
            XDataCenter.FurnitureManager.AddFurniture(v)
        end
        local roomData = DormitoryData[dormitoryId]

        if roomData then
            roomData:SetRoomName(dormitoryName)
            roomData:SetRoomUnlock(true)
            for _, data in pairs(furnitureList) do
                roomData:AddFurniture(data.Id, data.ConfigId, data.X, data.Y, data.Angle)
            end
        end

        local room = XHomeDormManager.GetSingleDormByRoomId(dormitoryId)
        room:SetData(roomData)
    end

    -- 访问宿舍(包括自己和他人的)
    function XDormManager.VisitDormitory(displayState, dormitoryId)
        local f = displayState == XDormConfig.VisitDisplaySetType.MySelf
        local isvistor = false
        local ids = XDormManager.GetDormitoryActiveIds()
        for _, dormId in pairs(ids) do
            XHomeDormManager.RevertOnWall(dormId)
        end

        if f then
            local data = XDataCenter.DormManager.GetDormitoryData()
            XHomeDormManager.LoadRooms(data, XDormConfig.DormDataType.Self)
        else
            local data = XDataCenter.DormManager.GetDormitoryData(XDormConfig.DormDataType.Target)
            XHomeDormManager.LoadRooms(data, XDormConfig.DormDataType.Target)
            isvistor = true
        end

        XHomeDormManager.SetSelectedRoom(dormitoryId, true, isvistor)
    end

    -- 进入模板宿舍(包括临时模板)
    function XDormManager.EnterTeamplateDormitory(dormitoryId, roomDataType)
        local roomType = roomDataType
        local isCollectNone = roomType == XDormConfig.DormDataType.CollectNone
        if isCollectNone then
            roomType = XDormConfig.DormDataType.Template
        end

        local data = XDormManager.GetRoomDataByRoomId(dormitoryId, roomType)
        if isCollectNone then
            local defluatFurnitrue = XDataCenter.FurnitureManager.GetCollectNoneFurnitrue(dormitoryId)
            if defluatFurnitrue then
                data:SetFurnitureDic(defluatFurnitrue)
            end
        end

        local datas = { data }
        XHomeDormManager.LoadRooms(datas, roomType)
        XLuaUiManager.Open("UiDormTemplateScene", dormitoryId, roomDataType)
        XHomeDormManager.SetSelectedRoom(dormitoryId, true)
    end

    -- 房间改名
    function XDormManager.RequestDormitoryRename(dormitoryId, newName, cb)
        XNetwork.Call(DormitoryRequest.DormRenameReq, { DormitoryId = dormitoryId, NewName = newName }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                XDormManager.RenameSuccess(dormitoryId, newName)
                cb()
            end
        end)
    end

    -- 摆放家具请求
    function XDormManager.RequestDormitoryPutFurniture(dormitoryId, furnitureList, cb)
        XNetwork.Call(DormitoryRequest.PutFurnitureReq, { DormitoryId = dormitoryId, FurnitureList = furnitureList }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    -- 退出宿舍请求
    function XDormManager.RequestDormitoryExit()
        XNetwork.Send(DormitoryRequest.DormExitReq)
    end

    -- 进入宿舍通知
    function XDormManager.RequestDormitoryDormEnter(cb)
        XNetwork.Call(DormitoryRequest.DormEnterReq, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local data = res.CharacterEvents
            if data then
                for _, v in pairs(data) do

                    local t = XDormManager.GetCharacterDataByCharId(v.CharacterId)
                    if not t then
                        return
                    end

                    t.EventList = v.EventList
                end
            end

            if cb then
                cb()
            end

        end)
    end

    -- 构造体处理事件反馈
    function XDormManager.RequestDormitoryCharacterOperate(charId, dormitoryId, eventId, operateType, cb)
        XNetwork.Call(DormitoryRequest.DormCharacterOperateReq, { CharacterId = charId, EventId = eventId, OperateType = operateType }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local character = XDormManager.GetCharacterDataByCharId(charId)
            if not character.EventList then
                return
            end

            local index = -1
            for i, v in ipairs(character.EventList) do
                if v.EventId == eventId then
                    index = i
                end
            end

            if index > 0 then
                table.remove(character.EventList, index)
            end

            XHomeCharManager.SetEventReward(charId, res.RewardGoods)

            -- 处理回复弹条
            local changeValue = math.floor(res.MoodValue / 100)
            if character.Mood + changeValue > XDormConfig.DORM_MOOD_MAX_VALUE then
                changeValue = XDormConfig.DORM_MOOD_MAX_VALUE - character.Mood
            end

            character.Mood = character.Mood + changeValue
            local showEventId = changeValue > 0 and XDormConfig.ShowEventId.MoodAdd or XDormConfig.ShowEventId.MoodCut
            XDormManager.DormShowEventShowAdd(charId, changeValue, showEventId)

            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_MOOD_CHANGED, charId, changeValue)

            if cb then
                cb()
            end
        end)
    end

    -- 放置构造体
    function XDormManager.RequestDormitoryPutCharacter(dormitoryId, characterIds, cb)
        XNetwork.Call(DormitoryRequest.DormPutCharacterReq, { DormitoryId = dormitoryId, CharacterIds = characterIds }, function(res)
            XDormManager.PutCharacterSuccess(dormitoryId, res.SuccessIds)
            if cb then
                cb()
            end
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_CHANGE_ROOM_CHARACTER, characterIds)
        end)
    end

    -- 放置构造体成功修正数据
    function XDormManager.PutCharacterSuccess(dormitoryId, characterIds)
        if not dormitoryId or not characterIds then
            return
        end

        for _, id in pairs(characterIds) do
            local d = CharacterData[id]
            if d then
                d.DormitoryId = dormitoryId
            end

            local roomData = DormitoryData[dormitoryId]
            roomData:AddCharacter(d)
            local room = XHomeDormManager.GetRoom(dormitoryId)
            if room and room.IsSelected then
                room.Data.Character = roomData.Character
                room:AddCharacter(dormitoryId, id)
            end
        end
    end

    -- 重新放置构造体
    function XDormManager.ResetPutCharacter(dormitoryId, characterIds)
        if not dormitoryId or not characterIds or #characterIds <= 0 then
            return
        end

        for _, id in pairs(characterIds) do
            local room = XHomeDormManager.GetRoom(dormitoryId)
            if room and room.IsSelected then
                room:AddCharacter(dormitoryId, id)
            end
        end
    end

    -- 移走构造体
    function XDormManager.RequestDormitoryRemoveCharacter(characterIds, cb)
        XNetwork.Call(DormitoryRequest.DormRemoveCharacterReq, { CharacterIds = characterIds }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XDormManager.RemoveCharacterSuccess(res.SuccessList)
            if cb then
                cb()
            end

            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_CHANGE_ROOM_CHARACTER, characterIds)
        end)
    end

    -- 移走构造体成功修正数据
    function XDormManager.RemoveCharacterSuccess(successList)
        if not successList then
            return
        end

        for _, v in pairs(successList) do
            local roomData = DormitoryData[v.DormitoryId]
            if roomData then
                roomData:RemoveCharacter(v.CharacterId)

                local room = XHomeDormManager.GetRoom(v.DormitoryId)
                if room then
                    room:RemoveCharacter(v.DormitoryId, v.CharacterId)
                end
            end

            local id = v.CharacterId
            local d = CharacterData[id]
            if d then
                d.DormitoryId = -1
            end
        end
    end

    -- 请求刷新家具建造列表
    function XDormManager.RequestDormitoryCheckCreateFurniture(cb)
        XNetwork.Call(DormitoryRequest.CheckCreateFurnitureReq, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb(res.FurnitureList)
            end
        end)
    end

    -- 访问具体宿舍
    function XDormManager.RequestDormitoryVisit(targetId, dormitoryId, characterId, cb)
        XNetwork.Call(DormitoryRequest.DormVisitReq, { TargetId = targetId, DormitoryId = dormitoryId, CharacterId = characterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XDormManager.DormitoryVisitData(res.VisitorList, res.CharacterList, res.DormitoryList, res.FurnitureList, res.PlayerName, targetId)

            if cb then
                cb()
            end
        end)
    end

    -- 访问具体宿舍数据记录
    function XDormManager.DormitoryVisitData(visitorList, characterList, dormitoryList, furnitureList, playername, targetId)
        local dormitoryCfgs = XDormConfig.GetTotalDormitoryCfg()

        -- 宿舍布局数据
        for id, _ in pairs(dormitoryCfgs) do
            TargetDormitoryData[id] = XHomeRoomData.New(id)
            TargetDormitoryData[id]:SetPlayerId(targetId)
            TargetDormitoryData[id]:SetRoomDataType(XDormConfig.DormDataType.Target)
            TargetDormitoryData[id].PlayerName = playername
        end

        if dormitoryList then
            for _, data in pairs(dormitoryList) do
                local roomData = TargetDormitoryData[data.DormitoryId]
                if not roomData then
                    XLog.Error("XDormManager.DormitoryVisitData错误: dormitory id is not exist, id = " .. tostring(data.DormitoryId))
                else
                    roomData:SetRoomUnlock(true)
                    roomData:SetRoomName(data.DormitoryName)
                end
            end
        end

        -- 宿舍家具
        XDataCenter.FurnitureManager.RemoveFurnitureOther()
        if furnitureList then
            for _, data in pairs(furnitureList) do
                local roomData = TargetDormitoryData[data.DormitoryId]
                if roomData then
                    roomData:SetRoomUnlock(true)
                    roomData:AddFurniture(data.Id, data.ConfigId, data.X, data.Y, data.Angle)
                    XDataCenter.FurnitureManager.AddFurniture(data, XDormConfig.DormDataType.Target)
                end
            end
        end

        -- 构造体数据
        if characterList then
            for _, data in ipairs(characterList) do
                TargetCharacterData[data.CharacterId] = data
                if data.DormitoryId and data.DormitoryId > 0 then
                    local roomData = TargetDormitoryData[data.DormitoryId]
                    if roomData then
                        roomData:AddCharacter(data)
                    end
                end
            end
        end

        -- 正在访问宿舍数据
        -- if visitorList then
        --     for _, data in pairs(visitorList) do
        --         TargetVisitorData[data.CharacterId] = data
        --     end
        -- end
    end

    -- 推荐访问
    function XDormManager.RequestDormitoryRecommend(cb)
        XNetwork.Call(DormitoryRequest.DormRecommendReq, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XDormManager.RecordDormitoryRecommend(res)
            if cb then
                cb(res)
            end
        end)
    end

    -- 记录推荐访问数据
    function XDormManager.RecordDormitoryRecommend(data)
        RecommVisData = {}
        local d = data.Details or {}
        for _, v in pairs(d) do
            RecommVisIds[v.DormitoryId] = v.DormitoryId
            RecommVisData[v.PlayerId] = v
        end
    end

    -- 取总的推荐访问数据
    function XDormManager.GetDormitoryRecommendTotalData()
        return RecommVisData
    end

    -- 取总的推荐访问数据
    function XDormManager.GetDormitoryRecommendScore(id)
        if not id then
            return
        end

        return RecommVisData[id]
    end

    function XDormManager.GetDormitoryTargetScore(roomId)
        local roomData = XDormManager.GetRoomDataByRoomId(roomId, XDormConfig.DormDataType.Target)
        if not roomData then
            return
        end
        return XHomeDormManager.GetFurnitureScoresByRoomData(roomData, XDormConfig.DormDataType.Target)
    end

    -- 取推荐访问id和是否是最后一个(当前dormId的下一个id,最后一个直接返回dormId和true)
    function XDormManager.GetDormitoryRecommendDataForNext(dormId)
        local data = XDormManager.GetDormitoryRecommendTotalDormId()
        local len = #data
        local f = false

        for i = 1, len do
            if f then
                return data[i], len == i
            end

            if data[i] == dormId then
                f = true
            end
        end

        return dormId, true
    end

    -- 取推荐访问id和是否是前一个(当前dormId的上一个id,第一个直接返回dormId和true)
    function XDormManager.GetDormitoryRecommendDataForPre(dormId)
        local data = XDormManager.GetDormitoryRecommendTotalDormId()
        local f = false

        for i, v in pairs(data) do
            if f then
                return v, i == 1
            end

            if v == dormId then
                f = true
            end
        end

        return dormId, true
    end

    -- 取所有推荐访问DormId
    function XDormManager.GetDormitoryRecommendTotalDormId()
        local d = {}
        for _, v in pairs(RecommVisIds) do
            table.insert(d, v)
        end
        return d
    end

    function XDormManager.HandleVisFriendData(data)
        if data then
            for _, v in pairs(data) do
                if v.DormitoryId ~= 0 then
                    v.DataTime = XTime.GetServerNowTimestamp()
                    RecommVisFriendData[v.PlayerId] = v
                end
            end
        end
        return RecommVisFriendData
    end

    function XDormManager.GetVisFriendData()
        return RecommVisFriendData
    end

    function XDormManager.GetVisFriendById(playerid)
        if not playerid then
            return
        end

        if RecommVisFriendData and RecommVisFriendData[playerid] then
            return RecommVisFriendData[playerid]
        end
    end
    -- 访问具体数据
    function XDormManager.RequestDormitoryDetails(players, cb)
        XNetwork.Call(DormitoryRequest.DormDetailsReq, { Players = players }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XDormManager.HandleVisFriendData(res.Details)
            if cb then
                cb()
            end
        end)
    end

    -- 宿舍打工
    function XDormManager.RequestDormitoryWork(works, cb)
        XNetwork.Call(DormitoryRequest.DormWorkReq, { Works = works }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XDormManager.DormWorkRespHandle(res.WorkList)
            if cb then
                cb(res)
            end
        end)
    end

    -- 打工成功修正数据
    function XDormManager.DormWorkRespHandle(workList)
        if not workList then
            return
        end

        for _, data in pairs(workList) do
            WorkListData[data.WorkPos] = data
            local dormitoryId = XDormManager.GetCharacterRoomNumber(data.CharacterId)
            if dormitoryId then
                local room = XHomeDormManager.GetRoom(dormitoryId)
                if room then
                    room:RemoveCharacter(dormitoryId, data.CharacterId)
                end
            end
        end
    end

    -- 宿舍打工领取奖励
    function XDormManager.RequestDormitoryWorkReward(posList, cb)
        XNetwork.Call(DormitoryRequest.DormWorkRewardReq, { PosList = posList }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XDormManager.DormWorkRewardGet(res.WorkRewards)
            if cb then
                cb()
            end
        end)
    end

    -- 领取奖励成功修正数据
    function XDormManager.DormWorkRewardGet(workRewards)
        if not workRewards or _G.next(workRewards) == nil then
            return
        end

        local rewards = {}
        local workPos = {}
        for _, v0 in pairs(workRewards) do
            for _, v1 in pairs(WorkListData) do
                if v1.WorkPos == v0.WorkPos then
                    if v0.ResetCount == 0 then
                        v1.WorkEndTime = 0
                    else
                        workPos[v1.WorkPos] = v1.WorkPos
                    end
                end
            end
            table.insert(rewards, { TemplateId = v0.ItemId, Count = v0.ItemNum, RewardType = v0.RewardType or XRewardManager.XRewardType.Item })
        end

        for pos, _ in pairs(workPos) do
            for index, item in pairs(WorkListData) do
                if item and item.WorkPos == pos then
                    WorkListData[index] = nil
                end
            end
        end

        XUiManager.OpenUiObtain(rewards)
    end

    -- 爱抚信息查询
    function XDormManager.GetDormFondleData(characterId, cb)
        if not characterId then
            return
        end

        XNetwork.Call(DormitoryRequest.FondleDataReq, { CharacterId = characterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local fondle = { LastRecoveryTime = res.LastRecoveryTime, LeftCount = res.FondleCount }
            if cb then
                cb(fondle)
            end
        end)
    end

    -- 爱抚请求
    function XDormManager.DoFondleReq(characterId, fondleType, cb)
        if not characterId or not fondleType then
            return
        end

        local now = XTime.GetServerNowTimestamp()
        if fondleType == XDormConfig.TouchState.WaterGun then
            if LastSyncServerTime + XDormConfig.WATERGUN_TIME >= now then
                return
            end
        end
        LastSyncServerTime = now

        local req = { CharacterId = characterId, FondleType = fondleType }
        XNetwork.Call(DormitoryRequest.FondleReq, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    -- 代工请求
    function XDormManager.DormWordDoneReq(workposList, cb)
        if not workposList then
            return
        end

        local req = { WorkPos = workposList }
        XNetwork.Call(DormitoryRequest.DormWordDoneReq, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDormManager.DormCharacterRewardGet(res.WorkRewards, res.ExtraRewards, workposList)
            XEventManager.DispatchEvent(XEventId.EVENT_DORM_DAI_GONE_REWARD)
            if cb then
                cb()
            end
        end)
    end
    --记录玩家最后停留的宿舍Id
    function XDormManager.SetCurrentDormId(dormId)
        CurrentDormId = dormId
    end
	--一键代工后回调（因为点返回不会重新读取小人状态，临时把角色小人加回宿舍）
    function XDormManager.QuickDormDoneCallBack(workposList)
        if CurrentDormId == -1 then return end --若记录停留的宿舍为空说明没有进入宿舍页面，不用重新放入小人
        local checkDic = {} --检查同一个宿舍不用重复Reset
        for _, pos in pairs(workposList) do
            local data = WorkListData[pos]
            if data then
                local dormitoryId = XDormManager.GetCharacterRoomNumber(data.CharacterId)
                if dormitoryId and not checkDic[dormitoryId] and dormitoryId == CurrentDormId then
                    local room = XHomeDormManager.GetRoom(dormitoryId)
                    if room then
                        room:ResetCharacterList()
                    end
                    checkDic[dormitoryId] = true
                end
            end
        end
    end
    function XDormManager.DormCharacterRewardGet(workRewards, extraRewards)
        if (not workRewards or _G.next(workRewards) == nil) and (not extraRewards or _G.next(extraRewards) == nil) then
            return
        end

        local rewards = {}
        local workPos = {}
        for _, v0 in pairs(workRewards) do
            for _, v1 in pairs(WorkListData) do
                if v1.WorkPos == v0.WorkPos then
                    if v0.ResetCount == 0 then
                        v1.WorkEndTime = 0
                    else
                        workPos[v1.WorkPos] = v1.WorkPos
                    end
                end
            end
            table.insert(rewards, { TemplateId = v0.ItemId, Count = v0.ItemNum, RewardType = v0.RewardType or XRewardManager.XRewardType.Item })
        end

        for _, v in pairs(extraRewards) do
            table.insert(rewards, { TemplateId = v.TemplateId, Count = v.Count, RewardType = v.RewardType or XRewardManager.XRewardType.Item })
        end

        for pos, _ in pairs(workPos) do
            for index, item in pairs(WorkListData) do
                if item and item.WorkPos == pos then
                    WorkListData[index] = nil
                end
            end
        end

        XUiManager.OpenUiObtain(rewards)
    end

    function XDormManager.NotifyFurnitureUnLock(data)
        XDormManager.FurnitureUnlockList = {}
        if data and data.FurnitureUnlockList then
            for _, v in pairs(data.FurnitureUnlockList) do
                XDormManager.FurnitureUnlockList[v] = v
            end
        end
    end

    function XDormManager.IdFurnitureUnLock(id)
        return XDormManager.FurnitureUnlockList[id] ~= nil or XDataCenter.FurnitureManager.IsFieldGuideHave(id)
    end

    -- 已使用的分享次数
    function XDormManager.NotifySnapshotTimes(data)
        SnapshotTimes = data.SnapshotTimes
    end

    function XDormManager.GetSnapshotTimes()
        return SnapshotTimes
    end

    -- 打工数据
    function XDormManager.NotifyDormWork(data)
        if data and data.WorkList then
            for _, tmpData in pairs(data.WorkList) do
                WorkListData[tmpData.WorkPos] = tmpData
            end
        end
    end

    function XDormManager.GetDormWorkByPos(pos)
        return WorkListData[pos]
    end

    function XDormManager.GetDormWorkRewCounrByPos(pos)
        if WorkListData[pos] and WorkListData[pos].RewardNum then
            return WorkListData[pos].RewardNum
        end

        return 0
    end

    -- 打工Red
    function XDormManager.DormWorkRedFun()
        if _G.next(WorkListData) ~= nil then
            for _, data in pairs(WorkListData) do
                if data.WorkEndTime > 0 and data.WorkEndTime < XTime.GetServerNowTimestamp() then
                    return true
                end
            end
        end
        return false
    end

    -- 重置打工工位
    function XDormManager.ResetDormWorkPos()
        local workdata = {}
        if _G.next(WorkListData) ~= nil then
            for _, data in pairs(WorkListData) do
                if data.WorkEndTime ~= 0 then
                    workdata[data.WorkPos] = data
                end
            end
        end
        WorkListData = workdata
    end

    -- 启动
    function XDormManager.StartDormRedTimer()
        if DormRedTimer then
            return
        end

        DormRedTimer = XScheduleManager.ScheduleForever(XDormManager.UpdateDormRed, 2000)
    end

    -- 停止
    function XDormManager.StopDormRedTimer()
        if not DormRedTimer then
            return
        end

        XScheduleManager.UnSchedule(DormRedTimer)
        DormRedTimer = nil
    end

    function XDormManager.UpdateDormRed()
        XEventManager.DispatchEvent(XEventId.EVENT_DORM_WORK_REDARD)
        XEventManager.DispatchEvent(XEventId.EVENT_FURNITURE_CREATE_CHANGED)
    end

    -- 宿舍性别
    --function XDormManager.GetDormSex(characterId)
    --    return XDormConfig.GetCharacterStyleConfigSexById(characterId)
    --end

    function XDormManager.NotifyAddDormCharacter(data)
        if data then
            for _, v in pairs(data) do
                CharacterData[v.CharacterId] = v
                if v.DormitoryId and v.DormitoryId > 0 then
                    local roomData = DormitoryData[v.DormitoryId]
                    if roomData then
                        roomData:AddCharacter(v)
                    end
                end
            end
        end
    end

    -- 获取他人宿舍模板请求
    function XDormManager.DormGetPlayerLayoutReq(shareId, cb)
        if not shareId then
            return
        end

        local req = { ShareId = shareId }
        XNetwork.Call(DormitoryRequest.DormGetPlayerLayoutReq, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end


            XDormManager.SetDormProvisionalData(shareId, res.FurnitureList)
            if cb then
                cb()
            end
        end)
    end

    -- 绑定模板宿舍
    function XDormManager.DormBindLayoutReq(dormId, templateId, cb)
        if not dormId or not templateId then
            return
        end

        local req = { DormitoryId = dormId, LayoutId = templateId }
        XNetwork.Call(DormitoryRequest.DormBindLayoutReq, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    -- 解除绑定模板宿舍
    function XDormManager.DormUnBindLayoutReq(templateId, cb)
        if not templateId then
            return
        end

        local req = { LayoutId = templateId }
        XNetwork.Call(DormitoryRequest.DormUnBindLayoutReq, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    -- 收藏宿舍模板
    function XDormManager.DormCollectLayoutReq(id, name, furnitureList, cb)
        if not id or not name or not furnitureList then
            return
        end

        local req = { LayoutId = id, LayoutName = name, FurnitureList = furnitureList }
        XNetwork.Call(DormitoryRequest.DormCollectLayoutReq, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local collectDorm = TempDormitoryData[id]
            if not collectDorm then  -- 普通存储
                local newId = res.NewLayoutId
                TempDormitoryData[newId] = XHomeRoomData.New(newId)
                TempDormitoryData[newId]:SetPlayerId(XPlayer.Id)
                TempDormitoryData[newId]:SetRoomName(name)
                TempDormitoryData[newId]:SetRoomUnlock(true)
                TempDormitoryData[newId]:SetRoomDataType(XDormConfig.DormDataType.Collect)
                TempDormitoryData[newId]:SetRoomCreateTime(res.CreateTime)

                for _, furniture in ipairs(furnitureList) do
                    local incId = XGlobalVar.GetIncId()
                    TempDormitoryData[newId]:AddFurniture(incId, furniture.ConfigId, furniture.X, furniture.Y, furniture.Angle)
                end
            else -- 覆盖存储
                collectDorm:SetRoomName(name)
                collectDorm:ClearFruniture()
                for i, furniture in ipairs(furnitureList) do
                    collectDorm:AddFurniture(i, furniture.ConfigId, furniture.X, furniture.Y, furniture.Angle)
                end
            end

            local roomId = collectDorm and id or res.NewLayoutId
            if cb then
                cb(roomId)
            end
        end)
    end

    -- 收藏宿舍摆放家具
    function XDormManager.CollectPutFunitrue(id, name, furnitureList, cb)
        if not id or not name or not furnitureList then
            return
        end

        local req = { LayoutId = id, LayoutName = name, FurnitureList = furnitureList }
        XNetwork.Call(DormitoryRequest.DormCollectLayoutReq, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    -- 一键摆放模板宿舍
    function XDormManager.CopyTemplateDorm(roomId, templateDormId, roomType, cb)
        local room = XDataCenter.DormManager.GetRoomDataByRoomId(roomId, XDormConfig.DormDataType.Self)
        local templateRoom = XDataCenter.DormManager.GetRoomDataByRoomId(templateDormId, roomType)
        if not room or not templateRoom then
            return
        end

        local roomFurnitureConfigs = room:GetFurnitureConfigDic()
        local templateFurnitures = templateRoom:GetFurnitureDic()

        -- 未使用背包家具
        local caheBagConfigs = XTool.Clone(XDataCenter.FurnitureManager.GetUnuseFurnitue())
        -- 临时缓存宿舍数据
        local cacheRoom = XHomeRoomData.New(roomId)

        for _, v in pairs(templateFurnitures) do
            local notFurniture = true
            -- 检查当前宿舍中是否有此家具
            local furnitureIds = roomFurnitureConfigs[v.ConfigId]
            if furnitureIds and #furnitureIds > 0 then
                local id = furnitureIds[1]
                notFurniture = false
                cacheRoom:AddFurniture(id, v.ConfigId, v.GridX, v.GridY, v.RotateAngle)
                table.remove(furnitureIds, 1)
            else
                -- 检查背包中是否有此家具
                local bagFurnitureIds = caheBagConfigs[v.ConfigId]
                if bagFurnitureIds and #bagFurnitureIds > 0 then
                    local id = bagFurnitureIds[1]
                    notFurniture = false
                    cacheRoom:AddFurniture(id, v.ConfigId, v.GridX, v.GridY, v.RotateAngle)
                    table.remove(bagFurnitureIds, 1)
                end
            end

            -- 保留地板，天花板，墙
            local baseType = XFurnitureConfigs.HomeSurfaceBaseType
            local tempF = nil
            if XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(v.ConfigId, baseType.Ground) and notFurniture then
                tempF = room:GetGroundFurniture()
            elseif XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(v.ConfigId, baseType.Ceiling) and notFurniture then
                tempF = room:GetCeillingFurniture()
            elseif XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(v.ConfigId, baseType.Wall) and notFurniture then
                tempF = room:GetWallFurniture()
            end

            if notFurniture and tempF then
                cacheRoom:AddFurniture(tempF.Id, tempF.ConfigId, tempF.GridX, tempF.GridY, tempF.RotateAngle)
            end
        end

        local furnitures = cacheRoom:GetFurnitureDic()
        local furnitureList = {}
        for _, v in pairs(furnitures) do
            local data = {}
            data.Id = v.Id
            data.X = v.GridX
            data.Y = v.GridY
            data.Angle = v.RotateAngle
            table.insert(furnitureList, data)
        end

        if #furnitureList <= 0 then
            XUiManager.TipText("DormTemplateOneKeyNone", XUiManager.UiTipType.Tip)
            return
        end

        XDataCenter.FurnitureManager.PutFurniture(roomId, furnitureList, false, function()
            XDormManager.SetRoomDataDormitoryId(room, 0)
            XDormManager.SetRoomDataDormitoryId(cacheRoom, roomId)

            room:SetFurnitureDic(furnitures)
            local datas = { room }
            local isNotChangeView = true
            XHomeDormManager.LoadRooms(datas, XDormConfig.DormDataType.Self, isNotChangeView)
            if cb then
                cb()
            end
        end)
    end
    --================
    --推送宿舍名变更
    --@param data:{ int DormId, string DormName}
    --================
    function XDormManager.NotifyDormName(data)
        local dorm = DormitoryData[data.DormId]
        if dorm then dorm:SetRoomName(data.DormName) end
    end
    ---------------------end net---------------------

    ---
    --- 是否有权限访问其他玩家宿舍
    ---@param playerId number
    ---@param appearanceShowType number 类型为XUiAppearanceShowType枚举
    ---@return boolean
    function XDormManager.HasDormPermission(playerId, appearanceShowType)
        if playerId == XPlayer.Id then
            return true
        else
            if appearanceShowType then
                if appearanceShowType == XUiAppearanceShowType.ToAll then
                    return true
                elseif appearanceShowType == XUiAppearanceShowType.ToSelf then
                    return false
                elseif appearanceShowType == XUiAppearanceShowType.ToFriend then
                    return XDataCenter.SocialManager.CheckIsFriend(playerId)
                else
                    XLog.Error("XDormManager.HasDormPermission函数错误，展示设置不属于XUiAppearanceShowType类型")
                    return false
                end
            else
                XLog.Error("XDormManager.HasDormPermission函数错误，没有玩家宿舍展示设置数据")
                return false
            end
        end
    end

    function XDormManager.GetCharacterData()
        return CharacterData
    end

    return XDormManager
end

XRpc.NotifyDormVisitEnter = function(data)
    XDataCenter.DormManager.NotifyDormVisitEnter(data)
end
--================
--通知宿舍名称改变
--@param data:{ int DormId, string DormName}
--================
XRpc.NotifyDormName = function(data)
    XDataCenter.DormManager.NotifyDormName(data)
end

XRpc.NotifyWorkNextRefreshTime = function(data)
    XDataCenter.DormManager.NotifyDormWorkRefreshTime(data)
end

XRpc.NotifyCharacterAttr = function(data)
    XDataCenter.DormManager.NotifyCharacterAttr(data)
end

XRpc.NotifyCharacterMood = function(data)
    XDataCenter.DormManager.NotifyCharacterMood(data)
end

XRpc.NotifyCharacterVitality = function(data)
    XDataCenter.DormManager.NotifyCharacterVitality(data)
end

XRpc.NotifyDormCharacterRecovery = function(data)
    XDataCenter.DormManager.NotifyCharacterSpeedChange(data)
end

XRpc.NotifyDormCharacterAddEvent = function(data)
    XDataCenter.DormManager.NotifyDormCharacterAddEvent(data)
end

XRpc.NotifyDormCharacterSubEvent = function(data)
    XDataCenter.DormManager.NotifyDormCharacterSubEvent(data)
end

XRpc.NotifyDormitoryData = function(data)
    -- 初始化默认一次的数据
    XDataCenter.DormManager.InitOnlyOnce()
    -- 之前旧协议原有字段
    XDataCenter.DormManager.NotifyDormWork(data)
    XDataCenter.DormManager.NotifySnapshotTimes(data)
    XDataCenter.DormManager.NotifyFurnitureUnLock(data)
    XDataCenter.FurnitureManager.InitFurnitureCreateList(data)
    -- from DormitoryDataRequest
    XDataCenter.DormManager.InitDormitoryData(data.DormitoryList)
    XDataCenter.DormManager.InitFurnitureData(data.FurnitureList)
    XDataCenter.DormManager.InitCharacterData(data.CharacterList)
    XDataCenter.DormManager.InitdormCollectData(data.Layouts)
    XDataCenter.DormManager.InitbindRelationData(data.BindRelations)
    XDataCenter.FurnitureManager.InitData(data.FurnitureList)
end

XRpc.NotifyAddDormCharacter = function(data)
    XDataCenter.DormManager.NotifyAddDormCharacter(data)
end

XRpc.NotifyDormExceptionItem = function(data)
    XUiManager.TipMsg(CS.XTextManager.GetText("DormExceptionItemConvert"))
end

XRpc.NotifyDormDailyReset = function (data)
    XDataCenter.DormManager.NotifySnapshotTimes(data)
end