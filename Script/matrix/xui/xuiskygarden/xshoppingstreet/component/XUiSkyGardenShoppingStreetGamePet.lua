---@class XUiSkyGardenShoppingStreetGamePet : XUiNode
local XUiSkyGardenShoppingStreetGamePet = XClass(XUiNode, "XUiSkyGardenShoppingStreetGamePet")

--region 生命周期
function XUiSkyGardenShoppingStreetGamePet:OnStart()
    self:_RegisterButtonClicks()

    self._MascotData = self._Control:GetMascotData()
    self._DelayTime = tonumber(self._Control:GetGlobalConfigByKey("MascotMessageDelayTime")) * 1000
    self._DelayFunc = handler(self, self._DelayHideFunc)
end

function XUiSkyGardenShoppingStreetGamePet:OnEnable()
end

function XUiSkyGardenShoppingStreetGamePet:OnGetLuaEvents()
    return { XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_LIKE_TALK_REFRESH, }
end

function XUiSkyGardenShoppingStreetGamePet:OnNotify(event)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_LIKE_TALK_REFRESH then
        self:CheckTips()
    end
end

function XUiSkyGardenShoppingStreetGamePet:OnDisable()
    self:_RemoveTimer()
    self:_DelayHideFunc()
end
--endregion

function XUiSkyGardenShoppingStreetGamePet:CheckTips()
    if self._MascotData:HasLikeMessageTag() then
        self.HasLikeMessage = true
        self:_AddMessage(self._MascotData:GetLikeRandomMessage())
    end
end

function XUiSkyGardenShoppingStreetGamePet:StageStartTips()
    if self.HasLikeMessage then return end
    self:_AddMessage(self._MascotData:GetStartRandomMessage())
end

--region 按钮事件
function XUiSkyGardenShoppingStreetGamePet:OnPanelTalkClick()
    self:_RemoveTimer()
    self.PanelTalk.gameObject:SetActive(false)
end

function XUiSkyGardenShoppingStreetGamePet:OnImgPetClick()
    if self.HasLikeMessage then return end
    self:_AddMessage(self._MascotData:GetRandomMessage())
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetGamePet:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.PanelTalk.CallBack = function() self:OnPanelTalkClick() end
    self.ImgPet.CallBack = function() self:OnImgPetClick() end
end

function XUiSkyGardenShoppingStreetGamePet:_AddMessage(msg)
    self.TxtTalk.text = msg
    self:_RemoveTimer()
    self._TimerId = XScheduleManager.ScheduleOnce(self._DelayFunc, self._DelayTime)
    self.PanelTalk.gameObject:SetActive(true)
end

function XUiSkyGardenShoppingStreetGamePet:_DelayHideFunc()
    if self.PanelTalk then
        self.PanelTalk.gameObject:SetActive(false)
    end
    self.HasLikeMessage = false
end

function XUiSkyGardenShoppingStreetGamePet:_RemoveTimer()
    if not self._TimerId then return end
    XScheduleManager.UnSchedule(self._TimerId)
    self._TimerId = nil
end
--endregion

return XUiSkyGardenShoppingStreetGamePet
