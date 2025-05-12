local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGachaLuciaMain : XLuaUi 露西亚卡池
local XUiGachaLuciaMain = XLuaUiManager.Register(XLuaUi, "UiGachaLuciaMain")

function XUiGachaLuciaMain:OnAwake()
    self._CanPlayEnableAnim = false -- 只有进入卡池时会检测播放1次
    self._IsGachaReturnMain = false -- 是否抽卡后返回卡池主界面
    self._ShowCourseRewardTrigger = nil
    self._DoGachaTrigger = nil -- 抽卡触发器，1/10回抽按钮设置，拨动时钟触发
    self._FinishCbTrigger = nil -- 抽卡结束触发器，抽卡请求回调设置，播放完抽卡演出后触发
    self._GachaAllFinishTrigger = nil -- 抽卡全结束触发器，1/10回抽按钮设置，抽卡结果界面关闭后刷新触发
    self._TipCbTrigger = nil -- 奖励弹框
    self._HasBeenKey = "LuciaHasBeenKey"
    self._SkipBtnKey = "UiGachaLucia"
    self._GachaStoryRedPoint = "GachaStoryRedPoint"
    self._TimerStoryRoleEnable = nil
    self._IsParentShow = true
    self._IsCanGacha = true
    self._IsCanGachaClick = true
    ---@type XUiGridCommon[]
    self._GridCourseRewardsDic = {}
    ---@type XUiGridCommon[]
    self._GridBoardRewardsDic = {}
    self._PanelShowDic = {}
    self:InitButton()
    self:Init3DSceneInfo()
end

function XUiGachaLuciaMain:OnStart(gachaId, autoOpenStory)
    self._GachaId = gachaId
    ---@type XTableGacha
    self._GachaCfg = XGachaConfigs.GetGachaCfgById(self._GachaId)
    self._AutoOpenStory = autoOpenStory
    ---@type XUiPanelGachaLuciaVolume
    self._Volume = require("XUi/XUiGachaLucia/Grid/XUiPanelGachaLuciaVolume").New(self.PanelVolume, self)
    self._Volume:HideAll()

    -- 跳过按钮,只有在进入ui时自动刷新1次
    local isSelect = XSaveTool.GetData(self._SkipBtnKey)
    local state = isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.BtnSkip:SetButtonState(state)

    self._CanPlayEnableAnim = true

    local timeId = self._GachaCfg.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        else
            local time = XFunctionManager.GetEndTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
            self.TxtTime.text = XUiHelper.GetText("GachaLuciaTime", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER))
        end
    end, nil, 0)

    self.BtnTemp.gameObject:SetActiveEx(false)
    self._AnimEnableLongLoop = self:FindTransform("AnimEnableLongLoop")
    self._AnimDisableLong = self:FindTransform("AnimDisableLong")

    -- 资源栏
    local managerItems = XDataCenter.ItemManager.ItemId
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ managerItems.PaidGem, managerItems.HongKa, self._GachaCfg.ConsumeId }, self.PanelSpecialTool, self)
    self.AssetPanel:SetButtonCb(3, function()
        self:OpenGachaItemShop()
    end)
end

function XUiGachaLuciaMain:OnEnable()
    -- 顺序不能改表
    -- 1.先检测是否需要打开子界面 -- 【需要的话】就不进行enable动画播放 且直接刷新红点
    -- 2.【不需要的话】就开始播放enable动画，且必须在动画播完后再刷新红点
    if not self.Panel3D or XTool.UObjIsNil(self.Panel3D.GameObject) then
        self:Init3DSceneInfo() -- 战斗回来后场景会被销毁，需要判空再加载1次
    end
    self:RefreshUiShow()
    self:AutoOpenChild()
    if self._IsGachaReturnMain then
        self.AssetPanel:Open()
        self.GachaButtonsEnable:PlayTimelineAnimation()
        self.Panel3D.AnimStart1:PlayTimelineAnimation()
    elseif self._CanPlayEnableAnim then
        self:PlayEnableAnim()
    else
        self:PlayAnimation("AnimStart1")
        self:RefreshReddot()
        self:SetXPostFaicalControllerActive(true)
    end
    -- 显示获得道具弹框
    if self._TipCbTrigger then
        self._TipCbTrigger()
        self._TipCbTrigger = nil
    end
    self._IsGachaReturnMain = false
end

