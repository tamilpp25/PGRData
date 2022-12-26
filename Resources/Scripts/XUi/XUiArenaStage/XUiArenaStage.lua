local XUiArenaStage = XLuaUiManager.Register(XLuaUi, "UiArenaStage")

local XUiPanelPassDetail = require("XUi/XUiArenaStage/XUiPanelPassDetail")
local XUiGridArenaStage = require("XUi/XUiArenaStage/ArenaStageCommon/XUiGridArenaStage")

function XUiArenaStage:OnAwake()
    self:AutoAddListener()
end

function XUiArenaStage:OnStart(areaId)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.PanelArenaStage.gameObject:SetActive(true)
    self.PassDetailPanel = XUiPanelPassDetail.New(self.PanelPassDetail, self)
    self.PassDetailPanel:Hide()

    self.StageList = {}
    for i = 1, 3 do
        local grid = XUiGridArenaStage.New(self["GridStage" .. i], self)
        table.insert(self.StageList, grid)
    end

    self.LordList = {}
    for i = 1, 3 do
        table.insert(self.LordList, self["GridLord" .. i])
    end

    self.AreaId = areaId
end


function XUiArenaStage:OnEnable()
    if XDataCenter.ArenaManager.IsChangeStatusInFight() then
        return
    end

    XDataCenter.ArenaManager.RequestAreaData()
    self:Refresh()
end

function XUiArenaStage:OnGetEvents()
    return { XEventId.EVENT_ARENA_REFRESH_AREA_INFO }
end


function XUiArenaStage:OnNotify(evt)
    if evt == XEventId.EVENT_ARENA_REFRESH_AREA_INFO then
        self:Refresh()
    end
end

function XUiArenaStage:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnPassDetail, self.OnBtnPassDetailClick)
    self:BindHelpBtn(self.BtnHelpCourse, "Arena")
end

function XUiArenaStage:OnBtnBackClick()
    if self.PassDetailPanel.IsShow then
        self.PanelArenaStage.gameObject:SetActive(true)
        self.PassDetailPanel:Hide()
        return
    end

    self:Close()
end

function XUiArenaStage:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArenaStage:OnBtnPassDetailClick()
    XDataCenter.ArenaManager.RequestStagePassDetail(self.AreaId, function(detailMap)
        self.PanelArenaStage.gameObject:SetActive(false)
        self.PassDetailPanel:Show(self.AreaCfg.StageId, detailMap)
    end)
end

function XUiArenaStage:Refresh()
    local areaInfo = XDataCenter.ArenaManager.GetArenaAreaDataByAreaId(self.AreaId)
    self.TxtPoint.text = areaInfo.Point
    self.AreaCfg = XArenaConfigs.GetArenaAreaStageCfgByAreaId(self.AreaId)
    self.TxtStageName.text = self.AreaCfg.Name
    self.TxtStageDesc.text = self.AreaCfg.BuffDesc

    self.CanEnterStageIndex = XDataCenter.ArenaManager.GetCurStageIndexByAreaId(self.AreaId)
    if self.CanEnterStageIndex > #self.AreaCfg.StageId then
        self.CanEnterStageIndex = #self.AreaCfg.StageId
    end

    for i, grid in ipairs(self.StageList) do
        local stageId = self.AreaCfg.StageId[i]
        local score = XDataCenter.ArenaManager.GetArenaStageScore(self.AreaId, stageId)
        grid:Refresh(i, self.CanEnterStageIndex, score, stageId, self.AreaId)
    end

    for i, grid in ipairs(self.LordList) do
        local head = XUiHelper.TryGetComponent(grid, "Head")
        local rank = XUiHelper.TryGetComponent(grid, "TxtRank", "Text")
        local point = XUiHelper.TryGetComponent(grid, "TxtPoint", "Text")
        local nickname = XUiHelper.TryGetComponent(grid, "TxtNickname", "Text")
        local btnHead = XUiHelper.TryGetComponent(grid, "BtnHead", "Button")

        CsXUiHelper.RegisterClickEvent(btnHead, function()
            local data = areaInfo.LordList[i]
            if not data or data.Id == XPlayer.Id then
                return
            end
            XDataCenter.PersonalInfoManager.ReqShowInfoPanel(data.Id)
        end, true)

        rank.text = i

        local lordInfo = areaInfo.LordList[i]
        if lordInfo then
            nickname.text = XDataCenter.SocialManager.GetPlayerRemark(lordInfo.Id, lordInfo.Name)
            point.text = lordInfo.Point

            XUiPLayerHead.InitPortrait(lordInfo.CurrHeadPortraitId, lordInfo.CurrHeadFrameId, head)
        else
            nickname.text = CS.XTextManager.GetText("ArenaActivityLordIsEmpty")
            point.text = ""
            XUiPLayerHead.Hide(head)
        end
    end
end