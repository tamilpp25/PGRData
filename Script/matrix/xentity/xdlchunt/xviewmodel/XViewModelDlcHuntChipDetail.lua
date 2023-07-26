local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")
local TAB = XDlcHuntChipConfigs.UI_DETAIL_TAB
local COST_TYPE = XDlcHuntChipConfigs.COST_TYPE

---@class XViewModelDlcHuntChipDetail
local XViewModelDlcHuntChipDetail = XClass(nil, "XViewModelDlcHuntChipDetail")

function XViewModelDlcHuntChipDetail:Ctor()
    self._ChipUid = false
    self._ChipVirtual = false
    self._ChipsSelected4LevelUp = {}
    self._ChipsSelected4Breakthrough = {}

    self._Data = {
        TabIndex = TAB.DETAIL,
        IsShowTabLevelUp = false,
        IsShowTabBreakthrough = false,
        IsLockTabLevelUp = false,
        IsShowTabs = true,

        --region detail
        ChipName = "",
        ChipIcon = "",
        ChipLevel = 0,
        ChipMaxLevel = 0,
        IsMaxLevel = false,
        Star = 0,
        IconBreakthrough = 0,
        AttrTable = {},
        Model = false,
        IsChipLock = false,
        MagicDesc = {},
        IsShowUndressBtn = false,
        --endregion detail

        --region level up
        CurLevel = 0,
        --ExpBeforeUpgrade = INVALID_VALUE,
        ExpVirtual = 0,
        ExpMax = 0,
        ExpReal = 0,
        ExpSelectedChips = 0,
        IsMaxLevel = false,
        AttrTableLevelUp = {},
        --endregion level up

        --region breakthrough
        IconBeforeBreakthrough = "",
        IconAfterBreakthrough = "",
        ---@type DlcHuntAttrCompare[]
        DataCompareBreakthrough = {},
        TextBreakthroughConsumeDesc = "",
        TextBreakthroughBefore = "",
        TextBreakthroughAfter = "",
        DataCompareMagic = {},
        DataBreakthroughCost = {},
        --endregion breakthrough
    }
end

function XViewModelDlcHuntChipDetail:GetData()
    return self._Data
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipDetail:SetChip(chip)
    if XDataCenter.DlcHuntChipManager.GetChip(chip:GetUid()) then
        self._ChipUid = chip:GetUid()
    else
        self._ChipVirtual = chip
    end
    self:UpdateTab()
end

---@return XDlcHuntChip
function XViewModelDlcHuntChipDetail:GetChip()
    return self._ChipVirtual
            or XDataCenter.DlcHuntChipManager.GetChip(self._ChipUid)
end

function XViewModelDlcHuntChipDetail:UpdateByTabIndex()
    local value = self._Data.TabIndex
    if value == TAB.DETAIL then
        self:UpdateTabDetail()
        return
    end
    if value == TAB.LEVEL_UP then
        self:UpdateTabLevelUp()
        return
    end
    if value == TAB.BREAKTHROUGH then
        self:UpdateTabBreakthrough()
        return
    end
end

function XViewModelDlcHuntChipDetail:UpdateTabDetail()
    local chip = self:GetChip()
    local data = self:GetData()
    data.ChipName = chip:GetName()
    data.ChipLevel = chip:GetLevel()
    data.ChipMaxLevel = chip:GetMaxLevel()
    data.AttrTable = XUiDlcHuntUtil.GetChipAttrTable4Display(chip)
    data.ChipIcon = chip:GetIcon()
    data.IsMaxLevel = chip:IsMaxLevel()
    data.Model = chip:GetModel()
    data.Star = chip:GetStarAmount()
    data.IconBreakthrough = chip:GetIconBreakthrough()
    data.IsChipLock = chip:IsLock()
    data.IsShowUndressBtn = chip:IsInUse()

    -- 预览后2级的magic
    local virtualLevel = math.min(chip:GetBreakthroughTimes() + 2, chip:GetMaxBreakthroughTimes())
    if virtualLevel > chip:GetBreakthroughTimes() then
        local virtualChip = chip:Clone()
        virtualChip:SetBreakthroughTimes(virtualLevel)
        local virtualMagicDesc = virtualChip:GetMagicDesc()
        local magicDesc = chip:GetMagicDesc()
        for i = 1, #magicDesc do
            local magic = virtualMagicDesc[i]
            if magic then
                magic.IsActive = true
            end
        end
        data.MagicDesc = virtualMagicDesc
    else
        local magicDesc = chip:GetMagicDesc()
        for i = 1, #magicDesc do
            local magic = magicDesc[i]
            magic.IsActive = true
        end
        data.MagicDesc = magicDesc
    end
