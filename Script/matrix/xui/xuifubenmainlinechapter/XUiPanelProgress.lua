---@class XUiPanelProgress
local XUiPanelProgress = XClass(nil, "XUiPanelProgress")

function XUiPanelProgress:Ctor(ui, stageId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageId = stageId
    self:InitAutoScript()
    self:Refresh()
end

function XUiPanelProgress:Refresh()
    local curNumber, totalNumber = XDataCenter.FubenMainLineManager.GetStageClearEventIdsFinishNum(self.StageId)
    if totalNumber <= 0  then
        return
    end
    local clearContrCfg = XFubenMainLineConfigs.GetStageClearContrByStageId(self.StageId)
    if clearContrCfg then
        self.RImgGreyBg:SetRawImage(clearContrCfg.ProgressBgIcon or "")
        self.ImgProgress:SetSprite(clearContrCfg.ProgressBarIcon or "")
    end
    local progress = curNumber / totalNumber
    self.ImgProgress.fillAmount = progress
    self.TxtGreyProgress.text = math.floor(progress * 100)
    self.TxtProgress.text = math.floor(progress * 100)

    if curNumber >= totalNumber then
        self.PanelJd.gameObject:SetActiveEx(false)
    end
end

function XUiPanelProgress:InitAutoScript()
    self:AutoInitUi()
end

function XUiPanelProgress:AutoInitUi()
    ---@type UnityEngine.UI.RawImage
    self.RImgGreyBg = XUiHelper.TryGetComponent(self.Transform, "RawImage", "RawImage")
    ---@type UnityEngine.UI.Image
    self.ImgProgress = XUiHelper.TryGetComponent(self.Transform, "Image", "Image")
    ---@type UnityEngine.UI.Text
    self.TxtGreyProgress = XUiHelper.TryGetComponent(self.Transform, "PanelJd/Text1", "Text")
    ---@type UnityEngine.UI.Text
    self.TxtProgress = XUiHelper.TryGetComponent(self.Transform, "PanelJd/Text2", "Text")
    ---@type UnityEngine.Transform
    self.PanelJd = XUiHelper.TryGetComponent(self.Transform, "PanelJd")
end

return XUiPanelProgress