local XUiFashionStoryStageFightDetail = XLuaUiManager.Register(XLuaUi, "UiFashionStoryStageFightDetail")

local MAX_STAR = 3

function XUiFashionStoryStageFightDetail:OnAwake()
    self.StarGridList = {}
    self.CommonGridList = {}
    self.GridCommonList = {}

    self:InitComponent()
    self:AddListener()
end

function XUiFashionStoryStageFightDetail:OnStart(closeParentCb)
    self.CloseParentCb = closeParentCb
end

function XUiFashionStoryStageFightDetail:InitComponent()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
            XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)

    for i = 1, MAX_STAR do
        self.StarGridList[i] = XUiGridStageStar.New(self[string.format("GridStageStar%d", i)])
    end

    self.GridCommon.gameObject:SetActiveEx(false)
end


-----------------------------------------------按钮响应函数---------------------------------------------------------------

function XUiFashionStoryStageFightDetail:AddListener()
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
end

function XUiFashionStoryStageFightDetail:OnBtnEnterClick()
    local leftTimeStamp = XDataCenter.FashionStoryManager.GetLeftTimeStamp(self.ActivityId)
    if leftTimeStamp <= 0 then
        XUiManager.TipText("FashionStoryActivityEnd")
        self.CloseParentCb()
        return
    end

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if XDataCenter.FubenManager.CheckPreFight(stageCfg) then
        XEventManager.DispatchEvent(XEventId.EVENT_FASHION_STORY_CLOSE_STAGE_DETAIL)
        XLuaUiManager.Open("UiBattleRoleRoom", self.StageId)
    end
end


---------------------------------------------------刷新------------------------------------------------------------------

function XUiFashionStoryStageFightDetail:Refresh(stageId, activityId)
    self.StageId = stageId
    self.ActivityId = activityId

    -- 名称
    self.TxtTitle.text = XDataCenter.FubenManager.GetStageName(stageId)

    -- 关卡通关描述
    local starDescList = XFubenConfigs.GetStarDesc(stageId)
    for i = 1, MAX_STAR do
        self.StarGridList[i]:Refresh(starDescList[i], false)
    end

    self:UpdateRewards()
end

---
--- 刷新掉落奖励
function XUiFashionStoryStageFightDetail:UpdateRewards()
    local rewardId = XFubenConfigs.GetFirstRewardShow(self.StageId)
    local rewardCount = 0

    if rewardId > 0 then
        local rewardsList = XRewardManager.GetRewardList(rewardId)
        if not rewardsList then
            return
        end
        rewardCount = #rewardsList
        
        local isPass = XDataCenter.FubenManager.CheckStageIsPass(self.StageId)
        for i = 1, rewardCount do
            local reward = self.GridCommonList[i]
            if not reward then
                local obj = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.PanelDropContent)
                reward = XUiGridCommon.New(self, obj)
                table.insert(self.GridCommonList, reward)
            end
            local temp = { ShowReceived = isPass }
            reward:Refresh(rewardsList[i], temp)
        end
    end

    -- 隐藏多余的奖励格子
    local gridCommonCount = #self.GridCommonList
    if gridCommonCount > rewardCount then
        for j = rewardCount + 1, gridCommonCount do
            self.GridCommonList[j]:Refresh()
        end
    end
end

function XUiFashionStoryStageFightDetail:CloseDetailWithAnimation()
    self:PlayAnimation("AnimClose", function()
        self:Close()
    end)
end