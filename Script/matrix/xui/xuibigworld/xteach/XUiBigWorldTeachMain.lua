local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBigWorldTeachGrid = require("XUi/XUiBigWorld/XTeach/XUiBigWorldTeachGrid")
local XUiBigWorldTeachContent = require("XUi/XUiBigWorld/XTeach/Common/XUiBigWorldTeachContent")

---@class XUiBigWorldTeachMain : XBigWorldUi
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field BtnHelp XUiComponent.XUiButton
---@field TabBtnGroup XUiButtonGroup
---@field BtnTab XUiComponent.XUiButton
---@field InputField UnityEngine.UI.InputField
---@field BtnDelete XUiComponent.XUiButton
---@field PanelNothingLeft UnityEngine.RectTransform
---@field PanelNothingRight UnityEngine.RectTransform
---@field TeachGrid UnityEngine.RectTransform
---@field ScrollTitleTab UnityEngine.RectTransform
---@field PanelTeachContent UnityEngine.RectTransform
---@field SearchPanel UnityEngine.RectTransform
---@field BtnSearch XUiComponent.XUiButton
---@field _Control XBigWorldTeachControl
local XUiBigWorldTeachMain = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTeachMain")

function XUiBigWorldTeachMain:OnAwake()
    self._TabList = {}
    self._TabIndexGroupMap = {}

    self._SelectTabIndex = 0
    self._SelectTeachIndex = 1

    self._SearchKey = ""

    ---@type XDynamicTableNormal
    self._DynamicTable = false
    ---@type XUiBigWorldTeachContent
    self._ContentUi = XUiBigWorldTeachContent.New(self.PanelTeachContent, self)

    self:_RegisterButtonClicks()
end

function XUiBigWorldTeachMain:OnStart()
    self._DynamicTable = XDynamicTableNormal.New(self.ScrollTitleTab)

    self:_InitUi()
    self:_InitTab()
    self:_InitDynamicTable()
end

function XUiBigWorldTeachMain:OnEnable()
    self:_RefreshTabReddot()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldTeachMain:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldTeachMain:OnDestroy()

end

function XUiBigWorldTeachMain:ChangeSelect(index, teachId)
    if self._SelectTeachIndex ~= index then
        local grid = self._DynamicTable:GetGridByIndex(self._SelectTeachIndex)

        if grid then
            grid:SetIsSelect(false)
        end
    end

    self._SelectTeachIndex = index
    self:_RefreshTeachContent(teachId)
    self:_RefreshTabReddot()
end

function XUiBigWorldTeachMain:OnBtnBackClick()
    self:Close()
end

function XUiBigWorldTeachMain:OnTabBtnGroupClick(index)
    if self._SelectTabIndex ~= index then
        self._SelectTabIndex = index
        self._SearchKey = ""
        self.InputField.text = ""
        self:_RefreshDynamicTable(index)
    end
end

function XUiBigWorldTeachMain:OnBtnDeleteClick()
    self.InputField.text = ""
    self:_RefreshDynamicTable(self._SelectTabIndex)
end

function XUiBigWorldTeachMain:OnBtnSearchClick()
    local searchKey = self.InputField.text

    if not string.IsNilOrEmpty(searchKey) then
        local teachs = self._Control:SearchTeach(searchKey)

        self._SearchKey = searchKey
        self:_RefreshDynamicTableWithTeachs(teachs)
    end
    self:_InitSearch(false)
end

function XUiBigWorldTeachMain:OnInputChanged(value)
    self:_InitSearch(true)

    if string.IsNilOrEmpty(value) then
        self._SearchKey = ""
        self:_RefreshDynamicTable(self._SelectTabIndex)
    end
end

---@param grid XUiBigWorldTeachGrid
function XUiBigWorldTeachMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local config = self._DynamicTable:GetData(index)

        grid:Refresh(config, index, index == self._SelectTeachIndex, self._SearchKey)
    end
end

function XUiBigWorldTeachMain:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnBack.CallBack = Handler(self, self.OnBtnBackClick)
    self.BtnDelete.CallBack = Handler(self, self.OnBtnDeleteClick)
    self.BtnSearch.CallBack = Handler(self, self.OnBtnSearchClick)
    self.InputField.onValueChanged:AddListener(Handler(self, self.OnInputChanged))
end

function XUiBigWorldTeachMain:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_READ, self._RefreshTabReddot, self)
end

function XUiBigWorldTeachMain:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_READ, self._RefreshTabReddot, self)
end

function XUiBigWorldTeachMain:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldTeachMain:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldTeachMain:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldTeachMain:_InitTab()
    local configs = self._Control:GetTeachGroupConfigs()

    if not XTool.IsTableEmpty(configs) then
        local index = 1

        self._TabIndexGroupMap = {}
        for _, config in pairs(configs) do
            local tab = XUiHelper.Instantiate(self.BtnTab, self.TabBtnGroup.transform)

            self._TabIndexGroupMap[index] = config.Id
            tab:SetSprite(config.Icon)
            table.insert(self._TabList, tab)
            index = index + 1
        end

        self.TabBtnGroup:Init(self._TabList, Handler(self, self.OnTabBtnGroupClick))
        self.TabBtnGroup:SelectIndex(1)
    end

    self.BtnTab.gameObject:SetActiveEx(false)
end

function XUiBigWorldTeachMain:_InitDynamicTable()
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(XUiBigWorldTeachGrid, self)
end

function XUiBigWorldTeachMain:_InitUi()
    self.TeachGrid.gameObject:SetActiveEx(false)
    self:_InitSearch(true)
end

function XUiBigWorldTeachMain:_InitSearch(isSearch)
    self.BtnSearch.gameObject:SetActiveEx(isSearch)
    self.BtnDelete.gameObject:SetActiveEx(not isSearch)
end

function XUiBigWorldTeachMain:_RefreshDynamicTable(index)
    local groupId = self._TabIndexGroupMap[index]

    if XTool.IsNumberValid(groupId) then
        local teachs = self._Control:GetUnlockTeachsByGroupId(groupId)

        self:_RefreshDynamicTableWithTeachs(teachs)
    else
        self:_SetTeachPanelActive(false)
    end
end

function XUiBigWorldTeachMain:_RefreshTabReddot()
    for index, groupId in pairs(self._TabIndexGroupMap) do
        local tab = self._TabList[index]

        if tab then
            tab:ShowReddot(self._Control:CheckHasUnReadTeachByGroupId(groupId))
        end
    end
end

function XUiBigWorldTeachMain:_RefreshDynamicTableWithTeachs(teachs)
    self._SelectTeachIndex = 1
    if not XTool.IsTableEmpty(teachs) then
        self:_SetTeachPanelActive(true)
        self._DynamicTable:SetDataSource(teachs)
        self._DynamicTable:ReloadDataSync()
    else
        self:_SetTeachPanelActive(false)
    end
end

function XUiBigWorldTeachMain:_RefreshTeachContent(teachId)
    self._ContentUi:Open()
    self._ContentUi:Refresh(teachId)
end

function XUiBigWorldTeachMain:_SetTeachPanelActive(isActive)
    self._DynamicTable:SetActive(isActive)
    self.PanelNothingRight.gameObject:SetActiveEx(not isActive)
    if isActive then
        self._ContentUi:Open()
    else
        self._ContentUi:Close()
    end
end

return XUiBigWorldTeachMain
