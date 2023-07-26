---@class XUiReform2ndStage
local XUiReform2ndStage = XClass(nil, "XUiReform2ndStage")

function XUiReform2ndStage:Ctor(rootUi, uiPrefab)
    self.RootUi = rootUi
    self.Data = nil
    
    XTool.InitUiObjectByUi(self, uiPrefab)
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnStageClick)
end

function XUiReform2ndStage:SetData(data)
    self.Data = data
end

function XUiReform2ndStage:GetIsUnlocked()
    return self.Data.IsUnlocked
end

function XUiReform2ndStage:RefreshStage()
    local data = self.Data
    local isSelect = data.IsSelect
    local isUnlocked = data.IsUnlocked

    self.TxtNumber.text = data.Number
    self.TxtStageTitle.text = data.Name
    self.TxtStar.text = data.StarDesc
    self.ImageSelected.gameObject:SetActiveEx(isSelect)
    if self.PanelStageLock then
        self.PanelStageLock.gameObject:SetActiveEx(not isUnlocked)
    end
    self.BtnStage:ShowTag(data.IsFinished)
    self.PanelDifficulty.gameObject:SetActiveEx(data.IsUnlockedDiff)

    if isSelect then
        self.RootUi:RefreshDetailPanel()
    end
end

function XUiReform2ndStage:SetStageSelect(isSelect)
    self.ImageSelected.gameObject:SetActiveEx(isSelect)
    self.Data.IsSelect = isSelect
end

function XUiReform2ndStage:OnStageClick()
    local data = self.Data
    local isUnlocked = data.IsUnlocked
    
    self.RootUi:PlayAnim()

    if not isUnlocked then
        XUiManager.TipMsg(data.UnlockedTip)
        
        return
    end

    self.RootUi:OnStageGridClick(data.Index)
end

return XUiReform2ndStage
