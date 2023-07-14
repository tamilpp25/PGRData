local XUiDoomsdaySettle = XLuaUiManager.Register(XLuaUi, "UiDoomsdaySettle")

function XUiDoomsdaySettle:OnAwake()
    self:AutoAddListener()
end

function XUiDoomsdaySettle:OnStart(stageId, closeCb)
    self.StageId = stageId
    self.StageData = XDataCenter.DoomsdayManager.GetStageData(stageId)
    self.CloseCb = closeCb

    self:InitView()
end

function XUiDoomsdaySettle:InitView()
    local stageId = self.StageId
    local stageData = self.StageData

    local isWin = stageData:IsWin()
    if isWin then
        self.TxtSettle.text = CsXTextManagerGetText("DoomsdayWin")
    else
        self.TxtSettle.text = CsXTextManagerGetText("DoomsdayFail")
    end

    self.TxtChapterName.text = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "Name")

    --主目标
    local mainTargetId = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "MainTaskId")
    self:RefreshTemplateGrids(
        self.GridCond,
        {mainTargetId},
        nil,
        nil,
        "MainTargetGrids",
        function(grid, mainTargetId)
            local paseed = stageData:IsTargetFinished(mainTargetId)
            grid.TxtDesc.text = XDoomsdayConfigs.TargetConfig:GetProperty(mainTargetId, "Desc")
            grid.TxtSuccess.gameObject:SetActiveEx(paseed)
            grid.TxtFail.gameObject:SetActiveEx(not paseed)
        end
    )

    --次要目标
    local subTargetIds = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "SubTaskId")
    self:RefreshTemplateGrids(
        self.GridCondSub,
        subTargetIds,
        self.PanelAim1Content,
        nil,
        "SubTargetGrids",
        function(grid, subTargetId)
            local paseed = stageData:IsTargetFinished(subTargetId)
            grid.TxtDesc.text = XDoomsdayConfigs.TargetConfig:GetProperty(subTargetId, "Desc")
            grid.TxtSuccess.gameObject:SetActiveEx(paseed)
            grid.TxtFail.gameObject:SetActiveEx(not paseed)
        end
    )

    --资源变化
    self:RefreshTemplateGrids(
        self.PanelTool1,
        XDoomsdayConfigs.GetResourceIds(),
        self["PanelAsset "], --fking space!!!
        nil,
        "ResourceGrids",
        function(grid, resourceId)
            grid.RImgTool1:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Icon"))
            local addCount = stageData:GetTotalHistoryAddResourceCount(resourceId)
            grid.TxtTool1.text = stageData:GetResource(resourceId):GetProperty("_Count")
        end
    )

    --居民人数变化
    self.TxtInhabitantNum.text = stageData:GetProperty("_InhabitantCount")

    --居民属性变化
    self:RefreshTemplateGrids(
        self.PanelState1,
        stageData:GetProperty("_AverageInhabitantAttrList"),
        self.PanelState,
        nil,
        "AttrGrids",
        function(grid, attr)
            local attrType = attr:GetProperty("_Type")
            grid.TxtState1.text = XDoomsdayConfigs.AttributeTypeConfig:GetProperty(attrType, "Name")
            local cur, max =
                attr:GetProperty("_Value"),
                XDoomsdayConfigs.AttributeTypeConfig:GetProperty(attrType, "MaxValue")
            grid.TxtState1Num.text = string.format("%d/%d", cur, max)
            grid.ImgProgress.fillAmount = XUiHelper.GetFillAmountValue(cur, max)
        end
    )

    --各种异常状态下居民数量变化
    self:RefreshTemplateGrids(
        self.PanelTool6,
        XDataCenter.DoomsdayManager.GetUnhealthyInhabitantChangeCountList(stageId),
        self.PanelBadAttr,
        nil,
        "BadAttrGrids",
        function(grid, info)
            grid.RImgTool6:SetRawImage(XDoomsdayConfigs.AttributeTypeConfig:GetProperty(info.AttrType, "BadIcon"))
            grid.TxtTool6.text = info.Count
        end
    )
end

function XUiDoomsdaySettle:AutoAddListener()
    self:RegisterClickEvent(self.BtnBlock, handler(self, self.OnClickBtnClose))
end

function XUiDoomsdaySettle:OnClickBtnClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end
