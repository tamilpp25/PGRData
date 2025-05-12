local XUiPanelTask = require("XUi/XUiMoneyReward/XUiPanelTask")
local XUiWelfare = XLuaUiManager.Register(XLuaUi, "UiWelfare")
---@desc 按钮类型
---@field Primary number 一级标签
---@field Secondary number 二级标签
local BtnType = {
    Primary = 1,
    Secondary = 2
}
--默认选择
local DefaultSelectIndex = 1

--选择索引缓存，用于切战斗等回来时界面复原
local SelectIndexCacheForResume = nil

function XUiWelfare:OnAwake()
    self:InitCb()
    self:InitUi()
end

function XUiWelfare:OnStart(tabIndex)
    self.Configs = XSignInConfigs.GetWelfareConfigsWithActivity()
    self.UiNodeDict = {}
    self.AfterStart = true
    self.DefaultTabIndex = tabIndex

    if self.__IsResume then
        self.DefaultTabIndex = SelectIndexCacheForResume
        self.__IsResume = false
        SelectIndexCacheForResume = nil
    end
    self:InitView()
end

function XUiWelfare:OnResume()
    self.__IsResume = true
end

function XUiWelfare:OnEnable()
    --首次进入不刷新，通过SelectIndex刷新
    if XTool.IsNumberValid(self.TabIndex)
            and not self.AfterStart then
        self:RefreshRightView()
    end
    self.AfterStart = false
end

function XUiWelfare:OnDestroy()
    for _, node in pairs(self.UiNodeDict) do
        if node.OnDestroy then
            node:OnDestroy()
        end
    end
    self.UiNodeDict = nil

    if self._WheelChairManualIsOpen then
        XEventManager.RemoveEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_TAB_GOTO, self.OnWheelChairManualSelectEvent, self)
        XEventManager.RemoveEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT, self.OnWheelChairManualTabReddotRefresh, self)
    end

    SelectIndexCacheForResume = self.TabIndex
end

function XUiWelfare:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_VIP_CARD_BUY_SUCCESS,
        XEventId.EVENT_CARD_REFRESH_WELFARE_BTN,
        XEventId.EVENT_ACTIVITY_INFO_UPDATE,
    }
end

function XUiWelfare:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_VIP_CARD_BUY_SUCCESS
            or evt == XEventId.EVENT_CARD_REFRESH_WELFARE_BTN
            or evt == XEventId.EVENT_ACTIVITY_INFO_UPDATE then
        self:RefreshRightView()
    end
end

function XUiWelfare:InitUi()
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnFirstHasSnd.gameObject:SetActiveEx(false)
    self.BtnSecondTop.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    self.BtnSecondBottom.gameObject:SetActiveEx(false)
    self.BtnSecondAll.gameObject:SetActiveEx(false)

    local viewPort = self.PanelTitleBtnGroup.transform.parent
    self.ViewPortHeight = viewPort.transform.rect.height
end

function XUiWelfare:InitCb()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
end

function XUiWelfare:InitView()
    self:InitRefreshFunc()
    self:InitTabButton()
end

