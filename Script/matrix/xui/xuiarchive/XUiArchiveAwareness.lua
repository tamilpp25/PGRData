--
-- Author: wujie
-- Note: 图鉴意识一级界面
local XUiArchiveAwareness = XLuaUiManager.Register(XLuaUi, "UiArchiveAwareness")

local XUiGridArchiveAwareness = require("XUi/XUiArchive/XUiGridArchiveAwareness")
local Object = CS.UnityEngine.Object
local DrdSortIndexToType = {
    XEnumConst.Archive.EquipStarType.All,
    XEnumConst.Archive.EquipStarType.Two,
    XEnumConst.Archive.EquipStarType.Three,
    XEnumConst.Archive.EquipStarType.Four,
    XEnumConst.Archive.EquipStarType.Five,
    XEnumConst.Archive.EquipStarType.Six,
}

local StarTypeToStarNum = function(type)
    if type == XEnumConst.Archive.EquipStarType.All then XLog.Error("StarType.All cannot be passed in") end
    return type
end

function XUiArchiveAwareness:OnAwake()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.IsHaveCallOnEnable = false
    self:InitTabBtnGroup()
    self:InitDrdSort()
    self:InitDynamicTable()
    self:AutoAddListener()

    self.EventIdAwarenessRedPoint = self:AddRedPointEvent(
    self.TabBtnGroup,
    self.OnCheckAwarenessRedPoint,
    self,
    { XRedPointConditions.Types.CONDITION_ARCHIVE_AWARENESS_NEW_TAG, XRedPointConditions.Types.CONDITION_ARCHIVE_AWARENESS_SETTING_RED },
    nil,
    false
    )
end

function XUiArchiveAwareness:OnStart()
    self.IsStarAscendOrder = false
    self.SecondHierarchyFilterSelectIndex = self.DrdSort.value + 1
    self.AwarenessDataDic = self._Control:GetAwarenessTypeToGroupDatasDic()

    XRedPointManager.Check(self.EventIdAwarenessRedPoint)
    self:UpdateOrderStatus(self.IsStarAscendOrder)
    local btnCount = #self.GroupTypeList
    if btnCount > 0 then
        self.TabBtnGroup:SelectIndex(1)
    end
end

function XUiArchiveAwareness:OnEnable()
    if self.IsHaveCallOnEnable then
        self.DynamicTable:ReloadDataASync()
        return
    end
    self.IsHaveCallOnEnable = true
end

function XUiArchiveAwareness:OnDestroy()
    self._Control:HandleCanUnlockAwarenessSuit()
    self._Control:HandleCanUnlockAwarenessSetting()
end

function XUiArchiveAwareness:InitTabBtnGroup()
    self.GroupTypeList = XMVCA.XArchive:GetAwarenessGroupTypes()
    self.BtnTypeList = {}
    self.TabBtnTypeDic = {}
    self.BtnAwareness.gameObject:SetActiveEx(false)
    for index, v in pairs(self.GroupTypeList) do
        local btn = Object.Instantiate(self.BtnAwareness)
        btn.gameObject:SetActive(true)
        btn.transform:SetParent(self.TabBtnGroup.transform, false)
        local btncs = btn:GetComponent("XUiButton")
        local name = v.GroupName
        btncs:SetName(name or "Null")
        table.insert(self.BtnTypeList, btncs)
        self.TabBtnTypeDic[v.GroupId] = btncs
    end

    self.TabBtnGroup:Init(self.BtnTypeList, handler(self, self.OnTabBtnGroupClick))
end

function XUiArchiveAwareness:InitDrdSort()
    local StarToQualityName = self._Control:GetStarToQualityNameEnum()
    self.DrdSort:ClearOptions()
    local firstOptionType = DrdSortIndexToType[1]
    self.DrdSort.captionText.text = StarToQualityName[firstOptionType]
    local CsDropdown = CS.UnityEngine.UI.Dropdown
    for _, starType in ipairs(DrdSortIndexToType) do
        local op = CsDropdown.OptionData()
        op.text = StarToQualityName[starType]
        self.DrdSort.options:Add(op)
    end
