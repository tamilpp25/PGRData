---@class XUiEscapeLayerGrid
local XUiEscapeLayerGrid = XClass(nil, "XUiEscapeLayerGrid")

function XUiEscapeLayerGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)

    self.EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self:InitUi()
    self:InitClickEvent()
end

function XUiEscapeLayerGrid:InitUi()
    self.Clear = XUiHelper.TryGetComponent(self.Transform, "Clear")
    --self.Restart = XUiHelper.TryGetComponent(self.Transform, "Restart")
    self.Restart = XUiHelper.TryGetComponent(self.Transform, "BtnRestart")
    self.Btn = self.Transform:GetComponent("XUiButton")
    self.CanvasGroup = self.Transform:GetComponent("CanvasGroup")
    self.Lock = XUiHelper.TryGetComponent(self.Transform, "Lock")
    self.GameObject:AddComponent(typeof(CS.UnityEngine.UI.XEmpty4Raycast))
end

function XUiEscapeLayerGrid:InitClickEvent()
    XUiHelper.RegisterClickEvent(self, self.Btn, self.OnBtnFightClick)
    XUiHelper.RegisterClickEvent(self, self.Restart, self.OnBtnResetClick)
end

function XUiEscapeLayerGrid:Refresh(chapterId, layerId, stageId)
    if not chapterId or not layerId or not stageId then
        self:SetCanvasGroupAlpha(0)
        return
    end
    self.ChapterId = chapterId
    self.LayerId = layerId
    self.StageId = stageId

    local stageColor = XEscapeConfigs.GetStageColor(self.StageId)
    --关卡名
    local stageName = XUiHelper.GetText("EscapeStageTitleTxt", XEscapeConfigs.GetStageTitleColor(stageColor), XDataCenter.FubenManager.GetStageName(stageId))
    self.Btn:SetNameByGroup(0, stageName)
    --背景图
    local bgIcon = XEscapeConfigs.GetStageTitleBg(stageColor)
    if self.Btn.RawImageList.Count > 0 and not string.IsNilOrEmpty(bgIcon) then
        self.Btn:SetRawImage(bgIcon)
    end
    --奖励时间
    local awardTime = XEscapeConfigs.GetStageAwardTime(stageId)
    self.Btn:SetNameByGroup(1, awardTime)
    --关卡描述
    local stageDesc = XEscapeConfigs.GetStageGridDesc(stageId)
    self.Btn:SetNameByGroup(2, stageDesc)

    local layerState = XDataCenter.EscapeManager.GetLayerChallengeState(chapterId, layerId)
    local isStageClear = self.EscapeData:IsCurChapterStageClear(stageId)
    self.Lock.gameObject:SetActiveEx(layerState == XEscapeConfigs.LayerState.Lock)
    self.Btn:SetDisable(not isStageClear and layerState == XEscapeConfigs.LayerState.Pass)
    self.Restart.gameObject:SetActiveEx(isStageClear and layerState == XEscapeConfigs.LayerState.Now)
    self.Clear.gameObject:SetActiveEx(isStageClear)
    self:SetCanvasGroupAlpha(1)
end

function XUiEscapeLayerGrid:SetCanvasGroupAlpha(alpha)
    if not XTool.UObjIsNil(self.CanvasGroup) then
        self.CanvasGroup.alpha = alpha
    end
end

function XUiEscapeLayerGrid:SetActive(active)
    self.GameObject:SetActiveEx(active)
end

function XUiEscapeLayerGrid:OnBtnFightClick()
    local chapterId = self.ChapterId
    local layerId = self.LayerId
    local stageId = self.StageId
    if not chapterId or not layerId or not stageId then
        return
    end

    local layerState = XDataCenter.EscapeManager.GetLayerChallengeState(chapterId, layerId)
    local isStageClear = self.EscapeData:IsCurChapterStageClear(stageId)
    if layerState == XEscapeConfigs.LayerState.Pass and not isStageClear then
        XUiManager.TipErrorWithKey("EscapeCurLayerClear")
        return
    end

    --XLuaUiManager.Open("UiEscapeTeamTips", chapterId, layerId, stageId)
    XLuaUiManager.Open("UiEscape2EnterFight", chapterId, layerId, stageId)
end

function XUiEscapeLayerGrid:OnBtnResetClick()
    local title = XUiHelper.GetText("EscapeResetStageTipsTitle")
    local content = XUiHelper.GetText("EscapeResetStageTipsDesc")
    XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, function() 
        XDataCenter.EscapeManager.RequestEscapeResetStage(self.StageId)
    end)
end

return XUiEscapeLayerGrid