--虚像地平线关卡组件
local XUiExpeditionStageDetailComponent = XClass(nil, "XUiExpeditionStageDetailComponent")
local StageScripts = {}
function XUiExpeditionStageDetailComponent:Ctor(chapter, rootUi, ui, storyType)
    self.ChapterComponent = chapter
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = ui.transform.parent
    XTool.InitUiObject(self)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self:AddBtnListener()
    self.EStage = storyType
    local script = self:GetStageScript(storyType)
    if script then self.StageScript = script end
end

function XUiExpeditionStageDetailComponent:GetStageScript(storyType)
    if StageScripts[storyType] ~= nil then return StageScripts[storyType] end
    local scriptName = XDataCenter.ExpeditionManager.StageType[storyType]
    if not scriptName then
        XLog.Error("虚像地平线读取关卡出错！无效的关卡类型：StageType :" .. tostring(storyType))
        return nil
    end
    local script = require("XUi/XUiExpedition/MainPage/StageDetail/XUiExpeditionStage" .. scriptName .. "Detail")
    if not script then
        XLog.Error("虚像地平线读取关卡出错！无效的关卡类型：StageType :" .. tostring(storyType))
        return nil
    end
    StageScripts[storyType] = script
    return script
end

function XUiExpeditionStageDetailComponent:OnEnable()
    if self.StageScript then self.StageScript.OnEnable() end
end

function XUiExpeditionStageDetailComponent:OnUiEnable(ui)
    if self.StageScript and self.EStage then self.StageScript.OnUiEnable(self, ui) end
end

function XUiExpeditionStageDetailComponent:RefreshData(eStage)
    self.EStage = eStage
    self.TxtName.text = self.EStage:GetStageName()
    if self.EStage:GetIsPass() then self.CommonFuBenClear.gameObject:SetActiveEx(true) end
    if self.ImgBoss then
        self.ImgBoss:SetRawImage(self.EStage:GetStageCover())
    end
    local warning = self.EStage:GetStageIsDanger()
    if self.IconYellow then
        self.IconYellow.gameObject:SetActiveEx(warning == XDataCenter.ExpeditionManager.StageWarning.Warning)
    end
    if self.IconRed then
        self.IconRed.gameObject:SetActiveEx(warning == XDataCenter.ExpeditionManager.StageWarning.Danger)
    end
    if self.TxtWave then
        self.TxtWave.text = XDataCenter.ExpeditionManager.GetWave()
    end
    if self.StageScript then self.StageScript.RefreshData(self, self.EStage) end
end

function XUiExpeditionStageDetailComponent:OnDisable()
    if self.StageScript then self.StageScript.OnDisable() end
end

function XUiExpeditionStageDetailComponent:OnUiDisable(ui)
    if self.StageScript then self.StageScript.OnUiDisable(self, ui) end
end

function XUiExpeditionStageDetailComponent:OnDestroy()
    if self.StageScript then self.StageScript.OnDestroy() end
end

function XUiExpeditionStageDetailComponent:CancelSelect()
    if self.StageScript then self.StageScript.CancelSelect(self) end
end

function XUiExpeditionStageDetailComponent:SetSelect()
    if self.StageScript then self.StageScript.SetSelect(self) end
end

function XUiExpeditionStageDetailComponent:OnBtnStageClick()
    local canOpen = self.ChapterComponent:ClickStage(self)
    if canOpen and self.StageScript then self.StageScript.OnClick(self) end
end

function XUiExpeditionStageDetailComponent:AddBtnListener()
    CsXUiHelper.RegisterClickEvent(self.ImgStage, function() self:OnBtnStageClick() end)
end
return XUiExpeditionStageDetailComponent