end

function XUiArchiveAwareness:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridArchiveAwareness,self,handler(self, self.OnGridClick),self)
    self.DynamicTable:SetDelegate(self)
end

function XUiArchiveAwareness:AutoAddListener()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.DrdSort.onValueChanged:AddListener(function()
        local CSArrayIndexToLuaTableIndex = function(index) return index + 1 end
        self:OnDrdSortClick(CSArrayIndexToLuaTableIndex(self.DrdSort.value))
    end)
    self.BtnOrder.CallBack = function() self:OnBtnOrderClick() end
end

-- function XUiArchiveAwareness:OnPlayAnimation()
--     -- self:PlayAnimation("AnimStartEnable")
-- end
-- 第一层判断
function XUiArchiveAwareness:FirstHierarchyFilter(originDataList, filterType)
    return originDataList[filterType] or {}
end

-- 第二层判断
function XUiArchiveAwareness:SecondHierarchyFilter(firstHierarchyFilterDataList, filterType)
    local dataList = {}
    if filterType == XEnumConst.Archive.EquipStarType.All then
        return firstHierarchyFilterDataList
    else
        local filterStar = StarTypeToStarNum(filterType)
        for _, data in ipairs(firstHierarchyFilterDataList) do
            if XDataCenter.EquipManager.GetSuitStar(data.Id) == filterStar then
                table.insert(dataList, data)
            end
        end
    end
    return dataList
end

-- 按星级高低顺序来排序，默认降序（可变为升序），在此之下默认TemplateId排序
function XUiArchiveAwareness:SortEquipDataList(dataList, isAscendOrder)
    if not dataList then return end
    -- 需要调整
    if isAscendOrder then
        table.sort(dataList, function(aData, bData)
            local aId = aData.Id
            local bId = bData.Id

            local aStar = XDataCenter.EquipManager.GetSuitStar(aId)
            local bStar = XDataCenter.EquipManager.GetSuitStar(bId)

            if aStar == bStar then
                return aId < bId
            else
                return aStar < bStar
            end
        end)
    else
        table.sort(dataList, function(aData, bData)
            local aId = aData.Id
            local bId = bData.Id

            local aStar = XDataCenter.EquipManager.GetSuitStar(aId)
            local bStar = XDataCenter.EquipManager.GetSuitStar(bId)


            if aStar == bStar then
                return aId > bId
            else
                return aStar > bStar
            end
        end)
    end
end

function XUiArchiveAwareness:ResetDrdSort()
    local selectIndex = 1
    for index, filterType in ipairs(DrdSortIndexToType) do
        if filterType == XEnumConst.Archive.EquipStarType.All then
            selectIndex = index
            break
        end
    end
    self.DrdSort.value = selectIndex - 1
end

--排序按钮状态
function XUiArchiveAwareness:UpdateOrderStatus(isAscendOrder)
    self.ImgAscend.gameObject:SetActiveEx(isAscendOrder)
    self.ImgDescend.gameObject:SetActiveEx(not isAscendOrder)
end

--设置动态列表
function XUiArchiveAwareness:UpdateDynamicTable()
    self:PlayAnimation("QieHuan")
    self.DynamicTableDataList = self.DynamicTableDataList or {}
    local isEmpty = #self.DynamicTableDataList == 0
    self.DynamicTable:SetDataSource(self.DynamicTableDataList)
    self.DynamicTable:ReloadDataASync(isEmpty and -1 or 1)
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
end

