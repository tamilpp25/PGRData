--BOSS关卡选择 每个关卡的格子界面
local XUIBrilliantWalkBossStageGrid = XClass(nil, "XUIBrilliantWalkBossStageGrid")
local STAGE_LOCK_MSG = CsXTextManagerGetText("BrilliantWalkStagelockMsg")
function XUIBrilliantWalkBossStageGrid:Ctor(perfabObject, rootUi, clickStageCb)
    self.GameObject = perfabObject.gameObject
    self.Transform = perfabObject.transform
    self.RootUi = rootUi
    self.Parent = self.Transform.parent
    XTool.InitUiObject(self)
    self.PanelStageLockParent.gameObject:SetActiveEx(false)
    self.PanelStageSelectedParent.gameObject:SetActiveEx(false)
    self.PanelKillParent.gameObject:SetActiveEx(false)
    self.ClickStageCb = clickStageCb    --点击关卡回调
    self:RegisterButtonEvent()
end

function XUIBrilliantWalkBossStageGrid:RegisterButtonEvent()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick)
end

function XUIBrilliantWalkBossStageGrid:Refresh(stageId, chapterId)
    self.StageId = stageId
    self.ChapterId = chapterId
    local UIData = XDataCenter.BrilliantWalkManager.GetUIStageData(stageId)
    self.Unlock = UIData.IsUnLock
    if UIData.StageIcon then
        self.RImgStage:SetRawImage(UIData.StageIcon) --设置关卡图片
    end
    self.TxtStageName.text = UIData.StageName --设置关卡名字
    self.PanelKillParent.gameObject:SetActiveEx(UIData.IsClear == true) --通关情况
    --解锁情况
    self.PanelStageLockParent.gameObject:SetActiveEx(not(self.Unlock == true))
    if not self.Unlock then
        local preStageName = XFubenConfigs.GetStageName(UIData.PerStages[1])
        for i=2,#UIData.PerStages do
            preStageName = preStageName .. "," .. XFubenConfigs.GetStageName(UIData.PerStages[i])
        end
        self.TxtLockInfo.text = CsXTextManagerGetText("BrilliantWalkStageUnlock",preStageName)
    end

end

function XUIBrilliantWalkBossStageGrid:SetSelect(selected)
    self.PanelStageSelectedParent.gameObject:SetActiveEx(selected)
end

function XUIBrilliantWalkBossStageGrid:OnBtnStageClick()
    if not self.Unlock then
        XUiManager.TipMsg(STAGE_LOCK_MSG)
        return
    end
    self.RootUi:OnStageGridClick(self,self.StageId)
end

function XUIBrilliantWalkBossStageGrid:GetStageId()
    return self.StageId
end
function XUIBrilliantWalkBossStageGrid:GetParentLocalPosX()
    return self.Parent.localPosition.x
end


return XUIBrilliantWalkBossStageGrid