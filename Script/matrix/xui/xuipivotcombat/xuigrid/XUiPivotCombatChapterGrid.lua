local XUiPivotCombatChapterGrid = XClass(nil, "XUiPivotCombatChapterGrid")

function XUiPivotCombatChapterGrid:Ctor(ui, region, isLockRole, openDetailCb)
    self.Ui = ui
    self.Region = region
    self.OpenDetailCb = openDetailCb
    self.IsLockRole = isLockRole
    --头像脚本列表
    self.HeadList = {}
    self.IsSelect = false
    local grid
    if isLockRole then
        grid = ui.transform:LoadPrefab(XDataCenter.PivotCombatManager.GetLockRoleStagePrefabPath())
    else
        grid = ui.transform:LoadPrefab(XDataCenter.PivotCombatManager.GetStagePrefabPath())
    end
    
    XTool.InitUiObjectByUi(self, grid)
    --头像Ui控件列表
    self.HeadUiList = { self.Head1, self.Head2, self.Head3 }
    self:InitCB()
end 

function XUiPivotCombatChapterGrid:Refresh(stage)
    self.Stage = stage
    local stageId = stage:GetStageId()
    local unlock = XDataCenter.PivotCombatManager.CheckUnlockByStageId(stageId)
    local passed = XDataCenter.PivotCombatManager.CheckPassedByStageId(stageId)
    local gridIcon = stage:GetGridIcon()
    if gridIcon then
        self.ImgNormal:SetRawImage(gridIcon)
    end
    --是否显示关卡
    self.Ui.gameObject:SetActiveEx(unlock)
    --通关状态
    self.ImgClear.gameObject:SetActiveEx(passed)
    --名称
    self.TxtName.text = stage:GetGridName()
    
    self:SetSelect(self.IsSelect)
    
    --锁角色关
    if self.IsLockRole then
        local charIds = self.Stage:GetCharacterList()
        self.HeadList = XDataCenter.PivotCombatManager.RefreshHeadIcon(charIds, self.HeadList, self.HeadUiList)
    end 
    
end

function XUiPivotCombatChapterGrid:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

function XUiPivotCombatChapterGrid:InitCB()
    self.BtnStage.CallBack = function()
        self.IsSelect = true
        self:SetSelect(self.IsSelect)
        if self.OpenDetailCb then
            RunAsyn(function()
                self.OpenDetailCb(self.Region, self.Stage, self.Ui.transform, handler(self, self.Refresh))
                local signalCode, _ = XLuaUiManager.AwaitSignal("UiPivotCombatSecondaryDetail", "SetSelect", self)
                if signalCode ~= XSignalCode.SUCCESS then return end
                self.IsSelect = false
                self:SetSelect(self.IsSelect)
            end)
            
        end
    end
end
return XUiPivotCombatChapterGrid