---@desc 初始化页签
function XUiWelfare:InitTabButton()
    if XTool.IsTableEmpty(self.Configs) then
        self.PaneNothing.gameObject:SetActiveEx(true)
        return
    end
    self.PaneNothing.gameObject:SetActiveEx(false)
    self.TabButtons = {}
    self.TabIndex2Config = {}
    local btnIndex = 0
    local firstRedPointIndex
    for _, config in ipairs(self.Configs or {}) do
        local functionType = config.FunctionType
        local subCount = #config.SubConfig
        local prefab = self:GetButtonPrefab(BtnType.Primary, subCount > 1)
        local ui = XUiHelper.Instantiate(prefab, self.PanelTitleBtnGroup.transform)
        ui.gameObject:SetActiveEx(true)

        local btn = ui:GetComponent("XUiButton")

        btn:SetRawImage(config.BtnBg)
        btn:SetNameByGroup(0, config.Name)
        table.insert(self.TabButtons, btn)
        btnIndex = btnIndex + 1
        self.TabIndex2Config[btnIndex] = config
        local firstRedPoint = XSignInConfigs.CheckWelfareRedPoint(functionType, config)
        if firstRedPoint and not firstRedPointIndex then
            firstRedPointIndex = btnIndex
        end
        local secondRedPoint
        if subCount > 0 then
            local firstIndex = btnIndex
            for index, subCfg in ipairs(config.SubConfig or {}) do
                if functionType == XAutoWindowConfigs.AutoFunctionType.NoticeActivity then
                    secondRedPoint = XDataCenter.ActivityManager.CheckRedPointByActivityId(subCfg.Id)
                end
                if not (subCount == 1 and XAchievementConfigs.GetActivityGroupIsOnlyGroup(config.Id) == 1) then
                    prefab = self:GetButtonPrefab(BtnType.Secondary, false, index, subCount)
                    ui = XUiHelper.Instantiate(prefab, self.PanelTitleBtnGroup.transform)
                    ui.gameObject:SetActiveEx(true)

                    local btnSecondary = ui:GetComponent("XUiButton")
                    btnSecondary:SetNameByGroup(0, subCfg.Name)
                    btnSecondary.SubGroupIndex = firstIndex
                    table.insert(self.TabButtons, btnSecondary)
                    btnIndex = btnIndex + 1
                    btnSecondary:ShowReddot(secondRedPoint)

                end
                self.TabIndex2Config[btnIndex] = subCfg

                if secondRedPoint then
                    firstRedPoint = true
                    if not firstRedPointIndex then
                        firstRedPointIndex = btnIndex
                    end
                end
            end
        end

        btn:ShowReddot(firstRedPoint)
    end
    self.PanelTitleBtnGroup:Init(self.TabButtons, function(index)
        self:OnSelectTab(index)
    end)
    --如果有外界传值，否则打开第一个红点处，没有红点则打开默认选中
    self.PanelTitleBtnGroup:SelectIndex(self.DefaultTabIndex or firstRedPointIndex or DefaultSelectIndex)
    self:MoveTo()
end

---@desc 跳转到选中位置
function XUiWelfare:MoveTo()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelTitleBtnGroup.transform)
    local selectBtn = self.TabButtons[self.TabIndex]
    local posY = math.abs(selectBtn.transform.localPosition.y)
    local offsetY = posY - self.ViewPortHeight
    if offsetY > 0 then
        local tarPos = self.PanelTitleBtnGroup.transform.localPosition
        tarPos.y = tarPos.y + offsetY + selectBtn.transform.rect.width / 2
        self.PanelTitleBtnGroup.transform.localPosition = tarPos
    end
end

---@desc 初始化刷新函数
function XUiWelfare:InitRefreshFunc()
    self.ActivityInViewFunc = {
        [XActivityConfigs.ActivityType.Task] = handler(self, self.OnRefreshTask),
        [XActivityConfigs.ActivityType.Shop] = handler(self, self.OnRefreshShop),
        [XActivityConfigs.ActivityType.Skip] = handler(self, self.OnRefreshSkip),
        [XActivityConfigs.ActivityType.Link] = handler(self, self.OnRefreshLink),
        [XActivityConfigs.ActivityType.BackFlowLink] = handler(self, self.OnRefreshLink),
        [XActivityConfigs.ActivityType.SendInvitation] = handler(self, self.OnRefreshSendInvitation),
        [XActivityConfigs.ActivityType.AcceptInvitation] = handler(self, self.OnRefreshAcceptInvitation),
        [XActivityConfigs.ActivityType.JigsawPuzzle] = handler(self, self.OnRefreshJigsawPuzzle),
        [XActivityConfigs.ActivityType.ConsumeReward] = handler(self, self.OnRefreshConsumeReward),
        [XActivityConfigs.ActivityType.ScratchTicket] = handler(self, self.OnRefreshScratchTicket),
        [XActivityConfigs.ActivityType.ScratchTicketGolden] = handler(self, self.OnRefreshScratchTicketGolden),
        [XActivityConfigs.ActivityType.RepeatChallengeReward] = handler(self, self.OnRefreshRepeatChallengeReward),
        [XActivityConfigs.ActivityType.WheelChairManual] = handler(self, self.OnRefreshWheelChairManual),
        [XActivityConfigs.ActivityType.GachaCanLiver] = handler(self, self.OnRefreshGachaCanLiver),
    }

    self.WelfareInViewFunc = {
        [XAutoWindowConfigs.AutoFunctionType.Sign] = handler(self, self.OnRefreshWelfareSign),
        [XAutoWindowConfigs.AutoFunctionType.FirstRecharge] = handler(self, self.OnRefreshWelfareFirstRecharge),
        [XAutoWindowConfigs.AutoFunctionType.Card] = handler(self, self.OnRefreshWelfareCard),
        [XAutoWindowConfigs.AutoFunctionType.WeekChallenge] = handler(self, self.OnRefreshWelfareWeekChallenge),
        [XAutoWindowConfigs.AutoFunctionType.SClassConstructNovice] = handler(self, self.OnRefreshSClassConstructNovice),
        [XAutoWindowConfigs.AutoFunctionType.WeekCard] = handler(self, self.OnRefreshWelfareWeekCard),
    }
