local XUiMentorAwarenessGiveaway = XLuaUiManager.Register(XLuaUi, "UiMentorAwarenessGiveaway")
local XUiPanelEquipScroll = require("XUi/XUiEquipAwarenessReplace/XUiPanelEquipScroll")
local XUiPanelSuitSimpleScroll = require("XUi/XUiEquipAwarenessReplace/XUiPanelSuitSimpleScroll")
local XUiGridEquip = require("XUi/XUiEquipAwarenessReplace/XUiGridEquip")

local type = type
local tableInsert = table.insert
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule
local CSXScheduleManagerScheduleOnce = XScheduleManager.ScheduleOnce

local MAX_MERGE_ATTR_COUNT = 4
local MAX_RESONANCE_SKILL_COUNT = 6
local GIVE_COUNT = 2

local ViewPattern = {
    Suit = 1,
    Quick = 2,
}

function XUiMentorAwarenessGiveaway:OnAwake()
    self:AutoAddListener()
    self:InitComponentStatus()
end

function XUiMentorAwarenessGiveaway:OnStart(studentId, taskId, callBack)
    self.IsAscendOrder = false --初始降序
    self.LastViewPattern = ViewPattern.Suit
    self.SelectedSuitStar = 5
    self.SelectedEquipSite = "Total"
    self.SelectedEquipIdList = {}
    self.TempSpriteList = {}
    self.IsSending = false
    self.StudentId = studentId
    self.TaskId = taskId
    self.CallBack = callBack
    self.PanelTabBtns:Init({
        self.BtnSuit,
    }, function(tabIndex) self:OnSelectViewPattern(tabIndex) end)

    self.PanelTogPos:Init({
        self.Tog1,
        self.Tog2,
        self.Tog3,
        self.Tog4,
        self.Tog5,
        self.Tog6,
    }, function(tabIndex) self:OnSelectEquipSite(tabIndex) end)

    self.PanelTogPosStar:Init({
        self.TogStar1,
        self.TogStar2,
        self.TogStar3,
        self.TogStar4,
        self.TogStar5,
    }, function(tabIndex) self:OnSelectSuitStar(tabIndex) end)

    self:InitScrollPanel()
    self:InitCurEquipGrids()
end

function XUiMentorAwarenessGiveaway:OnEnable()
    self:ResetPanel()
end

function XUiMentorAwarenessGiveaway:OnDestroy()
    for _, info in pairs(self.TempSpriteList) do
        CS.UnityEngine.Object.Destroy(info.Sprite)
        CS.XResourceManager.Unload(info.Resource)
    end
end


function XUiMentorAwarenessGiveaway:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_RECYCLE_NOTIFY,
    }
end

function XUiMentorAwarenessGiveaway:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_EQUIP_RECYCLE_NOTIFY then
        --有意识被回收时直接关闭界面
        XLuaUiManager.Close("UiMentorAwarenessPopup")
        self:Close()
    end
end

function XUiMentorAwarenessGiveaway:ResetPanel()
    self:UpdateCurEquipGrids()
    self:UpdateViewData()
    if self.LastViewPattern ~= ViewPattern.Quick then
        self.PanelTabBtns:SelectIndex(self.LastViewPattern)
    else
        self:UpdateSuitDrdOptionList()
        self:OnSelectSortType(XEquipConfig.PriorSortType.Star, true)
    end
end

function XUiMentorAwarenessGiveaway:InitComponentStatus()
    self.GridSuitSimple.gameObject:SetActive(false)
    self.Verticallayout = self.PanelAdapter:GetComponent("VerticalLayoutGroup")
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.DrdSuit.onValueChanged:AddListener(function()
        self:OnDrdSuitValueChanged()
    end)
end

function XUiMentorAwarenessGiveaway:UpdateViewData()
    self.SiteToEquipIdsDic = XDataCenter.EquipManager.ConstructAwarenessSiteToEquipIdsDic(nil, true)
    self.StarToSiteToSuitIdsDic = XDataCenter.EquipManager.ConstructAwarenessStarToSiteToSuitIdsDic(nil, true)
    self.SuitIdToEquipIdsDic = XDataCenter.EquipManager.ConstructAwarenessSuitIdToEquipIdsDic(nil, true)
