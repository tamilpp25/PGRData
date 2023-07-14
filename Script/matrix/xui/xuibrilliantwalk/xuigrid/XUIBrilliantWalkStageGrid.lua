--主线关卡选择 每个关卡的格子界面
local XUIBrilliantWalkStageGrid = XClass(nil, "XUIBrilliantWalkStageGrid")

function XUIBrilliantWalkStageGrid:Ctor(perfabObject, rootUi, clickStageCb)
    self.GameObject = perfabObject.gameObject
    self.Transform = perfabObject.transform
    self.RootUi = rootUi
    self.Parent = self.Transform.parent
    XTool.InitUiObject(self)
    self.PanelStageLockParent.gameObject:SetActiveEx(false)
    self.TxtLockInfo.gameObject:SetActiveEx(false) --普通关卡不显示解锁提示
    self.PanelStageSelectedParent.gameObject:SetActiveEx(false)
    self.PanelKillParent.gameObject:SetActiveEx(false)
    self.ClickStageCb = clickStageCb    --点击关卡回调
    self:RegisterButtonEvent()
end

function XUIBrilliantWalkStageGrid:RegisterButtonEvent()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick)
end

function XUIBrilliantWalkStageGrid:Refresh(stageId, chapterId)
    self.StageId = stageId
    self.ChapterId = chapterId
    local UIData = XDataCenter.BrilliantWalkManager.GetUIStageData(stageId)
    if UIData.StageIcon then
        self.RImgStage:SetRawImage(UIData.StageIcon) --设置关卡图片
    end
    self.TxtStageName.text = UIData.StageName --设置关卡名字
    self.PanelKillParent.gameObject:SetActiveEx(UIData.IsClear == true) --通关情况
end

function XUIBrilliantWalkStageGrid:SetSelect(selected)
    self.PanelStageSelectedParent.gameObject:SetActiveEx(selected)
end

function XUIBrilliantWalkStageGrid:OnBtnStageClick()
    self.RootUi:OnStageGridClick(self, self.StageId)
end

function XUIBrilliantWalkStageGrid:GetStageId()
    return self.StageId
end
function XUIBrilliantWalkStageGrid:GetParentLocalPosX()
    return self.Parent.localPosition.x
end


return XUIBrilliantWalkStageGrid