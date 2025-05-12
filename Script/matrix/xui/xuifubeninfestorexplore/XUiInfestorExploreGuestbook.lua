local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridInfestorExplorePlayerMessage = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExplorePlayerMessage")

local XUiInfestorExploreGuestbook = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreGuestbook")

function XUiInfestorExploreGuestbook:OnAwake()
    self:AutoAddListener()
    self.GridGuestbook.gameObject:SetActiveEx(false)
end

function XUiInfestorExploreGuestbook:OnStart(chapterId)
    self.ChapterId = chapterId
    self:InitDynamicTable()
end

function XUiInfestorExploreGuestbook:OnEnable()
    self:RefreshView()
end

function XUiInfestorExploreGuestbook:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridInfestorExplorePlayerMessage)
end

function XUiInfestorExploreGuestbook:RefreshView()
    local msgs = XDataCenter.FubenInfestorExploreManager.GetAllChapterMsgs(self.ChapterId)
    self.Msgs = msgs

    if next(msgs) then
        self.ImgEmpty.gameObject:SetActiveEx(false)
        self.PanelSelectList.gameObject:SetActiveEx(true)

        self.DynamicTable:SetDataSource(self.Msgs)
        self.DynamicTable:ReloadDataSync()
    else
        self.ImgEmpty.gameObject:SetActiveEx(true)
        self.PanelSelectList.gameObject:SetActiveEx(false)
    end
end

function XUiInfestorExploreGuestbook:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local chapterId = self.ChapterId
        local msg = self.Msgs[index]
        grid:Refresh(msg)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local msg = self.Msgs[index]
        local playerId = msg.Id
        if playerId and playerId ~= XPlayer.Id then
            XDataCenter.PersonalInfoManager.ReqShowInfoPanel(playerId)
        end
    end
end

function XUiInfestorExploreGuestbook:AutoAddListener()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnSend.CallBack = function() self:OnClickBtnSend() end
end

function XUiInfestorExploreGuestbook:OnClickBtnSend()
    local msg = self.InputFieldMsg.text
    if string.IsNilOrEmpty(msg) then
        XUiManager.TipText("InfestorExploreChapterMessageEmpty")
        return
    end

    local chapterId = self.ChapterId
    local callBack = function()
        XUiManager.TipText("InfestorExploreChapterMessageSuc")
        self:RefreshView()
    end
    XDataCenter.FubenInfestorExploreManager.RequestChapterLeaveMsg(chapterId, msg, callBack)
end