end

function XUiMentorAwarenessGiveaway:UpdateSuitDrdOptionList()
    self.DrdSuit:ClearOptions()
    local optionDataList = CS.UnityEngine.UI.Dropdown.OptionDataList()
    for _, suitId in pairs(self.StarToSiteToSuitIdsDic[self.SelectedSuitStar][self.SelectedEquipSite]) do
        local optionData = CS.UnityEngine.UI.Dropdown.OptionData()
        optionData.text = XDataCenter.EquipManager.GetSuitName(suitId)

        local resource = CS.XResourceManager.Load(XDataCenter.EquipManager.GetSuitIconBagPath(suitId))
        local texture = resource.Asset
        local sprite = CS.UnityEngine.Sprite.Create(texture,
        CS.UnityEngine.Rect(0, 0, texture.width, texture.height),
        CS.UnityEngine.Vector2.zero)
        optionData.image = sprite
        optionDataList.options:Add(optionData)

        local info = {
            Sprite = sprite,
            Resource = resource,
        }
        tableInsert(self.TempSpriteList, info)
    end
    self.DrdSuit:AddOptions(optionDataList.options)
end

function XUiMentorAwarenessGiveaway:InitScrollPanel()
    local equipTouchCb = function(equipId)
        self:OnSelectEquip(equipId)
    end

    local suitTouchCb = function(suitId)
        self:OnSelectViewPattern(ViewPattern.Quick)
        self:UpdateSuitDrdOptionList()
        self:UpdateDrdSuitValue(suitId)
    end

    self.EquipScroll = XUiPanelEquipScroll.New(self, self.PanelEquipScroll, equipTouchCb)
    self.SuitSimpleScroll = XUiPanelSuitSimpleScroll.New(self, self.PanelSuitSimpleScroll, suitTouchCb)
end

function XUiMentorAwarenessGiveaway:InitCurEquipGrids()
    self.CurEquipGirds = {}

    for index = 1, GIVE_COUNT, 1 do
        local item = CSUnityEngineObjectInstantiate(self.GridCurAwareness)
        self.CurEquipGirds[index] = XUiGridEquip.New(item, function()
            local curId = self.SelectedEquipIdList[index]
            if curId then
                self:OnSelectEquip(curId)
            end
        end)
        self.CurEquipGirds[index]:InitRootUi(self)
        self.CurEquipGirds[index].Transform:SetParent(self[string.format("%s%d", "PanelPos", index)], false)
    end
end

function XUiMentorAwarenessGiveaway:UpdateCurEquipGrids()
    for index = 1, GIVE_COUNT, 1 do
        self:UpdateCurEquipGrid(index)
    end
end

function XUiMentorAwarenessGiveaway:UpdateCurEquipGrid(index)
    local equipId = self.SelectedEquipIdList[index]
    if not equipId then
        self.CurEquipGirds[index].GameObject:SetActive(false)
        self[string.format("%s%d", "PanelNoEquip", index)].gameObject:SetActive(true)
    else
        self.CurEquipGirds[index]:Refresh(equipId)
        self.CurEquipGirds[index].GameObject:SetActive(true)
        self[string.format("%s%d", "PanelNoEquip", index)].gameObject:SetActive(false)
    end
end

function XUiMentorAwarenessGiveaway:OnSelectSortType(sortType, doNotResetSelect, onlyUpdate)
    if not onlyUpdate then
        for key, list in pairs(self.SiteToEquipIdsDic) do
            XDataCenter.EquipManager.SortEquipIdListByPriorType(list, sortType)
            if self.IsAscendOrder then
                XTool.ReverseList(list)
            end
        end

        for _, lists in pairs(self.SuitIdToEquipIdsDic) do
            for key, list in pairs(lists) do
                XDataCenter.EquipManager.SortEquipIdListByPriorType(list, sortType)
                if self.IsAscendOrder then
                    XTool.ReverseList(list)
                end
            end
        end
    end
    self:UpdateScroll(doNotResetSelect)
