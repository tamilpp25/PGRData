local XUiAwarenessOccupyProgress = XLuaUiManager.Register(XLuaUi, "UiAwarenessOccupyProgress")
local XUiGridAwarenessOccupyProgress = require("XUi/XUiAwareness/Grid/XUiGridAwarenessOccupyProgress")

function XUiAwarenessOccupyProgress:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiAwarenessOccupyProgress:OnStart(characterId)
    self.CharacterId = characterId
    self.Character = XDataCenter.CharacterManager.GetCharacter(characterId)
end

function XUiAwarenessOccupyProgress:InitButton()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
end

function XUiAwarenessOccupyProgress:InitDynamicTable()
    -- 选择作战层的滑动列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiGridAwarenessOccupyProgress, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiAwarenessOccupyProgress:OnEnable()
    self.TxTtitle.text = CS.XTextManager.GetText("AwarenessFight")
    self:RefreshDynamicTable()
end

function XUiAwarenessOccupyProgress:RefreshDynamicTable()
    self.DataList = XDataCenter.FubenAwarenessManager.GetChapterIdList()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(self.CurrSelectLayerListIndex or 1)
end

function XUiAwarenessOccupyProgress:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end