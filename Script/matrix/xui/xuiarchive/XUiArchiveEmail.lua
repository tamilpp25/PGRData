local XUiGridArchiveCommunication = require("XUi/XUiArchive/XUiGridArchiveCommunication")
local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridArchiveEmail = require("XUi/XUiArchive/XUiGridArchiveEmail")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XDynamicTableIrregular = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableIrregular")
local XUiArchiveEmail = XLuaUiManager.Register(XLuaUi, "UiArchiveEmail")
local Object = CS.UnityEngine.Object

function XUiArchiveEmail:OnEnable()
    self:SetupDynamicTable()
end

function XUiArchiveEmail:OnStart()
    self.MailGridState = {}
    self.CurTag = {}
    self.CurTag[XEnumConst.Archive.EmailType.Email] = 1
    self.CurTag[XEnumConst.Archive.EmailType.Communication] = 1
    self.CurType = 1
    self.TabBtnContent = {}
    self.TabBtnContent[XEnumConst.Archive.EmailType.Email] = self.TabMailBtnContent
    self.TabBtnContent[XEnumConst.Archive.EmailType.Communication] = self.TabCommuniContent
    self:SetButtonCallBack()
    self:InitEmailDynamicTable()
    self:InitCommunicationDynamicTable()
    self:InitTagButton()
    self:InitTypeButton()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiArchiveEmail:OnDestroy()
    self._Control.CGControl:ClearAllCGReddot()
end
------------------------------------------EMail---------------------------->>>
function XUiArchiveEmail:InitEmailDynamicTable()
    self.EmailDynamicTable = XDynamicTableIrregular.New(self.PanelArchiveEmailList)
    self.EmailDynamicTable:SetDynamicEventDelegate(function(event, index, grid)
            self:OnEmailDynamicTableEvent(event, index, grid)
        end)
    self.EmailDynamicTable:SetProxy("XUiGridArchiveEmail", XUiGridArchiveEmail, self.EmalItem.gameObject,self)
    self.EmailDynamicTable:SetDelegate(self)
    self.EmalItem.gameObject:SetActiveEx(false)
end

function XUiArchiveEmail:GetProxyType()
    return "XUiGridArchiveEmail"
end

function XUiArchiveEmail:SetupEmailDynamicTable(tag)
    XScheduleManager.ScheduleOnce(function()--异形屏适配需要
            self.PageEmailDatas = self._Control:GetArchiveMailList(tag)
            self.EmailDynamicTable:SetDataSource(self.PageEmailDatas)
            self.EmailDynamicTable:ReloadDataSync(1)
        end, 1)
    
end

function XUiArchiveEmail:OnEmailDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageEmailDatas[index],self.MailGridState)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnGridClick(self.PageEmailDatas[index])
    end
end

function XUiArchiveEmail:OnGridClick(chapter)
    if chapter then
        if self.OldId and self.OldId ~= chapter:GetId() then
            self.MailGridState[self.OldId] = false
        end
        self.MailGridState[chapter:GetId()] = self.MailGridState[chapter:GetId()] or false
        self.MailGridState[chapter:GetId()] = not self.MailGridState[chapter:GetId()]
        self.EmailDynamicTable:ReloadDataSync()
        self.OldId = chapter:GetId()
    end

end
------------------------------------------EMail----------------------------<<<

------------------------------------------Communication---------------------------->>>
function XUiArchiveEmail:InitCommunicationDynamicTable()
    self.CommunicationDynamicTable = XDynamicTableNormal.New(self.PanelArchiveCommunicationList)
    self.CommunicationDynamicTable:SetDynamicEventDelegate(function(event, index, grid)
            self:OnCommunicationDynamicTableEvent(event, index, grid)
        end)
    self.CommunicationDynamicTable:SetProxy(XUiGridArchiveCommunication,self)
    self.CommunicationDynamicTable:SetDelegate(self)
    self.CommunicationItem.gameObject:SetActiveEx(false)
end

function XUiArchiveEmail:SetupCommunicationDynamicTable(tag)
    self.PageCommunicationDatas = self._Control:GetArchiveCommunicationList(tag)
    self.CommunicationDynamicTable:SetDataSource(self.PageCommunicationDatas)
    self.CommunicationDynamicTable:ReloadDataSync(1)
end

function XUiArchiveEmail:OnCommunicationDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageCommunicationDatas[index])
    end
end
------------------------------------------Communication----------------------------<<<
function XUiArchiveEmail:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
end

function XUiArchiveEmail:InitTagButton()
    self.TagList = self._Control:GetEventDateGroupList()
    for type, group in pairs(self.TagList) do
        local eventDateGroupBtn = {}
        for _,v in pairs(group)do
            local btn = Object.Instantiate(self.BtnTabShortNew)
            btn.gameObject:SetActiveEx(true)
            btn.transform:SetParent(self.TabBtnContent[type].transform, false)
            local btncs = btn:GetComponent("XUiButton")
            local name = v.Name
            btncs:SetName(name or "")

            table.insert(eventDateGroupBtn, btncs) 
        end
        self.TabBtnContent[type]:Init(eventDateGroupBtn, function(index) self:SelectTag(index) end)
        self.TabBtnContent[type]:SelectIndex(self.CurTag[type])
    end
    
    self.BtnTabShortNew.gameObject:SetActiveEx(false)
end

function XUiArchiveEmail:SelectTag(index)
    self.CurTag[self.CurType] = index
    self:SetupDynamicTable()
end

function XUiArchiveEmail:CheckTagButtonType()
    self.PanelMailTab.gameObject:SetActiveEx(self.CurType == XEnumConst.Archive.EmailType.Email)
    self.PanelCommuniTab.gameObject:SetActiveEx(self.CurType == XEnumConst.Archive.EmailType.Communication)
end


function XUiArchiveEmail:InitTypeButton()
    self.TypeList = {self.BtnEmail, self.BtnCommunication}
    self.PanelTabBtns:Init(self.TypeList, function(index) self:SelectType(index) end)
    self.PanelTabBtns:SelectIndex(self.CurType)
end

function XUiArchiveEmail:SelectType(index)
    self.CurType = index
    self:SetupDynamicTable()
    self:CheckTagButtonType()
end

function XUiArchiveEmail:SetupDynamicTable()
    local tagId = self.TagList[self.CurType][self.CurTag[self.CurType]].Id
    if self.CurType == XEnumConst.Archive.EmailType.Email then
        self:SetupEmailDynamicTable(tagId)
    elseif self.CurType == XEnumConst.Archive.EmailType.Communication then
        self:SetupCommunicationDynamicTable(tagId)
    end
    
    self.PanelMailTab.gameObject:SetActiveEx(self.CurType == XEnumConst.Archive.EmailType.Email)
    self.PanelCommuniTab.gameObject:SetActiveEx(self.CurType == XEnumConst.Archive.EmailType.Communication)
    
    self.PanelArchiveEmail.gameObject:SetActiveEx(self.CurType == XEnumConst.Archive.EmailType.Email)
    self.PanelArchiveCommunication.gameObject:SetActiveEx(self.CurType == XEnumConst.Archive.EmailType.Communication)
end


function XUiArchiveEmail:OnBtnBackClick()
    self:Close()
end

function XUiArchiveEmail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end