end

function XViewModelDlcHuntChipDetail:UpdateTabLevelUp()
    XUiDlcHuntUtil.PickOutInvalidChip(self._ChipsSelected4LevelUp)

    local chip = self:GetChip()
    local data = self:GetData()

    --region 预计算升级后的芯片
    local chipVirtual = chip:Clone()
    local exp = chip:GetExp()
    local expOfSelectedChip = self:GetExpOfSelectedChip()
    local expVirtual = exp + expOfSelectedChip
    local levelUpTemplates = XDlcHuntChipConfigs.GetChipLevelUpConfig(chip:GetId(), chip:GetBreakthroughTimes())
    local chipLevel = chip:GetLevel()
    local expUsed = 0
    for i = 1, #levelUpTemplates do
        local template = levelUpTemplates[i]
        if template.Level == chipLevel then
            expUsed = template.AllExp
            expVirtual = expVirtual + expUsed
            break
        end
    end
    local levelVirtual = 1
    for i = 1, #levelUpTemplates do
        local template = levelUpTemplates[i]
        if expVirtual >= template.AllExp then
            levelVirtual = template.Level
        end
    end
    local expVirtualUsed = 0
    for i = 1, #levelUpTemplates do
        local template = levelUpTemplates[i]
        if template.Level == levelVirtual then
            expVirtualUsed = template.AllExp
            break
        end
    end
    chipVirtual:SetLevel(levelVirtual)
    chipVirtual:SetExp(expVirtual - expVirtualUsed)
    --endregion 预计算升级后的芯片

    data.CurLevel = chipVirtual:GetLevel()
    data.ExpMax = chipVirtual:GetExpMaxToNextLevel()
    local expCurrent = math.min(chipVirtual:GetExp(), data.ExpMax)
    if chipVirtual:IsMaxLevel() then
        expCurrent = data.ExpMax
    end
    --if data.ExpBeforeUpgrade == INVALID_VALUE then
    --    data.ExpBeforeUpgrade = expCurrent
    --else
    --    data.ExpBeforeUpgrade = data.Exp
    --end
    data.ExpReal = chip:GetExp()
    if levelVirtual > chipLevel then
        data.ExpReal = 0
    end
    data.ExpVirtual = expCurrent
    data.ExpSelectedChips = expOfSelectedChip
    data.ChipMaxLevel = chipVirtual:GetMaxLevel()
    data.IsMaxLevel = chipVirtual:IsMaxLevel()
    data.AttrTableLevelUp = self:GetAttrTableCompare(chip, chipVirtual)
end

