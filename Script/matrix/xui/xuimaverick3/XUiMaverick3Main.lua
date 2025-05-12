local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiMaverick3Main : XLuaUi 孤胆枪手主界面
---@field _Control XMaverick3Control
local XUiMaverick3Main = XLuaUiManager.Register(XLuaUi, "UiMaverick3Main")

function XUiMaverick3Main:OnAwake()
    self.BtnMainLine.CallBack = handler(self, self.OnBtnMainLineClick)
    self.BtnStory.CallBack = handler(self, self.OnBtnStoryClick)
    self.BtnTeaching.CallBack = handler(self, self.OnBtnTeachingClick)
    self.BtnHard.CallBack = handler(self, self.OnBtnHardClick)
    self.BtnRank.CallBack = handler(self, self.OnBtnRankClick)
    self.BtnHandbook.CallBack = handler(self, self.OnBtnHandbookClick)
    self.BtnShop.CallBack = handler(self, self.OnBtnShopClick)
    self.BtnReward.CallBack = handler(self, self.OnBtnRewardClick)
    self.BtnCharacter.CallBack = handler(self, self.OnBtnCharacterClick)
    self:BindHelpBtn(self.BtnHelp, "Maverick3MainHelp")
end

function XUiMaverick3Main:OnStart(param)
    self._Param = param
    self._ActivityCfg = self._Control:GetCurActivityCfg()
    self._InfiniteChapterCfg = self._Control:GetInfiniteChapter()

    self:InitComponent()
    self:InitView()
    self:InitModel()
end

function XUiMaverick3Main:OnEnable()
    self:UpdateMainLineInfo()
    self:UpdateInfiniteInfo()
    self:UpdateShopInfo()
    self:UpdateModel()
    self:UpdateRankData()

    if self._Param and self._Param.IsInit then
        -- 从外面进入活动（不包括战斗返回）
        self._Param.IsInit = false
        self:PlayAnimationWithMask("Enable")
        local mainEnable = self.UiModelGo.transform:FindTransform("MainEnable")
        if not XTool.UObjIsNil(mainEnable) then
            mainEnable:PlayTimelineAnimation()
        end
    else
        if self._IsNeedDelayAnim then
            -- 从角色界面返回需要隐藏UI动画 为了和镜头动画对齐
            self._IsNeedDelayAnim = false
            XLuaUiManager.SetMask(true)
            self._AnimTimer = XScheduleManager.ScheduleOnce(function()
                XLuaUiManager.SetMask(false)
                self:PlayAnimationWithMask("QieHuanEnable")
            end, 1000)
        else
            self:PlayAnimationWithMask("QieHuanEnable")
        end
    end
end

function XUiMaverick3Main:OnDisable()

end

function XUiMaverick3Main:OnDestroy()
    if self._AnimTimer then
        XScheduleManager.UnSchedule(self._AnimTimer)
        self._AnimTimer = nil
    end
end

function XUiMaverick3Main:InitComponent()
    local ItemIds = { XEnumConst.Maverick3.Currency.Cultivate, XEnumConst.Maverick3.Currency.Shop }
    XUiHelper.NewPanelActivityAssetSafe(ItemIds, self.PanelSpecialTool, self)
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
end

function XUiMaverick3Main:InitModel()
    local uiObject = {}
    XUiHelper.InitUiClass(uiObject, self.UiModelGo.transform)
    self._PanelRoleModel = uiObject.PanelRoleModel
    ---@type XUiPanelRoleModel
    self._RoleModelPanel = require("XUi/XUiCharacter/XUiPanelRoleModel").New(self._PanelRoleModel, self.Name, nil, true, false)
end