end

function XUiMentorAwarenessGiveaway:OnSelectViewPattern(viewPattern)
    self.LastViewPattern = viewPattern

    if viewPattern == ViewPattern.Suit then
        self.PanelEquipScroll.gameObject:SetActive(false)
        self.PanelSuitDropDown.gameObject:SetActive(false)
        self.PanelTabBtns.gameObject:SetActive(true)
        self.PanelTogPos.gameObject:SetActive(false)
        self.PanelTogPosStar.gameObject:SetActive(true)
        self.PanelTogPos.CanDisSelect = true
        self.PanelSuitSimpleScroll.gameObject:SetActive(true)

        if type(self.SelectedEquipSite) == "number" then
            self.PanelTogPos:SelectIndex(self.SelectedEquipSite)    --重置位置选择
        end
        self:PlayAnimation("SuitSimpleScrollQieHuan")
        self:PlayAnimation("LeftEnableTwo")

        self.PanelTogPosStar:SelectIndex(self.SelectedSuitStar)

    elseif viewPattern == ViewPattern.Quick then
        self.PanelEquipScroll.gameObject:SetActive(true)
        self:PlayAnimation("LeftEnableOne")
        self.PanelSuitSimpleScroll.gameObject:SetActive(false)
        self.PanelSuitDropDown.gameObject:SetActive(true)
        self.PanelTabBtns.gameObject:SetActive(false)
        self.PanelTogPosStar.gameObject:SetActive(false)
        self.PanelTogPos.CanDisSelect = true
        self.PanelTogPos.gameObject:SetActive(true)
    end
end

function XUiMentorAwarenessGiveaway:OnSelectEquipSite(equipSite)
    self.SelectedEquipSite = self.PanelTogPos.CanDisSelect and equipSite == self.SelectedEquipSite and "Total" or equipSite

    if self.LastViewPattern == ViewPattern.Quick then
        self:UpdateSuitDrdOptionList()
        self:UpdateDrdSuitValue(self.QuickLastSelectSuitId)
    end

    self:OnSelectSortType(XEquipConfig.PriorSortType.Star)
    self:PlayAnimation("EquipScrollQieHuan")
end

function XUiMentorAwarenessGiveaway:OnSelectSuitStar(star)
    self.SelectedSuitStar = star
    self:OnSelectSortType(XEquipConfig.PriorSortType.Star)
    self:PlayAnimation("EquipScrollQieHuan")
end

function XUiMentorAwarenessGiveaway:OnSelectDrdSuit(suitId)
    if not suitId then
        return
    end
    self.SelectedSuitId = suitId

    self.PanelTogPosStar:SelectIndex(XDataCenter.EquipManager.GetSuitStar(suitId))
end

function XUiMentorAwarenessGiveaway:UpdateDrdSuitValue(suitId)
    local findSuitInDrd = false
    for k, v in pairs(self.StarToSiteToSuitIdsDic[self.SelectedSuitStar][self.SelectedEquipSite]) do
        if v == suitId then
            self.DrdSuit.value = k - 1
            findSuitInDrd = true
            break
        end
    end

    -- 如果当前位置没有对应套装ID，那么也调用调度函数刷到下个套装显示
    if not findSuitInDrd then
        if self.DrdSuit.value == 0 then
            self:OnDrdSuitValueChanged()
        else
            self.DrdSuit.value = 0
        end
    else
        self:OnDrdSuitValueChanged()
    end
end

