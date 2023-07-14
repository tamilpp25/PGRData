local XUiPanelBlackView = require("XUi/XUiSocial/Black/XUiPanelBlackView")
local XUiPanelTips = require("XUi/XUiSocial/PanelTips/XUiPanelTips")

local XUiSocial = XLuaUiManager.Register(XLuaUi, "UiSocial")

XUiSocial.BtnTabIndex = {
    MainContact = 1,
    WaitPass = 2,
    MainAddContact = 3,
    Black = 4,
}

function XUiSocial:OnAwake()
    XTool.InitUiObject(self)
    self:InitAutoScript()
end

function XUiSocial:OnStart(onLoadCompleteCB, defaultIndex)
    self.PrivateChatViewPanel = XUiPanelPrivateChatView.New(self, self.PanelPrivateChatView, handler(self, self.OnBtnBackClick))
    self.ContactViewPanel = XUiPanelContactView.New(self.PanelContactView, self)
    self.WaitForPassViewPanel = XUiPanelWaitForPassView.New(self.PanelWaitForPassView, self)
    self.AddContactViewPanel = XUiPanelAddContactView.New(self.PanelAddContactView, self)
    self.BlackViewPanel = XUiPanelBlackView.New(self.PanelBlacklistView, self, handler(self, self.InsertPanelTipsDesc))
    self.XUiPanelDaily = XUiPanelDaily.New(self.PanelDaily, self)
    self.XUiPanelDaily:SetIsShow(false)
    self.XUiPanelTips = XUiPanelTips.New(self.PanelTips, self)
    self.XUiPanelTips:Hide()

    self.OnLoadCompleteCB = onLoadCompleteCB

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self:InitSubPanel()

    local tabGroup = {
        self.BtnMainContact,
        self.BtnMainWaitPass,
        self.BtnMainAddContact,
        self.BtnMainBlacklist,
    }
    self.PanelButtons:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)

    XRedPointManager.AddRedPointEvent(self.BtnMainContact, self.RefreshContactRedDot, self, { XRedPointConditions.Types.CONDITION_FRIEND_CONTACT })
    XRedPointManager.AddRedPointEvent(self.BtnMainWaitPass, self.RefreshWaitPassRedDot, self, { XRedPointConditions.Types.CONDITION_FRIEND_WAITPASS })

    local selectIndex = defaultIndex or self.BtnTabIndex.MainContact
    self.PanelButtons:SelectIndex(selectIndex)
end

function XUiSocial:SetSelectedIndex(index)
    self.PanelButtons:SelectIndex(index)
end

function XUiSocial:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FRIEND_OPEN_PRIVATE_VIEW, self.OpenPrivateChatView, self)
    if self.OnLoadCompleteCB then
        self.OnLoadCompleteCB()
        self.OnLoadCompleteCB = nil
    end

    CS.XScheduleManager.ScheduleOnce(function()
        self.PrivateChatViewPanel:OnEnable()
    end, 1)
end

function XUiSocial:OnDestroy()
    self.PrivateChatViewPanel:OnClose()
    self.ContactViewPanel:OnClose()
    self.WaitForPassViewPanel:OnClose()
    self.AddContactViewPanel:OnClose()
    self.XUiPanelDaily:OnClose()
    self.BlackViewPanel:OnClose()
    self.XUiPanelTips:Hide()
    XDataCenter.PersonalInfoManager.OnDispose()
    XEventManager.RemoveEventListener(XEventId.EVENT_FRIEND_OPEN_PRIVATE_VIEW, self.OpenPrivateChatView, self)
end

function XUiSocial:OnOpenSubPanel(panel)
    for index = 1, #self.PanelViews do
        self.PanelViews[index]:Hide()
    end
    panel:Show()
end

--更新社交界面的 联系人红点
function XUiSocial:RefreshContactRedDot(count)
    self.BtnMainContact:ShowReddot(count >= 0)
end

--更新等待通过界面的 红点
function XUiSocial:RefreshWaitPassRedDot(count)
    self.BtnMainWaitPass:ShowReddot(count >= 0)
end

