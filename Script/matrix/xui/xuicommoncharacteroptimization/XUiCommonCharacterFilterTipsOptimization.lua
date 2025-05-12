local XUiCommonCharacterFilterTipsOptimization = XLuaUiManager.Register(XLuaUi, "UiCommonCharacterFilterTipsOptimization")
local XUiGridFilterTagGroup = require("XUi/XUiCommonCharacterOptimization/XUiGridFilterTagGroup")
-- 通用构造体角色筛选器界面

function XUiCommonCharacterFilterTipsOptimization:OnAwake()
    self.Grids = {}
    -- 选中的标签数据
    self.SelectTagData = 
    {
        -- [InitialQuality] = {}, -- 构造体品质，etc: A级，B级...
        -- [Career] = {},  -- 构造体职业类型，etc：先锋型，辅助型...
        -- [Element] = {}, -- 构造体能量（元素）类型，etc:物理，火，雷...
    }
    self.RadioTagId = nil
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFilter, self.OnBtnFilterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClearTag, self.OnBtnClearTagClick)
end

--- func desc
---@param characterList (必传)默认传入以有存在字段名为Id值为CharacterID数据组成的构造体角色顺序表list etc:{ [1] = {Id = CharacterId}，[2] = {Id = CharacterId}...}
---@param cacheKeyName (必传)缓存筛选项并可查找其信息的keyName
---@param filterCb (必传)筛选器确认回调
---@param filterType (选传)读取该字段对应配置表，决定当前筛选前显示的标签，不传则使用默认类型
---@param forceFilterFunction (选传)可兼容非构造体角色数据筛选，传入该参数则强制使用该函数作为筛选方法，不适用通用管理器里的方法，但仍会记录缓存
---@param groupNameList (选传)可传对应group的名称
---@param IsRadio (选传)是否单选
function XUiCommonCharacterFilterTipsOptimization:OnStart(characterList, cacheKeyName, filterCb, filterType, forceFilterFunction, groupNameList, isRadio)
    self.CharacterList = characterList
    self.CacheKeyName = cacheKeyName
    self.FilterType = filterType or CharacterFilterGroupType.Default
    self.ForceFilterFunction = forceFilterFunction
    self.FilterCb = filterCb
    self.GroupNameList = groupNameList
    self.IsRadio = isRadio or false
end

function XUiCommonCharacterFilterTipsOptimization:OnEnable()
    self:RefreshSelectSortTag()
end

function XUiCommonCharacterFilterTipsOptimization:GetIsRadio()
    return self.IsRadio
end

function XUiCommonCharacterFilterTipsOptimization:SetSelectRadioTagId(tagId)
    self.RadioTagId = tagId
end

-- 选择标签(包括取消选中)
function XUiCommonCharacterFilterTipsOptimization:OnTagClick(tagType, tagValue, isSelectTag)
    if not self.SelectTagData[tagType] then
        self.SelectTagData[tagType] = {}
    end
    if isSelectTag then --选中tag
        table.insert(self.SelectTagData[tagType], tagValue)
    else    -- 取消tag
        for k, v in pairs(self.SelectTagData[tagType]) do
            if v ==  tagValue then
                table.remove(self.SelectTagData[tagType], k)
            end
        end
    end
end

