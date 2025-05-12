---@class XUiTwoSideTowerStageDetail : XLuaUi
---@field _Control XTwoSideTowerControl
local XUiTwoSideTowerStageDetail = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerStageDetail")

function XUiTwoSideTowerStageDetail:OnAwake()
    self:RegisterUiEvents()
    self.BtnReset.gameObject:SetActiveEx(false)
    self.BtnFeature.gameObject:SetActiveEx(false)
    self.BtnCombat.gameObject:SetActiveEx(false)
    self.BtnAuto.gameObject:SetActiveEx(false)
    self.GridFeatureList = {}
end

function XUiTwoSideTowerStageDetail:OnStart(pointId, chapterId, callBack)
    self.CallBack = callBack
    self.PointId = pointId
    self.ChapterId = chapterId

    self.GreatHearUi = XTool.InitUiObjectByUi({}, self.GreatHear)
    self.StageIds = self._Control:GetPointStageIds(self.PointId)
    self:InitFeature()
end

function XUiTwoSideTowerStageDetail:OnEnable()
    self:Refresh()
    self:PlayAnimationWithMask("AnimUilEnable")
end

function XUiTwoSideTowerStageDetail:OnDisable()
   self:CancelSelect()
end

function XUiTwoSideTowerStageDetail:CancelSelect()
    self.BtnGroup:CancelSelect()
    self.SelectIndex = 0
    self.CurSelectStageId = 0
end

function XUiTwoSideTowerStageDetail:InitFeature()
    ---@type XUiComponent.XUiButton[]
    self.TagBtnList = {}
    for index, stageId in pairs(self.StageIds) do
        local btn = index == 1 and self.BtnFeature or XUiHelper.Instantiate(self.BtnFeature, self.PanelFeatureList)
        btn.gameObject:SetActiveEx(true)
        local featureId = self._Control:GetStageFeatureId(stageId)
        btn:SetNameByGroup(0, self._Control:GetFeatureName(featureId))
        btn:SetNameByGroup(1, self._Control:GetFeatureDesc(featureId))
        btn:SetRawImage(self._Control:GetFeatureIcon(featureId))
        self.TagBtnList[index] = btn
    end
    self.BtnGroup:Init(self.TagBtnList, function(index) self:OnSelectBtnTag(index) end)
end

function XUiTwoSideTowerStageDetail:OnSelectBtnTag(index)
    if self.SelectIndex == index then
        return
    end
    local stageId = self.StageIds[index]
    if self.IsPointPass and self.PassStageId ~= stageId then
        return
    end
    self.SelectIndex = index
    self.CurSelectStageId = stageId
    self:RefreshAutoBtn()
    self:RefreshView()
end

function XUiTwoSideTowerStageDetail:GetDefaultSelectIndex()
    local contain, index = table.contains(self.StageIds, self.PassStageId)
    if contain then
        return index
    end
    return 0
end

function XUiTwoSideTowerStageDetail:Refresh()
    -- 节点是否通关
    self.IsPointPass = self._Control:CheckPointIsPass(self.ChapterId, self.PointId)
    -- 已通关关卡Id
    self.PassStageId = self._Control:GetPointPassStageId(self.ChapterId, self.PointId)
    self:RefreshMonster()
    self:RefreshFeatureStatus()
    self:RefreshBtn()
end

function XUiTwoSideTowerStageDetail:RefreshMonster()
    local stageId = self.StageIds[1] -- 默认使用第一个关卡id
    -- 背景
    self.Bg:SetRawImage(self._Control:GetClientConfig("StageDetailBg", self.IsPointPass and 2 or 1))
    -- 头像
    self.GreatHearUi.RImgBossIcon:SetRawImage(self._Control:GetStageSmallMonsterIcon(stageId))
    -- 名称
    self.TxtName.text = self._Control:GetStageTypeName(stageId)
    -- 弱点
    self.RImgWeakIcon:SetRawImage(self._Control:GetStageWeakIcon(stageId))
    -- 额外特性描述
    local extraFeatureId = self._Control:GetStageExtraFeatureId(stageId)
    self.TxtDesc.text = self._Control:GetFeatureDesc(extraFeatureId)
end

