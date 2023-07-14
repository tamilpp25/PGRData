local XUiGridDoomsdayResource = require("XUi/XUiDoomsday/XUiGridDoomsdayResource")
local XUiGridDoomsdayResourceShow = require("XUi/XUiDoomsday/XUiGridDoomsdayResourceShow")
local XUiGridDoomsdayInhabitantAttr = require("XUi/XUiDoomsday/XUiGridDoomsdayInhabitantAttr")

local XUiDoomsdayFubenLineDetail = XLuaUiManager.Register(XLuaUi, "UiDoomsdayFubenLineDetail")

--UI层建筑表现状态
local WORK_STATE = {
    --待建造
    EMPTY = {
        NOT_SELECT_BUILDING = 1, --未选择建筑
        SELECT_BUILDING = 2 --已选择建筑
    },
    BUILDING = 3, --建造中
    WORKING = 4 --工作中/等待分配/工作打断
}

--确认按钮实际执行状态
XUiDoomsdayFubenLineDetail.CONFIRM_STATE = {
    CAN_BUILD = 1, --可建造
    BUILDING_INHABITANT_IN = 2, --建造中：请求撤下居民
    BUILDING_INHABITANT_OUT = 3 --等待中：请求分配居民
}

function XUiDoomsdayFubenLineDetail:OnAwake()
    self:AutoAddListener()
    self.PanelClean.gameObject:SetActiveEx(false)
end

function XUiDoomsdayFubenLineDetail:OnStart(stageId, buildingIndex, closeCb)
    self.StageId = stageId
    self.StageData = XDataCenter.DoomsdayManager.GetStageData(stageId)
    self.BuildingIndex = buildingIndex
    self.ExistedBuilding = self.StageData:GetBuilding(buildingIndex)
    self.CloseCb = closeCb

    self.WorkState = nil
    self.ConfirmState = nil
    self.SelectBuildingCfgId = self.ExistedBuilding:GetProperty("_CfgId")
    self.SelectInhabitantCount = self.ExistedBuilding:GetProperty("_WorkingInhabitantCount")
    self.NeedInhabitantCount = 0
    self.IdleCount = self.StageData:GetProperty("_IdleInhabitantCount")
    self.IsReplace = false
end

function XUiDoomsdayFubenLineDetail:OnEnable()
    self:UpdateView()
end

function XUiDoomsdayFubenLineDetail:AutoAddListener()
    self.BtnClose.CallBack = handler(self, self.OnClickBtnClose)
    self.BtnEnter.CallBack = handler(self, self.OnClickBtnEnter)
    self.BtnRemove.CallBack = handler(self, self.OnClickBtnRemove)
    self.BtnOut.CallBack = handler(self, self.OnClickBtnOut)
    self.BtnIn.CallBack = handler(self, self.OnClickBtnIn)
    local selectBuildingFunc = handler(self, self.OnClickBtnSelectBuilding)
    self.BtnBuildSelect.CallBack = selectBuildingFunc
    self.BtnBuildSelect2.CallBack = selectBuildingFunc
end

function XUiDoomsdayFubenLineDetail:UpdateView()
    local stageId = self.StageId
    local buildingIndex = self.BuildingIndex
    local stageData = self.StageData
    local building = self.ExistedBuilding

    --居民信息
    self:BindViewModelPropertiesToObj(
        stageData,
        function(idleCount, count)
            self.TxtInhabitantCount.text = string.format("%d/%d", idleCount, count)
        end,
        "_IdleInhabitantCount",
        "_InhabitantCount"
    )

    --居民异常状态
    self:BindViewModelPropertyToObj(
        stageData,
        function(unhealthyInhabitantInfoList)
            --只显示不健康状态下的属性
            self:RefreshTemplateGrids(
                self.GridAttr,
                unhealthyInhabitantInfoList,
                self.PanelInhabitant,
                XUiGridDoomsdayInhabitantAttr,
                "InhabitantAttrGrids"
            )
        end,
        "_UnhealthyInhabitantInfoList"
    )

    --资源栏
    self:RefreshTemplateGrids(
        self.GridResource,
        XDoomsdayConfigs.GetResourceIds(true),
        self.PanelResource,
        function()
            return XUiGridDoomsdayResource.New(stageId)
        end,
        "ResourceGrids"
    )

    --建筑状态
    self:BindViewModelPropertyToObj(building, handler(self, self.UpdateBuildingState), "_State")
