---@class XUiTwoSideTowerSettle : XLuaUi
---@field _Control XTwoSideTowerControl
local XUiTwoSideTowerSettle = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerSettle")

function XUiTwoSideTowerSettle:OnAwake()
    self.GridCombo.gameObject:SetActiveEx(false)
end

function XUiTwoSideTowerSettle:OnStart(chapterId)
    self.ChapterId = chapterId
    self.BtnExitFight.CallBack = function() self:Close() end
    self.GridFeatureList = {}
end

function XUiTwoSideTowerSettle:OnEnable()
    self:Refresh()
end

function XUiTwoSideTowerSettle:Refresh()
    local pointIds = self._Control:GetChapterPointIds(self.ChapterId)
    local stageIds = {}
    for _, pointId in pairs(pointIds) do
        local stageId = self._Control:GetPointPassStageId(self.ChapterId, pointId)
        if stageId > 0 then
            table.insert(stageIds, stageId)
        end
    end
    local totalCount = 0
    local shieldCount = 0
    for index, stageId in pairs(stageIds) do
        local grid = self.GridFeatureList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridCombo, self.PanelComboContent)
            grid = XTool.InitUiObjectByUi({}, go)
            self.GridFeatureList[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        local featureId = self._Control:GetStageFeatureId(stageId)
        grid.RImgCombo:SetRawImage(self._Control:GetFeatureIcon(featureId))
        grid.TxtNumber.gameObject:SetActiveEx(false)
        local isShield = self._Control:CheckChapterIsShieldFeature(self.ChapterId, featureId)
        grid.EffectSettle.gameObject:SetActiveEx(isShield)
        grid.EffectRed.gameObject:SetActiveEx(self._Control:GetFeatureType(featureId) == 2)
        
        -- 计算屏蔽数和总数
        if isShield then
            shieldCount = shieldCount + 1
        end
        totalCount = totalCount + 1
    end
    
    local descDetail = self._Control:GetClientConfig("SettleShieldDetail")
    self.TxtShieldDetail.text = XUiHelper.ConvertLineBreakSymbol(XUiHelper.FormatText(descDetail, totalCount - shieldCount, shieldCount))
    local icon = self._Control:GetCurChapterScoreIcon(self.ChapterId)
    self.RImgRank:SetRawImage(icon)
    local desc = self._Control:GetClientConfig("SettleWinTitle")
    self.TxtWinTitle.text = XUiHelper.FormatText(desc, self._Control:GetChapterName(self.ChapterId))
end

return XUiTwoSideTowerSettle