function XUiGachaLuciaMain:OnDisable()
    -- 本地缓存skip按钮状态
    local isSelect = self.BtnSkip:GetToggleState()
    XSaveTool.SaveData(self._SkipBtnKey, isSelect)

    -- 离开界面时关闭视线跟随
    self:SetXPostFaicalControllerActive(false)

    if self._TimerStoryRoleEnable then
        XScheduleManager.UnSchedule(self._TimerStoryRoleEnable)
        self._TimerStoryRoleEnable = nil
    end

    if self._LongAnimTimer then
        XScheduleManager.UnSchedule(self._LongAnimTimer)
        self._LongAnimTimer = nil
    end
end

function XUiGachaLuciaMain:OnDestroy()
    self._ShowCourseRewardTrigger = nil
    self._DoGachaTrigger = nil
    --self.LightControlTimeline:Stop()
end

-- 记录战斗前后数据
function XUiGachaLuciaMain:OnReleaseInst()
    return {
        IsGoFight = true
    }
end

function XUiGachaLuciaMain:OnResume(data)
    data = data or {}
    self._IsGoFight = data.IsGoFight
end

function XUiGachaLuciaMain:SetSelfActive(flag)
    self.PanelGachaGroup.gameObject:SetActiveEx(flag)
    self:SetXPostFaicalControllerActive(flag)
    self._IsParentShow = flag
    if flag then
        self.AssetPanel:Open()
    else
        self.AssetPanel:Close()
    end
end

function XUiGachaLuciaMain:InitButton()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function()
        XLuaUiManager.RunMain()
    end)
    self:RegisterClickEvent(self.BtnGacha, function()
        self:OnBtnGachaClick(self._GachaCfg.BtnGachaCount[1])
    end)
    self:RegisterClickEvent(self.BtnGacha2, function()
        self:OnBtnGachaClick(self._GachaCfg.BtnGachaCount[2])
    end)
    self:RegisterClickEvent(self.BtnSkipGacha, self.OnBtnSkipGachaClick)
    self:RegisterClickEvent(self.BtnStoryLine, self.OnBtnStoryLineClick)
    self:RegisterClickEvent(self.BtnAward, function()
        XLuaUiManager.Open("UiGachaLuciaLog", self._GachaCfg, 1)
    end)
    self:RegisterClickEvent(self.BtnHelp, function()
        XLuaUiManager.Open("UiGachaLuciaLog", self._GachaCfg)
    end)
    self:RegisterClickEvent(self.BtnSet, function()
        XLuaUiManager.Open("UiSet")
    end)
    self.BtnTemp.CallBack = handler(self, self.PlayInteraction)
end

function XUiGachaLuciaMain:Init3DSceneInfo()
    if not self.UiSceneInfo or XTool.UObjIsNil(self.UiSceneInfo.Transform) then
        self:LoadUiScene(self:GetDefaultSceneUrl(), self:GetDefaultUiModelUrl())
    end

    self.Panel3D = {}
    XTool.InitUiObjectByUi(self.Panel3D, self.UiSceneInfo.Transform) -- 将场景的内容和镜头的内容加到1个table里
    XTool.InitUiObjectByUi(self.Panel3D, self.UiModelGo.transform) -- 3d镜头的ui

    ---- 阴影要放在武器模型加载完之后
    if not XTool.UObjIsNil(self.Panel3D.ModelLucia) then
        CS.XShadowHelper.AddShadow(self.Panel3D.ModelLucia.gameObject, true)
    end

    --- 卡池场景为白昼 不受电量和实际时间的影响
    local animationRoot = self.UiSceneInfo.Transform:Find("Animations")
    local fullTimeLine = animationRoot:Find("FullTimeLine"):GetComponent("PlayableDirector")
    if fullTimeLine then
        fullTimeLine.gameObject:SetActiveEx(true)
    end
    self._ChoukaAudioDisable = self.UiModelGo.transform:FindTransform("ChoukaAudioDisable")
end

function XUiGachaLuciaMain:OnChildClose()
    self:SetSelfActive(true)
    self:RefreshUiShow()
    self.Panel3D.AnimEnableStory.gameObject:SetActiveEx(false)

    if self._CanPlayEnableAnim then
        self:PlayEnableAnim()
    else
        self:PlayAnimation("AnimStart1")
        self.Panel3D.AnimDisableStory.gameObject:SetActiveEx(true)
        self.Panel3D.AnimDisableStory:PlayTimelineAnimation()
        self:RefreshReddot()
        self:SetXPostFaicalControllerActive(true)
    end

    self.Panel3D.UiFarCamStory.gameObject:SetActiveEx(false)
    self.Panel3D.UiNearCamStory.gameObject:SetActiveEx(false)

    if self._TimerStoryRoleEnable then
        XScheduleManager.UnSchedule(self._TimerStoryRoleEnable)
        self._TimerStoryRoleEnable = nil
    end
