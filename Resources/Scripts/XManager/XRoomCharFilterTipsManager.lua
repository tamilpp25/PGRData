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
            local levelA = XDataCenter.CharacterManager.GetCharacterLevel(idA)
            local levelB = XDataCenter.CharacterManager.GetCharacterLevel(idB)
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
            local qualityA = XDataCenter.CharacterManager.GetCharacterQuality(idA)
            local qualityB = XDataCenter.CharacterManager.GetCharacterQuality(idB)
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
            local abilityA = XDataCenter.CharacterManager.GetCharacterHaveRobotAbilityById(idA)
            local abilityB = XDataCenter.CharacterManager.GetCharacterHaveRobotAbilityById(idB)
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

        SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default] = function(idA, idB, isAscendOrder, alreadySortTag, isSortAbility)
            local isSort, sortResult
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
    
            local priorityA = XCharacterConfigs.GetCharacterPriority(idA)
            local priorityB = XCharacterConfigs.GetCharacterPriority(idB)
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
            characterType = XCharacterConfigs.CharacterType.Normal
        end
        return CharacterTypeDic[characterType] and CharacterTypeDic[characterType]["SelectTag"] or {}
    end

    local function GetSortTagByCharacterType(characterType)
        if not characterType then
            characterType = XCharacterConfigs.CharacterType.Normal
        end
        return CharacterTypeDic[characterType] and CharacterTypeDic[characterType]["SortTag"]
    end

    ---
    --- ??????character??????????????????characterId
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
    --- ???????????????
    function XRoomCharFilterTipsManager.InitTemp(characterType)
        local selectTag = GetSelectTagByCharacterType(characterType)
        TempSelectTag = XTool.Clone(selectTag)
        TempSortTag = GetSortTagByCharacterType(characterType)
    end

    ---
    --- ????????????
    function XRoomCharFilterTipsManager.UseTemp(characterType)
        if not characterType then
            characterType = XCharacterConfigs.CharacterType.Normal
        end
        if not CharacterTypeDic[characterType] then
            CharacterTypeDic[characterType] = {}
        end
        CharacterTypeDic[characterType]["SelectTag"] = TempSelectTag
        CharacterTypeDic[characterType]["SortTag"] = TempSortTag
    end

    ---
    --- ????????????
    function XRoomCharFilterTipsManager.ClearTemp()
        TempSelectTag = {}
        TempSortTag = nil
    end

    ---
    --- ????????????UI?????????????????????????????????????????????????????????????????????
    function XRoomCharFilterTipsManager.Reset()
        TempSelectTag = {}
        TempSortTag = nil
        CharacterTypeDic = {}
    end

    function XRoomCharFilterTipsManager.Init()
        InitSortFunction()
    end
    ---------------------------------------------------- ???????????? ---------------------------------------------------------

    ---
    --- ??????????????????????????????????????????
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
    --- ????????????????????????????????????,?????????UI????????????
    function XRoomCharFilterTipsManager.GetSelectFilterTag()
        return TempSelectTag
    end

    -- ???????????????????????????
    function XRoomCharFilterTipsManager.IsFilterSelectTag(templateId, characterType, isUseTempSelectTag)
        local selectTag = isUseTempSelectTag and TempSelectTag or GetSelectTagByCharacterType(characterType)
        if XTool.IsTableEmpty(selectTag) then
            return true
        end
        
        local career = XCharacterConfigs.GetCharDetailCareer(templateId)
        local obtainElementList = XCharacterConfigs.GetCharDetailObtainElementList(templateId)
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
    --- ?????????????????????????????????????????????????????????
    function XRoomCharFilterTipsManager.CheckFilterTagIsSelect(groupId, filterTagId, characterType)
        local isSelect = false
        local selectTag = GetSelectTagByCharacterType(characterType)

        if (selectTag[groupId] or {})[filterTagId] then
            isSelect = true
        end

        return isSelect
    end

    ---
    --- ?????????????????????'selectTagGroupDic'??????'tagCacheDic'???'selectTagList'
    ---
    ---@param tagCacheDic table ????????????????????????????????? ??????????????????????????????????????????????????????????????????????????????
    ---@param selectTagGroupDic table ???????????????????????????,???XUiRoomCharacterFilterTips??????
    ---
    ---@param allCharList table ????????????????????????????????????????????????????????????
    ---???????????????number?????????characterId
    ---???????????????table???Entity????????????????????? GetCharacterId()?????? ??? Id ??????
    ---
    ---@param judgeCb function ???????????????????????????????????????????????????????????????
    ---@param filterRefreshCb function ????????????????????????????????????????????????
    ---@param isThereFilterDataCb function ????????????????????????????????????????????????XUiRoomCharacterFilterTips??????
    function XRoomCharFilterTipsManager.Filter(tagCacheDic, selectTagGroupDic, allCharList, judgeCb, filterRefreshCb, isThereFilterDataCb)
        local filteredData = {}
        local selectTagList = {}    -- ???????????????Id??????

        if XTool.IsTableEmpty(allCharList) then
            XLog.Error("XRoomCharFilterTipsManager.Filter?????????????????????allCharList??????")
            return
        end

        local characterType = XCharacterConfigs.GetCharacterType(GetCharacterIdByValueType(allCharList[1])) or XCharacterConfigs.CharacterType.Normal
        -- ?????????????????????
        for groupId, tagDic in pairs(selectTagGroupDic) do
            for tag, _ in pairs(tagDic) do
                if tagCacheDic[tag] == nil then
                    tagCacheDic[tag] = {}
                end

                if tagCacheDic[tag][characterType] == nil then
                    tagCacheDic[tag][characterType] = {}
                    local tagValue = XRoomCharFilterTipsConfigs.GetFilterTagValue(tag)
                    -- ??????????????????
                    for _, character in pairs(allCharList) do
                        if judgeCb(groupId, tagValue, character) then
                            -- ???????????????????????????
                            local characterId = GetCharacterIdByValueType(character)
                            tagCacheDic[tag][characterType][characterId] = character
                        end
                    end
                end
                table.insert(selectTagList, tag)
            end
        end

        -- ????????????????????????
        if next(selectTagList) == nil then
            if isThereFilterDataCb and isThereFilterDataCb(allCharList) then
                filterRefreshCb(allCharList)
                return
            end
        end

        -- ??????????????????,????????????
        for _, character in pairs(allCharList) do
            local isPass = true
            for _,tag in pairs(selectTagList) do
                local characterId = GetCharacterIdByValueType(character)
                if not tagCacheDic[tag][characterType][characterId] then
                    -- ????????????????????????????????????????????????
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


    ---------------------------------------------------- ???????????? ---------------------------------------------------------

    ---
    --- ?????????????????????????????????
    function XRoomCharFilterTipsManager.SetSelectSortTag(sortTagId)
        TempSortTag = sortTagId
    end

    ---
    --- ????????????????????????????????????????????????UI????????????
    function XRoomCharFilterTipsManager.GetSelectSortTag()
        return TempSortTag
    end

    ---
    --- ?????????????????????????????????????????????????????????
    function XRoomCharFilterTipsManager.CheckSortTagIsSelect(sortTagId, characterType)
        local sortTag = GetSortTagByCharacterType(characterType)
        return sortTag == sortTagId
    end

    function XRoomCharFilterTipsManager.GetSort(idA, idB, characterType, isAscendOrder)
        if not idA or not idB then
            return false
        end
        local sortTag = TempSortTag or GetSortTagByCharacterType(characterType) or XRoomCharFilterTipsConfigs.EnumSortTag.Default
        return SortFunction[sortTag](idA, idB, isAscendOrder)
    end

    XRoomCharFilterTipsManager.Init()
    return XRoomCharFilterTipsManager
end