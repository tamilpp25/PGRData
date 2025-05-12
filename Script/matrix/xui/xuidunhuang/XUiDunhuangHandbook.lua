local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDunhuangEditPaintingGrid = require("XUi/XUiDunhuang/XUiDunhuangEditPaintingGrid")

---@class XUiDunhuangHandbook : XLuaUi
---@field _Control XDunhuangControl
local XUiDunhuangHandbook = XLuaUiManager.Register(XLuaUi, "UiDunhuangHandbook")

function XUiDunhuangHandbook:OnAwake()
    self:BindExitBtns()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.MuralShareCoin)
    self:BindHelpBtn(self.BtnHelp, "DunhuangHelp")
    self.DynamicTable = XDynamicTableNormal.New(self.ListMaterial.gameObject)
    self.DynamicTable:SetProxy(XUiDunhuangEditPaintingGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridMaterial.gameObject:SetActiveEx(false)

    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self.OnClickUnlock)

    self._IsFirstLoad = true
end

function XUiDunhuangHandbook:OnStart()
    if self.Icon1 and self.Icon2 then
        local icon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.MuralShareCoin)
        self.Icon1:SetRawImage(icon)
        self.Icon2:SetRawImage(icon)
    end
end

function XUiDunhuangHandbook:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_DUNHUANG_SELECT_PAINTING, self.UpdateSelectedPainting, self)
    XEventManager.AddEventListener(XEventId.EVENT_DUNHUANG_UPDATE_OWN_PAINTING, self.UpdateAfterUnlock, self)
    self:Update()
end

function XUiDunhuangHandbook:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DUNHUANG_SELECT_PAINTING, self.UpdateSelectedPainting, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DUNHUANG_UPDATE_OWN_PAINTING, self.UpdateAfterUnlock, self)
end

function XUiDunhuangHandbook:Update(isAfterUnlock)
    self:UpdateList()
    self:UpdateSelectedPainting(true, isAfterUnlock)
end

function XUiDunhuangHandbook:UpdateAfterUnlock()
    ---@type XUiDunhuangEditPaintingGrid[]
    local grids = self.DynamicTable:GetGrids()
    local playNextAnimation = function()
        self:UpdateList()
    end
    for i, grid in pairs(grids) do
        if grid:PlayAnimationIfSelected(playNextAnimation) then
            self:UpdateSelectedPainting(true, true)
            break
        end
    end
end

function XUiDunhuangHandbook:UpdateList()
    self._Control:UpdateAllPainting(self._IsFirstLoad)
    self._Control:UpdatePaintingUnlockProgress()

    local uiData = self._Control:GetUiData()
    local paintings = uiData.PaintingListAll
    self.DynamicTable:SetDataSource(paintings)
    if self._IsFirstLoad then
        self.DynamicTable:ReloadDataSync()
    else
        self:RefreshListNotScroll()
    end

    self.TxtNum2.text = uiData.PaintingProgress1

    self._IsFirstLoad = false
end

function XUiDunhuangHandbook:RefreshListNotScroll()
    for index, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:Update(self.DynamicTable:GetData(index))
    end
end

function XUiDunhuangHandbook:UpdateSelectedPainting(notPlayQieHuan, isAfterUnlock)
    if not notPlayQieHuan then
        self:PlayAnimation("QieHuan")
    end
    self._Control:UpdateHangBookSelectedPainting()
    local uiData = self._Control:GetUiData()
    local paintingSelected = uiData.PaintingSelected
    self.RImgMaterial:SetRawImage(paintingSelected.Icon)
    self.TxtTitle.text = paintingSelected.Name
    self.TxtDetail.text = paintingSelected.Desc
    if paintingSelected.IsShowUnlockButton then
        self.Lock.gameObject:SetActiveEx(true)
        self.TxtTitleLock.text = paintingSelected.Name
        self.PanelConsume.gameObject:SetActiveEx(true)
        self.BtnTongBlack.gameObject:SetActiveEx(true)
        if paintingSelected.IsMoneyEnough then
            self.TxtCosumeNumber1.text = paintingSelected.Price
            self.PanelSkillPointOn.gameObject:SetActiveEx(true)
            self.PanelSkillPointOff.gameObject:SetActiveEx(false)
        else
            self.TxtCosumeNumber2.text = paintingSelected.Price
            self.PanelSkillPointOn.gameObject:SetActiveEx(false)
            self.PanelSkillPointOff.gameObject:SetActiveEx(true)
        end
    else
        -- 靠动画
        if isAfterUnlock then
            self:PlayAnimation("UnlockEnable", function()
                self:StopAnimation("UnlockEnable", false, true)
                self.Lock.gameObject:SetActiveEx(false)
            end)
        else
            self:StopAnimation("UnlockEnable", false, true)
            self.Lock.gameObject:SetActiveEx(false)
        end
        self.PanelConsume.gameObject:SetActiveEx(false)
        self.PanelSkillPointOff.gameObject:SetActiveEx(false)
        self.BtnTongBlack.gameObject:SetActiveEx(false)
    end

    for i, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:UpdateSelected(paintingSelected)
    end

    self:ResetScroll()
end

---@param grid XUiDunhuangEditPaintingGrid
function XUiDunhuangHandbook:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetIsOnGame(false)
        grid:Update(self.DynamicTable:GetData(index), self, index)
        grid:UpdateSelected(self._Control:GetUiData().PaintingSelected)
    end
end

function XUiDunhuangHandbook:OnClickUnlock()
    self._Control:RequestUnlockPainting()
end

function XUiDunhuangHandbook:ResetScroll()
    ---@type UnityEngine.UI.ScrollRect
    local scrollRect = XUiHelper.TryGetComponent(self.TxtDetail.transform.parent.parent, "", "ScrollRect")
    if scrollRect then
        scrollRect.verticalNormalizedPosition = 1
    end
end

return XUiDunhuangHandbook