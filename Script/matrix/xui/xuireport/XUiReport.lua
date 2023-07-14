local XUiReport = XLuaUiManager.Register(XLuaUi, "UiReport")

local ReportDailyMaxTimes = CS.XGame.Config:GetInt("ReportDailyMaxTimes")

function XUiReport:OnAwake()
    self.BtnReportSubType.gameObject:SetActiveEx(false)
    self.BtnReportThreeType.gameObject:SetActiveEx(false)
    self.PanelSelectGroup.CanDisSelect = true
    self.PanelSelectSubGroup.CanDisSelect = true
    self.PanelSelectThreeGroup.CanDisSelect = true
end

function XUiReport:OnStart(data, reportMessage, callback, enterType, cancelCallback, chatChannelType)
    self.Id = data.Id or 0      --玩家Id / 公会Id
    self.TitleName = data.TitleName or ""       --玩家名字 / 公会名字
    self.PlayerLevel = data.PlayerLevel or 0    --玩家等级
    self.PlayerIntroduction = data.PlayerIntroduction or ""     --玩家简介

    self.GuildOuterIntroduction = data.GuildOuterIntroduction or ""      --公会对外简介
    self.GuildInsideIntroduction = data.GuildInsideIntroduction or ""    --公会对内简介

    self.ReportMessage = reportMessage              --举报内容
    self.CallBack = callback                    --按下举报后回调
    self.EnterType = enterType or XReportConfigs.EnterType.Player       --入口类型，从哪个界面打开举报
    self.CancelCallback = cancelCallback
    self.ChatChannelType = chatChannelType or 0      --聊天频道

    local enterTitle = XReportConfigs.GetReportEntryTitle(self.EnterType)
    self.TxtReportName.text = string.format(enterTitle, self.TitleName)

    self.BtnClose.CallBack = function() self:OnBtnClose() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirm() end
    if self.BtnTanchuangClose then
        self.BtnTanchuangClose.CallBack = function() self:OnBtnClose() end
    end

    self.TimerId = XScheduleManager.ScheduleForever(function()
        self.TxtCount.text = (self.InputField.textComponent.cachedTextGenerator.characterCount - 1) .. "/100"
    end, 300)

    self.MainTabIds = {}
    self.MainTabs = {}
    self.CurSelectMainIndex = 0
    self.SubTabIds = {}
    self.SubTabs = {}
    self.CurSelectSubIndex = 0
    self.ThreeTabIds = {}
    self.ThreeTabs = {}
    self.CurSelectThreeIndex = 0
    self:UpdateReportChatContent(reportMessage)
    self:UpdateTabs()
    self:UpdateReportCount()
end

function XUiReport:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_REPORT_NOTIFY, self.UpdateReportCount, self)
end

function XUiReport:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_REPORT_NOTIFY, self.UpdateReportCount, self)
end

function XUiReport:OnDestroy()
    self:RemoveTimer()
end

function XUiReport:RemoveTimer()
    if self.TimerId then
        XScheduleManager.UnSchedule(self.TimerId)
        self.TimerId = nil
    end
end

function XUiReport:UpdateReportCount()
    local reportTimes = XDataCenter.ReportManager.GetReportTimes()
    self.TxtReportCount.text = string.format("（%s/%s）", reportTimes, ReportDailyMaxTimes)
end

--举报的聊天内容
function XUiReport:UpdateReportChatContent(chatContent)
    local isShowReportChat = XReportConfigs.IsShowReportChat(self.EnterType)
    if isShowReportChat then
        local maxChatLen = 30
        local isMaxChatLen = chatContent and string.Utf8Len(chatContent) >= maxChatLen
        if isMaxChatLen then
            chatContent = string.Utf8Sub(chatContent, 1, maxChatLen - 1) .. "..."
        end
        self.TextReportContent.text = chatContent
        self.PanelReport.gameObject:SetActiveEx(true)
    else
        self.PanelReport.gameObject:SetActiveEx(false)
    end
end

