---@class XUiEpicFashionGacha:XLuaUi@gacha3D抽卡界面
local XUiEpicFashionGacha = XLuaUiManager.Register(XLuaUi, "UiEpicFashionGacha")

function XUiEpicFashionGacha:Ctor()
    self.LongEnableCb = nil -- 长动画的回调
    self.CanPlayEnableAnim = false -- 只有进入卡池时会检测播放1次
    self.ShowFashionTrigger = nil
    self.ShowCourseRewardTrigger = nil
    self.DoGachaTrigger = nil -- 抽卡触发器，1/10回抽按钮设置，拨动时钟触发
    self.FinishCbTrigger = nil -- 抽卡结束触发器，抽卡请求回调设置，播放完抽卡演出后触发
    self.GachaAllFinishTrigger = nil -- 抽卡全结束触发器，1/10回抽按钮设置，抽卡结果界面关闭后刷新触发
    self.HasBeenKey = "HasBeenKey"
    self.SkipBtnKey = "UiEpicFashionGacha"
    self.GachaStoryRedPoint = "GachaStoryRedPoint"
    self.TempFx = nil
    self.TimerStoryRoleEnable = nil
end

function XUiEpicFashionGacha:SetSelfActive(flag)
    self.PanelGachaGroup.gameObject:SetActiveEx(flag)
    self:SetXPostFaicalControllerActive(flag)
    self.IsParentShow = flag
end

function XUiEpicFashionGacha:OnAwake()
    self.IsParentShow = true
    self.IsCanGacha = true
    self.IsCanGachaClick = true
    self.GridCourseRewardsDic = {}
    self.GridBoardRewardsDic = {}
    self.PanelShowDic = {}
    self:InitButton()
    self:Init3DSceneInfo()
end

function XUiEpicFashionGacha:InitButton()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function()
        XLuaUiManager.RunMain()
    end)
    self:RegisterClickEvent(self.BtnGacha, function()
        self:OnBtnGachaClick(self.GachaCfg.BtnGachaCount[1])
    end)
    self:RegisterClickEvent(self.BtnGacha2, function()
        self:OnBtnGachaClick(self.GachaCfg.BtnGachaCount[2])
    end)
    self:RegisterClickEvent(self.BtnStartGacha, self.OnBtnStartClick)
    self:RegisterClickEvent(self.BtnStartAnim, self.PlayLongEnableAnim2)
    self:RegisterClickEvent(self.BtnSkipGacha, self.OnBtnSkipGachaClick)
    self:RegisterClickEvent(self.BtnStoryLine, self.OnBtnStoryLineClick)
    self:RegisterClickEvent(self.BtnAward, function()
        XLuaUiManager.Open("UiEpicFashionGachaLog", self.GachaCfg, 1)
    end)
    self:RegisterClickEvent(self.BtnHelp, function()
        XLuaUiManager.Open("UiEpicFashionGachaLog", self.GachaCfg)
    end)
    self:RegisterClickEvent(self.BtnSet, function()
        XLuaUiManager.Open("UiSet")
    end)
end

function XUiEpicFashionGacha:Init3DSceneInfo()
    if not self.UiSceneInfo or XTool.UObjIsNil(self.UiSceneInfo.Transform) then
        self:LoadUiScene(self:GetDefaultSceneUrl(), self:GetDefaultUiModelUrl())
    end

    self.Panel3D = {}
    local root = self.UiModelGo.transform
    XTool.InitUiObjectByUi(self.Panel3D, self.UiSceneInfo.Transform) -- 将场景的内容和镜头的内容加到1个table里
    XTool.InitUiObjectByUi(self.Panel3D, root) -- 3d镜头的ui
    self:Refresh3DSceneInfo()

    -- 阴影要放在武器模型加载完之后
    CS.XShadowHelper.AddShadow(self.Panel3D.Model2.gameObject, true)
end

