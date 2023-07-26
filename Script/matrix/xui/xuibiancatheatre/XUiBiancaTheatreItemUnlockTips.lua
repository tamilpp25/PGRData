-- 肉鸽玩法二期图鉴道具展示
-- ================================================================================
local XUiGridUnlockItem = XClass(nil, "XUiGridUnlockItem")
function XUiGridUnlockItem:Ctor(ui)
    self.Ui = ui
    XUiHelper.InitUiClass(self, self.Ui)
end

function XUiGridUnlockItem:RefreshUi(itemId)
    self.AfterLevelTxt = self.Transform:Find("PanelTxt")
    self.AfterLevelTxt.gameObject:SetActiveEx(false)
    self.BtnClick.gameObject:SetActiveEx(false)
    
    self.RImgIcon:SetRawImage(XBiancaTheatreConfigs.GetItemIcon(itemId))
    XUiHelper.SetQualityIcon(nil, self.ImgQuality, XBiancaTheatreConfigs.GetTheatreItemQuality(itemId))
end


-- 肉鸽玩法二期图鉴解锁提示
-- ================================================================================
local XUiBiancaTheatreItemUnlockTips = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreItemUnlockTips")

function XUiBiancaTheatreItemUnlockTips:OnAwake()
    self.UnlockItemTable = {}
    self:InitUiObject()
    self:AddClickListener()
end

function XUiBiancaTheatreItemUnlockTips:OnStart(closeCb, unlockItemIds)
    self.UnlockItemIds = unlockItemIds
    self.CloseCb = closeCb
    self:Refresh()
end

function XUiBiancaTheatreItemUnlockTips:Refresh()
    if XTool.IsTableEmpty(self.UnlockItemIds) then
        return
    end
    for index, itemId in ipairs(self.UnlockItemIds) do
        if XTool.IsTableEmpty(self.UnlockItemTable[index]) then
            self.UnlockItemTable[index] = XUiGridUnlockItem.New(XUiHelper.Instantiate(self.GridCommon, self.PanelRecycle))
        end
        self.UnlockItemTable[index]:RefreshUi(itemId)
    end
    self.GridCommon.gameObject:SetActive(false)
end

function XUiBiancaTheatreItemUnlockTips:InitUiObject()
    self.RecycleTitle.gameObject:SetActiveEx(false)
    self.RecycleTitle2.gameObject:SetActiveEx(true)
end

function XUiBiancaTheatreItemUnlockTips:AddClickListener()
    self:RegisterClickEvent(self.BtnClose, function () self:OnCloseClick() end)
end

function XUiBiancaTheatreItemUnlockTips:OnCloseClick()
    -- 清空道具及对象引用
    XDataCenter.BiancaTheatreManager.ClearNewUnlockItemDic()
    self.UnlockItemIds = {}
    self.UnlockItemTable = {}
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end