end

--建筑状态机（数据层状态 -> UI状态）
function XUiDoomsdayFubenLineDetail:UpdateBuildingState(state)
    self.PanelBuildNotselected.gameObject:SetActiveEx(false)
    self.PanelBuild.gameObject:SetActiveEx(false)
    self.PanelClean.gameObject:SetActiveEx(false)
    self.PanelWorking.gameObject:SetActiveEx(false)
    self.PanelPeople.gameObject:SetActiveEx(false)

    self.BtnRemove.gameObject:SetActiveEx(false)
    self.BtnEnter:SetDisable(true, false)

    local buildingIndex = self.BuildingIndex
    local stageData = self.StageData
    if state == XDoomsdayConfigs.BUILDING_STATE.EMPTY then
        self:UpdateBuildingStateEmpty() --待建造
    elseif state == XDoomsdayConfigs.BUILDING_STATE.WORKING then
        if stageData:IsBuildingBuilding(buildingIndex) then
            self:UpdateBuildingStateBuilding() --建造中
        else
            self:UpdateBuildingStateWorking() --工作中
        end
    elseif state == XDoomsdayConfigs.BUILDING_STATE.PENDING then
        if stageData:IsBuildingBuildPending(buildingIndex) then
            self:UpdateBuildingStateBuilding() --建造中断
        else
            self:UpdateBuildingStateWorking() --工作中断
        end
    else
        self:UpdateBuildingStateWorking() --待分配工作
    end
end

--待建造
function XUiDoomsdayFubenLineDetail:UpdateBuildingStateEmpty()
    self.TxtTitle.text = CsXTextManagerGetText("DoomsdayFubenDetailBuildingEmptyTitle")
    self.TxtDescribe.text =
        XUiHelper.ConvertLineBreakSymbol(CsXTextManagerGetText("DoomsdayFubenDetailBuildingEmptyContent"))

    if not self:CheckSelectedBuilding() then
        --未选择建筑
        self.WorkState = WORK_STATE.EMPTY.NOT_SELECT_BUILDING

        self.PanelBuildNotselected.gameObject:SetActiveEx(true)

        self.TxtTips.text = CsXTextManagerGetText("DoomsdayFubenDetailTipsSelectBuilding")
    else
        --已选择建筑
        self.WorkState = WORK_STATE.EMPTY.SELECT_BUILDING

        local buildingCfgId = self.SelectBuildingCfgId

        --建筑名称
        self.TxtBuildName.text = XDoomsdayConfigs.BuildingConfig:GetProperty(buildingCfgId, "Name")

        --建造消耗资源
        self:RefreshTemplateGrids(
            {
                self.PanelUseTool1,
                self.PanelUseTool2
            },
            XDoomsdayConfigs.GetBuildingConstructResourceInfos(buildingCfgId),
            nil,
            XUiGridDoomsdayResourceShow,
            "ConstructResourceGrids"
        )

        self.PanelBuild.gameObject:SetActiveEx(true)
    end

    --工作安排
    self:UpdateInhabitantPanel()
end

