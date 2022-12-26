local DormBagItem = require("XUi/XUiDormBag/XUiPanelDormBagItem")
local XUiRecyclePreview = require("XUi/XUiDormBag/XUiRecyclePreview")
local XUiDormBag = XLuaUiManager.Register(XLuaUi, "UiDormBag")

local SELECT_OFFSET_MIN = CS.UnityEngine.Vector2(32, 155)
local SELECT_OFFSET_MAX = CS.UnityEngine.Vector2(-59, -216)
local SELECT_TYPE_ALL = 0

function XUiDormBag:OnAwake()
    self:AddListener()
end

function XUiDormBag:OnStart(pageRecord, furnitureState, selectCb, filter, needDaftCount, furnitureTypeId)
    self.SelectIds = {} -- 记录筛选的ConfigId
    self.SelectSuitIds = {} -- 记录套装筛选的ConfigId
    self.NeedDraftCount = needDaftCount or 0 -- 需要图纸数量
    self.PriorSortType = XFurnitureConfigs.PriorSortType.All

    self:InitFurniturePart()
    self:InitRecyclePreview()
    self:InitPrivateVariable(pageRecord, furnitureState, selectCb, filter)
    self:InitDynamicTable()
    self:InitTabGroup(furnitureTypeId)
    self:SetAscendBtn()

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelHostelAsset, XDataCenter.ItemManager.ItemId.DormCoin, XDataCenter.ItemManager.ItemId.FurnitureCoin)
end

function XUiDormBag:OnDestroy()
    self.SelectIds = nil
    self.SelectSuitIds = nil
    self.PageRecord = 0
    self.CharPageRecord = 0
    self.FurnitureState = 0
    self.AscendSort = false
end

function XUiDormBag:OnEnable()
    self:RefreshSelectedPanel(self.PageRecord, true)
    XEventManager.AddEventListener(XEventId.EVENT_CLICKFURNITURE_GRID, self.OnFurnitureGridClick, self)
    XEventManager.AddEventListener(XEventId.EVENT_CLICKDRAFT_GRID, self.OnDraftGridClick, self)
    XEventManager.AddEventListener(XEventId.EVENT_DORM_BAG_REFRESH, self.UpdateDynamicTable, self)
end

function XUiDormBag:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_CLICKFURNITURE_GRID, self.OnFurnitureGridClick, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CLICKDRAFT_GRID, self.OnDraftGridClick, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_BAG_REFRESH, self.UpdateDynamicTable, self)
end

function XUiDormBag:InitRecyclePreview()
    self.RecyclePreview = XUiRecyclePreview.New(self.PanelRecyclePreview, self)
    self.RecyclePreview:Hide()
end

function XUiDormBag:InitPrivateVariable(pageRecord, furnitureState, selectCb, filter)
    self.SelectCb = selectCb

    if pageRecord then
        self.PageRecord = pageRecord
    else
        self.PageRecord = XDormConfig.DORM_BAG_PANEL_INDEX.FURNITURE
    end

    self.CharPageRecord = XDormConfig.DORM_CHAR_INDEX.CHARACTER

    if furnitureState then
        self.FurnitureState = furnitureState
    else
        self.FurnitureState = XFurnitureConfigs.FURNITURE_STATE.DETAILS
    end

    -- 过滤家具或者图纸
    self.Filter = filter
end

