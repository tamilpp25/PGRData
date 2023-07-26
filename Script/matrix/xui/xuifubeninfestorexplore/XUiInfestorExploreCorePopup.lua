local XUiGridInfestorExploreCore = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreCore")

local XUiInfestorExploreCorePopup = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreCorePopup")

function XUiInfestorExploreCorePopup:OnAwake()
    self:AutoAddListener()
end

function XUiInfestorExploreCorePopup:OnStart(coreId, wearingCoreId, closeCb)
    self.CoreId = coreId
    self.WearingCoreId = wearingCoreId
    self.CloseCb = closeCb
end

function XUiInfestorExploreCorePopup:OnEnable()
    self:Refresh(self.CoreId, self.WearingCoreId)
end

function XUiInfestorExploreCorePopup:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiInfestorExploreCorePopup:OnGetEvents()
    return { XEventId.EVENT_INFESTOREXPLORE_SELECT_CORE }
end

function XUiInfestorExploreCorePopup:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_INFESTOREXPLORE_SELECT_CORE then
        local coreId = args[1]
        local selectPos = args[2]
        self:Refresh(coreId, selectPos)
    end
end

function XUiInfestorExploreCorePopup:Refresh(coreId, selectPos)
    self.SelectPos = selectPos
    local wearingCoreId = XDataCenter.FubenInfestorExploreManager.GetWearingCoreId(selectPos)

    local isShowUsingPanel = (coreId and coreId > 0 and wearingCoreId and wearingCoreId > 0 and coreId ~= wearingCoreId) and true or false
    self.PanelUsing.gameObject:SetActiveEx(isShowUsingPanel)

    self:UpdateSelectPanel(coreId)
    self:UpdateUsingPanel(wearingCoreId)
end

function XUiInfestorExploreCorePopup:UpdateSelectPanel(coreId)
    if not coreId then return end
    self.CoreId = coreId

    local grid = self.SelectCoreGrid
    if not grid then
        grid = XUiGridInfestorExploreCore.New(self.GridSelectCore, self)
        self.SelectCoreGrid = grid
    end
    grid:Refresh(coreId)

    local isWearing = XDataCenter.FubenInfestorExploreManager.IsCoreWearing(coreId)
    self.BtnPutOn.gameObject:SetActiveEx(not isWearing)
    self.BtnTakeOff.gameObject:SetActiveEx(isWearing)
end

function XUiInfestorExploreCorePopup:UpdateUsingPanel(wearingCoreId)
    if not wearingCoreId or wearingCoreId <= 0 then return end

    local grid = self.UsingCoreGrid
    if not grid then
        grid = XUiGridInfestorExploreCore.New(self.GridUsingCore, self)
        self.UsingCoreGrid = grid
    end
    grid:Refresh(wearingCoreId)
end

function XUiInfestorExploreCorePopup:AutoAddListener()
    self:RegisterClickEvent(self.BtnPutOn, self.OnBtnPutOnClick)
    self:RegisterClickEvent(self.BtnTakeOff, self.OnBtnTakeOffClick)
end

function XUiInfestorExploreCorePopup:OnBtnPutOnClick()
    local coreId = self.CoreId
    local pos = self.SelectPos
    local callBack = function()
        self:Close()
    end
    XDataCenter.FubenInfestorExploreManager.RequestInfestorExplorePutOnCore(coreId, pos, callBack)
end

function XUiInfestorExploreCorePopup:OnBtnTakeOffClick()
    local pos = self.SelectPos
    local callBack = function()
        self:Close()
    end
    XDataCenter.FubenInfestorExploreManager.RequestInfestorExploreTakeOffCore(pos, callBack)
end