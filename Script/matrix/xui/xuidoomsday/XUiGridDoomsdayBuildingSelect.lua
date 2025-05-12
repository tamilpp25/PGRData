local MAX_COST_NUM = 2

local XUiGridDoomsdayBuildingSelect = XClass(nil, "XUiGridDoomsdayBuildingSelect")

function XUiGridDoomsdayBuildingSelect:Ctor(stageId, clickCb)
    self.StageId = stageId
    self.ClickCb = clickCb
end

function XUiGridDoomsdayBuildingSelect:Init()
    self.BtnEnvironment.CallBack = handler(self, self.OnClickBtnClick)
    self:SetSelect(false)
    self.TxtUnlock = self.Disable.transform:Find("TxtUnlock")
    self.TxtUnlock.gameObject:SetActiveEx(false)
end

function XUiGridDoomsdayBuildingSelect:Refresh(cfgId)
    self.BuildingCfgId = cfgId
    local stageData = XDataCenter.DoomsdayManager.GetStageData(self.StageId)

    self.TxtName.text = XDoomsdayConfigs.BuildingConfig:GetProperty(cfgId, "Name")
    self.TxtDescripe.text = XDoomsdayConfigs.BuildingConfig:GetProperty(cfgId, "Desc")

    --建造上限 可建造：2/8
    local cur, limit =
        stageData:GetSameTypeBuildingCount(cfgId),
        XDoomsdayConfigs.BuildingConfig:GetProperty(cfgId, "MaxNum")
    if XTool.IsNumberValid(limit) then
        self.TxtQuantity.text = CsXTextManagerGetText("DoomsdayBuildingCountLimit", cur, limit)
        self.TxtQuantity.gameObject:SetActiveEx(true)
    else
        self.TxtQuantity.gameObject:SetActiveEx(false)
    end
    local conditionId = XDoomsdayConfigs.BuildingConfig:GetProperty(cfgId, "UnlockCondition")
    local passCondition, desc
    if XTool.IsNumberValid(conditionId) then
        passCondition, desc = XDoomsdayConfigs.CheckCondition(conditionId, self.StageId)
    else
        passCondition, desc = true, ""
    end
    local reachLimit = XTool.IsNumberValid(limit) and cur >= limit
    local isLock = reachLimit or not passCondition
    self.BtnEnvironment:SetDisable(isLock, not isLock)
    if reachLimit then
        self.TxtDisable.text = XUiHelper.GetText("DoomsdayBuildReachLimit")
    elseif not passCondition then
        self.TxtDisable.text = desc
    end
    self.Disable.gameObject:SetActiveEx(isLock)
    self.ReachLimit = reachLimit

    --工期 工期：{0}天
    self.TxtSpendTime.text =
        CsXTextManagerGetText(
        "DoomsdayBuildingBuildDay",
        XDoomsdayConfigs.BuildingConfig:GetProperty(cfgId, "FinishDayCount"))
    

    local costResourceList = XDoomsdayConfigs.GetBuildingConstructResourceInfos(cfgId)
    for index, resourceInfo in pairs(costResourceList) do
        self["RImgTool" .. index]:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceInfo.Id, "Icon"))
        local cur, max = stageData:GetResource(resourceInfo.Id):GetProperty("_Count"), resourceInfo.Count
        self["TxtTool" .. index].supportRichText = true
        self["TxtTool" .. index].text = XDoomsdayConfigs.GetRequireNumerText(cur, max)
        self["PanelTool" .. index].gameObject:SetActiveEx(true)
    end
    for index = #costResourceList + 1, MAX_COST_NUM do
        self["PanelTool" .. index].gameObject:SetActiveEx(false)
    end
end

function XUiGridDoomsdayBuildingSelect:SetSelect(value)
    self.Select.gameObject:SetActiveEx(value)
end

function XUiGridDoomsdayBuildingSelect:OnClickBtnClick()
    self.ClickCb(self.BuildingCfgId)
end

return XUiGridDoomsdayBuildingSelect
