local CsXTextManager = CS.XTextManager
local tableInsert = table.insert
local XUiGridActivityBossSingle = XClass(nil, "XUiGridActivityBossSingle")

function XUiGridActivityBossSingle:Ctor(parent, ui)
    self.Parent = parent
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridActivityBossSingle:AutoAddListener()
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
end

function XUiGridActivityBossSingle:Refresh(stageId, index)
    self.Index = index
    --刷新是否解锁
    local isUnLock = XDataCenter.FubenActivityBossSingleManager.IsChallengeUnlockByStageId(stageId)
    self.PanelStageLockParent.gameObject:SetActiveEx(not isUnLock)
    self.PanelNor.gameObject:SetActiveEx(isUnLock)
    --self.BtnStage.gameObject:SetActiveEx(isUnLock)
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
    self.BtnStage.gameObject:SetActiveEx(false)
    self.PanelKillParent.gameObject:SetActiveEx(false)
    self.Parent:SelectStageCallBack(self.Index)
end

return XUiGridActivityBossSingle