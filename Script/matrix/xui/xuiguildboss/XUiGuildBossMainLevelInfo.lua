--工会boss Boss关卡详细信息页面
local XUiGuildBossLog = require("XUi/XUiGuildBoss/Component/XUiGuildBossLog")
local XUiGuildBossRankPanel = require("XUi/XUiGuildBoss/Component/XUiGuildBossRankPanel")
local XUiGuildBossMainLevelInfo = XLuaUiManager.Register(XLuaUi, "UiGuildBossMainLevelInfo")

function XUiGuildBossMainLevelInfo:OnAwake()
    self.BtnStart.CallBack = function() self:OnBtnStartClick() end
    self.Instantiate = CS.UnityEngine.GameObject.Instantiate
    self.VectorOne = CS.UnityEngine.Vector3.one
    self.VectorZero = CS.UnityEngine.Vector3.zero
    self.MaxCount = CS.XGame.Config:GetInt("GuildBossStageUploadCount")
    self.GuildBossDeathAddScore = CS.XGame.Config:GetInt("GuildBossDeathAddScore")
    self.RankPanel = XUiGuildBossRankPanel.New(self.PanelRankObj)
    --Log相关
    self.BtnCloseFullRecord.CallBack = function() self:OnBtnCloseFullRecordClick() end
    self.BtnOpenRecord.CallBack = function() self:OnBtnOpenRecordClick() end
    self.LogDynamicTable = XDynamicTableIrregular.New(self.PanelRecordView)
    self.LogDynamicTable:SetProxy("XUiGuildBossLog",XUiGuildBossLog, self.RecordItem.gameObject)
    self.LogDynamicTable:SetDelegate(self)
end

function XUiGuildBossMainLevelInfo:GetProxyType()
    return "XUiGuildBossLog"
end

function XUiGuildBossMainLevelInfo:OnStart(ui)
    self.ParentUi = ui
end

function XUiGuildBossMainLevelInfo:OnEnable()
    self.Data = self.ParentUi.CurSelectLevelData
    self.ConfigData = XGuildBossConfig.GetBossStageInfo(self.Data.StageId)
    self.TxtCode.text = self.ConfigData.Code
    self.TxtName.text = self.ConfigData.Name
    self.TxtLimit.text = self.ConfigData.Limit
    self.ImgIcon:SetSprite(self.ConfigData.Icon)
    self.OrderMark.gameObject:SetActiveEx(false)
    self.TxtIsDone.gameObject:SetActiveEx(self.Data.Score > 0)
    self.GroupScore.gameObject:SetActiveEx(self.Data.Score > 0)
    self.TxtScore.text = XUiHelper.GetLargeIntNumText(self.Data.Score)
    self.TxtCount.text = CS.XTextManager.GetText("GuildBossCount", self.Data.UploadCount, self.MaxCount)
    --bossHp
    local bossMaxHp = XDataCenter.GuildBossManager.GetMaxBossHp()
    local bossCurHp = XDataCenter.GuildBossManager.GetCurBossHp()
    self.TxtCur.text = XUiHelper.GetLargeIntNumText(bossCurHp)
    self.TxtMax.text = "/ " .. XUiHelper.GetLargeIntNumText(bossMaxHp)
    self.ImgBossHp.fillAmount = bossCurHp / bossMaxHp
    self.TxtBossDie.text = CS.XTextManager.GetText("GuildBossDie", self.GuildBossDeathAddScore)
    self.PanelActive.gameObject:SetActiveEx(bossCurHp <= 0)
    --Rank
    self.RankPanel:Init(self.Data.StageId)
    --log
    self:RefreshLogList(true)
end

function XUiGuildBossMainLevelInfo:RefreshLogList(reloadData)
    if reloadData then
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
    end
    self.LogDynamicTable:ReloadDataASync(#self.LogData)
end

function XUiGuildBossMainLevelInfo:OnBtnCloseClick()
    self:Close()
end

--Log动态列表事件
function XUiGuildBossMainLevelInfo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Init(self.LogData[index])
    end
end


--展开详细记录
function XUiGuildBossMainLevelInfo:OnBtnOpenRecordClick()
    self.BtnOpenRecord.gameObject:SetActiveEx(false)
    self.BtnCloseFullRecord.gameObject:SetActiveEx(true)
    self.ImgUnfoldBack.gameObject:SetActiveEx(true)
    self.PanelRecordViewRect.sizeDelta = CS.UnityEngine.Vector2(410, 900)
    self.PanelRecordViewRect.anchoredPosition = CS.UnityEngine.Vector2(30, 950)
    self:RefreshLogList()
end

--关闭详细记录
function XUiGuildBossMainLevelInfo:OnBtnCloseFullRecordClick()
    self.BtnOpenRecord.gameObject:SetActiveEx(true)
    self.BtnCloseFullRecord.gameObject:SetActiveEx(false)
    self.ImgUnfoldBack.gameObject:SetActiveEx(false)
    self.PanelRecordViewRect.sizeDelta = CS.UnityEngine.Vector2(410, 163)
    self.PanelRecordViewRect.anchoredPosition = CS.UnityEngine.Vector2(30, 250)
    self:RefreshLogList()
end

function XUiGuildBossMainLevelInfo:OnBtnStartClick()
    if self.Data.UploadCount == self.MaxCount then
        XUiManager.TipError(CS.XTextManager.GetText("GuildBossCountFull"))
        return
    end
    if XTool.USENEWBATTLEROOM then
        XLuaUiManager.Open("UiBattleRoleRoom", self.Data.StageId
            , XDataCenter.GuildBossManager.GetXTeamByStageId(self.Data.StageId)
            , require("XUi/XUiGuildBoss/XUiGuildBossBattleRoleRoom"))
    else
        XLuaUiManager.Open("UiNewRoomSingle", self.Data.StageId)
    end
end