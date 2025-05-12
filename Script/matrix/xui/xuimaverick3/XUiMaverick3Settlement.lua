local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiMaverick3Settlement : XLuaUi 孤胆枪手结算
local XUiMaverick3Settlement = XLuaUiManager.Register(XLuaUi, "UiMaverick3Settlement")

function XUiMaverick3Settlement:OnAwake()
    self.BtnAgain.CallBack = handler(self, self.OnBtnAgainClick)
    self.BtnRight.CallBack = handler(self, self.Close)
end

function XUiMaverick3Settlement:OnStart(settleData)
    self._StageId = settleData.StageId
    self._Star = settleData.Maverick3SettleResult.Star
    self._IsFirstPass = settleData.Maverick3SettleResult.IsFirstPass
    self._SavedData = settleData.Maverick3SettleResult.RobotSaved
    self._Score = settleData.Maverick3SettleResult.Score
    self._StageConfig = XMVCA.XMaverick3:GetStageById(self._StageId)
    self._ChapterConfig = XMVCA.XMaverick3:GetChapterById(self._StageConfig.ChapterId)

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end, nil, 0)
end

function XUiMaverick3Settlement:OnEnable()
    local characterId = XMVCA.XMaverick3:GetTempFightCharId()
    local robotId = XMVCA.XMaverick3:GetRobotById(characterId).RobotId
    self.RImgRole:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyBigImage(XRobotManager.GetCharacterId(robotId)))
    if self._ChapterConfig.Type == XEnumConst.Maverick3.ChapterType.MainLine then
        -- 关卡目标
        self.PanelTargetList.gameObject:SetActiveEx(true)
        self.PanelScore.gameObject:SetActiveEx(false)
        XUiHelper.RefreshCustomizedList(self.GridStageStar.parent, self.GridStageStar, #self._StageConfig.StarDesc, function(i, go)
            local uiObject = {}
            XUiHelper.InitUiClass(uiObject, go)
            uiObject.PanelUnActive.gameObject:SetActiveEx(self._Star < i)
            uiObject.PanelActive.gameObject:SetActiveEx(self._Star >= i)
            uiObject.TxtUnActive.text = self._StageConfig.StarDesc[i]
            uiObject.TxtActive.text = self._StageConfig.StarDesc[i]
        end, true)
    else
        -- 分数
        self.PanelTargetList.gameObject:SetActiveEx(false)
        self.PanelScore.gameObject:SetActiveEx(true)
        self.TxtScore.text = self._Score
    end
    -- 数据统计
    self.TxtTime.text = XUiHelper.GetTime(math.floor(self._SavedData.UseTime))
    self.TxtRevive.text = self._SavedData.DeadCount
    -- 奖励
    local totalRewards = {}
    if XTool.IsNumberValid(self._StageConfig.FirstRewardId) and self._IsFirstPass then
        local rewards = XRewardManager.GetRewardList(self._StageConfig.FirstRewardId)
        for _, v in ipairs(rewards) do
            table.insert(totalRewards, {
                TemplateId = v.TemplateId,
                Count = v.Count,
                IsFirstReward = true,
            })
        end
    end
    if XTool.IsNumberValid(self._StageConfig.FinishRewardId) then
        local finishRewards = XRewardManager.GetRewardList(self._StageConfig.FinishRewardId)
        for _, v in ipairs(finishRewards) do
            table.insert(totalRewards, v)
        end
    end
    XUiHelper.RefreshCustomizedList(self.Grid256New.parent, self.Grid256New, #totalRewards, function(i, go)
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self, go)
        grid:Refresh(totalRewards[i])
        grid:SetPanelFirst(totalRewards[i].IsFirstReward)
    end, true)
end

function XUiMaverick3Settlement:OnBtnAgainClick()
    XMVCA.XMaverick3:RequestMaverick3ExitStage(self._StageId, function()
        XMVCA.XFuben:EnterFightByStageId(self._StageId, nil, false, 1, nil, function()
            self:Close()
        end)
    end)
end

return XUiMaverick3Settlement