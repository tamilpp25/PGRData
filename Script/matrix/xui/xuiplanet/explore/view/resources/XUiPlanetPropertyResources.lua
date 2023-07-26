---@class XUiPlanetPropertyResources:XLuaUi
local XUiPlanetPropertyResources = XLuaUiManager.Register(XLuaUi, "UiPlanetPropertyResources")

function XUiPlanetPropertyResources:Ctor()
end

function XUiPlanetPropertyResources:OnAwake()
    self:BindExitBtns(self.BtnClose)
    self:BindExitBtns(self.BtnTanchuangClose)
end

function XUiPlanetPropertyResources:OnStart(itemList)
    self.ItemList = itemList
    self:InitItemList()
end

function XUiPlanetPropertyResources:OnEnable()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.DETAIL)
end

function XUiPlanetPropertyResources:OnDisable()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.DETAIL)
end

--region ui
function XUiPlanetPropertyResources:InitItemList()
    self.TabBtns = {}
    for _, itemId in ipairs(self.ItemList) do
        local go = XUiHelper.Instantiate(self.ImgBuffBg01.gameObject, self.PanelStageList.transform)
        local button = go:GetComponent("XUiButton")
        local name = XDataCenter.ItemManager.GetItemName(itemId)
        local icon = XDataCenter.ItemManager.GetItemIcon(itemId)
        button:SetNameByGroup(0, name)
        if not string.IsNilOrEmpty(icon) then
            button:SetRawImage(icon)
        end
        table.insert(self.TabBtns, button)
    end
    self.PanelStageList:Init(self.TabBtns, function(index) self:OnSelectItem(index) end)

    self.SelectIndex = 1
    self.PanelStageList:SelectIndex(self.SelectIndex)
    self.ImgBuffBg01.gameObject:SetActiveEx(false)
end

function XUiPlanetPropertyResources:OnSelectItem(index)
    local itemId = self.ItemList[index]
    local name = XDataCenter.ItemManager.GetItemName(itemId)
    local icon = XDataCenter.ItemManager.GetItemBigIcon(itemId)
    local desc = XDataCenter.ItemManager.GetItemDescription(itemId)

    self.TxtName.text = name
    self.TxtNr.text = desc
    if not string.IsNilOrEmpty(icon) then
        self.RawImage:SetRawImage(icon)
    end
    
    if itemId == XDataCenter.ItemManager.ItemId.PlanetRunningTalent then
        if #self.ItemList > 1 then
            self.TxtMode2.text = XDataCenter.PlanetManager.GetStageData():GetTalentCoin()
        else
            self.TxtMode2.text = XDataCenter.ItemManager.GetCount(itemId)
        end
    elseif itemId == XDataCenter.ItemManager.ItemId.PlanetRunningStageCoin then
        self.TxtMode2.text = XDataCenter.PlanetManager.GetStageData():GetCoin()
    end
    self:PlayAnimation("QieHuan")
end
--endregion

return XUiPlanetPropertyResources