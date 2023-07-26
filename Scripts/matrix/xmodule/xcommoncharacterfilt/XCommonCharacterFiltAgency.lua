---@class XCommonCharacterFiltAgency : XAgency
---@field _Model XCommonCharacterFiltModel
local XCommonCharacterFiltAgency = XClass(XAgency, "XCommonCharacterFiltAgency")
local XUiPanelCommonCharacterFilterV2P6 = require("XUi/XUiCommonCharacterOptimization/XUiPanelCommonCharacterFilterV2P6")
local tagMethodName = "GetCharacter"
local SortFunction = {}
local CheckSortFun = {}

CharacterSortFunType = 
{
    Default = 1,
    Level = 2,
    Quality = 3,
    Ability = 4,
    Priority = 5,
    Latest = 6, -- 刚抽出来的
    Target = 7, -- 装备目标
    InTeam = 8,
    EnoughFragment = 9,
    NotRobot = 10, -- 自机靠前
    Robot = 11, -- 机器人靠前
    Omniframe = 12, -- 泛用机体
    Uniframe = 13, -- 独域机体
    Custom1 = 55, -- 由程序员自定义追加的算法
    Custom2 = 56, -- 由程序员自定义追加的算法
    Custom3 = 57, -- 由程序员自定义追加的算法
}

---@return XCharacterAgency
local GetCharAgency = function ()
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    return ag
end

function XCommonCharacterFiltAgency:OnInit()
    self:InitSortFunction()
    self:InitCheckSortFun()
end

function XCommonCharacterFiltAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

---@return XUiPanelCommonCharacterFilterV2P6
function XCommonCharacterFiltAgency:InitFilter(parentTransform, parentUiProxy, ...)
    local path = CS.XGame.ClientConfig:GetString("UiPanelCommonCharacterFilterV2P6")
    local filterUi = parentTransform:LoadPrefab(path)
    local xPanelFilter = XUiPanelCommonCharacterFilterV2P6.New(filterUi, parentUiProxy, ...)
    self._Model.FilterGoProxyDic[filterUi.transform] = xPanelFilter
    return xPanelFilter
end

---@return XUiPanelCommonCharacterFilterV2P6
function XCommonCharacterFiltAgency:GetFilterProxyByTransfrom(transform)
    return self._Model.FilterGoProxyDic[transform]
end

function XCommonCharacterFiltAgency:GetTagNameByTagGroupId(id)
    for k, v in pairs(CharacterFilterTagTypeNum) do
        if v == id then
            return k
        end 
    end
end

---@param characterList 传入以有存在字段名为Id值为CharacterID数据组成的构造体角色顺序表list etc:{ [1] = {Id = CharacterId}，[2] = {Id = CharacterId}...}
---@param selectTagData 筛选项数据
function XCommonCharacterFiltAgency:DoFilter(charaterList, selectTagData)
    local resultList = {}
    for k, charaData in ipairs(charaterList) do
        if self:IsCharaInTag(charaData, selectTagData, "InitialQuality") --检测稀有度筛选项
        and self:IsCharaInTag(charaData, selectTagData, "Career") --检测职业筛选项
        and self:IsCharaInTag(charaData, selectTagData, "Element") --检测元素筛选项
        then  
            table.insert(resultList, charaData)
        end
    end

    return resultList
end

-- 检测筛选项是否满足条件
---@param charaData 构造体角色数据
---@param tagTypeName 筛选项名称
function XCommonCharacterFiltAgency:IsCharaInTag(charaData, selectTagData, tagTypeName)
    local tagData = selectTagData[tagTypeName] --拿到该筛选项的数据

    if not tagData or not next(tagData) then -- 如果该筛选项为空则不启用该筛选项，默认为全选该筛选项
        return true
    end

    -- tagTypeName筛选项的字段名和characterManager对应方法的字段名一样
    -- 构造体角色数据一定要通过characterManager接口去拿，不要通过XCharacter去拿，因为传进来的构造体角色可能是机器人
    for k, v in pairs(tagData) do
        local ag = GetCharAgency()
        if ag[tagMethodName..tagTypeName](ag, charaData.Id) == v then
            return true
        end
    end
    
    return false
end

-- 缓存筛选项数据（需要手动缓存和清除，因为无法区分混合筛选还是单类型构造体筛选（类型指泛用和独域））退出界面时要手动调用Clear清除
function XCommonCharacterFiltAgency:SetSelectTagData(selectTagData, keyName)
    if not keyName then return end
    self._Model.SelectTagData[keyName] = XTool.Clone(selectTagData) --缓存记录筛选项(keyName可以和构造体类型（独域、泛用）耦合，也可以自定义keyName)