--建造中
function XUiDoomsdayFubenLineDetail:UpdateBuildingStateBuilding()
    self.WorkState = WORK_STATE.BUILDING

    self.TxtTitle.text = CsXTextManagerGetText("DoomsdayFubenDetailBuildingEmptyTitle")
    self.TxtDescribe.text =
        XUiHelper.ConvertLineBreakSymbol(CsXTextManagerGetText("DoomsdayFubenDetailBuildingEmptyContent"))

    local buildingCfgId = self.ExistedBuilding:GetProperty("_CfgId")

    --建筑名称
    self.TxtBuildName.text = XDoomsdayConfigs.BuildingConfig:GetProperty(buildingCfgId, "Name")

    --建造消耗资源
    self:RefreshTemplateGrids(
        {
            self.PanelUseTool1,
            self.PanelUseTool2
        },
        XDoomsdayConfigs.GetBuildingConstructResourceInfos(buildingCfgId),
        nil,
        XUiGridDoomsdayResourceShow,
        "ConstructResourceGrids"
    )

    --除废墟类型外显示移除按钮
    if not XDoomsdayConfigs.IsBuildingRuins(buildingCfgId) then
        self.BtnRemove.gameObject:SetActiveEx(true)
    end

    self.PanelBuild.gameObject:SetActiveEx(true)

    --工作安排
    self:UpdateInhabitantPanel()
end

--工作中/等待分配/工作打断
function XUiDoomsdayFubenLineDetail:UpdateBuildingStateWorking()
    self.WorkState = WORK_STATE.WORKING

    local buildingCfgId = self.ExistedBuilding:GetProperty("_CfgId")
    self.TxtTitle.text = XDoomsdayConfigs.BuildingConfig:GetProperty(buildingCfgId, "Name")
    self.TxtDescribe.text = XDoomsdayConfigs.BuildingConfig:GetProperty(buildingCfgId, "Desc")

    --除废墟类型外显示移除按钮
    if not XDoomsdayConfigs.IsBuildingRuins(buildingCfgId) then
        self.BtnRemove.gameObject:SetActiveEx(true)
    end

    if XDoomsdayConfigs.IsBuildingInOperable(buildingCfgId) then
        --不可操作类型

        --除废墟类型外显示移除按钮
        if not XDoomsdayConfigs.IsBuildingRuins(buildingCfgId) then
            self.BtnRemove.gameObject:SetActiveEx(true)
        end
    else
        --可操作类型

        --工作安排
        self:UpdateInhabitantPanel()
    end
end

