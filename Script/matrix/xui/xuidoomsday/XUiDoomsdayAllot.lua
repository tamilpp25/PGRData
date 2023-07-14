local XUiGridDoomsdayResourceAllot = require("XUi/XUiDoomsday/XUiGridDoomsdayResourceAllot")

--资源分配按钮组
local RESOURCE_ALLOCTION_SELECTION = {
    --给所有人分配食物
    [1] = {
        TYPE = XDoomsdayConfigs.RESOURCE_TYPE.FOOD,
        FUNC_NAME = XDoomsdayConfigs.RESOURCE_ALLOCTION_FUNC_NAME.ALL
    },
    --给一半的人分配食物
    [3] = {
        TYPE = XDoomsdayConfigs.RESOURCE_TYPE.FOOD,
        FUNC_NAME = XDoomsdayConfigs.RESOURCE_ALLOCTION_FUNC_NAME.HALF
    },
    --不分配食物
    [5] = {
        TYPE = XDoomsdayConfigs.RESOURCE_TYPE.FOOD,
        FUNC_NAME = XDoomsdayConfigs.RESOURCE_ALLOCTION_FUNC_NAME.NONE
    },
    --给所有人分配血清
    [2] = {
        TYPE = XDoomsdayConfigs.RESOURCE_TYPE.MEDICINE,
        FUNC_NAME = XDoomsdayConfigs.RESOURCE_ALLOCTION_FUNC_NAME.ALL
    },
    --给一半人分配血清
    [4] = {
        TYPE = XDoomsdayConfigs.RESOURCE_TYPE.MEDICINE,
        FUNC_NAME = XDoomsdayConfigs.RESOURCE_ALLOCTION_FUNC_NAME.HALF
    },
    --不分配血清
    [6] = {
        TYPE = XDoomsdayConfigs.RESOURCE_TYPE.MEDICINE,
        FUNC_NAME = XDoomsdayConfigs.RESOURCE_ALLOCTION_FUNC_NAME.NONE
    }
}

local XUiDoomsdayAllot = XLuaUiManager.Register(XLuaUi, "UiDoomsdayAllot")

function XUiDoomsdayAllot:OnAwake()
    self:AutoAddListener()
end

function XUiDoomsdayAllot:OnStart(stageId, closeCb)
    self.StageId = stageId
    self.CloseCb = closeCb

    self.SelectTypeDic = {} --已分配资源类型 -> 分配方式Index

    self:InitView()
end

function XUiDoomsdayAllot:InitView()
    self.TxtEvent.text = CsXTextManagerGetText("DoomsdayAllotTips")

    --资源分配方式选项按钮
    for index, selection in pairs(RESOURCE_ALLOCTION_SELECTION) do
        local resourceType = selection.TYPE
        local btn = self["BtnOption" .. index]

        btn:SetNameByGroup(0, XDoomsdayConfigs.ResourceAllotConfig:GetProperty(index, "Desc"))
        btn:SetNameByGroup(1, XDoomsdayConfigs.ResourceAllotConfig:GetProperty(index, "Tips"))

        btn:ShowTag(false)

        btn.CallBack = function()
            self:OnClickBtnOption(index, resourceType)
        end

        --初始化已选择表
        self.SelectTypeDic[resourceType] = self.SelectTypeDic[resourceType] or 0
    end
end

function XUiDoomsdayAllot:OnEnable()
    self:UpdateView()
end

function XUiDoomsdayAllot:UpdateView()
    local stageId = self.StageId
    local stageData = XDataCenter.DoomsdayManager.GetStageData(stageId)

    self.AllotResourceList = stageData:GetCanAllotResourceList()

    --居民数量
    self:BindViewModelPropertyToObj(
        stageData,
        function(count)
            self.TxtInhabitantCount.text = count
        end,
        "_InhabitantCount"
    )

    --分配方式
    for index, selection in pairs(RESOURCE_ALLOCTION_SELECTION) do
        local btn = self["BtnOption" .. index]

        local isSelect = index == self.SelectTypeDic[selection.TYPE]
        if isSelect then
            btn:SetButtonState(CS.UiButtonState.Select)
        else
            btn:SetButtonState(CS.UiButtonState.Normal)
        end
    end

    --资源数量
    self:RefreshTemplateGrids(
        {
            self.PanelTool1,
            self.PanelTool2
        },
        self.AllotResourceList,
        nil,
        XUiGridDoomsdayResourceAllot,
        "ResourceAllotGrids",
        function(grid, resource)
            grid:Refresh(resource)

            local resourceId = resource:GetProperty("_CfgId")
            local selection = self:GetResourceAllotSelect(resourceId)
            if selection then
                local allocatedCount = stageData[selection.FUNC_NAME](stageData, resourceId)
                grid:SetAllotCount(allocatedCount)
            end
        end
    )
end

function XUiDoomsdayAllot:AutoAddListener()
    self.BtnConfirm.CallBack = handler(self, self.OnClickBtnConfirm)
end

function XUiDoomsdayAllot:OnClickBtnConfirm()
    if not self:CheckAllotFinished() then
        XUiManager.TipText("DoomsdayAllotTipsNotFinish")
        return
    end

    local allocations = {}
    for _, resource in pairs(self.AllotResourceList) do
        local resourceId = resource:GetProperty("_CfgId")
        local selection = self:GetResourceAllotSelect(resourceId)
        if selection then
            table.insert(
                allocations,
                {
                    ResourceId = resourceId,
                    AllocationType = selection.FUNC_NAME
                }
            )
        end
    end

    XDataCenter.DoomsdayManager.DoomsdayOpResourceRequest(
        self.StageId,
        allocations,
        function()
            self:Close()
            self.CloseCb()
        end
    )
end

function XUiDoomsdayAllot:OnClickBtnOption(index, resourceType)
    self.SelectTypeDic[resourceType] = index

    self:UpdateView()
end

--检查是否所有资源类型都已经完成分配
function XUiDoomsdayAllot:CheckAllotFinished()
    for _, selectIndex in pairs(self.SelectTypeDic) do
        if not XTool.IsNumberValid(selectIndex) then
            return false
        end
    end
    return true
end

--获取指定资源类型已选择分配方式
function XUiDoomsdayAllot:GetResourceAllotSelect(resourceType)
    for index, selection in pairs(RESOURCE_ALLOCTION_SELECTION) do
        local selectIndex = self.SelectTypeDic[resourceType]
        if XTool.IsNumberValid(selectIndex) and selectIndex == index then
            return selection
        end
    end
end