--刷新行为类型页签
function XUiReport:UpdateTabs()
    self.PanelNotSelectActionType.gameObject:SetActiveEx(true)
    self.PanelViolation.gameObject:SetActiveEx(false)

    local tagLevel = XReportConfigs.GetReportEntryTagLevel(self.EnterType)
    if tagLevel ~= XReportConfigs.TagLevel.One then
        self.PanelBehavior.gameObject:SetActiveEx(false)
        self:OnMainTab()
        return
    end

    self.PanelBehavior.gameObject:SetActiveEx(true)

    self.MainTabIds = XReportConfigs.GetReportEntryTagIds(self.EnterType)
    local tagIds = self.MainTabIds
    local defaultSelectIndex = self:GetDefaultTagIndex(tagIds)
    for index, tagId in ipairs(tagIds) do
        if not self.MainTabs[index] then
            local tabObj = index == 1 and self.BtnReportType or CS.UnityEngine.Object.Instantiate(self.BtnReportType)
            tabObj.transform:SetParent(self.PanelSelectGroup.transform, false)
            local xUiButton = tabObj:GetComponent("XUiButton")
            local name = XReportConfigs.GetReportName(tagId)
            xUiButton:SetName(name)
            self.MainTabs[index] = xUiButton
        end
    end

    self.PanelSelectGroup:Init(self.MainTabs, function(index) self:OnMainTab(index) end)
    if XTool.IsNumberValid(defaultSelectIndex) then
        self.PanelSelectGroup:SelectIndex(defaultSelectIndex)
    end
end

function XUiReport:OnMainTab(index)
    self.InputField.text = ""
    if self.CurSelectMainIndex == index then
        self.PanelNotSelectActionType.gameObject:SetActiveEx(true)
        self.PanelViolation.gameObject:SetActiveEx(false)
        self.CurSelectMainIndex = 0
        return
    end

    self.CurSelectMainIndex = index or 0
    self.PanelNotSelectActionType.gameObject:SetActiveEx(false)
    self.PanelViolation.gameObject:SetActiveEx(true)
    self:UpdateSubTabs(index)
end

--刷新违规类型页签
function XUiReport:UpdateSubTabs(index)
    self.PanelSelectThreeGroup.gameObject:SetActiveEx(false)

    --clean
    for _, v in pairs(self.SubTabs) do
        CS.UnityEngine.GameObject.Destroy(v.gameObject)
    end
    self.SubTabs = {}

    if index then
        local mainTagId = self.MainTabIds[index]
        self.SubTabIds = XReportConfigs.GetReportTagIdToChildTagIdList(mainTagId)
    else
        self.SubTabIds = XReportConfigs.GetReportEntryTagIds(self.EnterType)
    end

    local defaultSelectIndex = self:GetDefaultTagIndex(self.SubTabIds)
    for i, reportTagId in ipairs(self.SubTabIds) do
        local tabObj = CS.UnityEngine.Object.Instantiate(self.BtnReportSubType)
        tabObj.gameObject:SetActiveEx(true)
        tabObj.transform:SetParent(self.PanelSelectSubGroup.transform, false)
        local xUiButton = tabObj:GetComponent("XUiButton")
        local name = XReportConfigs.GetReportName(reportTagId)
        xUiButton:SetName(name)
        self.SubTabs[i] = xUiButton
    end

    self.PanelSelectSubGroup:Init(self.SubTabs, function(idx) self:OnSubTab(idx) end)

    --延迟保证按钮排版位置正确
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        self.PanelViolation.gameObject:SetActiveEx(false)
        self.PanelViolation.gameObject:SetActiveEx(true)
        if XTool.IsNumberValid(defaultSelectIndex) then
            self.PanelSelectSubGroup:SelectIndex(defaultSelectIndex)
        end
    end, 1)
end

--违规类型选择
function XUiReport:OnSubTab(index)
    self.InputField.text = ""
    if self.CurSelectSubIndex == index then
        self.CurSelectSubIndex = 0
        self.PanelSelectThreeGroup.gameObject:SetActiveEx(false)
        return
    end

    self.CurSelectSubIndex = index
    self:UpdateThreeTabs(index)
end

