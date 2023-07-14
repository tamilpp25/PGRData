local XUiHelp = XLuaUiManager.Register(XLuaUi, "UiHelp")
local XUiGridHelpCourse = require("XUi/XUiHelpCourse/XUiGridHelpCourse")

function XUiHelp:OnAwake()

end

function XUiHelp:OnStart(config, cb)
    self.Config = config
    self.Cb = cb
    self:RegisterClickEvent(self.BtnMask, self.OnBtnMaskClick)
    self:InitDynamicTable()
end

function XUiHelp:InitDynamicTable()
    self.DynamicTable = XDynamicTableCurve.New(self.PanelHelp.gameObject)
    self.DynamicTable:SetProxy(XUiGridHelpCourse)
    self.DynamicTable:SetDelegate(self)
end

function XUiHelp:OnEnable()
    if not self.Config then
        return
    end
    self.Icons = self.Config.ImageAsset
    self.Length = #self.Icons
    self.DynamicTable:SetDataSource(self.Config.ImageAsset)
    self.DynamicTable:ReloadData()
end

--动态列表事件
function XUiHelp:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.Icons[index + 1], index + 1, self.Length)
    end
end

function XUiHelp:OnBtnMaskClick()
    if self.Cb then
        self.Cb()
    end
    self:Close()
end