local XUiPurchaseSceneMainPreview = XLuaUiManager.Register(XLuaUi, "UiPurchaseSceneMainPreview")

local ShowCD = CS.XGame.ClientConfig:GetFloat("ScenePreviewUiHideCD")
local HideDelayCD = CS.XGame.ClientConfig:GetFloat("ScenePreviewUiHideDelay")
local PurchaseBuyPayCD = CS.XGame.ClientConfig:GetInt("PurchaseBuyPayCD") / 1000

--region 生命周期

function XUiPurchaseSceneMainPreview:OnAwake()
    self:AddClickListener()
end

function XUiPurchaseSceneMainPreview:OnStart(sceneId, openType, data, checkCb, finishCb, beforeBuyCb, uiTypes)
    self.SceneId = sceneId
    self:AutoSetUi()
    self.OpenType = openType
    self.CloseByHand = false
    self.Data = data
    self.CheckBuyFun = checkCb
    self.UpdateCb = finishCb
    self.BeforeBuyReqFun = beforeBuyCb
    self.UiTypeList = uiTypes
    
    self.RawImageConsume:SetRawImage(XItemConfigs.GetItemIconById(self.Data.ConsumeId))
    -- 计算实际价格，与涂装逻辑一致
    local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(data)
    local finalCount = math.modf(data.ConvertSwitch * disCountValue)
    
    self.BtnBuy:SetNameByGroup(0, finalCount)
end

function XUiPurchaseSceneMainPreview:OnEnable()
    self:StartScheduleToHideUi(HideDelayCD)
    self:Refresh()

    XEventManager.DispatchEvent(XEventId.EVENT_SCENE_PREVIEW)
    XEventManager.DispatchEvent(XEventId.EVENT_SCENE_UIMAIN_STATE_CHANGE)

    self:AddEventListener()
    self:RefreshBuyButtonState()
end

function XUiPurchaseSceneMainPreview:OnDisable()
    self:StopScheduleToHideUi()
    self:RemoveEventListener()
end

function XUiPurchaseSceneMainPreview:OnDestroy()
    if not self.CloseByHand then
        self.CloseByHand = true
        XDataCenter.PhotographManager.ClearPreviewSceneId()
        if self.OpenType ~= XPhotographConfigs.PreviewOpenType.SceneSetting then
            XDataCenter.GuideManager.SetDisableGuide(false)
        end
    end
end
--endregion

--region 初始化
function XUiPurchaseSceneMainPreview:AutoSetUi()
    local tags = XPhotographConfigs.GetBackgroundTagById(self.SceneId)
    local sceneName = XPhotographConfigs.GetBackgroundNameById(self.SceneId)

    for i = 1, 2 do
        local name = "Function" .. i
        local txtName = "TxtFunction" .. i
        if not string.IsNilOrEmpty(tags[i])then
            self[name].gameObject:SetActiveEx(true)
            self[txtName].text = tags[i]
        else
            self[name].gameObject:SetActiveEx(false)
        end
    end

    self.SceneName.text = sceneName
    self.TogPreview.isOn = true
    self.Scene.gameObject:SetActiveEx(false)
    self.SceneText.gameObject:SetActiveEx(false)

    if self.SwitchBtn == nil then return end
    if not XTool.IsTableEmpty(XPhotographConfigs.GetBackgroundSwitchDescById(self.SceneId)) then
        local btn = require("XUi/XUiSceneTip/XUiSwitchBtn")
        local isFirst = XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full
        self.BtnSwitch = btn.New(self.SwitchBtn, isFirst, self.SceneId, function ()
            self:OnBtnUiClick()
        end)
    else
        self.SwitchBtn.gameObject:SetActiveEx(false)
    end
    self.SceneText.gameObject:SetActiveEx(false)
end

function XUiPurchaseSceneMainPreview:AddClickListener()
    self:RegisterClickEvent(self.TogPreview, self.OnTogPreviewClick)
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnUiAwake, self.OnBtnUiClick)
    self:RegisterClickEvent(self.BtnBuy, self.OnBuyBtnClick)
end
--endregion

--region 界面刷新
function XUiPurchaseSceneMainPreview:Refresh()
    self.TogPreview.isOn = true
    local isFirst = XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full
    if self.BtnSwitch then
        self.BtnSwitch:RefreshSelect(isFirst)
    end
    -- Todo 角色特效
end

function XUiPurchaseSceneMainPreview:RefreshBuyButtonState()
    self._PackageIsEmpty = false
    self._SceneIsHave = false

    -- 无礼包数据或全部购买时不可购买
    if not self.Data or (XTool.IsNumberValid(self.Data.BuyTimes) and self.Data.BuyTimes == self.Data.BuyLimitTimes) then
        self._PackageIsEmpty = true
        self.BtnBuy:SetButtonState(CS.UiButtonState.Disable)
        return
    end

    -- 该场景已拥有时不可重复购买
    if XDataCenter.PhotographManager.CheckSceneIsHaveById(self.SceneId) then
        self._SceneIsHave = true
        self.BtnBuy:SetButtonState(CS.UiButtonState.Disable)
        return
    end

    self.BtnBuy:SetButtonState(CS.UiButtonState.Normal)
