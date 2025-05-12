local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local pairs = pairs
local tableSort = table.sort

local XUiGridArchivesCenterFile = require("XUi/XUiDormQuest/XUiGridArchivesCenterFile")

-- 委托文件系统界面
---@class XUiDormArchivesCenter : XLuaUi
local XUiDormArchivesCenter = XLuaUiManager.Register(XLuaUi, "UiDormArchivesCenter")

local BTN_INDEX = {
    First = 1,
    Second = 2,
}

local DefaultIndex = 100

function XUiDormArchivesCenter:OnAwake()
    self:RegisterUiEvents()
    self:InitHideView()
end

function XUiDormArchivesCenter:OnStart()
    self:InitLeftTabBtn()
    self:InitDynamicTable()
end

function XUiDormArchivesCenter:OnEnable()
    self:CheckLeftTabBtnRedPoint()
    local Index = self:GetSelectIndex()
    self.BtnContent:SelectIndex(Index)
end

function XUiDormArchivesCenter:InitLeftTabBtn()
    self.BtnTabList = {}
    local questFileGroupDic = XDormQuestConfigs.GetQuestFileGroupDic()
    for _, config in pairs(questFileGroupDic) do
        -- 一级标题
        local btnPrefab = self:GetCertainBtnModel(BTN_INDEX.First, true)
        local firstGo = XUiHelper.Instantiate(btnPrefab, self.BtnContent.transform)
        local firstBtn = firstGo:GetComponent("XUiButton")
        firstBtn.gameObject:SetActiveEx(true)
        firstBtn:SetNameByGroup(0, config.Name)
        self.BtnTabList[config.Id] = firstBtn
        -- 二级标题
        local questFileSubGroupDic = XDormQuestConfigs.GetQuestFileSubGroupDic(config.Id)
        local subCount = #questFileSubGroupDic
        for index, subConfig in pairs(questFileSubGroupDic) do
            local tmpBtnPrefab = self:GetCertainBtnModel(BTN_INDEX.Second, nil, index, subCount)
            local secondGo = XUiHelper.Instantiate(tmpBtnPrefab, self.BtnContent.transform)
            local secondBtn = secondGo:GetComponent("XUiButton")
            secondBtn.gameObject:SetActiveEx(true)
            secondBtn:SetNameByGroup(0, subConfig.Name)
            secondBtn.SubGroupIndex = subConfig.ParentGroup
            self.BtnTabList[subConfig.Id] = secondBtn
        end
    end
    self.BtnContent:Init(self.BtnTabList, function(tabId)
        self:OnClickTabCallBack(tabId)
    end)
end

function XUiDormArchivesCenter:OnClickTabCallBack(tabId)
    if self.CurrentTabId and self.CurrentTabId == tabId then
        return
    end
    self.CurrentTabId = tabId
    self:SetupDynamicTable()
    self:PlayAnimation("QieHuan")
end

function XUiDormArchivesCenter:GetCertainBtnModel(index, hasChild, pos, totalNum)
    if index == BTN_INDEX.First then
        if hasChild then
            return self.BtnFirstHasSnd
        else
            return self.BtnFirst
        end
    elseif index == BTN_INDEX.Second then
        if totalNum == 1 then
            return self.BtnSecondAll
        end

        if pos == 1 then
            return self.BtnSecondTop
        elseif pos == totalNum then
            return self.BtnSecondBottom
        else
            return self.BtnSecond
        end
    end
end

function XUiDormArchivesCenter:InitHideView()
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnFirstHasSnd.gameObject:SetActiveEx(false)
    self.BtnSecondTop.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    self.BtnSecondBottom.gameObject:SetActiveEx(false)
    self.BtnSecondAll.gameObject:SetActiveEx(false)

    self.PanelFileItem.gameObject:SetActiveEx(false)
end

function XUiDormArchivesCenter:GetQuestFileList()
    local questFiles = XDataCenter.DormQuestManager.GetCollectFileDataBySubGroupId(self.CurrentTabId)
    if XTool.IsTableEmpty(questFiles) then
        return {}
    end
    -- 排序 未查阅的文件置顶显示
    tableSort(questFiles, function(a, b)
        local isReadFileA = XDataCenter.DormQuestManager.CheckReadFile(a)
        local isReadFileB = XDataCenter.DormQuestManager.CheckReadFile(b)
        if isReadFileA ~= isReadFileB then
            return isReadFileB
        end
        return a < b
    end)
    return questFiles
end

function XUiDormArchivesCenter:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelFile)
    self.DynamicTable:SetProxy(XUiGridArchivesCenterFile, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDormArchivesCenter:SetupDynamicTable()
    self.DataList = self:GetQuestFileList()
    self.PanelNoFile.gameObject:SetActiveEx(XTool.IsTableEmpty(self.DataList))
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiGridArchivesCenterFile
function XUiDormArchivesCenter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end

function XUiDormArchivesCenter:CheckLeftTabBtnRedPoint()
    local notReadFile = XDataCenter.DormQuestManager.GetNotReadQuestFile()
    local groupIds = {}
    for _, fileId in pairs(notReadFile) do
        local dormQuestFileViewModel = self:GetQuestFileViewModel(fileId)
        local groupId = dormQuestFileViewModel:GetQuestFileDetailGroupId()
        local subGroupId = dormQuestFileViewModel:GetQuestFileDetailSubGroupId()
        groupIds[groupId] = groupId
        groupIds[subGroupId] = subGroupId
    end
    for id, btn in pairs(self.BtnTabList) do
        local isContain = groupIds[id] and true or false
        btn:ShowReddot(isContain)
    end
end

-- 返回第一个未查阅文件的SubGroupId
function XUiDormArchivesCenter:GetSelectIndex()
    local notReadFile = XDataCenter.DormQuestManager.GetNotReadQuestFile()
    if XTool.IsTableEmpty(notReadFile) then
        return DefaultIndex
    end
    tableSort(notReadFile, function(a, b)
        local dormQuestFileA = self:GetQuestFileViewModel(a)
        local dormQuestFileB = self:GetQuestFileViewModel(b)
        local groupIdA = dormQuestFileA:GetQuestFileDetailGroupId()
        local groupIdB = dormQuestFileB:GetQuestFileDetailGroupId()
        local subGroupIdA = dormQuestFileA:GetQuestFileDetailSubGroupId()
        local subGroupIdB = dormQuestFileB:GetQuestFileDetailSubGroupId()
        if groupIdA ~= groupIdB then
            return groupIdA < groupIdB
        end
        if subGroupIdA ~= subGroupIdB then
            return subGroupIdA < subGroupIdB
        end
        return a < b
    end)
    local dormQuestFileViewModel = self:GetQuestFileViewModel(notReadFile[1])
    return dormQuestFileViewModel:GetQuestFileDetailSubGroupId()
end

---@return XDormQuestFile
function XUiDormArchivesCenter:GetQuestFileViewModel(fileId)
    return XDataCenter.DormQuestManager.GetDormQuestFileViewModel(fileId)
end

function XUiDormArchivesCenter:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self:BindHelpBtn(self.BtnHelp, "DormArchivesCenter")
end

function XUiDormArchivesCenter:OnBtnBackClick()
    self:Close()
end

return XUiDormArchivesCenter