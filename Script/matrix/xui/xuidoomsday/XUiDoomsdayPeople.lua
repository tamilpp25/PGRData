local XUiGridDoomsdayInhabitantAttr = require("XUi/XUiDoomsday/XUiGridDoomsdayInhabitantAttr")
local XUiGridDoomsdayInhaibitantAttrNormal = require("XUi/XUiDoomsday/XUiGridDoomsdayInhaibitantAttrNormal")

local XUiDoomsdayPeople = XLuaUiManager.Register(XLuaUi, "UiDoomsdayPeople")

function XUiDoomsdayPeople:OnAwake()
    self:AutoAddListener()
end

function XUiDoomsdayPeople:OnStart(stageId)
    self.StageId = stageId
end

function XUiDoomsdayPeople:OnEnable()
    local stageId = self.StageId
    local stageData = XDataCenter.DoomsdayManager.GetStageData(stageId)

    --居民信息
    self:BindViewModelPropertiesToObj(
        stageData,
        function(idleCount, count)
            self.TxtPeopleNum.text =
                string.format("%d/%d", idleCount, count) ..
                XDataCenter.DoomsdayManager.GetInhabitantDeadCountText(stageId)
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
                self.PanelTool6,
                unhealthyInhabitantInfoList,
                self.PanelList,
                function()
                    return XUiGridDoomsdayInhabitantAttr.New(true)
                end,
                "InhabitantAttrGrids"
            )
        end,
        "_UnhealthyInhabitantInfoList"
    )

    --居民属性
    self:RefreshTemplateGrids(
        self.GridAttr,
        stageData:GetProperty("_AverageInhabitantAttrList"),
        self.PanelState,
        function()
            return XUiGridDoomsdayInhaibitantAttrNormal.New(stageId)
        end,
        "InhabitantNormalAttrGrids"
    )
end

function XUiDoomsdayPeople:AutoAddListener()
    self.BtnClose.CallBack = handler(self, self.Close)
end