--分配居民
function XUiDoomsdayFubenLineDetail:UpdateInhabitantPanel(ignoreBtn)
    self.BtnIn.gameObject:SetActiveEx(false)
    self.BtnOut.gameObject:SetActiveEx(false)

    local stageData = self.StageData
    local buildingCfgId = self.SelectBuildingCfgId
    local curCount, needCount = self.SelectInhabitantCount, 0
    local idleCount = stageData:GetProperty("_IdleInhabitantCount")

    local showBtn
    if self.WorkState == WORK_STATE.EMPTY.NOT_SELECT_BUILDING then
        --待建造：未选择建筑
        curCount = 0
        showBtn = self.BtnIn
    elseif self.WorkState == WORK_STATE.EMPTY.SELECT_BUILDING then
        --待建造：已选择建筑
        needCount = XDoomsdayConfigs.BuildingConfig:GetProperty(buildingCfgId, "LockPeopleOnBuilding")

        if curCount < needCount then
            --人手不足
            self.TxtTips.text = CsXTextManagerGetText("DoomsdayFubenDetailTipsLackInhabitantToBuild")
            showBtn = self.BtnIn
        else
            --可建造
            self.TxtTips.text =
                CsXTextManagerGetText(
                "DoomsdayFubenDetailTipsBuildDay",
                XDoomsdayConfigs.BuildingConfig:GetProperty(buildingCfgId, "FinishDayCount")
            )

            showBtn = self.BtnOut
        end
    elseif self.WorkState == WORK_STATE.BUILDING then
        --建造中
        needCount = XDoomsdayConfigs.BuildingConfig:GetProperty(buildingCfgId, "LockPeopleOnBuilding")
        if curCount < needCount then
            --人手不足
            self.TxtTips.text = CsXTextManagerGetText("DoomsdayFubenDetailTipsLackInhabitantToBuild")
            if curCount > 0 then
                showBtn = self.BtnOut
            else
                showBtn = self.BtnIn
            end
        else
            --人手充足
            self.TxtTips.text =
                CsXTextManagerGetText(
                "DoomsdayFubenDetailTipsBuildLeftDay",
                XDoomsdayConfigs.BuildingConfig:GetProperty(buildingCfgId, "FinishDayCount") -
                    self.ExistedBuilding:GetProperty("_ProgressDay")
            )
            showBtn = self.BtnOut
        end
    else
        --工作中/等待工作/工作打断
        needCount = XDoomsdayConfigs.BuildingConfig:GetProperty(buildingCfgId, "LockPeopleOnWorking")

        if curCount < needCount then
            --人手不足
            self.TxtTips.text = CsXTextManagerGetText("DoomsdayFubenDetailTipsLackInhabitantToWork")
            if curCount > 0 then
                showBtn = self.BtnOut
            else
                showBtn = self.BtnIn
            end
        else
            --人手充足
            if XDoomsdayConfigs.IsBuildingRuins(buildingCfgId) then
                --废墟清理时间
                self.TxtTips.text =
                    CsXTextManagerGetText(
                    "DoomsdayFubenDetailTipsWorkDayRuins",
                    XDoomsdayConfigs.BuildingConfig:GetProperty(buildingCfgId, "WorkDayCount") -
                        self.ExistedBuilding:GetProperty("_ProgressDay")
                )
            else
                --工作时间不显示
                self.TxtTips.gameObject:SetActiveEx(false)
            end

            showBtn = self.BtnOut
        end

        self.NeedInhabitantCount = needCount

        --工作每日转换资源
        self:UpdateBuildingWorkingResourcePanel()
    end

    self.ImgProgressInhabitant.fillAmount = XUiHelper.GetFillAmountValue(curCount, needCount)
    if curCount < needCount then
        self.TxtInhabitantNeed.text =
            CsXTextManagerGetText("DoomsdayFubenDetailBuildingInhabitantCountLack", curCount, needCount)
    else
        self.TxtInhabitantNeed.text =
            CsXTextManagerGetText("DoomsdayFubenDetailBuildingInhabitantCount", curCount, needCount)
    end

    self.NeedInhabitantCount = needCount

    if not ignoreBtn then
        showBtn.gameObject:SetActiveEx(true)
    end

    self.PanelPeople.gameObject:SetActiveEx(true)
end

function XUiDoomsdayFubenLineDetail:UpdateCanOperateInhabitant()
    self.TxtInhabitantCount.text =
        string.format("%d/%d", self.IdleCount, self.StageData:GetProperty("_InhabitantCount"))
end