function XUiDormBag:InitTabGroup(furnitureTypeId)
    self.BtnList = {}
    table.insert(self.BtnList, self.BtnTogFurniture)
    table.insert(self.BtnList, self.BtnTogCharacter)
    table.insert(self.BtnList, self.BtnTogDraft)

    self.PanelTogs:Init(self.BtnList, function(index)
        self:RefreshSelectedPanel(index, true)
    end)

    -- 处理构造体/感染体
    self.BtnCharList = {}
    table.insert(self.BtnCharList, self.BtnTogChar)
    table.insert(self.BtnCharList, self.BtnTogEmney)
    -- table.insert(self.BtnCharList, self.BtnTogHuman)
    table.insert(self.BtnCharList, self.BtnTogInfestor)
    table.insert(self.BtnCharList, self.BtnTogNier)
    self.PanelCharacterBtn:Init(self.BtnCharList, function(index)
        self:RefreshSelectedCharPanel(index)
    end)

    -- 选择家具状态处理
    if self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECT or
    self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECTSINGLE then

        self.FurnitureSelectList = {}
        if self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.FURNITURE then
            self.BtnTogFurniture.gameObject:SetActiveEx(true)
            self.BtnTogCharacter.gameObject:SetActiveEx(false)
            self.BtnTogDraft.gameObject:SetActiveEx(false)
            self.TxtSelectTip.gameObject:SetActiveEx(true)
        elseif self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT then
            self.BtnTogFurniture.gameObject:SetActiveEx(false)
            self.BtnTogCharacter.gameObject:SetActiveEx(false)
            self.BtnTogDraft.gameObject:SetActiveEx(true)
            self.TxtSelectTip.gameObject:SetActiveEx(false)
        end
        self:InitDrdSort(furnitureTypeId)

        self.PanelSelect.gameObject:SetActiveEx(true)
        self.BtnRecycle.gameObject:SetActiveEx(false)
        self.PanelNormlBt.gameObject:SetActiveEx(false)
        self.BtnBuild.gameObject:SetActiveEx(false)
        self.PanelTogs.gameObject:SetActiveEx(false)
        self.BtnShop.gameObject:SetActiveEx(false)
        self.TxtPartDesc.gameObject:SetActiveEx(false)
        self.TxtSelectCount.gameObject:SetActiveEx(false)
        self.DrdSort.gameObject:SetActiveEx(false)
        self.PanelDordPart.gameObject:SetActiveEx(true)
        self.BtnOrder.gameObject:SetActiveEx(false)
        self.BtnPart.gameObject:SetActiveEx(false)

        self.PanelDynamicTableRct.offsetMin = SELECT_OFFSET_MIN
        self.PanelDynamicTableRct.offsetMax = SELECT_OFFSET_MAX

        self.AscendSort = true
    else
        self.PanelSelect.gameObject:SetActiveEx(false)
        self.BtnRecycle.gameObject:SetActiveEx(true)
        self.PanelNormlBt.gameObject:SetActiveEx(true)
        self.BtnBuild.gameObject:SetActiveEx(true)
        self.PanelTogs.gameObject:SetActiveEx(true)
        self.BtnShop.gameObject:SetActiveEx(true)
        self.TxtPartDesc.gameObject:SetActiveEx(true)
        self.TxtSelectCount.gameObject:SetActiveEx(false)
        self.DrdSort.gameObject:SetActiveEx(true)
        self.BtnOrder.gameObject:SetActiveEx(true)
        self.PanelDordPart.gameObject:SetActiveEx(false)
        self.BtnPart.gameObject:SetActiveEx(true)

        self.AscendSort = false
    end

    -- 设置默认开启
    self.PanelTogs:SelectIndex(self.PageRecord)

    -- 设置默认开启
    self.PanelCharacterBtn:SelectIndex(self.CharPageRecord)
end

function XUiDormBag:InitDynamicTable()
    self.PanelDormBagItem.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(DormBagItem)
    self.DynamicTable:SetDelegate(self)
end

function XUiDormBag:InitFurniturePart()
    local typeList = XFurnitureConfigs.GetFurnitureTemplateTypeList()
    for _, furnitureType in ipairs(typeList) do
        table.insert(self.SelectIds, furnitureType.Id)
    end

    local typeSuitList = XFurnitureConfigs.GetFurnitureSuitTemplates()
    for _, suit in ipairs(typeSuitList) do
        if suit.Id ~= XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID then
            table.insert(self.SelectSuitIds, suit.Id)
        end
    end
end

function XUiDormBag:SetAscendBtn()
    self.ImgAscend.gameObject:SetActiveEx(self.AscendSort)
    self.ImgDescend.gameObject:SetActiveEx(not self.AscendSort)
end

--动态列表事件
function XUiDormBag:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.PageDatas[index]
        if self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.FURNITURE then
            local isSelect = self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECT
            grid:SetupFurniture(data, isSelect)
        elseif self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.CHARACTER then
            grid:SetupCharacter(data)
        elseif self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT then
            grid:SetupDraft(data, self.NeedDraftCount)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if self.DOAnchor_PosY then
            self.Content:DOAnchorPosY(self.DOAnchor_PosY, 0.1)
            self.DOAnchor_PosY = nil
        end
    end
end

