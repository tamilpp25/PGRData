local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridRegion = XClass(nil, "XUiGridRegion")

function XUiGridRegion:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.GridCommon.gameObject:SetActive(false)

    self.IsShow = true
    self.GameObject:SetActive(true)

    self.DynamicTable = XDynamicTableNormal.New(self.SViewReward.transform)
    self.DynamicTable:SetProxy(XUiGridCommon)
    self.DynamicTable:SetDelegate(self)
end

function XUiGridRegion:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = nil
        if self.DataList then
            data = self.DataList[index]
        end

        grid.RootUi = self.RootUi
        grid:Refresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnBtnClickClick()
    end
end

function XUiGridRegion:SetMetaData(title, des, isNotBorder, rewardList)
    self.TxtRankRegion.text = title
    self.TxtRegionDesc.text = des
    self.SViewReward.gameObject:SetActive(isNotBorder)
    if isNotBorder then
        self.DataList = rewardList or {}
        self.DynamicTable:SetTotalCount(#self.DataList)
        self.DynamicTable:ReloadDataSync()
    end
end

return XUiGridRegion