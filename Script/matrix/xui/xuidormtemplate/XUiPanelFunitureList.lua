local XUiPanelFunitureList = XClass(nil, "XUiPanelFunitureList")
local XUiGridFurnitreTemplate = require("XUi/XUiDormTemplate/XUiGridFurnitreTemplate")

function XUiPanelFunitureList:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self:AddListener()
    self:InitDynamicTable()
end

function XUiPanelFunitureList:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelFunitureList:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelFunitureList:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelFunitureList:AddListener()
    self:RegisterClickEvent(self.BtnFurnitureListBack, self.OnBtnCloseClick)
end

function XUiPanelFunitureList:OnBtnCloseClick()
    self:Close()
end

function XUiPanelFunitureList:Close()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelFunitureList:Open(homeRoomData)
    self.HomeRoomData = homeRoomData
    self.PageDatas = self.HomeRoomData:GetAllFurnitures()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
    self.GameObject:SetActiveEx(true)
end

function XUiPanelFunitureList:InitDynamicTable()
    self.GridFurnitureTemplate.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridFurnitreTemplate)
    self.DynamicTable:SetDelegate(self)
end

-- 动态列表事件
function XUiPanelFunitureList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.PageDatas[index]
        grid:Refresh(data)
    end
end

return XUiPanelFunitureList