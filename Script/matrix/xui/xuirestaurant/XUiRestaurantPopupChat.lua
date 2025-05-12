
---@class XUiRestaurantPopupChat : XLuaUi 对话界面
---@field _Control XRestaurantControl
---@field ListChat UnityEngine.UI.ScrollRect
local XUiRestaurantPopupChat = XLuaUiManager.Register(XLuaUi, "UiRestaurantPopupChat")

local XUiGridMessage = require("XUi/XUiRestaurant/XUiGrid/XUiGridMessage")

local MessageType = XMVCA.XRestaurant.MessageType

local MaxAnswerCount = 2

function XUiRestaurantPopupChat:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantPopupChat:OnStart(performId)
    self.PerformId = performId
    self:InitView()
end

function XUiRestaurantPopupChat:InitUi()
    self.GridChats = {}
    self.GridChat.gameObject:SetActiveEx(false)
    self:RefreshFinish(false)
    self:RefreshAnswer(false)
end

function XUiRestaurantPopupChat:OnDisable()
    self:StopTimer()
end

function XUiRestaurantPopupChat:InitCb()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    
    self.OnChatRefreshCb = handler(self, self.OnChatRefresh)
end

function XUiRestaurantPopupChat:InitView()
    self.Record = {}
    self.Index = 1
    
    local perform = self._Control:GetPerform(self.PerformId)
    self.TalkIds = perform:GetTalkStoryTalkIds()
    self.Durations = perform:GetTalkStoryDurations()
    self.TalkCount = #self.TalkIds
    self:SetupDynamicTable()
    self:StartTimer()
end

function XUiRestaurantPopupChat:SetupDynamicTable()
    self.DataList = self:GetMessageList()
    local count = #self.DataList
    for i = self.Index, count do
        local grid = self.GridChats[i]
        if not grid then
            local ui = XUiHelper.Instantiate(self.GridChat, self.Content)
            ui.gameObject:SetActiveEx(true)
            grid = XUiGridMessage.New(ui, self)
            self.GridChats[i] = grid
        end
        grid:Refresh(self.DataList[i], i)
    end
    self.ListChat.verticalNormalizedPosition = 0
end

function XUiRestaurantPopupChat:OnChatRefresh()
    if XTool.UObjIsNil(self.GameObject) then
        self:StopTimer()
        return
    end
    self.Index = self.Index + 1
    if self.Index > self.TalkCount then
        self:StopTimer()
        self:RefreshFinish(true)
        return
    end
    local business = self._Control:GetBusiness()
    local talkId = self.TalkIds[self.Index]
    local template = business:GetTalkTemplate(talkId)

    if template.Type == MessageType.Auto then
        self:PlayNext()
    elseif template.Type == MessageType.Select then
        self:StopTimer()
        self:RefreshAnswer(true)
    end
end

function XUiRestaurantPopupChat:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleOnce(self.OnChatRefreshCb, self:GetDuration())
end

function XUiRestaurantPopupChat:StopTimer()
    if not self.Timer then
        return
    end
    
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end

function XUiRestaurantPopupChat:GetDuration()
    local duration = self.Durations[self.Index]
    return duration or 0
end

function XUiRestaurantPopupChat:GetMessageList()
    local ids = {}
    for i = 1, self.Index do
        table.insert(ids, self.TalkIds[i])
    end
    return ids
end

function XUiRestaurantPopupChat:PlayNext()
    self:SetupDynamicTable()
    self:StartTimer()
end

function XUiRestaurantPopupChat:RefreshAnswer(isShow)
    local talkId = self.TalkIds and self.TalkIds[self.Index] or 0
    local answer
    if isShow then
        local business = self._Control:GetBusiness()
        local template = business:GetTalkTemplate(talkId)
        answer = template.Answers
    end
    for i = 1, MaxAnswerCount do
        local btn = self["BtnAnswer" .. i]
        if XTool.UObjIsNil(btn) then
            break
        end
        btn.gameObject:SetActiveEx(isShow and not string.IsNilOrEmpty(answer[i]))
        if isShow then
            btn:SetNameByGroup(0, answer[i])
            btn.CallBack = function() 
                self:OnSelectAnswer(talkId, i)
            end
        end
    end
end

function XUiRestaurantPopupChat:RefreshFinish(isFinish)
    self.BtnClose.gameObject:SetActiveEx(isFinish)
    self.TxtTips.gameObject:SetActiveEx(isFinish)

    if isFinish then
        self.ListChat.verticalNormalizedPosition = 0
    end
end

function XUiRestaurantPopupChat:OnSelectAnswer(talkId, index)
    self.Record[talkId] = index
    self:RefreshAnswer(false)

    self:PlayNext()
end

function XUiRestaurantPopupChat:GetTalkMessage(talkId)
    local business = self._Control:GetBusiness()
    local template = business:GetTalkTemplate(talkId)
    if template.Type == MessageType.Auto then
        return template.Reply
    end
    local index = self.Record[talkId]
    return template.Answers[index]
end

function XUiRestaurantPopupChat:OnBtnCloseClick()
    local performId = self.PerformId
    self._Control:RequestTakePerform(performId, self.Record, function() 
        XLuaUiManager.PopThenOpen("UiRestaurantPopupStory", performId)
    end)
end