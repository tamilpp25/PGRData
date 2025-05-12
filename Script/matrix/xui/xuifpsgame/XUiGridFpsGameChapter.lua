---@class XUiGridFpsGameChapter : XUiNode
---@field Parent XUiFpsGameChapter
---@field _Control XFpsGameControl
local XUiGridFpsGameChapter = XClass(XUiNode, "XUiGridFpsGameChapter")

---@param stage XTableFpsGameStage
function XUiGridFpsGameChapter:OnStart(stage, nodeIdx)
    self._Stage = stage
    self._NodeIdx = nodeIdx
    self._IsSingleStar = self._Stage.StarCount == 1

    self.BtnChapter.CallBack = handler(self, self.OnBtnChapterClick)
    self.BtnChapter:SetNameByGroup(0, self._Stage.Name)
    self.ListStar1.gameObject:SetActiveEx(self._IsSingleStar)
    self.ListStar2.gameObject:SetActiveEx(not self._IsSingleStar)
end

function XUiGridFpsGameChapter:RefreshData()
    self._IsUnlock = self._Control:IsStageUnlock(self._Stage.StageId)

    if self._IsUnlock then
        self:Open()

        local starCount = self._Control:GetStageStar(self._Stage.StageId)
        local isNormal = self._Stage.ChapterId == XEnumConst.FpsGame.Story
        if self._IsSingleStar then
            self.StarOn.gameObject:SetActiveEx(starCount >= 1 and isNormal)
            self.StarOnRed.gameObject:SetActiveEx(starCount >= 1 and not isNormal)
            self.StarOff.gameObject:SetActiveEx(starCount < 1)
        else
            for i = 1, self._Stage.StarCount do
                local onNormal = string.format("Star%sOn", i)
                local onHard = string.format("Star%sOnRed", i)
                self[onNormal].gameObject:SetActiveEx(starCount >= i and isNormal)
                self[onHard].gameObject:SetActiveEx(starCount >= i and not isNormal)
                local off = string.format("Star%sOff", i)
                self[off].gameObject:SetActiveEx(starCount < i)
            end
        end
        self.CommonFuBenClear.gameObject:SetActiveEx(starCount >= self._Stage.StarCount)
    else
        self:Close()
    end
end

function XUiGridFpsGameChapter:CheckPanelNowShow(stageId)
    self.PanelNow.gameObject:SetActiveEx(stageId == self._Stage.StageId)
end

function XUiGridFpsGameChapter:OnBtnChapterClick()
    self.Parent:PlayCameraAnim(self._NodeIdx)
    XLuaUiManager.OpenWithCloseCallback("UiFpsGamePopupChapterDetail", function()
        self.Parent:PlayCameraAnim()
    end, self._Stage)
end

function XUiGridFpsGameChapter:BindNode(node3D)
    self._Node3D = node3D
end

function XUiGridFpsGameChapter:RefreshPosition()
    if not self._Node3D then
        return
    end
    if self:IsNodeShow() then
        self.Parent:SetViewPosToTransformLocalPosition(self.Transform, self._Node3D)
    end
end

return XUiGridFpsGameChapter