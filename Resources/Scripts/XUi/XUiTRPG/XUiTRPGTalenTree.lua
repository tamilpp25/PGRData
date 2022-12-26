local XUiGridTRPGRoleTalent = require("XUi/XUiTRPG/XUiGridTRPGRoleTalent")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local ipairs = ipairs
local handler = handler

local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("0F70BCFF"),
    [false] = CS.UnityEngine.Color.red,
}

local XUiTRPGTalenTree = XLuaUiManager.Register(XLuaUi, "UiTRPGTalenTree")

function XUiTRPGTalenTree:RefreshData(roleId, notNext, notLast)
    self.RoleId = roleId
    self.NotNext = notNext
    self.NotLast = notLast
end

function XUiTRPGTalenTree:OnAwake()
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiTRPGTalenTree:OnStart(roleId, closeCb, showDetailCb, hideDetailCb, selectNextCb, selectLastCb, notNext, notLast)
    self.RoleId = roleId
    self.CloseCb = closeCb
    self.ShowDetailCb = showDetailCb
    self.HideDetailCb = hideDetailCb
    self.SelectNextCb = selectNextCb
    self.SelectLastCb = selectLastCb
    self.NotNext = notNext
    self.NotLast = notLast
    self.TalentGrids = {}

    self:InitUi()
end

function XUiTRPGTalenTree:OnEnable()
    self:UpdateTalents()
    self:UpdateTalentDetail()
    self:UpdateSwitchBtns()
end

function XUiTRPGTalenTree:OnDisable()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiTRPGTalenTree:OnGetEvents()
    return { XEventId.EVENT_TRPG_ROLES_DATA_CHANGE }
end

function XUiTRPGTalenTree:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TRPG_ROLES_DATA_CHANGE then
        self:UpdateTalents()
        self:UpdateTalentDetail()
    end
end

function XUiTRPGTalenTree:InitUi()
    local resetCostItemIcon = XTRPGConfigs.GetTalentResetCostItemIcon()
    self.RImgCostItemIcon:SetRawImage(resetCostItemIcon)

    local resetCostCount = XTRPGConfigs.GetTalentResetCostItemCount()
    self.TxtResetCostItemNum.text = resetCostCount

    local talentIcon = XTRPGConfigs.GetTalentPointIcon()
    self.RImgTalentIcon:SetRawImage(talentIcon)
    self.RImgCostTalentIcon:SetRawImage(talentIcon)
    self.RImgAssetTalentIcon:SetRawImage(talentIcon)
end

function XUiTRPGTalenTree:UpdateSwitchBtns()
    self.BtnNext.gameObject:SetActiveEx(not self.NotNext)
    self.BtnLast.gameObject:SetActiveEx(not self.NotLast)
end

function XUiTRPGTalenTree:UpdateTalents()
    local roleId = self.RoleId

    local usedTalent = XDataCenter.TRPGManager.GetRoleUsedTalentPoints(roleId)
    self.TxtTalentCount.text = usedTalent

    local haveTalent = XDataCenter.TRPGManager.GetRoleHaveTalentPoints()
    local maxTalentPoint = XDataCenter.TRPGManager.GetMaxTalentPoint()
    self.TxtHaveTalentNum.text = CSXTextManagerGetText("TRPGTalent", haveTalent, maxTalentPoint)
    self.TxtAssetHaveTalentNum.text = CSXTextManagerGetText("TRPGTalent", haveTalent, maxTalentPoint)

    local prefab = XTRPGConfigs.GetRoleTalentTreePrefab(roleId)
    local parentUi = self.PanelTalentTree:LoadPrefab(prefab)
    local tree = {}
    XTool.InitUiObjectByUi(tree, parentUi)

    local talentIds = XDataCenter.TRPGManager.GetRoleTalentIds(roleId)
    for index, talentId in ipairs(talentIds) do
        local grid = self.TalentGrids[talentId]
        if not grid then
            local ui = index == 1 and self.GridStageTRPGTalent or CSUnityEngineObjectInstantiate(self.GridStageTRPGTalent)
            local clickCb = handler(self, self.ShowUiDetail)
            grid = XUiGridTRPGRoleTalent.New(ui, clickCb)
            self.TalentGrids[talentId] = grid
        end

        local gridParent = tree["talent" .. index]
        grid.Transform:SetParent(gridParent, false)

        local isActive = XDataCenter.TRPGManager.IsRoleTalentActive(roleId, talentId)
        local canActive = XDataCenter.TRPGManager.IsRoleTalentCanActive(roleId, talentId)
        local showLine = isActive
        local line = tree["line" .. index]
        if line then
            line.gameObject:SetActiveEx(showLine)
        end

        grid:Refresh(roleId, talentId)
        grid:SetSelect(talentId == self.TalentId)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiTRPGTalenTree:UpdateTalentDetail()
    local talentId = self.TalentId
    if not talentId then return end
    local roleId = self.RoleId

    self.TxtTalentDesc.text = XTRPGConfigs.GetRoleTalentDescription(roleId, talentId)
    self.TxtTalentName.text = XTRPGConfigs.GetRoleTalentTitle(roleId, talentId)
    self.TxtTalentInto.text = XTRPGConfigs.GetRoleTalentIntro(roleId, talentId)

    local costPoint = XDataCenter.TRPGManager.GetActiveTalentCostPoint(roleId, talentId)
    self.TxtCostTalent.text = costPoint

    local isCostEnough = XDataCenter.TRPGManager.IsActiveTalentCostEnough(roleId, talentId)
    self.TxtCostTalent.color = CONDITION_COLOR[isCostEnough]

    local isActive = XDataCenter.TRPGManager.IsRoleTalentActive(roleId, talentId)
    self.PanelBottom.gameObject:SetActiveEx(not isActive)

    if self.RImgIconTalent then
        local icon = XTRPGConfigs.GetRoleTalentIcon(roleId, talentId)
        self.RImgIconTalent:SetRawImage(icon)
    end