end

function XUiGachaLuciaMain:AutoOpenChild()
    if self._AutoOpenStory then
        self:OnBtnStoryLineClick(true)
        self._AutoOpenStory = nil
    elseif self._IsGoFight then
        self:OnBtnStoryLineClick()
        self._IsGoFight = nil
    end
end

-- 开启/关闭角色的视线跟随
function XUiGachaLuciaMain:SetXPostFaicalControllerActive(flag)
    if XTool.UObjIsNil(self.Panel3D.ModelLucia) then
        return
    end
    local targetComponent = self.Panel3D.ModelLucia:GetComponent(typeof(CS.XPostFaicalController))
    if not targetComponent then
        return
    end
    if flag and not targetComponent.enabled then
        targetComponent.enabled = true
    end
    targetComponent:ActiveInput(flag)
end

function XUiGachaLuciaMain:SetXPostFaicalControllerEnable(flag)
    if XTool.UObjIsNil(self.Panel3D.ModelLucia) then
        return
    end
    local targetComponent = self.Panel3D.ModelLucia:GetComponent(typeof(CS.XPostFaicalController))
    if not targetComponent then
        return
    end

    targetComponent.enabled = flag
end

function XUiGachaLuciaMain:PlayEnableAnim()
    if not self._IsParentShow then
        return
    end
    self._CanPlayEnableAnim = false

    self:SetXPostFaicalControllerActive(false)

    local isSkip = XSaveTool.GetData(self._SkipBtnKey)
    ---- 如果勾了跳过演出 就播放短动画 否则播放长动画
    if isSkip then
        self:RefreshReddot()
        self:PlayShortEnableAnim()
    else
        self:PlayLongEnableAnim()
        local hasBeen = XSaveTool.GetData(self._HasBeenKey)
        if not hasBeen then
            -- 如果第一次进来播长动画，自动勾上跳过
            self.BtnSkip:SetButtonState(CS.UiButtonState.Select)
            XSaveTool.SaveData(self._HasBeenKey, 1)
        end
    end
end

function XUiGachaLuciaMain:PlayLongEnableAnim()
    self._Volume:PlayStart()
    self.Panel3D.AnimStart1:StopTimelineAnimation()
    self:PlayAnimation("AnimEnableLong")
    self:_PlayAnimNextFrame(function()
        self.Panel3D.AnimEnableLong.gameObject:SetActiveEx(true)
        self:_PlayTimeLineAnim(self.Panel3D.AnimEnableLong)
    end)
    self._LongAnimTimer = XScheduleManager.ScheduleOnce(function()
        self.Panel3D.AnimEnableLong.gameObject:SetActiveEx(false)
        self:StopAnimation("AnimEnableLong")
        self:PlayAnimation("AnimEnableLongLoop")
        self.BtnTemp.gameObject:SetActiveEx(true)
        self:_PlayAnimNextFrame(function()
            self:_PlayTimeLineAnim(self.Panel3D.AnimEnableLongLoop)
        end)
    end, math.ceil(self.Panel3D.AnimEnableLong.duration * XScheduleManager.SECOND))
end

-- 点击首席的手继续入场表现
function XUiGachaLuciaMain:PlayInteraction()
    self.BtnTemp.gameObject:SetActiveEx(false)
    self.Panel3D.AnimEnableLongLoop.gameObject:SetActiveEx(false)
    self:StopAnimation("AnimEnableLongLoop")
    self:PlayAnimation("AnimDisableLong")
    self:_PlayAnimNextFrame(function()
        self:_PlayTimeLineAnim(self.Panel3D.AnimDisableLong, nil, nil, function()
            -- 必须要在enable动画完成后打开视线跟随
            self:SetXPostFaicalControllerActive(true)
            self:RefreshReddot()
            self._Volume:PlayEnd()
        end)
    end)
    --self.Panel3D.AnimDisableLong:PlayTimelineAnimation(function()
    --    self:SetXPostFaicalControllerActive(true)
    --    self:RefreshReddot()
    --    self._Volume:PlayEnd()
    --end)
end

function XUiGachaLuciaMain:PlayShortEnableAnim(cb)
    self.AnimEnableShort:PlayTimelineAnimation()
    self.Panel3D.AnimEnableShort:PlayTimelineAnimation(function()
        self:SetXPostFaicalControllerActive(true)
        if cb then
            cb()
        end
    end)
end