function XViewModelDlcHuntChipDetail:UpdateTabBreakthrough()
    local chip = self:GetChip()
    if chip:IsMaxBreakthroughTimes() then
        return false
    end
    local data = self:GetData()

    -- if breakthrough
    local chipVirtual = chip:Clone()
    chipVirtual:SetBreakthroughTimes(chip:GetBreakthroughTimes() + 1)
    chipVirtual:SetLevel(1)
    chipVirtual:SetExp(0)
    data.IconBeforeBreakthrough = chip:GetIconBreakthrough()
    data.IconAfterBreakthrough = chipVirtual:GetIconBreakthrough()
    data.DataCompareBreakthrough = {}

    --region 对比属性，突破前后
    local compareData = self:GetAttrTableLvUpCompare(chip, chipVirtual)
    -- Max Level
    table.insert(compareData, 1, {
        Name = XUiHelper.GetText("EquipBreakthroughBtnTxt2"),
        StrValueBefore = chip:GetMaxLevel(),
        ValueBefore = chip:GetMaxLevel(),
        StrValueAfter = chipVirtual:GetMaxLevel(),
        ValueAfter = chipVirtual:GetMaxLevel(),
    })
    data.DataCompareBreakthrough = compareData
    --endregion 对比属性，突破前后

    data.TextBreakthroughConsumeDesc = chip:GetTextBreakthrough()
    local breakthroughTime = chip:GetBreakthroughTimes()
    if breakthroughTime == 0 then
        data.TextBreakthroughBefore = XUiHelper.GetText("DlcHuntChipBreakthrough0", chip:GetBreakthroughTimes())
    else
        data.TextBreakthroughBefore = XUiHelper.GetText("DlcHuntChipBreakthrough", chip:GetBreakthroughTimes())
    end
    data.TextBreakthroughAfter = XUiHelper.GetText("DlcHuntChipBreakthrough", chipVirtual:GetBreakthroughTimes())
    -- 突破所需材料数量上限
    if #self._ChipsSelected4Breakthrough == 0 then
        local cost = chip:GetCostBreakthrough()
        for i = 1, #cost do
            self._ChipsSelected4Breakthrough[i] = 0
        end
    end

    --region magic 词缀
    data.DataCompareMagic = {}
    local magicDict = {}
    local magicEvent = chip:GetMagicDesc()
    local magicEventVirtual = chipVirtual:GetMagicDesc()
    for i = 1, #magicEvent do
        local magic = magicEvent[i]
        local type = magic.Type
        magicDict[type] = magic
    end
    for i = 1, #magicEventVirtual do
        local magicVirtual = magicEventVirtual[i]
        local oldMagic = magicDict[magicVirtual.Type]
        if not oldMagic then
            magicDict[magicVirtual.Type] = magicVirtual
            magicVirtual.IsNew = true
        else
            local oldValue = oldMagic.Params[1] or 0
            local value = magicVirtual.Params[1] or 0
            if value > oldValue then
                magicDict[magicVirtual.Type] = magicVirtual
                magicVirtual.IsLevelUp = true
            else
                magicDict[magicVirtual.Type] = nil
            end
        end
    end
    for type, magic in pairs(magicDict) do
        data.DataCompareMagic[#data.DataCompareMagic + 1] = magic
    end
    --endregion

    local cost = chip:GetCostBreakthrough()
    data.DataBreakthroughCost = cost
    self:ClearInvalidChip4Breakthrough()
    
    return true
end

function XViewModelDlcHuntChipDetail:SetTabIndex(value)
    self._Data.TabIndex = value
    self:UpdateByTabIndex()
end

function XViewModelDlcHuntChipDetail:GetTabIndexAfterUpdate()
    self:UpdateTab()
    local tabIndex = self._Data.TabIndex
    local tabIndexNew = TAB.None
    -- 在升级完成后，可突破，切到突破
    if tabIndex == TAB.LEVEL_UP and not self._Data.IsShowTabLevelUp and self._Data.IsShowTabBreakthrough then
        tabIndexNew = TAB.BREAKTHROUGH

        -- 在突破完成后，可升级，切到升级
    elseif tabIndex == TAB.BREAKTHROUGH and not self._Data.IsShowTabBreakthrough and self._Data.IsShowTabLevelUp and not self._Data.IsLockTabLevelUp then
        tabIndexNew = TAB.LEVEL_UP
    end
    if not self._Data.IsShowTabBreakthrough and not self._Data.IsShowTabLevelUp then
        tabIndexNew = TAB.DETAIL
    end
    if tabIndexNew == TAB.None then
        tabIndexNew = tabIndex
    end
    return tabIndexNew, tabIndex ~= tabIndexNew
end

function XViewModelDlcHuntChipDetail:UpdateTab()
    local chip = self:GetChip()
    if chip:IsVirtual() then
        self._Data.IsLockTabLevelUp = false
        self._Data.IsShowTabLevelUp = false
        self._Data.IsShowTabBreakthrough = false
        self._Data.IsShowTabs = false
        return
    end
    self._Data.IsShowTabs = true
    local isMaxLevel = chip:IsMaxLevel()
    local isMaxBreakthroughTimes = chip:IsMaxBreakthroughTimes()
    self._Data.IsLockTabLevelUp = isMaxLevel and isMaxBreakthroughTimes
    self._Data.IsShowTabLevelUp = (not self._Data.IsLockTabLevelUp) and (not isMaxLevel)
    self._Data.IsShowTabBreakthrough = isMaxLevel and not isMaxBreakthroughTimes
end

function XViewModelDlcHuntChipDetail:SetLockInverse()
    local chip = self:GetChip()
    chip:SetIsLock(not self._Data.IsChipLock)
    self._Data.IsChipLock = chip:IsLock()
    XDataCenter.DlcHuntChipManager.RequestLock(chip, chip:IsLock())
end

function XViewModelDlcHuntChipDetail:TakeOffChipFromAllGroup()
    XLuaUiManager.Open("UiDlcHuntDialog",
            CS.XTextManager.GetText("TipTitle"),
            XUiHelper.GetText("DlcHuntChipUndressFromAllGroup"),
            function()
                local chip = self:GetChip()
                XDataCenter.DlcHuntChipManager.RequestTakeOffChipFromAllGroup(chip)
            end
    )
end

---@alias DlcHuntAttrCompare {Name:string,StrValueBefore:string,StrValueAfter:string,ValueBefore:number,ValueAfter:number}
---@param chip1 XDlcHuntChip
---@param chip2 XDlcHuntChip
---@return DlcHuntAttrCompare[]
function XViewModelDlcHuntChipDetail:GetAttrTableCompare(chip1, chip2)
    local attrTableCompare = {}
    local dictAttr = {}
    local attrTable = chip1:GetAttrTable()
    local attrTableNextLevel = chip2:GetAttrTable()
    for attrId, attrValue in pairs(attrTable) do
        if XDlcHuntAttrConfigs.IsAttr(attrId) then
            if attrValue ~= 0 then
                dictAttr[attrId] = { AttrId = attrId, ValueBefore = attrValue, ValueAfter = 0 }
            end
        end
    end
    for attrId, attrValue in pairs(attrTableNextLevel) do
        if XDlcHuntAttrConfigs.IsAttr(attrId) and attrValue ~= 0 then
            if dictAttr[attrId] then
                dictAttr[attrId].ValueAfter = attrValue
            else
                dictAttr[attrId] = { AttrId = attrId, ValueBefore = 0, ValueAfter = attrValue }
            end
        end
    end
    for attrId, attrParams in pairs(dictAttr) do
        attrTableCompare[#attrTableCompare + 1] = attrParams
        attrParams.Name = XDlcHuntAttrConfigs.GetAttrName(attrId)
        attrParams.StrValueBefore = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrParams.ValueBefore)
        attrParams.StrValueAfter = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrParams.ValueAfter)
    end
    return attrTableCompare
