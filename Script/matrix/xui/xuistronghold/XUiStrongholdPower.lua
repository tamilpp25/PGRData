local XUiGridTeamCharacter = require("XUi/XUiStronghold/XUiGridTeamCharacter")

local tableRemove = table.remove
local tableInsert = table.insert
local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("77E8F9FF"),
    [false] = XUiHelper.Hexcolor2Color("FCFA68FF"),
}

local CONDITION_COLOR_2 = {
    [true] = XUiHelper.Hexcolor2Color("56E8F3FF"),
    [false] = XUiHelper.Hexcolor2Color("FFFFFFFF"),
}

local CONDITION_COLOR_FOR_TEXT = {
    [true] = XUiHelper.Hexcolor2Color("ff3f3f"),
    [false] = XUiHelper.Hexcolor2Color("59f5ff"),
}

local XUiStrongholdPower = XLuaUiManager.Register(XLuaUi, "UiStrongholdPower")

function XUiStrongholdPower:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    local itemId = XDataCenter.StrongholdManager.GetMineralItemId()
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self.AssetActivityPanel:Refresh({ itemId })
    end, self.AssetActivityPanel)

    self.GridData.gameObject:SetActiveEx(false)
end

function XUiStrongholdPower:OnStart()
    self.CharacterGrids = {}
end

function XUiStrongholdPower:OnEnable()
    self.AssetActivityPanel:Refresh({ XDataCenter.StrongholdManager.GetMineralItemId() })
    self:UpdateElectric()
    self:UpdateTeam()
end

function XUiStrongholdPower:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_MAX_ELECTRIC_CHANGE,
        XEventId.EVENT_STRONGHOLD_ELECTRIC_CHARACTER_CHANGE,
    }
end

function XUiStrongholdPower:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_STRONGHOLD_MAX_ELECTRIC_CHANGE then
        self:UpdateElectric()
    elseif evt == XEventId.EVENT_STRONGHOLD_ELECTRIC_CHARACTER_CHANGE then
        self:UpdateTeam()
    end
end

function XUiStrongholdPower:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SView)
    local class = XClass(nil, "")
    class.Ctor = function(o, go) XTool.InitUiObjectByUi(o, go) end
    self.DynamicTable:SetProxy(class)
    self.DynamicTable:SetDelegate(self)
end

