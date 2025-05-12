---@class XBigWorldTeachAgency : XAgency
---@field private _Model XBigWorldTeachModel
local XBigWorldTeachAgency = XClass(XAgency, "XBigWorldTeachAgency")

function XBigWorldTeachAgency:OnInit()
    -- 初始化一些变量
    self._IsIgnoreNotify = false
end

function XBigWorldTeachAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
    XRpc.NotifyBigWorldHelpCourseUnlock = Handler(self, self.OnNotifyBigWorldHelpCourseUnlock)
end

function XBigWorldTeachAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XBigWorldTeachAgency:OnNotifyBigWorldHelpCourseUnlock(data)
    self._Model:AddTeachUnlockServerData(data.Data)

    if not self._IsIgnoreNotify then
        self._Model:AddTeachQueue(data.Data)
        self:TryShowTeach()
    end
end

function XBigWorldTeachAgency:TryShowTeach()
    if XMVCA.XBigWorldGamePlay:IsInGame() then
        local data = self._Model:GetTeachFromQueue()

        if data then
            local teachId = data.Id

            if self:CheckTeachIsForce(teachId) then
                XMVCA.XBigWorldUI:Open("UiBigWorldPopupTeach", teachId)
            else
                XMVCA.XBigWorldUI:Open("UiBigWorldTeachTips", teachId)
            end
        end
    end
end

function XBigWorldTeachAgency:UpdateTeachUnlockServerData(teachDatas)
    self._Model:UpdateTeachUnlockServerData(teachDatas)
end

function XBigWorldTeachAgency:RequestBigWorldHelpCourseUnlock(teachId, isRead, isIgnoreNotify)
    self._IsIgnoreNotify = isIgnoreNotify or false
    XNetwork.Call("BigWorldHelpCourseUnlockRequest", {
        CourseId = teachId,
        IsRead = isRead or false,
    }, function(res)
        self._IsIgnoreNotify = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

function XBigWorldTeachAgency:OnShowTeach(data)
    local teachId = data.TeachId

    if not self._Model:CheckTeachIsUnlock(teachId) then
        self:RequestBigWorldHelpCourseUnlock(teachId)
    end
end

function XBigWorldTeachAgency:OnOpenTeachPopup(data)
    self:OpenTeachTipUi(data.TeachId)
end

function XBigWorldTeachAgency:CheckTeachIsForce(teachId)
    return self._Model:GetBigWorldHelpCourseIsForceById(teachId)
end

function XBigWorldTeachAgency:CheckHasUnReadTeach()
    local unlockTeach = self._Model:GetTeachUnlockServerDatas()

    if not XTool.IsTableEmpty(unlockTeach) then
        for _, data in ipairs(unlockTeach) do
            if not data.IsRead then
                return true
            end
        end
    end

    return false
end

function XBigWorldTeachAgency:OpenTeachMainUi()
    XMVCA.XBigWorldUI:Open("UiBigWorldTeachMain")
end

function XBigWorldTeachAgency:OpenTeachTipUi(teachId)
    if XTool.IsNumberValid(teachId) then
        if not self._Model:CheckTeachIsUnlock(teachId) then
            self:RequestBigWorldHelpCourseUnlock(teachId, false, true)
        end

        XMVCA.XBigWorldUI:Open("UiBigWorldPopupTeach", teachId)
    end
end

return XBigWorldTeachAgency
