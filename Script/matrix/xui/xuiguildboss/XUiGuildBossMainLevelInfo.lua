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
    self.ImgBossHead:SetRawImage(self.ConfigData.BossHead) --nzwjV3
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

function XUiGuildBossMainLevelInfo:OnDisable()

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

    local seleceStyleCb = function ()
        -- 向服务器请求风格信息 再打开
        XDataCenter.GuildBossManager.GuildBossStyleInfoRequest(function ()
            XLuaUiManager.Open("UiGuildBossSelectStyle")
        end)
    end

    local continueCb = function ()
        XLuaUiManager.Open("UiBattleRoleRoom", self.Data.StageId
            , XDataCenter.GuildBossManager.GetXTeamByStageId(self.Data.StageId)
            , require("XUi/XUiGuildBoss/XUiGuildBossBattleRoleRoom"))
    end

    local textData = 
    {
        sureText = CS.XTextManager.GetText("GuildBossStyleWarningGoSelect"), 
        closeText = CS.XTextManager.GetText("GuildBossStyleWarningCountinue"),
    }

    XDataCenter.GuildBossManager.GuildBossStyleInfoRequest(function ()
        -- 风格选择判断
        local isInV3 = XFunctionManager.CheckInTimeByTimeId(CS.XGame.Config:GetInt("GuildBossThirdVersionTimeId"))
        local fightStyle = XDataCenter.GuildBossManager.GetFightStyle()
        local allStyleConfig = XGuildBossConfig.GetGuildBossFightStyle() -- 所有的风格数据
        local isMaxSkill = fightStyle and fightStyle.StyleId and fightStyle.StyleId > 0 and fightStyle.EffectedSkillId and #fightStyle.EffectedSkillId == allStyleConfig[fightStyle.StyleId].MaxCount
        if (not fightStyle or not fightStyle.StyleId or fightStyle.StyleId <= 0 or not isMaxSkill) and isInV3 then
            XLuaUiManager.Open("UiDialog", self.EnterWarningTitleStr, CS.XTextManager.GetText("GuildBossEnterWarningStyleStr"), XUiManager.DialogType.Normal, continueCb, seleceStyleCb, textData)
        else
            continueCb()
        end
    end)
end