end

---@desc 选中页签回调
---@param index number 页签下标
---@return nil
function XUiWelfare:OnSelectTab(index)
    index = index > #self.TabButtons and DefaultSelectIndex or index
    if self.TabIndex == index then
        return
    end
    self:PlayAnimation("QieHuan")
    self.TabIndex = index
    self:RefreshRightView()
end

---@desc 刷新右边界面
---@return nil
function XUiWelfare:RefreshRightView()
    if not XTool.IsNumberValid(self.TabIndex) then
        return
    end

    local config = self.TabIndex2Config[self.TabIndex]
    if not config then
        XLog.Error("XUiWelfare.RefreshRightView: could not found config, tabIndex = " .. tostring(self.TabIndex))
        return
    end
    self:HideAll()
    local functionType = config.FunctionType
    if functionType == XAutoWindowConfigs.AutoFunctionType.NoticeActivity then
        self:RefreshActivity(config)
    else
        self:RefreshWelfare(config)
    end
end

---@desc 刷新活动界面
---@param config table 活动配置 Activity.tab
---@return nil
function XUiWelfare:RefreshActivity(config)
    local template = XActivityConfigs.GetActivityTemplate(config.Id)
    if not template then
        XLog.Error("XUiWelfare:RefreshActivity: could not find activity config. Id = " .. tostring(config.Id))
        return
    end
    local activityType = template.ActivityType
    local func = self.ActivityInViewFunc[activityType]
    if not func then
        XLog.Error("could not refresh activity view. activityType = " .. tostring(activityType))
        return
    end
    func(template)
    local bgType = template.ActivityBgType
    local activityBg = config.FullScreenBg
    if string.IsNilOrEmpty(activityBg) then
        XLog.Error("activity ActivityBg is empty. please check Activity.tab. activityId = " .. tostring(config.Id))
    end
    local isSpine = bgType == XActivityConfigs.ActivityBgType.Spine
    self.FullScreenBg.gameObject:SetActiveEx(not isSpine)
    self.SpineRoot.gameObject:SetActiveEx(isSpine)
    if isSpine then
        self.SpineRoot:LoadPrefab(activityBg)
    else
        self.FullScreenBg:SetRawImage(activityBg)
    end
    self:RefreshActivityRedPoint(template)
end

---@desc 刷新福利界面
---@param config table 福利配置
---@return nil
function XUiWelfare:RefreshWelfare(config)
    local functionType = config.FunctionType
    local func = self.WelfareInViewFunc[functionType]
    if not func then
        XLog.Error("could not refresh welfare view. functionType = " .. tostring(functionType))
        return
    end
    func(config)
    self.FullScreenBg.gameObject:SetActiveEx(true)
    self.FullScreenBg:SetRawImage(config.FullScreenBg)
end

---@desc 加载预制，并初始化
---@param prefabPath string 预制路径
---@param parent UnityEngine.Transform 预制父物体
---@param modulePath string 初始化模块路径
function XUiWelfare:LoadFromPrefab(prefabPath, parent, modulePath, ...)
    if string.IsNilOrEmpty(prefabPath) then
        XLog.Error("XUiWelfare:LoadFromPrefab: prefab path id empty!")
        return
    end
    for _, uiNode in pairs(self.UiNodeDict) do
        if uiNode.Close then
            uiNode:Close()
        else
            uiNode.GameObject:SetActiveEx(false)
        end
    end
    local uiNode = self.UiNodeDict[prefabPath]
    if not uiNode then
        local rootGo = CS.UnityEngine.GameObject('', typeof(CS.UnityEngine.RectTransform))
        rootGo.transform:SetParent(parent)
        rootGo.transform.localPosition = Vector3.zero
        rootGo.transform.anchorMin = Vector2.zero
        rootGo.transform.anchorMax = Vector2.one
        rootGo.transform.anchoredPosition = Vector2.zero
        rootGo.transform.localScale = Vector3.one
        rootGo.transform.offsetMin = Vector2.zero
        rootGo.transform.offsetMax = Vector2.zero
        
        local ui = rootGo:LoadPrefab(prefabPath)
        ui.gameObject:SetLayerRecursively(parent.gameObject.layer)
        rootGo.name = ui.name..'Root'

        uiNode = require(modulePath).New(ui, self, ...)

        if uiNode.OnShow then
            uiNode:OnShow()
        elseif uiNode.Open then
            uiNode:Open()
        end
        
        self.UiNodeDict[prefabPath] = uiNode
    end
    return uiNode
