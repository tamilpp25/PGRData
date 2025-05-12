local XUiGridAttribute = require("XUi/XUiDorm/XUiDormCommom/XUiGridAttribute")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiWorldBossAttributeArea = XLuaUiManager.Register(XLuaUi, "UiWorldBossAttributeArea")
local XUiGridAttributeChapter = require("XUi/XUiWorldBoss/XUiGridAttributeChapter")
local XUiGridBuff = require("XUi/XUiWorldBoss/XUiGridBuff")
local CSTextManagerGetText = CS.XTextManager.GetText
local Normal = CS.UiButtonState.Normal
local Disable = CS.UiButtonState.Disable
function XUiWorldBossAttributeArea:OnStart(areaId)
    self.AreaId = areaId
    self:SetButtonCallBack()
    self:InitArea()
    self:InitPanelRegional()
    self:InitPanelRewrd()
    self:UpdatePanelRewrd()

    self.ChapterGrid:UpdateStageList()
    self.ChapterGrid:GoToNearestStage()
end

function XUiWorldBossAttributeArea:OnDestroy()

end

function XUiWorldBossAttributeArea:OnEnable()
    XDataCenter.WorldBossManager.CheckWorldBossActivityReset()
    self:UpdateArea()
    self:UpdatePanelChat()
    XEventManager.AddEventListener(XEventId.EVENT_WORLDBOSS_SYNCDATA, self.UpdateArea, self)
    XEventManager.AddEventListener(XEventId.EVENT_WORLDBOSS_REPORT, self.UpdatePanelChat, self)
end

function XUiWorldBossAttributeArea:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_WORLDBOSS_SYNCDATA, self.UpdateArea, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_WORLDBOSS_REPORT, self.UpdatePanelChat, self)
end

function XUiWorldBossAttributeArea:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end

    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end

    self.BtnRank.CallBack = function()
        self:OnBtnRankClick()
    end

    self.BtnTask.CallBack = function()
        self:OnBtnTaskClick()
    end

    self.PanelChat:GetObject("BtnWarReport").CallBack = function()
        self:OnBtnWarReportClick()
    end

    self.PanelRewrd:GetObject("BtnTreasure").CallBack = function()
        self:OnBtnTreasureClick()
    end

    self.PanelShop:GetObject("BtnShop").CallBack = function()
        self:OnBtnShopClick()
    end
    self:BindHelpBtn(self.BtnActDesc, "WorldBossHelp")
end

function XUiWorldBossAttributeArea:InitArea()
    local attributeArea = XDataCenter.WorldBossManager.GetAttributeAreaById(self.AreaId)
    local prefabName = attributeArea:GetPrefabName()
    local gameObject = self.PanelChapter:LoadPrefab(prefabName)
    if gameObject == nil or not gameObject:Exist() then
        return
    end

    self.ChapterGrid = XUiGridAttributeChapter.New(gameObject, self.AreaId)
    self.ChapterGrid.Transform:SetParent(self.PanelChapter, false)
end

function XUiWorldBossAttributeArea:UpdatePanelShop()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    local shopCurrencyId = worldBossActivity:GetShopCurrencyId()

    local moneyItem = XUiGridCommon.New(self, self.PanelShop:GetObject("MoneyItemGrid"))
    moneyItem:Refresh(shopCurrencyId)
    local moneyCount = XDataCenter.ItemManager.GetCount(shopCurrencyId)
    self.PanelShop:GetObject("MoneyNum").text = moneyCount
    self.PanelShop.gameObject:SetActiveEx(false)
end

