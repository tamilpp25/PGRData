--
-- Author: wujie
-- Note: 图鉴武器一级界面

local XUiArchiveWeapon = XLuaUiManager.Register(XLuaUi, "UiArchiveWeapon")
local XUiGridArchiveWeapon = require("XUi/XUiArchive/XUiGridArchiveWeapon")
local Object = CS.UnityEngine.Object

local OwnStatusType = {
    All = 1,
    Owned = 2,
    NotOwned = 3,
}

local DrdSortIndexToType = {
    OwnStatusType.All,
    OwnStatusType.Owned,
    OwnStatusType.NotOwned,
}

local MinIndex = 1

function XUiArchiveWeapon:OnAwake()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.IsHaveCallOnEnable = false

    self.EventIdWeaponRedPoint = self:AddRedPointEvent(
        self.TabBtnGroup,
        self.OnCheckWeaponRedPoint,
        self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_WEAPON_NEW_TAG, XRedPointConditions.Types.CONDITION_ARCHIVE_WEAPON_SETTING_RED },
        nil,
        false
    )
end

function XUiArchiveWeapon:OnStart()
    self.IsStarAscendOrder = false

    self.SecondHierarchyFilterSelectIndex = self.DrdSort.value + 1
    self.WeaponDataDic = self._Control:GetWeaponTypeToIdsDic()

    self:InitDynamicTable()
    self:InitTabBtnGroup()
    self:AutoAddListener()

    XRedPointManager.Check(self.EventIdWeaponRedPoint)

    self:UpdateOrderStatus(self.IsStarAscendOrder)
end

function XUiArchiveWeapon:OnEnable()
    if self.IsHaveCallOnEnable then
        self.DynamicTable:ReloadDataASync()
        return
    end
    self.IsHaveCallOnEnable = true
end

function XUiArchiveWeapon:OnDestroy()
    self._Control:HandleCanUnlockWeapon()
    self._Control:HandleCanUnlockWeaponSetting()
end

function XUiArchiveWeapon:InitTabBtnGroup()
    self.TabBtnList = {}
    self.BtnGroupTypeList = XMVCA.XArchive:GetShowedWeaponTypeList()
    for _, v in pairs(self.BtnGroupTypeList) do
        local btn = Object.Instantiate(self.BtnTog)
        btn.gameObject:SetActive(true)
        btn.transform:SetParent(self.TabBtnGroup.transform, false)
        local btncs = btn:GetComponent("XUiButton")
        local name = XMVCA.XArchive:GetWeaponGroupName(v)
        btncs:SetName(name or "")
        table.insert(self.TabBtnList, btncs)
    end
    self.TabBtnGroup:Init(self.TabBtnList, handler(self, self.OnTabBtnGroupClick))

    self.TabBtnTypeDic = {}
    local weaponType
    for i, btn in ipairs(self.TabBtnList) do
        weaponType = self.BtnGroupTypeList[i]
        self.TabBtnTypeDic[weaponType] = btn
    end

    self.TabBtnGroup:SelectIndex(1)
    self:SaveCollectionDefaultData()
end

function XUiArchiveWeapon:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridArchiveWeapon,self,handler(self, self.OnGridClick),self)
    self.DynamicTable:SetDelegate(self)
end

function XUiArchiveWeapon:AutoAddListener()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end

    self.DrdSort.onValueChanged:AddListener(function()
            local CSArrayIndexToLuaTableIndex = function(index) return index + 1 end
            self:OnDrdSortClick(CSArrayIndexToLuaTableIndex(self.DrdSort.value))
        end)

    self.BtnOrder.CallBack = function() self:OnBtnOrderClick() end
end

-- function XUiArchiveWeapon:OnPlayAnimation()
--     -- self:PlayAnimation("AnimStartEnable")
-- end
-- 第一层判断
function XUiArchiveWeapon:FirstHierarchyFilter(originDataList, filterType)
    return originDataList[filterType] or {}
end

-- 第二层判断
function XUiArchiveWeapon:SecondHierarchyFilter(firstHierarchyFilterDataList, filterType)
    local dataList = {}
    if filterType == OwnStatusType.All then
        return firstHierarchyFilterDataList
    elseif filterType == OwnStatusType.Owned then
        for _, templateId in ipairs(firstHierarchyFilterDataList) do
            if XMVCA.XArchive:IsWeaponGet(templateId) then
                table.insert(dataList, templateId)
            end
        end
    elseif filterType == OwnStatusType.NotOwned then
        for _, templateId in ipairs(firstHierarchyFilterDataList) do
            if not XMVCA.XArchive:IsWeaponGet(templateId) then
                table.insert(dataList, templateId)
            end
        end
    end

    return dataList
end