end

--region   ------------------红点刷新 start-------------------

---@desc 刷新活动类型界面的红点
---@param template table 活动配置 Activity.tab
---@return nil
function XUiWelfare:RefreshActivityRedPoint(template)
    if not template then
        return
    end
    local activityType = template.ActivityType
    --3种特殊情况，在对应的刷新方法里处理
    local handle = activityType ~= XActivityConfigs.ActivityType.SendInvitation
            and activityType ~= XActivityConfigs.ActivityType.AcceptInvitation
            and activityType ~= XActivityConfigs.ActivityType.Link

    if handle then
        XDataCenter.ActivityManager.SaveInGameNoticeReadList(template.Id)
    end

    local childBtn = self.TabButtons[self.TabIndex]
    childBtn:ShowReddot(XDataCenter.ActivityManager.CheckRedPointByActivityId(template.Id))

    --可能存在一级按钮
    local parentIndex = childBtn.SubGroupIndex
    if XTool.IsNumberValid(parentIndex) and self.TabButtons[parentIndex] then
        local state = false
        for _, btn in pairs(self.TabButtons) do
            if btn.SubGroupIndex and btn.SubGroupIndex == parentIndex
                    and btn.ReddotObj.activeSelf then
                state = true
                break
            end
        end
        self.TabButtons[parentIndex]:ShowReddot(state)
    end
end

--endregion------------------红点刷新 finish------------------


--region   ------------------界面刷新 start-------------------

---@desc 隐藏所有界面
function XUiWelfare:HideAll()
    for _, uiNode in pairs(self.UiNodeDict) do
        if uiNode.Close then
            uiNode:Close()
        else
            uiNode.GameObject:SetActiveEx(false)
        end
    end
    if self.TaskPanel then
        self.TaskPanel:Close()
    else
        self.PanelTask.gameObject:SetActiveEx(false)
    end
    self.PanelActivityShop.gameObject:SetActiveEx(false)
    self.PanelReward.gameObject:SetActiveEx(false)
    self.PanelSkip.gameObject:SetActiveEx(false)
end

---@desc 刷新【活动-任务】类型界面
---@param template XTableActivity 活动配置 Activity.tab
---@return nil
function XUiWelfare:OnRefreshTask(template)
    self.TaskPanel = self.TaskPanel or require("XUi/XUiActivityBase/XUiPanelTask").New(self.PanelTask, self)
    self.TaskPanel:Open()
    self.TaskPanel:Refresh(template)
end

---@desc 刷新【活动-商店】类型界面
---@param template XTableActivity 活动配置 Activity.tab
---@return nil
function XUiWelfare:OnRefreshShop(template)
    self.PanelActivityShop.gameObject:SetActiveEx(true)
    self.ShopPanel = self.ShopPanel or require("XUi/XUiActivityBase/XUiPanelShop").New(self.PanelActivityShop, self)
    self.ShopPanel:Refresh(template)
end

---@desc 刷新【活动-跳转】类型界面
---@param template XTableActivity 活动配置 Activity.tab
---@return nil
function XUiWelfare:OnRefreshSkip(template)
    self.PanelSkip.gameObject:SetActiveEx(true)
    ---@type XUiPanelTask
    self.SkipPanel = self.SkipPanel or require("XUi/XUiActivityBase/XUiPanelSkip").New(self.PanelSkip)
    self.SkipPanel:Refresh(template)
end

