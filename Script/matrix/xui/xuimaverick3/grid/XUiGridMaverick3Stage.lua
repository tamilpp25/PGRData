---@class XUiGridMaverick3Stage : XUiNode 关卡节点
---@field Parent XUiMaverick3Chapter
---@field _Control XMaverick3Control
local XUiGridMaverick3Stage = XClass(XUiNode, "XUiGridMaverick3Stage")

function XUiGridMaverick3Stage:OnStart()
    self.GridStage.CallBack = handler(self, self.OnGridStageClick)
end

function XUiGridMaverick3Stage:SetData(stageId)
    self._StageCfg = self._Control:GetStageById(stageId)
    self._IsUnlock = self._Control:IsStageUnlock(stageId)
    self.GridStage:SetNameByGroup(0, self._StageCfg.Name)
    
    if self._IsUnlock then
        self.PanelReward.gameObject:SetActiveEx(true)
        self.PanelLock.gameObject:SetActiveEx(false)
        self.TxtNum.text = string.format("%s%%", self._Control:GetStageProgress(stageId))
        self.TxtLock.text = ""
        -- 首通奖励
        local isPass = self._Control:IsStageFinish(stageId)
        if isPass then
            self.PanelFirst.gameObject:SetActiveEx(false)
        else
            local rewards = XRewardManager.GetRewardList(self._StageCfg.FirstRewardId)
            self.TxtItemNum1.text = rewards[1].Count
            self.RImgTool1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(rewards[1].TemplateId))
            self.PanelFirst.gameObject:SetActiveEx(true)
        end
        -- 通关奖励
        local rewards = XRewardManager.GetRewardList(self._StageCfg.FinishRewardId)
        self.TxtItemNum2.text = rewards[1].Count
        self.RImgTool2:SetRawImage(XDataCenter.ItemManager.GetItemIcon(rewards[1].TemplateId))
        -- 关卡正在进行
        local isPlaying = self._Control:IsStagePlaying(stageId)
        self.PanelOngoing.gameObject:SetActiveEx(isPlaying)
    else
        -- 未解锁
        self.PanelReward.gameObject:SetActiveEx(false)
        self.PanelLock.gameObject:SetActiveEx(true)
        self.PanelOngoing.gameObject:SetActiveEx(false)
        self.TxtNum.text = ""
        local preStage = self._Control:GetStageById(self._StageCfg.PreStageId)
        if self._Control:GetChapterById(preStage.ChapterId).Difficult == XEnumConst.Maverick3.Difficulty.Normal then
            self._UnlockDesc = XUiHelper.GetText("Maverick3PreStageUnlock1", self._Control:GetStageById(self._StageCfg.PreStageId).Name)
        else
            self._UnlockDesc = XUiHelper.GetText("Maverick3PreStageUnlock2", self._Control:GetStageById(self._StageCfg.PreStageId).Name)
        end
        self.TxtLock.text = self._UnlockDesc
    end
end

function XUiGridMaverick3Stage:OnGridStageClick()
    if not self._IsUnlock then
        XUiManager.TipError(self._UnlockDesc)
        return
    end
    if self._Control:GetChapterById(self._StageCfg.ChapterId).Difficult == XEnumConst.Maverick3.Difficulty.Normal then
        XLuaUiManager.OpenWithCloseCallback("UiMaverick3PopupChapterDetail", function()
            self.Parent:OnDetailClose()
        end, self._StageCfg.StageId)
    else
        XLuaUiManager.OpenWithCloseCallback("UiMaverick3PopupChapterDetailRed", function()
            self.Parent:OnDetailClose()
        end, self._StageCfg.StageId)
    end
    self.Parent:OnDetailOpen(self._StageCfg)
end

return XUiGridMaverick3Stage
