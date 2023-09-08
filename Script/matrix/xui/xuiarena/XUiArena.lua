local XUiArena = XLuaUiManager.Register(XLuaUi, "UiArena")

local XUiPanelActive = require("XUi/XUiArena/XUiPanelActive")
local XUiPanelPrepare = require("XUi/XUiArena/XUiPanelPrepare")

function XUiArena:OnAwake()
    self:AutoAddListener()
end

function XUiArena:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    -- 依靠uiNode:Open()来激活
    self.PanelActive.gameObject:SetActiveEx(false)
    self.PanelPrepare.gameObject:SetActiveEx(false)
    
    ---@type XUiPanelActive
    self.ActivePanel = XUiPanelActive.New(self.PanelActive, self)
    ---@type XUiPanelPrepare
    self.PreparePanel = XUiPanelPrepare.New(self.PanelPrepare, self)
end

function XUiArena:OnEnable()
    XDataCenter.ArenaManager.OpenArenaActivityResult()
    self:Refresh()

    -- 刷新任务红点
    if self.ActivePanel then
        self.ActivePanel:CheckRedPoint()
    end
end

function XUiArena:OnDestroy()
    self.ActivePanel:UnBindTimer()
    self.ActivePanel:Close()
end

function XUiArena:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, "Arena")
end

function XUiArena:OnBtnBackClick()
    self:Close()
end

function XUiArena:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArena:Refresh()
    if not self.GameObject:Exist() then
        return
    end

    local status = XDataCenter.ArenaManager.GetArenaActivityStatus()
    if status == XArenaActivityStatus.Fight then
        if self.ActivePanel:IsNodeShow() then
            XDataCenter.ArenaManager.RequestGroupMember()
            return
        end
        self.ActivePanel:Open()
        self.PreparePanel:Close()
    else
        self.PreparePanel:Open()
        self.ActivePanel:Close()
    end
end