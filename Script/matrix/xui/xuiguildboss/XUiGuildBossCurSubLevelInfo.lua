--工会boss普通关卡详细信息页面
local XUiGuildBossLog = require("XUi/XUiGuildBoss/Component/XUiGuildBossLog")
local XUiGuildBossSkillGrid = require("XUi/XUiGuildBoss/Component/XUiGuildBossSkillGrid")
local XUiGuildBossRankPanel = require("XUi/XUiGuildBoss/Component/XUiGuildBossRankPanel")
local XUiGuildBossCurSubLevelInfo = XLuaUiManager.Register(XLuaUi, "UiGuildBossCurSubLevelInfo")
local GUILD_BOSS_NEED_BUFF = 100

function XUiGuildBossCurSubLevelInfo:OnAwake()
    self.Instantiate = CS.UnityEngine.GameObject.Instantiate
    self.VectorOne = CS.UnityEngine.Vector3.one
    self.VectorZero = CS.UnityEngine.Vector3.zero
    self.BtnStart.CallBack = function() self:OnBtnStartClick() end
    self.MaxCount = CS.XGame.Config:GetInt("GuildBossStageUploadCount")
    self.Skill = XUiGuildBossSkillGrid.New(self.SkillGrid)
    self.RankPanel = XUiGuildBossRankPanel.New(self.PanelRankObj)
    self.EnterWarningTitleStr = CS.XTextManager.GetText("GuildBossEnterWarningTitleStr")
    self.EnterLowWarningStr = CS.XTextManager.GetText("GuildBossEnterLowWarningStr")
    self.EnterHighWarningStr = CS.XTextManager.GetText("GuildBossEnterHighWarningStr")

    --Log相关
    self.BtnCloseFullRecord.CallBack = function() self:OnBtnCloseFullRecordClick() end
    self.BtnOpenRecord.CallBack = function() self:OnBtnOpenRecordClick() end
    self.LogDynamicTable = XDynamicTableIrregular.New(self.PanelRecordView)
    self.LogDynamicTable:SetProxy("XUiGuildBossLog", XUiGuildBossLog, self.RecordItem.gameObject)
    self.LogDynamicTable:SetDelegate(self)
end

function XUiGuildBossCurSubLevelInfo:GetProxyType()
    return "XUiGuildBossLog"
end

function XUiGuildBossCurSubLevelInfo:OnStart(ui)
    self.ParentUi = ui
end

--参数data XXDataCenter.GuildBossManager.GuildBossActivityRequest->GuildBossLevelData
function XUiGuildBossCurSubLevelInfo:OnEnable()
    self:UpdateAllInfo()
end

function XUiGuildBossCurSubLevelInfo:UpdateAllInfo()
    self.Data = self.ParentUi.CurSelectLevelData
    self.DetailData = XDataCenter.GuildBossManager.GetDetailLevelData(self.Data.StageId)

    self.ConfigData = XGuildBossConfig.GetBossStageInfo(self.Data.StageId)
    self.TxtCode.text = self.ConfigData.Code .. self.Data.NameOrder
    self.TxtName.text = self.ConfigData.Name
    self.TxtLimit.text = self.ConfigData.Limit
    self.ImgIcon:SetSprite(self.ConfigData.DetailIcon)
    self.OrderMark.gameObject:SetActiveEx(false)
    self.TxtIsDone.gameObject:SetActiveEx(self.Data.Score > 0)
    self.GroupScore.gameObject:SetActiveEx(self.Data.Score > 0)
    self.GroupOne.gameObject:SetActiveEx(self.Data.Score == 0)
    self.TxtScore.text = XUiHelper.GetLargeIntNumText(self.Data.Score)
    self.TxtCount.text = CS.XTextManager.GetText("GuildBossCount", self.Data.UploadCount, self.MaxCount)
    --buff
    self.Skill:Init(self.ConfigData, self.Data.BuffNeed)
    --Rank
    self.RankPanel:Init(self.Data.StageId)
    --log
    self:RefreshLogList(true)
