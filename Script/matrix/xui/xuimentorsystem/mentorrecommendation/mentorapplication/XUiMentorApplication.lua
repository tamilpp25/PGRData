local XUiMentorApplication = XLuaUiManager.Register(XLuaUi, "UiMentorApplication")
local XUiGridGotManifesto = require("XUi/XUiMentorSystem/MentorRecommendation/MentorApplication/XUiGridGotManifesto")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiMentorApplication:OnStart()
    self:SetButtonCallBack()
    self:InitDynamicTable()
end

function XUiMentorApplication:OnDestroy()
   
end

function XUiMentorApplication:OnEnable()
    self:UpdatePanel()
    XDataCenter.MentorSystemManager.ShowMentorShipComplete()
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_GET_STUDENT, self.UpdateHintText, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_LOSE_STUDENT, self.UpdateHintText, self)
    XEventManager.AddEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.OnBtnRefreshClick, self)
end

function XUiMentorApplication:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_GET_STUDENT, self.UpdateHintText, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_LOSE_STUDENT, self.UpdateHintText, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.OnBtnRefreshClick, self)
end

function XUiMentorApplication:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelAddContactView)
    self.DynamicTable:SetProxy(XUiGridGotManifesto)
    self.DynamicTable:SetDelegate(self)
    self.GridAddContact.gameObject:SetActiveEx(false)
end

function XUiMentorApplication:SetupDynamicTable()
    self.PageDatas = XDataCenter.MentorSystemManager.GetApplyPlayerList() or {}
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
    self.PanelNoneDailyTask.gameObject:SetActiveEx(not next(self.PageDatas))
end

function XUiMentorApplication:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
    end
end

function XUiMentorApplication:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnApply.CallBack = function()
        self:OnBtnApplyClick()
    end
end

function XUiMentorApplication:UpdatePanel()
    self:SetupDynamicTable()
    self:UpdateHintText()
end

function XUiMentorApplication:UpdateHintText()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.HintText.text = mentorData:IsTeacher() and CSTextManagerGetText("MentorStudentCountText",mentorData:GetLeftStudentCount()) or ""
end

function XUiMentorApplication:OnBtnCloseClick()
    self:Close()
end

function XUiMentorApplication:OnBtnRefreshClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if not mentorData:IsCanDoApply(true) then
        return
    end
    XDataCenter.MentorSystemManager.GetMentorPlayerInfoListRequest(mentorData:GetApplyIdList(), function ()
            self:UpdatePanel()
        end)
end

function XUiMentorApplication:OnBtnApplyClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    XDataCenter.MentorSystemManager.OperationApplyMentorRequest(mentorData:GetApplyIdList(), false, true, function ()
            self:UpdatePanel()
        end)
end