function XUiMentorAwarenessGiveaway:UpdateScroll(doNotResetSelect)
    if not self.LastViewPattern then
        return
    end

    local scroll, idList
    if self.LastViewPattern == ViewPattern.Suit then

        idList = self.StarToSiteToSuitIdsDic[self.SelectedSuitStar] and self.StarToSiteToSuitIdsDic[self.SelectedSuitStar][self.SelectedEquipSite] or {}

        scroll = self.SuitSimpleScroll
        self.PanelNoSuitSimple.gameObject:SetActive(not next(idList))

    elseif self.LastViewPattern == ViewPattern.Quick then
        scroll = self.EquipScroll
        idList = self.SuitIdToEquipIdsDic[self.SelectedSuitId]
        and self.SuitIdToEquipIdsDic[self.SelectedSuitId][self.SelectedEquipSite] or {}
        self.PanelNoEquip.gameObject:SetActive(not next(idList))
    end

    if scroll then
        XLuaUiManager.Close("UiMentorAwarenessPopup")

        --NEVER DELETE ME!
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelAdapter)
        if self.TimerId then
            CSXScheduleManagerUnSchedule(self.TimerId)
            self.TimerId = nil
        end
        self.TimerId = CSXScheduleManagerScheduleOnce(function()
            if XTool.UObjIsNil(scroll.GameObject) then return end
            scroll:UpdateEquipGridList(idList, doNotResetSelect, self.SelectedEquipSite)
        end, 0)
    end
end

function XUiMentorAwarenessGiveaway:OnSelectEquip(equipId, needFixPopUpPos)
    self.SelectEquipId = equipId
    self:OpenChildUi()
end

function XUiMentorAwarenessGiveaway:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterClickEvent(self.BtnClosePopup, self.OnBtnClosePopupClick)
    self:RegisterClickEvent(self.PanelEquipScroll, self.OnPanelEquipScrollClick)
    self.BtnStand.CallBack = function()
        self:OnBtnStandClick()
    end
end

function XUiMentorAwarenessGiveaway:OpenChildUi()--打开详情界面
    if not self.IsSending then
        XLuaUiManager.Close("UiMentorAwarenessPopup")
        XLuaUiManager.Open("UiMentorAwarenessPopup", self)
    end
end

function XUiMentorAwarenessGiveaway:OnPanelEquipScrollClick()
    XLuaUiManager.Close("UiMentorAwarenessPopup")
end

function XUiMentorAwarenessGiveaway:OnBtnClosePopupClick()
    self.EquipScroll:ResetSelectGrid()
    XLuaUiManager.Close("UiMentorAwarenessPopup")
end

function XUiMentorAwarenessGiveaway:OnBtnStandClick()
    if self:CheckUiPopupIsOpen() then
        XLuaUiManager.Close("UiMentorAwarenessPopup")
        return
    end

    if not (self.SelectedEquipIdList and next(self.SelectedEquipIdList)) then
        XUiManager.TipText("MentorTeacherGiftEmpeyHint")
        return
    end

    self.IsSending = true
    XDataCenter.MentorSystemManager.MentorGiveRewardRequest(self.StudentId, self.TaskId, function()
        self.SelectedEquipIdList = {}
        self:ResetPanel()
        self:Close()
        self.CallBack()
    end, function()
        self.IsSending = false
    end)
end

function XUiMentorAwarenessGiveaway:OnBtnBackClick()
    XLuaUiManager.Close("UiMentorAwarenessPopup")
    if self.LastViewPattern == ViewPattern.Quick then
        self.PanelTabBtns:SelectIndex(ViewPattern.Suit)
    else
        self:Close()
    end
end

function XUiMentorAwarenessGiveaway:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiMentorAwarenessGiveaway:OnDrdSuitValueChanged()
    local suitId = self.StarToSiteToSuitIdsDic[self.SelectedSuitStar][self.SelectedEquipSite][self.DrdSuit.value + 1]
    self.QuickLastSelectSuitId = suitId
    self:OnSelectDrdSuit(suitId)
end

function XUiMentorAwarenessGiveaway:CheckUiPopupIsOpen()
    return XLuaUiManager.IsUiLoad("UiMentorAwarenessPopup") or XLuaUiManager.IsUiShow("UiMentorAwarenessPopup")
end