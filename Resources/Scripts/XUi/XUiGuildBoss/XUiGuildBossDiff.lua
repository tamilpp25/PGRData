--工会boss设置难度页面
local XUiGuildBossLevelGrid = require("XUi/XUiGuildBoss/Component/XUiGuildBossLevelGrid")
local XUiGuildBossDiff = XLuaUiManager.Register(XLuaUi, "UiGuildBossDiff")

function XUiGuildBossDiff:OnAwake()
    self.DynamicTable = XDynamicTableNormal.New(self.BossScoreList)
    self.DynamicTable:SetProxy(XUiGuildBossLevelGrid)
    self.DynamicTable:SetDelegate(self)
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
end

function XUiGuildBossDiff:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDBOSS_UPDATEDIFF, self.UpdateDynamicTable, self)
end

function XUiGuildBossDiff:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDBOSS_UPDATEDIFF, self.UpdateDynamicTable, self)
end

function XUiGuildBossDiff:OnStart()
    self.TxtTotalScore.text = XUiHelper.GetLargeIntNumText(XDataCenter.GuildBossManager.GetTotalScore())
    self.LevelData = XGuildBossConfig.GetBossLevel()
    self:UpdateDynamicTable()
end

function XUiGuildBossDiff:UpdateDynamicTable()
    self.DynamicTable:SetDataSource(self.LevelData)
    self.DynamicTable:ReloadDataASync()
end

--动态列表事件
function XUiGuildBossDiff:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Init(self.LevelData[index], XDataCenter.GuildBossManager.GetCurBossLevel(), XDataCenter.GuildBossManager.GetNextBossLevel(), XDataCenter.GuildManager.GetCurRankLevel(), XDataCenter.GuildBossManager.GetScoreSumBest())
    end
end

function XUiGuildBossDiff:OnBtnBackClick()
    self:Close()
end
