
---@class XUiBigWorldTaskMain : XBigWorldUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XBigWorldQuestControl
local XUiBigWorldTaskMain = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTaskMain")

local XUiSGPanelTaskGroup = require("XUi/XUiBigWorld/XQuest/Panel/XUiPanelBWTaskGroup")

local DlcEventId = XMVCA.XBigWorldService.DlcEventId

local TASK_TYPE_ALL = XMVCA.XBigWorldQuest.QuestType.All
--策划需要缓存
local Type2TabIndex = {}

function XUiBigWorldTaskMain:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldTaskMain:OnStart(index, questId)
    self._DefaultIndex = index or 1
    self._DefaultQuestId = questId
    self:InitView()
    
    XEventManager.AddEventListener(DlcEventId.EVENT_REFRESH_QUEST_MAIN, self.OnRefreshSelect, self)
end

function XUiBigWorldTaskMain:OnEnable()
    self.PanelTabBtnGroup:SelectIndex(self._DefaultIndex)
end

function XUiBigWorldTaskMain:OnDisable()
end

function XUiBigWorldTaskMain:OnDestroy()
    XEventManager.RemoveEventListener(DlcEventId.EVENT_REFRESH_QUEST_MAIN, self.OnRefreshSelect, self)
end

function XUiBigWorldTaskMain:InitUi()
    -- 任务类型页签
    self._TypeIds = {TASK_TYPE_ALL, }
    self._TypeIds = XTool.MergeArray(self._TypeIds, self._Control:GetQuestTypeIds())

    local tabList = {}
    for index, typeId in ipairs(self._TypeIds) do
        local btn = index == 1 and self.BtnTab or XUiHelper.Instantiate(self.BtnTab, self.PanelTabBtnGroup.transform)
        local icon = self._Control:GetQuestTypeIcon(typeId)
        if not string.IsNilOrEmpty(icon) then
            btn:SetSprite(icon)
        end
        table.insert(tabList, btn)
    end
    self.PanelTabBtnGroup:Init(tabList, function(index) self:OnSelectTab(index) end)

    -- 任务组页签
    ---@type table<number, XUiPanelBWTaskGroup>
    self._PanelTaskGroup = {}
    self.PanelTitleBtnGroup.gameObject:SetActiveEx(false)
end

function XUiBigWorldTaskMain:InitCb()
    self.BtnBack.CallBack = function()
        self:Close()
    end

    self.BtnStory.CallBack = function()
        self:OnBtnStoryClick()
    end
end

function XUiBigWorldTaskMain:InitView()
    
end

function XUiBigWorldTaskMain:OnSelectTab(tabIndex)
    if self._TabIndex == tabIndex then
        return
    end

    self._TabIndex = tabIndex
    self:RefreshTaskGroup()
end

function XUiBigWorldTaskMain:RefreshTaskGroup()
    local typeId = self._TypeIds[self._TabIndex]
    if self._LastTypeId then
        local lastPanel = self:GetPanelTaskGroup(self._LastTypeId)
        lastPanel:Close()
    end
    local panel = self:GetPanelTaskGroup(typeId)
    panel:Open()
    self._LastTypeId = typeId
end

function XUiBigWorldTaskMain:GetGroupSelectIndex()
    if self._DefaultQuestIndex then
        local index = self._DefaultQuestIndex
        self._DefaultQuestIndex = nil
        self._DefaultQuestId = nil
        return index
    end
    
    local typeId = self._TypeIds[self._TabIndex]
    if Type2TabIndex[typeId] then
        return Type2TabIndex[typeId]
    end
    
    return 1
end

function XUiBigWorldTaskMain:SetGroupSelectIndex(index)
    self._DefaultQuestIndex = index
end

function XUiBigWorldTaskMain:RefreshTaskContent(isGroup, id, tabIndex)
    if isGroup then
        return
    end
    local typeId = self._TypeIds[self._TabIndex]
    Type2TabIndex[typeId] = tabIndex
    if not self._PanelTaskContent then
        self._PanelTaskContent = require("XUi/XUiBigWorld/XQuest/Panel/XUiPanelBWTaskContent").New(self.PanelTask, self)
    end
    if XTool.IsNumberValid(id) and XTool.IsNumberValid(tabIndex) then
        self.PaneNothing.gameObject:SetActiveEx(false)
        self._PanelTaskContent:Open()
        self._PanelTaskContent:RefreshView(id)
    else
        self.PaneNothing.gameObject:SetActiveEx(true)
        self._PanelTaskContent:Close()
    end
end

function XUiBigWorldTaskMain:GetPanelTaskGroup(typeId)
    local panel = self._PanelTaskGroup[typeId]
    if panel then
        return panel
    end
    local ui = XUiHelper.Instantiate(self.PanelTitleBtnGroup, self.ContentGroup.transform)
    ui.gameObject:SetActiveEx(true)
    panel = XUiSGPanelTaskGroup.New(ui, self, typeId, self._DefaultQuestId)
    self._PanelTaskGroup[typeId] = panel

    return panel
end

function XUiBigWorldTaskMain:OnBtnStoryClick()
    XLuaUiManager.Open("UiBigWorldLineChapter")
end

function XUiBigWorldTaskMain:OnRefreshSelect(index, questId)
    local typeId = self._TypeIds[index]
    local panel = self._PanelTaskGroup[typeId]
    --已经打开过
    if panel then
        local subIndex = panel:GetIndexByQuestId(questId)
        Type2TabIndex[typeId] = subIndex
    else
        self._TabIndex = nil
        self._DefaultQuestId = questId
        
    end
    self.PanelTabBtnGroup:SelectIndex(index)
    
end