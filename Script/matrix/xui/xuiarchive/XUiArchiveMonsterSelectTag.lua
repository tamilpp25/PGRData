local XUiGridArchiveTag = require("XUi/XUiArchive/XUiGridArchiveTag")
local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiArchiveMonsterSelectTag = XLuaUiManager.Register(XLuaUi, "UiArchiveMonsterSelectTag")
local tableInsert = table.insert

function XUiArchiveMonsterSelectTag:OnEnable()
    self.InfoData = self.Base.CurInfoData
    self.EvaluateData = self.Base.CurEvaluateData
    self:SetupDynamicTable()

end

function XUiArchiveMonsterSelectTag:OnDisable()

end

function XUiArchiveMonsterSelectTag:OnStart(base)
    self.Base = base
    local taglist = {}

    if not XTool.IsTableEmpty(self.Base.MyTagIds) then
        for _, tag in pairs(self.Base.MyTagIds) do
            tableInsert(taglist, tag)
        end
    end
    self.TagIds = taglist
    self:SetButtonCallBack()
    self:InitDynamicTable()
end

function XUiArchiveMonsterSelectTag:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnSubmit.CallBack = function()
        self:OnBtnSubmitClick()
    end
end

function XUiArchiveMonsterSelectTag:OnBtnCloseClick()
    self:Close()
end

function XUiArchiveMonsterSelectTag:OnBtnSubmitClick()
    local taglist = {}

    if not XTool.IsTableEmpty(self.TagIds) then
        for _, tag in pairs(self.TagIds) do
            tableInsert(taglist, tag)
        end
    end
    
    self.Base.MyTagIds = taglist
    self.Base:SetPanelTag()
    self:Close()
end

function XUiArchiveMonsterSelectTag:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTagScroll)
    self.DynamicTable:SetProxy(XUiGridArchiveTag,self)
    self.DynamicTable:SetDelegate(self)
end

function XUiArchiveMonsterSelectTag:SetupDynamicTable()
    self.PageDatas = self._Control:GetArchiveTagList(self.Base.TagGroupId)
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiArchiveMonsterSelectTag:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
    end
end