function XUiEpicFashionGacha:Refresh3DSceneInfo()
    self.Panel3D.UiModelParent.gameObject:SetActiveEx(true)
    self.Panel3D.UiModelParentStory.gameObject:SetActiveEx(false)
    self.Panel3D.Model2.gameObject:SetActiveEx(true)
    self.Panel3D.Uimc_05ClockAni.gameObject:SetActiveEx(true) -- 抽卡界面专用时钟
    self.Panel3D.Uimc_05ClockAni2.gameObject:SetActiveEx(false)
    self.Panel3D.Uimc_05ClockAni3.gameObject:SetActiveEx(false) -- 关闭主界面专用时钟
    -- 打开主摄像机 关闭剧情相机和时钟相机
    self.Panel3D.UiFarCameraMain.gameObject:SetActiveEx(true)
    self.Panel3D.UiFarCameraClock.gameObject:SetActiveEx(false)
    self.Panel3D.UiFarCameraDeep.gameObject:SetActiveEx(false)
    self.Panel3D.UiFarCameraStory.gameObject:SetActiveEx(false)

    self.Panel3D.UiNearCameraMain.gameObject:SetActiveEx(true)
    self.Panel3D.UiNearCameraClock.gameObject:SetActiveEx(false)
    self.Panel3D.UiNearCameraDeep.gameObject:SetActiveEx(false)
    self.Panel3D.UiNearCameraStory.gameObject:SetActiveEx(false)
end

function XUiEpicFashionGacha:OnStart(gachaId, autoOpenStory)
    self.GachaId = gachaId
    self.GachaCfg = XGachaConfigs.GetGachaCfgById(self.GachaId)
    self.AutoOpenStory = autoOpenStory

    -- 跳过按钮,只有在进入ui时自动刷新1次
    local isSelect = XSaveTool.GetData(self.SkipBtnKey)
    local state = isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.BtnSkip:SetButtonState(state)

    self.CanPlayEnableAnim = true
end

function XUiEpicFashionGacha:OnChildClose()
    self:SetSelfActive(true)
    self:Refresh3DSceneInfo()
    self:RefreshUiShow()

    if self.CanPlayEnableAnim then
        self:PlayEnableAnim(function()
            self:RefreshReddot()
        end)
    else
        self.AnimEnableShort:PlayTimelineAnimation()
        self.Panel3D.AnimEnableShort:PlayTimelineAnimation(function()
            self:RefreshReddot()
            self:SetXPostFaicalControllerActive(true)
        end)
    end

    if self.TimerStoryRoleEnable then
        XScheduleManager.UnSchedule(self.TimerStoryRoleEnable)
        self.TimerStoryRoleEnable = nil
    end
end

function XUiEpicFashionGacha:AutoOpenChild()
    if self.AutoOpenStory then
        self:OnBtnStoryLineClick(true)
        self.AutoOpenStory = nil
    elseif self.IsGoFight then
        self:OnBtnStoryLineClick()
        self.IsGoFight = nil
    end
end

function XUiEpicFashionGacha:OnEnable()
    -- 顺序不能改表
    -- 1.先检测是否需要打开子界面 -- 【需要的话】就不进行enable动画播放 且直接刷新红点
    -- 2.【不需要的话】就开始播放enable动画，且必须在动画播完后再刷新红点
    if not self.Panel3D or XTool.UObjIsNil(self.Panel3D.GameObject) then
        self:Init3DSceneInfo() -- 战斗回来后场景会被销毁，需要判空再加载1次
    end
    self:RefreshUiShow()
    self:AutoOpenChild()
    if self.CanPlayEnableAnim then
        self:PlayEnableAnim(function()
            self:RefreshReddot()
        end)
    else
        self:RefreshReddot()
        self:SetXPostFaicalControllerActive(true)
    end
end

-- 开启/关闭角色的视线跟随
function XUiEpicFashionGacha:SetXPostFaicalControllerActive(flag)
    local model = self.Panel3D.Model2
    local targetComponent = model:GetComponent(typeof(CS.XPostFaicalController))
    if not targetComponent then
        return
    end
    if flag and not targetComponent.enabled then
        targetComponent.enabled = true
    end
    targetComponent:ActiveInput(flag)
end

function XUiEpicFashionGacha:SetXPostFaicalControllerEnable(flag)
    local model = self.Panel3D.Model2
    local targetComponent = model:GetComponent(typeof(CS.XPostFaicalController))
    if not targetComponent then
        return
    end

    targetComponent.enabled = flag
end

