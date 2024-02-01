local XUiPartnerTeachingFightDetail = XLuaUiManager.Register(XLuaUi, "UiPartnerTeachingFightDetail")

local MAX_STAR = 3

function XUiPartnerTeachingFightDetail:OnAwake()
    self.StarGridList = {}
    self.CommonGridList = {}
    self.GridList = {}

    self:InitComponent()
    self:AddListener()
end

function XUiPartnerTeachingFightDetail:OnStart(closeParentCb)
    self.CloseParentCb = closeParentCb
end

function XUiPartnerTeachingFightDetail:InitComponent()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
            XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)

    for i = 1, MAX_STAR do
        self.StarGridList[i] = XUiGridStageStar.New(self[string.format("GridStageStar%d", i)])
    end
end

-----------------------------------------------按钮响应函数---------------------------------------------------------------
function XUiPartnerTeachingFightDetail:AddListener()
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
end

function XUiPartnerTeachingFightDetail:OnBtnEnterClick()
    local isUnlockChapter = XDataCenter.PartnerTeachingManager.WhetherUnLockChapter(self.ChapterId)
    if not isUnlockChapter then
        XUiManager.TipMsg(CSXTextManagerGetText("PartnerTeachingActivityEnd"))
        self.CloseParentCb()
        return
    end

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if XDataCenter.FubenManager.CheckPreFight(stageCfg) then
        XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_TEACHING_CLOSE_STAGE_DETAIL)
        XLuaUiManager.Open("UiBattleRoleRoom", self.StageId)
    end
end

---------------------------------------------------刷新------------------------------------------------------------------
function XUiPartnerTeachingFightDetail:Refresh(stageId, chapterId)
    self.StageId = stageId
    self.ChapterId = chapterId

    -- 名称
    self.TxtTitle.text = XDataCenter.FubenManager.GetStageName(stageId)

    -- 关卡通关描述
    local starDescList = XFubenConfigs.GetStarDesc(stageId)
    for i = 1, MAX_STAR do
        self.StarGridList[i]:Refresh(starDescList[i], false)
    end

    -- 需要的消耗体力
    self.ImgCostIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.ActionPoint))
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(stageId)

    self:UpdateRewards()
end

---
--- 刷新掉落奖励
function XUiPartnerTeachingFightDetail:UpdateRewards()
    local rewardId
    local isFirst = not XDataCenter.FubenManager.CheckStageIsPass(self.StageId)
    if isFirst then
        rewardId = XFubenConfigs.GetFirstRewardShow(self.StageId)
    else
        rewardId = XFubenConfigs.GetFinishRewardShow(self.StageId)
    end

    -- 可能掉落
    self.TxtDrop.gameObject:SetActiveEx(not isFirst)
    -- 首通奖励
    self.TxtFirstDrop.gameObject:SetActiveEx(isFirst)

    -- 刷新奖励格子
    local rewards
    if rewardId > 0 then
        rewards = isFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    end
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

    -- 隐藏多余的奖励格子
    local rewardCount = rewards and #rewards or 0
    for j = rewardCount + 1, #self.GridList do
        self.GridList[j].GameObject:SetActiveEx(false)
    end
end

function XUiPartnerTeachingFightDetail:OnEnable()

end

function XUiPartnerTeachingFightDetail:OnDisable()

end

function XUiPartnerTeachingFightDetail:CloseDetailWithAnimation()
    self:PlayAnimation("AnimDisableEnd", function()
        self:Close()
    end)
end