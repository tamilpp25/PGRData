local stringGsub = string.gsub
local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdMining = XLuaUiManager.Register(XLuaUi, "UiStrongholdMining")

function XUiStrongholdMining:OnAwake()
    self:AutoAddListener()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    local itemId = XDataCenter.StrongholdManager.GetMineralItemId()
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self.AssetActivityPanel:Refresh({ itemId })
    end, self.AssetActivityPanel)
end

function XUiStrongholdMining:OnStart()
    self:InitView()
end

function XUiStrongholdMining:OnEnable()
    self.AssetActivityPanel:Refresh({ XDataCenter.StrongholdManager.GetMineralItemId() })
    self:UpdateView()
end

function XUiStrongholdMining:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_MINERAL_RECORD_CHANGE,
    }
end

function XUiStrongholdMining:OnNotify(evt, ...)
    if evt == XEventId.EVENT_STRONGHOLD_MINERAL_RECORD_CHANGE then
        self:UpdateView()
    end
end

function XUiStrongholdMining:InitView()
    local itemId = XDataCenter.StrongholdManager.GetMinerItemId()

    local name = XItemConfigs.GetItemNameById(itemId)
    self.TxtName.text = name

    local icon = XItemConfigs.GetItemIconById(itemId)
    self.RImgIcon:SetRawImage(icon)

    local efficiency = XDataCenter.StrongholdManager.GetTotalMinerEfficiency()
    self.TxtEfficiency.text = CsXTextManagerGetText("StrongholdMineEfficiencyDesc", efficiency)

    local growRate = XDataCenter.StrongholdManager.GetTotalMinerGrowRate()
    self.TxtProliferation.text = CsXTextManagerGetText("StrongholdMinerGrowRateDesc", growRate)

    self.TxtExplain1.text = CsXTextManagerGetText("StrongholdMinerExplainOne")
    self.TxtExplain2.text = CsXTextManagerGetText("StrongholdMinerExplainTwo")
end

function XUiStrongholdMining:UpdateView()
    local minerCount = XDataCenter.StrongholdManager.GetMinerCount()
    self.TxtPeople.text = minerCount

    local mineralCount = XDataCenter.StrongholdManager.GetMineralOutput(minerCount)
    self.TxtMineral.text = mineralCount

    local mineralTotalCount = XDataCenter.StrongholdManager.GetPredictTotalMineralCount()
    self.TxtMineralTotal.text = mineralTotalCount
end

function XUiStrongholdMining:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    -- self.BtnActDesc.CallBack = function() self:OnClickBtnActDesc() end
    self:BindHelpBtn(self.BtnActDesc, "StrongholdMain")
    self.BtnApply.CallBack = function() self:OnClickBtnApply() end
end

function XUiStrongholdMining:OnClickBtnBack()
    self:Close()
end

function XUiStrongholdMining:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiStrongholdMining:OnClickBtnActDesc()
    local description = XUiHelper.ConvertLineBreakSymbol(CsXTextManagerGetText("StrongholdUiMineActDes"))
    XUiManager.UiFubenDialogTip("", description)
end

function XUiStrongholdMining:OnClickBtnApply()
    XLuaUiManager.Open("UiStrongholdJournal")
end