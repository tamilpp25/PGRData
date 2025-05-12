--- 超难关关卡入口
---@class XUiGridActivityBossSingle: XUiNode
local XUiGridActivityBossSingle = XClass(XUiNode, "XUiGridActivityBossSingle")

function XUiGridActivityBossSingle:OnStart()
    self:AutoAddListener()
end

function XUiGridActivityBossSingle:AutoAddListener()
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
end

function XUiGridActivityBossSingle:Refresh(stageId, index)
    self.StageId = stageId
    self.Index = index
    --刷新是否解锁
    local isUnLock = XDataCenter.FubenActivityBossSingleManager.IsChallengeUnlockByStageId(stageId)
    self.BtnStage:SetButtonState(isUnLock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    local bgMaskName = "Img" .. index .. "BgMask"
    if self.Parent[bgMaskName] then
        self.Parent[bgMaskName].gameObject:SetActiveEx(isUnLock)
    end
    self.IsUnLock = isUnLock
    --刷新红点显示
    local starMap = XDataCenter.FubenActivityBossSingleManager.GetStageStarMap(stageId)
    for i = 1, #starMap do
        self["ImgOn" .. i].gameObject:SetActiveEx(starMap[i])
        self["ImgOff" .. i].gameObject:SetActiveEx(not starMap[i]) 
    end
    --刷新是否通关显示
    local isPassed = XDataCenter.FubenActivityBossSingleManager.IsChallengePassedByStageId(stageId)
    self.PanelKillParent.gameObject:SetActiveEx(isPassed)
end

function XUiGridActivityBossSingle:OnBtnStageClick()
    if self.IsUnLock == false then
        XUiManager.TipText("ActivityBossOpenTip")
        return
    end
    
    XLuaUiManager.Open('UiActivityBossSinglePopupStageDetail', self.StageId)
end

return XUiGridActivityBossSingle