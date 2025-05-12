local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiEquipPanelSuit = XClass(XUiNode, "XUiEquipPanelSuit")

function XUiEquipPanelSuit:OnStart()
    self.SuitItem.gameObject:SetActiveEx(false)
    self.SuitList.gameObject:SetActiveEx(false)
    self.BtnSortSuggest.gameObject:SetActiveEx(false)
    self.BtnSortStar.gameObject:SetActiveEx(false)

    self.SORT_TYPE = { SUGGEST = 1, STAR = 2 }
    self.IsOpenSuitList = false
    self.CurSortType = self.SORT_TYPE.SUGGEST
    self:SetButtonCallBack()
end

function XUiEquipPanelSuit:OnDestroy()

end

function XUiEquipPanelSuit:OnRelease()
    self.SORT_TYPE = nil
    self.IsOpenSuitList = nil
    self.CurSortType = nil
    self.SuitInfoList = nil
    self.PriorityDic = nil
    self.SuitPriorityCfg = nil
end

function XUiEquipPanelSuit:SetButtonCallBack()
    self.Parent:RegisterClickEvent(self.SuitTitle, function() self:OnBtnSuitTitleClick(true) end)
    self.Parent:RegisterClickEvent(self.SuitTitleSelect, function() self:OnBtnSuitTitleClick(false) end)
    self.Parent:RegisterClickEvent(self.BtnSortSuggest, function() self:OnBtnSortSuggest() end)
    self.Parent:RegisterClickEvent(self.BtnSortStar, function() self:OnBtnSortStar() end)
end

function XUiEquipPanelSuit:OnBtnSuitTitleClick(isOpen)
    local INTERVAL_TIME = 0.25 -- 点击间隔时间
    local curTime = CS.UnityEngine.Time.realtimeSinceStartup
    if self.LastClickSuitTitleTime then 
        if curTime - self.LastClickSuitTitleTime < INTERVAL_TIME then 
            return
        end
    end
    self.LastClickSuitTitleTime = curTime

    self:OpenSuitFilter(isOpen)
end

function XUiEquipPanelSuit:OnBtnSortSuggest()
    self.BtnSortSuggest.gameObject:SetActiveEx(false)
    self.BtnSortStar.gameObject:SetActiveEx(true)

    self.CurSortType = self.SORT_TYPE.STAR
    self:UpdateSuitList()
end

function XUiEquipPanelSuit:OnBtnSortStar()
    self.BtnSortSuggest.gameObject:SetActiveEx(true)
    self.BtnSortStar.gameObject:SetActiveEx(false)

    self.CurSortType = self.SORT_TYPE.SUGGEST
    self:UpdateSuitList()
end

function XUiEquipPanelSuit:InitDynamicTable()
    local XUiEquipGridSuit = require("XUi/XUiEquip/XUiEquipAwarenessReplace/XUiEquipGridSuit")
    self.DynamicTable = XDynamicTableNormal.New(self.SuitList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiEquipGridSuit)
end

function XUiEquipPanelSuit:UpdateSuitList()
    if not self.DynamicTable then
        self:InitDynamicTable()
    end

    self.SuitInfoList = self:GetSuitInfoList()
    self.DynamicTable:SetDataSource(self.SuitInfoList)
    self.DynamicTable:ReloadDataASync(#self.SuitInfoList > 0 and #self.SuitInfoList or -1)
end

function XUiEquipPanelSuit:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.Parent)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local suitInfo = self.SuitInfoList[index]
        local isSelect = suitInfo.SuitId == self.Parent.SelectSuitId
        grid:Refresh(suitInfo, isSelect)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local suitInfo = self.SuitInfoList[index]
        self.Parent:OnSelectSuit(suitInfo.SuitId)
    end
end

