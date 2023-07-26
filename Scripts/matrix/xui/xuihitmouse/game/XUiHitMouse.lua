local Panels = {
    PanelStart = require("XUi/XUiHitMouse/Panels/XUiHitMousePanelStart"),
    PanelMoles = require("XUi/XUiHitMouse/Panels/XUiHitMousePanelMoles"),
    PanelInformation = require("XUi/XUiHitMouse/Panels/XUiHitMousePanelInfo"),
    PanelCombos = require("XUi/XUiHitMouse/Panels/XUiHitMousePanelCombo")
}

--================
--打地鼠小游戏游戏页面
--================
local XUiHitMouse = XLuaUiManager.Register(XLuaUi, "UiHitMouse")

function XUiHitMouse:OnStart(stageId)
    self.StageId = stageId
    self.Round = 0
    self.RefreshIntervalDic = {}
    self.ComboCount = 0
    self.FeverComboCount = 0
    self.FeverTimeCount = 0
    self.Score = 0
    self:InitStageCfg()
    self:InitRefreshCfg()
    self:InitBaseBtns()
    self:InitPanels()
    self:AddListeners()
    Panels.PanelStart.PlayStart(self, function() self:StartGame() end)
end

function XUiHitMouse:InitStageCfg()
    local stageCfg = XHitMouseConfigs.GetCfgByIdKey(
        XHitMouseConfigs.TableKey.Stage,
        self.StageId
    )
    self.FeverCount = stageCfg.HaveFever
    self.FeverRefresh = stageCfg.FeverRefresh
    self.FeverTime = stageCfg.FeverTime
    self.ComboSizeDic = XDataCenter.HitMouseManager.GetComboSizeDic()
end

function XUiHitMouse:InitRefreshCfg()
    local refreshDic = XHitMouseConfigs.GetCfgByIdKey(
        XHitMouseConfigs.TableKey.Stage2Refresh,
        self.StageId
    )
    local targetRefreshCfg = refreshDic[0]
    self.IsFever = false
    self.ScoreRate = (targetRefreshCfg.HitScoreRate and targetRefreshCfg.HitScoreRate > 0 and targetRefreshCfg.HitScoreRate) or 1
    self.RoundTime = targetRefreshCfg.MaxShowTime or 5
    self.BreakTime = targetRefreshCfg.RestTime or 0.2
    self.FeverComboCount = 0
    self.RefreshHitKeyList = {}
    self.HitKey2RefreshDic = {}
    for hitKey, cfg in pairs(refreshDic) do
        table.insert(self.RefreshHitKeyList, hitKey)
        self.HitKey2RefreshDic[hitKey] = cfg
    end
    table.sort(self.RefreshHitKeyList, function(v1, v2) return v1 > v2 end)
end
--==============
--注册基础按钮
--==============
function XUiHitMouse:InitBaseBtns()
    --self.BtnMainUi.CallBack = handler(self, self.OnClickBtnMainUi)
    self.BtnBack.CallBack = handler(self, self.OnClickBtnBack)
    --self:BindHelpBtn(self.BtnHelp, "HitMouseHelp")
end

function XUiHitMouse:InitPanels()
    for _, panel in pairs(Panels) do
        panel.Init(self)
    end
end

function XUiHitMouse:OnClickBtnBack()
    self.Paused = true
    XLuaUiManager.Open("UiHitMouseExitTips", false,
        self.Score,
        XDataCenter.HitMouseManager.GetStageScore(self.StageId),
        function()
            XDataCenter.HitMouseManager.GameFinish(self.StageId, self.Score, function()
                    self:Close()
                end)
        end,
        function()
            self:ResumeGame()
        end)
end

function XUiHitMouse:StartGame()
    self.UpdateScheduleId = XScheduleManager.ScheduleForever(
        function()
            self:OnUpdate()
        end,
        1
    )
    self:NewRound()
end

function XUiHitMouse:ResumeGame()
    self.Paused = false
end

function XUiHitMouse:OnUpdate()
    if self.Paused then return end
    --[[ 需要处理顺序，这部分先注释
    for _, panel in pairs(Panels) do
        if panel.OnUpdate then
            panel.OnUpdate(self)
        end
    end
    ]]
    Panels.PanelMoles.OnUpdate(self)
    Panels.PanelCombos.OnUpdate(self)
    Panels.PanelInformation.OnUpdate(self)
end

function XUiHitMouse:OnDestroy()
    self:UnSchedule()
    self:RemoveListeners()
end

function XUiHitMouse:NewRound()
    self.Round = self.Round + 1
    --XLog.Error("===========第" .. self.Round .. "轮开始============================")
    Panels.PanelMoles.StartRound(self)
    self.RoundTimeFlag = true
    self.RoundTimeCount = 0
end