function XUiStrongholdPower:UpdateElectric()
    local useElectric = XDataCenter.StrongholdManager.GetTotalUseElectricEnergy()
    local maxElectricEnergy = XDataCenter.StrongholdManager.GetMaxElectricEnergy()
    local extraElectricEnergy = XDataCenter.StrongholdManager.GetExtraElectricEnergy()
    local totalElectric = XDataCenter.StrongholdManager.GetTotalElectricEnergy()

    local isUp = useElectric <= totalElectric
    self.PanelZheng.gameObject:SetActiveEx(isUp)
    self.PanelFu.gameObject:SetActiveEx(not isUp)
    self.PanelFu1.gameObject:SetActiveEx(not isUp)
    self.PanelZheng1.gameObject:SetActiveEx(isUp)

    self.TxtYiyong.color = CONDITION_COLOR[isUp]
    self.TxtZong.color = CONDITION_COLOR[isUp]

    self.TxtNumberZheng.text = useElectric .. "/" .. totalElectric
    self.TxtNumberFu.text = useElectric .. "/" .. totalElectric
    self.TxtYiyong.text = CsXTextManagerGetText("StrongholdUseElectricDes", useElectric)
    self.TxtZong.text = CsXTextManagerGetText("StrongholdTotalElectricDes", maxElectricEnergy, extraElectricEnergy)

    self.ImgJinduZheng.fillAmount = totalElectric ~= 0 and (totalElectric - useElectric) / totalElectric or 0

    local maxElectric = XDataCenter.StrongholdManager.GetMaxElectricEnergy()
    local extraElectric = XDataCenter.StrongholdManager.GetExtraElectricEnergy()

    self.TxtElectricMax.text = maxElectric ~= 0 and "+" .. maxElectric or 0
    self.TxtElectricExtra.text = extraElectric ~= 0 and "+" .. extraElectric or 0

    local isPaused = XDataCenter.StrongholdManager.IsDayPaused()
    if isPaused then
        local countTime = XDataCenter.StrongholdManager.GetDelayCountTimeStr()
        self.TxtTipTime.text = CsXTextManagerGetText("StrongholdElectricTimeTwoDelay", countTime)
    else
        local countTime = XDataCenter.StrongholdManager.GetCountTimeStr()
        self.TxtTipTime.text = CsXTextManagerGetText("StrongholdElectricTimeTwo", countTime)
    end
    self.TxtTipTime.color = CONDITION_COLOR_FOR_TEXT[isPaused]

    local addElectric = XDataCenter.StrongholdManager.GetAddElectricEnergy()
    self.TxtTipEnergy.text = CsXTextManagerGetText("StrongholdElectricAdd", addElectric)

    self.Effect.gameObject:SetActiveEx(false)
    if self.OldAddElectric then
        if self.OldAddElectric ~= extraElectric then
            self.Effect.gameObject:SetActiveEx(true)
        end
    end
    self.OldAddElectric = extraElectric

    self.CurIndex = nil
    local totalAbility = XDataCenter.StrongholdManager.GetElectricCharactersTotalAbility()
    self.Records = XStrongholdConfigs.GetTeamAbilityExtraElectricList()
    for index, record in pairs(self.Records) do
        if totalAbility >= record.Ability then
            self.CurIndex = index
        end
    end

    self.DynamicTable:SetDataSource(self.Records)
    self.DynamicTable:ReloadDataASync(self.CurIndex or -1)
end

function XUiStrongholdPower:UpdateTeam()
    local totalAbility = XDataCenter.StrongholdManager.GetElectricCharactersTotalAbility()
    self.TxtTotalAbility.text = CsXTextManagerGetText("StrongholdElectricAbility", totalAbility)

    local characterIds = XDataCenter.StrongholdManager.GetElectricCharacterIds()
    self.CharacterIds = characterIds
    local maxNum = XDataCenter.StrongholdManager.GetElectricTeamMaxCharacterNum()
    for pos = 1, maxNum do
        local grid = self.CharacterGrids[pos]
        if not grid then
            local ui = pos == 1 and self.GridCharacter or CSUnityEngineObjectInstantiate(self.GridCharacter, self.Layout)
            grid = XUiGridTeamCharacter.New(ui)
            self.CharacterGrids[pos] = grid
        end

        local characterId = characterIds[pos]
        grid:Refresh(characterId)
        grid.GameObject:SetActiveEx(true)
    end

    for pos = maxNum + 1, #self.CharacterGrids do
        local grid = self.CharacterGrids[pos]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiStrongholdPower:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local record = self.Records[index]
        grid.TxtZhanLi.text = record.Ability
        grid.TxtKuoRong.text = record.Electric

        local isCurrent = index and self.CurIndex == index
        grid.TxtZhanLi.color = CONDITION_COLOR_2[isCurrent]
        grid.TxtKuoRong.color = CONDITION_COLOR_2[isCurrent]
    end
end

function XUiStrongholdPower:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    if self.BtnHelp then
        self.BtnHelp.CallBack = function() self:OnClickBtnHelp() end
    end
    self:BindHelpBtn(self.BtnActDesc, "StrongholdMain")
end

function XUiStrongholdPower:OnClickBtnBack()
    self:Close()
end

function XUiStrongholdPower:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiStrongholdPower:OnClickBtnActDesc()
    local description = XUiHelper.ConvertLineBreakSymbol(CsXTextManagerGetText("StrongholdUiElectricActDes"))
    XUiManager.UiFubenDialogTip("", description)
end

function XUiStrongholdPower:OnClickBtnHelp()
    XLuaUiManager.Open("UiStrongholdPowerExpectTips")
end