end

-- 缓存筛选后的列表数据
function XCommonCharacterFiltAgency:SetSelectListData(sortList, keyName)
    if not keyName then return end
    self._Model.SelectListData[keyName] = sortList
end

function XCommonCharacterFiltAgency:GetSelectTagData(keyName)
    return XTool.Clone(self._Model.SelectTagData[keyName])
end

function XCommonCharacterFiltAgency:GetSelectListData(keyName)
    return self._Model.SelectListData[keyName]
end

function XCommonCharacterFiltAgency:ClearSelectTagData(keyName)
    if keyName then
        self._Model.SelectTagData[keyName] = nil
        self._Model.SelectListData[keyName] = nil
    else
        self._Model.SelectTagData = {}
        self._Model.SelectListData = {}
    end
end

-- 缓存排序数据（需要手动缓存和清除）,退出界面时要手动调用Clear清除
function XCommonCharacterFiltAgency:SetSortData(sortTypeName, keyName)
    if not keyName then return end
    self._Model.SortTagData[keyName] = sortTypeName --缓存记录筛选项(keyName仅和构造体类型（独域、泛用）耦合)
end

function XCommonCharacterFiltAgency:GetSortData(keyName)
    return self._Model.SortTagData[keyName]
end

function XCommonCharacterFiltAgency:ClearSortData(keyName)
    if keyName then
        self._Model.SortTagData[keyName] = nil
    else
        self._Model.SortTagData = {}
    end
end

function XCommonCharacterFiltAgency:ClearCacheData()
    self:ClearSelectTagData()
    self:ClearSortData()
end

-- 下一次调用排序不执行，返回上一次排序的结果
function XCommonCharacterFiltAgency:SetNotSortTrigger()
    self._Model.NotSortTrigger = true
end

