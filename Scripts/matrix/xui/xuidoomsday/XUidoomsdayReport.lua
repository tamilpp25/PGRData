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
    self.TxtRound.text = CsXTextManagerGetText("NewbieDayTab2", cur - 1)
        --CsXTextManagerGetText("DoomsdayReportDay", stageData:GetProperty("_Day") - 1, stageData:GetProperty("_MaxDay"))

    
    local time = XDoomsdayConfigs.DOOMSDAY_REPORT_ANIMA_TIME * 0.25
    local resourceChangeInfo = XDataCenter.DoomsdayManager.GetResourceChangeCountList(stageId)
    --资源变化
    self:RefreshTemplateGrids(
        self.PanelTool1,
        resourceChangeInfo,
        self.PanelAsset,
        nil,
        "ResourceGrids",
        function(grid, info)
            local resourceId = info.Id
            grid.RImgTool:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Icon"))
            local addCount = info.ChangeCount --stageData:GetTotalHistoryAddResourceCount(resourceId)
            local curCount = info.CurCount --stageData:GetResource(resourceId):GetProperty("_Count")
            local lastCount = info.LastCount --math.max(0, curCount - addCount)
            grid.TxtTool.text = lastCount .. XDoomsdayConfigs.GetNumberText(addCount, false, false, true)
            self:RefreshBtnState(false)
            XUiHelper.Tween(time, function(delta) 
                local count = math.ceil(addCount * delta)
                grid.TxtTool.text = lastCount + count .. XDoomsdayConfigs.GetNumberText(addCount,false, false, true)
            end, function()
                self:RefreshBtnState(true)
            end)
            
        end
    )

    --居民人数变化
    self.TxtInhabitant.text =
        stageData:GetProperty("_InhabitantCount") .. XDataCenter.DoomsdayManager.GetInhabitantCountChangeText(stageId)

    --各种异常状态下居民数量变化
    self:RefreshTemplateGrids(
        self.GridAttrBad,
        XDataCenter.DoomsdayManager.GetUnhealthyInhabitantChangeCountList(stageId),
        self.PanelAssetAttr,
        nil,
        "BadAttrGrids",
        function(grid, info)
            grid.RImgTool:SetRawImage(XDoomsdayConfigs.AttributeTypeConfig:GetProperty(info.AttrType, "BadIcon"))
            grid.TxtTool.text = info.Count .. XDoomsdayConfigs.GetNumberText(info.ChangeCount, true, false, true)
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
            local changeCount = info.ChangeCount
            local last = math.min(max, cur - changeCount)
            local first, second
            if changeCount > 0 then
                first, second = grid.ImgProgressAdd, grid.ImgProgress
            else
                first, second = grid.ImgProgress, grid.ImgProgressAdd
            end
            first.fillAmount =  XUiHelper.GetFillAmountValue(cur, max)
            grid.TxtState1Num.text = string.format("%d/%d", last, max) .. XDoomsdayConfigs.GetNumberText(changeCount, false, false, true)
            self:RefreshBtnState(false)
            XUiHelper.Tween(time, function(delta)
                local num = delta * changeCount
                grid.TxtState1Num.text = string.format("%d/%d", last + math.ceil(num), max) .. XDoomsdayConfigs.GetNumberText(changeCount, false, false, true)
                second.fillAmount = XUiHelper.GetFillAmountValue(last + num, max)
            end, function()
                self:RefreshBtnState(true)
            end)
            
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

function XUidoomsdayReport:RefreshBtnState(state)
    if self.BtnState == state then
        return
    end
    self.BtnState = state
    self.BtnClose.gameObject:SetActiveEx(state)
    self.BtnEnter.gameObject:SetActiveEx(state)
end

function XUidoomsdayReport:OnClickBtnClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end
