local XUiPanelOwnRole = require("XUi/XUiTheatre/UnlockTips/XUiPanelOwnRole")
local XUiPanelPrerogative = require("XUi/XUiTheatre/UnlockTips/XUiPanelPrerogative")
local XUiPanelNewTalent = require("XUi/XUiTheatre/UnlockTips/XUiPanelNewTalent")

--肉鸽玩法弹窗
local XUiTheatreUnlockTips = XLuaUiManager.Register(XLuaUi, "UiTheatreUnlockTips")

function XUiTheatreUnlockTips:OnAwake()
    self.OwnRolePanel = XUiPanelOwnRole.New(self.PanelOwnRole)
    self.PrerogativePanel = XUiPanelPrerogative.New(self.PanelPrerogative)
    self.NewTalentPanel = XUiPanelNewTalent.New(self.PanelNewTalent)
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiTheatreUnlockTips:OnStart(data)
    self.OwnRolePanel:CheckShow(data)
    self.PrerogativePanel:CheckShow(data)
    self.NewTalentPanel:CheckShow(data)

    self.CloseCb = data.CloseCb
end

function XUiTheatreUnlockTips:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end