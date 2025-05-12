---@class XUiGridDMCFestivalActivityStage: XUiNode
---@field Parent XUiDMCFestivalActivityMain
local XUiGridDMCFestivalActivityStage = XClass(XUiNode, 'XUiGridDMCFestivalActivityStage')

function XUiGridDMCFestivalActivityStage:OnStart()
    
end

function XUiGridDMCFestivalActivityStage:SetNormalStage()
    if self.ImgNor then
        self.ImgNor:SetRawImage(self.FStage:GetIcon())
    end
    
    local chapter = self.FStage:GetChapter()

    if chapter then
        self.TxtStageOrder.text = string.format("%s%d", chapter:GetStagePrefix(), self.FStage:GetOrderIndex() - 1)
    end
    self.TxtStageName.text = self.FStage:GetName()
    -- SetLockStage
    self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
end


function XUiGridDMCFestivalActivityStage:SetPassStage()
    self.PanelStagePass.gameObject:SetActiveEx(self.FStage:GetIsPass())
end

function XUiGridDMCFestivalActivityStage:UpdateNode(festivalId, stageId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    if not fStage then
        return 
    end
    self.FestivalId = festivalId
    self.StageId = stageId
    self.FStage = fStage
    self.FChapter = fStage:GetChapter()
    self.StageIndex = fStage:GetOrderIndex()
    local stagePrefabName = fStage:GetStagePrefab()
    local isOpen, description = self.FStage:GetCanOpen()
    local isShow = self.FStage:GetIsShow()

    if isShow then
        self:Open()
    else
        self:Close()
    end

    local gridGameObject = self.Transform:LoadPrefab(stagePrefabName)
    local uiObj = gridGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    
    if self.ImageSelected then
        self.ImageSelected.gameObject:SetActiveEx(false)
    end
    
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end
    self.IsLock = not isOpen
    self.Description = description
    self:SetNormalStage()
    self:SetPassStage()
end

function XUiGridDMCFestivalActivityStage:OnBtnStageClick()
    if self.FStage then
        if not self.IsLock then
            self.Parent:UpdateNodesSelect(self.StageId)
            -- 打开详细界面
            self.Parent:OpenStageDetails(self.StageId, self.FestivalId)
            self.Parent:PlayScrollViewMove(self.Transform)
        else
            XUiManager.TipMsg(self.Description)
        end

    end
end

function XUiGridDMCFestivalActivityStage:SetNodeSelect(isSelect)
    if not self.IsLock then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridDMCFestivalActivityStage:ResetItemPosition(pos)
    if self.ImgHideLine then
        local rect = self.ImgHideLine:GetComponent("RectTransform").rect
        self.Transform.localPosition = CS.UnityEngine.Vector3(pos.x, pos.y - rect.height, pos.z)
    end
end

return XUiGridDMCFestivalActivityStage