function XUiGachaLuciaMain:RefreshUiShow()
    -- 奖励展示滚动
    local PanelAwardShow = {}
    XTool.InitUiObjectByUi(PanelAwardShow, self.PanelAwardShow)
    local rewardRareLevelList = XDataCenter.GachaManager.GetGachaRewardSplitByRareLevel(self._GachaId)
    for i, group in ipairs(rewardRareLevelList) do
        local Panel = self._PanelShowDic[i]
        if XTool.IsTableEmpty(Panel) then
            Panel = {}
            self._PanelShowDic[i] = Panel
            local panelShowUiTrans = PanelAwardShow["PanelShow" .. i]
            if not panelShowUiTrans then
                break
            end
            XTool.InitUiObjectByUi(Panel, panelShowUiTrans)
        end

        for k, v in pairs(group) do
            local searchIndex = i * 10 + k
            local item = self._GridBoardRewardsDic[searchIndex]
            if not item then
                local uiTrans = k == 1 and Panel.GridRewards or Panel["GridRewards" .. k]
                local fashionId = tonumber(XGachaConfigs.GetClientConfig("WeaponFashionId", self._GachaCfg.CourseRewardId))
                item = XUiGridCommon.New(self, uiTrans)
                item:SetCustomWeaopnFashionId(fashionId, XUiHelper.GetText("GachaLuciaFashionDesc"))
                item:SetCustomItemTip(function(data, hideSkipBtn, rootUiName, lackNum)
                    XLuaUiManager.Open("UiGachaLuciaTip", data, hideSkipBtn, rootUiName, lackNum)
                end)
                self._GridBoardRewardsDic[searchIndex] = item
            end

            local tmpData = {}
            tmpData.TemplateId = v.TemplateId
            tmpData.Count = v.Count
            local curCount
            if v.RewardType == XGachaConfigs.RewardType.Count then
                curCount = v.CurCount
            end
            item:Refresh(tmpData, nil, nil, nil, curCount)
        end
    end

    -- 历程
    local curTotalGachaTimes = XDataCenter.GachaManager.GetTotalGachaTimes(self._GachaId)
    local courseReward = XGachaConfigs.GetGachaCourseRewardById(self._GachaCfg.CourseRewardId)
    local gachaBuyTicketRuleConfig = XGachaConfigs.GetGachaItemExchangeCfgById(self._GachaCfg.ExchangeId)
    local totaMaxTimes = gachaBuyTicketRuleConfig.TotalBuyCountMax
    curTotalGachaTimes = curTotalGachaTimes >= totaMaxTimes and totaMaxTimes or curTotalGachaTimes -- 分子不能超过分母
    self.TextProgress.text = curTotalGachaTimes .. "/" .. totaMaxTimes
    local Notes = {}
    for i = 1, #courseReward.LimitDrawTimes, 1 do
        Notes[i] = {}
        XTool.InitUiObjectByUi(Notes[i], self["Note" .. i])
    end

    for i, rewardId in ipairs(courseReward.RewardIds) do
        -- 节点进度条
        local curNoteGachaTime = courseReward.LimitDrawTimes[i] -- 该节点对应的gacha抽次数
        local progresssImg = self["ProgressImgYellow" .. i]
        progresssImg.fillAmount = (curTotalGachaTimes - (courseReward.LimitDrawTimes[i - 1] or 0)) / (curNoteGachaTime - (courseReward.LimitDrawTimes[i - 1] or 0))

        -- 节点奖励
        local rewards = XRewardManager.GetRewardList(rewardId)
        local note = Notes[i]
        note.Txt.text = curNoteGachaTime
        local isReceived = curTotalGachaTimes >= curNoteGachaTime
        if isReceived then
            if self._ShowCourseRewardTrigger and curTotalGachaTimes - 10 < curNoteGachaTime then
                -- 只有刚刚抽到的时候才闪一下
                XUiHelper.PlayAllChildParticleSystem(note.PanelEffect)
            end
            note.PanelEffect.gameObject:SetActiveEx(true)
            note.Select.gameObject:SetActiveEx(true)
        else
            note.PanelEffect.gameObject:SetActiveEx(false)
            note.Select.gameObject:SetActiveEx(false)
        end
        for j, item in pairs(rewards) do
            local searchIndex = curNoteGachaTime + j
            local gridReward = self._GridCourseRewardsDic[searchIndex]
            if not gridReward then
                local ui = CS.UnityEngine.Object.Instantiate(note.GridRewards, note.GridRewards.parent)
                gridReward = XUiGridCommon.New(self, ui)
                gridReward:SetCustomItemTip(function(data, hideSkipBtn, rootUiName, lackNum)
                    XLuaUiManager.Open("UiGachaLuciaTip", data, hideSkipBtn, rootUiName, lackNum)
                end)
                self._GridCourseRewardsDic[searchIndex] = gridReward
            end
            gridReward.GameObject:SetActiveEx(true)
            gridReward:Refresh(item)
            gridReward:SetReceived(isReceived)
        end
    end
    -- 如果抽完卡达到历程奖励 弹奖励提示
    self._ShowCourseRewardTrigger = nil

    -- 抽奖按钮
    local GridBtnGachas = {}
    GridBtnGachas[1] = {}
    GridBtnGachas[2] = {}
    XTool.InitUiObjectByUi(GridBtnGachas[1], self.BtnGacha)
    XTool.InitUiObjectByUi(GridBtnGachas[2], self.BtnGacha2)
    local icon = XDataCenter.ItemManager.GetItemTemplate(self._GachaCfg.ConsumeId).Icon
    GridBtnGachas[1].ImgUseItemIcon:SetRawImage(icon)
    GridBtnGachas[1].TxtUseItemCount.text = self._GachaCfg.ConsumeCount
    GridBtnGachas[2].ImgUseItemIcon:SetRawImage(icon)
    GridBtnGachas[2].TxtUseItemCount.text = self._GachaCfg.ConsumeCount * 10
    -- 按钮显示
    local leftCanGachaCount = totaMaxTimes - curTotalGachaTimes
    self.IsCanGacha1 = leftCanGachaCount > 0
    self.IsCanGacha10 = leftCanGachaCount >= 10
    self.IsGachaTimesEnd = leftCanGachaCount == 0

    self.BtnGacha:SetDisable(not self.IsCanGacha1)
    self.BtnGacha2:SetDisable(not self.IsCanGacha10)
    self.BtnGacha.transform:GetComponent("RawImage").enabled = self.IsCanGacha1
    GridBtnGachas[2].BtnGacha2.enabled = self.IsCanGacha10
    GridBtnGachas[2].RImg1.gameObject:SetActiveEx(leftCanGachaCount >= 1 and leftCanGachaCount < 10)
    GridBtnGachas[2].RImg2.gameObject:SetActiveEx(self.IsGachaTimesEnd)

    if not self.IsCanGacha1 then
        GridBtnGachas[1].ImgUseItemIcon.gameObject:SetActiveEx(false)
        GridBtnGachas[1].TxtUseItemCount.gameObject:SetActiveEx(false)
    end
    if not self.IsCanGacha10 then
        GridBtnGachas[2].ImgUseItemIcon.gameObject:SetActiveEx(false)
        GridBtnGachas[2].TxtUseItemCount.gameObject:SetActiveEx(false)
    end

    if self._GachaAllFinishTrigger then
        self._GachaAllFinishTrigger = nil
        self:ShowRewardAfterGacha()
    end