---@desc 刷新【活动-链接】类型界面
---@param template XTableActivity 活动配置 Activity.tab
---@return nil
function XUiWelfare:OnRefreshLink(template)
    self.PanelReward.gameObject:SetActiveEx(true)
    self.LinkPanel = self.LinkPanel or require("XUi/XUiActivityBase/XUiPanelLink").New(self.PanelReward, self)
    self.LinkPanel:Refresh(template)

    --刷新红点
    XDataCenter.ActivityManager.HandleLinkActivityRedPoint(template.Id)
end

--region   ------------------自定义活动类型 start-------------------

function XUiWelfare:OnRefreshSendInvitation(template)
    local prefab = self:LoadFromPrefab(template.ActivityPrefabPath, self.PanelLoadPrefab2, "XUi/XUiActivityBase/XUiPanelSendInvitation")
    if not prefab then
        XLog.Error("refresh SendInvitation view error! load prefab empty")
        return
    end
    prefab.GameObject:SetActiveEx(true)
    prefab:Refresh(template)

    --刷新红点
    XDataCenter.RegressionManager.HandleReadSendInvitationActivity()
end

function XUiWelfare:OnRefreshAcceptInvitation(template)
    local prefab = self:LoadFromPrefab(template.ActivityPrefabPath, self.PanelLoadPrefab2, "XUi/XUiActivityBase/XUiPanelAcceptInvitation")
    if not prefab then
        XLog.Error("refresh AcceptInvitation view error! load prefab empty")
        return
    end
    prefab.GameObject:SetActiveEx(true)
    prefab:Refresh(template)

    --刷新红点
    XDataCenter.RegressionManager.HandleReadAcceptInvitationActivity()
end

function XUiWelfare:OnRefreshJigsawPuzzle(template)
    local prefab = self:LoadFromPrefab(template.ActivityPrefabPath, self.PanelLoadPrefab2, "XUi/XUiActivityBase/XUiJigsawPuzzle")
    if not prefab then
        XLog.Error("refresh JigsawPuzzle view error! load prefab empty")
        return
    end
    prefab.GameObject:SetActiveEx(true)
    prefab:Refresh(template)
end

function XUiWelfare:OnRefreshConsumeReward(template)
    local prefab = self:LoadFromPrefab(template.ActivityPrefabPath, self.PanelLoadPrefab2, "XUi/XUiActivityBase/XUiConsumeReward")
    if not prefab then
        XLog.Error("refresh JigsawPuzzle view error! load prefab empty")
        return
    end
    prefab.GameObject:SetActiveEx(true)
    prefab:Refresh(template)
end

function XUiWelfare:OnRefreshScratchTicket(template)
    local prefab = self:LoadFromPrefab(template.ActivityPrefabPath, self.PanelLoadPrefab2, "XUi/XUiActivityBase/XUiScratchTicket")
    if not prefab then
        XLog.Error("refresh JigsawPuzzle view error! load prefab empty")
        return
    end
    prefab.GameObject:SetActiveEx(true)
    prefab:Refresh(template)
end

function XUiWelfare:OnRefreshScratchTicketGolden(template)
    local prefab = self:LoadFromPrefab(template.ActivityPrefabPath, self.PanelLoadPrefab2, "XUi/XUiActivityBase/XUiScratchTicket")
    if not prefab then
        XLog.Error("refresh JigsawPuzzle view error! load prefab empty")
        return
    end
    prefab.GameObject:SetActiveEx(true)
    prefab:Refresh(template)
end

function XUiWelfare:OnRefreshRepeatChallengeReward(template)
    local prefab = self:LoadFromPrefab(template.ActivityPrefabPath, self.PanelLoadPrefab2, 'XUi/XUiActivityBase/XUiRepeatChallengeReward')
    if not prefab then
        XLog.Error("refresh RepeatChallenge view error! load prefab empty")
        return
    end
    prefab.GameObject:SetActiveEx(true)
    prefab:Refresh(template)
end

