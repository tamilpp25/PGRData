local XUiPurchaseSceneTip = XLuaUiManager.Register(XLuaUi, "UiPurchaseSceneTip")
local PurchaseBuyPayCD = CS.XGame.ClientConfig:GetInt("PurchaseBuyPayCD") / 1000
local UiMainMenuType = {
    Main = 1,
    Second = 2,
}

--region 生命周期

function XUiPurchaseSceneTip:OnAwake()
    self:AddClickListener()
end

---@param data @XPurchaseClientInfo
function XUiPurchaseSceneTip:OnStart(sceneId,openType, data, checkCb, finishCb, beforeBuyCb, uiTypes)
    self.SceneId = sceneId
    self.OpenType = openType
    self.Data = data
    self.CheckBuyFun = checkCb
    self.UpdateCb = finishCb
    self.BeforeBuyReqFun = beforeBuyCb
    self.UiTypeList = uiTypes
    
    local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(self.SceneId)
    local scenePath, modelPath = XSceneModelConfigs.GetSceneAndModelPathById(sceneTemplate.SceneModelId)
    self:LoadUiScene(scenePath, modelPath, function() self:SetBatteryUi() end, false)
    self:AutoSetUi()
    
    self.RawImageConsume:SetRawImage(XItemConfigs.GetItemIconById(self.Data.ConsumeId))
    -- 计算实际价格，与涂装逻辑一致
    local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(data)
    local finalCount = math.modf(data.ConvertSwitch * disCountValue)
    self.FinalCount = finalCount
    self.BtnBuy:SetNameByGroup(0, finalCount)
end

function XUiPurchaseSceneTip:OnEnable()
    self:Refresh()
    self:AddEventListener()
    self:RefreshBuyButtonState()
    -- 开启时钟
    self.ClockTimer = XUiHelper.SetClockTimeTempFun(self)
end

function XUiPurchaseSceneTip:OnDisable()
    self:RemoveEventListener()

    -- 关闭时钟
    if self.ClockTimer then
        XUiHelper.StopClockTimeTempFun(self, self.ClockTimer)
        self.ClockTimer = nil
    end
end

--endregion

--region 初始化
function XUiPurchaseSceneTip:SetBatteryUi()
    --self:SetGameObject()
    -- 场景虚拟相机
    self.CamFarMain = self:FindVirtualCamera("CamFarMain")
    if self.CamFarMain then self.CamFarMain.gameObject:SetActive(true) end
    -- 场景动画
    self.AnimationRoot = self.UiSceneInfo.Transform:Find("Animations")
    if XTool.UObjIsNil(self.AnimationRoot) then return end

    self.ToChargeTimeLine = self.AnimationRoot:Find("ToChargeTimeLine")
    self.ToFullTimeLine = self.AnimationRoot:Find("ToFullTimeLine")
    self.FullTimeLine = self.AnimationRoot:Find("FullTimeLine")
    self.ChargeTimeLine = self.AnimationRoot:Find("ChargeTimeLine")

    self.ToChargeTimeLine.gameObject:SetActiveEx(false)
    self.ToFullTimeLine.gameObject:SetActiveEx(false)
    self.FullTimeLine.gameObject:SetActiveEx(false)
    self.ChargeTimeLine.gameObject:SetActiveEx(false)
end

function XUiPurchaseSceneTip:AutoSetUi()
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
    self.TogPreview.isOn = false
    self.BtnUiAwake.gameObject:SetActiveEx(false)

    if self.SwitchBtn == nil then return end
    if  not XTool.IsTableEmpty(XPhotographConfigs.GetBackgroundSwitchDescById(self.SceneId))  then
        local btn = require("XUi/XUiPurchaseSceneTip/XUiSwitchBtn")
        self.BtnSwitch = btn.New(self.SwitchBtn, XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full, self.SceneId)
    else
        self.SwitchBtn.gameObject:SetActiveEx(false)
    end
end

function XUiPurchaseSceneTip:AddClickListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.TogPreview, self.OnTogPreview)
    self:RegisterClickEvent(self.BtnBuy, self.OnBuyBtnClick)
end
--endregion

--region 界面刷新

function XUiPurchaseSceneTip:Refresh()
    self:UpdateBatteryMode()
    self.TogPreview.isOn = false
    local isFirst = XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full
    if self.BtnSwitch then self.BtnSwitch:RefreshSelect(isFirst) end
end