-- 排序算法
function XCommonCharacterFiltAgency:InitSortFunction()
    local LevelSort = function(idA, idB, isAscendOrder)
        local levelA = GetCharAgency():GetCharacterLevel(idA)
        local levelB = GetCharAgency():GetCharacterLevel(idB)
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
        local qualityA = GetCharAgency():GetCharacterQuality(idA)
        local qualityB = GetCharAgency():GetCharacterQuality(idB)
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
        local abilityA = GetCharAgency():GetCharacterHaveRobotAbilityById(idA)
        local abilityB = GetCharAgency():GetCharacterHaveRobotAbilityById(idB)
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

    SortFunction[CharacterSortFunType.Default] = function(idA, idB, isAscendOrder, alreadySortTag, isSortAbility)
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
    SortFunction[CharacterSortFunType.Quality] = function(idA, idB, isAscendOrder)
        local isSort, sortResult = QualitySort(idA, idB, isAscendOrder)
        if isSort then
            return sortResult
        end
        return SortFunction[CharacterSortFunType.Default](idA, idB, isAscendOrder, CharacterSortFunType.Quality, true)
    end
    SortFunction[CharacterSortFunType.Level] = function(idA, idB, isAscendOrder)
        local isSort, sortResult = LevelSort(idA, idB, isAscendOrder)
        if isSort then
            return sortResult
        end
        return SortFunction[CharacterSortFunType.Default](idA, idB, isAscendOrder, CharacterSortFunType.Level, true)
    end
    SortFunction[CharacterSortFunType.Ability] = function(idA, idB, isAscendOrder)
        local isSort, sortResult = AbilitySort(idA, idB, isAscendOrder)
        if isSort then
            return sortResult
        end
        return SortFunction[CharacterSortFunType.Default](idA, idB, isAscendOrder, CharacterSortFunType.Ability)
    end
    SortFunction[CharacterSortFunType.Priority] = function (idA, idB, isAscendOrder)
        idA = XRobotManager.CheckIdToCharacterId(idA)
        idB = XRobotManager.CheckIdToCharacterId(idB)
        
        local aP = XCharacterConfigs.GetCharacterPriority(idA)
        local bP = XCharacterConfigs.GetCharacterPriority(idB)
        if isAscendOrder then
            return aP < bP
        end
        return aP > bP
    end
    SortFunction[CharacterSortFunType.Target] = function (idA, idB)
        local aR = XDataCenter.EquipGuideManager.IsEquipGuideCharacter(idA)
        local bR = XDataCenter.EquipGuideManager.IsEquipGuideCharacter(idB)
        if aR ~= bR then
            return aR
        end
        return false
    end
    SortFunction[CharacterSortFunType.Latest] = function (idA, idB)
        local charA = GetCharAgency():GetCharacter(idA)
        local charB = GetCharAgency():GetCharacter(idB)
        if not charA or not charB then
            return false
        end
        
        if charA.NewFlag ~= charB.NewFlag then
            return XTool.IsNumberValid(charA.NewFlag)
        end
        
        return false
    end
    SortFunction[CharacterSortFunType.EnoughFragment] = function (idA, idB)
        local bornQuality = XCharacterConfigs.GetCharMinQuality(idA)
        local characterType = XCharacterConfigs.GetCharacterType(idA)
        local curFragment = GetCharAgency():GetCharUnlockFragment(idA)
        local needFragment = XCharacterConfigs.GetComposeCount(characterType, bornQuality)
        local isAEnought = curFragment >= needFragment

        bornQuality = XCharacterConfigs.GetCharMinQuality(idB)
        characterType = XCharacterConfigs.GetCharacterType(idB)
        curFragment = GetCharAgency():GetCharUnlockFragment(idB)
        needFragment = XCharacterConfigs.GetComposeCount(characterType, bornQuality)
        local isBEnought = curFragment >= needFragment
        
        local isAFragment = GetCharAgency():CheckIsFragment(idA)
        local isBFragment = GetCharAgency():CheckIsFragment(idB)
     
        if (isAEnought and isAFragment) ~= (isBEnought and isBFragment) then
            return isAEnought and isAFragment
        end
    end
    SortFunction[CharacterSortFunType.NotRobot] = function (idA, idB)
        local isARobot = XRobotManager.CheckIsRobotId(idA)
        local isBRobot = XRobotManager.CheckIsRobotId(idB)
        if isARobot ~= isBRobot then
            return (not isARobot)
        end
    end
    SortFunction[CharacterSortFunType.Robot] = function (idA, idB)
        local isARobot = XRobotManager.CheckIsRobotId(idA)
        local isBRobot = XRobotManager.CheckIsRobotId(idB)
        if isARobot ~= isBRobot then
            return isARobot
        end
    end
    SortFunction[CharacterSortFunType.Omniframe] = function (idA, idB)
        local isAOmiframe = not GetCharAgency():GetIsIsomer(idA)
        local isBOmiframe = not GetCharAgency():GetIsIsomer(idB)
        if isAOmiframe ~= isBOmiframe then
            return isAOmiframe
        end
    end
    SortFunction[CharacterSortFunType.Uniframe] = function (idA, idB)
        local isAUni = GetCharAgency():GetIsIsomer(idA)
        local isBUni = GetCharAgency():GetIsIsomer(idB)
        if isAUni ~= isBUni then
            return isAUni
        end
    end
end