---@param template XTableActivity 
function XUiWelfare:OnRefreshWheelChairManual(template)
    --参数1是手册页签类型
    local tabType = template.Params[1]

    if XTool.IsNumberValid(tabType) then
        local tabId, url = XMVCA.XWheelchairManual:GetCurActivityTabIdAndPanelUrlByTabType(tabType)
        if not string.IsNilOrEmpty(url) then
            local grid = self:LoadFromPrefab(url, self.PanelFullContent, XEnumConst.WheelchairManual.TabTypeModule[tabType], tabId)
            XUiHelper.SetCanvasesSortingOrder(grid.Transform)
            grid:Open()
            if not self._WheelChairManualIsOpen then
                XEventManager.AddEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_TAB_GOTO, self.OnWheelChairManualSelectEvent, self)
                XEventManager.AddEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT, self.OnWheelChairManualTabReddotRefresh, self)
            end
            self._WheelChairManualIsOpen = true
            
            -- 消除首次点击提示蓝点
            XMVCA.XWheelchairManual:SetLocalReddotAsOld(XEnumConst.WheelchairManual.ReddotKey.EntranceChangedNew)
            self:OnWheelChairManualTabReddotRefresh()
        end
    else
        XLog.Error('公告活动轮椅手册'..tostring(template.Id)..'指定了错误的页签类型:'..tostring(tabType))    
    end
end

---@param template XTableActivity
function XUiWelfare:OnRefreshGachaCanLiver(template)
    local activityId = XMVCA.XGachaCanLiver:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        local prefabAddress = XMVCA.XGachaCanLiver:GetCurActivityMainPrefabAddress()

        if not string.IsNilOrEmpty(prefabAddress) then
            local gachaId = XMVCA.XGachaCanLiver:GetCurActivityResidentGachaId()
            XDataCenter.GachaManager.GetGachaRewardInfoRequest(gachaId, function()
                local grid = self:LoadFromPrefab(prefabAddress, self.PanelFullContent, "XUi/XUiGachaCanLiver/XUiGachaCanLiverMain/XUiPanelGachaLiverDrawBase", gachaId, nil, self, true)
                XUiHelper.SetCanvasesSortingOrder(grid.Transform)
                grid:Open()
            end)
            
        else
            XLog.Error('GachaCanLiver活动Id:'..tostring(activityId)..' 的主界面预制路径配置无效: '..tostring(prefabAddress))
        end
    else
        XLog.Error('公告活动GachaCanLiver卡池没有有效的活动Id'..tostring(activityId)..' ，检查活动是否正常开启，condition配置是否符合预期')    
    end
end

--endregion------------------自定义活动类型 finish------------------

---@desc 刷新【S级新手礼包领取】类型界面
function XUiWelfare:OnRefreshSClassConstructNovice(template)
    local prefab = self:LoadFromPrefab(template.PrefabPath, self.PanelLoadPrefab1, "XUi/XUiSClassConstructWelfare/XUiSClassConstructWelfare")
    if not prefab then
        XLog.Error("refresh WeekChallenge view error! load prefab empty")
        return
    end
    prefab:Refresh(template.Id, false)
    prefab.GameObject:SetActiveEx(true)

    local btn = self.TabButtons[self.TabIndex]
    if btn then
        btn:ShowReddot(XDataCenter.SignInManager.IsShowSignIn(template.Id, true))
    end
end

---@desc 刷新【福利-签到】类型界面
---@param template
---@return nil
function XUiWelfare:OnRefreshWelfareSign(template)
    local prefab = self:LoadFromPrefab(template.PrefabPath, self.PanelLoadPrefab1, "XUi/XUiSignIn/XUiSignPrefabContent")
    if not prefab then
        XLog.Error("refresh Sign view error! load prefab empty")
        return
    end
    prefab:Refresh(template.Id, true)
    prefab.GameObject:SetActiveEx(true)
end

---@desc 刷新【福利-首冲】类型界面
---@param template
---@return nil
function XUiWelfare:OnRefreshWelfareFirstRecharge(template)
    local prefab = self:LoadFromPrefab(template.PrefabPath, self.PanelLoadPrefab1, "XUi/XUiSignIn/XUiSignFirstRecharge")
    if not prefab then
        XLog.Error("refresh FirstRecharge view error! load prefab empty")
        return
    end
    prefab:Refresh(template.Id, false)
    prefab.GameObject:SetActiveEx(true)

    local btn = self.TabButtons[self.TabIndex]
    if btn then
        btn:ShowReddot(not XDataCenter.PayManager.IsGotFirstReCharge())
    end

end

---@desc 刷新【福利-月卡】类型界面
---@param template
---@return nil
function XUiWelfare:OnRefreshWelfareCard(template)
    local prefab = self:LoadFromPrefab(template.PrefabPath, self.PanelLoadPrefab1, "XUi/XUiSignIn/XUiSignCard")
    if not prefab then
        XLog.Error("refresh Card view error! load prefab empty")
        return
    end
    prefab:Refresh(template.Id, false, true)
    prefab.GameObject:SetActiveEx(true)

    self:RefreshWelfareCardRed()
