local XUiNieRRepeatTag = XClass(nil, "XUiNieRRepeatTag")
local XUiPanelNieRRepeatBanner = require("XUi/XUiNieR/XUiRepeat/XUiPanelNieRRepeatBanner")
function XUiNieRRepeatTag:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.StageNor.gameObject:SetActiveEx(false)
    self.StageNorSel.gameObject:SetActiveEx(false)
    self.StageNor.gameObject:SetActiveEx(false)
    self.StageNorSel.gameObject:SetActiveEx(false)
end

function XUiNieRRepeatTag:Init(data, isSel)
    self.IsActive = data:CheckNieRRepeatMainStageUnlock()
    self.StageId = data:GetNieRRepeatStageId()
    self.Stage = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.IsSelect = isSel
    if self.IsActive then
        self.TextNor.text = self.Stage.Name
        self.TextNorSel.text = self.Stage.Name 
        if not isSel then
            self.StageNor.gameObject:SetActiveEx(true)
            self.StageNorSel.gameObject:SetActiveEx(false)
        else
            self.StageNor.gameObject:SetActiveEx(false)
            self.StageNorSel.gameObject:SetActiveEx(true)
        end
    else
        self.TextDis.text = self.Stage.Name
        self.TextDisSel.text = self.Stage.Name 
        if not isSel then
            self.StageDis.gameObject:SetActiveEx(true)
            self.StageDisSel.gameObject:SetActiveEx(false)
        else
            self.StageDis.gameObject:SetActiveEx(false)
            self.StageDisSel.gameObject:SetActiveEx(true)
        end
    end
end

function XUiNieRRepeatTag:ChangeSelState(isSel)
    if self.IsSelect == isSel then
        return 
    end
    self.IsSelect = isSel
    if self.IsActive then
        if not isSel then
            self.StageNor.gameObject:SetActiveEx(true)
            self.StageNorSel.gameObject:SetActiveEx(false)
        else
            self.StageNor.gameObject:SetActiveEx(false)
            self.StageNorSel.gameObject:SetActiveEx(true)
        end
    else
        if not isSel then
            self.StageDis.gameObject:SetActiveEx(true)
            self.StageDisSel.gameObject:SetActiveEx(false)
        else
            self.StageDis.gameObject:SetActiveEx(false)
            self.StageDisSel.gameObject:SetActiveEx(true)
        end
    end
end

return XUiNieRRepeatTag