function XUiArchiveAwareness:UpdateCollection()
    self.TxtCollectionDesc.text = self.GroupTypeList[self.FirstHierarchyFilterSelectIndex] and
    self.GroupTypeList[self.FirstHierarchyFilterSelectIndex].GroupName or ""

    local sumNum = 0
    local collectionNum = 0
    local suitId
    local awarenessIdList
    for _, groupData in ipairs(self.FirstHierarchyFilterDataList) do
        suitId = groupData.Id
        awarenessIdList = XEquipConfig.GetEquipTemplateIdsListBySuitId(suitId)
        sumNum = sumNum + #awarenessIdList
        for _, templateId in ipairs(awarenessIdList) do
            if XMVCA.XArchive:IsAwarenessGet(templateId) then
                collectionNum = collectionNum + 1
            end
        end
    end

    if sumNum == 0 then
        self.TxtCollectionRate.text = 0
        return
    end

    local percentNum = self._Control:GetPercent(collectionNum * 100 / sumNum)
    self.TxtCollectionRate.text = percentNum
end

-----------------------------------事件相关----------------------------------------->>>
function XUiArchiveAwareness:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTableDataList, index)
    end
end

function XUiArchiveAwareness:OnGridClick(suitIdList,index)
    XLuaUiManager.Open("UiArchiveAwarenessDetail", suitIdList,index)
end

-- 需注意，index不一定就是type，需要结合业务具体考虑
function XUiArchiveAwareness:OnTabBtnGroupClick(index)
    if self.FirstHierarchyFilterSelectIndex == index then return end

    if self.FirstHierarchyFilterSelectIndex then
        local oldFilterType = self.GroupTypeList[self.FirstHierarchyFilterSelectIndex] and
        self.GroupTypeList[self.FirstHierarchyFilterSelectIndex].GroupId or 0
        if oldFilterType ~= 0 then
            self._Control:HandleCanUnlockAwarenessSuitByGetType(oldFilterType)
            self._Control:HandleCanUnlockAwarenessSettingByGetType(oldFilterType)
        end
    end

    local filterType = self.GroupTypeList[index] and self.GroupTypeList[index].GroupId or 0
    if filterType ~= 0 then
        self.DynamicTableDataList = self:FirstHierarchyFilter(self.AwarenessDataDic, filterType)
        self.FirstHierarchyFilterDataList = self.DynamicTableDataList
        self.FirstHierarchyFilterSelectIndex = index

        self:UpdateCollection()

        if DrdSortIndexToType[self.SecondHierarchyFilterSelectIndex] == XEnumConst.Archive.EquipStarType.All then
            self:SortEquipDataList(self.DynamicTableDataList, self.IsStarAscendOrder)
            self:UpdateDynamicTable()
        else
            self:ResetDrdSort()
        end
    end
end

function XUiArchiveAwareness:OnDrdSortClick(index)
    if self.SecondHierarchyFilterSelectIndex == index then return end

    if self.FirstHierarchyFilterDataList then
        self.DynamicTableDataList = self:SecondHierarchyFilter(self.FirstHierarchyFilterDataList, DrdSortIndexToType[index])
    end
    self.SecondHierarchyFilterSelectIndex = index

    self:SortEquipDataList(self.DynamicTableDataList, self.IsStarAscendOrder)
    self:UpdateDynamicTable()
end

function XUiArchiveAwareness:OnBtnOrderClick()
    self.IsStarAscendOrder = not self.IsStarAscendOrder
    self:UpdateOrderStatus(self.IsStarAscendOrder)
    self:SortEquipDataList(self.DynamicTableDataList, self.IsStarAscendOrder)
    self:UpdateDynamicTable()
end

-- 有new标签时显示new标签，如果只有红点显示红点，红点和new标签同时存在则只显示new标签
function XUiArchiveAwareness:OnCheckAwarenessRedPoint()
    local btn
    local isShowTag
    for type, _ in pairs(self.AwarenessDataDic) do
        btn = self.TabBtnTypeDic[type]
        if btn then
            isShowTag = self._Control:IsHaveNewAwarenessSuitByGetType(type)
            if isShowTag then
                btn:ShowTag(true)
                btn:ShowReddot(false)
            else
                btn:ShowTag(false)
                btn:ShowReddot(self._Control:IsHaveNewAwarenessSettingByGetType(type))
            end
        end
    end
end

-----------------------------------事件相关-----------------------------------------<<<