--工作每日转换资源
function XUiDoomsdayFubenLineDetail:UpdateBuildingWorkingResourcePanel()
    self.PanelWork1.gameObject:SetActiveEx(false)
    self.PanelWork2In1.gameObject:SetActiveEx(false)
    self.PanelWork1In1.gameObject:SetActiveEx(false)

    local buildingCfgId = self.ExistedBuilding:GetProperty("_CfgId")
    local consumeResourceInfos = XDoomsdayConfigs.GetBuildingDailyConsumeResourceInfos(buildingCfgId) --消耗
    local gainResourceInfos = XDoomsdayConfigs.GetBuildingDailyGainResourceInfos(buildingCfgId) --获得

    if not self:CheckSelectedInhabitantFull() then
        --居民不足时数量全部显示为0
        for _, info in pairs(consumeResourceInfos) do
            info.Count = 0
        end
        for _, info in pairs(gainResourceInfos) do
            info.Count = 0
        end
    end

    local consumeCount = #consumeResourceInfos --消耗物品种类
    if consumeCount == 0 then
        self:RefreshTemplateGrids(
            {
                self.GridGain1
            },
            gainResourceInfos,
            nil,
            XUiGridDoomsdayResourceShow,
            "WorkingGainResourceGrids1"
        )

        self.PanelWork1.gameObject:SetActiveEx(true)
    elseif consumeCount == 1 then
        self:RefreshTemplateGrids(
            {
                self.PanelWorkTool3
            },
            consumeResourceInfos,
            nil,
            XUiGridDoomsdayResourceShow,
            "WorkingConsumeResourceGrids2"
        )
        self:RefreshTemplateGrids(
            {
                self.GridGain3
            },
            gainResourceInfos,
            nil,
            XUiGridDoomsdayResourceShow,
            "WorkingGainResourceGrids2"
        )

        self.PanelWork1In1.gameObject:SetActiveEx(true)
    elseif consumeCount == 2 then
        self:RefreshTemplateGrids(
            {
                self.PanelWorkTool1,
                self.PanelWorkTool2
            },
            consumeResourceInfos,
            nil,
            XUiGridDoomsdayResourceShow,
            "WorkingConsumeResourceGrids3"
        )
        self:RefreshTemplateGrids(
            {
                self.GridGain2
            },
            gainResourceInfos,
            nil,
            XUiGridDoomsdayResourceShow,
            "WorkingGainResourceGrids3"
        )

        self.PanelWork2In1.gameObject:SetActiveEx(true)
    end

    if #gainResourceInfos == 0 then
        self.GridGain1.gameObject:SetActiveEx(false)
        self.GridGain2.gameObject:SetActiveEx(false)
        self.GridGain3.gameObject:SetActiveEx(false)
    end

    self:RefreshTemplateGrids(
        {
            self.PanelUseTool1,
            self.PanelUseTool2
        },
        XDoomsdayConfigs.GetBuildingConstructResourceInfos(buildingCfgId),
        nil,
        XUiGridDoomsdayResourceShow,
        "WorkingConsumeResourceGrids"
    )

    self.PanelWorking.gameObject:SetActiveEx(true)
end

--更新确认按钮实际工作状态
function XUiDoomsdayFubenLineDetail:UpdateConfirmState(state)
    self.ConfirmState = state

    if self:CheckSelectedInhabitantCountChange() then
        self.BtnEnter:SetDisable(false, true)
    else
        self.BtnEnter:SetDisable(true, false)
    end
end

function XUiDoomsdayFubenLineDetail:OnClickBtnClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiDoomsdayFubenLineDetail:OnClickBtnEnter()
    local isReplace = self.IsReplace
    if self.WorkState == WORK_STATE.EMPTY.SELECT_BUILDING then
        XDataCenter.DoomsdayManager.DoomsdayAddBuildingRequest(
            self.StageData:GetProperty("_Id"),
            self.BuildingIndex,
            self.SelectBuildingCfgId,
            self.SelectInhabitantCount,
            isReplace,
            function()
                self.SelectInhabitantCount = self.ExistedBuilding:GetProperty("_WorkingInhabitantCount")
                self:UpdateCanOperateInhabitant()
                self.BtnEnter:SetDisable(true, false)
                self.IsReplace = false
            end
        )
    else
        if self.ConfirmState == XUiDoomsdayFubenLineDetail.CONFIRM_STATE.BUILDING_INHABITANT_IN then
            XDataCenter.DoomsdayManager.DoomsdayOpPeopleRequest(
                self.StageData:GetProperty("_Id"),
                self.BuildingIndex,
                self.SelectInhabitantCount,
                isReplace,
                function()
                    self.SelectInhabitantCount = self.ExistedBuilding:GetProperty("_WorkingInhabitantCount")
                    self:UpdateCanOperateInhabitant()
                    self.BtnEnter:SetDisable(true, false)
                    self.IsReplace = false
                end
            )
        elseif self.ConfirmState == XUiDoomsdayFubenLineDetail.CONFIRM_STATE.BUILDING_INHABITANT_OUT then
            XDataCenter.DoomsdayManager.ZeroDoomsdayOpPeopleRequest(
                self.StageData:GetProperty("_Id"),
                self.BuildingIndex,
                function()
                    self.SelectInhabitantCount = self.ExistedBuilding:GetProperty("_WorkingInhabitantCount")
                    self:UpdateCanOperateInhabitant()
                    self.BtnEnter:SetDisable(true, false)
                    self.IsReplace = false
                end
            )
        end
    end
