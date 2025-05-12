local XUiBigWorldMessageChat = require("XUi/XUiBigWorld/XMessage/Common/XUiBigWorldMessageChat")

---@class XUiBigWorldMessage : XBigWorldUi
---@field BtnChat XUiComponent.XUiButton
---@field MessageGroup XUiButtonGroup
---@field PanelChat UnityEngine.RectTransform
---@field BtnCharacter XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field BtnCloseBg XUiComponent.XUiButton
---@field _Control XBigWorldMessageControl
local XUiBigWorldMessage = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldMessage")

-- region 生命周期

function XUiBigWorldMessage:OnAwake()
    ---@type XUiBigWorldMessageChat
    self._ChatUi = XUiBigWorldMessageChat.New(self.PanelChat, self)

    self._MessageGroupList = {}
    ---@type table<number, XBWMessageEntity>
    self._MessageIndexMap = {}
    self._ContactsButtonMap = {}
    self._ContactMessageMap = {}

    self._CurrentSelectIndex = 0

    self:_InitUi()
    self:_InitMessageList()
    self:_RegisterButtonClicks()
end

function XUiBigWorldMessage:OnStart()

end

function XUiBigWorldMessage:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMessage:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldMessage:OnDestroy()

end

-- endregion

-- region 按钮事件

function XUiBigWorldMessage:OnBtnCloseClick()
    self:Close()
end

function XUiBigWorldMessage:OnMessageGroupClick(index)
    if index ~= self._CurrentSelectIndex then
        local message = self._MessageIndexMap[index]

        self._CurrentSelectIndex = index
        self._ChatUi:RefreshChat(message)
    end
end

function XUiBigWorldMessage:OnMessageFinish()
    self:_RefreshMessageGroupList()
end

-- endregion

-- region 私有方法

function XUiBigWorldMessage:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnCloseBg, self.OnBtnCloseClick, true)
end

function XUiBigWorldMessage:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMessage:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMessage:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY, self.OnMessageFinish,
        self)
end

function XUiBigWorldMessage:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY,
        self.OnMessageFinish, self)
end

function XUiBigWorldMessage:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldMessage:_InitUi()
    self.BtnCharacter.gameObject:SetActiveEx(false)
    self.BtnChat.gameObject:SetActiveEx(false)
end

function XUiBigWorldMessage:_InitMessageList()
    local contactsMap = self._Control:GetContactsMessageList()
    local index = 1

    self._ContactsButtonMap = {}
    for contactsId, messages in pairs(contactsMap) do
        local mainIndex = index
        local button = self._MessageGroupList[index]
        local isShowReddot = false

        if not button then
            button = XUiHelper.Instantiate(self.BtnCharacter, self.MessageGroup.transform)
            button.gameObject:SetActiveEx(true)
            self._MessageGroupList[index] = button
        end

        button:SetRawImage(self._Control:GetContactsIcon(contactsId))
        button:SetNameByGroup(0, self._Control:GetContactsName(contactsId))

        index = index + 1

        local mainButton = button

        self._ContactsButtonMap[contactsId] = mainButton
        for _, message in pairs(messages) do
            local isComplete = message:IsComplete()

            self._MessageIndexMap[index] = message
            button = self._MessageGroupList[index]

            if not button then
                button = XUiHelper.Instantiate(self.BtnChat, self.MessageGroup.transform)
                button.gameObject:SetActiveEx(true)
                self._MessageGroupList[index] = button
            end

            if not isComplete then
                isShowReddot = true
            end

            local isQuest = message:IsQuest()
            local isQuestFinish = message:IsQuestFinish()

            if isQuest then
                button:SetSprite(message:GetQuestIcon())
            end

            button:SetNameByGroup(0, message:GetCurrentPreviewText())
            button:ShowReddot(not isComplete)
            button:ShowTag(isComplete and isQuestFinish)
            button:SetSpriteVisible(isQuest and not isQuestFinish and isComplete)
            button.SubGroupIndex = mainIndex

            index = index + 1
        end

        mainButton:ShowReddot(isShowReddot)
    end

    self._ContactMessageMap = contactsMap
    self.MessageGroup:Init(self._MessageGroupList, Handler(self, self.OnMessageGroupClick))
    self._ChatUi:RefreshChat()
end

function XUiBigWorldMessage:_RefreshMessageGroupList()
    local contactsMap = self._ContactMessageMap

    if not XTool.IsTableEmpty(contactsMap) then
        for contactsId, messages in pairs(contactsMap) do
            local button = self._ContactsButtonMap[contactsId]
            local isShowReddot = false

            if button then
                for _, message in pairs(messages) do
                    local isComplete = message:IsComplete()

                    if not isComplete then
                        isShowReddot = true
                    end
                end

                button:ShowReddot(isShowReddot)
            end
        end
        for index, button in ipairs(self._MessageGroupList) do
            ---@type XBWMessageEntity
            local message = self._MessageIndexMap[index]

            if message then
                local isComplete = message:IsComplete()
                local isQuest = message:IsQuest()

                if isQuest then
                    local isQuestFinish = message:IsQuestFinish()

                    button:SetSprite(message:GetQuestIcon())
                    button:ShowTag(isComplete and isQuestFinish)
                    button:SetSpriteVisible(isQuest and not isQuestFinish and isComplete)
                else
                    button:ShowTag(isComplete)
                    button:SetSpriteVisible(false)
                end

                button:ShowReddot(not isComplete)
                button:SetNameByGroup(0, message:GetCurrentPreviewText())
            end
        end
    end
end

-- endregion

return XUiBigWorldMessage