function XUiEpicFashionGacha:PlayEnableAnim(cb)
    if not self.IsParentShow then
        return
    end
    self.CanPlayEnableAnim = false

    -- 播放演出动画的时候必须关闭头部跟随 关闭待机loop动画
    self.Panel3D.RoleLoop:GetComponent("PlayableDirector"):Stop()
    self:SetXPostFaicalControllerActive(false)

    local isSkip = XSaveTool.GetData(self.SkipBtnKey)
    -- 如果勾了跳过演出 就播放短动画 否则播放长动画
    if isSkip then
        if cb then
            cb()
        end
        self:PlayShortEnableAnim()
    else
        self:PlayLongEnableAnim1(cb)
        local hasBeen = XSaveTool.GetData(self.HasBeenKey)
        if not hasBeen then
            -- 如果第一次进来播长动画，自动勾上跳过
            self.BtnSkip:SetButtonState(CS.UiButtonState.Select)
            XSaveTool.SaveData(self.HasBeenKey, 1)
        end
    end
end

-- 长动画1阶段，开始播放循环等待动画
function XUiEpicFashionGacha:PlayLongEnableAnim1(cb)
    self.LongEnableCb = cb
    -- 播放循环动画
    self.AnimStart1:PlayTimelineAnimation()
    self.Panel3D.AnimStart1Loop:GetComponent("PlayableDirector"):Play()
    -- 打开按钮 等待玩家点击开始下一阶段长动画
    self.BtnStartAnim.gameObject:SetActiveEx(true)
end

-- 长动画2阶段，该方法由玩家点击按钮后主动调用
function XUiEpicFashionGacha:PlayLongEnableAnim2()
    -- 点击后直接隐藏按钮
    self.BtnStartAnim.gameObject:SetActiveEx(false)
    -- 动画
    local lastUiDirector = self.Panel3D.AnimStart1Loop:GetComponent("PlayableDirector")
    local currTime = lastUiDirector.time or 0
    lastUiDirector:Stop()

    self.Panel3D.AnimEnableLong.gameObject:SetActiveEx(true)
    local curUiDirector = self.Panel3D.AnimEnableLong:GetComponent("PlayableDirector")
    curUiDirector.initialTime = currTime
    curUiDirector:Play()
    self.LongAnimTimer = XScheduleManager.ScheduleOnce(function()
        self.Panel3D.RoleLoop:GetComponent("PlayableDirector"):Play()
        -- 必须要在enable动画完成后打开视线跟随
        self.Panel3D.AnimEnableLong.gameObject:SetActiveEx(false)
        self:SetXPostFaicalControllerActive(true)
        if self.LongEnableCb then
            self.LongEnableCb()
            self.LongEnableCb = nil
        end
    end, math.round(curUiDirector.duration * XScheduleManager.SECOND))

    self.AnimEnableLong:GetComponent("PlayableDirector").initialTime = currTime
    self.AnimEnableLong:GetComponent("PlayableDirector"):Play()

    self.Panel3D.TimeDisable:GetComponent("PlayableDirector").initialTime = currTime
    self.Panel3D.TimeDisable:GetComponent("PlayableDirector"):Play()
end

function XUiEpicFashionGacha:PlayShortEnableAnim(cb)
    self.Panel3D.RoleLoop:GetComponent("PlayableDirector"):Play()
    self.AnimEnableShort:PlayTimelineAnimation()
    self.Panel3D.AnimEnableShort:PlayTimelineAnimation(function()
        self:SetXPostFaicalControllerActive(true)
        if cb then
            cb()
        end
    end)
end

