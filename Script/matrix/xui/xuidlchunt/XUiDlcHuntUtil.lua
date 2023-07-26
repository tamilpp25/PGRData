local CHIP_FILTER_ORDER = XDlcHuntChipConfigs.CHIP_FILTER_ORDER
local ATTR_TYPE_STR = XDlcHuntAttrConfigs.ATTR_TYPE_STR

local XUiDlcHuntUtil = {}

function XUiDlcHuntUtil.UpdateUiElement(ui, character)
    local elementList = character:GetElementIconList()
    ui.RImgCharElement1.gameObject:SetActiveEx(elementList[1] and true or false)
    ui.RImgCharElement1:SetRawImage(elementList[1])
    ui.RImgCharElement2.gameObject:SetActiveEx(elementList[2] and true or false)
    ui.RImgCharElement2:SetRawImage(elementList[2])
end

local function SortAttr(a, b)
    return a.Priority > b.Priority
end

function XUiDlcHuntUtil.SortAttr(attrTable)
    table.sort(attrTable, SortAttr)
end

function XUiDlcHuntUtil.GetSumAttrTable(...)
    local result = {}
    local attrTables = { ... }
    for i = 1, #attrTables do
        local attrTable = attrTables[i]
        for attrId, attrValue in pairs(attrTable) do
            result[attrId] = (result[attrId] or 0) + (attrValue or 0)
        end
    end
    return result
end

function XUiDlcHuntUtil.GetAttrTable4Display(attrTable)
    local result = {}
    -- 固定显示部分属性
    if not attrTable[ATTR_TYPE_STR.Attack] then
        attrTable[ATTR_TYPE_STR.Attack] = 0
    end
    if not attrTable[ATTR_TYPE_STR.Defense] then
        attrTable[ATTR_TYPE_STR.Defense] = 0
    end
    if not attrTable[ATTR_TYPE_STR.Life] then
        attrTable[ATTR_TYPE_STR.Life] = 0
    end
    for attrId, attrValue in pairs(attrTable) do
        if XDlcHuntAttrConfigs.IsAttr(attrId) then
            if attrValue ~= 0
                    -- 固定显示部分属性
                    or attrId == ATTR_TYPE_STR.Attack
                    or attrId == ATTR_TYPE_STR.Defense
                    or attrId == ATTR_TYPE_STR.Life
            then
                local attrName = XDlcHuntAttrConfigs.GetAttrName(attrId)
                local strAttrValue = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrValue)
                local priority = XDlcHuntAttrConfigs.GetAttrPriority(attrId)
                local attrNameEn = XDlcHuntAttrConfigs.GetAttrNameEn(attrId)
                result[#result + 1] = { 
                    Name = attrName, 
                    Value = strAttrValue, 
                    Priority = priority,
                    NameEn = attrNameEn,
                }
            end
        end
    end
    table.sort(result, SortAttr)
    return result
end

function XUiDlcHuntUtil.GetAttrTableMerge4Display(attrTable1, attrTable2)
    local result = {}
    local dict = {}
    for attrId, attrValue in pairs(attrTable1) do
        if XDlcHuntAttrConfigs.IsAttr(attrId) and attrValue ~= 0 then
            local attrName = XDlcHuntAttrConfigs.GetAttrName(attrId)
            local priority = XDlcHuntAttrConfigs.GetAttrPriority(attrId)
            local nameEn = XDlcHuntAttrConfigs.GetAttrNameEn(attrId)
            dict[attrId] = {
                Name = attrName,
                Value = attrValue,
                Value1 = attrValue,
                Priority = priority,
                NameEn = nameEn,
            }
        end
    end
    for attrId, attrValue in pairs(attrTable2) do
        if XDlcHuntAttrConfigs.IsAttr(attrId) and attrValue ~= 0 then
            local attrData = dict[attrId]
            if not attrData then
                local attrName = XDlcHuntAttrConfigs.GetAttrName(attrId)
                local priority = XDlcHuntAttrConfigs.GetAttrPriority(attrId)
                local nameEn = XDlcHuntAttrConfigs.GetAttrNameEn(attrId)
                attrData = {
                    Name = attrName,
                    Value = 0,
                    Priority = priority,
                    NameEn = nameEn,
                }
                dict[attrId] = attrData
            end
            attrData.Value1 = attrData.Value
            attrData.Value2 = attrValue
            attrData.Value = attrData.Value + attrValue
        end
    end
    for attrId, attrData in pairs(dict) do
        result[#result + 1] = attrData
        attrData.Value1 = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrData.Value1 or 0)
        attrData.Value2 = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrData.Value2 or 0)
        attrData.Value = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrData.Value or 0)
    end
    table.sort(result, SortAttr)
    return result