end
--endregion

--region 事件回调
-- 唤醒Ui
function XUiPurchaseSceneMainPreview:OnBtnUiClick()
    if not self.InTimer then
        self:PlayUiShowAnim()
    else
        self:StartScheduleToHideUi(ShowCD)
    end
end

function XUiPurchaseSceneMainPreview:OnTogPreviewClick()
    if not self.InTimer then
        self:PlayUiShowAnim()
        self.TogPreview.isOn = true
    else
        XDataCenter.PhotographManager.ClearPreviewSceneId()
        XLuaUiManager.Open("UiPurchaseSceneTip", self.SceneId,self.OpenType, self.Data, self.CheckBuyFun, self.UpdateCb, self.BeforeBuyReqFun, self.UiTypeList)
        XDataCenter.GuideManager.SetDisableGuide(false)
    end
end

function XUiPurchaseSceneMainPreview:OnBuyBtnClick()
    -- 如果所属界面隐藏，则显示UI，不触发购买请求
    if not self.InTimer then
        self:PlayUiShowAnim()
        return
    end
    
    if self._PackageIsEmpty then
        XUiManager.TipText("PurchaseLiSellOut")
    elseif self._SceneIsHave then
        XUiManager.TipText("PurchaseRewardAllHaveErrorTips")
    else
        local now = CS.UnityEngine.Time.realtimeSinceStartup
        if not self.LastBuyTime or (self.LastBuyTime and now - self.LastBuyTime > PurchaseBuyPayCD) then
            self.LastBuyTime = now
            if self.CheckBuyFun then
                -- 存在检测函数
                local result = self.CheckBuyFun(1, nil)
                if result == 1 then
                    if self.BeforeBuyReqFun then
                        -- 购买前执行函数
                        self.BeforeBuyReqFun(function()
                            self:_BuyPurchaseRequest()
                        end)
                        return
                    end
                    self:_BuyPurchaseRequest()
                elseif result ~= 3 then
                    self:CloseTips()
                end
            else
                self:_BuyPurchaseRequest()
            end
        end
    end
end
--endregion

--region 其他
function XUiPurchaseSceneMainPreview:StartScheduleToHideUi(time)
    self:StopScheduleToHideUi()
    self.HideTimer = XScheduleManager.ScheduleAtTimestamp(function()
        self:PlayAnimationWithMask("UiDisable")
        self.InTimer = false
    end, XTime.GetServerNowTimestamp() + time)
    self.InTimer = true
end

function XUiPurchaseSceneMainPreview:StopScheduleToHideUi()
    if XTool.IsNumberValid(self.HideTimer) then
        XScheduleManager.UnSchedule(self.HideTimer)
    end
    self.InTimer = false
end

-- 播放Ui渐显动画
function XUiPurchaseSceneMainPreview:PlayUiShowAnim()
    self:PlayAnimationWithMask("UiEnable", function ()
        -- 开启自动重启倒计时
        self:StartScheduleToHideUi(ShowCD)
    end)
end

function XUiPurchaseSceneMainPreview:Close()
    if not self.InTimer then
        self:PlayUiShowAnim()
    else
        self:ClearPreviewData()
    end
    self.CloseByHand = true
end

function XUiPurchaseSceneMainPreview:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_PREVIEW_STATE_CHANGE, self.PlayChangeModeAnim, self)
end

function XUiPurchaseSceneMainPreview:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_PREVIEW_STATE_CHANGE, self.PlayChangeModeAnim, self)
end

function XUiPurchaseSceneMainPreview:PlayChangeModeAnim()
    self:PlayAnimationWithMask("DarkEnable", function ()
        XEventManager.DispatchEvent(XEventId.EVENT_SCENE_UIMAIN_STATE_CHANGE)
        self:Refresh()
        self:PlayAnimationWithMask("DarkDisable")
    end)
end

function XUiPurchaseSceneMainPreview:ClearPreviewData()
    XDataCenter.PhotographManager.ClearPreviewSceneId()
    self.Super.Close(self)
    if self.OpenType == XPhotographConfigs.PreviewOpenType.SceneSetting then
        XLuaUiManager.CloseWithCallback("UiMain", function()
            XDataCenter.GuideManager.SetDisableGuide(false)
        end)
    end

end

function XUiPurchaseSceneMainPreview:_BuyPurchaseRequest()
    if self.Data and self.Data.Id then
        if not self.CurrentBuyCount or self.CurrentBuyCount == 0 then
            self.CurrentBuyCount = 1
        end
        local discountCouponId = nil
        if self.CurDiscountCouponIndex and self.CurDiscountCouponIndex ~= 0 then
            discountCouponId = self.CurData.DiscountCouponInfos[self.CurDiscountCouponIndex].Id
        end

        XDataCenter.PurchaseManager.PurchaseRequest(self.Data.Id, self.UpdateCb, self.CurrentBuyCount, discountCouponId, self.UiTypeList)
        self:ClearPreviewData()
    end
end

function XUiPurchaseSceneMainPreview:CloseTips()

end
--endregion

return XUiPurchaseSceneMainPreview