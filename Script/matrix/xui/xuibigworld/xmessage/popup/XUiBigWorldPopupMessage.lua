local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBigWorldPopupMessageGrid = require("XUi/XUiBigWorld/XMessage/Popup/XUiBigWorldPopupMessageGrid")
local XUiBigWorldMessageChat = require("XUi/XUiBigWorld/XMessage/Common/XUiBigWorldMessageChat")

---@class XUiBigWorldPopupMessage : XBigWorldUi
---@field BtnBgClose XUiComponent.XUiButton
---@field ListContacts UnityEngine.RectTransform
---@field GridContacts UnityEngine.RectTransform
---@field BtnClose XUiComponent.XUiButton
---@field PanelChat UnityEngine.RectTransform
---@field PanelNone UnityEngine.RectTransform
---@field _Control XBigWorldMessageControl
local XUiBigWorldPopupMessage = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupMessage")

-- region 生命周期

function XUiBigWorldPopupMessage:OnAwake()
    ---@type XUiBigWorldMessageChat
    self._ChatUi = XUiBigWorldMessageChat.New(self.PanelChat, self)
    self._DynamicTable = XDynamicTableNormal.New(self.ListContacts)
    self._CurrrentSelectIndex = 0
    self._MessageList = self._Control:GetUnreadMessageList()

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldPopupMessage:OnStart()
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(XUiBigWorldPopupMessageGrid, self)
end

function XUiBigWorldPopupMessage:OnEnable()
    self:_RefreshDynamicTable()
    self:_RefreshChatPanel()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldPopupMessage:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldPopupMessage:OnDestroy()
end

-- endregion

---@param message XBWMessageEntity
function XUiBigWorldPopupMessage:RefreshChat(selectIndex, message)
    if XTool.IsNumberValid(self._CurrrentSelectIndex) and self._CurrrentSelectIndex ~= selectIndex then
        ---@type XUiBigWorldPopupMessageGrid
        local grid = self._DynamicTable:GetGridByIndex(self._CurrrentSelectIndex)

        if grid then
            grid:SetSelect(false)
        end
    end
    if self._CurrrentSelectIndex ~= selectIndex then
        self._CurrrentSelectIndex = selectIndex
        self._ChatUi:RefreshChat(message)
    end
end

---@param grid XUiBigWorldPopupMessageGrid
function XUiBigWorldPopupMessage:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:Refresh(data, index)
        grid:SetSelect(self._CurrrentSelectIndex == index)
    end
end

-- region 按钮事件

function XUiBigWorldPopupMessage:OnBtnBgCloseClick()
    self:Close()
end

function XUiBigWorldPopupMessage:OnBtnCloseClick()
    self:Close()
end

function XUiBigWorldPopupMessage:OnMessageFinish()
    self:_RefreshDynamicTable()
end

-- endregion

-- region 私有方法

function XUiBigWorldPopupMessage:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnBgClose, self.OnBtnBgCloseClick, true)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
end

function XUiBigWorldPopupMessage:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldPopupMessage:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldPopupMessage:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY, self.OnMessageFinish,
        self)
end

function XUiBigWorldPopupMessage:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY,
        self.OnMessageFinish, self)
end

function XUiBigWorldPopupMessage:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldPopupMessage:_RefreshDynamicTable()
    local messageList = self._MessageList

    self.PanelNone.gameObject:SetActiveEx(XTool.IsTableEmpty(messageList))
    self._DynamicTable:SetDataSource(messageList)
    self._DynamicTable:ReloadDataASync()
end

function XUiBigWorldPopupMessage:_RefreshChatPanel()
    self._ChatUi:RefreshChat()
end

function XUiBigWorldPopupMessage:_InitUi()
    self.GridContacts.gameObject:SetActiveEx(false)
end

-- endregion

return XUiBigWorldPopupMessage
