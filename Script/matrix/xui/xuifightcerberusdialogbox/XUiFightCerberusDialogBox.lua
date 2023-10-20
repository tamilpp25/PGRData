local XUiFightCerberusDialogBox = XLuaUiManager.Register(XLuaUi, "UiFightCerberusDialogBox")
local XUiFightCerberusDialogBoxGrid = require("XUi/XUiFightCerberusDialogBox/XUiFightCerberusDialogBoxGrid")

function XUiFightCerberusDialogBox:OnAwake()
    self.Grid = XUiFightCerberusDialogBoxGrid.New()
end

function XUiFightCerberusDialogBox:OnEnable()
    self.Grid:OnEnable()
end

function XUiFightCerberusDialogBox:OnDisable()
    self.Grid:OnDisable()
end

function XUiFightCerberusDialogBox:Show(id)
    self.Grid:Refresh(self.PanelDialog, id)
end

function XUiFightCerberusDialogBox:Close()
    self.Grid:Close()
    self.Super.Close(self)
end 