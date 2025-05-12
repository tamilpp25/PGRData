---@class XUiSkyGardenShoppingStreetGameCustomer : XUiNode
local XUiSkyGardenShoppingStreetGameCustomer = XClass(XUiNode, "XUiSkyGardenShoppingStreetGameCustomer")
local XUiSkyGardenShoppingStreetInsideBuildGridFeedback = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetInsideBuildGridFeedback")

--region 生命周期
function XUiSkyGardenShoppingStreetGameCustomer:OnStart(...)
    self:_RegisterButtonClicks()
    self._FollowComponet = XUiHelper.TryAddComponent(self.GameObject, typeof(CS.SetUiFollowTarget))
    self:UnBindingCustomer()

    self._FeedbackUi = XUiSkyGardenShoppingStreetInsideBuildGridFeedback.New(self.UiSkyGardenShoppingStreetGridFeedback.gameObject, self)
    self._FeedbackUi:Close()
end

function XUiSkyGardenShoppingStreetGameCustomer:BindingCustomer(customerId, targetTransform)
    self._NpcId = customerId
    if self._FollowComponet and targetTransform then
        self._FollowComponet:StartFollow(XMVCA.XBigWorldGamePlay:GetCamera(), targetTransform, CS.UnityEngine.Vector3.zero, CS.UnityEngine.Vector2(0.5, 0.5))
        self._FollowComponet.CallBack = function()
            self:_FollowFinishCallback()
        end
    end
    self.UiSkyGardenShoppingStreetGameGridEvent.gameObject:SetActive(false)
    self.UiSkyGardenShoppingStreetGameGridFeedback.gameObject:SetActive(false)
    if self._FeedbackUi then self._FeedbackUi:Close() end

    self.RImgHead:SetRawImage(self._Control:GetCustomerHeadIcon(customerId))
end

function XUiSkyGardenShoppingStreetGameCustomer:_FollowFinishCallback()
    local cb = self.Parent.CheckUiRunFinishCallback
    if cb then cb(self.Parent, self._NpcId, self._isArrived) end
end

function XUiSkyGardenShoppingStreetGameCustomer:CheckFinishCallback(isArrived)
    self._isArrived = isArrived
    if self._FollowComponet then self._FollowComponet:CheckFinishCallback() end
end

function XUiSkyGardenShoppingStreetGameCustomer:UnBindingCustomer()
    if self._FeedbackUi then self._FeedbackUi:Close() end
    if self._FollowComponet then
        self._FollowComponet:StopFollow()
    end
end

-- 头像移动刷新
function XUiSkyGardenShoppingStreetGameCustomer:SetUpdateStatus(isUpdate)
    if self._FollowComponet then
        self._FollowComponet.IsRunning = isUpdate
    end
end

-- 增加事件
function XUiSkyGardenShoppingStreetGameCustomer:SetTaskEvent(taskData)
    self._TaskData = taskData
    self._eventData = taskData.EventData
    local XSgStreetCustomerEventType = XMVCA.XSkyGardenShoppingStreet.XSgStreetCustomerEventType
    local isDiscontent = self._eventData.Type == XSgStreetCustomerEventType.Discontent

    self._EventFinish = false
    self.UiSkyGardenShoppingStreetGameGridEvent:SetButtonState(CS.UiButtonState.Normal)
    self.UiSkyGardenShoppingStreetGameGridEvent.gameObject:SetActive(isDiscontent)
    self.UiSkyGardenShoppingStreetGameGridFeedback.gameObject:SetActive(not isDiscontent)

    self._FeedbackUi:Close()
    local keyStr = isDiscontent and "CustomerDiscontentWaitSecond" or "CustomerFeedbackWaitSecond"
    local waitTime = tonumber(self._Control:GetGlobalConfigByKey(keyStr)) * 1000
    self.Parent:RemoveCustomerDelayCallback(self._NpcId, self._TimerId)
    self.Parent:RemoveCustomerDelayCallback(self._NpcId, self._AutoTimerId)
    self._TimerId = false
    self._AutoTimerId = false
    self._TimerId = self.Parent:AddCustomerDelayCallback(self._NpcId, waitTime, function()
        if isDiscontent then
            self.UiSkyGardenShoppingStreetGameGridEvent.gameObject:SetActive(false)
        else
            self.UiSkyGardenShoppingStreetGameGridFeedback.gameObject:SetActive(false)
        end
    end)

    if isDiscontent then
        if self._Control:AutoDiscontentEvent() then
            local delayTime = self._Control:GetGlobalConfigByKey("AutoClickDiscontentDelay") or 1
            self._AutoTimerId = self.Parent:AddCustomerDelayCallback(self._NpcId, delayTime * 1000, function()
                self:OnUiSkyGardenShoppingStreetGameGridEventClick()
            end)
        end
    else
        if self._Control:AutoFeedbackEvent() then
            local delayTime = self._Control:GetGlobalConfigByKey("AutoClickFeedbackDelay") or 1
            self._AutoTimerId = self.Parent:AddCustomerDelayCallback(self._NpcId, delayTime * 1000, function()
                self:OnUiSkyGardenShoppingStreetGameGridFeedbackClick()
            end)
        end
    end