function XUiHitMouse:EndRound()
    self.BreakTimeFlag = true
    self.BreakTimeCount = 0
    self.ClearRoundFlag = false
    self.RoundTimeFlag = false
    if self.FeverCount > 0 and self.FeverComboCount >= self.FeverCount then
        self:StartFever()
    end
    if self.FeverEnd then
        self.FeverEnd = false
        Panels.PanelCombos.OnComboChange(self)
    end
    --XLog.Error("===========第" .. self.Round .. "轮结束============================")
end

--===================
--清屏,把未消失的地鼠全部强制消失
--(满足回合结束条件：1.全部得分地鼠被击倒， 2.回合时间到)
--@param isChecked:是否已经检测过全部地鼠被击倒
--===================
function XUiHitMouse:ClearRound(isChecked)
    self.ClearRoundFlag = true
    self.RoundTime = nil
    local allClear = isChecked and true or Panels.PanelMoles.CheckMoleClear(self.Moles)
    if not allClear then
        if self.IsFever then
            self:EndFever(false)
        else
            self:ComboFailed()
        end
    end
    Panels.PanelMoles.ClearRound(self)
    self.MolesPanel.SoundCloseGaiZi.gameObject:SetActiveEx(false)
    self.MolesPanel.SoundCloseGaiZi.gameObject:SetActiveEx(true)
end

function XUiHitMouse:OnMoleDead(mole)
    Panels.PanelCombos.OnMoleDead(self, mole)
    Panels.PanelInformation.OnMoleDead(self, mole)
end

function XUiHitMouse:ComboFailed()
    Panels.PanelCombos.ComboFailed(self)
    if self.IsFever then
        self:EndFever(true)
    end
end

function XUiHitMouse:StartFever()
    local refreshCfg = XHitMouseConfigs.GetCfgByIdKey(
        XHitMouseConfigs.TableKey.Refresh,
        self.FeverRefresh
    )
    self.ScoreRate = (refreshCfg.HitScoreRate and refreshCfg.HitScoreRate > 0 and refreshCfg.HitScoreRate) or 1
    self.RoundTime = refreshCfg.MaxShowTime
    self.BreakTime = refreshCfg.RestTime
    self.IsFever = true
    Panels.PanelCombos.StartFever(self)
end

function XUiHitMouse:EndFever(needClear)
    self.IsFever = false
    self.FeverComboCount = 0
    self.FeverTimeCount = 0
    self.FeverEnd = true
    Panels.PanelCombos.EndFever(self)
    if needClear then
        self.ClearRoundFlag = true
        self.RoundTime = nil
        Panels.PanelMoles.ClearRound(self)
    end
end
--====================
--一局时间用完处理
--====================
function XUiHitMouse:TimesUp()
    self.ClearFinishCount = 0
    XLuaUiManager.SetMask(true)
    local _clearFinish = function()
        self.ClearFinishCount = self.ClearFinishCount + 1
        if self.ClearFinishCount >= #self.Moles then
            self.Paused = true
            self.PanelFinish.gameObject:SetActiveEx(true)
            self.PaneFinishEnable:PlayTimelineAnimation(
                function()
                    XLuaUiManager.SetMask(false)
                    self.PanelFinish.gameObject:SetActiveEx(false)
                    XLuaUiManager.Open("UiHitMouseExitTips", true,
                        self.Score,
                        XDataCenter.HitMouseManager.GetStageScore(self.StageId),
                        function()
                            XDataCenter.HitMouseManager.GameFinish(self.StageId, self.Score, function()
                                    self:Close()
                                end)
                        end,
                        function()
                            XDataCenter.HitMouseManager.GameFinish(self.StageId, self.Score, function()
                                    self.Round = 0
                                    self.RefreshIntervalDic = {}
                                    self.ComboCount = 0
                                    self.Score = 0
                                    self:InitRefreshCfg()
                                    self:InitPanels()
                                    Panels.PanelStart.PlayStart(self,
                                        function()
                                            self.Paused = false
                                            self:NewRound()
                                        end)
                                end)
                        end)
                end)
        end
    end
    for _, mole in pairs(self.Moles) do
        mole:Clear(_clearFinish)
    end
end

function XUiHitMouse:UnSchedule()
    if self.UpdateScheduleId then
        XScheduleManager.UnSchedule(self.UpdateScheduleId)
        self.UpdateScheduleId = nil
    end
end

function XUiHitMouse:OnActivityEnd()
    XDataCenter.HitMouseManager.OnActivityEndHandler()
end

--==============
--添加UI事件监听
--==============
function XUiHitMouse:AddListeners()
    XEventManager.AddEventListener(XEventId.EVENT_HIT_MOUSE_ACTIVITY_END, self.OnActivityEnd, self)
end
--==============
--移除UI事件监听
--==============
function XUiHitMouse:RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_HIT_MOUSE_ACTIVITY_END, self.OnActivityEnd, self)
end