function XUiSocial:OnClickTabCallBack(tabIndex)
    if self.SelectedIndex and self.SelectedIndex == tabIndex then
        return
    end
    self.SelectedIndex = tabIndex

    if tabIndex == self.BtnTabIndex.MainContact then
        --点击联系人
        self:OnOpenSubPanel(self.ContactViewPanel)
    elseif tabIndex == self.BtnTabIndex.WaitPass then
        --等待通过
        self:OnOpenSubPanel(self.WaitForPassViewPanel)
        XDataCenter.SocialManager.ResetWaitPassLocalMap()
        XDataCenter.SocialManager.ResetApplyCount()
    elseif tabIndex == self.BtnTabIndex.MainAddContact then
        --增加联系人
        self:OnOpenSubPanel(self.AddContactViewPanel)
    elseif tabIndex == self.BtnTabIndex.Black then
        --黑名单
        self:OnOpenSubPanel(self.BlackViewPanel)
    end

    self.XUiPanelTips:Hide()
    if self.BtnHelp then
        self.BtnHelp.gameObject:SetActiveEx(tabIndex == self.BtnTabIndex.Black)
    end
end

function XUiSocial:InitSubPanel()
    self.PanelViews = {}
    table.insert(self.PanelViews, self.ContactViewPanel)
    table.insert(self.PanelViews, self.WaitForPassViewPanel)
    table.insert(self.PanelViews, self.AddContactViewPanel)
    table.insert(self.PanelViews, self.BlackViewPanel)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiSocial:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiSocial:AutoInitUi()
    -- self.PanelAddContactView = self.Transform:Find("SafeAreaContentPane/PanelAddContactView")
    -- self.PanelContactView = self.Transform:Find("SafeAreaContentPane/PanelContactView")
    -- self.BtnBack = self.Transform:Find("SafeAreaContentPane/PanelCharTopButton/BtnBack"):GetComponent("Button")
    -- self.PanelWaitForPassView = self.Transform:Find("SafeAreaContentPane/PanelWaitForPassView")
    -- self.PanelBg3d = self.Transform:Find("FullScreenBackground/PanelBg3d")
    -- self.BtnMainUi = self.Transform:Find("SafeAreaContentPane/PanelCharTopButton/BtnMainUi"):GetComponent("Button")
    -- self.PanelAsset = self.Transform:Find("SafeAreaContentPane/PanelAsset")
    -- self.PanelAllChatView = self.Transform:Find("SafeAreaContentPane/PanelAllChatView")
    -- self.PanelPrivateChatView = self.Transform:Find("SafeAreaContentPane/PanelPrivateChatView")
    -- self.PanelEmoji = self.Transform:Find("SafeAreaContentPane/PanelEmoji")
    -- self.GridEmoji = self.Transform:Find("SafeAreaContentPane/PanelEmoji/EmojiList/GridEmoji")
    -- self.PanelDaily = self.Transform:Find("SafeAreaContentPane/PanelDaily")
    -- self.BtnDaily = self.Transform:Find("SafeAreaContentPane/PanelButtons/BtnDaily"):GetComponent("Button")
    -- self.PanelButtons = self.Transform:Find("SafeAreaContentPane/PanelButtons"):GetComponent("XUiButtonGroup")
end

function XUiSocial:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiSocial:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiSocial:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiSocial:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnDaily, self.OnBtnBtnDailyClick)
    if self.BtnHelp then
        self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    end
end
-- auto

function XUiSocial:OnBtnHelpClick()
    XUiManager.ShowHelpTip("SocialBlack")
end

function XUiSocial:OnBtnBackClick()
    if self.PrivatePanelIsOpen then
        if self.PrivateChatViewPanel ~= nil then
            self.PrivateChatViewPanel:Hide()
            self.PanelButtons.gameObject:SetActive(true)
            self.ContactViewPanel:Show()
            self.PrivatePanelIsOpen = false
        end
    else
        self:Close()
    end
end

function XUiSocial:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSocial:OnBtnBtnDailyClick()
    self:PlayAnimation("DailyIn", function()

    end, function()
            self.XUiPanelDaily:SetIsShow(true)
    end)
end

function XUiSocial:OpenPrivateChatView(friendId)
    if self.PrivateChatViewPanel ~= nil then
        self.PanelButtons.gameObject:SetActive(false)
        self.ContactViewPanel:Hide()
        self.PrivateChatViewPanel:Refresh(friendId)
    end
    self.PrivatePanelIsOpen = true
end

function XUiSocial:InsertPanelTipsDesc(desc)
    self.XUiPanelTips:InsertDesc(desc)
end