function XUiEpicFashionGacha:RefreshUiShow()
    -- 把实际的刷新方法放进1个fun里，因为会有两种刷新方式，
    -- 1 是抽完卡后的第一次刷新，必须通过动画回调，且这个动画必须放在刷新前
    -- 2 是正常刷新，非抽卡后的刷新
    local doRefreshFun = function()
        -- 资源栏
        local managerItems = XDataCenter.ItemManager.ItemId
        self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ managerItems.PaidGem, managerItems.HongKa, self.GachaCfg.ConsumeId }, self.PanelSpecialTool, self)
        self.AssetPanel:SetButtonCb(3, function()
            self:OpenGachaItemShop()
        end)

        -- 奖励展示滚动
        local PanelAwardShow = {}
        XTool.InitUiObjectByUi(PanelAwardShow, self.PanelAwardShow)
        local rewardRareLevelList = XDataCenter.GachaManager.GetGachaRewardSplitByRareLevel(self.GachaId)
        for i, group in ipairs(rewardRareLevelList) do
            local Panel = self.PanelShowDic[i]
            if XTool.IsTableEmpty(Panel) then
                Panel = {}
                self.PanelShowDic[i] = Panel
                local panelShowUiTrans = PanelAwardShow["PanelShow" .. i]
                if not panelShowUiTrans then
                    break
                end
                XTool.InitUiObjectByUi(Panel, panelShowUiTrans)
            end

            for k, v in pairs(group) do
                local searchIndex = i * 10 + k
                local item = self.GridBoardRewardsDic[searchIndex]
                if not item then
                    local uiTrans = k == 1 and Panel.GridRewards or CS.UnityEngine.Object.Instantiate(Panel.GridRewards, Panel.GridRewards.parent)
                    item = XUiGridCommon.New(self, uiTrans)
                    self.GridBoardRewardsDic[searchIndex] = item
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
        local curTotalGachaTimes = XDataCenter.GachaManager.GetTotalGachaTimes(self.GachaId)
        local courseReward = XGachaConfigs.GetGachaCourseRewardById(self.GachaCfg.CourseRewardId)
        local gachaBuyTicketRuleConfig = XGachaConfigs.GetGachaItemExchangeCfgById(self.GachaCfg.ExchangeId)
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
                if self.ShowCourseRewardTrigger and curTotalGachaTimes - 10 < curNoteGachaTime then
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
                local gridReward = self.GridCourseRewardsDic[searchIndex]
                if not gridReward then
                    local ui = CS.UnityEngine.Object.Instantiate(note.GridRewards, note.GridRewards.parent)
                    gridReward = XUiGridCommon.New(self, ui)
                    self.GridCourseRewardsDic[searchIndex] = gridReward
                end
                gridReward.GameObject:SetActiveEx(true)
                gridReward:Refresh(item)
                gridReward:SetReceived(isReceived)

            end
        end
        -- 如果抽完卡达到历程奖励 弹奖励提示
        if self.ShowCourseRewardTrigger then
            self.ShowCourseRewardTrigger()
            self.ShowCourseRewardTrigger = nil
        end

        -- 抽奖按钮
        local GridBtnGachas = {}
        GridBtnGachas[1] = {}
        GridBtnGachas[2] = {}
        XTool.InitUiObjectByUi(GridBtnGachas[1], self.BtnGacha)
        XTool.InitUiObjectByUi(GridBtnGachas[2], self.BtnGacha2)
        local icon = XDataCenter.ItemManager.GetItemTemplate(self.GachaCfg.ConsumeId).Icon
        GridBtnGachas[1].ImgUseItemIcon:SetRawImage(icon)
        GridBtnGachas[1].TxtUseItemCount.text = self.GachaCfg.ConsumeCount
        GridBtnGachas[2].ImgUseItemIcon:SetRawImage(icon)
        GridBtnGachas[2].TxtUseItemCount.text = self.GachaCfg.ConsumeCount * 10
        -- 按钮显示
        local leftCanGachaCount = totaMaxTimes - curTotalGachaTimes
        self.IsCanGacha1 = leftCanGachaCount > 0
        self.IsCanGacha10 = leftCanGachaCount >= 10

        self.BtnGacha:SetDisable(not self.IsCanGacha1)
        self.BtnGacha2:SetDisable(not self.IsCanGacha10)

        if not self.IsCanGacha1 then
            GridBtnGachas[1].ImgUseItemIcon.gameObject:SetActiveEx(false)
            GridBtnGachas[1].TxtUseItemCount.gameObject:SetActiveEx(false)
        end
        if not self.IsCanGacha10 then
            GridBtnGachas[2].ImgUseItemIcon.gameObject:SetActiveEx(false)
            GridBtnGachas[2].TxtUseItemCount.gameObject:SetActiveEx(false)
        end

        if self.ShowFashionTrigger then
            self.ShowFashionTrigger()
            self.ShowFashionTrigger = nil
        end
    end

    if self.GachaAllFinishTrigger then
        self.GachaAllFinishTrigger = nil
        self.AnimEnableShort:PlayTimelineAnimation(function()
            doRefreshFun()
            self.Panel3D.RoleLoop:GetComponent("PlayableDirector"):Play()
            self:ShowRewardAfterGacha()
        end)
    else
        doRefreshFun()
    end
