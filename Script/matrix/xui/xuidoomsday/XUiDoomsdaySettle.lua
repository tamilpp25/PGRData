local XUiDoomsdaySettle = XLuaUiManager.Register(XLuaUi, "UiDoomsdaySettle")
local Text_Color = {
    Normal = XUiHelper.Hexcolor2Color("34AFF9FF"),
    Red = XUiHelper.Hexcolor2Color("EF1717FF"),
}

local Progress_Color = {
    Normal = XUiHelper.Hexcolor2Color("1873BEFF"),
    Red = XUiHelper.Hexcolor2Color("EF1717FF"),
}

function XUiDoomsdaySettle:OnAwake()
    self:AutoAddListener()
    self.ImgWinDi = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelTitle/ImgWinDi")
    self.ImgLostDi = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelTitle/ImgLostDi")
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
    --if isWin then
    --    self.TxtSettle.text = CsXTextManagerGetText("DoomsdayWin")
    --else
    --    self.TxtSettle.text = CsXTextManagerGetText("DoomsdayFail")
    --end
    --解决描述
    self.TxtSettle.text = XDoomsdayConfigs.StageEndingConfig:GetProperty(self.StageData:GetProperty("_FinishEndingId"), "Desc")
    --关卡名
    self.TxtChapterName.text = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "Name")
    --坚持天数
    self.TxtDay.text = CSXTextManagerGetText("DoomsDayDaysOfPersistence", self.StageData:GetProperty("_Day"))
    --幸存者数量
    local inhabitantCount = stageData:GetProperty("_InhabitantCount")
    self.TxtSurvival.text = inhabitantCount
    self.TxtSurvival.color = tonumber(inhabitantCount) == 0 and Text_Color.Red or Text_Color.Normal
    --死亡数
    local deathCount = stageData:GetProperty("_AccDeadInhabitantCount")
    self.TxtDeath.text = deathCount
    self.TxtDeath.color = deathCount == 0 and Text_Color.Normal or Text_Color.Red
    --主目标
    local mainTargetId = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "MainTaskId")
    --local passed = stageData:IsTargetFinished(mainTargetId)
    self.TxtTask.text = XDoomsdayConfigs.TargetConfig:GetProperty(mainTargetId, "Desc")
    self.TxtWin.gameObject:SetActiveEx(isWin)
    self.TxtLost.gameObject:SetActiveEx(not isWin)
    self.ImgWinDi.gameObject:SetActiveEx(isWin)
    self.ImgLostDi.gameObject:SetActiveEx(not isWin)
    
    ----次要目标
    --local subTargetIds = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "SubTaskId")
    --self:RefreshTemplateGrids(
    --    self.GridCondSub,
    --    subTargetIds,
    --    self.PanelAim1Content,
    --    nil,
    --    "SubTargetGrids",
    --    function(grid, subTargetId)
    --        local paseed = stageData:IsTargetFinished(subTargetId)
    --        grid.TxtDesc.text = XDoomsdayConfigs.TargetConfig:GetProperty(subTargetId, "Desc")
    --        grid.TxtSuccess.gameObject:SetActiveEx(paseed)
    --        grid.TxtFail.gameObject:SetActiveEx(not paseed)
    --    end
    --)

    --资源变化
    self:RefreshTemplateGrids(
            self.PanelTool,
            XDoomsdayConfigs.GetResourceIds(),
            self.PanelList,
            nil,
            "ResourceGrids",
            function(grid, resourceId)
                grid.RImgTu:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Icon"))
                local count = stageData:GetResource(resourceId):GetProperty("_Count")
                grid.TxtZuo.text = XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Name")  
                grid.TxtYou.text = count
                grid.TxtYou.color = tonumber(count) == 0 and Text_Color.Red or Text_Color.Normal
            end
    )

    --居民属性变化
    self:RefreshTemplateGrids(
            self.PanelAttribute,
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
                local color = attr:IsBad() and Progress_Color.Red or Progress_Color.Normal
                grid.ImgProgress.color = color
                grid.TxtState1Num.color = color
            end
    )

    --各种异常状态下居民数量变化
    --XDataCenter.DoomsdayManager.GetUnhealthyInhabitantChangeCountList(stageId)
    local list = self.StageData:GetProperty("_UnhealthyInhabitantInfoList") or {}
    local sortAttrType = {
        [XDoomsdayConfigs.ATTRUBUTE_TYPE.HEALTH] = 0,
        [XDoomsdayConfigs.ATTRUBUTE_TYPE.HUNGER] = 0,
        [XDoomsdayConfigs.ATTRUBUTE_TYPE.SAN] = 0,
        [XDoomsdayConfigs.HOMELESS_ATTR_TYPE] = 0,
    }
    for _, info in ipairs(list) do
        local attrType = info.AttrType
        sortAttrType[attrType] = info.Count
    end
    local unhealthyInhabitantInfoList = {}
    for type, count in pairs(sortAttrType) do
        table.insert(unhealthyInhabitantInfoList, {
            AttrType = type,
            Count = count
        })
    end
    self:RefreshTemplateGrids(
            self.PanelEmo,
            unhealthyInhabitantInfoList,
            self.PanelEmotion,
            nil,
            "BadAttrGrids",
            function(grid, info)
                grid.RImgTool:SetRawImage(XDoomsdayConfigs.AttributeTypeConfig:GetProperty(info.AttrType, "BadIcon"))
                grid.TxtTool.text = XDoomsdayConfigs.AttributeTypeConfig:GetProperty(info.AttrType, "BadName")
                local count = info.Count
                grid.TxtQuantity.text = count
                grid.TxtQuantity.color = tonumber(count) == 0 and Text_Color.Normal or Text_Color.Red
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