function XUiWorldBossAttributeArea:InitPanelRegional()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    local attributeArea = XDataCenter.WorldBossManager.GetAttributeAreaById(self.AreaId)
    local nowTime = XTime.GetServerNowTimestamp()
    local activityTime = XUiHelper.GetTime(worldBossActivity:GetEndTime() - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    local buffParent = self.PanelRegional:GetObject("BuffContent")
    local buffObj = self.PanelRegional:GetObject("BtnBossBuff")
    local buffIds = attributeArea:GetBuffIds()

    self.PanelRegional:GetObject("TextTime").text = activityTime
    self.PanelRegional:GetObject("TxtTName").text = attributeArea:GetName()
    self.PanelRegional:GetObject("AreaDesc").text = attributeArea:GetAreaDesc()

    buffObj.gameObject:SetActiveEx(false)

    if buffIds then
        for _,id in pairs(buffIds) do
            local ui = CS.UnityEngine.Object.Instantiate(buffObj,buffParent)
            local grid = XUiGridBuff.New(ui,false)
            local buffData = XDataCenter.WorldBossManager.GetWorldBossBuffById(id)
            grid:UpdateData(buffData)
            grid.GameObject:SetActiveEx(true)
        end
    end
end

function XUiWorldBossAttributeArea:InitPanelRewrd()
    local attributeArea = XDataCenter.WorldBossManager.GetAttributeAreaById(self.AreaId)
    local rewrdParent = self.PanelRewrd:GetObject("PanelBfrtRewrds")
    local rewrdObj = self.PanelRewrd:GetObject("GridCommonPopUp")
    local rewrdId = attributeArea:GetFinishReward()
    local rewardList = XRewardManager.GetRewardList(rewrdId)
    rewrdObj.gameObject:SetActiveEx(false)

    if rewardList then
        for _,reward in pairs(rewardList) do
            local ui = CS.UnityEngine.Object.Instantiate(rewrdObj,rewrdParent)
            local grid = XUiGridCommon.New(self,ui)

            grid:Refresh(reward)
            grid.GameObject:SetActiveEx(true)
        end
    end
end

function XUiWorldBossAttributeArea:UpdatePanelRewrd()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    local attributeArea = XDataCenter.WorldBossManager.GetAttributeAreaById(self.AreaId)
    local IsCanGet = attributeArea:GetIsAreaFinish()
    local IsGeted = attributeArea:GetIsRewardGeted()
    local finishCount = attributeArea:GetFinishStageCount()
    local stageCount = #attributeArea:GetStageIds()

    self.PanelRewrd:GetObject("TxtCondition").text = CSTextManagerGetText("WorldBossAttributeStageRewrdHint", finishCount, stageCount)
    self.PanelRewrd:GetObject("TxtCondition").gameObject:SetActiveEx(not IsCanGet)
    self.PanelRewrd:GetObject("BtnTreasure").gameObject:SetActiveEx(IsCanGet)
    self.PanelRewrd:GetObject("BtnTreasure"):SetButtonState((not IsGeted and IsCanGet) and Normal or Disable)
end

function XUiWorldBossAttributeArea:UpdatePanelChat()
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

function XUiWorldBossAttributeArea:UpdateArea()
    self.ChapterGrid:UpdateStageList()
    self:UpdatePanelRewrd()
    self:UpdatePanelShop()
    self:SetActivityInfo()
end

function XUiWorldBossAttributeArea:SetActivityInfo()
    local IsHaveRed = XDataCenter.WorldBossManager.CheckAnyTaskFinished()
    self.BtnTask:ShowReddot(IsHaveRed)
end


function XUiWorldBossAttributeArea:OnBtnBackClick()
    self:Close()
end

function XUiWorldBossAttributeArea:UpdatePhasesReward()
    self.UpdatePanelPhasesReward()
end

function XUiWorldBossAttributeArea:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiWorldBossAttributeArea:OnBtnRankClick()
    XLuaUiManager.Open("UiWorldBossAreaRank", self.AreaId)
end

function XUiWorldBossAttributeArea:OnBtnTaskClick()
    XLuaUiManager.Open("UiWorldBossTask")
end

function XUiWorldBossAttributeArea:OnBtnWarReportClick()
    XLuaUiManager.Open("UiChatUiWorldBoss")
end

function XUiWorldBossAttributeArea:OnBtnTreasureClick()
    local attributeArea = XDataCenter.WorldBossManager.GetAttributeAreaById(self.AreaId)
    local IsCanGet = attributeArea:GetIsAreaFinish()
    local IsGeted = attributeArea:GetIsRewardGeted()
    if not IsCanGet or IsGeted then
        return
    end
    XDataCenter.WorldBossManager.GetAttributeAreaReward(self.AreaId, function ()
            self:UpdatePanelRewrd()
        end)
end

function XUiWorldBossAttributeArea:OnBtnShopClick()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        XLuaUiManager.Open("UiShop", XShopManager.ShopType.WorldBoss)
    end
end