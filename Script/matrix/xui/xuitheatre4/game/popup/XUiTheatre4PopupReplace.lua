local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTheatre4PropCard = require("XUi/XUiTheatre4/Common/XUiGridTheatre4PropCard")
-- 藏品替换弹窗
---@class XUiTheatre4PopupReplace : XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4PopupReplace = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupReplace")

function XUiTheatre4PopupReplace:OnAwake()
    self._Control:RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self._Control:RegisterClickEvent(self, self.ImgBtnHuiShou, self.OnBtnCloseClick)
    self._Control:RegisterClickEvent(self, self.BtnMap, self.OnBtnMapClick)
    self:InitDynamicTable()
    self.GridPropCardOld.gameObject:SetActiveEx(false)
    self.GridPropCard.gameObject:SetActiveEx(false)
end

---@param oldItemId number 旧藏品id
function XUiTheatre4PopupReplace:OnStart(oldItemId, replaceCallback)
    self.OldItemId = oldItemId
    self.IsSelectReplace = replaceCallback ~= nil
    self.ReplaceCallback = replaceCallback
    self.ItemType = XEnumConst.Theatre4.AssetType.Item
    self:InitCloseTag()
    self:InitOldPropCard()
end

function XUiTheatre4PopupReplace:OnEnable()
    self:SetupDynamicTable()
    self:PlayAnimation("PopupEnable")
end

function XUiTheatre4PopupReplace:InitOldPropCard()
    if not self.PanelOldPropCard then
        ---@type XUiGridTheatre4PropCard
        self.PanelOldPropCard = XUiGridTheatre4PropCard.New(self.GridPropCardOld, self)
    end
    self.PanelOldPropCard:Open()
    self.PanelOldPropCard:Refresh({ Id = self.OldItemId, Type = self.ItemType })
    self.PanelOldPropCard:SetImgNow(true)
end

function XUiTheatre4PopupReplace:InitCloseTag()
    self.BtnClose.gameObject:SetActiveEx(self.IsSelectReplace or false)
    self.ImgBtnHuiShou.gameObject:SetActiveEx(not self.IsSelectReplace)
    self.BtnMap.gameObject:SetActiveEx(not self.IsSelectReplace)
    if not self.IsSelectReplace then
        local count = self._Control:GetItemBackPrice(self.OldItemId)
        self.TxtSell.text = "+" .. count
        self.RImgIcon:SetRawImage(self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold))
    end
end

function XUiTheatre4PopupReplace:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ListReward)
    self.DynamicTable:SetProxy(XUiGridTheatre4PropCard, self, handler(self, self.OnSelectCallback), handler(self, self.OnYesCallback))
    self.DynamicTable:SetDelegate(self)
end

-- 选择藏品信息列表
---@return { UId:number, Id:number, Type:number, Index:number }[]
function XUiTheatre4PopupReplace:GetItemDataList()
    ---@type { UId:number, ItemId:number }[]
    local itemDataList = self._Control:GetCountLimitItemDataList()
    if XTool.IsTableEmpty(itemDataList) then
        return nil
    end
    local data = {}
    for _, itemData in pairs(itemDataList) do
        table.insert(data, { UId = itemData.UId, Id = itemData.ItemId, Type = self.ItemType, Index = itemData.UId })
    end
    return data
end

function XUiTheatre4PopupReplace:SetupDynamicTable()
    self.DataList = self:GetItemDataList()
    if XTool.IsTableEmpty(self.DataList) then
        return
    end
    self._IsRefreshing = true
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridTheatre4PropCard
function XUiTheatre4PopupReplace:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetAlpha(0)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self._IsRefreshing then
            grid:SetAlpha(0)
        end
        grid:Refresh(self.DataList[index])
        local isSelect = self.CurSelectIndex and self.CurSelectIndex == grid:GetIndex()
        grid:SetIsSelect(isSelect)
        grid:SetBtnYes(isSelect)
        grid:SetSellTag(isSelect)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayPropCardAnimation()
        self._IsRefreshing = false
    end
end

-- 选择回调
---@param grid XUiGridTheatre4PropCard
function XUiTheatre4PopupReplace:OnSelectCallback(grid)
    if self.CurSelectIndex == grid:GetIndex() then
        return
    end
    self.CurSelectIndex = grid:GetIndex()
    -- 刷新选择状态
    for _, v in pairs(self.DynamicTable:GetGrids()) do
        v:SetIsSelect(v:GetIndex() == self.CurSelectIndex)
        v:SetBtnYes(v:GetIndex() == self.CurSelectIndex)
        v:SetSellTag(v:GetIndex() == self.CurSelectIndex)
    end
end

-- 确认回调
function XUiTheatre4PopupReplace:OnYesCallback(index)
    if self.IsSelectReplace then
        if self.ReplaceCallback then
            self.ReplaceCallback(index)
        end
        return
    end
    -- 替换藏品
    self._Control:ReplaceItemRequest(self.OldItemId, index, function()
        self._Control:CheckNeedOpenNextPopup(self.Name, true)
    end)
end

-- 关闭界面 自动视为放弃替换
function XUiTheatre4PopupReplace:OnBtnCloseClick()
    if self.IsSelectReplace then
        -- 放弃替换
        self:Close()
    else
        -- 回收当前藏品
        self._Control:WaitItemRecyclingRequest(self.OldItemId, function()
            self._Control:CheckNeedOpenNextPopup(self.Name, true)
        end)
    end
end

function XUiTheatre4PopupReplace:PlayPropCardAnimation()
    local grids = self.DynamicTable:GetGrids()
    local startIndex = self.DynamicTable:GetStartIndex()

    if not XTool.IsTableEmpty(grids) then
        XLuaUiManager.SetMask(true, self.Name)
        RunAsyn(function()
            for i = startIndex, table.nums(grids) + startIndex - 1 do
                local grid = grids[i]

                if grid then
                    grid:PlayPropCardAnimation()
                    asynWaitSecond(0.04)
                end
            end
            XLuaUiManager.SetMask(false, self.Name)
        end)
    end
end

function XUiTheatre4PopupReplace:OnBtnMapClick()
    self._Control:ShowViewMapPanel(XEnumConst.Theatre4.ViewMapType.ReplaceItem)
end

function XUiTheatre4PopupReplace:GetPopupArgs()
    return { self.OldItemId }
end

return XUiTheatre4PopupReplace