-- 检测是否启用当前算法
function XCommonCharacterFiltAgency:InitCheckSortFun()
    CheckSortFun[CharacterSortFunType.Quality] = function (idA, idB)
        local qualityA = GetCharAgency():GetCharacterQuality(idA)
        local qualityB = GetCharAgency():GetCharacterQuality(idB)
        if qualityA ~= qualityB then
            return true
        end
    end
    CheckSortFun[CharacterSortFunType.Level] = function (idA, idB)
        local levelA = GetCharAgency():GetCharacterLevel(idA)
        local levelB = GetCharAgency():GetCharacterLevel(idB)
        if levelA ~= levelB then
            return true
        end
    end
    CheckSortFun[CharacterSortFunType.Ability] = function (idA, idB)
        local abilityA = GetCharAgency():GetCharacterHaveRobotAbilityById(idA)
        local abilityB = GetCharAgency():GetCharacterHaveRobotAbilityById(idB)
        if abilityA ~= abilityB then
            return true
        end
    end
    CheckSortFun[CharacterSortFunType.Priority] = function (idA, idB)
        idA = XRobotManager.CheckIdToCharacterId(idA)
        idB = XRobotManager.CheckIdToCharacterId(idB)
        local aP = XCharacterConfigs.GetCharacterPriority(idA)
        local bP = XCharacterConfigs.GetCharacterPriority(idB)
        if aP ~= bP then
            return true
        end 
    end
    CheckSortFun[CharacterSortFunType.Target] = function (idA, idB)
        local aR = XDataCenter.EquipGuideManager.IsEquipGuideCharacter(idA)
        local bR = XDataCenter.EquipGuideManager.IsEquipGuideCharacter(idB)
        if aR or bR then
            return true
        end
    end
    CheckSortFun[CharacterSortFunType.Latest] = function (idA, idB)
        local charA = GetCharAgency():GetCharacter(idA)
        local charB = GetCharAgency():GetCharacter(idB)
        if not charA or not charB then
            return false
        end

        if XTool.IsNumberValid(charA.NewFlag) or XTool.IsNumberValid(charB.NewFlag) then
            return true
        end

        return false
    end
    CheckSortFun[CharacterSortFunType.EnoughFragment] = function (idA, idB)
        local isAFragment = GetCharAgency():CheckIsFragment(idA)
        local isBFragment = GetCharAgency():CheckIsFragment(idB)
        if not isAFragment and not isBFragment then
            return false
        end

        local bornQuality = XCharacterConfigs.GetCharMinQuality(idA)
        local characterType = XCharacterConfigs.GetCharacterType(idA)
        local curFragment = GetCharAgency():GetCharUnlockFragment(idA)
        local needFragment = XCharacterConfigs.GetComposeCount(characterType, bornQuality)
        local isAEnought = curFragment >= needFragment

        bornQuality = XCharacterConfigs.GetCharMinQuality(idB)
        characterType = XCharacterConfigs.GetCharacterType(idB)
        curFragment = GetCharAgency():GetCharUnlockFragment(idB)
        needFragment = XCharacterConfigs.GetComposeCount(characterType, bornQuality)
        local isBEnought = curFragment >= needFragment

        if (isAEnought and isAFragment) ~= (isBEnought and isBFragment) then
            return true
        end
    end
    CheckSortFun[CharacterSortFunType.NotRobot] = function (idA, idB)
        local isARobot = XRobotManager.CheckIsRobotId(idA)
        local isBRobot = XRobotManager.CheckIsRobotId(idB)
        if isARobot ~= isBRobot then
            return true
        end
    end
    CheckSortFun[CharacterSortFunType.Robot] = CheckSortFun[CharacterSortFunType.NotRobot]
    CheckSortFun[CharacterSortFunType.Omniframe] = function (idA, idB)
        local isAUni = GetCharAgency():GetIsIsomer(idA)
        local isBUni = GetCharAgency():GetIsIsomer(idB)
        if isAUni ~= isBUni then
            return true
        end
    end
    CheckSortFun[CharacterSortFunType.Uniframe] = CheckSortFun[CharacterSortFunType.Omniframe]
end

--- sortFunList 根据列表里的顺序依次使用排序算法。检查是否可启用此算法直到找到可用的
function XCommonCharacterFiltAgency:DoSortFilterV2P6(charaterList, sortFunList, isAscendOrderList, overrideSortList)
    if self._Model.NotSortTrigger and not XTool.IsTableEmpty(self._Model.LastSortResList) then
        self._Model.NotSortTrigger = nil
        return self._Model.LastSortResList
    end

    -- 初始化排序数据
    isAscendOrderList = isAscendOrderList or {}
    local overrideCheckFunList = nil
    local overrideSortFunList = nil
    if not XTool.IsTableEmpty(overrideSortList) then
        overrideCheckFunList = overrideSortList.CheckFunList
        overrideSortFunList = overrideSortList.SortFunList
    end

    local res = {}
    for i, v in ipairs(charaterList) do
        table.insert(res, v)
    end
    table.sort(res, function (dataA, dataB)
        local idA = dataA.Id
        local idB = dataB.Id

        for k, sortTagEnum in ipairs(sortFunList) do
            local checkFun = CheckSortFun[sortTagEnum]
            -- 检查是否有覆盖排序方法
            if overrideCheckFunList and overrideCheckFunList[sortTagEnum] then
                checkFun = overrideCheckFunList[sortTagEnum]
            end

            local sortFun = SortFunction[sortTagEnum]
            if overrideSortFunList and overrideSortFunList[sortTagEnum] then
                sortFun = overrideSortFunList[sortTagEnum]
            end

            local isCanCheck = checkFun and checkFun(idA, idB)
            if isCanCheck and sortFun then
                local isAscendOrder = isAscendOrderList[k]
                return sortFun(idA, idB, isAscendOrder)
            end
        end

        return idA > idB
    end)

    self._Model.LastSortResList = res
    return res
end

----------public end----------

----------private start----------


----------private end----------

return XCommonCharacterFiltAgency