-- 生成并刷新UI筛选项状态（记录了上一次使用的筛选项状态）
function XUiCommonCharacterFilterTipsOptimization:RefreshSelectSortTag()
    local selectTagData = XDataCenter.CommonCharacterFiltManager.GetSelectTagData(self.CacheKeyName)
    if selectTagData and next(selectTagData) then -- 检测是否有上一次缓存过的筛选项信息
        self.SelectTagData = selectTagData
    end

    -- 拿到该筛选类型要显示的所有标签
    local allTags = XRoomCharFilterTipsConfigs.GetFilterTagCommonGroupTags(self.FilterType)
    -- 整理tag对应的标签组 
    local allTagGroups = XRoomCharFilterTipsConfigs.GetFilterTagGroup()
    local groupTagDic = {} -- key为CharacterFilterTagGroup.tab对应的group的Id, value = { {TagId = 标签id1, Order = 1}，{TagId = 标签id2, Order = 2} ...}
    for i, tagId in pairs(allTags) do
        local currTagGroupId = nil
        local currTagOrder = 1
        --1.找到该tag的groupId
        for groupId, v in pairs(allTagGroups) do
            local isContainInThisGroup = table.contains(v.Tags, tagId)
            if isContainInThisGroup then
                currTagGroupId = groupId
                currTagOrder = i
            end
        end
        --2.插入字典
        if not groupTagDic[currTagGroupId] then
            groupTagDic[currTagGroupId] = {}
        end
        if currTagGroupId then
            table.insert(groupTagDic[currTagGroupId], {TagId = tagId, Order = currTagOrder})
        end
    end

    -- 给每个标签组里的标签排序，按照CharacterFilterTagGroup的tag顺序排序
    local groupOrderList = {}  -- 并给标签组也排序 提前记录
    for groupId, tags in pairs(groupTagDic) do
        table.sort(tags, function (a, b)
            return a.Order < b.Order
        end)
        table.insert(groupOrderList, groupId)
    end

    table.sort(groupOrderList, function (idA, idB)
        local orderA = XRoomCharFilterTipsConfigs.GetFilterTagGroupOrder(idA)
        local orderB = XRoomCharFilterTipsConfigs.GetFilterTagGroupOrder(idB)

        return orderA < orderB
    end)
    -- 至此 groupOrderList 排序完成 记录 key = 顺序 ， value = group 标签组id
    
    -- 按照记录的标签组顺序开始生成筛选项
    for i, groupId in ipairs(groupOrderList) do
        -- 筛选组GameObject
        self.GridFilterTagGroup.gameObject:SetActiveEx(false)
        self.BtnFilterTagGrid.gameObject:SetActiveEx(false)
        local gridGroupGo = XUiHelper.Instantiate(self.GridFilterTagGroup.gameObject, self.GridFilterTagGroup.parent)
        local groupName = XRoomCharFilterTipsConfigs.GetFilterTagGroupName(groupId)
        if self.GroupNameList and self.GroupNameList[groupId] then 
            groupName = self.GroupNameList[groupId]
        end
        gridGroupGo:SetActiveEx(true)
        gridGroupGo.transform:Find("TxtFilterTitle/Text"):GetComponent("Text").text = groupName
        -- 在该筛选组生成筛选项标签
        local currTags = groupTagDic[groupId]
        for i, v in ipairs(currTags) do
            local currTagId = v.TagId
            local tagType = XDataCenter.CommonCharacterFiltManager.GetTagNameByTagGroupId(groupId)  --根据groupId获取标签类型（职业类型？元素类型？）
            local go = XUiHelper.Instantiate(self.BtnFilterTagGrid.gameObject, gridGroupGo.transform:Find("PanelTags"))

            local isSelect = self.SelectTagData[tagType] and table.contains(self.SelectTagData[tagType], XRoomCharFilterTipsConfigs.GetFilterTagValue(currTagId)) -- 是否缓存选择过
            local grid = XUiGridFilterTagGroup.New(go, self, currTagId, tagType, isSelect)
            go:SetActiveEx(true)
            table.insert(self.Grids, grid)
        end
    end
end

-- 点击筛选
function XUiCommonCharacterFilterTipsOptimization:OnBtnFilterClick()
    if self.ForceFilterFunction then  -- 若有强制使用第三方筛选方法则使用          
        self.ForceFilterFunction(self.SelectTagData)
    else    -- 否则使用默认的筛选管理器方法
        local resultFiltCharacterList = XDataCenter.CommonCharacterFiltManager.DoFilter(self.CharacterList, self.SelectTagData)
        
        if resultFiltCharacterList and next(resultFiltCharacterList) then
            -- 成功返回筛选时缓存记录筛选项
            XDataCenter.CommonCharacterFiltManager.SetSelectTagData(self.SelectTagData, self.CacheKeyName)
            XDataCenter.CommonCharacterFiltManager.SetSelectListData(resultFiltCharacterList, self.CacheKeyName)
            -- 在回调里使用返回的构造体筛选列表，etc重新刷新列表..
            if self.FilterCb then
                self.FilterCb(resultFiltCharacterList, self.RadioTagId)
            end
        else  -- 如果筛选结果为空,不处理
            XUiManager.TipText("CharacterFilterEmpty")
            return
        end
    end

    self:Close()
end

-- 清除所有选中的标签
function XUiCommonCharacterFilterTipsOptimization:OnBtnClearTagClick()
    self:ClearAllTagClick()
end

function XUiCommonCharacterFilterTipsOptimization:ClearAllTagClick(targetId)
    for _, grid in pairs(self.Grids) do
        if not targetId or grid:GetId() ~= targetId then
            grid:CancelSelect()
        end
    end
end

function XUiCommonCharacterFilterTipsOptimization:OnBtnBackClick()
    self:Close()
end

function XUiCommonCharacterFilterTipsOptimization:OnDisable()
    self.SelectTagData = {}
end

return XUiCommonCharacterFilterTipsOptimization