-- 打开意识套装筛选
function XUiEquipPanelSuit:OpenSuitFilter(isOpen)
    if self.IsOpenSuitList == isOpen then
        return
    end

    self.IsOpenSuitList = isOpen
    self.SuitTitle.gameObject:SetActiveEx(not isOpen)
    self.SuitTitleSelect.gameObject:SetActiveEx(isOpen)
    self.BtnSortSuggest.gameObject:SetActiveEx(isOpen and self.CurSortType == self.SORT_TYPE.SUGGEST)
    self.BtnSortStar.gameObject:SetActiveEx(isOpen and self.CurSortType == self.SORT_TYPE.STAR)
    self.Parent.PanelTogPos.gameObject:SetActiveEx(not isOpen)

    if isOpen then
        self.SuitList.gameObject:SetActiveEx(true)
        self.Parent:PlayAnimation("SuitListEnable")
        self:UpdateSuitList()
    else
        self.Parent:PlayAnimation("SuitListDisable", function()
            self.SuitList.gameObject:SetActiveEx(false)
        end)
    end
end

-- 刷新套装标题
function XUiEquipPanelSuit:UpdateSuitTitle(suitId)
    local isAll = suitId == XEnumConst.EQUIP.ALL_SUIT_ID
    self.ImgSuitIcon.gameObject:SetActiveEx(not isAll)
    self.ImgSuitIconSelect.gameObject:SetActiveEx(not isAll)
    local suitName
    if isAll then
        suitName = XUiHelper.GetText("ScreenAll")
    else
        suitName = XMVCA:GetAgency(ModuleId.XEquip):GetSuitName(suitId)
        local iconPath = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitIconPath(suitId)
        self.ImgSuitIcon:SetSprite(iconPath)
        self.ImgSuitIconSelect:SetSprite(iconPath)
    end

    local title = XUiHelper.GetText("CurrentFilterSuit", suitName)
    self.TxtSuitTitle.text = title
    self.TxtSuitTitleSelect.text = title
end

-- 获取套装列表
function XUiEquipPanelSuit:GetSuitInfoList()
    -- 初始化排序优先级
    if not self.PriorityDic then
        self.PriorityDic = {}
        self.SuitPriorityCfg = self._Control:GetConfigCharacterSuitPriority(self.Parent.CharacterId)
        if self.SuitPriorityCfg then
            for index, suitType in ipairs(self.SuitPriorityCfg.PriorityType) do
                self.PriorityDic[suitType] = index
            end
        end
    end

    -- 排序
    local suitInfoList = self._Control:GetSuitInfoList(self.Parent.CharacterId, self.Parent.SelectSite)
    if self.CurSortType == self.SORT_TYPE.SUGGEST then
        table.sort(suitInfoList, function(a, b)
            return self:SortSuggest(a, b)
        end)
    elseif self.CurSortType == self.SORT_TYPE.STAR then
        table.sort(suitInfoList, function(a, b)
            return self:SortStar(a, b)
        end)
    end

    -- 全部按钮
    local allCount = 0
    for _, suitInfo in ipairs(suitInfoList) do
        allCount = allCount + suitInfo.Count
    end
    table.insert(suitInfoList, 1, { SuitId = 0, Count = allCount})

    -- 从下往上反序显示
    XTool.ReverseList(suitInfoList)
    return suitInfoList
end

function XUiEquipPanelSuit:SortSuggest(a, b)
    -- 专属套装优先
    if self.SuitPriorityCfg and self.SuitPriorityCfg.ExclusiveSuitId ~= 0 then
        local isExclusiveA = self.SuitPriorityCfg.ExclusiveSuitId == a.SuitId
        local isExclusiveB = self.SuitPriorityCfg.ExclusiveSuitId == b.SuitId
        if isExclusiveA ~= isExclusiveB then
            return isExclusiveA
        end
    end

    -- 根据优先级排序
    local agency = XMVCA:GetAgency(ModuleId.XEquip)
    local suitTypeA = agency:GetEquipSuitSuitType(a.SuitId)
    local suitTypeB = agency:GetEquipSuitSuitType(b.SuitId)
    local priorityA = self.PriorityDic[suitTypeA] or 100000
    local priorityB = self.PriorityDic[suitTypeB] or 100000
    if priorityA ~= priorityB then
        return priorityA < priorityB
    end

    -- 按照意识套装ID从大到小排序
    return a.SuitId > b.SuitId
end

function XUiEquipPanelSuit:SortStar(a, b)
    local aStar = XMVCA.XEquip:GetSuitStar(a.SuitId)
    local bStar = XMVCA.XEquip:GetSuitStar(b.SuitId)
    if aStar ~= bStar then
        return aStar > bStar
    else
        return self:SortSuggest(a, b)
    end
end

return XUiEquipPanelSuit
