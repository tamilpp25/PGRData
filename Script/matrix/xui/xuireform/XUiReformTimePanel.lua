local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--######################## XUiReformTimeGrid ########################
local XUiReformTimeGrid = XClass(nil, "XUiReformTimeGrid")

function XUiReformTimeGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnReform, self.OnBtnReformClicked)
end

function XUiReformTimeGrid:SetData(baseStageId, evolvableStage, data)
    self.BaseStageId = baseStageId
    self.EvolvableStage = evolvableStage
    self.Data = data
    self.RImgIcon:SetRawImage(data:GetIcon())
    self.RImgText:SetRawImage(data:GetTextIcon())
    self.TxtDes.text = data:GetDes()
    self.TxtScore.text = data:GetScore()
    self.PanelSelect.gameObject:SetActiveEx(data:GetIsActive())
end

function XUiReformTimeGrid:OnBtnReformClicked()
    -- 检查取消激活后分数是否大于0
    if self.Data:GetIsActive() and self.EvolvableStage:GetChallengeScore() < self.Data:GetScore() then
        XUiManager.TipError(XUiHelper.GetText("ReformScoreLimitTip"))
        return
    end
    if not self.Data:GetIsActive() and not self.EvolvableStage:CheckStageTimeMaxCount() then
        XUiManager.TipError(XUiHelper.GetText("ReformMaxTimeCountTip"))
        return
    end
    local updateTimeId = 0
    if not self.Data:GetIsActive() then
        updateTimeId = self.Data:GetId()
    end
    XDataCenter.ReformActivityManager.StageTimeUpdateRequest(self.BaseStageId, self.EvolvableStage:GetDifficulty(), updateTimeId, self.Data:GetId())
end

--######################## XUiReformEnvironmentPanel ########################
local XUiReformTimePanel = XClass(nil, "XUiReformTimePanel")

function XUiReformTimePanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    -- XReformEvolvableStage
    self.EvolvableStage = nil
    -- XReformBaseStage
    self.BaseStage = nil
    -- 初始化动态列表
    self.GridTime.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTimeList)
    self.DynamicTable:SetProxy(XUiReformTimeGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridDic = nil
end

function XUiReformTimePanel:SetData(baseStage, evolableStage)
    self.GridDic = {}
    self.BaseStage = baseStage
    self.EvolvableStage = evolableStage
    -- 刷新动态列表
    self:RefreshDynamicTable()
    self.TxtTip.text = XUiHelper.GetText("ReformStageTimeTip")
end

function XUiReformTimePanel:RefreshEvolvableData(stageTimeId)
    local timeGroup = self.EvolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.StageTime)
    self.GridDic[stageTimeId]:SetData(self.BaseStage:GetId(), self.EvolvableStage, timeGroup:GetStageTimeById(stageTimeId))
end

--######################## 私有方法 ########################

function XUiReformTimePanel:RefreshDynamicTable()
    local stageTimeGroup = self.EvolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.StageTime)
    self.DynamicTable:SetDataSource(stageTimeGroup:GetStageTimes())
    self.DynamicTable:ReloadDataSync(1)
end

function XUiReformTimePanel:OnDynamicTableEvent(event, index, grid)
    if index <= 0 or index > #self.DynamicTable.DataSource then return end
    local stageTime = self.DynamicTable.DataSource[index]
    self.GridDic[stageTime:GetId()] = grid
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.BaseStage:GetId(), self.EvolvableStage, stageTime)
    end
end
return XUiReformTimePanel