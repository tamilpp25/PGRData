local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSpecialFashionShop = XLuaUiManager.Register(XLuaUi, "UiSpecialFashionShop")
local XUiCommodity = require("XUi/XUiSpecialFashionShop/XUiCommodity")

local Dropdown = CS.UnityEngine.UI.Dropdown
local NewFashionFilterShopList = {}

function XUiSpecialFashionShop:OnAwake()
    self.ShopId = XSpecialShopConfigs.GetShopId()
    self.WeaponShopId = XSpecialShopConfigs.GetWeaponFashionShopId()
    self.TabUiBtnList = {}
    self.CurTabIndex = 0

    self.IndexToShopData = {}
    self.DynamicTable = nil
    self.GoodList = nil

    self.TagList = nil
    self.SelectTag = nil

    self.TimerFunctions = {}
    self.ScheduleId = nil
    self:InitNewFashionFilterShopList()
    self:AddListener()
    self:InitDynamicTable()
    self:InitTabList()

    -- 货币
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)

    -- 定时器
    self:StartTimer()
end

function XUiSpecialFashionShop:OnStart()
end

function XUiSpecialFashionShop:OnEnable()
    self:Refresh()
end

function XUiSpecialFashionShop:OnDisable()
end

function XUiSpecialFashionShop:OnDestroy()
    self:DestroyTimer()
end

--- 初始化需要使用新筛选器的商店Id的列表
function XUiSpecialFashionShop:InitNewFashionFilterShopList()
    local str = CS.XGame.ClientConfig:GetString('NewFashionFilterShopList')
    local strList = string.Split(str, '|')

    if not XTool.IsTableEmpty(strList) then
        for i, idStr in pairs(strList) do
            if string.IsNumeric(idStr) then
                NewFashionFilterShopList[tonumber(idStr)] = true
            end
        end
    end
end

function XUiSpecialFashionShop:Refresh()
    -- 货币
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(self.ShopId))

    -- 活动时间
    local timeInfo = XShopManager.GetShopTimeInfo(self.ShopId)
    self.TxtTime.text = XUiHelper.GetTime(timeInfo.ClosedLeftTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiSpecialFashionShop:GetCurShopId()
    local shopData = self.IndexToShopData[self.CurTabIndex]
    return shopData.ShopId
end

function XUiSpecialFashionShop:CheckShopChanged()
    if self._LastShopId == nil or self._LastShopId ~= self:GetCurShopId() then
        return true
    else
        return false
    end
end

-- 购买成功后刷新
function XUiSpecialFashionShop:OnBuySuccessCb()
    self:RefreshDynamicTable()
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(self.ShopId))
end

------------------------------------------------------- 监听函数start -------------------------------------------------------

function XUiSpecialFashionShop:AddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.DropFilter.onValueChanged:AddListener(function()
        self.SelectTag = self.DropFilter.captionText.text
        self:FilterGoodList()
        self:RefreshDynamicTable()
    end)

    if self.BtnFilter then
        self:RegisterClickEvent(self.BtnFilter, self.OnBtnFilterClick)
    end
end

function XUiSpecialFashionShop:OnBtnBackClick()
    self:Close()
end

function XUiSpecialFashionShop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSpecialFashionShop:OnBtnFilterClick()
    -- 将selectTag转成characterId
    local screenGroupCfg = XShopManager.GetShopScreenGroupDataById(XShopManager.ScreenType.FashionType)
    local characterId = nil
    if screenGroupCfg then
        for i, name in pairs(screenGroupCfg.ScreenName) do
            if self.SelectTag == name then
                characterId = screenGroupCfg.ScreenID[i]
                break
            end
        end
    end

    XLuaUiManager.Open('UiShopFashionFilter', self:GetCurShopId(), self._TmpCareerTags, self._TmpElementTags, characterId, function(careerTags, elementTags, characterId)
        self._TmpCareerTags = careerTags
        self._TmpElementTags = elementTags
        self.SelectTag = CS.XTextManager.GetText("ScreenAll")
        -- characterId 转成selectTag
        if screenGroupCfg then
            for i, id in pairs(screenGroupCfg.ScreenID) do
                if characterId == id then
                    self.SelectTag = screenGroupCfg.ScreenName[i]
                    break
                end
            end
        end
        -- 刷新列表
        self.BtnFilter:SetNameByGroup(0, self.SelectTag)
        self:FilterGoodList()
        self:RefreshDynamicTable()
    end)