end

function XUiEpicFashionGacha:RefreshReddot()
    -- 红点
    local allStageIds = XFestivalActivityConfig.GetFestivalById(self.GachaCfg.FestivalActivityId).StageId
    local isAllPass = true
    for k, stageId in pairs(allStageIds) do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if not stageInfo.Passed then
            isAllPass = false
            break
        end
    end

    local isNewDay = nil
    local updateTime = XSaveTool.GetData(self.GachaStoryRedPoint)
    if updateTime then
        isNewDay = XTime.GetServerNowTimestamp() > updateTime
    else
        isNewDay = true
    end

    local isRed = not isAllPass and isNewDay
    self.BtnStoryLine:ShowReddot(isRed)
end

-- 打开gacha道具购买界面
function XUiEpicFashionGacha:OpenGachaItemShop(openCb, gachaCount)
    -- 购买上限检测
    local gachaBuyTicketRuleConfig = XGachaConfigs.GetGachaItemExchangeCfgById(self.GachaCfg.ExchangeId)
    if XDataCenter.GachaManager.GetCurExchangeItemCount(self.GachaId) >= gachaBuyTicketRuleConfig.TotalBuyCountMax then
        XUiManager.TipError(CS.XTextManager.GetText("BuyItemCountLimit", XDataCenter.ItemManager.GetItemName(self.GachaCfg.ConsumeId)))
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
    local targetData = { ItemId = self.GachaCfg.ConsumeId, ItemImg = gachaBuyTicketRuleConfig.TargetItemImg }
    XLuaUiManager.Open("UiEpicFashionGachaBuyTicket", self.GachaCfg, itemData1, itemData2, targetData, gachaCount, function()
        self:RefreshUiShow()
    end)

    if openCb then
        openCb()
    end
end

function XUiEpicFashionGacha:CheckIsCanGacha(gachaCount)
    if not XDataCenter.GachaManager.CheckGachaIsOpenById(self.GachaCfg.Id, true) then
        return false
    end

    -- 剩余抽卡次数检测
    if not self["IsCanGacha" .. gachaCount] then
        return
    end

    -- 抽卡前检测物品是否满了
    if XDataCenter.EquipManager.CheckBoxOverLimitOfDraw() then
        return false
    end
    -- 检查货币是否足够
    local ownItemCount = XDataCenter.ItemManager.GetItem(self.GachaCfg.ConsumeId).Count
    local lackItemCount = self.GachaCfg.ConsumeCount * gachaCount - ownItemCount
    if lackItemCount > 0 then
        -- 打开购买界面
        self:OpenGachaItemShop(function()
            XUiManager.TipError(CS.XTextManager.GetText("DrawNotEnoughError"))
        end, gachaCount)
        return false
    end

    -- 奖励库存检查(检测抽奖池剩余库存)
    -- local dtCount = XDataCenter.GachaManager.GetMaxCountOfAll() - XDataCenter.GachaManager.GetCurCountOfAll()
    -- if dtCount < gachaCount and not XDataCenter.GachaManager.GetIsInfinite() then
    --     XUiManager.TipMsg(CS.XTextManager.GetText("GachaIsNotEnough"))
    --     return
    -- end

    return true
end

