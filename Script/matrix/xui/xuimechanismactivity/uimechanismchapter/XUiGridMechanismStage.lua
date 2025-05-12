--======================================= XUiGridStar ==================================
local XUiGridStar = XClass(XUiNode, 'XUiGridStar')

function XUiGridStar:Refresh(isOn)
    self.ImgStarOn.gameObject:SetActiveEx(isOn)
end

--======================================= XUiGridMechanismStage ==================================
---@class XUiGridMechanismStage
---@field _Control XMechanismActivityControl
---@field Parent XUiPanelMechanismStageList
local XUiGridMechanismStage = XClass(XUiNode, 'XUiGridMechanismStage')

function XUiGridMechanismStage:OnStart(index)
    self.GridBtn.CallBack = handler(self, self.OnClickEvent)
    self._StageIndex = index
    self._StageId = 0
    self._StarGrids = {}
    self.GridStar.gameObject:SetActiveEx(false)
end

function XUiGridMechanismStage:Refresh(stageId)
    if self._StageId ~= stageId then
        self._StageId = stageId
        self.TxtName.text = self._Control:GetStageNameById(self._StageId)
        self.TxtTitle.text = string.format('%02d', self._StageIndex)
    end
    
    -- 刷新状态
    self._UnLock, self._PreStageId = XMVCA.XMechanismActivity:CheckUnlockByStageId(self._StageId)
    
    self.PanelLock.gameObject:SetActiveEx(not self._UnLock)
    self.PanelStar.gameObject:SetActiveEx(self._UnLock)

    if self._UnLock then
        if not XTool.IsTableEmpty(self._StarGrids) then
            for i, v in ipairs(self._StarGrids) do
                v:Close()
            end
        end
        
        -- 刷新星级进度
        local curStar = self._Control:GetStarOfStageById(self._StageId)
        local totalStar = self._Control:GetStarLimitByStageId(self._StageId)

        for i = 1, totalStar do
            if self._StarGrids[i] then
                self._StarGrids[i]:Open()
                self._StarGrids[i]:Refresh(curStar >= i)
            else
                local clone = CS.UnityEngine.GameObject.Instantiate(self.GridStar, self.GridStar.transform.parent)
                local grid = XUiGridStar.New(clone, self)
                grid:Open()
                grid:Refresh(curStar >= i)
                self._StarGrids[i] = grid
            end
        end
        
        self.ImgClear.gameObject:SetActiveEx(curStar >= totalStar)
        
        -- 新解锁蓝点
        self.GridBtn:ShowReddot(not self._Control:CheckStageIsOld(self._StageId))
    end
end

function XUiGridMechanismStage:OnClickEvent()
    if self._UnLock then
        
        -- 消除蓝点
        if not self._Control:CheckStageIsOld(self._StageId) then
            self._Control:SetStageToOld(self._StageId)
            self.GridBtn:ShowReddot(false)
        end
        
        self.Parent:FocusCurStageUI(self._StageId)
        self.Parent:SetSelectStage(self)
        if not XLuaUiManager.IsUiShow('UiMechanismChapterDetail') then
            XLuaUiManager.Open('UiMechanismChapterDetail', self.Parent._ChapterId, self._StageId, self._StageIndex)
        end
    else
        local content = XUiHelper.FormatText(self._Control:GetMechanismClientConfigStr('StageLockTips'), self._Control:GetStageNameById(self._PreStageId))
        XUiManager.TipMsg(content)
    end
end

function XUiGridMechanismStage:SetSelectShow(isShow)
    self.PanelEffectParent.gameObject:SetActiveEx(isShow)
    if not isShow then
        XLuaUiManager.Close('UiMechanismChapterDetail')
    end
end


return XUiGridMechanismStage