function XUiMaverick3Main:InitView()
    -- 倒计时
    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        local timeOfNow = XTime.GetServerNowTimestamp()
        self.TxtTime.text = XUiHelper.GetTime(endTime - timeOfNow, XUiHelper.TimeFormatType.ACTIVITY)
        if isClose then
            self._Control:HandleActivityEnd()
        end
        -- 每日奖励倒计时
        self:UpdateDailyRewardInfo()
    end, nil, 0)
    -- 商店物品展示
    local shopRewards = self._Control:GetClientConfigs("ShopRewards")
    XUiHelper.RefreshCustomizedList(self.Grid256New.parent, self.Grid256New, #shopRewards, function(i, go)
        local params = string.Split(shopRewards[i], "_")
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self, go)
        grid:Refresh({ TemplateId = tonumber(params[1]), Count = tonumber(params[2]) })
    end)
    -- 每日奖励
    local taskDataList = XDataCenter.TaskManager:GetMaverick3DailyTaskList()
    if not XTool.IsTableEmpty(taskDataList) then
        local taskTemplate = XDataCenter.TaskManager.GetTaskTemplate(taskDataList[1].Id)
        local rewards = XRewardManager.GetRewardList(taskTemplate.RewardId)
        self.BtnReward:SetNameByGroup(0, rewards[1].Count)
        self.BtnReward:SetRawImage(XDataCenter.ItemManager.GetItemIcon(rewards[1].TemplateId))
    end
end

function XUiMaverick3Main:UpdateRankData()
    -- 提前请求排行榜数据 如果在排行榜界面内请求 UI表现怪怪的
    local chapter = self._Control:GetInfiniteChapter()
    self._Stages = self._Control:GetStagesByChapterId(chapter.ChapterId)
    for _, stage in pairs(self._Stages) do
        self._Control:RequestMaverick3GetRank(stage.StageId)
    end
end

function XUiMaverick3Main:UpdateModel()
    local robotId = self._Control:GetShowRobotId()
    local robotCfg = self._Control:GetRobotById(robotId)
    local characterId = XRobotManager.GetCharacterId(robotCfg.RobotId)
    XDataCenter.DisplayManager.UpdateRoleModel(self._RoleModelPanel, characterId, nil, robotCfg.FashionId)
    self.BtnCharacter:SetNameByGroup(0, XMVCA.XCharacter:GetCharacterName(characterId))
end

function XUiMaverick3Main:UpdateMainLineInfo()
    local curChapterId = self._Control:GetCurChapterId()
    if XTool.IsNumberValid(curChapterId) then
        local chapterCfg = self._Control:GetChapterById(curChapterId)
        local cur, all = self._Control:GetChapterProgress(curChapterId)
        self.TxtChapter.text = chapterCfg.Name
        self.TxtDifficulty.text = XUiHelper.GetText(chapterCfg.Difficult == XEnumConst.Maverick3.Difficulty.Normal and "Maverick3Normal" or "Maverick3Hard")
        self.TxtProgress.text = string.format("%s%%", math.floor(cur / all * 100))
        self.TxtComplete.gameObject:SetActiveEx(false)
    else
        self.TxtChapter.text = ""
        self.TxtDifficulty.text = ""
        self.TxtProgress.text = ""
        self.TxtComplete.gameObject:SetActiveEx(true)
    end
    self.BtnMainLine:ShowReddot(self._Control:IsMainLineNormalRed() or self._Control:IsMainLineHardRed())
end

function XUiMaverick3Main:UpdateInfiniteInfo()
    self._IsHardUnlock, self._HardUnlockDesc = self._Control:IsChapterUnlock(self._InfiniteChapterCfg.ChapterId)
    self.BtnHard:SetButtonState(self._IsHardUnlock and XUiButtonState.Normal or XUiButtonState.Disable)
    if not self._IsHardUnlock then
        self.BtnHard:SetNameByGroup(1, self._HardUnlockDesc)
        self.GridChapter.gameObject:SetActiveEx(false)
        return
    end

    local datas = self._Control:GetStagesByChapterId(self._InfiniteChapterCfg.ChapterId)
    XUiHelper.RefreshCustomizedList(self.GridChapter.parent, self.GridChapter, #datas, function(i, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.TxtName.text = datas[i].Name
        uiObject.TxtScore.text = self._Control:GetInfiniteStageScore(datas[i].StageId)
    end)
    self.BtnHard:ShowReddot(self._Control:IsInfiniteRed())
end

