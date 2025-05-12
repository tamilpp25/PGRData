local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPokerGuessing2StoryGrid = require("XUi/XUiPokerGuessing2/Story/XUiPokerGuessing2StoryGrid")

---@class XUiPokerGuessing2Story : XLuaUi
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2Story = XLuaUiManager.Register(XLuaUi, "UiPokerGuessing2Story")

function XUiPokerGuessing2Story:OnAwake()
    self:BindExitBtns()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelArchiveList)
    self.DynamicTable:SetProxy(XUiPokerGuessing2StoryGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridArchiveNpc.gameObject:SetActiveEx(false)
    self.ToggleFilter.onValueChanged:AddListener(handler(self, self.OnToggleShowUnplayedStoriesFirst))
    self.ToggleFilter.isOn = XSaveTool.GetData("PokerGuessing2ShowUnplayedStoriesFirst") or false

    self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe({
        XDataCenter.ItemManager.ItemId.PokerGuessing2ItemId
    }, self.PanelSpecialTool, self)
end

function XUiPokerGuessing2Story:OnStart()
    self:Update()
end

function XUiPokerGuessing2Story:Update()
    local dataSource = self._Control:GetStoryList()
    if self.ToggleFilter.isOn then
        table.sort(dataSource, function(a, b)
            if a.IsPlayed ~= b.IsPlayed then
                return b.IsPlayed
            end
            return a.Id < b.Id
        end)
    end
    self.DynamicTable:SetDataSource(dataSource)
    self.DynamicTable:ReloadDataSync()
end

function XUiPokerGuessing2Story:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_STORY, self.Update, self)
end

function XUiPokerGuessing2Story:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_STORY, self.Update, self)
end

function XUiPokerGuessing2Story:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayGridAnimation()
    end
end

function XUiPokerGuessing2Story:PlayGridAnimation()
    local grids = self.DynamicTable:GetGrids()
    for i, grid in ipairs(grids) do
        grid:PlayEnableAnimation(i)
    end
end

function XUiPokerGuessing2Story:OnToggleShowUnplayedStoriesFirst(isOn)
    XSaveTool.SaveData("PokerGuessing2ShowUnplayedStoriesFirst", isOn)
    self:Update()
end

return XUiPokerGuessing2Story