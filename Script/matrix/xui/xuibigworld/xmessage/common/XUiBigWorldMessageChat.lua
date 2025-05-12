local XUiBigWorldMessageGrid = require("XUi/XUiBigWorld/XMessage/Common/XUiBigWorldMessageGrid")
local XUiBigWorldMessageTask = require("XUi/XUiBigWorld/XMessage/Common/XUiBigWorldMessageTask")
local XMessagePlayer = require("XModule/XBigWorldMessage/Common/XMessagePlayer")

---@class XUiBigWorldMessageChat : XUiNode
---@field PanelTop UnityEngine.RectTransform
---@field ImgHead UnityEngine.UI.Image
---@field TxtName UnityEngine.UI.Text
---@field TxtSign UnityEngine.UI.Text
---@field ListChat UnityEngine.RectTransform
---@field ChatContent UnityEngine.RectTransform
---@field PanelLeft UnityEngine.RectTransform
---@field PanelRight UnityEngine.RectTransform
---@field TxtTips UnityEngine.UI.Text
---@field PanelTask UnityEngine.RectTransform
---@field PanelEnd UnityEngine.RectTransform
---@field ListAnswer UnityEngine.RectTransform
---@field BtnAnswer XUiComponent.XUiButton
---@field PanelNone UnityEngine.RectTransform
---@field PanelTaskBg UnityEngine.RectTransform
---@field _Control XBigWorldMessageControl
local XUiBigWorldMessageChat = XClass(XUiNode, "XUiBigWorldMessageChat")

-- region 生命周期

function XUiBigWorldMessageChat:OnStart()
    ---@type XUiBigWorldMessageGrid[]
    self._ReceiveGridList = {}
    ---@type XUiBigWorldMessageGrid[]
    self._SendGridList = {}
    self._SystemTips = {}
    self._AnswerGroup = {}

    self._ReceiveGridIndex = 1
    self._SendGridIndex = 1
    self._SystemTipIndex = 1

    ---@type XUiBigWorldMessageTask
    self._TaskUi = XUiBigWorldMessageTask.New(self.PanelTask, self)
    ---@type XMessagePlayer
    self._Player = XMessagePlayer.New(self)

    self._ChatScroll = XUiHelper.TryGetComponent(self.ListChat, "", typeof(CS.UnityEngine.UI.ScrollRect))

    self._ScrollTimer = false
    self._IsLockGridIndex = false

    self._TaskUi:Close()
    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldMessageChat:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMessageChat:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
    self._Player:Stop()
end

function XUiBigWorldMessageChat:OnDestroy()
    self._Player:Destroy()
end

-- endregion

---@param message XBWMessageEntity
function XUiBigWorldMessageChat:RefreshChat(message)
    self:_Reset()
    self:_RefreshChatPanel(message == nil or message:IsNil())
    self:_ShowAnswerOptions(false)

    if message and not message:IsNil() then
        self.TxtName.text = self._Control:GetContactsName(message:GetContactsId())
        self.TxtSign.text = self._Control:GetContactsText(message:GetContactsId())
        self.ImgHead:SetSprite(self._Control:GetContactsIcon(message:GetContactsId()))
        self:_PlayMessage(message)
    end
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:OnPlayMessage(content)
    if content:IsReceive() then
        local grid = self:_GetReceiveGrid()

        grid:Refresh(content)
    elseif content:IsSend() then
        local grid = self:_GetSendGrid()

        grid:Refresh(content)
    elseif content:IsSystem() then
        local tip = self:_GetSystemTip()

        tip.text = content:GetText()
    elseif content:IsOptions() and not content:IsComplete() then
        self:_RefreshAnswerOptions(content)
    end

    if content:IsEnd() then
        self:_RefreshTeskPanel(content)
        self:_ShowMessageEnd()
        self._Control:SendMessageComplete(content:GetMessageId())
    end

    self:_RemoveScrollTimer()
    self._ScrollTimer = XScheduleManager.ScheduleNextFrame(function()
        self._ScrollTimer = false
        self._ChatScroll.verticalNormalizedPosition = 0
    end)
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:OnPlayMessageBeginLoading(content)
    self._IsLockGridIndex = true
    if content:IsReceive() then
        local grid = self:_GetReceiveGrid()

        grid:Refresh(content)
        grid:SetLoadingEffectActive(true)
    elseif content:IsSend() then
        local grid = self:_GetSendGrid()

        grid:Refresh(content)
        grid:SetLoadingEffectActive(true)
    end
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:OnPlayMessageEndLoading(content)
    if content:IsReceive() then
        local grid = self:_GetReceiveGrid()
        
        grid:SetLoadingEffectActive(false)
    elseif content:IsSend() then
        local grid = self:_GetSendGrid()
        
        grid:SetLoadingEffectActive(false)
    end
    self._IsLockGridIndex = false
end

-- region 私有方法

function XUiBigWorldMessageChat:_RegisterButtonClicks()
    -- 在此处注册按钮事件
end

function XUiBigWorldMessageChat:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMessageChat:_RemoveSchedules()
    -- 在此处移除定时器
    self:_RemoveScrollTimer()
end

function XUiBigWorldMessageChat:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_QUEST_NOTIFY, self._RefreshTask, self)
end

function XUiBigWorldMessageChat:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_QUEST_NOTIFY, self._RefreshTask,
        self)
end

