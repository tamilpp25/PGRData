local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiMentorRecommendation = XLuaUiManager.Register(XLuaUi, "UiMentorRecommendation")
local XUiGridManifesto = require("XUi/XUiMentorSystem/MentorRecommendation/XUiGridManifesto")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiMentorRecommendation:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self.InputField.placeholder.text = CSTextManagerGetText("MentorPlayerSearchText")
end

function XUiMentorRecommendation:OnDestroy()
   
end

function XUiMentorRecommendation:OnEnable()
    self:UpdatePanel()
    XDataCenter.MentorSystemManager.ShowMentorShipComplete()
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_TEACHER_MONTHLYSTUDENTCOUNT_UPDATE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_GET_APPLY, self.CheckRedPoint, self)
    XEventManager.AddEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.OnBtnRefreshClick, self)
end

function XUiMentorRecommendation:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_TEACHER_MONTHLYSTUDENTCOUNT_UPDATE, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_GET_APPLY, self.CheckRedPoint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.OnBtnRefreshClick, self)
end

function XUiMentorRecommendation:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiGridManifesto)
    self.DynamicTable:SetDelegate(self)
    self.GridManifesto.gameObject:SetActiveEx(false)
end

function XUiMentorRecommendation:SetupDynamicTable(data)
    self.PageDatas = data and data or XDataCenter.MentorSystemManager.GetRecommendPlayerList()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
    self.PanelNoneStudentTask.gameObject:SetActiveEx(#self.PageDatas == 0)
    
end

function XUiMentorRecommendation:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index],self)
    end
end

function XUiMentorRecommendation:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "MentorSystemHelp")
    self.BtnEstablish.CallBack = function()
        self:OnBtnEstablishClick()
    end
    self.BtnNews.CallBack = function()
        self:OnBtnNewsClick()
    end
    self.BtnApply.CallBack = function()
        self:OnBtnApplyClick()
    end
    self.BtnRefresh.CallBack = function()
        self:OnBtnRefreshClick()
    end
    self.BtnSearchOffice.CallBack = function()
        self:OnBtnSearchOfficeClick()
    end
end

function XUiMentorRecommendation:UpdatePanel(data)
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self:SetupDynamicTable(data)
    self.TitleText.text = mentorData:IsTeacher() and 
    CSTextManagerGetText("MentorRecommendStudentText") or
     CSTextManagerGetText("MentorRecommendTeacherText")
    self:CheckRedPoint()
    self.BtnEstablish:SetName(mentorData:IsTeacher() and
    CSTextManagerGetText("MentorTeacherEstablishText") or
    CSTextManagerGetText("MentorStudentEstablishText"))
    
    self.TxtNone.text = mentorData:IsTeacher() and
    CSTextManagerGetText("MentorRecommendStudentEmptyHint") or
    CSTextManagerGetText("MentorRecommendTeacherEmptyHint")
    
    local count = string.format("%d/%d", mentorData:GetMonthlyStudentCount(), XMentorSystemConfigs.GetMentorSystemData("MonthlyStudentCount"))
    self.StudentLimitText.text = CSTextManagerGetText("MentorMonthlyStudentCountHInt",count)
    self.StudentLimitText.gameObject:SetActiveEx(mentorData:IsTeacher())
    
end

function XUiMentorRecommendation:OnBtnBackClick()
    self:Close()
end

function XUiMentorRecommendation:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMentorRecommendation:OnBtnRefreshClick()
    XDataCenter.MentorSystemManager.ClearRecommendPlayerList()
    XDataCenter.MentorSystemManager.GetMentorRecommendPlayerListRequest(function ()
            self:UpdatePanel()
        end)
end

function XUiMentorRecommendation:OnBtnEstablishClick()
    XLuaUiManager.Open("UiMentorDeclaration")
end

function XUiMentorRecommendation:OnBtnNewsClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    XDataCenter.MentorSystemManager.GetMentorPlayerInfoListRequest(mentorData:GetApplyIdList(), function ()
            XLuaUiManager.Open("UiMentorApplication")
        end)
end

function XUiMentorRecommendation:OnBtnApplyClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if not mentorData:IsCanDoApply(true) then
        return
    end
    
    local idList = {}
    for _,data in pairs(self.PageDatas or {}) do
        table.insert(idList, data.PlayerId)
    end
    
    XDataCenter.MentorSystemManager.ApplyMentorRequest(idList, function ()
            self:UpdatePanel()
    end)
end

function XUiMentorRecommendation:OnBtnSearchOfficeClick()
    local id = tonumber(self.InputField.text)
    XDataCenter.MentorSystemManager.GetMentorSpecifyPlayerInfoRequest(id, function ()
            local data = {XDataCenter.MentorSystemManager.GetSpecifyPlayer()}
            self:UpdatePanel(data)
    end)
end

function XUiMentorRecommendation:CheckRedPoint()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.BtnNews:ShowReddot(mentorData:IsHasApply())
end