function XUiDormBag:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnBuild, self.OnBtnBuildClick)
    self:RegisterClickEvent(self.BtnRecycle, self.OnBtnRecycleClick)
    self:RegisterClickEvent(self.BtnRecycle_Draft, self.OnBtnRecycleClick)
    self:RegisterClickEvent(self.BtnPart, self.OnBtnPartClick)
    self:RegisterClickEvent(self.BtnShop, self.OnBtnShopClick)
    self:RegisterClickEvent(self.BtnSelect, self.OnBtnSelectClick)
    self:RegisterClickEvent(self.BtnOrder, self.OnBtnOrderClick)
    self.DrdSort.onValueChanged:AddListener(function()
        self.PriorSortType = self.DrdSort.value
        self:RefreshSelectedPanel(self.PageRecord, true)
    end)

    self.DrodPart.onValueChanged:AddListener(function()
        self:OnDrodPartValueChanged()
    end)
end

function XUiDormBag:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDormBag:OnBtnBackClick()
    if self.RecyclePreview:IsShow() then
        self:PlayAnimation("RecyclePreviewDisable", function()
            self:OnRecycleCancel()
            self.RecyclePreview:Hide()
        end)
        return
    end

    self:Close()
end

function XUiDormBag:OnBtnBuildClick()
    XLuaUiManager.Open("UiFurnitureBuild")
end

-- 点击筛选
function XUiDormBag:OnBtnPartClick()
    XLuaUiManager.Open("UiFurnitureTypeSelect", self.SelectIds, self.SelectSuitIds, false, function(selectIds, selectSuitIds)
        if #selectIds <= 0 or #selectSuitIds <= 0 then
            return
        end

        -- 如果再单选情况下 重新选择家具
        if self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECTSINGLE then
            if self.FurnitureSelectGrid then
                self.FurnitureSelectGrid:SetSelected(false)
                self.FurnitureSelectGrid = nil
            end
            self.FurnitureSelectId = nil
        end

        self.SelectIds = selectIds
        self.SelectSuitIds = selectSuitIds
        self:RefreshSelectedPanel(self.PageRecord, true)
    end)
end

function XUiDormBag:SetPartCount(count)
    local allTypeId = XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID
    local allSuitTypeId = XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID

    if #self.SelectIds == 1 and self.SelectIds[1] == allTypeId and
    self.PriorSortType == XFurnitureConfigs.PriorSortType.All and
    #self.SelectSuitIds == 1 and self.SelectSuitIds[1] == allSuitTypeId then
        self.TxtPartDesc.text = CS.XTextManager.GetText("DormSelectAllCount", count)
    else
        self.TxtPartDesc.text = CS.XTextManager.GetText("DormSelectCount", count)
    end
end

function XUiDormBag:OnBtnShopClick()
    XLuaUiManager.Open("UiShop", XShopManager.ShopType.Dorm)
end

-- 排序按钮
function XUiDormBag:OnBtnOrderClick()
    self.AscendSort = not self.AscendSort
    self:SetAscendBtn()
    self:RefreshSelectedPanel(self.PageRecord, true)
end

--家具、图纸回收
function XUiDormBag:OnBtnRecycleClick()
    self.AscendSort = true
    self:SetAscendBtn()
    self.DrdSort.gameObject:SetActiveEx(false)

    self.PanelFurnitureBtn.gameObject:SetActiveEx(false)
    self.RecyclePreview:Show(self.PageRecord)
    self:PlayAnimation("RecyclePreviewEnable")
    self.FurnitureSelectList = {}
    self.FurnitureState = XFurnitureConfigs.FURNITURE_STATE.RECYCLE
    self:RefreshSelectedPanel(self.PageRecord, true)
end

--@region 确认回收
function XUiDormBag:OnRecycleConfirm(count)
    if self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT then
        self:DecomposeDraft(count)
    elseif self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.FURNITURE then
        self:DecomposeFurniture()
    end
end

--图纸回收
function XUiDormBag:DecomposeDraft(count)
    local tm = {}
    for i,v in ipairs(self.FurnitureSelectList) do
        tm[v] = count
    end
    XDataCenter.ItemManager.Sell(tm, function(rewardGoodDic)
        local rewards = {}
        for key, value in pairs(rewardGoodDic) do
            table.insert(rewards, { TemplateId = key, Count = value })
        end
        XUiManager.OpenUiObtain(rewards)      

        -- 清理数据后重新进入
        self:OnRecycleCancel()
        self:OnBtnRecycleClick()
    end)
end

