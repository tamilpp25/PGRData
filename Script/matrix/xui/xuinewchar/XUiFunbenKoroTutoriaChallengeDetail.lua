local XUiFunbenKoroTutoriaChallengeDetail = XLuaUiManager.Register(XLuaUi, "UiFunbenKoroTutoriaChallengeDetail")
local XUiGridStageBuffIcon = require("XUi/XUiFubenSimulatedCombat/ChildItem/XUiGridStageBuffIcon")
local DescCount = 3


function XUiFunbenKoroTutoriaChallengeDetail:OnAwake()
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
    self:InitStarPanels()
end

function XUiFunbenKoroTutoriaChallengeDetail:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiFunbenKoroTutoriaChallengeDetail:InitStarPanels()
    self.StarGridList = {}
    for i = 1, DescCount do
        self.StarGridList[i] = XUiGridStageStar.New(self[string.format("GridStageStar%d", i)])
    end
end

function XUiFunbenKoroTutoriaChallengeDetail:SetStageDetail(stageId, id)
    self.Id = id
    self.StageId = stageId
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.TxtTitle.text = self.StageCfg.Description
    self.TxtDescDetail.text = XFubenNewCharConfig.GetNewCharDescDetail(self.StageId)
    local starsMap = XDataCenter.FubenNewCharActivityManager.GetStarMap(self.StageId)
    for i = 1, DescCount do
        self.StarGridList[i]:Refresh(self.StageCfg.StarDesc[i], starsMap[i])
    end
    self:SetBuffList()

    local data = XFubenConfigs.GetStageFightControl(self.StageId)
    if data then
        self.TxtATNums.text = data.ShowFight
    end
    self:PlayAnimation("AnimBegin")
end

--设置词缀
function XUiFunbenKoroTutoriaChallengeDetail:SetBuffList()
    if not self.BuffList then self.BuffList = {} end
    local buffList = XFubenNewCharConfig.GetNewCharShowFightEventIds(self.StageId)
    if buffList == nil or #buffList == 0 then
        self.PanelBuffNone.gameObject:SetActiveEx(true)
        self.BtnBuffTip.gameObject:SetActiveEx(false)
        self.PanelBuffContent.gameObject:SetActiveEx(false)
        return
    end
    self.PanelBuffNone.gameObject:SetActiveEx(false)
    self.BtnBuffTip.gameObject:SetActiveEx(true)
    self.PanelBuffContent.gameObject:SetActiveEx(true)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.StageBuffCfgList = {}
    for i = 1, #buffList do
        if not self.BuffList[i] then
            local prefab = CS.UnityEngine.GameObject.Instantiate(self.GridBuff.gameObject)
            self.BuffList[i] = XUiGridStageBuffIcon.New(prefab, self.RootUi)
        end
    end
    for i = 1, #self.BuffList do
        self.BuffList[i].Transform:SetParent(self.PanelBuffContent, false)
        if buffList[i] then
            self.BuffList[i]:RefreshData(buffList[i])
            self.BuffList[i]:Show()
            table.insert(self.StageBuffCfgList, buffList[i])
        else
            self.BuffList[i]:Hide()
        end
    end

    self.BtnBuffTip.CallBack = function()
        self:OnBtnBuffTip()
    end
    self.PanelBuffNone.gameObject:SetActiveEx(#buffList == 0)
end

function XUiFunbenKoroTutoriaChallengeDetail:OnBtnBuffTip()
    local buffList = XFubenNewCharConfig.GetNewCharShowFightEventIds(self.StageId)
    if buffList and next(buffList) then
        XLuaUiManager.Open("UiSimulatedCombatBossBuffTips", buffList)
    end
end

function XUiFunbenKoroTutoriaChallengeDetail:OnBtnEnterClick()
    --判断是否结束
    local activityCfg = XFubenNewCharConfig.GetDataById(self.Id)
    local endTime = XFunctionManager.GetEndTimeByTimeId(activityCfg.TimeId)
    local nowTime = XTime.GetServerNowTimestamp()
    if nowTime > endTime then
        XUiManager.TipText("KoroCharacterActivityEnd")
        XLuaUiManager.RunMain()
        return
    end

    if XDataCenter.FubenManager.CheckPreFight(self.StageCfg) then
        if self.RootUi then
            self.RootUi:ClearNodesSelect()
        end
        self.RootUi:CloseStageDetails()
        --self:Close()
        if XTool.USENEWBATTLEROOM then
            XLuaUiManager.Open("UiBattleRoleRoom", self.StageCfg.StageId
                , XDataCenter.FubenNewCharActivityManager.LoadTeamLocal(self.Id)
                , require("XUi/XUiNewChar/XUiTutoriaBattleRoleRoom"))
        else
            XLuaUiManager.Open("UiNewRoomSingle", self.StageCfg.StageId)
        end
    end
end

function XUiFunbenKoroTutoriaChallengeDetail:CloseDetailWithAnimation()
    self:PlayAnimation("AnimEnd", function()
            self:Close()
        end)
end