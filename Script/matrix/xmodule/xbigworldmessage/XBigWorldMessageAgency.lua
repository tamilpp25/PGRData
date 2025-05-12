---@class XBigWorldMessageAgency : XAgency
---@field private _Model XBigWorldMessageModel
local XBigWorldMessageAgency = XClass(XAgency, "XBigWorldMessageAgency")

function XBigWorldMessageAgency:OnInit()
    -- 初始化一些变量
end

function XBigWorldMessageAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
    XRpc.NotifyBigWorldNotReadMessage = Handler(self, self.OnNotifyBigWorldNotReadMessage)
end

function XBigWorldMessageAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XBigWorldMessageAgency:OnNotifyBigWorldNotReadMessage(data)
    local messageId = data.MessageId
    local messageType = self._Model:GetBigWorldMessageTypeById(messageId)

    if messageType == XEnumConst.BWMessage.MessageType.ForcePlay then
        self._Model:AddForceMessage(data)
        self:TryOpenMessageTipUi()
    else
        self._Model:AddUnReadMessage(data)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_RECEIVE_MESSAGE_NOTIFY)
    end
end

function XBigWorldMessageAgency:UpdateAllMessageData(data)
    self._Model:UpdateAllMessageData(data)
end

function XBigWorldMessageAgency:CheckCanPlayMessageTip()
    return self._Model:HasForceMessageData() and XMVCA.XBigWorldGamePlay:IsInGame()
end

function XBigWorldMessageAgency:CheckUnReadMessage()
    local messages = self._Model:GetUnReadMessageList()

    return not XTool.IsTableEmpty(messages)
end

function XBigWorldMessageAgency:TryOpenMessageTipUi()
    if self:CheckCanPlayMessageTip() then
        XMVCA.XBigWorldUI:Open("UiBigWorldMessageTips")
    end
end

function XBigWorldMessageAgency:OpenUnReadMessageUi()
    XMVCA.XBigWorldUI:Open("UiBigWorldPopupMessage")
end

function XBigWorldMessageAgency:OnReceiveMessage(message)
    -- 暂时屏蔽 后续有需求在接入
    -- local messageId = message.MessageId
    -- local messageType = self._Model:GetBigWorldMessageTypeById(messageId)

    -- if messageType == XEnumConst.BWMessage.MessageType.ForcePlay then
    --     self._Model:AddForceMessage({
    --         MessageId = messageId,
    --         State = XEnumConst.BWMessage.MessageState.NotRead,
    --     })
    --     self:TryOpenMessageTipUi()
    -- elseif messageType == XEnumConst.BWMessage.MessageType.Tips then
    --     self._Model:AddForceMessage({
    --         MessageId = messageId,
    --         State = XEnumConst.BWMessage.MessageState.NotRead,
    --     })
    --     XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_RECEIVE_MESSAGE_NOTIFY)
    --     self:TryOpenMessageTipUi()
    -- else
    --     self._Model:AddUnReadMessage({
    --         MessageId = messageId,
    --         State = XEnumConst.BWMessage.MessageState.NotRead,
    --     })
    --     XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_RECEIVE_MESSAGE_NOTIFY)
    -- end
end

function XBigWorldMessageAgency:RequestBigWorldMessageReadRecord(messageId, stepId, isFinish, callback)
    XNetwork.Call("BigWorldMessageReadRecordRequest", {
        MessageId = messageId,
        StepId = stepId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateMessageData(messageId, stepId, isFinish)

        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            XMVCA.XBigWorldUI:OpenBigWorldObtain(res.RewardGoodsList)
        end

        if callback then
            callback()
        end
    end)
end

return XBigWorldMessageAgency