end

function XUiDoomsdayFubenLineDetail:OnClickBtnRemove()
    local callFunc = function()
        XDataCenter.DoomsdayManager.DoomsdayRemoveBuildingRequest(
            self.StageData:GetProperty("_Id"),
            self.BuildingIndex,
            function()
                self:Close()
            end
        )
    end

    local title = CsXTextManagerGetText("DoomsdayRemoveBuildingConfirmTitle")
    local content = CsXTextManagerGetText("DoomsdayRemoveBuildingConfirmContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
end

function XUiDoomsdayFubenLineDetail:OnClickBtnOut()
    self.IdleCount = self.IdleCount + self.SelectInhabitantCount
    self.SelectInhabitantCount = 0
    self.IsReplace = true

    self:UpdateInhabitantPanel(true)
    self:UpdateCanOperateInhabitant()
    self.BtnIn.gameObject:SetActiveEx(true)

    self:UpdateConfirmState(XUiDoomsdayFubenLineDetail.CONFIRM_STATE.BUILDING_INHABITANT_OUT)
end

function XUiDoomsdayFubenLineDetail:OnClickBtnIn()
    if self.WorkState == WORK_STATE.EMPTY.NOT_SELECT_BUILDING then
        XUiManager.TipText("DoomsdayFubenDetailTipsSelectBuilding")
        return
    end

    if self:CheckSelectedInhabitantFull() then
        return
    end

    local needAllotCount = self.NeedInhabitantCount - self.SelectInhabitantCount
    if self.IdleCount > needAllotCount then
        self.IdleCount = self.IdleCount - needAllotCount
        self.SelectInhabitantCount = self.SelectInhabitantCount + needAllotCount
    else
        self.SelectInhabitantCount = self.SelectInhabitantCount + self.IdleCount
        self.IdleCount = 0
    end

    self:UpdateCanOperateInhabitant()
    self:UpdateInhabitantPanel(true)
    self.BtnOut.gameObject:SetActiveEx(true)

    self:UpdateConfirmState(XUiDoomsdayFubenLineDetail.CONFIRM_STATE.BUILDING_INHABITANT_IN)
end

function XUiDoomsdayFubenLineDetail:OnClickBtnSelectBuilding()
    if self.WorkState ~= WORK_STATE.EMPTY.NOT_SELECT_BUILDING then
        return
    end

    local closeCb = function(buildingCfgId)
        self.SelectBuildingCfgId = buildingCfgId
        self:UpdateBuildingState(XDoomsdayConfigs.BUILDING_STATE.EMPTY)
    end

    XLuaUiManager.Open("UiDoomsdayBuild", self.StageId, closeCb)
end

--是否选择了建筑
function XUiDoomsdayFubenLineDetail:CheckSelectedBuilding()
    if not XTool.IsNumberValid(self.SelectBuildingCfgId) then
        return false
    end
    return self.SelectBuildingCfgId ~= self.ExistedBuilding:GetProperty("_CfgId")
end

--居民是否充足
function XUiDoomsdayFubenLineDetail:CheckSelectedInhabitantFull()
    if not XTool.IsNumberValid(self.SelectInhabitantCount) then
        return false
    end

    return self.SelectInhabitantCount == self.NeedInhabitantCount
end

--是否修改了居民数量
function XUiDoomsdayFubenLineDetail:CheckSelectedInhabitantCountChange()
    return self.SelectInhabitantCount ~= self.ExistedBuilding:GetProperty("_WorkingInhabitantCount")
end

return XUiDoomsdayFubenLineDetail
