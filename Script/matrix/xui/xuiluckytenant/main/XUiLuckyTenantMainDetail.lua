local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiLuckyTenantMainDetailGrid = require("XUi/XUiLuckyTenant/Main/XUiLuckyTenantMainDetailGrid")
local XUiLuckyTenantChessGrid = require("XUi/XUiLuckyTenant/Game/XUiLuckyTenantChessGrid")

---@class XUiLuckyTenantMainDetail : XLuaUi
---@field _Control XLuckyTenantControl
local XUiLuckyTenantMainDetail = XLuaUiManager.Register(XLuaUi, "UiLuckyTenantMainDetail")

function XUiLuckyTenantMainDetail:OnAwake()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiLuckyTenantMainDetailGrid, self)
    self:BindExitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.Close, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTongBlue, self.OnClickStart, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTongBlue02, self.OnClickStart, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDetail, self.OnClickCloseDetail, nil, true)
    ---@type XUiLuckyTenantChessGrid
    self._Detail = XUiLuckyTenantChessGrid.New(self.GirdLuckyLandlordChessDetail, self)
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
end

---@param grid XUiLuckyTenantMainStageGrid
function XUiLuckyTenantMainDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    end
end

function XUiLuckyTenantMainDetail:OnStart(stageId)
    self._Control:UpdateStageDetail(stageId)
end

function XUiLuckyTenantMainDetail:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT_OPEN_DETAIL, self.OpenUiDetail, self)
    self:Update()
end

function XUiLuckyTenantMainDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT_OPEN_DETAIL, self.OpenUiDetail, self)
end

function XUiLuckyTenantMainDetail:Update()
    local data = self._Control:GetUiData().StageDetail

    if data.IsChallengeStage then
        self.Panel1.gameObject:SetActiveEx(true)
        self.Panel2.gameObject:SetActiveEx(false)
        self.RImgStageName1.text = data.Name
    else
        self.Panel1.gameObject:SetActiveEx(false)
        self.Panel2.gameObject:SetActiveEx(true)
        self.RImgStageName2.text = data.Name
    end

    self.TxtSchedule.text = data.BestRound
    self.TxtScore.text = data.BestScore
    self.Max.gameObject:SetActiveEx(data.IsMax)
    --self.PanelReward
    --self.GirdLuckyLandlordChessDetail
    self.TxtRewardNum.text = data.QuestAmount
    self.TxtTarget.text = data.Desc
    --self.ChessList
    --self.PanelList
    self.DynamicTable:SetDataSource(data.Pieces)
    self.DynamicTable:ReloadDataASync()
    if self.BtnTongBlue02 then
        if data.IsPlaying then
            self.BtnTongBlue.gameObject:SetActiveEx(true)
            self.BtnTongBlue02.gameObject:SetActiveEx(false)
        else
            self.BtnTongBlue.gameObject:SetActiveEx(false)
            self.BtnTongBlue02.gameObject:SetActiveEx(true)
        end
    end
    if self.TextEmpty then
        if #data.Pieces == 0 then
            self.TextEmpty.gameObject:SetActiveEx(true)
        else
            self.TextEmpty.gameObject:SetActiveEx(false)
        end
    end
end

function XUiLuckyTenantMainDetail:OnClickStart()
    self._Control:OpenGameUi(self._Control:GetUiData().StageDetail)
    self:Close()
end

function XUiLuckyTenantMainDetail:OpenUiDetail(data)
    self._Detail:Open()
    self.BtnCloseDetail.gameObject:SetActiveEx(true)
    self._Detail:Update(data)
end

function XUiLuckyTenantMainDetail:OnClickCloseDetail()
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self._Detail:Close()
end

return XUiLuckyTenantMainDetail