end

------------------------------------------------------- 监听函数end -------------------------------------------------------

------------------------------------------------------- 页签start -------------------------------------------------------
function XUiSpecialFashionShop:InitTabList()
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnFirstHasSnd.gameObject:SetActiveEx(false)
    self.BtnSecondTop.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    self.BtnSecondBottom.gameObject:SetActiveEx(false)

    -- 角色涂装
    local goodsList = XShopManager.GetShopGoodsList(self.ShopId)
    if #goodsList > 0 then 
        -- 一级页签
        local firstBtnGo = CS.UnityEngine.Object.Instantiate(self.BtnFirstHasSnd)
        firstBtnGo.transform:SetParent(self.TabBtnGroup.transform, false)
        firstBtnGo.gameObject:SetActiveEx(true)
        local firstUiBtn = firstBtnGo:GetComponent("XUiButton")
        local firstName = CSXTextManagerGetText("UiFashionDetailTitleCharacter")
        firstUiBtn:SetName(firstName)
        table.insert(self.TabUiBtnList, firstUiBtn)

        -- 二级页签
        local subGroupIndex = #self.TabUiBtnList -- firstUiBtn的下标
        local seriesIdList = XDataCenter.SpecialShopManager.GetSeriesIdList(self.ShopId)
        for secIndex, seriesId in ipairs(seriesIdList) do
            local secBtnGo
            if secIndex == 1 then
                secBtnGo = CS.UnityEngine.Object.Instantiate(self.BtnSecondTop)
            elseif secIndex == #seriesIdList then
                secBtnGo = CS.UnityEngine.Object.Instantiate(self.BtnSecondBottom)
            else 
                secBtnGo = CS.UnityEngine.Object.Instantiate(self.BtnSecond)
            end
            secBtnGo.transform:SetParent(self.TabBtnGroup.transform, false)
            secBtnGo.gameObject:SetActiveEx(true)
            local secUiBtn = secBtnGo:GetComponent("XUiButton")
            local secName = XFashionConfigs.GetSeriesName(seriesId)
            secUiBtn:SetName(secName)
            secUiBtn.SubGroupIndex = subGroupIndex
            table.insert(self.TabUiBtnList, secUiBtn)

            local tabIndex = #self.TabUiBtnList
            self.IndexToShopData[tabIndex] = {ShopId = self.ShopId, SeriesId = seriesId}
        end
    end

    -- 武器涂装
    local weaponList = XShopManager.GetShopGoodsList(self.WeaponShopId)
    if #weaponList > 0 then
        local firstBtnGo = CS.UnityEngine.Object.Instantiate(self.BtnFirst)
        firstBtnGo.transform:SetParent(self.TabBtnGroup.transform, false)
        firstBtnGo.gameObject:SetActiveEx(true)
        local firstUiBtn = firstBtnGo:GetComponent("XUiButton")
        local firstName = CSXTextManagerGetText("UiFashionDetailTitleWeapon")
        firstUiBtn:SetName(firstName)
        table.insert(self.TabUiBtnList, firstUiBtn)
        local tabIndex = #self.TabUiBtnList
        self.IndexToShopData[tabIndex] = {ShopId = self.WeaponShopId}
    end

    if #self.TabUiBtnList > 0 then 
        -- 初始化group
        self.TabBtnGroup:Init(self.TabUiBtnList, function(index) self:OnSelectedTab(index) end)
        self.TabBtnGroup:SelectIndex(1)
    end
end

function XUiSpecialFashionShop:OnSelectedTab(index)
    if self.CurTabIndex == index then
        return
    end

    if self.CurTabIndex ~= index and XTool.IsNumberValid(self.CurTabIndex) then
        self._LastShopId = self:GetCurShopId()
    end

    self.CurTabIndex = index
    self:InitDropDown()
    self:FilterGoodList()
    self:RefreshDynamicTable()
