local XUiFubenHackDetails = XLuaUiManager.Register(XLuaUi, "UiFubenHackDetails")

function XUiFubenHackDetails:OnAwake()
    self:AutoAddListener()
    self.GridSkillList = {}
end

function XUiFubenHackDetails:OnStart(stageId)
    self.StageId = stageId
    self:InitUi()
end

--function XUiFubenHackDetails:OnGetEvents()
--    return {XEventId.EVENT_ACTIVITY_ON_RESET}
--end
--
--function XUiFubenHackDetails:OnNotify(evt, ...)
--    local args = { ... }
--    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
--        if args[1] ~= XDataCenter.FubenManager.StageType.Hack then return end
--        XDataCenter.FubenHackManager.OnActivityEnd()
--    end
--end

function XUiFubenHackDetails:InitUi()
    local stageInterInfo = XFubenHackConfig.GetStageInfo(self.StageId)
    local count = #stageInterInfo.FeatureTitle

    for i = 1, count do
        local item = self.GridSkillList[i]

        if not item then
            item = CS.UnityEngine.Object.Instantiate(self.GridDetail, self.Content)  -- 复制一个item
            self.GridSkillList[i] = item
        end
        item:Find("TxtTitle"):GetComponent("Text").text = stageInterInfo.FeatureTitle[i]
        item:Find("TxtDesc"):GetComponent("Text").text = XUiHelper.ConvertLineBreakSymbol(stageInterInfo.FeatureDesc[i])
        item:Find("TxtNumber"):GetComponent("Text").text = string.format("%02d", i)
    end
    self.GridDetail.gameObject:SetActiveEx(false)
end

function XUiFubenHackDetails:AutoAddListener()
    self.BtnTanchuangCloseBig.CallBack = function() self:OnBtnTanchuangCloseBigClick() end
end

function XUiFubenHackDetails:OnBtnTanchuangCloseBigClick()
    self:Close()
end
