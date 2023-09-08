-- v1.30 通用构造体角色过滤筛选管理器,包括筛选和排序功能(逐渐替换旧筛选器)

-- 该标签类型用于查找CharacterManager的方法，用于搜索方法和规定标签，数字序号与 CharacterFilterTagGroup 对应
CharacterFilterTagTypeNum = 
{
    InitialQuality = 5,
    Career = 1,
    Element = 2,
}

CharacterFilterGroupType = -- 该参数决定当前筛选界面使用哪些标签进行显示，对应 CharacterFilterCommonGroup.tab的id
{
    Default = 1, --默认泛用型
    Isomer = 2, --授格者专用
    Prequel = 3, --支线间章
    Fragment = 4, --资源收集角色碎片
    Draw = 5, --抽武器/辅助机筛选适配角色
}

CharacterSortTagType = 
{
    Default = 1,
    Level = 2,
    Quality = 3,
    Ability = 4,
}

XCommonCharacterFiltManagerCreator = function()
    ---@class XCommonCharacterFiltManager XCommonCharacterFiltManager
    local XCommonCharacterFiltManager = {}
    local SelectTagData = {} -- 记录缓存用
    local SelectListData = {}
    local SortTagData = {}
    local SortFunction = {}
    local tagMethodName = "GetCharacter"

    function XCommonCharacterFiltManager.Init()
        XCommonCharacterFiltManager.InitSortFunction()
    end

    function XCommonCharacterFiltManager.GetTagNameByTagGroupId(id)
        for k, v in pairs(CharacterFilterTagTypeNum) do
            if v == id then
                return k
            end 
        end
    end

    ---@param characterList 传入以有存在字段名为Id值为CharacterID数据组成的构造体角色顺序表list etc:{ [1] = {Id = CharacterId}，[2] = {Id = CharacterId}...}
    ---@param selectTagData 筛选项数据
    function XCommonCharacterFiltManager.DoFilter(charaterList, selectTagData)
        local resultList = {}
        for k, charaData in ipairs(charaterList) do
            if XCommonCharacterFiltManager.IsCharaInTag(charaData, selectTagData, "InitialQuality") --检测稀有度筛选项
            and XCommonCharacterFiltManager.IsCharaInTag(charaData, selectTagData, "Career") --检测职业筛选项
            and XCommonCharacterFiltManager.IsCharaInTag(charaData, selectTagData, "Element") --检测元素筛选项
            then  
                table.insert(resultList, charaData)
            end
        end

        return resultList
    end

    -- 检测筛选项是否满足条件
    ---@param charaData 构造体角色数据
    ---@param tagTypeName 筛选项名称
    function XCommonCharacterFiltManager.IsCharaInTag(charaData, selectTagData, tagTypeName)
        local tagData = selectTagData[tagTypeName] --拿到该筛选项的数据

        if not tagData or not next(tagData) then -- 如果该筛选项为空则不启用该筛选项，默认为全选该筛选项
            return true
        end

        -- tagTypeName筛选项的字段名和characterManager对应方法的字段名一样
        -- 构造体角色数据一定要通过characterManager接口去拿，不要通过XCharacter去拿，因为传进来的构造体角色可能是机器人
        for k, v in pairs(tagData) do
            if XDataCenter.CharacterManager[tagMethodName..tagTypeName](charaData.Id) == v then
                return true
            end
        end
        
        return false
    end

    -- 缓存筛选项数据（需要手动缓存和清除，因为无法区分混合筛选还是单类型构造体筛选（类型指泛用和独域））退出界面时要手动调用Clear清除
    function XCommonCharacterFiltManager.SetSelectTagData(selectTagData, keyName)
        if not keyName then return end
        SelectTagData[keyName] = XTool.Clone(selectTagData) --缓存记录筛选项(keyName可以和构造体类型（独域、泛用）耦合，也可以自定义keyName)
    end

    -- 缓存筛选后的列表数据
    function XCommonCharacterFiltManager.SetSelectListData(sortList, keyName)
        if not keyName then return end
        SelectListData[keyName] = sortList
    end

    function XCommonCharacterFiltManager.GetSelectTagData(keyName)
        return XTool.Clone(SelectTagData[keyName])
    end

    function XCommonCharacterFiltManager.GetSelectListData(keyName)
        return SelectListData[keyName]
    end
    
    function XCommonCharacterFiltManager.ClearSelectTagData(keyName)
        if keyName then
            SelectTagData[keyName] = nil
            SelectListData[keyName] = nil
        else
            SelectTagData = {}
            SelectListData = {}
        end
    end

    -- 缓存排序数据（需要手动缓存和清除）,退出界面时要手动调用Clear清除
    function XCommonCharacterFiltManager.SetSortData(sortTypeName, keyName)
        if not keyName then return end
        SortTagData[keyName] = sortTypeName --缓存记录筛选项(keyName仅和构造体类型（独域、泛用）耦合)
    end

    function XCommonCharacterFiltManager.GetSortData(keyName)
        return SortTagData[keyName]
    end

    function XCommonCharacterFiltManager.ClearSortData(keyName)
        if keyName then
            SortTagData[keyName] = nil
        else
            SortTagData = {}
        end
    end

    function XCommonCharacterFiltManager.ClearCacheData()
        XCommonCharacterFiltManager.ClearSelectTagData()
        XCommonCharacterFiltManager.ClearSortData()
    end

    function XCommonCharacterFiltManager.InitSortFunction()
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

        SortFunction[CharacterSortTagType.Default] = function(idA, idB, isAscendOrder, alreadySortTag, isSortAbility)
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
        SortFunction[CharacterSortTagType.Quality] = function(idA, idB, isAscendOrder)
            local isSort, sortResult = QualitySort(idA, idB, isAscendOrder)
            if isSort then
                return sortResult
            end
            return SortFunction[CharacterSortTagType.Default](idA, idB, isAscendOrder, CharacterSortTagType.Quality, true)
        end
        SortFunction[CharacterSortTagType.Level] = function(idA, idB, isAscendOrder)
            local isSort, sortResult = LevelSort(idA, idB, isAscendOrder)
            if isSort then
                return sortResult
            end
            return SortFunction[CharacterSortTagType.Default](idA, idB, isAscendOrder, CharacterSortTagType.Level, true)
        end
        SortFunction[CharacterSortTagType.Ability] = function(idA, idB, isAscendOrder)
            local isSort, sortResult = AbilitySort(idA, idB, isAscendOrder)
            if isSort then
                return sortResult
            end
            return SortFunction[CharacterSortTagType.Default](idA, idB, isAscendOrder, CharacterSortTagType.Ability)
        end
    end

    -- 排序
    ---@param characterList 传入以有存在字段名为Id值为CharacterID数据组成的构造体角色顺序表list etc:{ [1] = {Id = CharacterId}，[2] = {Id = CharacterId}...}
    ---@param sortTypeName 排序标签
    ---@param isAscendOrder 是否升序
    function XCommonCharacterFiltManager.DoSort(charaterList, sortTypeName, isAscendOrder)
        if not sortTypeName then
            sortTypeName = CharacterSortTagType.Default
        end
        
        -- 该排序兼容角色碎片
        -- 以下列表按顺序最后合并
        local targetCharacterInTeam = {} --目标角色在队伍(有蓝色圆形标签的角色,目前只有成员界面会有这种角色，且仅有一个)
        local inTeamList = {} -- 在队伍的角色
        local canUnlockFragmentList = {} -- 可解锁的碎片
        local targetCharacterNotInTeam = {} --目标角色不在队伍
        local nmOwnCharaList = {} -- 不在队伍的拥有角色/机器人角色
        local normalFragmentList = {} -- 不可解锁的碎片
        for k, v in ipairs(charaterList) do
            if (not XDataCenter.CharacterManager.GetCharacter(v.Id)) and (not XRobotManager.CheckIsRobotId(v.Id)) then -- 分开碎片和角色
                local curFragmentA = XDataCenter.CharacterManager.GetCharUnlockFragment(v.Id)
                local bornQualityA = XMVCA.XCharacter:GetCharMinQuality(v.Id)
                local characterTypeA = XMVCA.XCharacter:GetCharacterType(v.Id)
                local needFragmentA = XCharacterConfigs.GetComposeCount(characterTypeA, bornQualityA)
                local isCanUnlockA = curFragmentA >= needFragmentA -- 是否可解锁碎片

                if isCanUnlockA then
                    table.insert(canUnlockFragmentList, v)
                else
                    table.insert(normalFragmentList, v)
                end
            else
                if XDataCenter.TeamManager.CheckInTeam(v.Id) then
                    if XDataCenter.EquipGuideManager.IsEquipGuideCharacter(v.Id) then
                        table.insert(targetCharacterInTeam, v)
                    else
                        table.insert(inTeamList, v)
                    end
                else
                    if XDataCenter.EquipGuideManager.IsEquipGuideCharacter(v.Id) then
                        table.insert(targetCharacterNotInTeam, v)
                    else
                        table.insert(nmOwnCharaList, v)
                    end

                end
            end
        end

        -- 需要使用标签排序功能的仅为 【不在队伍的拥有角色/机器人角色】和【不可解锁的碎片】
        table.sort(nmOwnCharaList, function (dataA, dataB)
            local idA, idB = dataA.Id, dataB.Id
            return SortFunction[sortTypeName](idA, idB, isAscendOrder)
        end)

        table.sort(normalFragmentList, function (dataA, dataB)
            local idA, idB = dataA.Id, dataB.Id
            return SortFunction[sortTypeName](idA, idB, isAscendOrder)
        end)

        local resultList = {}

        resultList = appendArray(targetCharacterInTeam, inTeamList)
        resultList = appendArray(resultList, canUnlockFragmentList)
        resultList = appendArray(resultList, targetCharacterNotInTeam)
        resultList = appendArray(resultList, nmOwnCharaList)
        resultList = appendArray(resultList, normalFragmentList)

        return resultList
    end

    XCommonCharacterFiltManager.Init()
    return XCommonCharacterFiltManager
end