end

function XUiGuildBossCurSubLevelInfo:RefreshLogList(reloadData)
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

function XUiGuildBossCurSubLevelInfo:OnBtnCloseClick()
    self:Close()
end

--Log动态列表事件
function XUiGuildBossCurSubLevelInfo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Init(self.LogData[index])
    end
end


--展开详细记录
function XUiGuildBossCurSubLevelInfo:OnBtnOpenRecordClick()
    self.BtnOpenRecord.gameObject:SetActiveEx(false)
    self.BtnCloseFullRecord.gameObject:SetActiveEx(true)
    self.ImgUnfoldBack.gameObject:SetActiveEx(true)
    self.PanelRecordViewRect.sizeDelta = CS.UnityEngine.Vector2(410, 900)
    self.PanelRecordViewRect.anchoredPosition = CS.UnityEngine.Vector2(30, 950)
    self:RefreshLogList()
end

--关闭详细记录
function XUiGuildBossCurSubLevelInfo:OnBtnCloseFullRecordClick()
    self.BtnOpenRecord.gameObject:SetActiveEx(true)
    self.BtnCloseFullRecord.gameObject:SetActiveEx(false)
    self.ImgUnfoldBack.gameObject:SetActiveEx(false)
    self.PanelRecordViewRect.sizeDelta = CS.UnityEngine.Vector2(410, 163)
    self.PanelRecordViewRect.anchoredPosition = CS.UnityEngine.Vector2(30, 250)
    self:RefreshLogList()
end

function XUiGuildBossCurSubLevelInfo:OnBtnStartClick()
    if self.Data.Type == GuildBossLevelType.High and not XConditionManager.CheckCondition(7201) then -- 重灾区检查等级检查52 临时写死 fix
        XUiManager.TipError(CS.XTextManager.GetText("GuildBossHighAreaLvLimit"))
        return
    end
    
    if self.Data.UploadCount == self.MaxCount then
        XUiManager.TipError(CS.XTextManager.GetText("GuildBossCountFull"))
        return
    end

    XDataCenter.GuildBossManager.GuildBossStageRequest(self.Data.StageId, function()
        local tmpDetailLevelData = XDataCenter.GuildBossManager.GetDetailLevelData(self.Data.StageId)
        if self.DetailData.BuffLeft ~= tmpDetailLevelData.BuffLeft then
            self.DetailData = tmpDetailLevelData

            XDataCenter.GuildBossManager.GuildBossActivityRequest(function()
                if self.ParentUi then
                    self.ParentUi:UpdatePage(0)
                    self.ParentUi:UpdateCurSelectLevelData()
                    self:UpdateAllInfo()
                else
                    self:Close()
                end
            end)
        end
        self:RealOnBtnStartClick()
    end)
end

function XUiGuildBossCurSubLevelInfo:RealOnBtnStartClick()
    local func = function()
        if XTool.USENEWBATTLEROOM then
            XLuaUiManager.Open("UiBattleRoleRoom", self.Data.StageId
                , XDataCenter.GuildBossManager.GetXTeamByStageId(self.Data.StageId)
                , require("XUi/XUiGuildBoss/XUiGuildBossBattleRoleRoom"))
        else
            XLuaUiManager.Open("UiNewRoomSingle", self.Data.StageId)
        end
    end
    if self.DetailData.BuffLeft >= GUILD_BOSS_NEED_BUFF then
        XLuaUiManager.Open("UiDialog", self.EnterWarningTitleStr, CS.XTextManager.GetText("GuildBossBuffActive"), XUiManager.DialogType.Normal, nil, func)
    elseif self.Data.UploadCount == 0 then
        local context = nil
        if self.Data.Type == GuildBossLevelType.Low then
            context = self.EnterLowWarningStr
        else
            context = self.EnterHighWarningStr
        end
        XLuaUiManager.Open("UiDialog", self.EnterWarningTitleStr, context, XUiManager.DialogType.Normal, nil, func)
    else
        func()
    end

end