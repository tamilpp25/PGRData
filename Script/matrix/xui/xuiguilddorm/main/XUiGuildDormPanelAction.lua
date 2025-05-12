local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--######################## XUiGuildDormPanelActionItem ########################
local XUiGuildDormPanelActionItem = XClass(nil, "XUiGuildDormPanelActionItem")

function XUiGuildDormPanelActionItem:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiGuildDormPanelActionItem:SetData(data)
    self.RImgIcon:SetRawImage(data.Icon)
    self.TxtName.text = data.ActionUiName
end

--######################## XUiGuildDormPanelAction ########################
local XUiGuildDormPanelAction = XClass(nil, "XUiGuildDormPanelAction")

function XUiGuildDormPanelAction:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.DynamicSelectTable = XDynamicTableNormal.New(self.ActionList)
    self.DynamicSelectTable:SetProxy(XUiGuildDormPanelActionItem)
    self.DynamicSelectTable:SetDelegate(self)
    self.GridAction.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    self.CloseCallback = nil
end

function XUiGuildDormPanelAction:Open(cb)
    self.GameObject:SetActiveEx(true)
    local configs = XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.GuildDormPlayAction)
    self.DynamicSelectTable:SetDataSource(configs)
    self.DynamicSelectTable:ReloadDataSync(1)
    self.CloseCallback = cb
end

function XUiGuildDormPanelAction:Close()
    self.GameObject:SetActiveEx(false)
    if self.CloseCallback then
        self.CloseCallback()
    end
end

function XUiGuildDormPanelAction:OnDynamicTableEvent(event, index, grid)
    local data = self.DynamicSelectTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        XDataCenter.GuildDormManager.RequestPlayAction(data.Id)
        self:Close()
    end
end

return XUiGuildDormPanelAction