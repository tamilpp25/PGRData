---@class XUiGridTwoSideTowerStage : XUiNode
---@field _Control XTwoSideTowerControl
local XUiGridTwoSideTowerStage = XClass(XUiNode, "XUiGridTwoSideTowerStage")

function XUiGridTwoSideTowerStage:OnStart(chapterId, callBack)
    self.ChapterId = chapterId
    self.CallBack = callBack
    self.GreatHearUi = XTool.InitUiObjectByUi({}, self.GreatHear)
    self.GridAffixList = {}
    self.GridAffix.gameObject:SetActiveEx(false)
    self.Select.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridTwoSideTowerStage:Refresh(pointId)
    self.PointId = pointId
    -- 节点名称
    self.TxtOrder.text = string.format("%02d", tonumber(self._Control:GetPointNumberName(pointId)))
    local stageIds = self._Control:GetPointStageIds(pointId)
    local stageId = stageIds[1] -- 默认使用第一个关卡id
    -- 头像
    self.GreatHearUi.RImgBossIcon:SetRawImage(self._Control:GetStageSmallMonsterIcon(stageId))
    -- 弱点
    self.RImgWeakIcon:SetRawImage(self._Control:GetStageWeakIcon(stageId))
    -- 节点是否通关
    local isPointPass = self._Control:CheckPointIsPass(self.ChapterId, pointId)
    if self.Select then
        self.Select.gameObject:SetActiveEx(isPointPass)
    end
    -- 刷新特性列表
    for index, id in pairs(stageIds) do
        local grid = self.GridAffixList[index]
        if not grid then
            local go = index == 1 and self.GridAffix or XUiHelper.Instantiate(self.GridAffix, self.PanelAffixList)
            grid = XTool.InitUiObjectByUi({}, go)
            self.GridAffixList[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        local featureId = self._Control:GetStageFeatureId(id)
        local icon = self._Control:GetFeatureIcon(featureId)
        grid.ImgAffixOff:SetRawImage(icon)
        grid.ImgAffixOn:SetRawImage(icon)
        local passStageId = self._Control:GetPointPassStageId(self.ChapterId, pointId)
        local isPass = passStageId == id
        grid.Off.gameObject:SetActiveEx(not isPass)
        grid.On.gameObject:SetActiveEx(isPass)
        grid.PanelScreen.gameObject:SetActiveEx(XTool.IsNumberValid(passStageId) and not isPass)
    end
end

function XUiGridTwoSideTowerStage:GetPointId()
    return self.PointId
end

function XUiGridTwoSideTowerStage:SetSelect(isSelect)
    --if self.Select then
    --    self.Select.gameObject:SetActiveEx(isSelect)
    --end
end

function XUiGridTwoSideTowerStage:OnBtnClick()
    if self.CallBack then
        self.CallBack(self)
    end
end

return XUiGridTwoSideTowerStage
