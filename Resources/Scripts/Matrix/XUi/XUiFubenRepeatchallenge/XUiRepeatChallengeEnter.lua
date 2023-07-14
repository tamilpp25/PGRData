local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.red,
}

local XUiRepeatChallengeEnter = XLuaUiManager.Register(XLuaUi, "UiRepeatChallengeEnter")

function XUiRepeatChallengeEnter:OnAwake()
    self:AutoAddListener()
    self.GridCommon.gameObject:SetActive(false)
end

function XUiRepeatChallengeEnter:OnStart(stage)
    self.Stage = stage
    self.StageId = stage.StageId
    self.GridList = {}
    self:ChangeChallengeCount(1)
end

function XUiRepeatChallengeEnter:OnEnable()
    self:Refresh()
end

function XUiRepeatChallengeEnter:Refresh()
    self:UpdateRewards()
end

function XUiRepeatChallengeEnter:ChangeChallengeCount(newCount)
    local stageId = self.StageId
    if not XDataCenter.FubenManager.CheckChallengeCount(stageId, newCount) then
        return
    end

    self.ChallengeCount = newCount
    self.TxtChallengeNum.text = newCount
    self.TxtRewardNum.text = "X" .. newCount

    local canSub = XDataCenter.FubenManager.CheckChallengeCount(stageId, newCount - 1)
    self.BtnSub.gameObject:SetActiveEx(canSub)
    self.ImgCantSub.gameObject:SetActiveEx(not canSub)

    local canAdd = XDataCenter.FubenManager.CheckChallengeCount(stageId, newCount + 1)
    self.BtnAdd.gameObject:SetActiveEx(canAdd)
    self.ImgCantAdd.gameObject:SetActiveEx(not canAdd)

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.TxtATNums.text = stageCfg.RequireActionPoint * newCount

    local exConsumeId, exConsumeNum = XDataCenter.FubenManager.GetStageExCost(stageId)
    if exConsumeId ~= 0 and exConsumeNum ~= 0 then
        local exHaveNum = XDataCenter.ItemManager.GetCount(exConsumeId)
        self.TxtCostNum.color = CONDITION_COLOR[exHaveNum >= exConsumeNum]
        self.TxtCostNum.text = exConsumeNum * newCount
        self.RawImgCostIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(exConsumeId))
        self.PanelCostEx.gameObject:SetActiveEx(true)
    else
        self.PanelCostEx.gameObject:SetActiveEx(false)
    end
end

function XUiRepeatChallengeEnter:UpdateRewards()
    local stageId = self.StageId
    local cfg = XDataCenter.FubenManager.GetStageLevelControl(stageId)
    local rewardId = cfg and cfg.FinishRewardShow

    if not rewardId or rewardId == 0 then
        self.PanelRewards.gameObject:SetActiveEx(false)
        return
    else
        self.PanelRewards.gameObject:SetActiveEx(true)
    end

    local rewards = XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.PanelRewards, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
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
end

function XUiRepeatChallengeEnter:AutoAddListener()
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSub, self.OnClickBtnSub)
    self:RegisterClickEvent(self.BtnMax, self.OnClickBtnMax)
    self:RegisterClickEvent(self.BtnAdd, self.OnClickBtnAdd)
end

function XUiRepeatChallengeEnter:OnBtnCloseClick()
    self:Close()
end

function XUiRepeatChallengeEnter:OnBtnEnterClick()
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Main_huge)
    self:Close()
    if XDataCenter.FubenManager.CheckPreFight(self.Stage, self.ChallengeCount) then
        local data = {ChallengeCount = self.ChallengeCount}
        XLuaUiManager.Open("UiNewRoomSingle", self.StageId, data)
    end
end

function XUiRepeatChallengeEnter:OnClickBtnSub()
    self:ChangeChallengeCount(self.ChallengeCount - 1)
end

function XUiRepeatChallengeEnter:OnClickBtnAdd()
    self:ChangeChallengeCount(self.ChallengeCount + 1)
end

function XUiRepeatChallengeEnter:OnClickBtnMax()
    self:ChangeChallengeCount(XDataCenter.FubenManager.GetStageMaxChallengeCount(self.StageId))
end