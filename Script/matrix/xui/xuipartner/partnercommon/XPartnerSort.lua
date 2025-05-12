local XPartnerSort = {}
local sortDic = {}

sortDic[XPartnerConfigs.SortType.Ability] = function(a, b, IsDescend)
    if a:GetAbility() ~= b:GetAbility() then
        if IsDescend then
            return a:GetAbility() > b:GetAbility()
        else
            return a:GetAbility() < b:GetAbility()
        end
    end
    return nil
end

sortDic[XPartnerConfigs.SortType.Quality] = function(a, b, IsDescend)
    if a:GetQuality() ~= b:GetQuality() then
        if IsDescend then
            return a:GetQuality() > b:GetQuality()
        else
            return a:GetQuality() < b:GetQuality()
        end
    end
    return nil
end

sortDic[XPartnerConfigs.SortType.Breakthrough] = function(a, b, IsDescend)
    if a:GetBreakthrough() ~= b:GetBreakthrough() then
        if IsDescend then
            return a:GetBreakthrough() > b:GetBreakthrough()
        else
            return a:GetBreakthrough() < b:GetBreakthrough()
        end
    end
    return nil
end

sortDic[XPartnerConfigs.SortType.Level] = function(a, b, IsDescend)
    if a:GetLevel() ~= b:GetLevel() then
        if IsDescend then
            return a:GetLevel() > b:GetLevel()
        else
            return a:GetLevel() < b:GetLevel()
        end
    end
    return nil
end

sortDic[XPartnerConfigs.SortType.SkillLevel] = function(a, b, IsDescend)
    if a:GetTotalSkillLevel() ~= b:GetTotalSkillLevel() then
        if IsDescend then
            return a:GetTotalSkillLevel() > b:GetTotalSkillLevel()
        else
            return a:GetTotalSkillLevel() < b:GetTotalSkillLevel()
        end
    end
    return nil
end

sortDic[XPartnerConfigs.SortType.Lock] = function(a, b, IsDescend)
    if a:GetIsLock() ~= b:GetIsLock() then
        if IsDescend then
            return a:GetIsLock()
        else
            return b:GetIsLock()
        end
    end
    return nil
end

sortDic[XPartnerConfigs.SortType.Priority] = function(a, b, IsDescend)
    if a:GetPriority() ~= b:GetPriority() then
        if IsDescend then
            return a:GetPriority() > b:GetPriority()
        else
            return a:GetPriority() < b:GetPriority()
        end
    end
    return nil
end

sortDic[XPartnerConfigs.SortType.Stack] = function(a, b, IsDescend)
    if a:GetIsByOneself() ~= b:GetIsByOneself() then
        if IsDescend then
            return a:GetIsByOneself()
        else
            return b:GetIsByOneself()
        end
    end
    return nil
end

sortDic[XPartnerConfigs.SortType.CanCompose] = function(a, b, IsDescend)
    if a:GetIsCanCompose() ~= b:GetIsCanCompose() then
        if IsDescend then
            return a:GetIsCanCompose()
        else
            return b:GetIsCanCompose()
        end
    end
    return nil
end

sortDic[XPartnerConfigs.SortType.Carry] = function(a, b, IsDescend)
    if a:GetIsCarry() ~= b:GetIsCarry() then
        if IsDescend then
            return a:GetIsCarry()
        else
            return b:GetIsCarry()
        end
    end
    return nil
end

local CarrySortTypeList = {
    {Type = XPartnerConfigs.SortType.Carry, IsDescend = false},
    {Type = XPartnerConfigs.SortType.Ability, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Quality, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Breakthrough, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Level, IsDescend = true},
    {Type = XPartnerConfigs.SortType.SkillLevel, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Priority, IsDescend = true},
}

local OverviewSortTypeList = {
    {Type = XPartnerConfigs.SortType.Ability, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Quality, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Breakthrough, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Level, IsDescend = true},
    {Type = XPartnerConfigs.SortType.SkillLevel, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Lock, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Priority, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Stack, IsDescend = false},
}

local EatSortTypeList = {
    {Type = XPartnerConfigs.SortType.Quality, IsDescend = false},
    {Type = XPartnerConfigs.SortType.Breakthrough, IsDescend = false},
    {Type = XPartnerConfigs.SortType.Level, IsDescend = false},
    {Type = XPartnerConfigs.SortType.Priority, IsDescend = false},
}

local ComposeSortTypeList = {
    {Type = XPartnerConfigs.SortType.CanCompose, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Quality, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Priority, IsDescend = true},
}

local BagShowSortTypeList = {
    {Type = XPartnerConfigs.SortType.Carry, IsDescend = false},
    {Type = XPartnerConfigs.SortType.Quality, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Breakthrough, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Level, IsDescend = true},
    {Type = XPartnerConfigs.SortType.Priority, IsDescend = true},
}

