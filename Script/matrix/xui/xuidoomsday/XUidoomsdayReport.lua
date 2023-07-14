local XUidoomsdayReport = XLuaUiManager.Register(XLuaUi, "UidoomsdayReport")

function XUidoomsdayReport:OnAwake()
    self:AutoAddListener()
end

function XUidoomsdayReport:OnStart(stageId, closeCb)
    self.StageId = stageId
    self.StageData = XDataCenter.DoomsdayManager.GetStageData(stageId)
    self.CloseCb = closeCb

    self:InitView()
end

function XUidoomsdayReport:InitView()
    local stageId = self.StageId
    local stageData = self.StageData

    local cur = stageData:GetProperty("_Day")
    self.TxtRound.text =
        CsXTextManagerGetText("DoomsdayReportDay", stageData:GetProperty("_Day") - 1, stageData:GetProperty("_MaxDay"))

    local resourceIds = XDoomsdayConfigs.GetResourceIds()

    --资源变化
    self:RefreshTemplateGrids(
        self.PanelTool1,
        resourceIds,
        self.PanelAsset,
        nil,
        "ResourceGrids",
        function(grid, resourceId)
            grid.RImgTool:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Icon"))
            local addCount = stageData:GetTotalHistoryAddResourceCount(resourceId)
            grid.TxtTool.text =
                stageData:GetResource(resourceId):GetProperty("_Count") .. XDoomsdayConfigs.GetNumerText(addCount)
        end
    )

    --居民人数变化
    self.TxtInhabitant.text =
        stageData:GetProperty("_InhabitantCount") .. XDataCenter.DoomsdayManager.GetInhabitantDeadCountText(stageId)

    --各种异常状态下居民数量变化
    self:RefreshTemplateGrids(
        self.GridAttrBad,
        XDataCenter.DoomsdayManager.GetUnhealthyInhabitantChangeCountList(stageId),
        self.PanelAssetAttr,
        nil,
        "BadAttrGrids",
        function(grid, info)
            grid.RImgTool:SetRawImage(XDoomsdayConfigs.AttributeTypeConfig:GetProperty(info.AttrType, "BadIcon"))
            grid.TxtTool.text = info.Count .. XDoomsdayConfigs.GetNumerText(info.ChangeCount)
        end
    )

    --居民属性变化
    self:RefreshTemplateGrids(
        self.PanelState1,
        XDataCenter.DoomsdayManager.GetInhabitantAttrChangeList(stageId),
        self.PanelState,
        nil,
        "AttrGrids",
        function(grid, info)
            local attrType = info.AttrType
            grid.TxtState1.text = XDoomsdayConfigs.AttributeTypeConfig:GetProperty(attrType, "Name")
            local cur, max = info.Count, XDoomsdayConfigs.AttributeTypeConfig:GetProperty(attrType, "MaxValue")
            grid.TxtState1Num.text = string.format("%d/%d", cur, max) .. XDoomsdayConfigs.GetNumerText(info.ChangeCount)
            grid.ImgProgress.fillAmount = XUiHelper.GetFillAmountValue(cur, max)
        end
    )

    --资源报告
    self:RefreshTemplateGrids(
        self.TxtNews,
        XDataCenter.DoomsdayManager.GenerateResourceReports(stageId),
        self.ContentNews,
        nil,
        "NewsGrids",
        function(grid, report)
            grid.TxtNews.text = report
        end
    )

    --居民报告
    self:RefreshTemplateGrids(
        self.TxtNewsInhabitant,
        XDataCenter.DoomsdayManager.GenerateInhabitantReports(stageId),
        self.ContentNewInhabitant,
        nil,
        "NewsInhabitantGrids",
        function(grid, report)
            grid.TxtNewsInhabitant.text = report
        end
    )
end

function XUidoomsdayReport:AutoAddListener()
    local closeFunc = handler(self, self.OnClickBtnClose)
    self.BtnClose.CallBack = closeFunc
    self.BtnEnter.CallBack = closeFunc
end

function XUidoomsdayReport:OnClickBtnClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end
