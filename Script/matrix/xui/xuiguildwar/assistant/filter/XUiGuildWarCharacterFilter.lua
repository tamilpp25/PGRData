local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelCommonCharacterFilterV2P6 = require("XUi/XUiCommonCharacterOptimization/XUiPanelCommonCharacterFilterV2P6")

---@class XUiGuildWarCharacterFilter:XUiPanelCommonCharacterFilterV2P6
local XUiGuildWarCharacterFilter = XClass(XUiPanelCommonCharacterFilterV2P6, "XUiGuildWarCharacterFilter")

function XUiGuildWarCharacterFilter:Ctor()
    -- 有两个dynamicTable
    self.DynamicTableNormal = nil
    self.DynamicTableSupport = nil

    self.DynamicTable = nil
end

function XUiGuildWarCharacterFilter:_InitDynamicTable()
end

function XUiGuildWarCharacterFilter:InitDynamicTable(grid1, grid2, uiList1, uiList2)
    self.DynamicTableNormal = XDynamicTableNormal.New(uiList1)
    self.DynamicTableNormal:SetProxy(grid1, self.Parent, self, self.OnSeleCharacterCb, self.RefreshGridFuns)
    self.DynamicTableNormal:SetDelegate(self)
    self.DynamicTableNormal:SetDynamicEventDelegate(function(event, index, grid)
        self:OnDynamicTableEventCharacterList(event, index, grid)
    end)

    self.DynamicTableSupport = XDynamicTableNormal.New(uiList2)
    self.DynamicTableSupport:SetProxy(grid2, self.Parent, self, self.OnSeleCharacterCb, self.RefreshGridFuns)
    self.DynamicTableSupport:SetDelegate(self)
    self.DynamicTableSupport:SetDynamicEventDelegate(function(event, index, grid)
        self:OnDynamicTableEventCharacterList(event, index, grid)
    end)

    -- 默认
    self.DynamicTable = self.DynamicTableNormal
end

function XUiGuildWarCharacterFilter:ChangeDynamicTable()
    if self:IsTagSupport() then
        self.DynamicTable = self.DynamicTableSupport
    else
        self.DynamicTable = self.DynamicTableNormal
    end
end

function XUiGuildWarCharacterFilter:ShowEmpty(value, ...)
    if self:IsTagSupport() then
        self.Super.ShowEmpty(self, false)
    else
        self.Super.ShowEmpty(self, value, ...)
    end
end

-- 外部手动调用，开启支援选项
function XUiGuildWarCharacterFilter:ImportSupportList(characterList)
    -- 好友/公会支援 数据列表
    self.SupportCharacterList = characterList
    --self.ImportListTrigger = true
end

return XUiGuildWarCharacterFilter
