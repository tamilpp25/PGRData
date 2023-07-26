local XUiGuildGift = XLuaUiManager.Register(XLuaUi, "UiGuildGift")
local XUiGridGuildPresentItem = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildPresentItem")

local IsLockBtnAdd = false

function XUiGuildGift:OnAwake()
    self:AddListener()
end

function XUiGuildGift:OnStart(targetMember)
    self.PresentList = {}
    self.SelectCount = 0
    self.DefaultMinSelectCount = 1
    self.SupposedCount = 1

    self.WgtBtnAddSelect = self.BtnAddSelect.gameObject:GetComponent("XUiPointer")
    self.WgtBtnMinusSelect = self.BtnMinusSelect.gameObject:GetComponent("XUiPointer")
    -- 默认隐藏数量选择界面
    self:SetPanelNumVisable(false)
    self.BtnAddSelect.CallBack = function() self:OnBtnAddSelectClick() end
    self.BtnMinusSelect.CallBack = function() self:OnBtnMinusSelectClick() end
    XUiButtonLongClick.New(self.WgtBtnMinusSelect, 100, self, nil, self.BtnMinusSelectLongClickCallback, nil, true)
    XUiButtonLongClick.New(self.WgtBtnAddSelect, 100, self, nil, self.BtnAddSelectLongClickCallback, nil, true)

    self:RefreshGift(targetMember)
end

function XUiGuildGift:AddListener()
    self.BtnMax.CallBack = function() self:OnBtnMaxClick() end
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnCancel.CallBack = function() self:OnBtnCloseClick() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
end