-- 按星级高低顺序来排序，默认降序（可变为升序），在此之下默认TemplateId排序
function XUiArchiveWeapon:SortEquipDataList(dataList, isAscendOrder)
    if not dataList then return end
    if isAscendOrder then
        table.sort(dataList, function(aId, bId)
                local aTemplateData = XEquipConfig.GetEquipCfg(aId)
                local bTemplateData = XEquipConfig.GetEquipCfg(bId)

                local aPriority = aTemplateData.Priority
                local bPriority = bTemplateData.Priority

                local aStar = aTemplateData.Star
                local bStar = bTemplateData.Star

                if aStar == bStar then
                    return aPriority < bPriority
                else
                    return aStar < bStar
                end
            end)
    else
        table.sort(dataList, function(aId, bId)
                local aTemplateData = XEquipConfig.GetEquipCfg(aId)
                local bTemplateData = XEquipConfig.GetEquipCfg(bId)

                local aPriority = aTemplateData.Priority
                local bPriority = bTemplateData.Priority

                local aStar = aTemplateData.Star
                local bStar = bTemplateData.Star

                if aStar == bStar then
                    return aPriority > bPriority
                else
                    return aStar > bStar
                end
            end)
    end
end

function XUiArchiveWeapon:ResetDrdSort()
    local selectIndex = 1
    for index, filterType in ipairs(DrdSortIndexToType) do
        if filterType == OwnStatusType.All then
            selectIndex = index
            break
        end
    end
    self.DrdSort.value = selectIndex - 1
end

--排序按钮状态
function XUiArchiveWeapon:UpdateOrderStatus(isAscendOrder)
    self.ImgAscend.gameObject:SetActiveEx(isAscendOrder)
    self.ImgDescend.gameObject:SetActiveEx(not isAscendOrder)
end

--设置动态列表
function XUiArchiveWeapon:UpdateDynamicTable()
    self:PlayAnimation("QieHuan")
    self.DynamicTableDataList = self.DynamicTableDataList or {}
    local isEmpty = #self.DynamicTableDataList == 0
    self.DynamicTable:SetDataSource(self.DynamicTableDataList)
    self.DynamicTable:ReloadDataASync(isEmpty and -1 or 1)
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
end

function XUiArchiveWeapon:UpdateCollection()
    local selectEquipType = self.BtnGroupTypeList[self.FirstHierarchyFilterSelectIndex]
    self.TxtCollectionDesc.text = XMVCA.XArchive:GetWeaponGroupName(selectEquipType)

    local sumNum = #self.FirstHierarchyFilterDataList
    if sumNum == 0 then
        self.TxtCollectionRate.text = 0
        return
    end

    local collectionNum = 0
    for _, templateId in ipairs(self.FirstHierarchyFilterDataList) do
        if XMVCA.XArchive:IsWeaponGet(templateId) then
            collectionNum = collectionNum + 1
        end
    end
    local percentNum = self._Control:GetPercent(collectionNum * 100 / sumNum)
    self.TxtCollectionRate.text = percentNum
end

function XUiArchiveWeapon:UpdateAchievement()
    local selectEquipType = self.BtnGroupTypeList[self.FirstHierarchyFilterSelectIndex]
    local groupData = XMVCA.XArchive:GetWeaponGroupByType(selectEquipType)
    local needCollectNumList = groupData.CollectNum
    local achievementNum = needCollectNumList and #needCollectNumList or 0

    local haveCollectNum = 0
    for _, templateId in ipairs(self.FirstHierarchyFilterDataList) do
        if XMVCA.XArchive:IsWeaponGet(templateId) then
            haveCollectNum = haveCollectNum + 1
        end
    end

    local nextAchievementIndex = 0
    local needCollectNum = 0
    for i = 1, achievementNum do
        needCollectNum = needCollectNumList[i]
        if haveCollectNum < needCollectNum then
            break
        end
        nextAchievementIndex = i
    end
    self:CheckLevelUp(selectEquipType,nextAchievementIndex,groupData)

    self.LockedAchievement.gameObject:SetActiveEx(achievementNum ~= 0 and nextAchievementIndex == 0)
    nextAchievementIndex = math.max(MinIndex, nextAchievementIndex)

    local content = groupData.CollectionContent[nextAchievementIndex]
    self.TxtAchievementName.text = content or self.TxtAchievementName.text

    local iconPath = groupData.IconPath[nextAchievementIndex]
    if iconPath then
        self.RImgAchievementIcon:SetRawImage(iconPath)
        self.RImgAchievementIcon.gameObject:SetActiveEx(true)
    else
        self.RImgAchievementIcon.gameObject:SetActiveEx(false)
    end

    haveCollectNum = math.min(haveCollectNum, needCollectNum)
    self.TxtHaveCollectNum.text = haveCollectNum
    self.TxtNeedCollectNum.text = needCollectNum

    local IsCountShow = haveCollectNum ~= needCollectNum
    self.TxtHaveCollectNum.gameObject:SetActiveEx(IsCountShow)