function XUiBigWorldMessageChat:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldMessageChat:_RemoveScrollTimer()
    if self._ScrollTimer then
        XScheduleManager.UnSchedule(self._ScrollTimer)
        self._ScrollTimer = false
    end
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:_RefreshAnswerOptions(content)
    local count = content:GetOprionsCount()

    self:_ShowAnswerOptions(count > 0)
    for i = 1, count do
        local answer = self:_GetAnswerGrid(i)
        local text = content:GetOprionsTextByIndex(i)
        local index = i

        answer:SetNameByGroup(0, text)
        answer.gameObject:SetActiveEx(true)
        answer.CallBack = function()
            self:_ShowAnswerOptions(false)
            self._Player:PlayNext(index)
        end
    end
    for i = count + 1, table.nums(self._AnswerGroup) do
        self._AnswerGroup[i].gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldMessageChat:_RefreshChatPanel(isNone)
    self.PanelNone.gameObject:SetActiveEx(isNone)
    self.ListChat.gameObject:SetActiveEx(not isNone)
    self.PanelTop.gameObject:SetActiveEx(not isNone)
end

function XUiBigWorldMessageChat:_Reset()
    self:_RefreshTask()
    self:_ResetAllReceiveGrid()
    self:_ResetAllSendGrid()
    self:_ResetAllSystemTip()
    self:_ResetMessageEnd()
end

function XUiBigWorldMessageChat:_ResetAllReceiveGrid()
    self._ReceiveGridIndex = 1
    for _, grid in pairs(self._ReceiveGridList) do
        grid:Close()
    end
end

function XUiBigWorldMessageChat:_ResetAllSendGrid()
    self._SendGridIndex = 1
    for _, grid in pairs(self._SendGridList) do
        grid:Close()
    end
end

function XUiBigWorldMessageChat:_ResetAllSystemTip()
    self._SystemTipIndex = 1
    for _, tip in pairs(self._SystemTips) do
        tip.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldMessageChat:_ResetMessageEnd()
    self.PanelEnd.gameObject:SetActiveEx(false)
end

function XUiBigWorldMessageChat:_GetReceiveGrid()
    local index = self._ReceiveGridIndex
    local grid = self._ReceiveGridList[index]

    if not grid then
        local gridObject = XUiHelper.Instantiate(self.PanelLeft, self.ChatContent)

        grid = XUiBigWorldMessageGrid.New(gridObject, self)
        self._ReceiveGridList[index] = grid
    end

    grid:Open()
    if not self._IsLockGridIndex then
        grid.Transform:SetAsLastSibling()
        self._ReceiveGridIndex = self._ReceiveGridIndex + 1
    end

    return grid
end

function XUiBigWorldMessageChat:_GetSendGrid()
    local index = self._SendGridIndex
    local grid = self._SendGridList[index]

    if not grid then
        local gridObject = XUiHelper.Instantiate(self.PanelRight, self.ChatContent)

        grid = XUiBigWorldMessageGrid.New(gridObject, self)
        self._SendGridList[index] = grid
    end

    grid:Open()
    if not self._IsLockGridIndex then
        grid.Transform:SetAsLastSibling()
        self._SendGridIndex = self._SendGridIndex + 1
    end

    return grid
end

function XUiBigWorldMessageChat:_GetSystemTip()
    local index = self._SystemTipIndex
    local tip = self._SystemTips[index]

    if not tip then
        tip = XUiHelper.Instantiate(self.TxtTips, self.ChatContent)

        self._SystemTips[index] = tip
    end

    tip.transform:SetAsLastSibling()
    self._SystemTipIndex = self._SystemTipIndex + 1

    return tip
end

function XUiBigWorldMessageChat:_GetAnswerGrid(index)
    local grid = self._AnswerGroup[index]

    if not grid then
        grid = XUiHelper.Instantiate(self.BtnAnswer, self.ListAnswer)

        self._AnswerGroup[index] = grid
    end

    return grid
end

function XUiBigWorldMessageChat:_ShowMessageEnd()
    self.PanelEnd.gameObject:SetActiveEx(true)
    self.PanelEnd.transform:SetAsLastSibling()
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:_RefreshTeskPanel(content)
    if content:IsQuest() then
        local questId = self._Control:GetMessageQuestId(content:GetMessageId())

        self:_RefreshTask(questId)
    end
end

function XUiBigWorldMessageChat:_RefreshTask(questId)
    if XTool.IsNumberValid(questId) then
        self._TaskUi:Open()
        self._TaskUi:Refresh(questId)
        self._TaskUi.Transform:SetAsLastSibling()
    else
        self._TaskUi:Close()
    end
end

function XUiBigWorldMessageChat:_ShowAnswerOptions(isShow)
    self.PanelTaskBg.gameObject:SetActiveEx(isShow)
    self.ListAnswer.gameObject:SetActiveEx(isShow)
end

function XUiBigWorldMessageChat:_InitUi()
    self.BtnAnswer.gameObject:SetActiveEx(false)
    self.PanelEnd.gameObject:SetActiveEx(false)
    self.PanelLeft.gameObject:SetActiveEx(false)
    self.PanelRight.gameObject:SetActiveEx(false)
    self.TxtTips.gameObject:SetActiveEx(false)
end

---@param message XBWMessageEntity
function XUiBigWorldMessageChat:_PlayMessage(message)
    self._Player:SetMessage(message)
    self._Player:Play()
end

-- endregion

return XUiBigWorldMessageChat
