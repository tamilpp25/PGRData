local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local CsXTextManager = CS.XTextManager

--######################## XUiReformBuffGrid ########################
local XUiReformBuffGrid = XClass(nil, "XUiReformBuffGrid")

function XUiReformBuffGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    -- XReformEvolvableStage
    self.EvolvableStage = nil
    self.BaseStageId = nil
    -- XReformBuff
    self.Data = nil
end

function XUiReformBuffGrid:SetData(baseStageId, evolvableStage, data)
    self.BaseStageId = baseStageId
    self.EvolvableStage = evolvableStage
    self.Data = data
    self.RImgIcon:SetRawImage(data:GetIcon())
    self.TxtName.text = data:GetName()
    self.TxtLevel.text = data:GetStarLevel()
    self.TxtScore.text = data:GetScore()
    local isActive = data:GetIsActive()
    self.PanelSelect.gameObject:SetActiveEx(isActive)
    self.Tab1.gameObject:SetActiveEx(false)
    -- self.Tab2.gameObject:SetActiveEx(isActive)
    self.Tab2.gameObject:SetActiveEx(false)
end

-- evolvableStage : XReformEvolvableStage
function XUiReformBuffGrid:DynamicTouched()
    XLuaUiManager.Open("UiReformBuffDetail", {
        Name = self.Data:GetName(),
        Icon = self.Data:GetIcon(),
        StarCount = self.Data:GetStarLevel(),
        Description = self.Data:GetDes()
    })
end

--######################## 私有方法 ########################

function XUiReformBuffGrid:RegisterUiEvents()
    self.BtnReform.CallBack = function() self:OnBtnReformClicked() end
end

function XUiReformBuffGrid:OnBtnReformClicked()
    -- 检查是否满足扣减分数
    if not self.Data:GetIsActive() then
        if not self.EvolvableStage:CheckBuffMaxCount() then
            XUiManager.TipError(CsXTextManager.GetText("ReformMaxBuffCountTip"))
            return 
        end
        if self.Data:GetScore() > self.EvolvableStage:GetChallengeScore() then
            XUiManager.TipError(CsXTextManager.GetText("ReformScoreLimitTip"))
            return
        end
    end
    local buffIds = XTool.Clone(self.EvolvableStage:GetBuffIds())
    local selfBuffId = self.Data:GetId()
    if self.Data:GetIsActive() then -- 取消激活
        XTool.TableRemove(buffIds, selfBuffId)
    else -- 激活
        table.insert(buffIds, selfBuffId)
    end
    XDataCenter.ReformActivityManager.BuffUpdateRequest(self.BaseStageId, self.EvolvableStage:GetDifficulty(), buffIds, self.Data:GetId())
end

--######################## XUiReformBuffPanel ########################
local XUiReformBuffPanel = XClass(nil, "XUiReformBuffPanel")

function XUiReformBuffPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    -- XReformEvolvableStage
    self.EvolvableStage = nil
    -- XReformBaseStage
    self.BaseStage = nil
    -- 初始化动态列表
    self.GirdBuff.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBuffList)
    self.DynamicTable:SetProxy(XUiReformBuffGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridDic = nil
end

-- baseStage : XReformBaseStage
-- evolableStage : XReformEvolvableStage
function XUiReformBuffPanel:SetData(baseStage, evolableStage)
    self.GridDic = {}
    self.BaseStage = baseStage
    self.EvolvableStage = evolableStage
    -- 刷新动态列表
    self:RefreshDynamicTable()
    self.TxtTip.text = CsXTextManager.GetText("ReformBuffPanelTopTip", evolableStage:GetMaxBuffCount())
end

function XUiReformBuffPanel:RefreshEvolvableData(buffId)
    local buffGroup = self.EvolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Buff)
    self.GridDic[buffId]:SetData(self.BaseStage:GetId(), self.EvolvableStage, buffGroup:GetBuffById(buffId))
end

--######################## 私有方法 ########################

function XUiReformBuffPanel:RefreshDynamicTable()
    local buffGroup = self.EvolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Buff)
    self.DynamicTable:SetDataSource(buffGroup:GetBuffs())
    self.DynamicTable:ReloadDataSync(1)
end

function XUiReformBuffPanel:OnDynamicTableEvent(event, index, grid)
    if index <= 0 or index > #self.DynamicTable.DataSource then return end
    local buff = self.DynamicTable.DataSource[index]
    self.GridDic[buff:GetId()] = grid
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.BaseStage:GetId(), self.EvolvableStage, buff)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:DynamicTouched()
    end
end

return XUiReformBuffPanel