end

function XUiGachaLuciaMain:RefreshReddot()
    -- 红点
    local allStageIds = XFestivalActivityConfig.GetFestivalById(self._GachaCfg.FestivalActivityId).StageId
    local isAllPass = true
    for k, stageId in pairs(allStageIds) do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if not stageInfo.Passed then
            isAllPass = false
            break
        end
    end

    local isNewDay = nil
    local updateTime = XSaveTool.GetData(self._GachaStoryRedPoint)
    if updateTime then
        isNewDay = XTime.GetServerNowTimestamp() > updateTime
    else
        isNewDay = true
    end

    local isRed = not isAllPass and isNewDay
    self.BtnStoryLine:ShowReddot(isRed)
end

-- 打开gacha道具购买界面
function XUiGachaLuciaMain:OpenGachaItemShop(openCb, gachaCount)
    -- 购买上限检测
    local gachaBuyTicketRuleConfig = XGachaConfigs.GetGachaItemExchangeCfgById(self._GachaCfg.ExchangeId)
    if XDataCenter.GachaManager.GetCurExchangeItemCount(self._GachaId) >= gachaBuyTicketRuleConfig.TotalBuyCountMax then
        XUiManager.TipError(CS.XTextManager.GetText("BuyItemCountLimit", XDataCenter.ItemManager.GetItemName(self._GachaCfg.ConsumeId)))
        return
    end

    local createItemData = function(config, index)
        return
        {
            ItemId = config.UseItemIds[index],
            Sale = config.Sales[index], -- 折扣
            CostNum = config.UseItemCounts[index], -- 价格
            ItemImg = config.UseItemImgs[index],
        }
    end
    local itemData1 = createItemData(gachaBuyTicketRuleConfig, 1)
    local itemData2 = createItemData(gachaBuyTicketRuleConfig, 2)
    local targetData = { ItemId = self._GachaCfg.ConsumeId, ItemImg = gachaBuyTicketRuleConfig.TargetItemImg }
    XLuaUiManager.Open("UiGachaLuciaBuyTicket", self._GachaCfg, itemData1, itemData2, targetData, gachaCount, function()
        self:RefreshUiShow()
    end)

    if openCb then
        openCb()
    end