-- 抽卡流程
-- 1.点击gacha按钮调用 OnBtnGachaClick ，将DoGacha写入触发器 DoGachaTrigger 等待BtnStart按钮触发 --→ 2.打开1阶段动画仅移动镜头和开启下一步点击的全屏按钮BtnStart, 仅调用PlayGachaAnime1
-- 3.点击 BtnStart按钮 触发DoGachaTrigger 调用 DoGacha，成功抽取奖励后将展示奖励ui的逻辑写入触发器 FinishCbTrigger 等待第二阶段动画播放完后调用。播放动画调用 PlayGachaAnime2
-- 4.播放第二阶段动画，在播放完的回调里调用 FinishCbTrigger 。结束
function XUiEpicFashionGacha:DoGacha(gachaCount, isSkipToShow)
    local totalGachaCountBefore = XDataCenter.GachaManager.GetTotalGachaTimes(self.GachaId)
    if self.IsCanGacha then
        self.IsCanGacha = false

        -- 根据是否已拥有奖励判断能否弹窗历程奖励
        local isShowCourseRewardList = {}
        local courseReward = XGachaConfigs.GetGachaCourseRewardById(self.GachaCfg.CourseRewardId)
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
            self.RewardList = rewardList
            -- 检测是否抽到时装
            for k, v in pairs(rewardList) do
                if v.TemplateId == self.GachaCfg.TargetTemplateId then
                    self.ShowFashionTrigger = function()
                        XLuaUiManager.Open("UiEpicFashionGachaQuickWear", self.GachaCfg.TargetTemplateId)
                    end
                    break
                end
            end

            -- 检测是否达到历程奖励
            local totalGachaCountAfter = XDataCenter.GachaManager.GetTotalGachaTimes(self.GachaId)
            for i = 1, #courseReward.LimitDrawTimes, 1 do
                local times = courseReward.LimitDrawTimes[i]
                if totalGachaCountBefore < times and totalGachaCountAfter >= times then
                    local rewardListCourse = XRewardManager.GetRewardList(courseReward.RewardIds[i])
                    local isShow = isShowCourseRewardList[i]
                    self.ShowCourseRewardTrigger = function()
                        if isShow then
                            -- 历程奖励已获得，有转换的，显示转换后的结果
                            local rewardListCourseFromServer = res.GachaCourseResult.RewardList
                            if rewardListCourseFromServer and #rewardListCourseFromServer > 0 then
                                XUiManager.OpenUiObtain(rewardListCourseFromServer)
                            else
                                XUiManager.OpenUiObtain(rewardListCourse)
                            end
                        end
                    end
                    break
                end
            end

            -- 播放完动画 展示奖励界面的触发器
            self.FinishCbTrigger = function(isSkipToShow2)
                -- 抽卡成功关闭场景镜头、特效
                self:StopAnime()
                local isSkipToShow = isSkipToShow2 or isSkipToShow -- 闭包在其他函数调用的时候不能获取当前函数里的的upvalue isSkipToShow，所以要在其他地方调用时要额外再传一次isSkipToShow2
                XLuaUiManager.Open("UiEpicFashionGachaShow", self.GachaId, self.RewardList, function()
                    XLuaUiManager.Open("UiEpicFashionGachaResult", self.GachaId, self.RewardList, function()
                    end, self.Background)
                end, nil, isSkipToShow and gachaCount > 1) -- 单抽不能跳过奖励展示
                self.IsCanGacha = true
                self.IsCanGachaClick = true
            end

            if isSkipToShow then
                if self.FinishCbTrigger then
                    self.FinishCbTrigger(isSkipToShow)
                    self.FinishCbTrigger = nil
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

                self:PlayGachaAnime2(maxQuality)
            end
        end
        XDataCenter.GachaManager.DoGacha(self.GachaCfg.Id, gachaCount, successCb, function(res)
            -- self.ImgMask.gameObject:SetActiveEx(false)
        end)
    end
end

-- 1阶段特效 （点击单抽或十连抽按钮后的特效：镜头推至时钟，打开冰霜特效）
function XUiEpicFashionGacha:PlayGachaAnime1()
    self.PlayAnime1 = true
    -- 镜头
    self.Panel3D.UiNearCameraClock.gameObject:SetActiveEx(true)
    self.Panel3D.UiFarCameraClock.gameObject:SetActiveEx(true)
    -- 特效
    self.PanelGachaEffect.gameObject:SetActiveEx(true)
    self.Panel3D.FxUiMain3dClockChoukaPingmuIce.gameObject:SetActiveEx(true)
    -- 按钮
    self.BtnSkipGacha.gameObject:SetActiveEx(true)
    self.BtnStartGacha.gameObject:SetActiveEx(true)
    -- 动画
    self.GachaButtonsEnable:PlayTimelineAnimation()
    self.Panel3D.GachaButtonsEnable:PlayTimelineAnimation()

    self.PlayAnime1 = false

    -- 生成音效
    self.TempFx = self.Transform:LoadPrefab(CS.XGame.ClientConfig:GetString("EpicGahcaSoundPingmuIce"))
