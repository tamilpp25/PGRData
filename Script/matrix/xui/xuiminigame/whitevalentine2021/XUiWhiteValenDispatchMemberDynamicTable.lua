--
local XUiWhiteValenDispatchMemberDynamicTable = XClass(nil, "XUiWhiteValenDispatchMemberDynamicTable")
--================
--构造函数
--================
function XUiWhiteValenDispatchMemberDynamicTable:Ctor(rootUi, ui)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, ui)
    self.CharaManager = XDataCenter.WhiteValentineManager.GetCharaManager()
    self:InitDynamicTable()
end
--================
--初始化动态列表
--================
function XUiWhiteValenDispatchMemberDynamicTable:InitDynamicTable()
    local XGrid = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenDispatchMemberDynamicGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XGrid)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiWhiteValenDispatchMemberDynamicTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, grid.DynamicGrid.gameObject)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.MemberList and self.MemberList[index] then
            grid:RefreshData(self.MemberList[index], index)
            if self.CurrentIndex and self.CurrentIndex == index then
                grid:SetIsSelect(true)
            end
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
    end
end
--================
--给动态列表赋值
--================
function XUiWhiteValenDispatchMemberDynamicTable:GuideGetDynamicTableIndex(id)
    for index, member in pairs(self.MemberList) do
        if member:GetCharaId() == tonumber(id) then
            return index
        end
    end
    return -1
end
--================
--刷新控件
--================
function XUiWhiteValenDispatchMemberDynamicTable:UpdateData(attrType)
    self.MemberList = self.CharaManager:GetCharaListSortByDispatching(attrType)
    self.DynamicTable:SetDataSource(self.MemberList)
    self.DynamicTable:ReloadDataASync(1)
end
--================
--列表项选中事件
--================
function XUiWhiteValenDispatchMemberDynamicTable:SetSelect(grid)
    if self.CurGrid and self.CurGrid ~= grid then
        self.CurGrid:SetIsSelect(false)
    end
    self.CurGrid = grid
    self.CurrentIndex = grid.GridIndex
    self.RootUi:SetDispatchChara(grid.Chara)
end

return XUiWhiteValenDispatchMemberDynamicTable