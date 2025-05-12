local pairs = pairs
local tableInsert = table.insert

local StarTogIndex = {
    [1] = { 1, 2, 3 },
    [2] = { 4 },
    [3] = { 5 },
}

local DaysTogIndex = {
    [1] = 1,
    [2] = 3,
    [3] = 14,
    [4] = 0,
}

local XUiRecyclingSettings = XLuaUiManager.Register(XLuaUi, "UiRecyclingSettings")

function XUiRecyclingSettings:OnAwake()
    self:AutoAddListener()

    local togs = {
        self.BtnDays1
        , self.BtnDays2
        , self.BtnDays3
        , self.BtnDays4
    }
    self.DaysBtnGroup:Init(togs, function(index) self:OnSelectDays(index) end)
end

function XUiRecyclingSettings:OnStart()
    self.StarCheckDic = XMVCA.XEquip:GetRecycleStarCheckDic()
    self.Days = XMVCA.XEquip:GetRecycleSettingDays()
end

function XUiRecyclingSettings:OnEnable()
    self:UpdateView()
end

function XUiRecyclingSettings:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.TryClose)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.TryClose)
    self:RegisterClickEvent(self.BtnTcanchaungBlack, self.TryClose)
    self:RegisterClickEvent(self.BtnTcanchaungBlue, self.OnClickBtnConfirm)

    for index in pairs(StarTogIndex) do
        local btn = self["BtnAwareness" .. index]
        btn.CallBack = function()
            local isSelect = btn.ButtonState == CS.UiButtonState.Select
            self:OnSelectStar(index, isSelect)
        end
    end

end

function XUiRecyclingSettings:UpdateView()
    for star, value in pairs(self.StarCheckDic) do
        local isSelect = value and true or false
        local index = self:GetStarBtnIndex(star)
        self["BtnAwareness" .. index]:SetButtonState(CS.UiButtonState.Select)
    end

    local index = self:GetDaysBtnIndex(self.Days)
    self.DaysBtnGroup:SelectIndex(index, false)
end

function XUiRecyclingSettings:OnClickBtnConfirm()
    local cb = function()
        self:Close()
    end
    local starList = {}
    for star, value in pairs(self.StarCheckDic) do
        if value then
            tableInsert(starList, star)
        end
    end
    local days = self.Days
    XMVCA.XEquip:EquipChipSiteAutoRecycleRequest(starList, days, cb)
end

function XUiRecyclingSettings:TryClose()
    local closeFunc = function()
        self:Close()
    end

    if XMVCA.XEquip:CheckRecycleInfoDifferent(self.StarCheckDic, self.Days) then
        local title = CsXTextManagerGetText("EquipRecycleSetttingCancelConfirmTitle")
        local content = CsXTextManagerGetText("EquipRecycleSetttingCancelConfirmContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, closeFunc)
    else
        closeFunc()
    end
end

function XUiRecyclingSettings:CheckDifferent()


end

function XUiRecyclingSettings:OnSelectStar(index, isSelect)
    local starValue = isSelect or nil
    local stars = StarTogIndex[index]
    for _, star in pairs(stars) do
        self.StarCheckDic[star] = starValue
    end
end

function XUiRecyclingSettings:OnSelectDays(index)
    self.Days = DaysTogIndex[index]
end

function XUiRecyclingSettings:GetStarBtnIndex(star)
    for index, stars in pairs(StarTogIndex) do
        for _, inStar in pairs(stars) do
            if inStar == star then
                return index
            end
        end
    end
end

function XUiRecyclingSettings:GetDaysBtnIndex(days)
    for index, inDays in pairs(DaysTogIndex) do
        if inDays == days then
            return index
        end
    end
end