end

function XUiGachaLuciaMain:CheckIsCanGacha(gachaCount)
    if not XDataCenter.GachaManager.CheckGachaIsOpenById(self._GachaCfg.Id, true) then
        return false
    end

    -- 剩余抽卡次数检测
    if not self["IsCanGacha" .. gachaCount] then
        if gachaCount == 10 and not self.IsGachaTimesEnd then
            XUiManager.TipText("GachaLuciaItemNoEnough")
        end
        return
    end

    -- 抽卡前检测物品是否满了
    if XMVCA.XEquip:CheckBoxOverLimitOfDraw() then
        return false
    end
    -- 检查货币是否足够
    local ownItemCount = XDataCenter.ItemManager.GetItem(self._GachaCfg.ConsumeId).Count
    local lackItemCount = self._GachaCfg.ConsumeCount * gachaCount - ownItemCount
    if lackItemCount > 0 then
        -- 打开购买界面
        self:OpenGachaItemShop(function()
            XUiManager.TipError(CS.XTextManager.GetText("DrawNotEnoughError"))
        end, gachaCount)
        return false
    end

    return true
end

-- 抽卡流程
function XUiGachaLuciaMain:DoGacha(gachaCount, isSkipToShow)
    local totalGachaCountBefore = XDataCenter.GachaManager.GetTotalGachaTimes(self._GachaId)
    if self._IsCanGacha then
        self._IsCanGacha = false

        -- 根据是否已拥有奖励判断能否弹窗历程奖励
        local isShowCourseRewardList = {}
        local courseReward = XGachaConfigs.GetGachaCourseRewardById(self._GachaCfg.CourseRewardId)
        for i = 1, #courseReward.LimitDrawTimes, 1 do
            local rewardList = XRewardManager.GetRewardList(courseReward.RewardIds[i])
            local isShow = true
            -- 检测是否已经拥有奖励的内容了，已拥有就不弹了。这个检测必须放在trigger外面作为upvalue，因为trigeer的调用时机很晚，背包可能已经被塞入东西看
            for k, data in pairs(rewardList) do
                if i == 1 then
                    if XRewardManager.CheckRewardOwn(data.RewardType, data.TemplateId) then
                        isShow = false
                    end
                end
                isShowCourseRewardList[i] = isShow
            end
        end

        local successCb = function(rewardList, newUnlockGachaId, res)
            -- 弹框相关
            local fashionItem
            local backgroundItem
            local rewardName
            local templateId
            local isConvertFrom
            local rewardListCourseFromServer

            self.RewardList = rewardList
            -- 检测是否抽到时装
            for _, v in pairs(rewardList) do
                if v.TemplateId == self._GachaCfg.TargetTemplateId then
                    fashionItem = v
                end
                if v.RewardType == XRewardManager.XRewardType.Background then
                    backgroundItem = v
                end
            end

            -- 检测是否达到历程奖励
            local totalGachaCountAfter = XDataCenter.GachaManager.GetTotalGachaTimes(self._GachaId)
            for i = 1, #courseReward.LimitDrawTimes, 1 do
                local times = courseReward.LimitDrawTimes[i]
                rewardName = courseReward.RewardNames[i]
                if totalGachaCountBefore < times and totalGachaCountAfter >= times then
                    self._ShowCourseRewardTrigger = true
                    local rewardListCourse = XRewardManager.GetRewardList(courseReward.RewardIds[i])
                    local isShow = isShowCourseRewardList[i]
                    if isShow then
                        -- 历程奖励已获得，先显示使用弹框，再显示（转化后）奖励展示弹框
                        rewardListCourseFromServer = res.GachaCourseResult.RewardList
                        if rewardListCourseFromServer and #rewardListCourseFromServer > 0 then
                            -- 固定【头像、头像框和武器涂装】
                            templateId = rewardListCourseFromServer[1].TemplateId
                            isConvertFrom = XTool.IsNumberValid(rewardListCourseFromServer[1].ConvertFrom)
                        else
                            templateId = rewardListCourse[1].TemplateId
                            isConvertFrom = false
                        end
                    end
                    break
                end
            end

            -- 播放完动画 展示奖励界面的触发器
            self._FinishCbTrigger = function(isSkipToShow2)
                -- 抽卡成功关闭场景镜头、特效
                self._IsCanGacha = true
                self._IsCanGachaClick = true
                local isSkipToShow = isSkipToShow2 or isSkipToShow -- 闭包在其他函数调用的时候不能获取当前函数里的的upvalue isSkipToShow，所以要在其他地方调用时要额外再传一次isSkipToShow2

                self:StopAnime()
                XLuaUiManager.Open("UiGachaLuciaShow", self._GachaId, self.RewardList, nil, isSkipToShow and gachaCount > 1) -- 单抽不能跳过奖励展示
                self._TipCbTrigger = function()
                    local asynOpen = asynTask(XLuaUiManager.Open)
                    RunAsyn(function()
                        if XTool.IsNumberValid(templateId) then
                            asynOpen("UiGachaLuciaQuickWear", templateId, self._GachaCfg.CourseRewardId, isConvertFrom, rewardName)
                        end
                        if fashionItem then
                            asynOpen("UiGachaLuciaPassport", fashionItem)
                        end
                        if backgroundItem then
                            asynOpen("UiGachaLuciaPassport", backgroundItem)
                        end
                        if isConvertFrom and rewardListCourseFromServer then
                            asynOpen("UiObtain", rewardListCourseFromServer)
                        end
                    end)
                end
            end

            if isSkipToShow then
                if self._FinishCbTrigger then
                    self._FinishCbTrigger(isSkipToShow)
                    self._FinishCbTrigger = nil
                end
            else
                local maxQuality = 0
                for k, rewardInfo in pairs(rewardList) do
                    --获取奖励品质
                    local id = rewardInfo.Id and rewardInfo.Id > 0 and rewardInfo.Id or rewardInfo.TemplateId
                    local Type = XTypeManager.GetTypeById(id)
                    if rewardInfo.ConvertFrom > 0 then
                        Type = XTypeManager.GetTypeById(rewardInfo.ConvertFrom)
                        id = rewardInfo.ConvertFrom
                    end
                    local quality
                    local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
                    if Type == XArrangeConfigs.Types.Wafer then
                        quality = templateIdData.Star
                    elseif Type == XArrangeConfigs.Types.Weapon then
                        quality = templateIdData.Star
                    elseif Type == XArrangeConfigs.Types.Character then
                        quality = XMVCA.XCharacter:GetCharMinQuality(id)
                    elseif Type == XArrangeConfigs.Types.Partner then
                        quality = templateIdData.Quality
                    else
                        quality = XTypeManager.GetQualityById(id)
                    end
                    if XDataCenter.ItemManager.IsWeaponFashion(id) then
                        quality = XTypeManager.GetQualityById(id)
                    end
                    -- 强制检测特效
                    local foreceQuality = XGachaConfigs.GetGachaShowRewardConfigById(id)
                    if foreceQuality then
                        quality = foreceQuality.EffectQualityType
                    end

                    if quality > maxQuality then
                        maxQuality = quality
                    end
                end

                self:PlayGachaAnime(maxQuality)
            end
        end
        XDataCenter.GachaManager.DoGacha(self._GachaCfg.Id, gachaCount, successCb, function(res)
            -- self.ImgMask.gameObject:SetActiveEx(false)
        end)
    end
