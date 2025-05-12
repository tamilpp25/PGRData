local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelWaitForPassView = XClass(nil, "XUiPanelWaitForPassView")
local XUiGridWaitPassItem = require("XUi/XUiSocial/WaitPassModel/XUiGridWaitPassItem")

function XUiPanelWaitForPassView:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
    self:InitAutoScript()

    self.GameObject:SetActive(false)
    self.GridWaitPassPlayer.gameObject:SetActive(false)
    self.PassList = {}
    self.Tips.gameObject:SetActive(false)


    self.DynamicListManager = XDynamicTableNormal.New(self.GameObject)
    self.DynamicListManager:SetProxy(XUiGridWaitPassItem)
    self.DynamicListManager:SetDelegate(self)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelWaitForPassView:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelWaitForPassView:AutoInitUi()
    -- self.GridWaitPassPlayer = self.Transform:Find("Viewport/WaitPassList/GridWaitPassPlayer")
    -- self.TxtChargeDay = self.Transform:Find("WaitPassPanelOther/TxtChargeDay"):GetComponent("Text")
    -- self.TxtFriendCountA = self.Transform:Find("WaitPassPanelOther/TxtFriendCount"):GetComponent("Text")
    -- self.BtnAdd = self.Transform:Find("Tips/BtnAdd"):GetComponent("Button")
    -- self.Tips = self.Transform:Find("Tips")
end

function XUiPanelWaitForPassView:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelWaitForPassView:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelWaitForPassView:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelWaitForPassView:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick)
end


-- auto
function XUiPanelWaitForPassView:OnBtnAddClick()
    self.Parent:SetSelectedIndex(self.Parent.BtnTabIndex.MainAddContact)
end


function XUiPanelWaitForPassView:Show()
    if not self.GameObject:Exist() then
        return
    end

    self.GameObject:SetActive(true)
    self.Parent:PlayAnimation("WaitForPassViewQieHuan")
    self:RefreshFriendCount()
    self:RefreshApplyList()

    XEventManager.AddEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.RefreshApplyList, self)
end

function XUiPanelWaitForPassView:Hide()
    if not self.GameObject:Exist() then
        return
    end

    self.GameObject:SetActive(false)
    XEventManager.RemoveEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.RefreshApplyList, self)
end

--刷新好友数量  和收取数量
function XUiPanelWaitForPassView:RefreshFriendCount()
    local friendCountText = CS.XTextManager.GetText("FriendCount")
    local dayChargeText = CS.XTextManager.GetText("FriendDayCharge")
    local maxCount = XPlayerManager.GetMaxFriendCount(XPlayer.GetLevelOrHonorLevel(), XPlayer.IsHonorLevelOpen())
    self.TxtFriendCountA.text = string.format("%s  %d / %d", friendCountText, XDataCenter.SocialManager.GetFriendCount(), maxCount)
    self.TxtChargeDay.text = string.format("%s  %d / %d", dayChargeText, 0, 0)
end

function XUiPanelWaitForPassView:RefreshApplyList()
    XDataCenter.SocialManager.GetApplyFriendsInfo(function()
        self.ApplyList = XDataCenter.SocialManager.GetApplyFriendList()
        if not self.ApplyList or #self.ApplyList <= 0 then
            self.Tips.gameObject:SetActive(true)
        else
            self.Tips.gameObject:SetActive(false)
        end

        self.DynamicListManager:SetDataSource(self.ApplyList)
        self.DynamicListManager:ReloadDataASync()
    end)
end


function XUiPanelWaitForPassView:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.ApplyList[index], function() self:RefreshFriendCount() end)
    end
end

function XUiPanelWaitForPassView:OnClose()
    XEventManager.RemoveEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.RefreshApplyList, self)
end

return XUiPanelWaitForPassView