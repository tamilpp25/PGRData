local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--================
--我方角色头像列表
--================
local XUiSSBPickCharaHeadList = XClass(nil, "XUiSSBPickCharaHeadList")

function XUiSSBPickCharaHeadList:Ctor(ui, panel)
    self.Panel = panel
    self.Mode = self.Panel.Mode
    XTool.InitUiObjectByUi(self, ui)
    self.GridCharaHead.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end
--================
--初始化动态列表
--================
function XUiSSBPickCharaHeadList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local gridProxy = require("XUi/XUiSuperSmashBros/Pick/Grids/XUiSSBPickGridCharaHead")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiSSBPickCharaHeadList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataList and self.DataList[index] then
            grid:Refresh(self.DataList[index], self.TeamData)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnGridSelect(grid)
    end
end
--================
--刷新动态列表
--================
function XUiSSBPickCharaHeadList:Refresh(_, changePos, dataList)
    self.TeamData = XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(self.Mode:GetId())
    self.ChangePos = changePos
    self:CreateDataList(dataList)
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end
--================
--建立数据列表
--================
function XUiSSBPickCharaHeadList:CreateDataList(dataList)
    -- 这边也要处理彩蛋角色，选角池子界面直接删除彩蛋角色
    local dataListWithoutEgg = {}
    for key, role in pairs(dataList) do
        if not role:IsSmashEggRobot() then
            table.insert(dataListWithoutEgg, role)
        end
    end

    self.DataList = { [1] = {RandomGrid = true}}
    for _, role in pairs(dataListWithoutEgg) do
        table.insert(self.DataList, role)
    end
end
--================
--选中项
--================
function XUiSSBPickCharaHeadList:OnGridSelect(grid)
    local roleId = grid:GetRoleId() -- 若是-1则表示随机
    if XDataCenter.SuperSmashBrosManager.SetTeamAssistanceMember(self.Mode, roleId, self.ChangePos) then
        self.Panel.RootUi:SwitchPage(XSuperSmashBrosConfig.PickPage.Pick)
    end
end

function XUiSSBPickCharaHeadList:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiSSBPickCharaHeadList:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiSSBPickCharaHeadList