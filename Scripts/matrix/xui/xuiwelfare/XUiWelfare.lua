
local XUiWelfare = XLuaUiManager.Register(XLuaUi, "UiWelfare")
---@desc 按钮类型
---@field Primary 一级标签
---@field Secondary 二级标签
local BtnType = {
    Primary = 1,
    Secondary = 2
}
--默认选择
local DefaultSelectIndex = 1


function XUiWelfare:OnAwake()
    self:InitCb()
    self:InitUi()
end

function XUiWelfare:OnStart(tabIndex)
    self.Configs = XSignInConfigs.GetWelfareConfigsWithActivity()
    self.PrefabDict = {}
    self.AfterStart = true
    self.DefaultTabIndex = tabIndex
    
    self:InitView()
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
    for _, info in pairs(self.PrefabDict) do
        if info.Resource then
            info.Resource:Release()
        end

        if info.Prefab then
            info.Prefab:OnHide()
            CS.UnityEngine.Object.Destroy(info.Prefab.GameObject)
        end
    end
    self.PrefabDict = {}
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
            or evt == XEventId.EVENT_ACTIVITY_INFO_UPDATE  then
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
        local firstRedPoint = XSignInConfigs.CheckWelfareRedPoint(functionType)
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
                if subCount > 1 then
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
    self.PanelTitleBtnGroup:Init(self.TabButtons, function(index) self:OnSelectTab(index) end)
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
    }
    
    self.WelfareInViewFunc = {
        [XAutoWindowConfigs.AutoFunctionType.Sign] = handler(self, self.OnRefreshWelfareSign),
        [XAutoWindowConfigs.AutoFunctionType.FirstRecharge] = handler(self, self.OnRefreshWelfareFirstRecharge),
        [XAutoWindowConfigs.AutoFunctionType.Card] = handler(self, self.OnRefreshWelfareCard),
        [XAutoWindowConfigs.AutoFunctionType.WeekChallenge] = handler(self, self.OnRefreshWelfareWeekChallenge),
        [XAutoWindowConfigs.AutoFunctionType.SClassConstructNovice] = handler(self, self.OnRefreshSClassConstructNovice),
    }
end

---@desc 选中页签回调
---@param index 页签下标
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
---@param config 活动配置 Activity.tab
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
    if string.IsNilOrEmpty(activityBg)  then
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
---@param config 福利配置
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
---@param prefabPath 预制路径
---@param parent 预制父物体
---@param modulePath 初始化模块路径
---@return init prefab
function XUiWelfare:LoadFromPrefab(prefabPath, parent, modulePath)
    if string.IsNilOrEmpty(prefabPath) then
        XLog.Error("XUiWelfare:LoadFromPrefab: prefab path id empty!")
        return
    end
    for _, info in pairs(self.PrefabDict) do
        info.Prefab.GameObject:SetActiveEx(false)
    end
    local prefab = self.PrefabDict[prefabPath] and self.PrefabDict[prefabPath].Prefab or nil
    if not prefab then
        local resource = CS.XResourceManager.Load(prefabPath)
        local ui = XUiHelper.Instantiate(resource.Asset, parent)
        ui.gameObject:SetLayerRecursively(parent.gameObject.layer)
        prefab = require(modulePath).New(ui, self)

        if prefab.OnShow then prefab:OnShow() end

        local item = {
            Prefab = prefab,
            Resource = resource
        }
        self.PrefabDict[prefabPath] = item
    end
    return prefab
end

--region   ------------------红点刷新 start-------------------

---@desc 刷新活动类型界面的红点
---@param template 活动配置 Activity.tab
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
    for _, info in pairs(self.PrefabDict) do
        info.Prefab.GameObject:SetActiveEx(false)
    end
    self.PanelTask.gameObject:SetActiveEx(false)
    self.PanelActivityShop.gameObject:SetActiveEx(false)
    self.PanelSkip.gameObject:SetActiveEx(false)
    self.PanelReward.gameObject:SetActiveEx(false)
end

---@desc 刷新【活动-任务】类型界面
---@param template 活动配置 Activity.tab
---@return nil
function XUiWelfare:OnRefreshTask(template)
    self.PanelTask.gameObject:SetActiveEx(true)
    self.TaskPanel = self.TaskPanel or require("XUi/XUiActivityBase/XUiPanelTask").New(self.PanelTask, self)
    self.TaskPanel:Refresh(template)
end

---@desc 刷新【活动-商店】类型界面
---@param template 活动配置 Activity.tab
---@return nil
function XUiWelfare:OnRefreshShop(template)
    self.PanelActivityShop.gameObject:SetActiveEx(true)
    self.ShopPanel = self.ShopPanel or require("XUi/XUiActivityBase/XUiPanelShop").New(self.PanelActivityShop, self)
    self.ShopPanel:Refresh(template)
end

---@desc 刷新【活动-跳转】类型界面
---@param template 活动配置 Activity.tab
---@return nil
function XUiWelfare:OnRefreshSkip(template)
    self.PanelSkip.gameObject:SetActiveEx(true)
    self.SkipPanel = self.SkipPanel or require("XUi/XUiActivityBase/XUiPanelSkip").New(self.PanelSkip)
    self.SkipPanel:Refresh(template)
end

---@desc 刷新【活动-链接】类型界面
---@param template 活动配置 Activity.tab
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
---@param template 福利配置
---@return nil
function XUiWelfare:OnRefreshWelfareSign(template)
    local prefab = self:LoadFromPrefab(template.PrefabPath, self.PanelLoadPrefab1, "XUi/XUiSignIn/XUiSignPrefabContent")
    if not prefab then
        XLog.Error("refresh Sign view error! load prefab empty")
        return
    end
    prefab:Refresh(template.Id, false)
    prefab.GameObject:SetActiveEx(true)
end

---@desc 刷新【福利-首冲】类型界面
---@param template 福利配置
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
---@param template 福利配置
---@return nil
function XUiWelfare:OnRefreshWelfareCard(template)
    local prefab = self:LoadFromPrefab(template.PrefabPath, self.PanelLoadPrefab1, "XUi/XUiSignIn/XUiSignCard")
    if not prefab then
        XLog.Error("refresh Card view error! load prefab empty")
        return
    end
    prefab:Refresh(template.Id, false)
    prefab.GameObject:SetActiveEx(true)

    local btn = self.TabButtons[self.TabIndex]
    if btn then
        btn:ShowReddot(not XDataCenter.PayManager.IsGotCard())
    end
end

---@desc 刷新【福利-周挑战】类型界面
---@param template 福利配置
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
---@param btnType BtnType 按钮类型
---@param hasChild 是否有子节点
---@param pos 位置
---@param totalNum 总数
---@return gameObject
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