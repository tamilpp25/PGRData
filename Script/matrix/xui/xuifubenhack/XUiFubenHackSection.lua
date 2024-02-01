local XUiFubenHackSection = XLuaUiManager.Register(XLuaUi, "UiFubenHackSection")
local ViewType = {
    StageInfo = 1,
    TargetInfo = 2,
}
function XUiFubenHackSection:OnAwake()
    self.StarGridList = {}
    self.GridList = {}

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self, true)
    self:InitStarPanels()
end

function XUiFubenHackSection:InitStarPanels()
    for i = 1, 3 do
        self.StarGridList[i] = XUiGridStageStar.New(self[string.format("GridStageStar%d", i)])
    end
end

function XUiFubenHackSection:OnStart(rootUi)
    self.RootUi = rootUi

    self.BtnEnter.CallBack = function() self:OnBtnEnterClick() end
    self.BtnTarget.CallBack = function() self:OnBtnTargetClick() end

    XUiHelper.RegisterClickEvent(self, self.BtnClose, function() self:OnBtnCloseClick() end)
end

function XUiFubenHackSection:OnGetEvents()
    return { XEventId.EVENT_FUBEN_HACK_UPDATE,
             XEventId.EVENT_ACTIVITY_ON_RESET}
end

function XUiFubenHackSection:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_FUBEN_HACK_UPDATE then
        --self:Refresh(args)
    elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Hack then return end
        XDataCenter.FubenHackManager.OnActivityEnd()
    end
end

function XUiFubenHackSection:SetStageDetail(stageId)
    self.StageId = stageId
    self.ActTemplate = XDataCenter.FubenHackManager.GetCurrentActTemplate()

    self.CurrentView = ViewType.StageInfo
    self:OnSwitchView(self.CurrentView, true)

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local stageInterInfo = XFubenHackConfig.GetStageInfo(self.StageId)

    self.TxtTitle.text = stageCfg.Name
    self.AssetActivityPanel:Refresh({self.ActTemplate.TicketId})
    for i = 1, 3 do
        self.StarGridList[i]:Refresh(stageCfg.StarDesc[i], stageInfo.StarsMap[i])
    end

    self.RImgCostIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.ActTemplate.TicketId))
    self.TxtResumeCount.text = stageInterInfo.ConsumeTicket or 0
    local isFirst = not XDataCenter.FubenManager.CheckStageIsPass(stageId)
    self.TxtFirstResume.gameObject:SetActiveEx(isFirst)
    self.TxtResume.gameObject:SetActiveEx(not isFirst)
    self.TxtResume.text = CS.XTextManager.GetText("FubenHackRepeatResume")
    self.TxtCondition.text = stageInterInfo.ConditionDesc
    self:UpdateRewards()
end

function XUiFubenHackSection:OnSwitchView(type, isFromOtherUi)
    if not isFromOtherUi then
        --self:PlayAnimation("QieHuan")
    end
    self.CurrentView = type

    self.PanelStageInfo.gameObject:SetActiveEx(type == ViewType.StageInfo)
    self.BtnTarget.gameObject:SetActiveEx(type == ViewType.StageInfo)
    self.PanelTargetInfo.gameObject:SetActiveEx(type == ViewType.TargetInfo)
    self.BtnStage.gameObject:SetActiveEx(type == ViewType.TargetInfo)
    if type == ViewType.StageInfo then
        local isRed = not XDataCenter.FubenHackManager.GetReadDetailMark(self.StageId)
        self.BtnTarget:ShowReddot(isRed)
    else
        XDataCenter.FubenHackManager.SetReadDetailMark(self.StageId)
        self.BtnTarget:ShowReddot(false)
    end
end

function XUiFubenHackSection:UpdateRewards()
    if not self.StageId then return end
    local stageId = self.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)

    local rewardId = stageCfg.FinishRewardShow
    local IsFirst = false
    -- 首通有没有填
    local controlCfg = XDataCenter.FubenManager.GetStageLevelControl(stageId)
    -- 有首通
    if not stageInfo.Passed then
        if controlCfg and controlCfg.FirstRewardShow > 0 then
            rewardId = controlCfg.FirstRewardShow
            IsFirst = true
        elseif stageCfg.FirstRewardShow > 0 then
            rewardId = stageCfg.FirstRewardShow
            IsFirst = true
        end
    end

    -- 没首通
    if not IsFirst then
        if controlCfg and controlCfg.FinishRewardShow > 0 then
            rewardId = controlCfg.FinishRewardShow
        else
            rewardId = stageCfg.FinishRewardShow
        end
    end

    local rewards = {}
    if rewardId > 0 then
        rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    end

    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.PanelDropContent)
                grid = XUiGridCommon.New(self, ui)
                self.GridList[i] = grid
            end
            -- 经验值道具特殊处理
            if item.TemplateId == self.ActTemplate.ExpId then
                local itemId = self.ActTemplate.ExpId
                local data = XTool.Clone(XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId))
                data.IsTempItemData = true
                data.OwnCount =  XDataCenter.FubenHackManager.GetTotalExp()
                data.Count =  item.Count
                data.Description = XGoodsCommonManager.GetGoodsDescription(itemId)
                data.WorldDesc = XGoodsCommonManager.GetGoodsWorldDesc(itemId)
                grid:Refresh(data)
            else
                grid:Refresh(item)
            end
            grid.GameObject:SetActive(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.GridList do
        if j > rewardsCount then
            self.GridList[j].GameObject:SetActive(false)
        end
    end

    self.GridCommon.gameObject:SetActiveEx(false)
end

function XUiFubenHackSection:OnBtnEnterClick()
    if not self.StageId then
        XLog.Error("XUiFubenHackSection:OnBtnEnterClick 函数错误: 变量stageId为空 " .. tostring(self.StageId))
        return
    end
    local stageId = self.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    if not stageCfg then
        local path = XFubenConfigs.GetTableStagePath()
        XLog.ErrorTableDataNotFound("XUiFubenHackSection:OnBtnEnterClick", "StageCfg", path, "stageId", tostring(stageId))
        return
    end

    if XDataCenter.FubenManager.CheckPreFight(stageCfg) then
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
        XLuaUiManager.Open("UiBattleRoleRoom", stageCfg.StageId)
        self:Close()
    end
end

function XUiFubenHackSection:OnBtnTargetClick()
    XLuaUiManager.Open("UiFubenHackDetails", self.StageId)
    XDataCenter.FubenHackManager.SetReadDetailMark(self.StageId)
    self.BtnTarget:ShowReddot(false)
end

function XUiFubenHackSection:OnBtnCloseClick()
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
    self:Close()
end