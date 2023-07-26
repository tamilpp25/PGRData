
local XUiMemorySaveDetail = XLuaUiManager.Register(XLuaUi, "UiMemorySaveDetail")

function XUiMemorySaveDetail:OnAwake()
    self:InitAutoScript()
end


function XUiMemorySaveDetail:OnStart(rootUi)
    self.RootUi = rootUi
    self.GridList = {}
end

function XUiMemorySaveDetail:OnEnable()
    self:Refresh(self.RootUi.Stage)
end

function XUiMemorySaveDetail:InitAutoScript()
    self:InItData()
    self:InitUI()
    self:InitCB()
end

function XUiMemorySaveDetail:Refresh(stage)
    self.Stage = stage
    self:UpdateCommon()
    self:UpdateReward()
end

function XUiMemorySaveDetail:UpdateCommon()
    self.TxtTitle.text = self.Stage.Name
    self.PanelNums.gameObject:SetActiveEx(false)
    self.PanelNoLimitCount.gameObject:SetActiveEx(true)
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(self.Stage.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.Stage.StageId)
    for i = 1, 3 do
        self.TargetList[i]:Refresh(self.Stage.StarDesc[i], stageInfo.StarsMap[i])
    end
end

function XUiMemorySaveDetail:UpdateReward()
    local passed = XDataCenter.MemorySaveManager.GetPassStageById(self.Stage.StageId)
    self.PanelDropList.gameObject:SetActiveEx(not passed)
    if passed then --如果通过，则不显示奖励
        return
    end
    local rewardId = 0
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.Stage.StageId)
    if not passed then
        rewardId = stageCfg.FirstRewardShow
    end
    local rewards = XRewardManager.GetRewardList(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.PanelDropContent, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end
end

function XUiMemorySaveDetail:InItData()
    self.TargetList = {}
    for i = 1, 3 do
        self.TargetList[i] = XUiGridStageStar.New(self["GridStageStar"..i])
    end
end

function XUiMemorySaveDetail:InitUI()
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiMemorySaveDetail:InitCB()
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

function XUiMemorySaveDetail:OnBtnEnterClick()
    if not self.Stage then
        XLog.Error("XUiMemorySaveDetail:OnBtnEnterClick: Can not find stage!")
        return
    end
    self.RootUi:OnHideDetailCallBack()
    if XTool.USENEWBATTLEROOM then
        XLuaUiManager.Open("UiBattleRoleRoom", self.Stage.StageId, nil, {
            OnNotify = function(proxy, evt)
                if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
                    XDataCenter.MemorySaveManager.OnActivityEnd()
                end
            end
        })
    else
        XLuaUiManager.Open("UiNewRoomSingle", self.Stage.StageId)
    end
end

function XUiMemorySaveDetail:OnBtnCloseClick()
    self:PlayAnimation("AnimDisableEnd", function ()
        self:Close()
    end)
end