function XUiPurchaseSceneTip:UpdateBatteryMode()
    if XTool.UObjIsNil(self.AnimationRoot) then return end
    local particleGroupName = XDataCenter.PhotographManager.GetSceneTemplateById(self.SceneId).ParticleGroupName
    local chargeAnimator = nil
    if particleGroupName and particleGroupName ~= "" then
        local chargeAnimatorTrans = self.UiSceneInfo.Transform:FindTransform(particleGroupName)
        if chargeAnimatorTrans then
            chargeAnimator = chargeAnimatorTrans:GetComponent("Animator")
        else
            XLog.Error("Can't Find \"" .. particleGroupName .. "\", Plase Check \"ParticleGroupName\" In Share/PhotoMode/Background.tab")
        end
    end

    if XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full then --满电状态
        if chargeAnimator then chargeAnimator:Play("Full") end
        self.FullTimeLine.gameObject:SetActiveEx(true)
        self.ChargeTimeLine.gameObject:SetActiveEx(false)
    else
        if chargeAnimator then chargeAnimator:Play("Low") end
        self.FullTimeLine.gameObject:SetActiveEx(false)
        self.ChargeTimeLine.gameObject:SetActiveEx(true)
    end
end

function XUiPurchaseSceneTip:RefreshBuyButtonState()
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
function XUiPurchaseSceneTip:OnBtnBackClick()
    -- 清除预览场景Id避免返回主界面场景未恢复原有场景
    XDataCenter.PhotographManager.ClearPreviewSceneId()
    XLuaUiManager.Remove("UiPurchaseSceneMainPreview")
    XDataCenter.GuideManager.SetDisableGuide(false)
    if self.OpenType==XPhotographConfigs.PreviewOpenType.SceneSetting then
        XLuaUiManager.RemoveTopOne('UiMain')
    end
    self:Close()

end

function XUiPurchaseSceneTip:OnTogPreview()
    self:PlayAnimationWithMask("DarkEnable", function ()
        if self.OpenType==XPhotographConfigs.PreviewOpenType.SceneSetting then
            XDataCenter.PhotographManager.SetPreviewSceneId(self.SceneId)
            XDataCenter.GuideManager.SetDisableGuide(true)
            XEventManager.DispatchEvent(XEventId.EVENT_SCENE_UIMAIN_RIGHTMIDTYPE_CHANGE, UiMainMenuType.Main)
            self:Close()
        else
            XLuaUiManager.RemoveTopOne('UiPurchaseSceneTip')
            XDataCenter.PhotographManager.OpenScenePreview(self.SceneId, 'UiPurchaseSceneMainPreview', nil, self.Data, self.CheckBuyFun, self.UpdateCb, self.BeforeBuyReqFun, self.UiTypeList)
        end
    end)
end

function XUiPurchaseSceneTip:OnBuyBtnClick()
    if self._PackageIsEmpty then
        XUiManager.TipText("PurchaseLiSellOut")
    elseif self._SceneIsHave then
        XUiManager.TipText("PurchaseRewardAllHaveErrorTips")
    else
        local now = CS.UnityEngine.Time.realtimeSinceStartup
        if not self.LastBuyTime or (self.LastBuyTime and now - self.LastBuyTime > PurchaseBuyPayCD) then
            self.LastBuyTime = now
            if self.CheckBuyFun then
                -- 存在检测函数: 检查参数[购买数量，价格]
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
function XUiPurchaseSceneTip:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_PREVIEW_STATE_CHANGE, self.PlayChangeModeAnim, self)
end

function XUiPurchaseSceneTip:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_PREVIEW_STATE_CHANGE, self.PlayChangeModeAnim, self)
end

function XUiPurchaseSceneTip:PlayChangeModeAnim()
    self:PlayAnimationWithMask("DarkEnable", function ()
        self:Refresh()
        self:PlayAnimationWithMask("DarkDisable", function ()
        end)
    end)
end

function XUiPurchaseSceneTip:_BuyPurchaseRequest()
    if self.Data and self.Data.Id then
        if not self.CurrentBuyCount or self.CurrentBuyCount == 0 then
            self.CurrentBuyCount = 1
        end
        local discountCouponId = nil
        if self.CurDiscountCouponIndex and self.CurDiscountCouponIndex ~= 0 then
            discountCouponId = self.CurData.DiscountCouponInfos[self.CurDiscountCouponIndex].Id
        end

        XDataCenter.PurchaseManager.PurchaseRequest(self.Data.Id, self.UpdateCb, self.CurrentBuyCount, discountCouponId, self.UiTypeList)
        self:OnBtnBackClick()
    end
end

function XUiPurchaseSceneTip:CloseTips()

end
--endregion







return XUiPurchaseSceneTip