local XUiStrongholdPowerusageTips = XLuaUiManager.Register(XLuaUi, "UiStrongholdPowerusageTips")
local XUiStrongholdPowerusageTipsGrid = require("XUi/XUiStronghold/PowerusageTips/XUiStrongholdPowerusageTipsGrid")

--电能弹窗
function XUiStrongholdPowerusageTips:OnAwake()
    self:RegisterButtonEvent()
    self.GridRecord.gameObject:SetActiveEx(false)
end

function XUiStrongholdPowerusageTips:OnStart(groupId, teamList)
    self.GroupId = groupId
    self.CurSelectChapterId = XTool.IsNumberValid(groupId) and XStrongholdConfigs.GetChapterIdByGroupId(groupId)

    local useElectric = XDataCenter.StrongholdManager.GetTotalUseElectricEnergy(teamList)
    self.TxtTips.text = XUiHelper.GetText("StrongholdSuggestElectricTipsDesc2", useElectric)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelContent.transform)
    self.DynamicTable:SetProxy(XUiStrongholdPowerusageTipsGrid)
    self.DynamicTable:SetDelegate(self)

    self.ChapterIds = XStrongholdConfigs.GetAllChapterIds(nil, true)
    self.DynamicTable:SetDataSource(self.ChapterIds)
    self.DynamicTable:ReloadDataSync()
end

function XUiStrongholdPowerusageTips:OnEnable()

end

function XUiStrongholdPowerusageTips:OnDisable()

end

function XUiStrongholdPowerusageTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.ChapterIds[index], self.CurSelectChapterId)
    end
end

function XUiStrongholdPowerusageTips:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end