function XUiTwoSideTowerStageDetail:RefreshFeatureStatus()
    if self.IsPointPass then
        local index = self:GetDefaultSelectIndex()
        for i, btn in pairs(self.TagBtnList) do
            btn:SetDisable(XTool.IsNumberValid(index) and i ~= index)
            btn:ShowTag(XTool.IsNumberValid(index) and i == index)
        end
        if XTool.IsNumberValid(index) then
            self.BtnGroup:SelectIndex(index)
        end
    else
        for _, btn in pairs(self.TagBtnList) do
            btn:SetDisable(false)
            btn:ShowTag(false)
        end
        self:RefreshAutoBtn()
        self:RefreshView()
    end
end

function XUiTwoSideTowerStageDetail:RefreshBtn()
    -- 重置
    self.BtnReset.gameObject:SetActiveEx(self.IsPointPass)
    -- 战斗
    self.BtnCombat.gameObject:SetActiveEx(not self.IsPointPass)
end

function XUiTwoSideTowerStageDetail:RefreshAutoBtn()
    -- 自动作战
    local isSweep = false
    if not self.IsPointPass and XTool.IsNumberValid(self.CurSelectStageId) then
        isSweep = self._Control:CheckIsCanSweepStageId(self.ChapterId, self.CurSelectStageId)
    end
    self.BtnAuto.gameObject:SetActiveEx(isSweep)
end

function XUiTwoSideTowerStageDetail:RefreshView()
    local isSelectPoint = XTool.IsNumberValid(self.CurSelectStageId)
    -- 未选择特性提示
    self.Text2.gameObject:SetActiveEx(not isSelectPoint)
    if not isSelectPoint then
        self.Text2.text = self._Control:GetClientConfig("StageDetailNotSelectPointTip")
    end
    self.BtnCombat:SetDisable(not isSelectPoint)
end

function XUiTwoSideTowerStageDetail:OnEnterFight()
    XLuaUiManager.Open("UiBattleRoleRoom", self.CurSelectStageId, self._Control:GetTeam(),
            require("XUi/XUiTwoSideTower/XUiTwoSideTowerBattleRoleRoom"))
end

function XUiTwoSideTowerStageDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnReset, self.OnBtnResetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCombat, self.OnBtnCombatClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAuto, self.OnBtnAutoClick)
end

function XUiTwoSideTowerStageDetail:OnBtnBackClick()
    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

-- 重置节点
function XUiTwoSideTowerStageDetail:OnBtnResetClick()
    local title = self._Control:GetClientConfig("ResetPointTitle")
    local content = self._Control:GetClientConfig("ResetPointContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        self._Control:TwoSideTowerResetPointRequest(self.ChapterId, self.PointId, function()
            self:CancelSelect()
            self:Refresh()
        end)
    end)
end

-- 战斗
function XUiTwoSideTowerStageDetail:OnBtnCombatClick()
    if not XTool.IsNumberValid(self.CurSelectStageId) then
        XUiManager.TipMsg(self._Control:GetClientConfig("PointDetailNotSelectTip"))
        return
    end
    local isHint = self._Control:GetBattleDialogHintCookie()
    if not isHint then
        local title = self._Control:GetClientConfig("BattleDialogHintTitle")
        local content = self._Control:GetClientConfig("BattleDialogHintContent")
        local hintInfo = {
            SetHintCb = function(value)
                self._Control:SaveBattleDialogHintCookie(value)
            end,
            Status = isHint,
            HintText = XUiHelper.GetText("EnterNoTips"),
        }
        self._Control:DialogHintTip(title, content, "", nil, function()
            self:OnEnterFight()
        end, hintInfo)
    else
        self:OnEnterFight()
    end
end

-- 自动作战
function XUiTwoSideTowerStageDetail:OnBtnAutoClick()
    if not XTool.IsNumberValid(self.CurSelectStageId) then
        XUiManager.TipMsg(self._Control:GetClientConfig("PointDetailNotSelectTip"))
        return
    end
    local title = self._Control:GetClientConfig("AutoFightTitle")
    local content = self._Control:GetClientConfig("AutoFightContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        self._Control:TwoSideTowerSweepPositiveStageRequest(self.CurSelectStageId, function()
            self:CancelSelect()
            self:Refresh()
        end)
    end)
end

return XUiTwoSideTowerStageDetail