end

-- 2阶段特效 （点击时钟后：播放时钟转动动画，打开玫瑰特效 并根据抽出的品质展示不同颜色的特效
function XUiEpicFashionGacha:PlayGachaAnime2(quality)
    self.PlayAnime2 = true
    if not self.FinishCbTrigger then
        return
    end

    -- 镜头
    self.Panel3D.UiFarCameraDeep.gameObject:SetActiveEx(true)
    self.Panel3D.UiNearCameraDeep.gameObject:SetActiveEx(true)
    -- 特效
    self.PanelGachaEffect.gameObject:SetActiveEx(false)
    self.Panel3D.FxJiaotangWuguang02.gameObject:SetActiveEx(false) --场景的光柱特效
    self.Panel3D.FxUiMain3dClockChouka.gameObject:SetActiveEx(true)
    self.Panel3D.FxUiMain3dClockChoukaYaan.gameObject:SetActiveEx(true)
    self.Panel3D.FxUiMain3dClockChoukaPingmuBlack.gameObject:SetActiveEx(true)
    -- 播放动画,隐藏原来的时钟
    self.Panel3D.Uimc_05ClockAni.gameObject:SetActiveEx(false)
    self.Panel3D.Uimc_05ClockAni2.gameObject:SetActiveEx(true)
    self.GachaButtonsDisable:PlayTimelineAnimation()
    quality = quality or 4
    local go = self.Panel3D["FxUiMain3dClockHuaban" .. quality]
    if go then
        go.gameObject:SetActiveEx(true)
    end

    self.Panel3D.Uimc_05ClockAni2:Find("Animation/Rotate"):PlayTimelineAnimation(function()
        if not self.PlayAnime2 then
            return
        end

        self.PlayAnime2 = false
        if self.FinishCbTrigger then
            self.FinishCbTrigger()
            self.FinishCbTrigger = nil
        end
    end)

    -- 销毁音效
    if self.TempFx then
        self.TempFx = self.Transform:LoadPrefab(CS.XGame.ClientConfig:GetString("EpicGahcaSoundClose"))
    end
end

-- 关闭所有特效
function XUiEpicFashionGacha:StopAnime()
    -- 镜头
    self.Panel3D.UiNearCameraClock.gameObject:SetActiveEx(false)
    self.Panel3D.UiFarCameraClock.gameObject:SetActiveEx(false)
    self.Panel3D.UiFarCameraDeep.gameObject:SetActiveEx(false)
    self.Panel3D.UiNearCameraDeep.gameObject:SetActiveEx(false)
    -- 特效
    self.PanelGachaEffect.gameObject:SetActiveEx(false)
    self.Panel3D.FxJiaotangWuguang02.gameObject:SetActiveEx(true) --场景的光柱特效
    self.Panel3D.FxUiMain3dClockChoukaPingmuIce.gameObject:SetActiveEx(false)
    self.Panel3D.FxUiMain3dClockChouka.gameObject:SetActiveEx(false)
    self.Panel3D.FxUiMain3dClockChoukaYaan.gameObject:SetActiveEx(false)
    self.Panel3D.FxUiMain3dClockChoukaPingmuBlack.gameObject:SetActiveEx(false)
    for i = 3, 6, 1 do
        local go = self.Panel3D["FxUiMain3dClockHuaban" .. i]
        if go then
            go.gameObject:SetActiveEx(false)
        end
    end
    -- 动画
    self.Panel3D.Uimc_05ClockAni.gameObject:SetActiveEx(true)
    self.Panel3D.Uimc_05ClockAni2.gameObject:SetActiveEx(false)
    -- 按钮
    self.BtnSkipGacha.gameObject:SetActiveEx(false)
    self.BtnStartGacha.gameObject:SetActiveEx(false)

    -- 销毁音效
    if self.TempFx then
        self.TempFx = self.Transform:LoadPrefab(CS.XGame.ClientConfig:GetString("EpicGahcaSoundClose"))
    end
end

