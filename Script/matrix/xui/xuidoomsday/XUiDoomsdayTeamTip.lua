local XUiDoomsdayTeamTip = XLuaUiManager.Register(XLuaUi, "UiDoomsdayTeamTip")

function XUiDoomsdayTeamTip:OnAwake()
    self:AutoAddListener()
end

function XUiDoomsdayTeamTip:OnStart(stageId, teamId)
    self.StageId = stageId
    self.StageData = XDataCenter.DoomsdayManager.GetStageData(stageId)
    self.TeamId = teamId
end

function XUiDoomsdayTeamTip:OnEnable()
    self:UpdateView()
end

function XUiDoomsdayTeamTip:UpdateView()
    local stageId = self.StageId
    local stageData = self.StageData
    local teamId = self.TeamId

    self.TxtTitle.text = CsXTextManagerGetText("DoomsdayTeamName", teamId)

    local team = stageData:GetTeam(teamId)
    if team:IsEmpty() then
        --组队
        self.TxtTips.text = CsXTextManagerGetText("DoomsdayTeamTipsCreate")
        self.TxtDesc.text = CsXTextManagerGetText("DoomsdayTeamDescCreate")

        --需求居民数量
        local cur, max =
            stageData:GetProperty("_IdleInhabitantCount"),
            XDoomsdayConfigs.CreatTeamConfig:GetProperty(teamId, "CostInhabitantCount")
        local showCur = cur < max and cur or max
        self.TxtInhabitantNum.text = string.format("%d/%d", showCur, max)
        self.ImgBar.fillAmount = XUiHelper.GetFillAmountValue(cur, max)
        self.LackInhabitant = cur < max

        local inhabitantCount = stageData:GetProperty("_InhabitantCount")
        self.EqualInhabitant = cur == inhabitantCount and cur == max

        --需求物资
        self:RefreshTemplateGrids(
            self.GridResource,
            XDoomsdayConfigs.GetCreateTeamCostResourceList(teamId),
            self.PanelContent,
            nil,
            "NeedResourceGrids",
            function(grid, info)
                local resourceId = info.ResourceId
                grid.RImgIcon:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Icon"))
                grid.TxtName.text = XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Name")

                local cur, max = stageData:GetResource(resourceId):GetProperty("_Count"), info.Count
                grid.TxtNum.text = XDoomsdayConfigs.GetRequireNumerText(cur, max)

                self.LackResource = cur < max
            end
        )

        self.BtnTcanBack:SetName(CsXTextManagerGetText("DoomsdayTeamBtnCreate"))
        local isDisable = self.LackResource or self.LackInhabitant or self.EqualInhabitant
        self.BtnTcanBack:SetDisable(isDisable)
        self.PanelInhabitant.gameObject:SetActiveEx(true)
    else
        --队伍信息
        self.TxtTips.text = CsXTextManagerGetText("DoomsdayTeamTips")
        self.TxtDesc.text = CsXTextManagerGetText("DoomsdayTeamDesc")

        --获得物资
        self:RefreshTemplateGrids(
            self.GridResource,
            team:GetCarryResourceList(),
            self.PanelContent,
            nil,
            "GainResourceGrids",
            function(grid, info)
                local resourceId = info.ResourceId
                if resourceId == XDoomsdayConfigs.SPECIAL_RESOURCE_TYPE_INHANBITANT then
                    grid.TxtName.text = CsXTextManagerGetText("DoomsdayInhabitantName")
                else
                    grid.RImgIcon:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Icon"))
                    grid.TxtName.text = XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Name")
                end
                grid.TxtNum.text = "X" .. info.Count
            end
        )

        local isInCamp = stageData:IsTeamInCamp(teamId)
        self.BtnTcanBack:SetName(CsXTextManagerGetText("DoomsdayTeamBtn"))
        self.BtnTcanBack:SetDisable(isInCamp, not isInCamp)
        self.PanelInhabitant.gameObject:SetActiveEx(false)
    end
end

function XUiDoomsdayTeamTip:AutoAddListener()
    local closeFunc = handler(self, self.Close)
    self.BtnTanchuangCloseBig.CallBack = closeFunc
    self.BtnTcanChancel.CallBack = closeFunc
    self.BtnTcanBack.CallBack = handler(self, self.OnClickBtnEnter)
end

function XUiDoomsdayTeamTip:OnClickBtnEnter()
    local stageId = self.StageId
    local teamId = self.TeamId
    local stageData = self.StageData
    local team = stageData:GetTeam(teamId)
    if team:IsEmpty() then
        if self.LackInhabitant then
            XUiManager.TipText("DoomsdayMakeTeamFailInhabitantLack")
            return
        end

        if self.EqualInhabitant then
            XUiManager.TipText("DoomsdayMakeTeamFailInhabitantEqual")
            return
        end

        if self.LackResource then
            XUiManager.TipText("DoomsdayMakeTeamFailRssLack")
            return
        end

        --确认组队
        XDataCenter.DoomsdayManager.DoomsdayCreateTeamRequest(
            stageId,
            teamId,
            function()
                XUiManager.TipText("DoomsdayMakeTeamSuc")
                self:Close()
            end
        )
    else
        if stageData:IsTeamBusy(teamId) then
            XUiManager.TipText("DoomsdayTeamBusy")
            return
        end

        if stageData:IsTeamInCamp(teamId) then
            return
        end

        --返回大本营
        local campPlaceId = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "FirstPlace")
        XDataCenter.DoomsdayManager.DoomsdayTargetPlaceRequest(
            stageId,
            teamId,
            campPlaceId,
            function()
                self:Close()
            end
        )
    end
end

return XUiDoomsdayTeamTip
