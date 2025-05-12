---@class XUiGridWheelChairManualTeachingStage: XUiNode
---@field _Control XWheelchairManualControl
local XUiGridWheelChairManualTeachingStage = XClass(XUiNode, 'XUiGridWheelChairManualTeachingStage')

local ReddotIdMartix = XMath.ToMinInt(math.pow(2, 32)) -- 红点Id的位数计算（与服务端对应，long，前四位记录类型，后四位则是任意类型配置的Id）

function XUiGridWheelChairManualTeachingStage:OnStart(stageId)
    self._StageId = stageId    
    self.TxtTitle.text = XMVCA.XFuben:GetStageName(self._StageId, true)
    
    -- 显示角色头像
    ---@type XTableStage
    local stageCfg = XMVCA.XFuben:GetStageCfg(self._StageId)
    local robotCount = stageCfg.RobotId and #stageCfg.RobotId or 0
    
    XUiHelper.RefreshCustomizedList(self.Head.transform.parent, self.Head, robotCount, function(index, go)
        local uiObj = go:GetComponent("UiObject")
        local icon = XRobotManager.GetRobotSmallHeadIcon(stageCfg.RobotId[index])
        uiObj:GetObject("StandIcon"):SetRawImage(icon)
        uiObj.gameObject:SetActiveEx(true)
    end)
    
    self.GridBtn.CallBack = handler(self, self.OnBtnClickEvent)
end

function XUiGridWheelChairManualTeachingStage:OnEnable()
    self:RefreshState()
end

function XUiGridWheelChairManualTeachingStage:RefreshState()
    local isUnLock = XMVCA.XFuben:CheckStageIsUnlock(self._StageId)
    local isPass = XMVCA.XFuben:CheckStageIsPass(self._StageId)
    
    self.PanelLock.gameObject:SetActiveEx(not isUnLock)
    self.ImgBgComplete.gameObject:SetActiveEx(isPass)
    self.ImgBgNormal.gameObject:SetActiveEx(not isPass and isUnLock)
    
    -- 如果解锁了需要判断是否显示红点
    if isUnLock then
        local id = XEnumConst.WheelchairManual.TabType.Teaching * ReddotIdMartix + self._StageId
        self.GridBtn:ShowReddot(XMVCA.XWheelchairManual:CheckNewUnlockReddotIsShow(id))
    end
end

function XUiGridWheelChairManualTeachingStage:OnBtnClickEvent()
    local isUnLock = XMVCA.XFuben:CheckStageIsUnlock(self._StageId)

    if not isUnLock then
        XUiManager.TipMsg(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('TeachingStageLockTips'))
        return
    end

    -- 尝试消除蓝点
    local id = XEnumConst.WheelchairManual.TabType.Teaching * ReddotIdMartix + self._StageId
    if XMVCA.XWheelchairManual:SetNewUnlockReddotIsOld(id) then
        -- 通知刷新红点
        XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
        self.GridBtn:ShowReddot(XMVCA.XWheelchairManual:CheckNewUnlockReddotIsShow(id))
    end
        
    
    XLuaUiManager.Open('UiWheelChairManualPopupStageDetail', self._StageId)
end

return XUiGridWheelChairManualTeachingStage