end

---@alias DlcHuntAttrCompare {Name:string,StrValueBefore:string,StrValueAfter:string,ValueBefore:number,ValueAfter:number}
---@param chip1 XDlcHuntChip
---@param chip2 XDlcHuntChip
---@return DlcHuntAttrCompare[]
function XViewModelDlcHuntChipDetail:GetAttrTableLvUpCompare(chip1, chip2)
    local attrTableCompare = {}
    local dictAttr = {}
    local attrTable = chip1:GetAttrTableLvUp()
    local attrTableNextLevel = chip2:GetAttrTableLvUp()
    for attrId, attrValue in pairs(attrTable) do
        if XDlcHuntAttrConfigs.IsAttr(attrId) then
            if attrValue ~= 0 then
                dictAttr[attrId] = { AttrId = attrId, ValueBefore = attrValue, ValueAfter = 0 }
            end
        end
    end
    for attrId, attrValue in pairs(attrTableNextLevel) do
        if XDlcHuntAttrConfigs.IsAttr(attrId) and attrValue ~= 0 then
            if dictAttr[attrId] then
                dictAttr[attrId].ValueAfter = attrValue
            else
                dictAttr[attrId] = { AttrId = attrId, ValueBefore = 0, ValueAfter = attrValue }
            end
        end
    end
    for attrId, attrParams in pairs(dictAttr) do
        attrTableCompare[#attrTableCompare + 1] = attrParams
        attrParams.Name = XUiHelper.GetText("DlcHuntPopUpAttrPrefix", XDlcHuntAttrConfigs.GetAttrName(attrId))
        attrParams.StrValueBefore = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrParams.ValueBefore, true)
        attrParams.StrValueAfter = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrParams.ValueAfter, true)
    end

    table.sort(attrTableCompare, function(a, b)
        return XDlcHuntAttrConfigs.GetAttrPriority(a.AttrId) > XDlcHuntAttrConfigs.GetAttrPriority(b.AttrId)
    end)
    return attrTableCompare
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipDetail:SetChipSelectedInverse(chip)
    local uid = chip:GetUid()

    -- 达到满级后再选择横幅提示“已达到等级上限”
    if not self._ChipsSelected4LevelUp[uid] then
        if self._Data.IsMaxLevel then
            XUiManager.TipText("EquipLevelUpMaxLevel")
            return
        end
    end

    if self._ChipsSelected4LevelUp[uid] then
        self._ChipsSelected4LevelUp[uid] = false
    else
        self._ChipsSelected4LevelUp[uid] = true
    end
    self:UpdateTabLevelUp()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_DETAIL_SELECTED_UPDATE)
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipDetail:IsChipSelected(chip)
    return self._ChipsSelected4LevelUp[chip:GetUid()]
