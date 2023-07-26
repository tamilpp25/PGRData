--工会boss普通其他关卡详细信息页面
local XUiGuildBossLog = require("XUi/XUiGuildBoss/Component/XUiGuildBossLog")
local XUiGuildBossSkillGrid = require("XUi/XUiGuildBoss/Component/XUiGuildBossSkillGrid")
local XUiGuildBossRankPanel = require("XUi/XUiGuildBoss/Component/XUiGuildBossRankPanel")
local XUiGuildBossOtherSubLevelInfo = XLuaUiManager.Register(XLuaUi, "UiGuildBossOtherSubLevelInfo")

function XUiGuildBossOtherSubLevelInfo:OnAwake()
    --self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.Instantiate = CS.UnityEngine.GameObject.Instantiate
    self.VectorOne = CS.UnityEngine.Vector3.one
    self.VectorZero = CS.UnityEngine.Vector3.zero

    self.Skill = XUiGuildBossSkillGrid.New(self.SkillGrid)
    self.RankPanel = XUiGuildBossRankPanel.New(self.PanelRankObj)
    
    --Log相关
    self.LogDynamicTable = XDynamicTableIrregular.New(self.PanelRecordView)
    self.LogDynamicTable:SetProxy("XUiGuildBossLog",XUiGuildBossLog, self.RecordItem.gameObject)
    self.LogDynamicTable:SetDelegate(self)
end

function XUiGuildBossOtherSubLevelInfo:GetProxyType()
    return "XUiGuildBossLog"
end

function XUiGuildBossOtherSubLevelInfo:OnStart(ui)
    self.ParentUi = ui
end

function XUiGuildBossOtherSubLevelInfo:OnEnable()
    self.Data = self.ParentUi.CurSelectLevelData
    self.ConfigData = XGuildBossConfig.GetBossStageInfo(self.Data.StageId)
    --buff
    self.Skill:Init(self.ConfigData, self.Data)
    --Rank
    self.RankPanel:Init(self.Data.StageId)
    --log
    self.LogData = {}
    local allLogData = XDataCenter.GuildBossManager.GetLogs()
    if allLogData then
        for i = 1, #allLogData do
            if allLogData[i].StageId == self.Data.StageId then
                table.insert(self.LogData, allLogData[i])
            end
        end
    end
    self.LogDynamicTable:SetDataSource(self.LogData)
    self.LogDynamicTable:ReloadDataASync()
    self.PanelNull.gameObject:SetActiveEx(#self.LogData == 0)
end

--Log动态列表事件
function XUiGuildBossOtherSubLevelInfo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Init(self.LogData[index])
    end
end

function XUiGuildBossOtherSubLevelInfo:OnBtnCloseClick()
    self:Close()
end