end

function XUiGachaLuciaMain:PlayGachaAnime(quality)
    self.PlayAnime = true
    if not self._FinishCbTrigger then
        return
    end

    local timeline
    quality = quality or 4
    if quality == 4 then
        timeline = self.Panel3D.ChoukaVioletEnable.transform
    elseif quality == 5 then
        timeline = self.Panel3D.ChoukaYellowEnable.transform
    elseif quality == 6 then
        timeline = self.Panel3D.ChoukaRedEnable.transform
    end
    if timeline then
        timeline:PlayTimelineAnimation(function()
            if self._FinishCbTrigger then
                self._FinishCbTrigger()
                self._FinishCbTrigger = nil
            end
        end)
    end

    self.GachaButtonsDisable:PlayTimelineAnimation(function()
        self.AssetPanel:Close()
    end)

    self.PlayAnime = false
end

-- 关闭所有特效
function XUiGachaLuciaMain:StopAnime()
    self.BtnSkipGacha.gameObject:SetActiveEx(false)
end

-- 传入要抽多少抽
function XUiGachaLuciaMain:OnBtnGachaClick(gachaCount)
    if not self:CheckIsCanGacha(gachaCount) then
        return
    end
    XDataCenter.KickOutManager.Lock(XEnumConst.KICK_OUT.LOCK.GACHA)

    self.BtnStoryLine:ShowReddot(false) -- 因为红点是用粒子特效做的，动画无法隐藏，必须程序控制抽卡时隐藏红点
    self:SetXPostFaicalControllerActive(false)
    self._GachaAllFinishTrigger = true
    self._DoGachaTrigger = function(isSkipToshow)
        self:DoGacha(gachaCount, isSkipToshow)
    end
    self._IsGachaReturnMain = true
    self._DoGachaTrigger()