end
--endregion

function XUiSkyGardenShoppingStreetGameCustomer:GetShopId()
    return self._TaskData.TargetId
end

--region 按钮事件
function XUiSkyGardenShoppingStreetGameCustomer:OnUiSkyGardenShoppingStreetGameGridEventClick()
    if self._EventFinish then return end
    self._Control:DoDiscontentEvent(self._eventData.Id, self._eventData.DiscontentAwardGold)
    self.UiSkyGardenShoppingStreetGameGridEvent:SetButtonState(CS.UiButtonState.Disable)
    self._EventFinish = true
    local keyStr = "CustomerDiscontentWaitSecond"
    local waitTime = tonumber(self._Control:GetGlobalConfigByKey(keyStr)) * 1000
    self.Parent:RemoveCustomerDelayCallback(self._NpcId, self._TimerId)
    self._TimerId = false
    self._TimerId = self.Parent:AddCustomerDelayCallback(self._NpcId, waitTime, function()
        self.UiSkyGardenShoppingStreetGameGridEvent.gameObject:SetActive(false)
    end)
end

function XUiSkyGardenShoppingStreetGameCustomer:OnUiSkyGardenShoppingStreetGameGridFeedbackClick()
    local feedback = self._eventData.FeedBackData
    self._Control:DoFeedbackEvent(self._eventData.Id, feedback)
    self.UiSkyGardenShoppingStreetGameGridFeedback.gameObject:SetActive(false)

    if not feedback then return end

    self._FeedbackUi:Open()
    self._FeedbackUi:Update(feedback)
    local waitTime = tonumber(self._Control:GetGlobalConfigByKey("CustomerFeedbackWaitSecond")) * 1000
    self.Parent:RemoveCustomerDelayCallback(self._NpcId, self._TimerId)
    self._TimerId = false
    self._TimerId = self.Parent:AddCustomerDelayCallback(self._NpcId, waitTime, function()
        self._FeedbackUi:Close()
    end)
end

function XUiSkyGardenShoppingStreetGameCustomer:OnUiSkyGardenShoppingStreetGridFeedbackClick()
    if self._FeedbackUi then self._FeedbackUi:Close() end
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetGameCustomer:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.UiSkyGardenShoppingStreetGameGridEvent.CallBack = function() self:OnUiSkyGardenShoppingStreetGameGridEventClick() end
    self.UiSkyGardenShoppingStreetGameGridFeedback.CallBack = function() self:OnUiSkyGardenShoppingStreetGameGridFeedbackClick() end
    self.UiSkyGardenShoppingStreetGridFeedback.CallBack = function() self:OnUiSkyGardenShoppingStreetGridFeedbackClick() end
end
--endregion

return XUiSkyGardenShoppingStreetGameCustomer
