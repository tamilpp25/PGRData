-- 大秘境关卡节点3D格子
local XUiGridRiftStageGroup3D = XClass(nil, "XUiGridRiftStageGroup3D")

local State = 
{
    Lock = 1,
    Fighting = 2,
    Passed = 3,
    UnLockProgress0 = 4,
}

function XUiGridRiftStageGroup3D:Ctor(ui, object3D, rootUi, rootChapter3D, camera2D, camera3D)
    self.RootUi2D = rootUi
    self.RootChapter3D = rootChapter3D
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Camera2D = camera2D
    self.Camera3D = camera3D
    XTool.InitUiObject(self)
    self.Object3D = {}
    XTool.InitUiObjectByUi(self.Object3D, object3D) -- 将3d的内容加进这
    self.XStageGroup = nil
    self.AffixsGridDic = {}

    self.BtnDetail.CallBack = function () self:OnBtnDetailClick() end
    self.BtnAffixs.CallBack = function () self:OnBtnAffixsClick() end
end

function XUiGridRiftStageGroup3D:SetState(state)
    self.TxtName.gameObject:SetActiveEx(true)
    self.TextAffixs.gameObject:SetActiveEx(true)
    self.PanelAffixs.gameObject:SetActiveEx(true)
    self.Ing.gameObject:SetActiveEx(false)
    self.Nomal.gameObject:SetActiveEx(true)
    self.Lock.gameObject:SetActiveEx(false)
    self.Finish.gameObject:SetActiveEx(false)
    self.BtnAffixs.gameObject:SetActiveEx(true)
    self.BossHead.transform.parent.gameObject:SetActiveEx(true)
    self.Object3D.Normal.gameObject:SetActiveEx(true)
    self.Object3D.Lock.gameObject:SetActiveEx(false)
    self.Object3D.Ing.gameObject:SetActiveEx(false)
    self.Object3D.Finish.gameObject:SetActiveEx(false)

    if state == State.Lock then                     -- 1.上锁
        self.TxtName.gameObject:SetActiveEx(false)
        self.Lock.gameObject:SetActiveEx(true)
        self.Finish.gameObject:SetActiveEx(false)
        self.Ing.gameObject:SetActiveEx(false)
        self.Object3D.Lock.gameObject:SetActiveEx(true)
    elseif state == State.Fighting then             -- 2.作战中
        self.Ing.gameObject:SetActiveEx(true)
        self.Object3D.Ing.gameObject:SetActiveEx(true)
    elseif state == State.Passed then               -- 3.通过
        self.Finish.gameObject:SetActiveEx(true) 
        self.TxtName.gameObject:SetActiveEx(false)
        self.TextAffixs.gameObject:SetActiveEx(false)
        self.PanelAffixs.gameObject:SetActiveEx(false)
        self.BtnAffixs.gameObject:SetActiveEx(false)
        self.BossHead.transform.parent.gameObject:SetActiveEx(false)
        self.Ing.gameObject:SetActiveEx(false)
        self.Nomal.gameObject:SetActiveEx(false)
        self.Object3D.Normal.gameObject:SetActiveEx(false)
        self.Object3D.Lock.gameObject:SetActiveEx(true)
        self.Object3D.Finish.gameObject:SetActiveEx(true) 
    elseif state == State.UnLockProgress0 then      -- 4.已解锁 还没打

    end

    self.GameObject:SetActiveEx(true)
    self.Object3D.GameObject:SetActiveEx(true)
end

function XUiGridRiftStageGroup3D:UpdateData(xStageGroup)
    self.XStageGroup = xStageGroup
    self.BossHead:SetRawImage(xStageGroup:GetBossHead())
    self.TxtName.text = xStageGroup:GetName()
    -- 状态
    local state = nil    
    if xStageGroup:CheckHasLock() then  -- 1.上锁
        state = State.Lock
    elseif xStageGroup:CheckIsOwnFighting() then -- 2.作战中
        state = State.Fighting
    elseif xStageGroup:CheckHasPassed() then    -- 3.通过
        state = State.Passed
    else                                        -- 4.已解锁 还没打
        state = State.UnLockProgress0
    end
    self:SetState(state)

    -- 词缀
    -- 刷新前先隐藏一遍
    self.GridAffixs.gameObject:SetActiveEx(false)
    for k, trans in pairs(self.AffixsGridDic) do
        trans.gameObject:SetActiveEx(false)
    end
    local allAffixs = xStageGroup:GetAllAffixs() -- 所有词缀
    for i = 1, 3 do
        local affixTrans = self.AffixsGridDic[i]
        if not affixTrans then
            affixTrans = CS.UnityEngine.Object.Instantiate(self.GridAffixs, self.GridAffixs.parent)
            self.AffixsGridDic[i] = affixTrans
        end
        local currAffixId = allAffixs[i]
        if not currAffixId then
            break
        end
        local affixCfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(currAffixId)
        if not affixCfg then
            XLog.Error("错误，服务器下发了没有配置的词缀Id ", currAffixId)
            break
        end

        affixTrans:Find("AffixsIcon"):GetComponent("RawImage"):SetRawImage(affixCfg.Icon)
        affixTrans.gameObject:SetActiveEx(true)
    end
    if XTool.IsTableEmpty(allAffixs) then
        self.PanelAffixs.gameObject:SetActiveEx(false)
    end
    -- 幸运关卡要隐藏词缀
    if xStageGroup:GetType() == XRiftConfig.StageGroupType.Luck then
        self.TextAffixs.gameObject:SetActiveEx(false)
        self.PanelAffixs.gameObject:SetActiveEx(false)
    end
