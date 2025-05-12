---@class XUiPanelBagOrganizeGuide: XUiNode
---@field _Control XBagOrganizeActivityControl
local XUiPanelBagOrganizeGuide = XClass(XUiNode, 'XUiPanelBagOrganizeGuide')

local TipsProgressLabel = nil

function XUiPanelBagOrganizeGuide:OnStart()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.Close)

    if TipsProgressLabel == nil or XMain.IsEditorDebug then
        TipsProgressLabel = self._Control:GetClientConfigText('TipsProgressLabel')
    end

    self.BtnPrevious.CallBack = handler(self, self.OnBtnLastClick)
    self.BtnNext.CallBack = handler(self, self.OnBtnNextClick)
end

function XUiPanelBagOrganizeGuide:OnEnable()
    local curStageId = self._Control:GetCurStageId()

    if self._StageId ~= curStageId then
        self._StageId = curStageId
        self._CurIndex = 1

        self._GuideImages = self._Control:GetStageGuideImagesById(self._StageId)

        if not XTool.IsTableEmpty(self._GuideImages) then
            self._GuideCount = XTool.GetTableCount(self._GuideImages)

            self._IsMulty = self._GuideCount > 1

            self.BtnPrevious.gameObject:SetActiveEx(self._IsMulty)
            self.BtnNext.gameObject:SetActiveEx(self._IsMulty)
            self.TxtProgress.gameObject:SetActiveEx(self._IsMulty)
        end
    end
    
    self:RefreshBtnState()
    self:RefreshGuideImgShow()
end

function XUiPanelBagOrganizeGuide:RefreshBtnState()
    local isFirst = self._CurIndex == 1
    local isLast = self._CurIndex == self._GuideCount

    self.BtnPrevious:SetButtonState(isFirst and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    self.BtnNext:SetButtonState(isLast and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiPanelBagOrganizeGuide:RefreshGuideImgShow()
    if self._IsMulty then
        self.TxtProgress.text = XUiHelper.FormatText(TipsProgressLabel, self._CurIndex, self._GuideCount)
    end

    self.GuideImg:SetRawImage(self._GuideImages[self._CurIndex])
end

function XUiPanelBagOrganizeGuide:OnBtnLastClick()
    if self._CurIndex > 1 then
        self._CurIndex = self._CurIndex - 1

        self:RefreshBtnState()
        self:RefreshGuideImgShow()
    end
end

function XUiPanelBagOrganizeGuide:OnBtnNextClick()
    if self._CurIndex < self._GuideCount then
        self._CurIndex = self._CurIndex + 1

        self:RefreshBtnState()
        self:RefreshGuideImgShow()
    end
end

return XUiPanelBagOrganizeGuide