function XUiMaverick3Main:UpdateShopInfo()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        local shopIds = { self._Control:GetCurActivityCfg().ShopId }
        XShopManager.GetShopInfoList(shopIds, function()
            self._IsShopRed = self._Control:IsShopRed()
            self.BtnShop:ShowReddot(self._IsShopRed)
        end, XShopManager.ActivityShopType.Maverick3Shop)
    end
end

function XUiMaverick3Main:UpdateDailyRewardInfo()
    if self._Control:IsDailyRewardCanGain() then
        if self.BtnReward.ButtonState ~= CS.UiButtonState.Normal then
            self.BtnReward:ShowReddot(true)
            self.BtnReward:SetButtonState(XUiButtonState.Normal)
        end
    else
        local leftTime = XTime.GetSeverTomorrowFreshTime() - XTime.GetServerNowTimestamp()
        if leftTime > 0 then
            if self.BtnReward.ButtonState ~= CS.UiButtonState.Disable then
                self.BtnReward:ShowReddot(false)
                self.BtnReward:SetButtonState(CS.UiButtonState.Disable)
            end
            local remainTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.MAIN)
            self.BtnReward:SetNameByGroup(1, XUiHelper.GetText("Maverick3DaliyRewardTime", remainTime))
        end
    end
end

function XUiMaverick3Main:OnBtnMainLineClick()
    self:PlayAnimationWithMask("QieHuanDisable", function()
        XLuaUiManager.Open("UiMaverick3Chapter")
    end)
end

function XUiMaverick3Main:OnBtnStoryClick()
    self:PlayAnimationWithMask("QieHuanDisable", function()
        XLuaUiManager.Open("UiMaverick3Story")
    end)
end

function XUiMaverick3Main:OnBtnTeachingClick()
    self._IsNeedDelayAnim = true
    self:PlayAnimationWithMask("QieHuanDisable", function()
        local teachChapter = self._Control:GetTeachChapter()
        local stages = self._Control:GetStagesByChapterId(teachChapter.ChapterId)
        XLuaUiManager.OpenWithCloseCallback("UiMaverick3Character", handler(self, self.PlayBackAnim), stages[1].StageId)
    end)
end

function XUiMaverick3Main:OnBtnHardClick()
    if not self._IsHardUnlock then
        XUiManager.TipError(self._HardUnlockDesc)
        return
    end
    self:PlayAnimationWithMask("QieHuanDisable", function()
        XLuaUiManager.Open("UiMaverick3PopupHard")
    end)
end

function XUiMaverick3Main:OnBtnRankClick()
    if self._Control:IsRankEmpty() then
        XLog.Error("没有排行榜数据.")
        return
    end
    self:PlayAnimationWithMask("QieHuanDisable", function()
        XLuaUiManager.Open("UiMaverick3Rank")
    end)
end

function XUiMaverick3Main:OnBtnHandbookClick()
    self:PlayAnimationWithMask("QieHuanDisable", function()
        XLuaUiManager.Open("UiMaverick3Handbook")
    end)
end

function XUiMaverick3Main:OnBtnShopClick()
    self:PlayAnimationWithMask("QieHuanDisable", function()
        if self._IsShopRed then
            self._Control:CloseShopRed()
            self:UpdateShopInfo()
        end
        XLuaUiManager.Open("UiMaverick3Shop")
    end)
end

function XUiMaverick3Main:OnBtnRewardClick()
    if not self._Control:IsDailyRewardCanGain() then
        XUiManager.TipError(XUiHelper.GetText("Maverick3DaliyRewardTip"))
        return
    end
    XDataCenter.TaskManager.FinishTask(self._ActivityCfg.DailyTaskGroup, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
    end)
end

function XUiMaverick3Main:OnBtnCharacterClick()
    self._IsNeedDelayAnim = true
    self:PlayAnimationWithMask("QieHuanDisable", function()
        XLuaUiManager.OpenWithCloseCallback("UiMaverick3Character", handler(self, self.PlayBackAnim))
    end)
end

function XUiMaverick3Main:PlayBackAnim()
    local camNormalEnable = self.UiModelGo.transform:FindTransform("CamNormalEnable")
    if not XTool.UObjIsNil(camNormalEnable) then
        camNormalEnable:PlayTimelineAnimation()
    end
end

return XUiMaverick3Main