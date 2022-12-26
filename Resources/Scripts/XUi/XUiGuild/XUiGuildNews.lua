local XUiGuildNews = XLuaUiManager.Register(XLuaUi, "UiGuildNews")
local XUiGridNewsItem = require("XUi/XUiGuild/XUiChildItem/XUiGridNewsItem")

function XUiGuildNews:OnAwake()
    self.BtnClose.CallBack = function() self:OnBtnBackClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnBackClick() end
    self:InitList()
end

function XUiGuildNews:OnEnable()
    self:OnRefresh()
end

function XUiGuildNews:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTreasureGrade)
    self.DynamicTable:SetProxy(XUiGridNewsItem)
    self.DynamicTable:SetDelegate(self)
end

function XUiGuildNews:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        if not data then
            return
        end
        grid:OnRefresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        -- grid:CurStatus()
    end
end

function XUiGuildNews:OnDisable()
end

function XUiGuildNews:OnBtnBackClick()
    self:Close()
end

-- 更新数据
function XUiGuildNews:OnRefresh()
    self.ListData = XDataCenter.GuildManager.GetGuildListRecruitDatas() or {}
    if next(self.ListData) == nil then
        self.DynamicTable:SetDataSource({})
        self.DynamicTable:ReloadDataASync(1)
        self.TxtNoNew.gameObject:SetActiveEx(true)
        return
    end

    self.TxtNoNew.gameObject:SetActiveEx(false)
    self.DynamicTable:SetDataSource(self.ListData)
    self.DynamicTable:ReloadDataASync(1)
end