function XUiReport:UpdateThreeTabs(index)
    self.PanelSelectThreeGroup.gameObject:SetActiveEx(true)

    --clean
    for _, v in pairs(self.ThreeTabs) do
        CS.UnityEngine.GameObject.Destroy(v.gameObject)
    end
    self.ThreeTabs = {}

    local data = XReportConfigs.GetReportCfg()
    local tabId = self.SubTabIds[index]
    self.ThreeTabIds = XReportConfigs.GetReportTagIdToChildTagIdList(tabId)
    local defaultSelectIndex = self:GetDefaultTagIndex(self.ThreeTabIds)

    for i, tagId in ipairs(self.ThreeTabIds) do
        local tabObj = CS.UnityEngine.Object.Instantiate(self.BtnReportThreeType)
        tabObj.gameObject:SetActiveEx(true)
        tabObj.transform:SetParent(self.PanelSelectThreeGroup.transform, false)
        local xUiButton = tabObj:GetComponent("XUiButton")
        local name = XReportConfigs.GetReportName(tagId)
        xUiButton:SetName(name)
        self.ThreeTabs[i] = xUiButton
    end

    if XTool.IsTableEmpty(self.ThreeTabIds) then
        return
    end

    self.PanelSelectThreeGroup:Init(self.ThreeTabs, function(idx) self:OnThreeTab(idx) end)

    --延迟保证按钮排版位置正确
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.PanelViolation.gameObject:SetActiveEx(false)
        self.PanelViolation.gameObject:SetActiveEx(true)
        if XTool.IsNumberValid(defaultSelectIndex) then
            self.PanelSelectThreeGroup:SelectIndex(defaultSelectIndex)
        end
    end, 1)
end

function XUiReport:OnThreeTab(index)
    if self.CurSelectThreeIndex == index then
        self.CurSelectThreeIndex = 0
        self.InputField.text = ""
        return
    end

    local tagId = self.ThreeTabIds[index]
    local name = XReportConfigs.GetReportName(tagId)
    self.InputField.text = CS.XTextManager.GetText("ReportTemplate", name)
    self.CurSelectThreeIndex = index
end

function XUiReport:OnBtnClose()
    self:Close()
    if self.CancelCallback then
        self.CancelCallback()
    end
end

function XUiReport:OnBtnConfirm()
    local curSelectMainIndex = self.CurSelectMainIndex
    local curSelectSubIndex = self.CurSelectSubIndex
    if curSelectSubIndex == 0 then
        XUiManager.TipText("ReportSelectTypeError")
        return
    end

    local tags = {}
    local tagId

    if XTool.IsNumberValid(curSelectMainIndex) then
        tagId = self.MainTabIds[curSelectMainIndex]
        table.insert(tags, tagId)
    end

    if XTool.IsNumberValid(curSelectSubIndex) then
        tagId = self.SubTabIds[curSelectSubIndex]
        table.insert(tags, tagId)
    end

    local curSelectThreeIndex = self.CurSelectThreeIndex
    if XTool.IsNumberValid(curSelectThreeIndex) then
        tagId = self.ThreeTabIds[curSelectThreeIndex]
        table.insert(tags, tagId)
    end

    local chatChannel = self.ChatChannelType
    local reportMessage = self:GetReportMessage(tags)

    if self.EnterType == XReportConfigs.EnterType.Guild then
        XDataCenter.ReportManager.RequestReportGuild(self.Id, self.EnterType, tags, reportMessage, self.InputField.text)
    else
        XDataCenter.ReportManager.Report(self.Id, self.TitleName, self.InputField.text, self.PlayerLevel, reportMessage, self.EnterType, tags, chatChannel)
    end

    if self.CallBack then
        self.CallBack()
    end

    local reportTimes = XDataCenter.ReportManager.GetReportTimes()
    if reportTimes < ReportDailyMaxTimes then
        self:Close()
    end
end

function XUiReport:GetDefaultTagIndex(tagIds)
    local defaultSelectIndex = 0
    for index, tagId in ipairs(tagIds) do
        local selectPriority = XReportConfigs.GetReportSelectPriority(tagId)
        if selectPriority > defaultSelectIndex then
            defaultSelectIndex = index
        end
    end

    return defaultSelectIndex
end

function XUiReport:GetReportMessage(tags)
    local contentType
    for _, tagId in ipairs(tags) do
        contentType = XReportConfigs.GetReportContentType(tagId)
        
        if contentType == XReportConfigs.ContentType.Name then
            return self.TitleName
        end
        if contentType == XReportConfigs.ContentType.PlayerIntroduction then
            return self.PlayerIntroduction
        end
        if contentType == XReportConfigs.ContentType.GuildOuterIntroduction then
            return self.GuildOuterIntroduction
        end
        if contentType == XReportConfigs.ContentType.GuildInsideIntroduction then
            return self.GuildInsideIntroduction
        end
    end
    
    return self.ReportMessage
end