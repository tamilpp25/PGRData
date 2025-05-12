local XUiGridSkip = require("XUi/XUiTip/XUiGridSkip")
local XUiSkipTip = XLuaUiManager.Register(XLuaUi, "UiSkipTip")

function XUiSkipTip:OnAwake()
    self:InitAutoScript()
    self.PanelGridSkip.gameObject:SetActive(false)
end

function XUiSkipTip:OnStart(skipIds)
    self.GridPool = {}
    self:Refresh(skipIds)
end

function XUiSkipTip:Refresh(skipIds)
    XUiHelper.CreateTemplates(self, self.GridPool, skipIds, XUiGridSkip.New, self.PanelGridSkip, self.PanelContent, function(grid, data)
        grid:Refresh(data)
    end)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiSkipTip:InitAutoScript()
    self:AutoAddListener()
end

function XUiSkipTip:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
end

-- auto
function XUiSkipTip:OnBtnCloseClick()
    self:Close()
end