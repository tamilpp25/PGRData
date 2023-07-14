local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiStrongholdSupportTips = XLuaUiManager.Register(XLuaUi, "UiStrongholdSupportTips")

function XUiStrongholdSupportTips:OnAwake()
    self:AutoAddListener()

    self.GridCondition.gameObject:SetActiveEx(false)
    self.GridSupport.gameObject:SetActiveEx(false)
end

function XUiStrongholdSupportTips:OnStart(supportId, teamList)
    self.SupportId = supportId
    self.TeamList = teamList
    self.ConditionGrids = {}
    self.SupportGrids = {}
end

function XUiStrongholdSupportTips:OnEnable()
    self:UpdateView()
end

function XUiStrongholdSupportTips:UpdateView()
    local supportId = self.SupportId
    local teamList = self.TeamList

    --支援方案条件
    local conditionIds = XStrongholdConfigs.GetSupportConditionIds(supportId)
    for index, conditionId in ipairs(conditionIds) do
        local grid = self.ConditionGrids[index]
        if not grid then
            local ui = index == 1 and self.GridCondition or CSUnityEngineObjectInstantiate(self.GridCondition, self.SviewCondition)
            grid = XTool.InitUiObjectByUi({}, ui)
            self.ConditionGrids[index] = grid
        end

        local isActive, desc = XConditionManager.CheckCondition(conditionId, teamList)
        grid.TxtON.text = desc
        grid.TxtOFF.text = desc
        grid.PanelON.gameObject:SetActiveEx(isActive)
        grid.PanelOFF.gameObject:SetActiveEx(not isActive)

        grid.GameObject:SetActiveEx(true)
    end
    for index = #conditionIds + 1, #self.ConditionGrids do
        self.ConditionGrids[index].GameObject:SetActiveEx(false)
    end

    --支援方案BUFF
    local isActive = XDataCenter.StrongholdManager.CheckSupportActive(supportId, teamList)
    self.PanelOn.gameObject:SetActiveEx(isActive)
    self.PanelOff.gameObject:SetActiveEx(not isActive)

    local buffIds = XStrongholdConfigs.GetSupportBuffIds(supportId)
    for index, buffId in ipairs(buffIds) do
        local grid = self.SupportGrids[index]
        if not grid then
            local ui = index == 1 and self.GridSupport or CSUnityEngineObjectInstantiate(self.GridSupport, self.SviewSupport)
            grid = XTool.InitUiObjectByUi({}, ui)
            self.SupportGrids[index] = grid
        end

        local desc = XStrongholdConfigs.GetBuffDesc(buffId)
        grid.TxtON.text = desc
        grid.TxtOFF.text = desc
        grid.TxtON.gameObject:SetActiveEx(isActive)
        grid.TxtOFF.gameObject:SetActiveEx(not isActive)

        grid.GameObject:SetActiveEx(true)
    end
    for index = #buffIds + 1, #self.SupportGrids do
        self.SupportGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiStrongholdSupportTips:AutoAddListener()
    self.BtnTanchuangCloseBig.CallBack = function() self:OnClickBtnClose() end
end

function XUiStrongholdSupportTips:OnClickBtnClose()
    self:Close()
end