end

-- 跳过抽卡演出,直接展示所有奖励
function XUiGachaLuciaMain:OnBtnSkipGachaClick()
    self._ChoukaAudioDisable:PlayTimelineAnimation(function() -- 特殊处理 为了关闭音效
        self.PlayAnime = false
        if self._FinishCbTrigger then
            -- timeline的PlayTimelineAnimation会在Disable执行回调
            -- 上面的抽卡动画的回调里就有个self._FinishCbTrigger()，所以这里得先置空，否则self._FinishCbTrigger会被调两次
            local cb = self._FinishCbTrigger
            self._FinishCbTrigger = nil
            cb(true)
        end
    end)
end

function XUiGachaLuciaMain:OnBtnStoryLineClick(isAutoOpen)
    self:SetSelfActive(false)
    -- 防止AnimEnableStory和AnimEnableLong冲突
    if not self._CanPlayEnableAnim or isAutoOpen then
        -- 在Hold状态时，最后一个事件帧触发会有问题
        self:PlayAnimationWithMask("AnimStart2")
    end
    self.Panel3D.UiFarCamStory.gameObject:SetActiveEx(false)
    self.Panel3D.UiNearCamStory.gameObject:SetActiveEx(false)
    self:OpenOneChildUi("UiGachaLuciaStageLine", self._GachaCfg.FestivalActivityId, self.Panel3D, isAutoOpen)
end

function XUiGachaLuciaMain:OnAfterStageLineEnable()
    self.Panel3D.AnimDisableStory.gameObject:SetActiveEx(false)
    self.Panel3D.AnimEnableStory.gameObject:SetActiveEx(true)
    self.Panel3D.AnimEnableStory:PlayTimelineAnimation()
end

function XUiGachaLuciaMain:ShowRewardAfterGacha()
    self:ShowWeaponFashion()
end

function XUiGachaLuciaMain:ShowWeaponFashion()
    local cacheReward = XDataCenter.LottoManager.GetWeaponFashionCacheReward()
    if cacheReward then
        XDataCenter.LottoManager.ClearWeaponFashionCacheReward()
        local data = cacheReward
        local rewards = { { TemplateId = data.ItemId, Count = data.ItemCount } }
        XUiManager.OpenUiObtain(rewards)
    end
end

---配合_PlayTimeLineAnim
---延迟一帧是因为_PlayTimeLineAnim自己控制了timeline播放
---ui动画还是走XUiPlayTimelineAnimation会延迟两帧
---所以延迟一帧播放尽量对齐场景动画和Ui动画
function XUiGachaLuciaMain:_PlayAnimNextFrame(playAnimFunc)
    if not playAnimFunc then
        return
    end
    local timerId = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        playAnimFunc()
    end, 0)
    self:_AddTimerId(timerId)
end

---PlayAnimationWithMask该接口最终使用的是C# XUiPlayTimelineAnimation
---XUiPlayTimelineAnimation的Play接口会因为WaitFrame等两帧
---由于角色动作切换是用【timeLine帧事件】实现的
---所以如果帧事件处于第一帧会导致场景演出对齐上有2帧时间误差,因此不用之,自己另写
---@param tran UnityEngine.Transform
---@param directorWrapMode number UnityEngine.Playables.DirectorWrapMode
function XUiGachaLuciaMain:_PlayTimeLineAnim(tran, time, directorWrapMode, finishCallBack)
    if not tran then
        return
    end
    ---@type UnityEngine.Playables.PlayableDirector
    local anim = tran:GetComponent("PlayableDirector")
    anim.initialTime = time or 0
    if directorWrapMode then
        anim.extrapolationMode = directorWrapMode
    end
    anim:Evaluate()
    anim:Play()
    if finishCallBack then
        local playTimer = XScheduleManager.ScheduleOnce(finishCallBack, math.ceil(anim.duration * 1000))
        self:_AddTimerId(playTimer)
    end
end

return XUiGachaLuciaMain