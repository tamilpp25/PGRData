---@class XUiGridItemCollect
---@field BtnTabPrefab XUiComponent.XUiButton
local XUiGridItemCollect = XClass(nil, "XUiGridItemCollect")

function XUiGridItemCollect:Ctor(ui, click)
    XTool.InitUiObjectByUi(self, ui)
    self.OnClick = click

    self.BtnTabPrefab.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiGridItemCollect:Refresh(id, selectId)
    self.Id = id
    local template = XItemConfigs.GetItemCollectTemplate(id)
    self:SetSelect(id == selectId)
    self:RefreshRedPoint()
    self.BtnTabPrefab:SetRawImage(template.BigIcon)
    self.BtnTabPrefab:SetSprite(XArrangeConfigs.GeQualityPath(template.Quality))
end

function XUiGridItemCollect:SetSelect(isSelect)
    self.IsSelect = isSelect
    self.BtnTabPrefab:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiGridItemCollect:OnBtnClick()
    if self.IsSelect then
        self.BtnTabPrefab:SetButtonState(self.IsSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        return
    end

    self:SetSelect(true)
    local template = XItemConfigs.GetItemCollectTemplate(self.Id)
    if template.Type ~= XItemConfigs.ItemCollectionType.DefaultCollect then
        XDataCenter.ItemManager.MarkNewItemCollect(self.Id)
    end
    self:RefreshRedPoint()
    if self.OnClick then
        self.OnClick(self)
    end
end

function XUiGridItemCollect:RefreshRedPoint()
    self.BtnTabPrefab:ShowReddot(XDataCenter.ItemManager.CheckHasNewItemCollect(self.Id))
end

---@class UiItemCollectionMain : XLuaUi 道具收藏主界面
local UiItemCollectionMain = XLuaUiManager.Register(XLuaUi, "UiItemCollectionMain")

local DefaultIndex = 1 --进入界面默认选中

function UiItemCollectionMain:OnAwake()
    self:InitUi()
    self:InitCb()
end

function UiItemCollectionMain:OnStart()
    self.ItemIds = self:GetSortCollectIds()
    self:InitView()
end

function UiItemCollectionMain:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelMailList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridItemCollect, handler(self, self.OnSelectItem))
    self.GridMail.gameObject:SetActiveEx(false)
    
    self.PanelSort = self.TxtContent.transform.parent.parent.parent.parent
end

function UiItemCollectionMain:InitCb()
    self:BindExitBtns()
end

function UiItemCollectionMain:InitView()
    local empty = XTool.IsTableEmpty(self.ItemIds)
    self.TxtCount.text = #self.ItemIds
    self.PanelNone.gameObject:SetActiveEx(empty)
    self.TxtMailTitle.transform.parent.gameObject:SetActiveEx(not empty)
    self.PanelSort.gameObject:SetActiveEx(not empty)
    self.DynamicTable:SetDataSource(self.ItemIds)
    self.DynamicTable:ReloadDataSync(self:GetSelectIndex())

    XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.FreeGem
    , XDataCenter.ItemManager.ItemId.ActionPoint
    , XDataCenter.ItemManager.ItemId.Coin }, self.PanelAssetitems, self)
    
    XDataCenter.ItemManager.MarkFirstOpenItemCollectView()
end

function UiItemCollectionMain:OnSelectItem(grid)
    if self.GridLast then
        self.GridLast:SetSelect(false)
    end
    self.GridLast = grid
    self.SelectId = grid.Id
    self:PlayAnimation("QieHuan")
    self:RefreshDetail()
end

function UiItemCollectionMain:RefreshDetail()
    if not XTool.IsNumberValid(self.SelectId) then
        XLog.Error("刷新道具详情失败，未选中道具!!!")
        return
    end
    local template = XItemConfigs.GetItemCollectTemplate(self.SelectId)
    self.RImgIcon:SetRawImage(template.BigIcon)
    self.TxtMailTitle.text = template.Name
    self.TxtMailDate.text = XUiHelper.ReplaceTextNewLine(template.Description)
    self.TxtContent.text = XUiHelper.ReplaceTextNewLine(template.WorldDesc)
end

function UiItemCollectionMain:GetSortCollectIds()
    local ids = XDataCenter.ItemManager.GetUnlockItemCollectIds()
    if XTool.IsTableEmpty(ids) then
        return {}
    end
    table.sort(ids, function(a, b)
        local templateA = XItemConfigs.GetItemCollectTemplate(a)
        local templateB = XItemConfigs.GetItemCollectTemplate(b)

        local qualityA = templateA.Quality
        local qualityB = templateB.Quality
        if qualityA ~= qualityB then
            return qualityA > qualityB
        end

        local priorityA = templateA.Priority
        local priorityB = templateB.Priority

        if priorityA ~= priorityB then
            return priorityA < priorityB
        end

        return a < b
    end)

    return ids
end

function UiItemCollectionMain:GetSelectIndex()
    if not XTool.IsNumberValid(self.SelectId) then
        return DefaultIndex
    end

    for index, id in ipairs(self.ItemIds) do
        if id == self.SelectId then
            return index
        end
    end
    return DefaultIndex
end

function UiItemCollectionMain:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.ItemIds[index], self.SelectId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local selectId = self.SelectId or self.ItemIds[DefaultIndex]
        local grids = self.DynamicTable:GetGrids()
        for _, tmpGrid in pairs(grids or {}) do
            if tmpGrid.Id == selectId then
                tmpGrid:SetSelect(false)
                tmpGrid:OnBtnClick()
                break
            end
        end
    end
end 