local XUiSpringFestivalHelpTips2 = XLuaUiManager.Register(XLuaUi, "UiSpringFestivalHelpTips2")
local XUiGridSpringFestivalGiveItem = require("XUi/XUiSpringFestival/CollectCard/XUiGridSpringFestivalGiveItem")
function XUiSpringFestivalHelpTips2:OnStart()
    self:RegisterButtonEvent()
    self:InitDynamicTable()
    self:SetupDynamicTable()
end

function XUiSpringFestivalHelpTips2:OnEnable()
    local isJoinGuild = XDataCenter.GuildManager.IsJoinGuild()
    self.GridContact.gameObject:SetActiveEx(isJoinGuild)
    if isJoinGuild then
        self:RefreshGuildRequestInfo()
    end
    self:RefreshRequestInfo()
    self:SetRemainingTime()
    self:StartTimer()
end

function XUiSpringFestivalHelpTips2:OnDisable()

end

function XUiSpringFestivalHelpTips2:OnDestroy()
    self:StopTimer()
end

function XUiSpringFestivalHelpTips2:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtTime) then
            self.StopTimer()
            return
        end
        self:SetRemainingTime() 
    end, XScheduleManager.SECOND)
end

function XUiSpringFestivalHelpTips2:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiSpringFestivalHelpTips2:SetRemainingTime()
    local offset = XDataCenter.SpringFestivalActivityManager.GetNextRequestTime()
    if offset <= 0 then
        XUiManager.TipText("SpringFestivalGuildRequestRefresh")
        XLuaUiManager.Close("UiSpringFestivalHelpTips2")
        return
    end
    if self.TxtTime then
        self.TxtTime.text = XUiHelper.GetTime(offset,XUiHelper.TimeFormatType.GUILDCD)
    end
end

function XUiSpringFestivalHelpTips2:RegisterButtonEvent()
    self.BtnTanchuangClose.CallBack = function()
        self:OnClickCloseBtn()
    end
    self.BtnHelp.CallBack = function() 
        self:OnClickBtnSendGuildRequest()
    end
end

function XUiSpringFestivalHelpTips2:OnClickCloseBtn()
    XLuaUiManager.Close("UiSpringFestivalHelpTips2")
end

function XUiSpringFestivalHelpTips2:OnClickBtnSendGuildRequest()
    local isCd,cd  = XDataCenter.SpringFestivalActivityManager.CheckIsInGuildRequestCd()
    if isCd then
        XUiManager.TipMsg(CS.XTextManager.GetText("SpringFestivalGuildCdTip",XUiHelper.GetTimeDesc(cd)))
        return 
    end
    XDataCenter.SpringFestivalActivityManager.CollectWordsRequestWordToGuildRequest(function() 
        XUiManager.TipText("SpringFestivalGuildRequestSuccess")
    end)
end

function XUiSpringFestivalHelpTips2:RefreshRequestInfo()
    local wordId = XDataCenter.SpringFestivalActivityManager.GetRequestWordId()
    local itemIcon = XDataCenter.ItemManager.GetItemIcon(wordId)
    self.RequestWordIcon:SetRawImage(itemIcon)
end

function XUiSpringFestivalHelpTips2:RefreshGuildRequestInfo()
    local guildIcon = XDataCenter.GuildManager.GetGuildIconId()
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(guildIcon)
    end
    local guildName = XDataCenter.GuildManager.GetGuildName()
    if self.TxtName then
        self.TxtName.text = guildName
    end
end

function XUiSpringFestivalHelpTips2:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelFriendList)
    self.DynamicTable:SetProxy(XUiGridSpringFestivalGiveItem)
    self.DynamicTable:SetDelegate(self)
end

function XUiSpringFestivalHelpTips2:SetupDynamicTable()
    self.FriendList = XDataCenter.SocialManager.GetFriendList()
    if self.ImgEmpty then
        self.ImgEmpty.gameObject:SetActiveEx(#self.FriendList == 0)
    end
    self.DynamicTable:SetTotalCount(#self.FriendList)
    self.DynamicTable:ReloadDataASync()
end

function XUiSpringFestivalHelpTips2:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.FriendList[index],XDataCenter.SpringFestivalActivityManager.GetRequestWordId())
    end
end

return XUiSpringFestivalHelpTips2