-- 传入要抽多少抽
function XUiEpicFashionGacha:OnBtnGachaClick(gachaCount)
    if not self:CheckIsCanGacha(gachaCount) then
        return
    end
    XDataCenter.KickOutManager.Lock(XEnumConst.KICK_OUT.LOCK.GACHA)

    self.BtnStoryLine:ShowReddot(false) -- 因为红点是用粒子特效做的，动画无法隐藏，必须程序控制抽卡时隐藏红点
    self:SetXPostFaicalControllerActive(false)
    self:PlayGachaAnime1()
    self.GachaAllFinishTrigger = true
    self.DoGachaTrigger = function(isSkipToshow)
        self:DoGacha(gachaCount, isSkipToshow)
    end
end

-- 出现抽卡特效后再点该按钮才进行下一步
function XUiEpicFashionGacha:OnBtnStartClick()
    if not self.IsCanGachaClick then
        return
    end
    self.IsCanGachaClick = false
    if self.DoGachaTrigger then
        self.DoGachaTrigger()
        self.DoGachaTrigger = nil
    end
end

-- 跳过抽卡演出,直接展示所有奖励
function XUiEpicFashionGacha:OnBtnSkipGachaClick()
    -- 3种情况，
    -- 1是还没点击抽卡，在播放动画1 
    -- 2是还没点击抽卡，准备播放动画2
    -- 3是已经点了抽卡正在播放动画2 
    if self.PlayAnime1 then
    elseif self.IsCanGacha and not self.PlayAnime2 then
        if self.DoGachaTrigger then
            self.DoGachaTrigger(true)
            self.DoGachaTrigger = nil
        end
    elseif not self.IsCanGacha and self.PlayAnime2 then
        self.PlayAnime2 = false
        if self.FinishCbTrigger then
            self.FinishCbTrigger(true)
            self.FinishCbTrigger = nil
        end
    end
end

function XUiEpicFashionGacha:OnBtnStoryLineClick(isAutoOpen)
    self:SetSelfActive(false)
    self:OpenOneChildUi("UiEpicFashionGachaStageLine", self.GachaCfg.FestivalActivityId, self.Panel3D, isAutoOpen)

    -- 下楼梯动画
    self.Panel3D.StoryRoleEnbale.gameObject:SetActiveEx(true)

    local storyRoleEnbaleDictor = self.Panel3D.StoryRoleEnbale:GetComponent("PlayableDirector")
    storyRoleEnbaleDictor:Play()
    self.TimerStoryRoleEnable = XScheduleManager.ScheduleOnce(function()
        self.Panel3D.RoleLoop:GetComponent("PlayableDirector"):Play()
        self.Panel3D.StoryRoleEnbale.gameObject:SetActiveEx(false)
    end, math.round(storyRoleEnbaleDictor.duration * XScheduleManager.SECOND))
end

function XUiEpicFashionGacha:OnDisable()
    -- 本地缓存skip按钮状态
    local isSelect = self.BtnSkip:GetToggleState()
    XSaveTool.SaveData(self.SkipBtnKey, isSelect)

    -- 离开界面时关闭视线跟随
    self:SetXPostFaicalControllerActive(false)

    if self.TimerStoryRoleEnable then
        XScheduleManager.UnSchedule(self.TimerStoryRoleEnable)
        self.TimerStoryRoleEnable = nil
    end

    if self.LongAnimTimer then
        XScheduleManager.UnSchedule(self.LongAnimTimer)
        self.LongAnimTimer = nil
    end
end

function XUiEpicFashionGacha:OnDestroy()
    self.ShowFashionTrigger = nil
    self.ShowCourseRewardTrigger = nil
    self.DoGachaTrigger = nil
end

-- 记录战斗前后数据
function XUiEpicFashionGacha:OnReleaseInst()
    return {
        IsGoFight = true
    }
end

function XUiEpicFashionGacha:OnResume(data)
    data = data or {}
    self.IsGoFight = data.IsGoFight
end

function XUiEpicFashionGacha:ShowRewardAfterGacha()
    self:ShowWeaponFashion()
end

function XUiEpicFashionGacha:ShowWeaponFashion()
    local cacheReward = XDataCenter.LottoManager.GetWeaponFashionCacheReward()
    if cacheReward then
        XDataCenter.LottoManager.ClearWeaponFashionCacheReward()
        local data = cacheReward
        local rewards = { { TemplateId = data.ItemId, Count = data.ItemCount } }
        XUiManager.OpenUiObtain(rewards)
    end
end
