-- 白色情人节约会活动邀约界面成员动态列表控件
local XUiWhiteValenInviteMemberDynamicTable = XClass(nil, "XUiWhiteValenInviteMemberDynamicTable")

--================
--构造函数
--================
function XUiWhiteValenInviteMemberDynamicTable:Ctor(rootUi, ui)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, ui)
    self:InitDynamicTable()
end
--================
--初始化动态列表
--================
function XUiWhiteValenInviteMemberDynamicTable:InitDynamicTable()
    local XGrid = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenInviteMemberDynamicGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XGrid)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiWhiteValenInviteMemberDynamicTable:OnDynamicTableEvent(event, index, grid)
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
--刷新控件
--================
function XUiWhiteValenInviteMemberDynamicTable:UpdateData(memberList)
    self.MemberList = memberList
    self.DynamicTable:SetDataSource(self.MemberList)
    self.DynamicTable:ReloadDataASync(1)
end
--================
--列表项选中事件
--================
function XUiWhiteValenInviteMemberDynamicTable:SetSelect(grid)
    if self.CurGrid and self.CurGrid ~= grid then
        self.CurGrid:SetIsSelect(false)
    end
    self.CurGrid = grid
    self.CurrentIndex = grid.GridIndex
    self.RootUi:SetInviteChara(grid.Chara)
end
return XUiWhiteValenInviteMemberDynamicTable