--家具回收
function XUiDormBag:DecomposeFurniture()
    XDataCenter.FurnitureManager.DecomposeFurniture(self.FurnitureSelectList, function(rewardItems, successIds)
        -- 先打开回收界面
        XLuaUiManager.Open("UiDormBagRecycle", self.FurnitureSelectList, rewardItems)

        -- 将分解成功的家具从缓存中移除
        for _, id in ipairs(successIds) do
            XDataCenter.FurnitureManager.RemoveFurniture(id)
        end

        -- 删除红点
        XDataCenter.FurnitureManager.DeleteNewHint(successIds)

        -- 清理数据
        self:OnRecycleCancel()
    end)
end
--@endregion

-- 取消回收
function XUiDormBag:OnRecycleCancel()
    -- 设置排序
    self.AscendSort = false
    self:SetAscendBtn()
    self.DrdSort.gameObject:SetActiveEx(true)

    self.FurnitureSelectList = {}
    self.FurnitureSelectId = nil
    self.FurnitureSelectGrid = nil
    self.FurnitureState = XFurnitureConfigs.FURNITURE_STATE.DETAILS
    self:RefreshSelectedPanel(self.PageRecord, true)
    if self.PageRecord ~= XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT then
        self.PanelFurnitureBtn.gameObject:SetActiveEx(true)
    end
end

-- 确认选择
function XUiDormBag:OnBtnSelectClick()
    if self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECT then
        if not self.FurnitureSelectList or #self.FurnitureSelectList <= 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("DormFurnitureSelectNull"), XUiManager.UiTipType.Tip)
            return
        end

        if self.SelectCb then
            self.SelectCb(self.FurnitureSelectList)
        end

    elseif self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECTSINGLE then
        if not self.FurnitureSelectId or self.FurnitureSelectId == nil then
            XUiManager.TipMsg(CS.XTextManager.GetText("DormFurnitureSelectNull"), XUiManager.UiTipType.Tip)
            return
        end

        if self.SelectCb then
            self.SelectCb(self.FurnitureSelectId)
        end
    end

    self:Close()
end

function XUiDormBag:RefreshSelectedPanel(index, startIndex)
    self.PageRecord = index
    self:UpdateDynamicTable(startIndex)
end

function XUiDormBag:RefreshSelectedCharPanel(index)
    self.CharPageRecord = index
    self:UpdateDynamicTable(true)
end

--@region 点击grid的响应事件
function XUiDormBag:OnFurnitureGridClick(furnitureId, furnitureConfigId, grid)
    if self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.DETAILS then
        grid:SetNewActive()
        XLuaUiManager.Open("UiFurnitureDetail", furnitureId, furnitureConfigId, nil, function()
            self:RefreshSelectedPanel(self.PageRecord, true)
        end)
    elseif self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.RECYCLE 
    or self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECT then
        self:RecycleFurniture(furnitureId, furnitureConfigId, grid)
    elseif self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECTSINGLE then
        self:SetSelectSingleFurnitureSelectGrid(furnitureConfigId, grid)
    end
end

function XUiDormBag:OnDraftGridClick(templateId, count, grid)
    if self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.DETAILS then
        XLuaUiManager.Open("UiTip", { TemplateId = templateId, Count = count })
    elseif self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.RECYCLE then
        self:RecycleDraft(templateId, grid)
    elseif self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECTSINGLE then
        self:SelectSingleFurnitureSelectGrid(templateId, grid)
    end
end

function XUiDormBag:RecycleFurniture(furnitureId, furnitureConfigId, grid)
    grid:SetSelected(not grid:IsSelected())
    for i = 1, #self.FurnitureSelectList do
        if self.FurnitureSelectList[i] == furnitureId then
            table.remove(self.FurnitureSelectList, i)
            self.RecyclePreview:Refresh(self.FurnitureSelectList)
            return
        end
    end

    table.insert(self.FurnitureSelectList, furnitureId)
    self.RecyclePreview:Refresh(self.FurnitureSelectList)
    self:IsSelectAllToRefreshSelectedPanel(furnitureConfigId)
end

--图纸出售只能单选
function XUiDormBag:RecycleDraft(templateId, grid)
    if templateId == self.FurnitureSelectId then
        self.FurnitureSelectList = {}
    else
        self.FurnitureSelectList = {templateId}
    end

    self:SelectSingleFurnitureSelectGrid(templateId, grid)

    self.RecyclePreview:Refresh(self.FurnitureSelectList)
