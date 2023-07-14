local pairs = pairs
local table = table
local tableInsert = table.insert
local tableSort = table.sort

XFashionManagerCreator = function()
    local XFashionManager = {}

    XFashionManager.FashionStatus = {
        -- 未拥有
        UnOwned = 0,
        -- 未解锁
        Lock = 1,
        -- 已解锁
        UnLock = 2,
        -- 已穿戴
        Dressed = 3,
    }

    local TABLE_FASHION_PATH = "Share/Fashion/Fashion.tab"
    local METHOD_NAME = {
        Use = "FashionUseRequest",
        Unlock = "FashionUnLockRequest",
    }

    local FashionTemplates = {}      -- 时装配置
    local OwnFashionStatus = {}           -- 已拥有的时装
    local CharFashions = {}     -- 角色对应时装列表
    local ResToFashionTab = {} -- 资源Id对应时装表
    local FashionHeadPortraitDic = {} -- 涂装头像Dic

    --==============================--
    --desc: 获取时装配置
    --@id: 时装Id
    --@return: 时装配置
    --==============================--
    function XFashionManager.GetFashionTemplate(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionTemplate", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab
    end

    function XFashionManager.IsFashionInTime(id)
        if not XTool.IsNumberValid(id) then return false end
        local fashionTemplate = XFashionManager.GetFashionTemplate(id)
        local showTimeStr = fashionTemplate.ShowTimeStr
        if string.IsNilOrEmpty(showTimeStr) then
            return true
        end
        local timeStamp = XTime.GetServerNowTimestamp()
        return timeStamp >= XTime.ParseToTimestamp(showTimeStr)
    end

    --==============================--
    --desc: 获取在显示时间内的整个时装配置
    --@return: 时装配置
    --==============================--
    function XFashionManager.GetAllFashionTemplateInTime()
        local allFashionTemplates = XTool.Clone(FashionTemplates)
        local fashionTemplateDic = {}
        local timeStamp = XTime.GetServerNowTimestamp()
        for _, fashionTemplate in pairs(allFashionTemplates) do
            local showTimeStr = fashionTemplate.ShowTimeStr
            if showTimeStr then
                if (timeStamp >= XTime.ParseToTimestamp(showTimeStr)) then
                    fashionTemplateDic[fashionTemplate.Id] = fashionTemplate
                end
            else
                fashionTemplateDic[fashionTemplate.Id] = fashionTemplate
            end
        end

        return fashionTemplateDic
    end

    --==============================--
    --desc: 获取拥有时装配置
    --@return: 已拥有时装
    --==============================--
    function XFashionManager.GetOwnFashionStatus()
        return XTool.Clone(OwnFashionStatus)
    end

    --==============================--
    --desc: 是否拥有时装
    --@id: 时装id
    --@return 拥有为true，否则false
    --==============================--
    -- local function CheckOwnFashion(id)
    --     return OwnFashionStatus[id] ~= nil
    -- end
    --==============================--
    --desc: 时装是否已穿戴
    --@id: 时装id
    --@return 穿戴为true，否则false
    --==============================--
    local function IsFashionDressed(id)
        local template = XFashionManager.GetFashionTemplate(id)

        if not template then
            return false
        end

        local char = XDataCenter.CharacterManager.GetCharacter(template.CharacterId)
        if not char then
            return false
        end

        return char.FashionId == id
    end

    --==============================--
    --desc: 获取时装状态
    --@id: 时装id
    --@return 状态
    --==============================--
    function XFashionManager.GetFashionStatus(id)
        local status = OwnFashionStatus[id]

        if status == nil then
            return XFashionManager.FashionStatus.UnOwned
        end

        if IsFashionDressed(id) then
            return XFashionManager.FashionStatus.Dressed
        end

        return status and XFashionManager.FashionStatus.Lock or XFashionManager.FashionStatus.UnLock
    end

    function XFashionManager.Init()
        FashionTemplates = XTableManager.ReadByIntKey(TABLE_FASHION_PATH, XTable.XTableFashion, "Id")

        local defaultHeadIconCheck = {}--默认头像只允许配置一种
        local liberationHeadIconCheck = {}--终解头像只允许配置一种
        for id, template in pairs(FashionTemplates) do
            local characterId = template.CharacterId

            local list = CharFashions[characterId]
            if not list then
                list = {}
            end

            tableInsert(list, id)
            CharFashions[characterId] = list
            --初始化资源ID对应时装Id
            ResToFashionTab[template.ResourcesId] = id

            --初始化characterId对应所有可选择头像（重复头像做去重处理）
            local headDic = FashionHeadPortraitDic[characterId]
            if not headDic then
                headDic = {}
                FashionHeadPortraitDic[characterId] = headDic
            end
            local iconPath
            iconPath = template.SmallHeadIcon --默认头像
            if iconPath and not headDic[iconPath] then
                if not defaultHeadIconCheck[characterId] then
                    headDic[iconPath] = {
                        HeadFashionId = XCharacterConfigs.GetCharacterTemplate(characterId).DefaultNpcFashtionId, --角色默认涂装Id
                        HeadFashionType = XFashionConfigs.HeadPortraitType.Default,
                    }
                    defaultHeadIconCheck[characterId] = iconPath
                else
                    XLog.Error("XFashionManager.Init error: 同一角色默认头像不允许配置多个,请修改SmallHeadIcon字段,配置路径: " .. TABLE_FASHION_PATH .. " ,id: " .. id .. " ,characterId: " .. characterId)
                end
            end
            iconPath = template.SmallHeadIconLiberation--终解头像
            if iconPath and not headDic[iconPath] then
                if not liberationHeadIconCheck[characterId] then
                    headDic[iconPath] = {
                        HeadFashionId = XCharacterConfigs.GetCharacterTemplate(characterId).DefaultNpcFashtionId, --角色默认涂装Id
                        HeadFashionType = XFashionConfigs.HeadPortraitType.Liberation,
                    }
                    liberationHeadIconCheck[characterId] = iconPath
                else
                    XLog.Error("XFashionManager.Init error: 同一角色终解头像不允许配置多个,请修改SmallHeadIconLiberation字段,配置路径: " .. TABLE_FASHION_PATH .. " ,id: " .. id .. " ,characterId: " .. characterId)
                end
            end
            iconPath = template.SmallHeadIconFashion--特效皮肤
            if iconPath and not headDic[iconPath] then
                headDic[iconPath] = {
                    HeadFashionId = id,
                    HeadFashionType = XFashionConfigs.HeadPortraitType.Fashion,
                }
            end
        end
    end

    function XFashionManager.InitFashions(fashions)
        local fashionDic = {}
        for _, data in ipairs(fashions) do
            fashionDic[data.Id] = data.IsLock
        end

        OwnFashionStatus = fashionDic
    end

    function XFashionManager.GetFashionHeadPortraitList(characterId)
        local headList = {}

        local headDic = FashionHeadPortraitDic[characterId] or {}
        for iconPath, oHeadInfo in pairs(headDic) do
            if XFashionManager.IsFashionInTime(oHeadInfo.HeadFashionId) then
                tableInsert(headList, {
                    Icon = iconPath,
                    HeadFashionId = oHeadInfo.HeadFashionId,
                    HeadFashionType = oHeadInfo.HeadFashionType,
                })
            end
        end

        tableSort(headList, function(a, b)
            local aId = a.HeadFashionId
            local bId = b.HeadFashionId

            --使用中
            local aIsUsing = XFashionManager.IsFashionHeadUsing(a.HeadFashionId, a.HeadFashionType, characterId)
            local bIsUsing = XFashionManager.IsFashionHeadUsing(b.HeadFashionId, b.HeadFashionType, characterId)
            if aIsUsing ~= bIsUsing then
                return aIsUsing
            end

            --已解锁
            local aUnLock = XFashionManager.IsFashionHeadUnLock(a.HeadFashionId, a.HeadFashionType, characterId)
            local bUnLock = XFashionManager.IsFashionHeadUnLock(b.HeadFashionId, b.HeadFashionType, characterId)
            if aUnLock ~= bUnLock then
                return aUnLock
            end

            return a.HeadFashionType < b.HeadFashionType
        end)

        return headList
    end

    --时装头像是否解锁
    function XFashionManager.IsFashionHeadUnLock(headFashionId, headFashionType, characterId)
        if not XFashionManager.IsFashionInTime(headFashionId) then return false end

        if headFashionType == XFashionConfigs.HeadPortraitType.Default then
            return true
        elseif headFashionType == XFashionConfigs.HeadPortraitType.Liberation then
            if not XTool.IsNumberValid(characterId) then
                return false
            end
            return XDataCenter.ExhibitionManager.IsAchieveMaxLiberation(characterId)
        elseif headFashionType == XFashionConfigs.HeadPortraitType.Fashion then
            return XFashionManager.CheckHasFashion(headFashionId)
        end

        return false
    end

    --时装头像是否使用中
    function XFashionManager.IsFashionHeadUsing(headFashionId, headFashionType, characterId)
        if not XFashionManager.IsFashionInTime(headFashionId) then return false end

        local usingHeadFashionId, usingHeadFashionType = XDataCenter.CharacterManager.GetCharacterFashionHeadInfo(characterId)
        return headFashionId == usingHeadFashionId
        and headFashionType == usingHeadFashionType
    end

    --获取时装头像解锁条件描述
    function XFashionManager.GetFashionHeadUnlockConditionDesc(headFashionType)
        if headFashionType == XFashionConfigs.HeadPortraitType.Default then
            return CsXTextManagerGetText("UiFashionHeadPortraitConditionDefault")
        elseif headFashionType == XFashionConfigs.HeadPortraitType.Liberation then
            return CsXTextManagerGetText("UiFashionHeadPortraitConditionLiberation")
        elseif headFashionType == XFashionConfigs.HeadPortraitType.Fashion then
            return CsXTextManagerGetText("UiFashionHeadPortraitConditionFashion")
        end
        return ""
    end

    --==============================--
    --desc: 检查角色是否有时装
    --@id: 时装Id
    --@return: 是否有时装
    --==============================--
    function XFashionManager.CheckHasFashion(id)
        return OwnFashionStatus[id] ~= nil
    end

    --==============================--
    --desc: 服务器获得时装推送
    --protoData：时装数据
    --==============================--
    function XFashionManager.NotifyFashionDict(data)
        local fashions = data.FashionList
        if not fashions then
            return
        end

        for _, tmpData in ipairs(fashions) do
            OwnFashionStatus[tmpData.Id] = tmpData.IsLock
        end
    end

    local function GetFashionSmallHeadIcon(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionSmallHeadIcon", "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.SmallHeadIcon
    end

    --==============================--
    --desc: 获取时装图标
    --@fashionId: 时装id
    --@return 时装对应的人物角色小图像图标
    --==============================--
    function XFashionManager.GetFashionSmallHeadIcon(fashionId, headFashionType)
        if headFashionType == XFashionConfigs.HeadPortraitType.Liberation then
            return XFashionManager.GetFashionSmallHeadIconLiberation(fashionId)
        elseif headFashionType == XFashionConfigs.HeadPortraitType.Fashion then
            return XFashionManager.GetFashionSmallHeadIconFashion(fashionId)
        else
            return GetFashionSmallHeadIcon(fashionId)
        end
    end

    --==============================--
    --desc: 获取时装图标【三阶解放版】
    --@fashionId: 时装id
    --@return 时装对应的人物角色小图像图标【三阶解放版】
    --==============================--
    function XFashionManager.GetFashionSmallHeadIconLiberation(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionSmallHeadIconLiberation",
            "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.SmallHeadIconLiberation
    end

    --==============================--
    --desc: 获取时装图标【特效时装版】
    --@fashionId: 时装id
    --@return 时装对应的人物角色小图像图标【特效时装版】
    --==============================--
    function XFashionManager.GetFashionSmallHeadIconFashion(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionSmallHeadIconFashion",
            "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.SmallHeadIconFashion
    end

    local function GetFashionBigHeadIcon(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionBigHeadIcon", "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.BigHeadIcon
    end

    --==============================--
    --desc: 获取时装图标
    --@fashionId: 时装id
    --@return 时装对应的人物角色大图像图标
    --==============================--
    function XFashionManager.GetFashionBigHeadIcon(fashionId, headFashionType)
        if headFashionType == XFashionConfigs.HeadPortraitType.Liberation then
            return XFashionManager.GetFashionBigHeadIconLiberation(fashionId)
        elseif headFashionType == XFashionConfigs.HeadPortraitType.Fashion then
            return XFashionManager.GetFashionBigHeadIconFashion(fashionId)
        else
            return GetFashionBigHeadIcon(fashionId)
        end
    end

    --==============================--
    --desc: 获取时装图标【三阶解放版】
    --@fashionId: 时装id
    --@return 时装对应的人物角色大图像图标【三阶解放版】
    --==============================--
    function XFashionManager.GetFashionBigHeadIconLiberation(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionBigHeadIconLiberation",
            "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.BigHeadIconLiberation
    end

    --==============================--
    --desc: 获取时装图标【特效时装版】
    --@fashionId: 时装id
    --@return 时装对应的人物角色大图像图标【特效时装版】
    --==============================--
    function XFashionManager.GetFashionBigHeadIconFashion(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionBigHeadIconFashion",
            "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.BigHeadIconFashion
    end

    --==============================--
    --desc: 获取时装图标
    --@fashionId: 时装id
    --@return 时装对应的人物角色小圆形图像图标
    --==============================--
    function XFashionManager.GetFashionRoundnessHeadIcon(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionRoundnessHeadIcon", "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.RoundnessHeadIcon
    end

    --==============================--
    --desc: 获取时装图标
    --@fashionId: 时装id
    --@return 时装对应的人物角色大圆形图像图标
    --==============================--
    function XFashionManager.GetFashionBigRoundnessHeadIcon(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionBigRoundnessHeadIcon", "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.BigRoundnessHeadIcon
    end

    --==============================--
    --desc: 获取时装图标
    --@fashionId: 时装id
    --@return 时装对应的人物角色圆形图像图标(非物品使用)
    --==============================--
    function XFashionManager.GetFashionRoundnessNotItemHeadIcon(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionRoundnessNotItemHeadIcon",
            "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.RoundnessNotItemHeadIcon
    end

    --==============================--
    --desc: 获取时装图标
    --@fashionId: 时装id
    --@return 时装对应的人物角色圆形图像图标(非物品使用)【三阶解放版】
    --==============================--
    function XFashionManager.GetFashionRoundnessNotItemHeadIconLiberation(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionRoundnessNotItemHeadIconLiberation",
            "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.RoundnessNotItemHeadIconLiberation
    end

    --==============================--
    --desc: 获取时装图标
    --@fashionId: 时装id
    --@return 时装对应的人物角色半身像（剧情用）
    --==============================--
    function XFashionManager.GetFashionHalfBodyImage(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionHalfBodyImage", "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.HalfBodyImage
    end

    --==============================--
    --desc: 获取时装图标
    --@fashionId: 时装id
    --@return 时装对应的人物角色半身像（通用）
    --==============================--
    function XFashionManager.GetRoleCharacterBigImage(fashionId)
        local tab = FashionTemplates[fashionId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetRoleCharacterBigImage", "tab", TABLE_FASHION_PATH, "fashionId", tostring(fashionId))
            return
        end
        return tab.RoleCharacterBigImage
    end

    --==============================--
    --desc: 获取时装图标
    --@id: 时装id
    --@return 时装图标
    --==============================--
    function XFashionManager.GetFashionIcon(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionIcon", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab.Icon
    end

    --==============================--
    --desc: 根据ResourcesId获取FashionId
    --@id: 资源id
    --@return FashionId
    --==============================--
    function XFashionManager.GetFashionIdByResId(resId)
        local id = ResToFashionTab[resId]
        if id == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionIdByResId", "时装Id", TABLE_FASHION_PATH, "ResourceId", tostring(resId))
        end
        return id
    end
    --==============================--
    --desc: 获取ResourcesId
    --@id: 时装id
    --@return ResourcesId
    --==============================--
    function XFashionManager.GetResourcesId(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetResourcesId", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab.ResourcesId
    end
    --==============================--
    --desc: 获取CharacterId
    --@id: 时装id
    --@return CharacterId
    --==============================--
    function XFashionManager.GetCharacterId(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetCharacterId", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab.CharacterId
    end
    --==============================--
    --desc: 获取时装大图标
    --@id: 时装id
    --@return 时装大图标
    --==============================--
    function XFashionManager.GetFashionBigIcon(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionBigIcon", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab.BigIcon
    end
    --==============================--
    --desc: 获取时装立绘图标
    --@id: 时装id
    --@return 时装图标
    --==============================--
    function XFashionManager.GetFashionCharacterIcon(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.CharacterIcon", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab.CharacterIcon
    end
    --==============================--
    --desc: 拿取时装名字
    --@id: 时装Id
    --@return: 时装名字
    --==============================--
    function XFashionManager.GetFashionName(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionName", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab.Name
    end

    --==============================--
    --desc: 拿取时装品质
    --@id: 时装Id
    --@return: 时装品质
    --==============================--
    function XFashionManager.GetFashionQuality(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionQuality", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab.Quality
    end

    --==============================--
    --desc: 拿取时装系列
    --@id: 时装Id
    --@return: 时装系列Id
    --==============================--
    function XFashionManager.GetFashionSeries(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionSeries", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab.Series
    end

    --==============================--
    --desc: 拿取时装简介1
    --@id: 时装Id
    --@return: 时装简介
    --==============================--
    function XFashionManager.GetFashionDesc(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionDesc", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab.Description
    end

    --==============================--
    --desc: 拿取时装简介2
    --@id: 时装Id
    --@return: 时装简介
    --==============================--
    function XFashionManager.GetFashionWorldDescription(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionWorldDescription", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab.WorldDescription
    end


    --==============================--
    --desc: 拿取时装跳转列表
    --@id: 时装Id
    --@return: 时装列表
    --==============================--
    function XFashionManager.GetFashionSkipIdParams(id)
        local tab = FashionTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionSkipIdParams", "tab", TABLE_FASHION_PATH, "id", tostring(id))
        end
        return tab.SkipIdParams
    end


    local SortStatusPriority = {
        [XFashionManager.FashionStatus.UnOwned] = 1,
        [XFashionManager.FashionStatus.UnLock] = 2,
        [XFashionManager.FashionStatus.Lock] = 3,
        [XFashionManager.FashionStatus.Dressed] = 4
    }

    --==============================--
    --desc: 通过角色ID获取角色所有时装信息
    --@charId: 角色ID
    --@return: 时装List
    --==============================--
    function XFashionManager.GetFashionByCharId(charId)
        local fashions = CharFashions[charId]
        if not fashions then
            XLog.Error("XFashionManager.GetFashionByCharId 错误: 无法根据参数charId " .. charId .. "获取" .. TABLE_FASHION_PATH .. "表中的时装信息, 检查charId获取这配置表")
            return
        end

        local fashionIdList = {}
        for _, id in pairs(fashions) do
            tableInsert(fashionIdList, id)
        end

        tableSort(fashionIdList, function(a, b)
            local status1, status2 = XFashionManager.GetFashionStatus(a), XFashionManager.GetFashionStatus(b)

            if status1 ~= status2 then
                return SortStatusPriority[status1] > SortStatusPriority[status2]
            end

            return XFashionManager.GetFashionPriority(a) > XFashionManager.GetFashionPriority(b)
        end)

        return fashionIdList
    end

    --==============================--
    --desc: 通过角色ID获取角色当前时间可以显示的所有时装信息
    --@charId: 角色ID
    --@return: 时装List
    --==============================--
    function XFashionManager.GetCurrentTimeFashionByCharId(charId)
        local fashions = CharFashions[charId]
        if not fashions then
            XLog.Error("XFashionManager.GetFashionByCharId 错误: 无法根据参数charId " .. charId .. "获取" .. TABLE_FASHION_PATH .. "表中的时装信息, 检查charId获取这配置表")
            return
        end

        local fashionIdList = {}
        local timeStamp = XTime.GetServerNowTimestamp()
        for _, id in pairs(fashions) do
            local fashionTemplate = XFashionManager.GetFashionTemplate(id)
            if fashionTemplate then
                local showTimeStr = fashionTemplate.ShowTimeStr
                if showTimeStr then
                    local showTimeStamp = XTime.ParseToTimestamp(showTimeStr)
                    if (timeStamp >= showTimeStamp) then
                        tableInsert(fashionIdList, id)
                    end
                else
                    tableInsert(fashionIdList, id)
                end
            end
        end

        if #fashionIdList > 0 then
            tableSort(fashionIdList, function(a, b)
                local status1, status2 = XFashionManager.GetFashionStatus(a), XFashionManager.GetFashionStatus(b)

                if status1 ~= status2 then
                    return SortStatusPriority[status1] > SortStatusPriority[status2]
                end

                return XFashionManager.GetFashionPriority(a) > XFashionManager.GetFashionPriority(b)
            end)
        end

        return fashionIdList
    end
    
    --==============================--
    --desc: 通过角色ID获取角色所有时装ResId（C#调试用）
    --@charId: 角色ID
    --@return: ResIdList
    --==============================--
    function XFashionManager.GetResIdListByCharId(charId)
        local resIdList = {}
        local fashions = CharFashions[charId]
        if not fashions then
            XLog.Error("XFashionManager.GetFashionByCharId 错误: 无法根据参数charId " ..
 charId .. "获取" .. TABLE_FASHION_PATH .. "表中的时装信息, 检查charId获取这配置表")
            return resIdList
        end

        for _, id in pairs(fashions) do
            tableInsert(resIdList, FashionTemplates[id].ResourcesId)
        end

        return resIdList
    end
    
    --==============================--
    --desc: 通过角色ID获取角色当前使用时装信息
    --@charId: 角色ID
    --@return: 当前使用的时装信息
    --==============================--
    function XFashionManager.GetFashionResourceIdByCharId(charId)
        local char = XDataCenter.CharacterManager.GetCharacter(charId)
        local fashionId = char and char.FashionId or XDataCenter.CharacterManager.GetShowFashionId(charId)
        local template = XFashionManager.GetFashionTemplate(fashionId)
        if template then
            return template.ResourcesId
        end
    end

    --==============================--
    --desc: 通过角色ID获取角色当前使用时装ID
    --@charId: 角色ID
    --@return: 当前使用的时装信息
    --==============================--
    function XFashionManager.GetFashionIdByCharId(charId)
        local char = XDataCenter.CharacterManager.GetCharacter(charId)
        local fashionId = char and char.FashionId or XDataCenter.CharacterManager.GetShowFashionId(charId)
        local template = XFashionManager.GetFashionTemplate(fashionId)
        if template then
            return template.Id
        end
    end

    --==============================--
    --desc: 通过XFightNpcData返回资源
    --@fightNpcData: 角色数据
    --@return: 角色模型名称
    --==============================--
    function XFashionManager.GetCharacterModelName(fightNpcData)
        if not fightNpcData then
            XLog.Error("XFashionManager.GetCharacterModelName 错误: 参数fightNpcData不能为空")
            return
        end

        local fashionId = fightNpcData.Character.FashionId
        if fashionId <= 0 then
            local charId = fightNpcData.Character.Id
            fashionId = XCharacterConfigs.GetCharacterTemplate(charId).DefaultNpcFashtionId
        end
        local resId = XFashionManager.GetFashionTemplate(fashionId).ResourcesId

        return XDataCenter.CharacterManager.GetCharResModel(resId)
    end

    --==============================--
    --desc: 通过fashionId拿取头像信息
    --@fightNpcData: fashionId
    --@return: 头像Icon
    --==============================--
    function XFashionManager.GetCharacterModelIcon(fashionId, charId)
        if not fashionId then
            XLog.Error("XFashionManager.GetCharacterModelIcon 错误: 参数fashionId不能为空")
            return
        end

        if fashionId <= 0 then
            fashionId = XCharacterConfigs.GetCharacterTemplate(charId).DefaultNpcFashtionId
        end

        local resId = XFashionManager.GetFashionTemplate(fashionId).ResourcesId
        return XDataCenter.CharacterManager.GetCharResIcon(resId)
    end

    --==============================--
    --desc: 获取时装显示优先级
    --@templateId: 时装配置表id
    --@return 显示优先级
    --==============================--
    function XFashionManager.GetFashionPriority(templateId)
        local tab = FashionTemplates[templateId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionPriority", "tab", TABLE_FASHION_PATH, "templateId", tostring(templateId))
        end
        return tab.Priority
    end

    --==============================--
    --desc: 获取时装对应场景路径
    --@templateId: 时装配置表id
    --@return 场景路径SceneUrl
    --==============================--
    function XFashionManager.GetFashionSceneUrl(templateId)
        local tab = FashionTemplates[templateId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionSceneUrl", "tab", TABLE_FASHION_PATH, "templateId", tostring(templateId))
            return
        end

        if not tab.SceneModelId or tab.SceneModelId == 0 then
            return
        end

        local sceneUrl, _ = XSceneModelConfigs.GetSceneAndModelPathById(tab.SceneModelId)
        if not sceneUrl then
            return
        end

        return sceneUrl
    end

    --==============================--
    --desc: 获取时装对应解放特效配置
    --@templateId: 时装配置表id
    --@return EffectRootName, EffectPath
    --==============================--
    function XFashionManager.GetFashionLiberationEffectRootAndPath(templateId)
        local tab = FashionTemplates[templateId]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionLiberationEffectRootAndPath", "tab", TABLE_FASHION_PATH, "templateId", tostring(templateId))
        end

        local rootName, fxPath = tab.EffectRootName, tab.EffectPath
        if not rootName or not fxPath then
            XLog.ErrorTableDataNotFound("XFashionManager.GetFashionLiberationEffectRootAndPath", "EffectRootName/EffectPath", TABLE_FASHION_PATH, "templateId", tostring(templateId))
        end

        return rootName, fxPath
    end

    -- service config begin --
    function XFashionManager.UseFashion(id, cb, errorCb, skipJudge)
        if not skipJudge then
            local temp = XFashionManager.GetFashionTemplate(id)
            if temp and not XDataCenter.CharacterManager.IsOwnCharacter(temp.CharacterId) then
                XUiManager.TipText("CharacterLock")
                return
            end
        end

        XNetwork.Call(METHOD_NAME.Use, { FashionId = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if errorCb then
                    errorCb()
                end
                return
            end

            if cb then cb() end
        end)
    end

    function XFashionManager.UnlockFashion(id, cb)
        local status = XFashionManager.GetFashionStatus(id)
        if status == XFashionManager.FashionStatus.UnOwned then
            XUiManager.TipCode(XCode.FashionIsUnOwned)
            return
        end

        if status ~= XFashionManager.FashionStatus.Lock then
            XUiManager.TipCode(XCode.FashionIsUnLock)
            return
        end

        XNetwork.Call(METHOD_NAME.Unlock, { FashionId = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
            end

            if cb then cb() end
        end)
    end
    -- service config end --
    XFashionManager.Init()
    return XFashionManager
end

XRpc.FashionSyncNotify = function(data)
    XDataCenter.FashionManager.NotifyFashionDict(data)
end