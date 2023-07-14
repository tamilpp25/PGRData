local XUiWorldBossMain = XLuaUiManager.Register(XLuaUi, "UiWorldBossMain")
local XUiGridBtnAttributeArea = require("XUi/XUiWorldBoss/XUiGridBtnAttributeArea")
local XUiGridBtnBossArea = require("XUi/XUiWorldBoss/XUiGridBtnBossArea")

local CSTextManagerGetText = CS.XTextManager.GetText
local SERVERDATAGETTIME = 30

function XUiWorldBossMain:OnStart()
    self:InitArea()
    self:InitAttributeArea()
    self:InitBossArea()
    self:SetButtonCallBack()

    self.UpdateTimer = XScheduleManager.ScheduleForever(function()
            XDataCenter.WorldBossManager.GetWorldBossGlobalData()
            XDataCenter.WorldBossManager.GetWorldBossReport()
        end, XScheduleManager.SECOND * SERVERDATAGETTIME, 0)
end

function XUiWorldBossMain:OnDestroy()
    if self.UpdateTimer then
        XScheduleManager.UnSchedule(self.UpdateTimer)
    end
end

function XUiWorldBossMain:OnEnable()
    XDataCenter.WorldBossManager.CheckWorldBossActivityReset()
    self:UpdateArea()
    self:UpdatePanelChat()
    XEventManager.AddEventListener(XEventId.EVENT_WORLDBOSS_SYNCDATA, self.UpdateArea, self)
    XEventManager.AddEventListener(XEventId.EVENT_WORLDBOSS_REPORT, self.UpdatePanelChat, self)
end

function XUiWorldBossMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_WORLDBOSS_SYNCDATA, self.UpdateArea, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_WORLDBOSS_REPORT, self.UpdatePanelChat, self)
end

function XUiWorldBossMain:InitArea()
    self.AttributeAreaObjList = {
        self.AreaEntrance:GetObject("Area01"),
        self.AreaEntrance:GetObject("Area02"),
        self.AreaEntrance:GetObject("Area03"),
        self.AreaEntrance:GetObject("Area04"),
        self.AreaEntrance:GetObject("Area05"),
    }

    self.BossAreaObjList = {
        self.BossEntrance:GetObject("BossArea01"),
    }
end

function XUiWorldBossMain:InitAttributeArea()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    if not worldBossActivity then
        return
    end
    local attributeAreaDic = worldBossActivity:GetAttributeAreaEntityDic()
    self.GridAttributeAreaDic = {}
    local gridIndex = 1

    for key,_ in pairs(attributeAreaDic) do
        local attributeAreaObj = self.AttributeAreaObjList[gridIndex]
        if attributeAreaObj then
            local grid = XUiGridBtnAttributeArea.New(attributeAreaObj)
            self.GridAttributeAreaDic[key] = grid
        end
        gridIndex = gridIndex + 1
    end

    local storyId = worldBossActivity:GetStartStoryId()
    if storyId and #storyId > 1 then
        local IsCanPlay = XDataCenter.WorldBossManager.CheckIsNewStoryID(storyId)
        if IsCanPlay then
            XDataCenter.MovieManager.PlayMovie(storyId)--一次
            XDataCenter.WorldBossManager.MarkStoryID(storyId)
        end
    end
end

function XUiWorldBossMain:InitBossArea()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    if not worldBossActivity then
        return
    end
    local bossAreaDic = worldBossActivity:GetBossAreaEntityDic()
    self.GridBossAreaDic = {}
    local gridIndex = 1

    for key,_ in pairs(bossAreaDic) do
        local bossAreaObj = self.BossAreaObjList[gridIndex]
        if bossAreaObj then
            local grid = XUiGridBtnBossArea.New(bossAreaObj)
            self.GridBossAreaDic[key] = grid
        end
        gridIndex = gridIndex + 1
    end
end

function XUiWorldBossMain:SetButtonCallBack()
    self.PanelChat:GetObject("BtnWarReport").CallBack = function()
        self:OnBtnWarReportClick()
    end
    self.BtnTask.CallBack = function()
        self:OnBtnTaskClick()
    end
    self.BtnFashion.CallBack = function()
        self:OnBtnFashionClick()
    end
    self.BtnShop.CallBack = function()
        self:OnBtnShopClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "WorldBossHelp")