function XPartnerSort.OverviewSortFunction(partnerList)
    local tmpSortList = {}
    local orderList = {}
    for _,data in pairs(OverviewSortTypeList) do
        table.insert(tmpSortList, sortDic[data.Type])
        table.insert(orderList, data.IsDescend)
    end

    table.sort(partnerList, function(a, b)
            
            for index,sort in pairs(tmpSortList) do
                if sort(a, b, orderList[index]) ~= nil then
                    return sort(a, b, orderList[index])
                end
            end
            
            return a:GetId() > b:GetId()
        end)
end

function XPartnerSort.BagShowSortFunction(partnerList, firstType, IsDescend)
    local tmpSortList = {}
    local orderList = {}
    for _,data in pairs(BagShowSortTypeList) do
        if data.Type == firstType then
            table.insert(tmpSortList, 2, sortDic[data.Type])
        else
            table.insert(tmpSortList, sortDic[data.Type])
        end
        
        local oder
        if IsDescend then
            oder = data.IsDescend
        else
            oder = not data.IsDescend
        end
        table.insert(orderList, oder)
    end

    table.sort(partnerList, function(a, b)
            for index,sort in pairs(tmpSortList) do
                if sort(a, b, orderList[index]) ~= nil then
                    return sort(a, b, orderList[index])
                end
            end
            return a:GetId() > b:GetId()
        end)
end

function XPartnerSort.ComposeSortFunction(partnerList)
    local tmpSortList = {}
    local orderList = {}
    for _,data in pairs(ComposeSortTypeList) do
        table.insert(tmpSortList, sortDic[data.Type])
        table.insert(orderList, data.IsDescend)
    end
    
    table.sort(partnerList, function(a, b)

            for index,sort in pairs(tmpSortList) do
                if sort(a, b, orderList[index]) ~= nil then
                    return sort(a, b, orderList[index])
                end
            end

            return a:GetId() > b:GetId()
        end)
end

function XPartnerSort.EatSortFunction(partnerList)
    local tmpSortList = {}
    local orderList = {}
    for _,data in pairs(EatSortTypeList) do
        table.insert(tmpSortList, sortDic[data.Type])
        table.insert(orderList, data.IsDescend)
    end

    table.sort(partnerList, function(a, b)

            for index,sort in pairs(tmpSortList) do
                if sort(a, b, orderList[index]) ~= nil then
                    return sort(a, b, orderList[index])
                end
            end

            return a:GetId() > b:GetId()
        end)
end

function XPartnerSort.CarrySortFunction(partnerList, carrierId)
    local tmpSortList = {}
    local orderList = {}
    for _,data in pairs(CarrySortTypeList) do
        table.insert(tmpSortList, sortDic[data.Type])
        table.insert(orderList, data.IsDescend)
    end

    table.sort(partnerList, function(a, b)
            if a:GetCharacterId() == carrierId or b:GetCharacterId() == carrierId then
                return a:GetCharacterId() == carrierId
            else
                for index,sort in pairs(tmpSortList) do
                    if sort(a, b, orderList[index]) ~= nil then
                        return sort(a, b, orderList[index])
                    end
                end
            end

            return a:GetId() > b:GetId()
        end)
end

function XPartnerSort.SkillSort(skillList)
    table.sort(skillList, function (a, b)
            return a:GetId() < b:GetId()
        end)
end

function XPartnerSort.CanComposeIdSort(partnerIdList)
    table.sort(partnerIdList, function (a, b)
            local cfg_A = XPartnerConfigs.GetPartnerTemplateById(a)
            local cfg_B = XPartnerConfigs.GetPartnerTemplateById(b)
            if cfg_A.InitQuality ~= cfg_B.InitQuality then
                return cfg_A.InitQuality > cfg_B.InitQuality
            else
                return cfg_A.Priority > cfg_B.Priority
            end
            
        end)
end

--==============================
 ---@desc 辅助机预设排序
 ---@partnerList 辅助机列表 
 ---@carriedPartnerDict 被携带的辅助机键值对，顺序（蓝，红，黄） 
--==============================
function XPartnerSort.PresetSort(partnerList, carriedPartnerDict)
    local tmpSortList = {}
    local orderList = {}
    for _,data in pairs(CarrySortTypeList) do
        if data.Type ~= XPartnerConfigs.SortType.Carry then
            table.insert(tmpSortList, sortDic[data.Type])
            table.insert(orderList, data.IsDescend)
        end
    end
    
    ---采用2>1>3>0的排序
    local tempDict = {
        [2] = 10000,
        [1] = 1000,
        [3] = 100,
        [0] = 1,
    }
    local compare = function(idx1, idx2) 
        return tempDict[idx1] > tempDict[idx2]
    end
    
    table.sort(partnerList, function(a, b)
        if carriedPartnerDict[a:GetId()] or carriedPartnerDict[b:GetId()] then
            local idx1 = carriedPartnerDict[a:GetId()] or 0
            local idx2 = carriedPartnerDict[b:GetId()] or 0
            return compare(idx1, idx2)
        else
            for index, sort in pairs(tmpSortList) do
                local sortResult = sort(a, b, orderList[index])
                if sortResult ~= nil then
                    return sortResult
                end
            end
        end
        return a:GetId() > b:GetId()
    end)
end


return XPartnerSort