end
------------------------------------------------------- 页签end -------------------------------------------------------


------------------------------------------------------- 滑动列表start -------------------------------------------------------

function XUiSpecialFashionShop:InitDynamicTable()
    self.GridShop.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelFashionList)
    self.DynamicTable:SetProxy(XUiCommodity)
    self.DynamicTable:SetDelegate(self)
end

function XUiSpecialFashionShop:RefreshDynamicTable()
    self.DynamicTable:SetDataSource(self.GoodList)
    self.DynamicTable:ReloadDataASync()
end

function XUiSpecialFashionShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.GoodList[index]
        grid:Refresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

------------------------------------------------------- 滑动列表页签end -------------------------------------------------------

------------------------------------------------------- Dropdown start -------------------------------------------------------

function XUiSpecialFashionShop:InitDropDown()
    local shopData = self.IndexToShopData[self.CurTabIndex]
    if shopData.ShopId == self.ShopId then 
        self.TagList = XDataCenter.SpecialShopManager.GetTagListBySeriesId(shopData.ShopId, shopData.SeriesId)
    else
        self.TagList = XShopManager.GetScreenTagListById(shopData.ShopId, XShopManager.ScreenType.WeaponType)
    end

    if self:CheckShopChanged() then
        self.SelectTag = CS.XTextManager.GetText("ScreenAll")
        local isShowDrop = self.TagList and #self.TagList > 0
        self.DropFilter.gameObject:SetActiveEx(isShowDrop)
        if self.BtnFilter then
            self.BtnFilter.gameObject:SetActiveEx(isShowDrop)
        end
        if not isShowDrop then
            return
        end

        local isUseNewFliter = NewFashionFilterShopList[self.ShopId]

        self.DropFilter.gameObject:SetActiveEx(not isUseNewFliter)

        if self.BtnFilter then
            self.BtnFilter.gameObject:SetActiveEx(isUseNewFliter)
        end

        if isUseNewFliter and self.BtnFilter then
            self.BtnFilter:SetNameByGroup(0, CS.XTextManager.GetText("ScreenAll"))
            self._TmpCareerTags = nil
            self._TmpElementTags = nil
        else
            self.DropFilter:ClearOptions()
            self.DropFilter.captionText.text = self.SelectTag
            for _,v in pairs(self.TagList or {}) do
                local op = Dropdown.OptionData()
                op.text = v.Text
                self.DropFilter.options:Add(op)
            end
            self.DropFilter.value = 0
        end
    end
end

function XUiSpecialFashionShop:FilterGoodList()
    local shopData = self.IndexToShopData[self.CurTabIndex]
    if shopData.ShopId == self.ShopId then
        self.GoodList = XDataCenter.SpecialShopManager.GetFashionListBySeriesId(shopData.ShopId, shopData.SeriesId, self.SelectTag)
    else
        self.GoodList = XDataCenter.SpecialShopManager.GetWeaponFashionListByTag(shopData.ShopId, self.SelectTag)
    end
end
------------------------------------------------------- Dropdown end -------------------------------------------------------

------------------------------------------------------- 定时器start -------------------------------------------------------
function XUiSpecialFashionShop:StartTimer()
    if self.ScheduleId then
        return
    end

    self.ScheduleId = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, 1000)
end

function XUiSpecialFashionShop:UpdateTimer()
    if next(self.TimerFunctions) then
        for _, timerFun in pairs(self.TimerFunctions) do
            if timerFun then
                timerFun()
            end
        end
    end
end

function XUiSpecialFashionShop:RegisterTimerFun(id, fun)
    self.TimerFunctions[id] = fun
end

function XUiSpecialFashionShop:RemoveTimerFun(id)
    self.TimerFunctions[id] = nil
end

function XUiSpecialFashionShop:DestroyTimer()
    if self.ScheduleId then
        XScheduleManager.UnSchedule(self.ScheduleId)
        self.ScheduleId = nil
    end
end
------------------------------------------------------- 定时器end -------------------------------------------------------
