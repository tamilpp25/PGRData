--==============
--超限乱斗核心强化主页面
--==============
local XUiSuperSmashBrosCore = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosCore")

function XUiSuperSmashBrosCore:InitPanels()
    self:InitPanelAssets() --资源显示栏
    self:InitBaseBtns() --基础界面按钮
    self:InitPanelCoreTabs() --核心页签列表
    self:InitPanelDetails() --核心详细显示界面
end

function XUiSuperSmashBrosCore:InitPanelAssets()
    --第一期不需要资源栏
end

function XUiSuperSmashBrosCore:InitBaseBtns()
    self.BtnMainUi.CallBack = handler(self, self.OnClickBtnMainUi)
    self.BtnBack.CallBack = handler(self, self.OnClickBtnBack)
    self:BindHelpBtn(self.BtnHelp, "SuperSmashBrosHelp")
end

--==============
--主界面按钮
--==============
function XUiSuperSmashBrosCore:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end
--==============
--返回按钮
--==============
function XUiSuperSmashBrosCore:OnClickBtnBack()
    self:Close()
end

function XUiSuperSmashBrosCore:InitPanelCoreTabs()
    local script = require("XUi/XUiSuperSmashBros/Core/Panels/XUiSSBCoreTabs")
    self.CoreTab = script.New(self.PanelTabGroup, function(core) self:OnSelectCore(core) end)
end

function XUiSuperSmashBrosCore:InitPanelDetails()
    local script = require("XUi/XUiSuperSmashBros/Core/Panels/XUiSSBCoreDetails")
    self.Details = script.New(self.PanelDetails)
end

function XUiSuperSmashBrosCore:OnStart(core)
    XDataCenter.SuperSmashBrosManager.SortCores()
    self.CurrentCore = core or XDataCenter.SuperSmashBrosManager.GetOneCore()
    self:InitPanels()
    self:SetActivityTimeLimit()
end

function XUiSuperSmashBrosCore:OnEnable()
    XUiSuperSmashBrosCore.Super.OnEnable(self)
    self.CoreTab:Refresh(self.CurrentCore and self.CurrentCore:GetId() or 1)
end
--==============
--选中核心页签时
--==============
function XUiSuperSmashBrosCore:OnSelectCore(core)
    self.CurrentCore = core
    self.Details:Refresh(core)
    self:PlayAnimation("QieHuan")
end

function XUiSuperSmashBrosCore:OnGetEvents()
    return { XEventId.EVENT_SSB_CORE_REFRESH}
end

function XUiSuperSmashBrosCore:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_SSB_CORE_REFRESH then
        local isCoreLevelUp = args[1]
        self.Details:OnCoreRefresh(isCoreLevelUp)
    end
end
--==============
--设置活动关闭时处理
--==============
function XUiSuperSmashBrosCore:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperSmashBrosManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SuperSmashBrosManager.OnActivityEndHandler()
            end
        end)
end