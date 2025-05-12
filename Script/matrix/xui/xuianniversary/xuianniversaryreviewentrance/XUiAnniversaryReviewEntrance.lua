---@class XUiAnniversaryReviewEntrance: XLuaUi
local XUiAnniversaryReviewEntrance = XLuaUiManager.Register(XLuaUi, 'UiAnniversaryReviewEntrance')

--region 生命周期
function XUiAnniversaryReviewEntrance:OnAwake()
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnSkip.CallBack = handler(self, self.OnBtnSkipClick)
end

function XUiAnniversaryReviewEntrance:OnStart()
    XMVCA.XAnniversary:DoSetReviewSlapFaceStateRequest(function(isHitFace)
        self.IsHitFace = isHitFace
    end)
end

function XUiAnniversaryReviewEntrance:OnDestroy()
    if self.IsHitFace then
        XEventManager.DispatchEvent(XEventId.EVENT_REVIEW_ACTIVITY_HIT_FACE_END)
    end
end
--endregion

--region 事件回调
function XUiAnniversaryReviewEntrance:OnBtnSkipClick()
    self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.ReviewH5)
end
--endregion

return XUiAnniversaryReviewEntrance