local XUiRogueLikeObtainBuff = XLuaUiManager.Register(XLuaUi, "UiRogueLikeObtainBuff")
local XUiGridBuffInfoItem = require("XUi/XUiFubenRogueLike/XUiGridBuffInfoItem")

function XUiRogueLikeObtainBuff:OnAwake()

    self.BtnSure.CallBack = function() self:OnObtainClose() end
    self.BtnCancel.CallBack = function() self:OnObtainClose() end
    self.BtnBack.CallBack = function() self:OnObtainClose() end
    self.BuffInfo = XUiGridBuffInfoItem.New(self, self.GridBuff)
end

function XUiRogueLikeObtainBuff:OnStart(buffIds)
    self.BuffIds = buffIds
    self.BuffInfo:SetBuffInfo(self.BuffIds[1])
end

function XUiRogueLikeObtainBuff:OnEnable()
    XDataCenter.FubenRogueLikeManager.CheckRogueLikeDayResetOnUi("UiRogueLikeObtainBuff")
end

function XUiRogueLikeObtainBuff:OnObtainClose()
    self:Close()
end
