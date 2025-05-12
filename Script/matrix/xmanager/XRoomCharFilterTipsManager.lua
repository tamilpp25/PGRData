XRoomCharFilterTipsManagerCreator = function()
    local XRoomCharFilterTipsManager = {}

    local SelectTag = {}
    local TempSelectTag = {}

    local SortTag
    local TempSortTag

    local CharacterTypeDic = {}
    local SortFunction = {}

    local function InitSortFunction()
        local LevelSort = function(idA, idB, isAscendOrder)
            local levelA = XMVCA.XCharacter:GetCharacterLevel(idA)
            local levelB = XMVCA.XCharacter:GetCharacterLevel(idB)
            local isSort = false
            if levelA ~= levelB then
                isSort = true
                if isAscendOrder then
                    return isSort, levelA < levelB
                end
                return isSort, levelA > levelB
            end
            return isSort
        end

        local QualitySort = function(idA, idB, isAscendOrder)
            local qualityA = XMVCA.XCharacter:GetCharacterQuality(idA)
            local qualityB = XMVCA.XCharacter:GetCharacterQuality(idB)
            local isSort = false
            if qualityA ~= qualityB then
                isSort = true
                if isAscendOrder then
                    return isSort, qualityA < qualityB
                end
                return isSort, qualityA > qualityB
            end
            return isSort
        end

        local AbilitySort = function(idA, idB, isAscendOrder)
            local abilityA = XMVCA.XCharacter:GetCharacterHaveRobotAbilityById(idA)
            local abilityB = XMVCA.XCharacter:GetCharacterHaveRobotAbilityById(idB)
            local isSort = false
            if abilityA ~= abilityB then
                isSort = true
                if isAscendOrder then
                    return isSort, abilityA < abilityB
                end
                return isSort, abilityA > abilityB
            end
            return isSort
        end
        
        local EquipGuideSort = function(idA, idB, isAscendOrder) 
            local isA = XDataCenter.EquipGuideManager.IsEquipGuideCharacter(idA)
            local isB = XDataCenter.EquipGuideManager.IsEquipGuideCharacter(idB)
            local isSort = false
            if isA ~= isB then
                isSort = true
                return isSort, isA
            end
            return isSort
        end

        SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default] = function(idA, idB, isAscendOrder, alreadySortTag, isSortAbility)
            local isSort, sortResult
            if alreadySortTag ~= XRoomCharFilterTipsConfigs.EnumSortTag.EquipGuide then
                isSort, sortResult = EquipGuideSort(idA, idB, isAscendOrder)
                if isSort then
                    return sortResult
                end
            end
            if alreadySortTag ~= XRoomCharFilterTipsConfigs.EnumSortTag.Level then
                isSort, sortResult = LevelSort(idA, idB, isAscendOrder)
                if isSort then
                    return sortResult
                end
            end

            if isSortAbility and alreadySortTag ~= XRoomCharFilterTipsConfigs.EnumSortTag.Ability then
                isSort, sortResult = AbilitySort(idA, idB, isAscendOrder)
                if isSort then
                    return sortResult
                end
            end

            if alreadySortTag ~= XRoomCharFilterTipsConfigs.EnumSortTag.Quality then
                isSort, sortResult = QualitySort(idA, idB, isAscendOrder)
                if isSort then
                    return sortResult
                end
            end

            local priorityA = XMVCA.XCharacter:GetCharacterPriority(idA)
            local priorityB = XMVCA.XCharacter:GetCharacterPriority(idB)
            if priorityA ~= priorityB then
                if isAscendOrder then
                    return priorityA < priorityB
                end
                return priorityA > priorityB
            end

            return idA > idB
        end
        SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Quality] = function(idA, idB, isAscendOrder)
            local isSort, sortResult = QualitySort(idA, idB, isAscendOrder)
            if isSort then
                return sortResult
            end
            return SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](idA, idB, isAscendOrder, XRoomCharFilterTipsConfigs.EnumSortTag.Quality, true)
        end
        SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Level] = function(idA, idB, isAscendOrder)
            local isSort, sortResult = LevelSort(idA, idB, isAscendOrder)
            if isSort then
                return sortResult
            end
            return SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](idA, idB, isAscendOrder, XRoomCharFilterTipsConfigs.EnumSortTag.Level, true)
        end
        SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Ability] = function(idA, idB, isAscendOrder)
            local isSort, sortResult = AbilitySort(idA, idB, isAscendOrder)
            if isSort then
                return sortResult
            end
            return SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](idA, idB, isAscendOrder, XRoomCharFilterTipsConfigs.EnumSortTag.Ability)
        end
    end

    local function GetSelectTagByCharacterType(characterType)
        if not characterType then
            characterType = XEnumConst.CHARACTER.CharacterType.Normal
        end
        return CharacterTypeDic[characterType] and CharacterTypeDic[characterType]["SelectTag"] or {}
    end

    local function GetSortTagByCharacterType(characterType)
        if not characterType then
            characterType = XEnumConst.CHARACTER.CharacterType.Normal
        end
        return CharacterTypeDic[characterType] and CharacterTypeDic[characterType]["SortTag"]
    end

    ---
    --- 根据character的类型来获取characterId
    local function GetCharacterIdByValueType(character)
        local characterId
        if type(character) == "table" then
            characterId = character.GetCharacterId and character:GetCharacterId() or character.Id
        else
            characterId = character
        end
        return characterId
    end

    ---
    --- 初始化缓存
    function XRoomCharFilterTipsManager.InitTemp(characterType)
        local selectTag = GetSelectTagByCharacterType(characterType)
        TempSelectTag = XTool.Clone(selectTag)
        TempSortTag = GetSortTagByCharacterType(characterType)
    end

    ---
    --- 使用缓存
    function XRoomCharFilterTipsManager.UseTemp(characterType)
        if not characterType then
            characterType = XEnumConst.CHARACTER.CharacterType.Normal
        end
        if not CharacterTypeDic[characterType] then
            CharacterTypeDic[characterType] = {}
        end
        CharacterTypeDic[characterType]["SelectTag"] = TempSelectTag
        CharacterTypeDic[characterType]["SortTag"] = TempSortTag
    end

    ---
    --- 清除缓存
    function XRoomCharFilterTipsManager.ClearTemp()
        TempSelectTag = {}
        TempSortTag = nil
    end

    ---
    --- 被筛选的UI切换或关闭时将所有的选择标签数据还原成默认状态
    function XRoomCharFilterTipsManager.Reset()
        TempSelectTag = {}
        TempSortTag = nil
        CharacterTypeDic = {}
    end

    function XRoomCharFilterTipsManager.Init()
        InitSortFunction()
    end
    ---------------------------------------------------- 筛选标签 ---------------------------------------------------------

    ---
    --- 更新缓存中的筛选标签选择状态
    function XRoomCharFilterTipsManager.SetSelectFilterTag(groupId, filterTagId, isSelect)
        if isSelect then
            if not TempSelectTag[groupId] then
                TempSelectTag[groupId] = {}
            end
            TempSelectTag[groupId][filterTagId] = filterTagId
        else
            (TempSelectTag[groupId] or {})[filterTagId] = nil
            if XTool.IsTableEmpty(TempSelectTag[groupId]) then
                TempSelectTag[groupId] = nil
            end
        end
    end

    ---
    --- 获取缓存中的选择筛选标签,返回给UI进行筛选
    function XRoomCharFilterTipsManager.GetSelectFilterTag()
        return TempSelectTag
    end

    -- 判断是否满足筛选项
    function XRoomCharFilterTipsManager.IsFilterSelectTag(templateId, characterType, isUseTempSelectTag)
        local selectTag = isUseTempSelectTag and TempSelectTag or GetSelectTagByCharacterType(characterType)
        if XTool.IsTableEmpty(selectTag) then
            return true
        end

        local career = XMVCA.XCharacter:GetCharDetailCareer(templateId)
        local obtainElementList = XMVCA.XCharacter:GetCharacterAllElement(templateId, true)
        local tagValue
        local isFill
        for groupId, filterTagIdDic in pairs(selectTag) do
            for filterTagId, _ in pairs(filterTagIdDic) do
                tagValue = XRoomCharFilterTipsConfigs.GetFilterTagValue(filterTagId)
                if groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Career then
                    if tagValue ~= career then
                        return false
                    end
                elseif groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Element then
                    isFill = false
                    for _, element in pairs(obtainElementList) do
                        if element == tagValue then
                            isFill = true
                            break
                        end
                    end
                    if not isFill then
                        return false
                    end
                end
            end
        end
        return true
    end

    ---
    --- 打开界面时，检查当前筛选标签是否被选中
    function XRoomCharFilterTipsManager.CheckFilterTagIsSelect(groupId, filterTagId, characterType)
        local isSelect = false
        local selectTag = GetSelectTagByCharacterType(characterType)

        if (selectTag[groupId] or {})[filterTagId] then
            isSelect = true
        end

        return isSelect
    end

    ---
    --- 根据选择的标签'selectTagGroupDic'构建'tagCacheDic'与'selectTagList'
    ---
    ---@param tagCacheDic table 存放在具体玩法界面上的 标签对应角色的缓存，筛选过一次后，不必每次都重新生成
    ---@param selectTagGroupDic table 选择的筛选标签字典,由XUiRoomCharacterFilterTips传递
    ---
    ---@param allCharList table 存放未进行筛选时的所有相同角色类型的角色
    ---存放的值为number时就是characterId
    ---存放的值为table（Entity）时，一定要有 GetCharacterId()接口 或 Id 字段
    ---
    ---@param judgeCb function 判断是否满足筛选条件的函数，由具体玩法实现
    ---@param filterRefreshCb function 筛选后的刷新函数，由具体玩法实现
    ---@param isThereFilterDataCb function 判断是否有符合筛选角色的函数，由XUiRoomCharacterFilterTips传递
    function XRoomCharFilterTipsManager.Filter(tagCacheDic, selectTagGroupDic, allCharList, judgeCb, filterRefreshCb, isThereFilterDataCb)
        local filteredData = {}
        local selectTagList = {}   -- 选择的标签Id数组

        if XTool.IsTableEmpty(allCharList) then
            XLog.Error("XRoomCharFilterTipsManager.Filter函数错误，参数allCharList为空")
            return
        end
        local characterType
        local characterId = GetCharacterIdByValueType(allCharList[1])
        if characterId then
            characterType = XMVCA.XCharacter:GetCharacterType(GetCharacterIdByValueType(allCharList[1])) or XEnumConst.CHARACTER.CharacterType.Normal
        end
        -- 遍历选择的标签
        for groupId, tagDic in pairs(selectTagGroupDic) do
            for tag, _ in pairs(tagDic) do
                if tagCacheDic[tag] == nil then
                    tagCacheDic[tag] = {}
                end
                if characterType then
                    if tagCacheDic[tag][characterType] == nil then
                        tagCacheDic[tag][characterType] = {}
                        local tagValue = XRoomCharFilterTipsConfigs.GetFilterTagValue(tag)
                        -- 遍历所有角色
                        for _, character in pairs(allCharList) do
                            if judgeCb(groupId, tagValue, character) then
                                -- 当前角色满足该标签
                                local characterId = GetCharacterIdByValueType(character)
                                tagCacheDic[tag][characterType][characterId] = character
                            end
                        end
                    end
                else
                        tagCacheDic[tag].DefaultGroup = {}
                        local tagValue = XRoomCharFilterTipsConfigs.GetFilterTagValue(tag)
                        -- 遍历所有角色
                        for _, character in pairs(allCharList) do
                            if judgeCb(groupId, tagValue, character) then
                                -- 当前角色满足该标签
                                tagCacheDic[tag]["DefaultGroup"][character:GetId()] = character
                            end
                        end
                end
                table.insert(selectTagList, tag)
            end
        end

        -- 没有选择筛选标签
        if next(selectTagList) == nil then
            if isThereFilterDataCb and isThereFilterDataCb(allCharList) then
                filterRefreshCb(allCharList)
                return
            end
        end

        -- 遍历所有角色,进行过滤
        for _, character in pairs(allCharList) do
            local isPass = true
            for _,tag in pairs(selectTagList) do
                local characterId = characterType and GetCharacterIdByValueType(character) or character:GetId()
                if not tagCacheDic[tag][characterType or "DefaultGroup"][characterId] then
                    -- 不满足其中一个标签，跳出标签遍历
                    isPass = false
                    break
                end
            end
            if isPass then
                table.insert(filteredData, character)
            end
        end

        if isThereFilterDataCb and isThereFilterDataCb(filteredData) then
            filterRefreshCb(filteredData)
        end
    end


    ---------------------------------------------------- 排序标签 ---------------------------------------------------------

    ---
    --- 更新缓存中的的排序标签
    function XRoomCharFilterTipsManager.SetSelectSortTag(sortTagId)
        TempSortTag = sortTagId
    end

    ---
    --- 获取缓存中的选择筛选标签，返回给UI进行排序
    function XRoomCharFilterTipsManager.GetSelectSortTag()
        return TempSortTag
    end

    ---
    --- 打开界面时，检查当前排序标签是否被选中
    function XRoomCharFilterTipsManager.CheckSortTagIsSelect(sortTagId, characterType)
        local sortTag = GetSortTagByCharacterType(characterType)
        return sortTag == sortTagId
    end

    function XRoomCharFilterTipsManager.GetSort(idA, idB, characterType, isAscendOrder, inSortTag)
        if not idA or not idB then
            return false
        end
        local sortTag
        if inSortTag then
            sortTag = inSortTag
        else
            sortTag = TempSortTag or GetSortTagByCharacterType(characterType) or XRoomCharFilterTipsConfigs.EnumSortTag.Default
        end
        return SortFunction[sortTag](idA, idB, isAscendOrder)
    end

    XRoomCharFilterTipsManager.Init()
    return XRoomCharFilterTipsManager
end