end

--单选
function XUiDormBag:SelectSingleFurnitureSelectGrid(selectId, grid)
    grid:SetSelected(not grid:IsSelected())
    if selectId == self.FurnitureSelectId then
        self.FurnitureSelectId = nil
        self.FurnitureSelectGrid = nil
    else
        self.FurnitureSelectId = selectId

        if self.FurnitureSelectGrid then
            self.FurnitureSelectGrid:SetSelected(false)
        end

        --记录选择得Grid
        self.FurnitureSelectGrid = grid
    end
end
--@endregion

function XUiDormBag:GetGridSelected(id)
    -- 选择家具状态下
    if self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECTSINGLE then
        if not self.FurnitureSelectId then
            return false
        end

        return id == self.FurnitureSelectId

        -- 多选状态下
    elseif self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.RECYCLE or
    self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECT then
        if not self.FurnitureSelectList then
            return false
        end

        for i = 1, #self.FurnitureSelectList do
            if self.FurnitureSelectList[i] == id then
                return true
            end
        end

        return false
    end

    return false
end

function XUiDormBag:UpdateDynamicTable(startIndex)
    self.PageDatas = self:GetDataByPage()

    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataASync(startIndex and 1 or -1)

    -- 判断是否为空
    local isEmpty = #self.PageDatas <= 0
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)

    -- 刷新Btn的显示
    if self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.FURNITURE then
        self.PanelFurnitureBtn.gameObject:SetActiveEx(true)
        self.PanelDraftBtn.gameObject:SetActiveEx(false)
        self.PanelCharacterBtn.gameObject:SetActiveEx(false)
        if isEmpty then
            self.TxtNull.text = CS.XTextManager.GetText("DormNullFurniture")
        end
    elseif self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.CHARACTER then
        self.PanelFurnitureBtn.gameObject:SetActiveEx(false)
        self.PanelDraftBtn.gameObject:SetActiveEx(false)
        self.PanelCharacterBtn.gameObject:SetActiveEx(true)
        if isEmpty then
            if self.CharPageRecord == XDormConfig.DORM_CHAR_INDEX.CHARACTER then
                self.TxtNull.text = CS.XTextManager.GetText("DormNullCharacter")
            -- elseif self.CharPageRecord == XDormConfig.DORM_CHAR_INDEX.HUMAN then
            --     self.TxtNull.text = CS.XTextManager.GetText("DormNullHumman")
            elseif self.CharPageRecord == XDormConfig.DORM_CHAR_INDEX.INFESTOR then
                self.TxtNull.text = CS.XTextManager.GetText("DormNullInfestor")
            elseif self.CharPageRecord == XDormConfig.DORM_CHAR_INDEX.NIER then
                self.TxtNull.text = CS.XTextManager.GetText("DormNullNiEr")
            else
                self.TxtNull.text = CS.XTextManager.GetText("DormNullEnmey")
            end
        end
    elseif self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT then
        self.PanelFurnitureBtn.gameObject:SetActiveEx(false)
        self.PanelDraftBtn.gameObject:SetActiveEx(true)
        self.PanelCharacterBtn.gameObject:SetActiveEx(false)
        if isEmpty then
            self.TxtNull.text = CS.XTextManager.GetText("DormNullDraft")
        end
    end
end

