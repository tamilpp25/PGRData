local XUiFashionStoryStageTrialDetailNew = XLuaUiManager.Register(XLuaUi, "UiFashionStoryStageTrialDetailNew")

--region 生命周期
function XUiFashionStoryStageTrialDetailNew:OnAwake()
    self.RewardList = {}
    self:AddListener()
end

function XUiFashionStoryStageTrialDetailNew:OnStart(trialStageId,closeParentCb,CloseTrialDetailCb)
    self.StageId = trialStageId
    self.CloseParentCb = closeParentCb
    self.CloseTrialDetailCb = CloseTrialDetailCb

    self:Refresh()
end

function XUiFashionStoryStageTrialDetailNew:OnEnable(trialStageId,closeParentCb,CloseTrialDetailCb)

    if trialStageId then self.StageId = trialStageId end
    if closeParentCb then self.CloseParentCb = closeParentCb end
    if CloseTrialDetailCb then self.CloseTrialDetailCb = CloseTrialDetailCb end

    self:Refresh()
end
--endregion

--region 初始化
function XUiFashionStoryStageTrialDetailNew:AddListener()
    self.BtnBack.CallBack = function()
        if self.CloseTrialDetailCb then
            self.CloseTrialDetailCb()
        end
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
end
--endregion

--region 事件处理
function XUiFashionStoryStageTrialDetailNew:OnBtnEnterClick()
    local leftTimeStamp = XDataCenter.FashionStoryManager.GetLeftTimeStamp(XDataCenter.FashionStoryManager.GetCurrentActivityId())
    if leftTimeStamp <= 0 then
        XUiManager.TipText("FashionStoryActivityEnd")
        self.CloseParentCb()
        return
    end

    local isInTime = XDataCenter.FashionStoryManager.IsTrialStageInTime(self.StageId)
    if isInTime then
        XLuaUiManager.Open("UiNewRoomSingle", self.StageId)
    else
        XUiManager.TipText("FashionStoryTrialStageEnd")
    end
end
--endregion

--region 数据更新
function XUiFashionStoryStageTrialDetailNew:Refresh()
    -- 图标
    self.RImgNandu:SetRawImage(XFashionStoryConfigs.GetTrialDetailHeadIcon(self.StageId))

    -- 名称
    self.TxtTitle.text = XFubenConfigs.GetStageName(self.StageId)

    -- 推荐等级
    self.TxtRecommendLevel.text = XFashionStoryConfigs.GetTrialDetailRecommendLevel(self.StageId)

    -- 背景
    self.ImgFullScreen.gameObject:SetActiveEx(true)
    self.PanelSpine.gameObject:SetActiveEx(false)
    local spine = XFashionStoryConfigs.GetTrialDetailSpine(self.StageId)
    if spine then
        self.PanelSpine.gameObject:SetActiveEx(true)
        self.PanelSpine.gameObject:LoadSpinePrefab(spine)
    else
        self.ImgFullScreen.gameObject:SetActiveEx(true)
        self.ImgFullScreen:SetRawImage(XFashionStoryConfigs.GetTrialDetailBg(self.StageId))
    end

    -- 描述
    self.TxtDes.text = string.gsub(XFashionStoryConfigs.GetTrialDetailDesc(self.StageId), "\\n", "\n")

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
--endregion

return XUiFashionStoryStageTrialDetailNew