end

---@param chip XDlcHuntChip
function XUiDlcHuntUtil.SetIconByChip(object, chip)
    -- name
    local txtName = object.Name
    txtName.text = chip:GetName()

    -- star
    local starAmount = chip:GetStarAmount()
    for i = 1, XDlcHuntChipConfigs.CHIP_STAR_AMOUNT do
        if object["ImgGirdStar" .. i] then
            if i <= starAmount then
                object["ImgGirdStar" .. i].transform.parent.gameObject:SetActiveEx(true)
            else
                object["ImgGirdStar" .. i].transform.parent.gameObject:SetActiveEx(false)
            end
        end
    end

    -- level
    local txtLevel = object.Level
    txtLevel.text = chip:GetLevel()

    -- icon
    local imageIcon = object.Image
    imageIcon:SetRawImage(chip:GetIcon())
end

---@return XDlcHuntChip[]
function XUiDlcHuntUtil.GetSortedChip(chips, filterType, orderType)
    local result = {}
    for uid, chip in pairs(chips) do
        result[#result + 1] = chip
    end
    table.sort(result, function(chipA, chipB)
        local priorityA = chipA:GetPriority(filterType)
        local priorityB = chipB:GetPriority(filterType)
        if orderType == CHIP_FILTER_ORDER.ASC then
            return priorityA > priorityB
        else
            return priorityA < priorityB
        end
    end)
    return result
end

local function AppendAttrArray(attrTable, attrId, attrValue)
    attrTable[#attrTable + 1] = {
        AttrId = attrId,
        Name = XDlcHuntAttrConfigs.GetAttrName(attrId),
        Value = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrValue),
        NameEn = XDlcHuntAttrConfigs.GetAttrNameEn(attrId),
    }
end

---@param chip XDlcHuntChip
function XUiDlcHuntUtil.GetChipAttrTable4Display(chip)
    local attrs = {}
    local attrTable = chip:GetAttrTable()
    if attrTable then
        -- 固定显示部分属性
        if attrTable[ATTR_TYPE_STR.Attack] > 0 and attrTable[ATTR_TYPE_STR.Defense] > 0 then
            AppendAttrArray(attrs, ATTR_TYPE_STR.Attack, attrTable.Attack)
            AppendAttrArray(attrs, ATTR_TYPE_STR.Defense, attrTable.Defense)

        elseif attrTable[ATTR_TYPE_STR.Attack] > 0 and attrTable[ATTR_TYPE_STR.Life] > 0 then
            AppendAttrArray(attrs, ATTR_TYPE_STR.Attack, attrTable.Attack)
            AppendAttrArray(attrs, ATTR_TYPE_STR.Life, attrTable.Life)

            -- 显示所有属性
            --else
            --for attrId, attrValue in pairs(attrTable) do
            --    if XDlcHuntAttrConfigs.IsAttr(attrId) then
            --        if attrValue ~= 0 then
            --            attrs[#attrs + 1] = { AttrId = attrId, Name = XDlcHuntAttrConfigs.GetAttrName(attrId), Value = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrValue) }
            --        end
            --    end
            --end
        end
    end
    return attrs
end

function XUiDlcHuntUtil.UpdateDynamicItem(gridArray, dataArray, uiObject, class, amount)
    amount = amount or math.huge
    if #dataArray > amount then
        XLog.Error("[XUiDlcHuntUtil] too much attr type, the Excess will not show:", dataArray)
    end
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, math.min(amount, #dataArray) do
        local grid = gridArray[i]
        if not grid then
            local uiObject = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = class.New(uiObject)
            gridArray[i] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Update(dataArray[i], i)
    end
    for i = #dataArray + 1, #gridArray do
        local grid = gridArray[i]
        grid.GameObject:SetActiveEx(false)
    end
end

function XUiDlcHuntUtil.PickOutInvalidChip(table)
    for uid, isHasSelected in pairs(table) do
        local chip = XDataCenter.DlcHuntChipManager.GetChip(uid)
        if not chip then
            table[uid] = nil
        end
    end
end

function XUiDlcHuntUtil.SelectCharacterAttr(attrTable)
    local result = {}
    local list = XDlcHuntConfigs.GetCharacterAttrOnUi()
    for i = 1, #list do
        local attrId = list[i]
        local value = attrTable[attrId]
        result[attrId] = value
    end
    return result
end

function XUiDlcHuntUtil.SetTextIndex(uiText, index)
    if not index then
        return
    end
    local color = string.match(uiText.text, "<color=#%w*>")
    local str = ""
    if index < 10 then
        str = str .. string.format("%s%s</color>", color, "0")
        str = str .. index
    else
        str = index
    end
    uiText.text = str
end

return XUiDlcHuntUtil