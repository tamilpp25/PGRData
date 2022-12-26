local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiKillZoneStageDetail = XLuaUiManager.Register(XLuaUi, "UiKillZoneStageDetail")

function XUiKillZoneStageDetail:OnAwake()
    self:AutoAddListener()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
    {
        XKillZoneConfigs.ItemIdCoinA,
        XKillZoneConfigs.ItemIdCoinB,
    }, handler(self, self.UpdateAssets), self.AssetActivityPanel)

    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiKillZoneStageDetail:OnStart(stageId, closeCb)
    self.StageId = stageId
    self.CloseCb = closeCb

    self.BuffGrids = {}
    self.StarDescGrids = {}
    self.RewardGrids = {}
end

function XUiKillZoneStageDetail:OnEnable()
    self:UpdateAssets()
    self:UpdateView()
end

function XUiKillZoneStageDetail:OnDestroy()
    if self.CloseCb then self.CloseCb() end
end

function XUiKillZoneStageDetail:UpdateAssets()
    self.AssetActivityPanel:Refresh({
        XKillZoneConfigs.ItemIdCoinA,
        XKillZoneConfigs.ItemIdCoinB,
    })
end

function XUiKillZoneStageDetail:UpdateView()
    local stageId = self.StageId

    local name = XKillZoneConfigs.GetStageName(stageId)
    self.TxtTitle.text = name

    --关卡词缀
    local buffIds = XKillZoneConfigs.GetStageBuffIds(stageId)
    for index, buffId in ipairs(buffIds) do
        local grid = self.BuffGrids[index]
        if not grid then
            local go = index == 1 and self.GridBuff or CSUnityEngineObjectInstantiate(self.GridBuff, self.PanelBuffContent)
            grid = XTool.InitUiObjectByUi({}, go)
            self.BuffGrids[index] = grid
        end

        local icon = XKillZoneConfigs.GetBuffIcon(buffId)
        grid.RImgIcon:SetRawImage(icon)

        grid.GameObject:SetActiveEx(true)
    end
    for index = #buffIds + 1, #self.BuffGrids do
        self.BuffGrids[index].GameObject:SetActiveEx(false)
    end

    local isBuffEmpty = #buffIds <= 0
    self.PanelBuffNone.gameObject:SetActiveEx(isBuffEmpty)
    self.BtnBuffTip.gameObject:SetActiveEx(not isBuffEmpty)

    --通关条件
    local passDesc = XKillZoneConfigs.GetStagePassDesc(stageId)
    self.TxtTip.text = passDesc
    self.TxtTipNone.text = passDesc

    local isPassed = XDataCenter.KillZoneManager.IsStageFinished(stageId)
    self.TxtTip.gameObject:SetActiveEx(isPassed)
    self.TxtTipNone.gameObject:SetActiveEx(not isPassed)

    --星级条件
    local currentStar = XDataCenter.KillZoneManager.GetStageStar(stageId)
    local starDescList = XKillZoneConfigs.GetStageStarDescList(stageId)
    for star, desc in ipairs(starDescList) do
        local grid = self.StarDescGrids[star]
        if not grid then
            local go = star == 1 and self.GridStageStar or CSUnityEngineObjectInstantiate(self.GridStageStar, self.PanelTargetList)
            grid = XTool.InitUiObjectByUi({}, go)
            self.StarDescGrids[star] = grid
        end

        if currentStar < star then
            grid.TxtTipNone.text = desc
            grid.IconStarNone.gameObject:SetActiveEx(true)
            grid.TxtTipNone.gameObject:SetActiveEx(true)
            grid.IconStar.gameObject:SetActiveEx(false)
            grid.TxtTip.gameObject:SetActiveEx(false)
        else
            grid.TxtTip.text = desc
            grid.IconStar.gameObject:SetActiveEx(true)
            grid.TxtTip.gameObject:SetActiveEx(true)
            grid.IconStarNone.gameObject:SetActiveEx(false)
            grid.TxtTipNone.gameObject:SetActiveEx(false)
        end

        grid.GameObject:SetActiveEx(true)
    end

    --首通奖励
    if not isPassed then
        local rewardId = XFubenConfigs.GetFirstRewardShow(stageId)
        local rewards = XRewardManager.GetRewardList(rewardId)
        if rewards then
            for index, item in ipairs(rewards) do
                local grid = self.RewardGrids[index]

                if not grid then
                    local ui = index == 1 and self.GridCommon or CSUnityEngineObjectInstantiate(self.GridCommon, self.PanelDropContent)
                    grid = XUiGridCommon.New(self, ui)
                    self.RewardGrids[index] = grid
                end

                grid:Refresh(item)
                grid.GameObject:SetActiveEx(true)
            end
        end
        for index = #rewards + 1, #self.RewardGrids do
            self.RewardGrids[index].GameObject:SetActiveEx(false)
        end

        self.PanelDropNone.gameObject:SetActiveEx(false)
        self.PanelDropContent.gameObject:SetActiveEx(true)
    else
        self.PanelDropContent.gameObject:SetActiveEx(false)
        self.PanelDropNone.gameObject:SetActiveEx(true)
    end
end

function XUiKillZoneStageDetail:AutoAddListener()
    self.BtnEnter.CallBack = function() self:OnClickBtnEnter() end
    self.BtnBuffTip.CallBack = function() self:OnClickBtnBuffTip() end
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiKillZoneStageDetail:OnClickBtnEnter()
    local stageId = self.StageId
    XLuaUiManager.Open("UiNewRoomSingle", stageId)
end

function XUiKillZoneStageDetail:OnClickBtnBuffTip()
    local buffIds = XKillZoneConfigs.GetStageBuffIds(self.StageId)
    if not XTool.IsTableEmpty(buffIds) then
        XLuaUiManager.Open("UiKillZoneBuffTips", self.StageId)
    end
end