end

function XUiArchiveWeapon:SaveCollectionDefaultData()
    for _,type in pairs(self.BtnGroupTypeList) do
        local groupData = XMVCA.XArchive:GetWeaponGroupByType(type)
        local needCollectNumList = groupData.CollectNum
        local achievementNum = needCollectNumList and #needCollectNumList or 0

        local haveCollectNum = 0
        local dataList = self:FirstHierarchyFilter(self.WeaponDataDic, type)
        for _, templateId in ipairs(dataList) do
            if XMVCA.XArchive:IsWeaponGet(templateId) then
                haveCollectNum = haveCollectNum + 1
            end
        end

        local nextAchievementIndex = 0
        local needCollectNum
        for i = 1, achievementNum do
            needCollectNum = needCollectNumList[i]
            if haveCollectNum < needCollectNum then
                break
            end
            nextAchievementIndex = i
        end
        self._Control:SaveWeaponsCollectionDefaultData(type,nextAchievementIndex)
    end
end

function XUiArchiveWeapon:CheckLevelUp(selectEquipType,level,groupData)
    local IsLevel,OldLevel = self._Control:CheckWeaponsCollectionLevelUp(selectEquipType,level)
    if IsLevel then
        local firstIndex = 1
        local levelData = {}
        levelData.Level = OldLevel
        levelData.OldIcon = groupData.IconPath[OldLevel] or groupData.IconPath[firstIndex]
        levelData.CurIcon = groupData.IconPath[level]
        levelData.OldText = groupData.CollectionTitle[OldLevel] or groupData.IconPath[firstIndex]
        levelData.CurText = groupData.CollectionTitle[level]
        XLuaUiManager.Open("UiArchiveWeaponsCollectionTips", levelData)
    end
end

-----------------------------------事件相关----------------------------------------->>>
function XUiArchiveWeapon:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTableDataList,index)
    end
end

function XUiArchiveWeapon:OnGridClick(templateIdList,index)
    XLuaUiManager.Open("UiArchiveWeaponDetail", templateIdList,index)
end

function XUiArchiveWeapon:OnTabBtnGroupClick(index)
    if self.FirstHierarchyFilterSelectIndex == index then return end

    if self.FirstHierarchyFilterSelectIndex then
        local oldFilterType = self.BtnGroupTypeList[self.FirstHierarchyFilterSelectIndex]
        self._Control:HandleCanUnlockWeaponByWeaponType(oldFilterType)
        self._Control:HandleCanUnlockWeaponSettingByWeaponType(oldFilterType)
    end

    local filterType = self.BtnGroupTypeList[index]
    self.DynamicTableDataList = self:FirstHierarchyFilter(self.WeaponDataDic, filterType)
    self.FirstHierarchyFilterDataList = self.DynamicTableDataList
    self.FirstHierarchyFilterSelectIndex = index

    self:UpdateCollection()
    self:UpdateAchievement()

    if DrdSortIndexToType[self.SecondHierarchyFilterSelectIndex] == OwnStatusType.All then
        self:SortEquipDataList(self.DynamicTableDataList, self.IsStarAscendOrder)
        self:UpdateDynamicTable()
    else
        self:ResetDrdSort()
    end
end

function XUiArchiveWeapon:OnDrdSortClick(index)
    if self.SecondHierarchyFilterSelectIndex == index then return end

    if self.FirstHierarchyFilterDataList then
        self.DynamicTableDataList = self:SecondHierarchyFilter(self.FirstHierarchyFilterDataList, DrdSortIndexToType[index])
    end
    self.SecondHierarchyFilterSelectIndex = index

    self:SortEquipDataList(self.DynamicTableDataList, self.IsStarAscendOrder)
    self:UpdateDynamicTable()
end

function XUiArchiveWeapon:OnBtnOrderClick()
    self.IsStarAscendOrder = not self.IsStarAscendOrder
    self:UpdateOrderStatus(self.IsStarAscendOrder)
    self:SortEquipDataList(self.DynamicTableDataList, self.IsStarAscendOrder)
    self:UpdateDynamicTable()
end

-- 有new标签时显示new标签，如果只有红点显示红点，红点和new标签同时存在则只显示new标签
function XUiArchiveWeapon:OnCheckWeaponRedPoint()
    local btn
    local isShowTag
    for type, _ in pairs(self.WeaponDataDic) do
        btn = self.TabBtnTypeDic[type]
        if btn then
            isShowTag = self._Control:IsHaveNewWeaponByWeaponType(type)
            if isShowTag then
                btn:ShowTag(true)
                btn:ShowReddot(false)
            else
                btn:ShowTag(false)
                btn:ShowReddot(self._Control:IsHaveNewWeaponSettingByWeaponType(type))
            end
        end
    end
end
-----------------------------------事件相关-----------------------------------------<<<