end

function XUiGridRiftStageGroup3D:ClearData()
    -- 清空数据。设为空数据状态
    self.XStageGroup = nil
    self.GameObject:SetActiveEx(false)
    self.Object3D.GameObject:SetActiveEx(false)
end

-- 摄像机聚焦到关卡节点
function XUiGridRiftStageGroup3D:SetCameraFocusStageGroup(flag)
    if not self.RootChapter3D.IsCurrFocusOnChapter then -- 当前chapter没有打开的话 返回
        return
    end

    self.Camera2D.gameObject:SetActiveEx(flag)
    self.Camera3D.gameObject:SetActiveEx(flag)
    self.Object3D.Select.gameObject:SetActiveEx(flag)
    if flag then
        self.RootUi2D.ChildUi.Transform:Find("Animation/UiDisable"):PlayTimelineAnimation(function ()
            self.RootUi2D.ChildUi.PanelSelectControl.gameObject:SetActiveEx(false)
        end)
    else
        self.RootUi2D.ChildUi.PanelSelectControl.gameObject:SetActiveEx(true)
        self.RootUi2D.ChildUi.Transform:Find("Animation/UiEnable"):PlayTimelineAnimation(function ()
            self.RootUi2D.ChildUi.PanelSelectControl.gameObject:GetComponent("CanvasGroup").alpha = 1
        end)
    end
end

function XUiGridRiftStageGroup3D:OnBtnAffixsClick()
    XLuaUiManager.Open("UiRiftAffix", self.XStageGroup)
end

function XUiGridRiftStageGroup3D:OnBtnDetailClick()
    -- 通关了不能再次打
    if not self.XStageGroup or self.XStageGroup:CheckHasPassed() then
        return
    end

    -- 幸运关必须在该层开始作战时才能进入
    if self.XStageGroup:GetType() == XRiftConfig.StageGroupType.Luck and not self.XStageGroup:GetParent():CheckHasStarted() then
        XUiManager.TipError(CS.XTextManager.GetText("RiftLucyNodeEnterLimit"))
        return
    end

    if self.XStageGroup:CheckHasLock() then
        XUiManager.TipError(CS.XTextManager.GetText("RiftNodeEnterPreLock"))
        return
    end

    -- 根据当前作战层类型，打开不同的详情界面
    local targetUiName = "UiRiftNormalStageDetail"
    self.RootChapter3D:OnStageGroupClickToFocusCamera(self) -- 点击时打开关卡节点摄像头
    if self.XStageGroup:GetType() == XRiftConfig.StageGroupType.Normal then
        targetUiName = "UiRiftNormalStageDetail"
    elseif self.XStageGroup:GetType() == XRiftConfig.StageGroupType.Zoom then
        targetUiName = "UiRiftZoomStageDetail"
    elseif self.XStageGroup:GetType() == XRiftConfig.StageGroupType.Multi then
        targetUiName = "UiRiftMultiStageDetail"
    elseif self.XStageGroup:GetType() == XRiftConfig.StageGroupType.Luck then
        targetUiName = "UiRiftLuckStageDetail"
    end 
    local closeCb = function ()
        self.RootChapter3D:OnStageGroupClickToFocusCamera(nil) -- 关闭详情界面时，关闭关卡节点摄像头
    end
    XDataCenter.RiftManager.SetCurrSelectRiftStage(self.XStageGroup)
    XLuaUiManager.Open(targetUiName, self.XStageGroup, closeCb)
end

return XUiGridRiftStageGroup3D