function XUiGuildGift:RefreshGift(targetMember)
    self.TargetMember = targetMember
    local allPresent = XGuildConfig.GetAllGuildPresent()
    self.PresentDatas = {}
    self.SelectGridIndexs = {}
    self.currentIndex = -1
    local index = 1
    for _, present in pairs(allPresent) do
        local itemId = present.PresentId
        local itemCount = XDataCenter.ItemManager.GetCount(itemId)
        if itemCount > 0 then
            table.insert(self.PresentDatas, {
                ItemId = itemId,
                ItemCount = itemCount,
                Popularity = present.Popularity,
                Index = index + 1
            })
            index = index + 1
        end
    end

    self.ImgEmpty.gameObject:SetActiveEx(#self.PresentDatas <= 0)
    -- XUiHelper.CreateTemplates(self.RootUi, self.GridRewardItem, PresentDatas, XUiGridGuildPresentItem.New, self.PanelExpItem.gameObject, self.PanelContent)
    for i = 1, #self.PresentDatas do
        if not self.PresentList[i] then
            local grid = CS.UnityEngine.Object.Instantiate(self.GridRewardItem)
            grid.transform:SetParent(self.PanelGiftSelect, false)
            self.PresentList[i] = XUiGridGuildPresentItem.New(grid, self, function(gridData, grid)
                self:SelectRewardGrid(gridData, grid)
            end)
        end
        self.PresentList[i]:SetSelectState(false)
        self.PresentList[i].GameObject:SetActiveEx(true)
        self.PresentList[i]:RefreshGiftItem(self.PresentDatas[i], i)
    end

    for i = #self.PresentDatas + 1, #self.PresentList do
        self.PresentList[i].GameObject:SetActiveEx(false)
    end
    self.LastSelectGrid = nil
    self:SetPanelNumVisable(self.currentIndex ~= -1)
end

function XUiGuildGift:SelectRewardGrid(gridData, grid)
    local id = gridData.Data.ItemId
    if not self.SelectGridIndexs[id] then
        if self.LastSelectGrid then
            self.SelectGridIndexs = {}
            self.LastSelectGrid:SetSelectState(false)
            self.SelectCount = gridData.CurSelectNum
        end
        grid:SetSelectState(true)
        if gridData.CurSelectNum == 0 and grid.SelectState then
            grid:SetSelectNum(self.SupposedCount)
        end
        self.LastSelectGrid = grid
        self.SelectGridIndexs[id] = gridData.GridIndex
    else
        grid:SetSelectState(false)
        grid:SetSelectNum(0)
        self.SelectGridIndexs[id] = nil
    end        
    self.currentIndex =  grid.SelectState and gridData.GridIndex or -1
    self:SetPanelNumVisable(self.currentIndex ~= -1)
    --self.TxtSelect.text = CS.XTextManager.GetText("ItemHaveSelectedCount", self.SelectCount, self.SupposedCount)
end

function XUiGuildGift:SetPanelNumVisable(bool)
    self.PanelNum.gameObject:SetActiveEx(bool)
    if bool then
        self:SetSelectCount(self.LastSelectGrid.CurSelectNum)
    end
end

function XUiGuildGift:OnBtnAddSelectClick()
    if self.SelectCount <= 0 or self.SelectCount >= self:GetGridCount() then
        return
    end
    if IsLockBtnAdd then
        return
    end
    self:SetSelectCount(self.SelectCount + 1)
    self:SetBtnShowOfActionPointOverLimit()
end

function XUiGuildGift:OnBtnMinusSelectClick()
    if self.SelectCount <= 0 then
        return
    end
    self:SetSelectCount(self.SelectCount - 1)
    self:SetBtnShowOfActionPointOverLimit()
end

function XUiGuildGift:OnBtnMaxClick()
    local maxCount = self:GetMaxCount()
    if maxCount and self.SelectCount >= maxCount then
        return
    end

    self:SetSelectCount(maxCount)
    self:SetBtnShowOfActionPointOverLimit()
end

function XUiGuildGift:OnBtnCloseClick()
    self:Close()
end

function XUiGuildGift:BtnMinusSelectLongClickCallback(time)
    if self.SelectCount == 0 then
        return
    end

    local delta = math.max(0, math.floor(time / 150))
    local count = self.SelectCount - delta
    if count <= 0 then
        count = 0
    end
    self:SetSelectCount(count)
    self:SetBtnShowOfActionPointOverLimit()
end

function XUiGuildGift:BtnAddSelectLongClickCallback(time)
    local maxCount = self:GetGridCount()
    if maxCount and self.SelectCount >= maxCount then
        return
    end
    if IsLockBtnAdd then
        XUiManager.TipMsg(CS.XTextManager.GetText("OverLimitCanNotUse"))
        return
    end
    local delta = math.max(0, math.floor(time / 150))
    local count = self.SelectCount + delta
    if maxCount and count >= maxCount then
        count = maxCount
    end

    self:SetSelectCount(count)
    self:SetBtnShowOfActionPointOverLimit()
end

function XUiGuildGift:SetSelectCount(newCount)
    if not self.LastSelectGrid then return end
    self.SelectCount = math.max(newCount, self.DefaultMinSelectCount)
    if self.BtnUse then
        self.BtnUse.interactable = newCount > 0
    end
    self.TxtGiftSelect.text = tostring(self.SelectCount)
    self.LastSelectGrid:SetSelectNum(self.SelectCount)
    IsLockBtnAdd = newCount == self:GetMaxCount()
end

function XUiGuildGift:OnBtnConfirmClick()
    if not self.TargetMember then return end
    local giftIds = {}
    local giftCounts = {}
    local totalPopularity = 0
    local notSelect = true

    for i = 1, #self.PresentList do
        local itemId, selectNum, popularity = self.PresentList[i]:GetSelectNums()
        if selectNum > 0 then
            notSelect = false
            table.insert(giftIds, itemId)
            table.insert(giftCounts, selectNum)
            totalPopularity = totalPopularity + popularity
        end
    end

    if notSelect then 
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildNoneSelectPresent"))
        return 
    end

    XDataCenter.GuildManager.GuildGiveLike(self.TargetMember.Id, giftIds, giftCounts, function()
        local memberList = XDataCenter.GuildManager.GetMemberList()
        local memberInfo = memberList[self.TargetMember.Id]
        if memberInfo then
            memberInfo.Popularity = memberInfo.Popularity + totalPopularity
        end
        
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildSendGiftSuccess", XDataCenter.SocialManager.GetPlayerRemark(self.TargetMember.Id, self.TargetMember.Name)))
        self:RefreshGift(self.TargetMember)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_ALLRANKNAME_UPDATE)
    end)
end


function XUiGuildGift:SetBtnShowOfActionPointOverLimit()
    IsLockBtnAdd = false
    local GoodsNum = 1
    local RewardIndex = 2
    local ActionPoint = XDataCenter.ItemManager.GetItem(XDataCenter.ItemManager.ItemId.ActionPoint)
end

function XUiGuildGift:GetMaxCount()
    local maxCount = self:GetGridCount() or 0
    if maxCount == 0 then
        return maxCount
    end
    local tmpMaxCount = 1
    return maxCount
end

--获取当前道具的数量包括堆叠显示
function XUiGuildGift:GetGridCount()
    if not self.LastSelectGrid then return end
    return self.LastSelectGrid.Gift.ItemCount
end

function XUiGuildGift:OnEnable()

end

function XUiGuildGift:OnDisable()

end