end

function XViewModelDlcHuntChipDetail:RequestLevelUp()
    if self:IsSelectExpensiveChip() then
        local title = CS.XTextManager.GetText("TipTitle")
        XLuaUiManager.Open("UiDialog", title, XUiHelper.GetText("DlcHuntChipExpensive"),
                XUiManager.DialogType.Normal, nil,
                function()
                    self:_RequestUpgradeChip()
                end
        )
        return
    end
    if XTool.IsTableEmpty(self._ChipsSelected4LevelUp) then
        XLog.Warning("[XViewModelDlcHuntChipDetail] select nothing")
        return
    end
    self:_RequestUpgradeChip()
end

function XViewModelDlcHuntChipDetail:_RequestUpgradeChip()
    local chips = {}
    for chipId, isSelected in pairs(self._ChipsSelected4LevelUp) do
        if isSelected then
            chips[#chips + 1] = chipId
        end
    end
    if XTool.IsTableEmpty(chips) then
        return
    end
    XDataCenter.DlcHuntChipManager.RequestUpgradeChip(self._ChipUid, chips)
end

---@return XDlcHuntChip[]
function XViewModelDlcHuntChipDetail:GetChips4LevelUp()
    local selectedChip = self:GetChip()
    ---@type XDlcHuntChip[]
    local chips = XDataCenter.DlcHuntChipManager.GetAllChip()
    local result = {}
    for uid, chip in pairs(chips) do
        if selectedChip:GetType() == chip:GetType()
                and not chip:IsLock()
                and not chip:IsInUse()
                and not chip:Equals(selectedChip)
                and not chip:HasSetAsAssistantChip2Others()
        then
            result[#result + 1] = chip
        end
    end
    local sortType = XDlcHuntChipConfigs.CHIP_FILTER_TYPE.EXP
    table.sort(result, function(a, b)
        return a:GetPriority(sortType) > b:GetPriority(sortType)
    end)

    return result
end

function XViewModelDlcHuntChipDetail:GetChipsAutoSelected4LevelUp()
    local result = {}
    local selectedChip = self:GetChip()
    local curExp = selectedChip:GetExp()
    local _, maxExpWithThisLevel = selectedChip:GetExpMaxWithThisLevel()
    local _, maxExpWithMaxLevel = selectedChip:GetExpMaxWithMaxLevel()
    local needExp = maxExpWithMaxLevel - maxExpWithThisLevel
    if needExp <= 0 then
        return result
    end
    if curExp == needExp then
        return result
    end
    local chipArray = self:GetChips4LevelUp()
    for i = 1, #chipArray do
        local chip = chipArray[i]
        local offerExp = chip:GetOfferExp()
        curExp = curExp + offerExp
        if curExp == needExp then
            result[chip:GetUid()] = chip
            break
        end
        if curExp > needExp then
            curExp = curExp - offerExp
        else
            result[chip:GetUid()] = chip
        end
    end
    if curExp < needExp then
        for i = #chipArray, 1, -1 do
            local chip = chipArray[i]
            local uid = chip:GetUid()
            if not result[uid] then
                local offerExp = chip:GetOfferExp()
                curExp = curExp + offerExp
                result[uid] = chip
                if curExp >= needExp then
                    break
                end
            end
        end
    end
    return result
end

function XViewModelDlcHuntChipDetail:AutoSelectChips4LevelUp()
    local chips = self:GetChipsAutoSelected4LevelUp()
    if XTool.IsTableEmpty(chips) then
        -- 没有选择的空间
        return
    end
    self._ChipsSelected4LevelUp = {}
    for uid, chip in pairs(chips) do
        self._ChipsSelected4LevelUp[uid] = true
    end
    self:UpdateTabLevelUp()
end

function XViewModelDlcHuntChipDetail:GetChipsAutoSelected4Breakthrough()
    local result = {}
    local hasSelected = {}
    for i = 1, #self._ChipsSelected4Breakthrough do
        --每个突破材料格，分别取材料
        local dataProvider = self:GetDataProvider4CostBreakthrough(i)
        for j = 1, #dataProvider do
            local chip = dataProvider[j]
            if not hasSelected[chip:GetUid()] then
                hasSelected[chip:GetUid()] = true
                result[#result + 1] = chip
            end
        end
    end
    return result
end

function XViewModelDlcHuntChipDetail:AutoSelectChips4Breakthrough()
    ---@type XDlcHuntChip[]
    local chips = self:GetChipsAutoSelected4Breakthrough()
    if XTool.IsTableEmpty(chips) then
        -- 没有选择的空间
        return
    end
    for i = 1, #self._ChipsSelected4Breakthrough do
        local chip = chips[i]
        if chip then
            self._ChipsSelected4Breakthrough[i] = chip:GetUid()
        else
            self._ChipsSelected4Breakthrough[i] = 0
        end
    end
end

function XViewModelDlcHuntChipDetail:GetExpOfSelectedChip()
    local chips = self._ChipsSelected4LevelUp
    local exp = 0
    for uid, isSelected in pairs(chips) do
        if isSelected then
            local chip = XDataCenter.DlcHuntChipManager.GetChip(uid)
            exp = exp + chip:GetOfferExp()
        end
    end
    return exp
end

function XViewModelDlcHuntChipDetail:IsShowLevelUpBtn()
    return XTool.IsTableEmpty(self._ChipsSelected4LevelUp)
end

--选择的材料中包含6星芯片
function XViewModelDlcHuntChipDetail:IsSelectExpensiveChip()
    for uid, isSelected in pairs(self._ChipsSelected4LevelUp) do
        if isSelected then
            local chip = XDataCenter.DlcHuntChipManager.GetChip(uid)
            if chip:GetStarAmount() >= 6 then
                return true
            end
        end
    end
    return false
end

function XViewModelDlcHuntChipDetail:GetCostBreakthrough()
    local result = {}
    for i = 1, #self._ChipsSelected4Breakthrough do
        local uid = self._ChipsSelected4Breakthrough[i]
        local chip = XDataCenter.DlcHuntChipManager.GetChip(uid)
        result[i] = {
            Chip = chip or false,
            Index = i
        }
    end
    return result
end

---@return XDlcHuntChip[]
function XViewModelDlcHuntChipDetail:GetDataProvider4CostBreakthrough(index)
    local result = {}
    local chips = XDataCenter.DlcHuntChipManager.GetAllChip()
    local selectedChip = self:GetChip()
    local costConfigArray = selectedChip:GetCostBreakthrough()
    local costConfig = costConfigArray[index]
    local breakthroughTimes = costConfig.BreakthroughTimes
    local star = costConfig.Star
    local costType = costConfig.Type
    for uid, chip in pairs(chips) do
        --[[
        1）显示同时符合以下所有规则的芯片
            显示符合ChipBreakTrough.tab中符合ConsumeParam1&ConsumeParam2&ConsumeParam3字段的芯片
            不存在于任意芯片组中的芯片
            未上锁的芯片
        ]]
        -- 条件1
        if not chip:IsInUse()
                and not chip:IsLock()
                and not chip:HasSetAsAssistantChip2Others()
                and not chip:Equals(selectedChip)
        then
            -- 条件2
            if chip:GetBreakthroughTimes() >= breakthroughTimes
                    and chip:GetStarAmount() == star then
                -- 条件3
                if costType == COST_TYPE.ALL then
                    result[#result + 1] = chip

                elseif costType == COST_TYPE.MAIN_CHIP then
                    if chip:IsMainChip() then
                        result[#result + 1] = chip
                    end
                elseif costType == COST_TYPE.SUB_CHIP then
                    if chip:IsSubChip() then
                        result[#result + 1] = chip
                    end
                elseif costType == COST_TYPE.SAME_CHIP then
                    if selectedChip:GetId() == chip:GetId()
                            and selectedChip:GetBreakthroughTimes() == chip:GetBreakthroughTimes()
                    then
                        result[#result + 1] = chip
                    end
                end
            end
        end
    end
    --[[
    2）排列优先级：
        优先显示星级较低的芯片
        次优先显示突破次数较低的芯片
        次优先显示等级较低的芯片
        次优先显示id较小的芯片
    ]]
    local sortType = XDlcHuntChipConfigs.CHIP_FILTER_TYPE.COST_BREAKTHROUGH
    table.sort(result, function(a, b)
        return a:GetPriority(sortType) > b:GetPriority(sortType)
    end)
    return result
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipDetail:SetChipSelected4CostBreakthrough(index, chip, value)
    local selected = self._ChipsSelected4Breakthrough
    if value then
        for i = 1, #selected do
            if selected[i] == chip:GetUid() then
                selected[i] = nil
            end
        end
        selected[index] = chip:GetUid()
    else
        for i = 1, #selected do
            if selected[i] == chip:GetUid() then
                selected[i] = nil
            end
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_BREAKTHROUGH_SELECT_COST_UPDATE)
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipDetail:IsChipSelected4CostBreakthrough(chip)
    local selected = self._ChipsSelected4Breakthrough
    for i = 1, #selected do
        if selected[i] == chip:GetUid() then
            return true
        end
    end
    return false
end

function XViewModelDlcHuntChipDetail:RequestBreakthrough()
    local chip = self:GetChip()
    if chip:IsMaxBreakthroughTimes() then
        return
    end
    local chips = {}
    for i = 1, #self._ChipsSelected4Breakthrough do
        local uid = self._ChipsSelected4Breakthrough[i]
        if uid and uid ~= 0 then
            chips[#chips + 1] = uid
        end
    end
    if XTool.IsTableEmpty(chips) then
        XUiManager.TipText("DlcHuntBreakthroughSelectMaterial")
        return
    end
    XDataCenter.DlcHuntChipManager.RequestBreakthrough(self._ChipUid, chips)
end

function XViewModelDlcHuntChipDetail:IsCanSelectGrid()
    return true
end

function XViewModelDlcHuntChipDetail:GetBreakthroughCostItemAmount()
    return #self._ChipsSelected4Breakthrough
end

function XViewModelDlcHuntChipDetail:SelectBreakthroughCost(index)
    local chipIdSelected = self._ChipsSelected4Breakthrough[index]
    if chipIdSelected == nil then
        XLog.Error("[XViewModelDlcHuntChipDetail] breakthrough cost index is invalid")
        return
    end
    local dataSource = self:GetDataProvider4CostBreakthrough(index)
    local callback = function(chipIdArray)
        for i = 1, #self._ChipsSelected4Breakthrough do
            self._ChipsSelected4Breakthrough[i] = chipIdArray[i]
        end
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_BREAKTHROUGH_SELECT_COST_UPDATE)
    end
    XLuaUiManager.Open("UiDlcHuntChipChoice", dataSource, self._ChipsSelected4Breakthrough, callback)
end

function XViewModelDlcHuntChipDetail:ClearInvalidChip4Breakthrough()
    for index, uid in pairs(self._ChipsSelected4Breakthrough) do
        local chip = XDataCenter.DlcHuntChipManager.GetChip(uid)
        if not chip then
            self._ChipsSelected4Breakthrough[index] = 0
        end
    end
end

return XViewModelDlcHuntChipDetail