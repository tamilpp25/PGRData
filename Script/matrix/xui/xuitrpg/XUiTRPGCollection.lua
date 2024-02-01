local CSXTextManagerGetText = CS.XTextManager.GetText

--探索营地界面-珍藏界面
local XUiTRPGCollection = XLuaUiManager.Register(XLuaUi, "UiTRPGCollection")

function XUiTRPGCollection:OnAwake()
    XDataCenter.TRPGManager.SaveIsAlreadyOpenCollection()

    self:InitTabGroup()
    self:AutoAddListener()
    
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.TRPGMoney, function()
        self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.TRPGMoney})
    end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.TRPGMoney})
end

function XUiTRPGCollection:OnEnable()
    self:Refresh()
end

function XUiTRPGCollection:Refresh()
    local itemId = XTRPGConfigs.GetMemoireStoryUnlockItemId(self.CurGroupIndex)
    local ownCount = XDataCenter.ItemManager.GetCount(itemId)
    local maxCount = XTRPGConfigs.GetMemoireStoryUnlockItemCount(self.CurGroupIndex)
    self.TxtSuiPian.text = CSXTextManagerGetText("TRPGMemoryChip", ownCount, maxCount)

    self.TxtTitle.text = XTRPGConfigs.GetMemoireStoryName(self.CurGroupIndex)
    self.TxtDesc.text = XTRPGConfigs.GetMemoireStoryDesc(self.CurGroupIndex)

    local icon = XDataCenter.ItemManager.GetItemBigIcon(itemId)
    self.Icon:SetRawImage(icon)

    local imgCG = XTRPGConfigs.GetMemoireStoryImgCG(self.CurGroupIndex)
    self.ImgCG:SetRawImage(imgCG)

    self.ImgDark.gameObject:SetActiveEx(ownCount < maxCount)

    self:OnCheckTabGroupRedPoint()
    self:OnCheckBtnTongBlackRedPoint()
end

function XUiTRPGCollection:InitTabGroup()
    self.CurGroupIndex = 1
    self.TabGroup = {}
    local tabName
    local maxNum = XTRPGConfigs.GetMemoirStoryMaxNum()
    for i = 1, maxNum do
        self.TabGroup[i] = self["TabStory" .. i]
        tabName = XTRPGConfigs.GetMemoireStoryTabName(i)
        self.TabGroup[i]:SetName(tabName)
    end

    self.PanelStoryTab:Init(self.TabGroup, function(groupIndex) self:TabGroupSkip(groupIndex) end)
    self.PanelStoryTab:SelectIndex(self.CurGroupIndex)
end

function XUiTRPGCollection:TabGroupSkip(groupIndex)
    self:PlayAnimation("QieHuan")

    if self.CurGroupIndex == groupIndex then return end
    self.CurGroupIndex = groupIndex
    self:Refresh()
end

function XUiTRPGCollection:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnTongBlack, self.OnBtnTongBlackClick)
    self:RegisterClickEvent(self.BtnIcon, self.OnBtnIconClick)
end

function XUiTRPGCollection:OnBtnIconClick()
    local itemId = XTRPGConfigs.GetMemoireStoryUnlockItemId(self.CurGroupIndex)
    local ownCount = XDataCenter.ItemManager.GetCount(itemId)
    local data = {Id = itemId, Count = ownCount}
    XLuaUiManager.Open("UiTip", data)
end

function XUiTRPGCollection:OnBtnTongBlackClick()
    local isCanPlay = XDataCenter.TRPGManager.IsCanPlayMemoir(self.CurGroupIndex)
    if not isCanPlay then
        XUiManager.TipText("TRPGMemoryNotPlayTipsDesc")
        return
    end

    local cb
    local movieId = XTRPGConfigs.GetMemoireStoryId(self.CurGroupIndex)
    if not XDataCenter.TRPGManager.IsPlayedMemoir(self.CurGroupIndex) then
        cb = function()
            XDataCenter.TRPGManager.RequestTRPGOpenMemoirSend(self.CurGroupIndex)
        end
    end
    XDataCenter.MovieManager.PlayMovie(movieId, cb)
end

function XUiTRPGCollection:OnBtnBackClick()
    self:Close()
end

function XUiTRPGCollection:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTRPGCollection:OnCheckTabGroupRedPoint()
    local maxNum = XTRPGConfigs.GetMemoirStoryMaxNum()
    local isShow
    for i = 1, maxNum do
        if self.TabGroup[i] then
            isShow = XDataCenter.TRPGManager.CheckFirstPlayMemoirStoryById(i)
            self.TabGroup[i]:ShowReddot(isShow)
        end
    end
end

function XUiTRPGCollection:OnCheckBtnTongBlackRedPoint()
    local isShow = XDataCenter.TRPGManager.CheckFirstPlayMemoirStoryById(self.CurGroupIndex)
    self.BtnTongBlack:ShowReddot(isShow)
end