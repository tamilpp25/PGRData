local CsXTextManager = CS.XTextManager

--######################## XUiReformEnvironmentGrid ########################
local XUiReformEnvironmentGrid = XClass(nil, "XUiReformEnvironmentGrid")

function XUiReformEnvironmentGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    -- XReformEvolvableStage
    self.EvolvableStage = nil
    self.BaseStageId = nil
    -- XReformEnvrionment
    self.Data = nil
end

function XUiReformEnvironmentGrid:SetData(baseStageId, evolvableStage, data)
    self.BaseStageId = baseStageId
    self.EvolvableStage = evolvableStage
    self.Data = data
    self.RImgIcon:SetRawImage(data:GetIcon())
    self.RImgText:SetRawImage(data:GetTextIcon())
    self.TxtDes.text = data:GetDes()
    self.TxtScore.text = data:GetScore()
    self.PanelSelect.gameObject:SetActiveEx(data:GetIsActive())
end

--######################## 私有方法 ########################

function XUiReformEnvironmentGrid:RegisterUiEvents()
    self.BtnReform.CallBack = function() self:OnBtnReformClicked() end
end

function XUiReformEnvironmentGrid:OnBtnReformClicked()
    -- 检查取消激活后分数是否大于0
    if self.Data:GetIsActive() and self.EvolvableStage:GetChallengeScore() < self.Data:GetScore() then
        XUiManager.TipError(CsXTextManager.GetText("ReformScoreLimitTip"))
        return
    end
    if not self.Data:GetIsActive() and not self.EvolvableStage:CheckEnvironmentMaxCount() then
        XUiManager.TipError(CsXTextManager.GetText("ReformMaxEnvCountTip"))
        return
    end
    local envIds = XTool.Clone(self.EvolvableStage:GetEnvIds())
    local selfId = self.Data:GetId()
    if self.Data:GetIsActive() then -- 取消激活
        XTool.TableRemove(envIds, selfId)
    else -- 激活
        table.insert(envIds, selfId)
    end
    XDataCenter.ReformActivityManager.EnvironmentUpdateRequest(self.BaseStageId, self.EvolvableStage:GetDifficulty(), envIds, self.Data:GetId())
end

--######################## XUiReformEnvironmentPanel ########################
local XUiReformEnvironmentPanel = XClass(nil, "XUiReformEnvironmentPanel")

function XUiReformEnvironmentPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    -- XReformEvolvableStage
    self.EvolvableStage = nil
    -- XReformBaseStage
    self.BaseStage = nil
    -- 初始化动态列表
    self.GirdScene.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSceneList)
    self.DynamicTable:SetProxy(XUiReformEnvironmentGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridDic = nil
end

-- baseStage : XReformBaseStage
-- evolableStage : XReformEvolvableStage
function XUiReformEnvironmentPanel:SetData(baseStage, evolableStage)
    self.GridDic = {}
    self.BaseStage = baseStage
    self.EvolvableStage = evolableStage
    -- 刷新动态列表
    self:RefreshDynamicTable()
    self:RefreshTopTips()
end

function XUiReformEnvironmentPanel:RefreshEvolvableData(envId)
    local environmentGroup = self.EvolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Environment)
    self.GridDic[envId]:SetData(self.BaseStage:GetId(), self.EvolvableStage, environmentGroup:GetEnvironmentById(envId))
    self:RefreshTopTips()
end

function XUiReformEnvironmentPanel:RefreshTopTips()
    local showColor = "#FF5F6C"
    local currentCount = #self.EvolvableStage:GetEnvIds()
    local maxCount = self.EvolvableStage:GetMaxEnvrionmentCount()
    if currentCount >= maxCount then
        showColor = "#000000"
    end
    self.TxtTip.text = CsXTextManager.GetText("ReformEnvPanelTopTip"
        , showColor, currentCount, maxCount)
end

--######################## 私有方法 ########################

function XUiReformEnvironmentPanel:RefreshDynamicTable(envId)
    local environmentGroup = self.EvolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Environment)
    self.DynamicTable:SetDataSource(environmentGroup:GetEnvironments())
    self.DynamicTable:ReloadDataSync(1)
end

function XUiReformEnvironmentPanel:OnDynamicTableEvent(event, index, grid)
    if index <= 0 or index > #self.DynamicTable.DataSource then return end
    local environmentGroup = self.EvolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Environment)
    local environment = self.DynamicTable.DataSource[index]
    self.GridDic[environment:GetId()] = grid
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.BaseStage:GetId(), self.EvolvableStage, environment)
    end
end

return XUiReformEnvironmentPanel