end

function XUiWorldBossMain:UpdateArea()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    if not worldBossActivity then
        return
    end
    local attributeAreaDic = worldBossActivity:GetAttributeAreaEntityDic()
    local bossAreaDic = worldBossActivity:GetBossAreaEntityDic()

    for key,areaEneity in pairs(attributeAreaDic) do
        self.GridAttributeAreaDic[key]:UpdateData(areaEneity)
    end
    for key,areaEneity in pairs(bossAreaDic) do
        self.GridBossAreaDic[key]:UpdateData(areaEneity)
    end

    self:SetActivityInfo()
end

function XUiWorldBossMain:SetActivityInfo()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    if not worldBossActivity then
        return
    end
    local nowTime = XTime.GetServerNowTimestamp()
    local actionPointId = worldBossActivity:GetActionPointId()
    local shopCurrencyId = worldBossActivity:GetShopCurrencyId()
    local specialSaleIds = worldBossActivity:GetSpecialSaleIds()
    local saleEntityDic = worldBossActivity:GetSpecialSaleEntityDic()
    local maxActionPointId = worldBossActivity:GetMaxActionPoint()

    local powerCount = XDataCenter.ItemManager.GetCount(actionPointId)
    local item = XUiGridCommon.New(self, self.PowerItemGrid)
    item:Refresh(actionPointId)
    self.PowerText.text = CSTextManagerGetText("WorldBossActionPoint")
    self.PowerNum.text = string.format("%d/%d",powerCount,maxActionPointId)

    local item = XUiGridCommon.New(self, self.MoneyItemGrid)
    item:Refresh(shopCurrencyId)
    local moneyCount = XDataCenter.ItemManager.GetCount(shopCurrencyId)
    self.MoneyNum.text = moneyCount

    local firstIndex = 1
    local saleId = specialSaleIds[firstIndex]
    local discountText = saleEntityDic[saleId]:GetMinDiscountText()
    self.DiscointText.text = discountText
    self.DiscointText.gameObject:SetActiveEx(#discountText > 0)
    
    self.TimeText.text = XUiHelper.GetTime(worldBossActivity:GetEndTime() - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    
    local IsHaveRed = XDataCenter.WorldBossManager.CheckAnyTaskFinished()
    self.BtnTask:ShowReddot(IsHaveRed)
end

function XUiWorldBossMain:UpdatePanelChat()
    local reportData = XDataCenter.WorldBossManager.GetWorldBossNewReport()
    if not reportData then
        return
    end
    local playerInfo = reportData.PlayerInfo
    local reportId = reportData.ReportId
    local reportCfg = XWorldBossConfigs.GetReportTemplatesById(reportId)
    local reportType = XDataCenter.WorldBossManager.GetFightReportTypeById(reportId)
    local IsSystemReport = reportType == XWorldBossConfigs.ReportType.System
    local nameText = ""
    local wordText = ""

    if IsSystemReport then
        nameText = CSTextManagerGetText("WorldBossReportName")
        wordText = reportCfg.Message
    else
        nameText = playerInfo.PlayerName
        local score = playerInfo.Score
        wordText = string.format(reportCfg.Message,nameText,score)
    end
    self.PanelChat:GetObject("TxtMessageLabel").gameObject:SetActiveEx(true)
    self.PanelChat:GetObject("TxtMessageContent").text =string.format("%s:%s", nameText, wordText)
end

function XUiWorldBossMain:OnBtnBackClick()
    self:Close()
end

function XUiWorldBossMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiWorldBossMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiWorldBossTask")
end

function XUiWorldBossMain:OnBtnFashionClick()
    XLuaUiManager.Open("UiWorldBossFashion")
end

function XUiWorldBossMain:OnBtnShopClick()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        XLuaUiManager.Open("UiShop", XShopManager.ShopType.WorldBoss)
    end
end

function XUiWorldBossMain:OnBtnWarReportClick()
    XLuaUiManager.Open("UiChatUiWorldBoss")
end