--获取数据
function XUiDormBag:GetDataByPage()
    -- 家具
    if self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.FURNITURE then
        -- 是否过滤已经使用的家具
        local isRemoveUsed = self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECT
        or self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.RECYCLE
        or self.PriorSortType == XFurnitureConfigs.PriorSortType.Unuse
        or self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECTSINGLE

        -- 是否过滤还未使用的家具
        local isRemoveUnuse = self.PriorSortType == XFurnitureConfigs.PriorSortType.Use and self.FurnitureState ~= XFurnitureConfigs.FURNITURE_STATE.RECYCLE
        local isRemoveLock = self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.RECYCLE
        local furnitureIds = XDataCenter.FurnitureManager.GetFurnitureCategoryIds(self.SelectIds, self.SelectSuitIds, isRemoveUsed, self.AscendSort, isRemoveUnuse, isRemoveLock)
        local filterIds = {}
        local filter = false
        if self.Filter then
            filter = true
            for _, furnitureId in pairs(furnitureIds) do
                if self.Filter(furnitureId) then
                    table.insert(filterIds, furnitureId)
                end
            end
        end
        local allCount = XDataCenter.FurnitureManager.GetAllFurnitureCount()
        self.TxtCount.text = CS.XTextManager.GetText("DormBagFurnitureCount", allCount)
        self.TxtSelectCount.text = CS.XTextManager.GetText("DormBagFurnitureCount", allCount)
        self:SetPartCount(filter and #filterIds or #furnitureIds)

        return filter and filterIds or furnitureIds
    end

    -- 构造体/感染体/人类
    if self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.CHARACTER then
        local characterIds = XDataCenter.DormManager.GetDormCharacterIds(XDormConfig.GetDormCharacterType(self.CharPageRecord))
        local allCount = XDormConfig.GetDormCharacterTemplatesCountByType(XDormConfig.GetDormCharacterType(self.CharPageRecord))

        if self.CharPageRecord == XDormConfig.DORM_CHAR_INDEX.CHARACTER then
            self.TxtCount.text = CS.XTextManager.GetText("DormBagCharacterCount", #characterIds, allCount)
            self.TxtSelectCount.text = CS.XTextManager.GetText("DormBagCharacterCount", #characterIds, allCount)
        elseif self.CharPageRecord == XDormConfig.DORM_CHAR_INDEX.EMNEY then
            self.TxtCount.text = CS.XTextManager.GetText("DormBagEmneyCount", #characterIds, allCount)
            self.TxtSelectCount.text = CS.XTextManager.GetText("DormBagEmneyCount", #characterIds, allCount)
        elseif self.CharPageRecord == XDormConfig.DORM_CHAR_INDEX.INFESTOR then
            self.TxtCount.text = CS.XTextManager.GetText("DormBagInfestorCount", #characterIds, allCount)
            self.TxtSelectCount.text = CS.XTextManager.GetText("DormBagInfestorCount", #characterIds, allCount)
        elseif self.CharPageRecord == XDormConfig.DORM_CHAR_INDEX.NIER then
            self.TxtCount.text = CS.XTextManager.GetText("DormBagNiErCount", #characterIds, allCount)
            self.TxtSelectCount.text = CS.XTextManager.GetText("DormBagNiErCount", #characterIds, allCount)
        -- else
        --     self.TxtCount.text = CS.XTextManager.GetText("DormBagHumanrCount", #characterIds, allCount)
        --     self.TxtSelectCount.text = CS.XTextManager.GetText("DormBagHumanrCount", #characterIds, allCount)
        end

        return characterIds
    end

    -- 图纸
    if self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT then
        local suitId = (self.SelectSuitIds and #self.SelectSuitIds == 1) and self.SelectSuitIds[1] or 0
        local itemDatas = XDataCenter.ItemManager.GetItemsByTypeAndSuitId(XItemConfigs.ItemType.FurnitureItem, suitId)

        -- 需要过滤
        local isSelectMode = self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECTSINGLE
        if isSelectMode and self.Filter then
            local filterDatas = {}
            for _, v in pairs(itemDatas) do
                if self.Filter(v.Id) then
                    table.insert(filterDatas, v)
                end
            end

            local count = self:GetDraftItemsCount(filterDatas)
            self.TxtCount.text = CS.XTextManager.GetText("DormBagDraftCount", count)
            self.TxtSelectCount.text = CS.XTextManager.GetText("DormBagDraftCount", count)
            return filterDatas
        end

        local count = self:GetDraftItemsCount(itemDatas)
        self.TxtCount.text = CS.XTextManager.GetText("DormBagDraftCount", count)
        self.TxtSelectCount.text = CS.XTextManager.GetText("DormBagDraftCount", count)
        return itemDatas
    end
end

function XUiDormBag:GuideGetDynamicTableIndex(id)
    for i, v in ipairs(self.PageDatas) do
        local furnitureConfig = XDataCenter.FurnitureManager.GetFurnitureConfigByUniqueId(v)
        if not furnitureConfig then
            return -1
        end

        if tostring(furnitureConfig.Id) == tostring(id) then
            return i
        end
    end

    return -1
end

function XUiDormBag:GetDraftItemsCount(list)
    local count = 0
    if not list or #list <= 0 then
        return count
    end

    for _, v in pairs(list) do
        count = count + v.Count
    end

    return count
end

-- 处理进入选择家具和图纸
function XUiDormBag:InitDrdSort(furnitureTypeId, notClearSelect)
    self.DrodPart:ClearOptions()

    local drodIndex = self:SetDrdSortIndexToType(furnitureTypeId)
    
    self.DrodPart.captionText.text = self.DrdSortIndexToType[drodIndex].Name

    self:CreateDrodPart()
    
    self.notClearSelect = notClearSelect
    local oldValue = self.DrodPart.value
    local newValue = drodIndex - 1
    self.DrodPart.value = newValue
    --强制触发OnDrodPartValueChanged
    if newValue == oldValue then
        self:OnDrodPartValueChanged()
    end
end

function XUiDormBag:SetDrdSortIndexToType(furnitureTypeId)
    self.DrdSortIndexToType = {}
    local drodIndex = 1

    if self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.FURNITURE then
        local typeList = XFurnitureConfigs.GetFurnitureTemplateTypeList()
        for i, config in ipairs(typeList) do
            if furnitureTypeId and furnitureTypeId == config.Id then
                drodIndex = i
            end

            local data = {
                TypeId = config.Id,
                Name = config.CategoryName,
            }
            table.insert(self.DrdSortIndexToType, data)
        end

        --增加一个全选的选项
        if self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECT then
            table.insert(self.DrdSortIndexToType, {
                TypeId = SELECT_TYPE_ALL,
                Name = CS.XTextManager.GetText("ScreenAll"),
            })
        end
    elseif self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT then
        local typeList = XFurnitureConfigs.GetFurnitureSuitTemplatesList()
        for i, config in ipairs(typeList) do
            local data = {
                TypeId = config.Id,
                Name = config.SuitName,
            }
            table.insert(self.DrdSortIndexToType, data)
        end
    end

    return drodIndex
end

function XUiDormBag:CreateDrodPart()
    local CsDropdown = CS.UnityEngine.UI.Dropdown
    for _, partType in ipairs(self.DrdSortIndexToType) do
        local op = CsDropdown.OptionData()
        op.text = partType.Name
        self.DrodPart.options:Add(op)
    end
end

function XUiDormBag:OnDrodPartValueChanged()
    local typeData = self.DrdSortIndexToType[self.DrodPart.value + 1]
    if self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.FURNITURE then
        if not self.notClearSelect then
            self.FurnitureSelectList = {}
        end
        self.notClearSelect = false
        self.SelectIds = self:GetSelectIdsByTypeId(typeData.TypeId)
    elseif self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT then
        self.FurnitureSelectId = nil
        self.FurnitureSelectGrid = nil
        self.SelectSuitIds = { typeData.TypeId }
    end

    self:RefreshSelectedPanel(self.PageRecord, true)
end

-- 如果在全选状态，页签自动筛选为对应类型
function XUiDormBag:IsSelectAllToRefreshSelectedPanel(furnitureConfigId)
    if self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECT then
        local typeData = self.DrdSortIndexToType[self.DrodPart.value + 1]
        if typeData.TypeId == SELECT_TYPE_ALL then
            local furnitureConfig = XFurnitureConfigs.GetFurnitureTemplateById(furnitureConfigId)
            self:InitDrdSort(furnitureConfig.TypeId, true)
            self:DOAnchorPosY()
        end
    end
end

function XUiDormBag:GetSelectIdsByTypeId(typeId)
    local selectIds = {}
    if self.PageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.FURNITURE then
        if typeId == SELECT_TYPE_ALL then
            for i,v in ipairs(self.DrdSortIndexToType) do
                if v.TypeId ~= SELECT_TYPE_ALL then
                    table.insert(selectIds, v.TypeId)
                end
            end
        else
            selectIds = { typeId }
        end
    end

    return selectIds
end

function XUiDormBag:DOAnchorPosY()
    self.DOAnchor_PosY = nil
    --默认只取第一个
    local furnitureId = self.FurnitureSelectList[1] 
    if furnitureId then
        local minRow = 3
        local dynamicTableNormal = self.PanelDynamicTable.gameObject:GetComponent(typeof(CS.XDynamicTableNormal))
        local index = 0
        for i,id in ipairs(self.PageDatas) do
            if furnitureId == id then
                index = i
                break
            end
        end

        local row = math.floor(index / dynamicTableNormal.ConstraintCount) - 1
        if minRow <= row then
            local posY = (dynamicTableNormal.GridSize.y + dynamicTableNormal.Spacing.y) * row 
            self.DOAnchor_PosY = posY
        end
    end
end