local XUiGridCreate = require("XUi/XUiDorm/XUiFurnitureBuild/XUiGridCreate")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
-- 家具建造子界面
XUiPanelCreate = XClass(nil, "XUiPanelCreate")

function XUiPanelCreate:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPanelCreate:Init(cfg)
    self.CreateGridDatas = cfg
    self.GridCreate.gameObject:SetActive(false)

    if not self.CreateGridDatas then
        XLog.Warning("XUiPanelCreate:Init error: cfg is nil")
    end

    if not self.DynamicTableCreate then
        self.DynamicTableCreate = XDynamicTableNormal.New(self.ScrCreate.gameObject)
        self.DynamicTableCreate:SetProxy(XUiGridCreate)
        self.DynamicTableCreate:SetDelegate(self)
    end

    self.DynamicTableCreate:SetDataSource(self.CreateGridDatas)
    self.DynamicTableCreate:ReloadDataASync()
end

-- [列表事件]
function XUiPanelCreate:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Rename(index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        self:OnRefreshCreate(index, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnClose()
    end
end

function XUiPanelCreate:OnRefreshCreate(index, grid)
    local data = self.CreateGridDatas[index]
    if not data then return end
    grid:Init(data, self)
end

function XUiPanelCreate:UpdateCreateGridByPos(pos)
    if not self.CreateGridDatas then return end

    local index = 1
    for k, v in pairs(self.CreateGridDatas) do
        if v.Pos == pos then
            index = k
            break
        end
    end

    if not self.DynamicTableCreate then return end
    local grid = self.DynamicTableCreate:GetGridByIndex(index)
    if grid then
        grid:Init(self.CreateGridDatas[index], self)
    end
end

function XUiPanelCreate:SetPanelActive(value)
    self.GameObject:SetActive(value)
end

return XUiPanelCreate