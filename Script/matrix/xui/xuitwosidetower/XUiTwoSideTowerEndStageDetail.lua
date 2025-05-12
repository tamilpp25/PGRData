---@class XUiTwoSideTowerEndStageDetail : XLuaUi
---@field _Control XTwoSideTowerControl
local XUiTwoSideTowerEndStageDetail = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerEndStageDetail")

function XUiTwoSideTowerEndStageDetail:OnAwake()
    self:RegisterUiEvents()
    self.GridAffix.gameObject:SetActiveEx(false)
    self.GridAffixList = {}
end

function XUiTwoSideTowerEndStageDetail:OnStart(chapterId)
    self.ChapterId = chapterId
    local endPointId = self._Control:GetChapterEndPointId(chapterId)
    local stageIds = self._Control:GetPointStageIds(endPointId)
    -- 终末节点只有一个关卡Id
    self.CurStageId = stageIds[1]
end

function XUiTwoSideTowerEndStageDetail:OnEnable()
    self:Refresh()
    self:PlayAnimationWithMask("AnimUilEnable")
end

function XUiTwoSideTowerEndStageDetail:Refresh()
    self:RefreshMonster()
    self:RefreshFeatureList()
end

function XUiTwoSideTowerEndStageDetail:RefreshMonster()
    -- Boss图片
    local monsterBg = self._Control:GetChapterMonsterBg(self.ChapterId)
    self.Boos1:SetRawImage(monsterBg)
    self.Boos2:SetRawImage(monsterBg)
    -- 名字
    self.TxtName.text = self._Control:GetStageTypeName(self.CurStageId)
    -- 弱点
    self.RImgWeakIcon:SetRawImage(self._Control:GetStageWeakIcon(self.CurStageId))
    -- 额外特性描述
    local extraFeatureId = self._Control:GetStageExtraFeatureId(self.CurStageId)
    self.TxtDesc.text = self._Control:GetFeatureDesc(extraFeatureId)
    -- 评分降低
    local isLower = self._Control:CheckChapterShieldFeaturesCount(self.ChapterId)
    self.TxtLower.gameObject:SetActiveEx(isLower)
    self.BgLower.gameObject:SetActiveEx(isLower)
end

function XUiTwoSideTowerEndStageDetail:RefreshFeatureList()
    local pointIds = self._Control:GetChapterPointIds(self.ChapterId)
    local stageIds = {}
    for _, pointId in pairs(pointIds) do
        local stageId = self._Control:GetPointPassStageId(self.ChapterId, pointId)
        if stageId > 0 then
            table.insert(stageIds, stageId)
        end
    end
    for index, stageId in pairs(stageIds) do
        local grid = self.GridAffixList[index]
        if not grid then
            local go = index == 1 and self.GridAffix or XUiHelper.Instantiate(self.GridAffix, self.PanelAffixList)
            grid = XTool.InitUiObjectByUi({}, go)
            self.GridAffixList[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid.Empty.gameObject:SetActiveEx(false)
        local featureId = self._Control:GetStageFeatureId(stageId)
        local icon = self._Control:GetFeatureIcon(featureId)
        grid.ImgAffixOff:SetRawImage(icon)
        grid.ImgAffixOn:SetRawImage(icon)
        local isShield = self._Control:CheckChapterIsShieldFeature(self.ChapterId, featureId)
        grid.Off.gameObject:SetActiveEx(isShield)
        grid.On.gameObject:SetActiveEx(not isShield)
        grid.PanelScreen.gameObject:SetActiveEx(isShield)
    end
    for i = #stageIds + 1, #self.GridAffixList do
        self.GridAffixList[i].GameObject:SetActiveEx(false)
    end
end

function XUiTwoSideTowerEndStageDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCombat, self.OnBtnCombatClick)
    XUiHelper.RegisterClickEvent(self, self.BtnShield, self.OnBtnShieldClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAffixList, self.OnBtnShieldClick)
end

function XUiTwoSideTowerEndStageDetail:OnBtnBackClick()
    self:Close()
end

function XUiTwoSideTowerEndStageDetail:OnBtnCombatClick()
    if not XTool.IsNumberValid(self.CurStageId) then
        return
    end
    XLuaUiManager.Open("UiBattleRoleRoom", self.CurStageId, self._Control:GetTeam(),
        require("XUi/XUiTwoSideTower/XUiTwoSideTowerBattleRoleRoom"))
end

function XUiTwoSideTowerEndStageDetail:OnBtnShieldClick()
    XLuaUiManager.Open("UiTwoSideTowerDetails", nil, self.ChapterId, XEnumConst.TwoSideTower.PointType.End,
        function()
            self:Refresh()
        end)
end

return XUiTwoSideTowerEndStageDetail
