XUiPanelSViewFurniture = XClass(nil, "XUiPanelSViewFurniture")

function XUiPanelSViewFurniture:Ctor(ui, rootUi, roomFurnitrueCount, roomType)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.IsActive = true
    self.RoomType = roomType
    self.RoomFurnitureCount = roomFurnitrueCount
    self.Items = {}
    self.ControlLimit = CS.XGame.ClientConfig:GetInt("UiGridFurnitureControlLimit")
    self:InitAutoScript()
    self:Init()
end

function XUiPanelSViewFurniture:Init()
    self.ScrollRect = self.Transform:GetComponent("ScrollRect")
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetProxy(XUiGridFurniture)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelSViewFurniture:OnDrag(eventData)
    if self.ScrollRect then
        self.ScrollRect:OnDrag(eventData);
    end
end

function XUiPanelSViewFurniture:OnBeginDrag(eventData)
    if self.ScrollRect then
        self.ScrollRect:OnBeginDrag(eventData);
    end
end

function XUiPanelSViewFurniture:OnEndDrag(eventData)
    if self.ScrollRect then
        self.ScrollRect:OnEndDrag(eventData);
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelSViewFurniture:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelSViewFurniture:AutoInitUi()
    self.GridFurniture = self.Transform:Find("Viewport/Content/GridFurniture")
end

function XUiPanelSViewFurniture:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelSViewFurniture:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelSViewFurniture:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelSViewFurniture:AutoAddListener()
    self.AutoCreateListeners = {}
end
-- auto
function XUiPanelSViewFurniture:HidePanel()
    if not self.IsActive then return end

    self.GameObject:SetActive(false)
    self.IsActive = false

end

function XUiPanelSViewFurniture:ShowPanel()
    if self.IsActive then return end

    self.GameObject:SetActive(true)
    self.IsActive = true

end

--重载数据
function XUiPanelSViewFurniture:UpdateItems(datas)
    if #datas > 0 then
        self:ShowPanel()
        self.Items = datas
        self.DynamicTable:SetDataSource(self.Items)
        self.DynamicTable:ReloadDataASync()
    else
        self:HidePanel()
    end
end

--动态列表事件
function XUiPanelSViewFurniture:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi, self, self.RoomFurnitureCount)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Items[index]
        if data == nil then return end
        grid:UpdateData(data, self.RoomType)
    end
end

--更新家具信息
function XUiPanelSViewFurniture:UpdateGoods(itemId)
    for k, v in pairs(self.Items) do
        if v.Id == itemId then
            local grid = self.DynamicTable:GetGridByIndex(k)
            grid:UpdateData(v, self.RoomType)
        end
    end
end

return XUiPanelSViewFurniture