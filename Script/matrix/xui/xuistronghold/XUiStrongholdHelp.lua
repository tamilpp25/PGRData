local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdHelp = XLuaUiManager.Register(XLuaUi, "UiStrongholdHelp")

function XUiStrongholdHelp:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.TxtReward.gameObject:SetActiveEx(false)

    self.ImgEmpty = self.GameObject:FindTransform("ImgEmpty")
end

function XUiStrongholdHelp:OnEnable()

    self:UpdateView()
end

function XUiStrongholdHelp:OnDisable()

end

function XUiStrongholdHelp:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_ASSISTANT_CHARACTER_SET_CHANGE,
    }
end

function XUiStrongholdHelp:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_STRONGHOLD_ASSISTANT_CHARACTER_SET_CHANGE then
        self:UpdateView()
    end
end

function XUiStrongholdHelp:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ScrollReward)
    local class = XClass(nil, "")
    class.Ctor = function(o, go) XTool.InitUiObjectByUi(o, go) end
    self.DynamicTable:SetProxy(class)
    self.DynamicTable:SetDelegate(self)
end

function XUiStrongholdHelp:UpdateView()
    if not XDataCenter.StrongholdManager.IsHaveAssistantCharacter() then

        self.TxtTips.text = XUiHelper.ConvertLineBreakSymbol(CsXTextManagerGetText("StrongholdSetAssistTips"))

        self.ImgAdd.gameObject:SetActiveEx(true)
        self.ImgEmptyRole.gameObject:SetActiveEx(true)
        self.PanelRoleInformation.gameObject:SetActiveEx(false)
        self.RImgRole.gameObject:SetActiveEx(false)
        self.PanelHint.gameObject:SetActiveEx(false)

    else

        local characterId = XDataCenter.StrongholdManager.GetAssistantCharacterId()

        local icon = XMVCA.XCharacter:GetCharHalfBodyBigImage(characterId)
        self.RImgRole:SetRawImage(icon)

        local ability = XMVCA.XCharacter:GetCharacterAbilityById(characterId)
        self.TxtAbility.text = ability

        local name = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
        self.TxtName.text = name

        self.Records = XDataCenter.StrongholdManager.GetAssitantRecordStrList()
        self.DynamicTable:SetDataSource(self.Records)
        self.DynamicTable:ReloadDataASync()

        local isEmpty = XTool.IsTableEmpty(self.Records)
        self.ImgAdd.gameObject:SetActiveEx(isEmpty)
        self.ImgEmpty.gameObject:SetActiveEx(isEmpty)

        self.ImgAdd.gameObject:SetActiveEx(false)
        self.ImgEmptyRole.gameObject:SetActiveEx(false)
        self.PanelRoleInformation.gameObject:SetActiveEx(true)
        self.RImgRole.gameObject:SetActiveEx(true)
        self.PanelHint.gameObject:SetActiveEx(true)
    end
end

function XUiStrongholdHelp:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local record = self.Records[index]
        grid.TxtReward.text = record
    end
end

function XUiStrongholdHelp:AutoAddListener()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnOccupy.CallBack = function() self:OnClickBtnOccupy() end
end

function XUiStrongholdHelp:OnClickBtnOccupy()
    local characterId = nil
    local supportData = {
        CanSupportCancel = false,
        CheckInSupportCb = function(characterId)
            return XDataCenter.StrongholdManager.CheckIsAssistantCharacter(characterId)
        end,
        SetCharacterCb = function(characterId, cb)
            XDataCenter.StrongholdManager.SetStrongholdAssistCharacterRequest(characterId, cb)
            return true
        end,
    }
    -- XLuaUiManager.Open("UiCharacter", characterId, nil, nil, nil, nil, nil, supportData)
    XLuaUiManager.Open("UiSelectCharacterStrongholdSupport", characterId, supportData)
end