end

function XUiTRPGTalenTree:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnClickBtnBack)
    self:RegisterClickEvent(self.BtnResetTalent, self.OnClickBtnResetTalent)
    self:RegisterClickEvent(self.BtnActiveTalent, self.OnClickBtnActiveTalent)
    self:RegisterClickEvent(self.BtnCloseDetail, self.OnClickBtnCloseDetail)
    self:RegisterClickEvent(self.BtnNext, self.OnClickBtnNext)
    self:RegisterClickEvent(self.BtnLast, self.OnClickBtnLast)
    self:RegisterClickEvent(self.BtnRimgAssetTalentIcon, self.OnClickRimgTalentIcon)
    self:RegisterClickEvent(self.BtnRimgDetailTalentIcon, self.OnClickRimgTalentIcon)
end

function XUiTRPGTalenTree:OnClickBtnBack()
    self:Close()
end

function XUiTRPGTalenTree:OnClickBtnResetTalent()
    local roleId = self.RoleId
    local talentId = self.TalentId

    if not XDataCenter.TRPGManager.IsRoleAnyTalentActive(roleId) then
        XUiManager.TipText("TRPGRoleTalentResetNotTalentActive")
        return
    end

    if not XDataCenter.TRPGManager.IsTalentResetCostEnough() then
        XUiManager.TipText("TRPGRoleTalentResetCostLack")
        return
    end

    local costItemId = XTRPGConfigs.GetTalentResetCostItemId()
    local costItemCount = XTRPGConfigs.GetTalentResetCostItemCount()
    local itemName = XDataCenter.ItemManager.GetItemName(costItemId)
    local title = CSXTextManagerGetText("TRPGExploreTalentResetTipsTitle")
    local content = CSXTextManagerGetText("TRPGExploreTalentResetTipsContent", itemName, costItemCount)
    local callFunc = function()
        XDataCenter.TRPGManager.TRPGResetTalentRequest(roleId)
    end
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
end

function XUiTRPGTalenTree:OnClickBtnActiveTalent()
    local roleId = self.RoleId
    local talentId = self.TalentId

    if not XDataCenter.TRPGManager.IsRoleTalentCanActive(roleId, talentId) then
        XUiManager.TipText("TRPGRoleTalentNeedPreTalentActive")
        return
    end

    if not XDataCenter.TRPGManager.IsActiveTalentCostEnough(roleId, talentId) then
        XUiManager.TipText("TRPGRoleTalentActiveCostLack")
        return
    end

    local cb = function()
        -- self:HideUiDetail()--他不要了
    end
    XDataCenter.TRPGManager.TRPGActivateTalentRequest(roleId, talentId, cb)
end

function XUiTRPGTalenTree:OnClickBtnCloseDetail()
    self:HideUiDetail()
end

function XUiTRPGTalenTree:OnClickBtnNext()
    self.SelectNextCb()

    self:UpdateTalents()
    self:UpdateTalentDetail()
    self:UpdateSwitchBtns()
end

function XUiTRPGTalenTree:OnClickBtnLast()
    self.SelectLastCb()

    self:UpdateTalents()
    self:UpdateTalentDetail()
    self:UpdateSwitchBtns()
end

function XUiTRPGTalenTree:OnClickRimgTalentIcon()
    local data = XDataCenter.TRPGManager.GetTalentPointTipsData()
    XLuaUiManager.Open("UiTip", data)
end

function XUiTRPGTalenTree:ShowUiDetail(roleId, talentId)
    self.TalentId = talentId

    self:UpdateTalentDetail()

    for paramTalentId, grid in pairs(self.TalentGrids) do
        grid:SetSelect(talentId == paramTalentId)
    end

    if self.ShowDetailCb then self.ShowDetailCb() end

    if not self.IsDetailShow then
        self:PlayAnimationWithMask("PanelDetailEnable")
    end
    self.BtnCloseDetail.gameObject:SetActiveEx(true)

    self.IsDetailShow = true
end

function XUiTRPGTalenTree:HideUiDetail()
    if not self.IsDetailShow then return end
    self.IsDetailShow = nil

    for _, grid in pairs(self.TalentGrids) do
        grid:SetSelect(false)
    end

    if self.HideDetailCb then self.HideDetailCb() end

    self:PlayAnimationWithMask("PanelDetailDisable")
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
end