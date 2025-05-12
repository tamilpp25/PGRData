local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiFashionStoryStageTrialDetail = XLuaUiManager.Register(XLuaUi, "UiFashionStoryStageTrialDetail")

function XUiFashionStoryStageTrialDetail:OnAwake()
    self.RewardList = {}
    self:AddListener()
end

function XUiFashionStoryStageTrialDetail:OnStart(closeParentCb,CloseTrialDetailCb)
    self.CloseParentCb = closeParentCb
    self.CloseTrialDetailCb = CloseTrialDetailCb
end

function XUiFashionStoryStageTrialDetail:AddListener()
    self.BtnBack.CallBack = function()
        self.CloseTrialDetailCb()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
end

function XUiFashionStoryStageTrialDetail:OnBtnEnterClick()
    local leftTimeStamp = XDataCenter.FashionStoryManager.GetLeftTimeStamp(self.ActivityId)
    if leftTimeStamp <= 0 then
        XUiManager.TipText("FashionStoryActivityEnd")
        self.CloseParentCb()
        return
    end

    local isInTime = XDataCenter.FashionStoryManager.IsTrialStageInTime(self.StageId)
    if isInTime then
        XLuaUiManager.Open("UiBattleRoleRoom", self.StageId)
    else
        XUiManager.TipText("FashionStoryTrialStageEnd")
    end
end

function XUiFashionStoryStageTrialDetail:Refresh(activityId, stageId)
    self.ActivityId = activityId
    self.StageId = stageId

    -- 图标
    self.RImgNandu:SetRawImage(XFashionStoryConfigs.GetTrialDetailHeadIcon(stageId))

    -- 名称
    self.TxtTitle.text = XFubenConfigs.GetStageName(stageId)

    -- 推荐等级
    self.TxtRecommendLevel.text = XFashionStoryConfigs.GetTrialDetailRecommendLevel(stageId)

    -- 背景
    self.ImgFullScreen.gameObject:SetActiveEx(true)
    self.PanelSpine.gameObject:SetActiveEx(false)
    local spine = XFashionStoryConfigs.GetTrialDetailSpine(stageId)
    if spine then
        self.PanelSpine.gameObject:SetActiveEx(true)
        self.PanelSpine.gameObject:LoadSpinePrefab(spine)
    else
        self.ImgFullScreen.gameObject:SetActiveEx(true)
        self.ImgFullScreen:SetRawImage(XFashionStoryConfigs.GetTrialDetailBg(stageId))
    end

    -- 描述
    self.TxtDes.text = string.gsub(XFashionStoryConfigs.GetTrialDetailDesc(stageId), "\\n", "\n")

    -- 奖励
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
            local reward = self.RewardList[i]
            if not reward then
                local obj = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.PanelDropContent)
                reward = XUiGridCommon.New(self, obj)
                table.insert(self.RewardList, reward)
            end
            local temp = { ShowReceived = isPass }
            reward:Refresh(rewardsList[i], temp)
        end
    end

    -- 隐藏多余的奖励格子
    local gridCommonCount = #self.RewardList
    if gridCommonCount > rewardCount then
        for j = rewardCount + 1, gridCommonCount do
            self.RewardList[j]:Refresh()
        end
    end
end