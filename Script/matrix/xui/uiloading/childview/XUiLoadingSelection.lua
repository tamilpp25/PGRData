local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiLoadingSelection = XClass(nil, "XUiLoadingSelection")

local XUiGridSelected = require("XUi/UiLoading/ChildItem/XUiGridSelected")

function XUiLoadingSelection:Ctor(uiRoot, ui)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.GridDic = {}
    self:InitUi()
end

function XUiLoadingSelection:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridSelected)
    self.DynamicTable:SetDelegate(self)
    self.GridSelectedItem.gameObject:SetActiveEx(false)
end

function XUiLoadingSelection:Refresh(selectionDic)
    self.EntityList = {}
    for i in pairs(selectionDic) do
        table.insert(self.EntityList, XMVCA.XArchive:GetArchiveCgEntity(i))
    end

    table.sort(self.EntityList, function(a, b)
        return selectionDic[a.Id] < selectionDic[b.Id]
    end)

    local count = #self.EntityList
    for _ = count + 1, XLoadingConfig.GetCustomMaxSize() do
        table.insert(self.EntityList, false)
    end

    self.DynamicTable:SetDataSource(self.EntityList)
    self.DynamicTable:ReloadDataSync()

    self:MoveInto(count)
end

function XUiLoadingSelection:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateCg(self.EntityList[index])
        self.GridDic[index] = grid
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if not self.EntityList[index] then return end
        self.UiRoot:OnGridClick(self.EntityList[index].Id)
    end
end

function XUiLoadingSelection:MoveInto(index)
    if not self.GridDic[index] then return end
    local gridRect = self.GridDic[index].Transform
    local tarPos = self.Content.localPosition
    local tarPosX = self.Transform.rect.width * 1/2 + ((1/2 - index / #self.EntityList) * self.Content.sizeDelta.x) - 35
    if gridRect.localPosition.x < 0 then
        tarPosX = (self.Content.sizeDelta.x - self.Transform.rect.width) / 2
    end
    tarPos.x = tarPosX

    self.SRSelectedList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    XUiHelper.DoMove(self.Content, tarPos, 0.5, XUiHelper.EaseType.Sin, function()
        self.SRSelectedList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    end)
end

return XUiLoadingSelection