end

-- 刷新月卡红点
function XUiWelfare:RefreshWelfareCardRed()
    local btn = self.TabButtons[self.TabIndex]
    if btn then
        btn:ShowReddot(not XDataCenter.PayManager.IsGotCard())
    end
end

---@desc 刷新【福利-周卡】类型界面
---@param template
---@return nil
function XUiWelfare:OnRefreshWelfareWeekCard(template)
    local prefab = self:LoadFromPrefab(template.PrefabPath, self.PanelLoadPrefab1, "XUi/XUiSignIn/XUiSignWeekCard")
    if not prefab then
        XLog.Error("refresh WeekCard view error! load prefab empty")
        return
    end

    prefab:Open()
    prefab:Refresh(template.Id, true)
    local btn = self.TabButtons[self.TabIndex]
    local weekCardData = XDataCenter.PurchaseManager.GetWeekCardDataBySignInId(template.Id)
    if btn and weekCardData then
        btn:ShowReddot(not weekCardData:GetIsGotToday())
    end
end

---@desc 刷新【福利-周挑战】类型界面
---@param template
---@return nil
function XUiWelfare:OnRefreshWelfareWeekChallenge(template)
    local prefab = self:LoadFromPrefab(template.PrefabPath, self.PanelLoadPrefab1, "XUi/XUiWeekChallenge/XUiWeekChallenge")
    if not prefab then
        XLog.Error("refresh WeekChallenge view error! load prefab empty")
        return
    end
    prefab:Refresh(template.Id, false)
    prefab.GameObject:SetActiveEx(true)

    local btn = self.TabButtons[self.TabIndex]
    if btn then
        btn:ShowReddot(XDataCenter.WeekChallengeManager.IsAnyRewardCanReceived())
    end
end

--endregion------------------界面刷新 finish------------------

---@desc 获取按钮预制
---@param btnType number 按钮类型
---@param hasChild boolean 是否有子节点
---@param pos number 位置
---@param totalNum number 总数
---@return UnityEngine.GameObject
function XUiWelfare:GetButtonPrefab(btnType, hasChild, pos, totalNum)
    if btnType == BtnType.Primary then
        return hasChild and self.BtnFirstHasSnd or self.BtnFirst
    elseif btnType == BtnType.Secondary then
        if totalNum == 1 then
            return self.BtnSecondAll
        end

        if pos == 1 then
            return self.BtnSecondTop
        elseif pos == totalNum then
            return self.BtnSecondBottom
        else
            return self.BtnSecond
        end
    end
end 

function XUiWelfare:OnWheelChairManualSelectEvent(wheelchairManualTabIndex)
    -- 先找到对应的类型
    local tabType = XMVCA.XWheelchairManual:GetCurActivityTabTypeByTabIndex(wheelchairManualTabIndex)
    -- 遍历索引-配置映射表
    if not XTool.IsTableEmpty(self.TabIndex2Config) then
        ---@param config XTableActivity
        for tabindex, config in pairs(self.TabIndex2Config) do
            if config.FunctionType == XAutoWindowConfigs.AutoFunctionType.NoticeActivity then
                local template = XActivityConfigs.GetActivityTemplate(config.Id)
                if template and template.ActivityType == XActivityConfigs.ActivityType.WheelChairManual then
                    if template.Params[1] == tabType then
                        self.PanelTitleBtnGroup:SelectIndex(tabindex)
                    end
                end
            end
        end
    end
end

function XUiWelfare:OnWheelChairManualTabReddotRefresh()
    ---- 红点都是在当前页签内的操作影响当前页签的红点，因此无需遍历全刷新
    if not XTool.IsTableEmpty(self.TabIndex2Config) then
        if XTool.IsNumberValid(self.TabIndex) then
            local template = self.TabIndex2Config[self.TabIndex]

            if template then
                self:RefreshActivityRedPoint(template)
            else
                XLog.Error('尝试刷新手册红点，但当前页签索引TabIndex:'..tostring(self.TabIndex)..'找不到对应的配置')
            end
        else
            XLog.Error('尝试刷新手册红点，但当前页签索引无效TabIndex:'..tostring(self.TabIndex))
        end
    end
end 