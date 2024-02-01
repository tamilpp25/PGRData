--===============
--公会宿舍设置头像界面
--===============
local XUiGuildDormSetGuildHead = XLuaUiManager.Register(XLuaUi, "UiGuildDormHeadPotrait")
local XUiGuildHeadPortraitItem = require("XUi/XUiGuild/XUiChildItem/XUiGuildHeadPortraitItem")

function XUiGuildDormSetGuildHead:OnAwake()
    self:InitButtons()
    self.CurHeadPortraitId = -1
    self.InitHeadPortraitId = 1
    self:InitDynamicTable()
    self:SetListDatas()
    self:UpdateInfo(XDataCenter.GuildManager.GetGuildHeadPortrait())
end

function XUiGuildDormSetGuildHead:OnStart(callback)
    self.CallBack = callback
end

function XUiGuildDormSetGuildHead:OnEnable()

end

function XUiGuildDormSetGuildHead:OnDisable()

end

function XUiGuildDormSetGuildHead:InitButtons()
    self.BtnHeadSure.CallBack = function() self:OnBtnHeadSureClick() end
    self.BtnHeadNulock.CallBack = function() self:OnBtnHeadUnlockClick() end
    self.BtnHeadCancel.CallBack = function() self:OnBtnHeadCancelClick() end
    self.BtnClose.CallBack = function() self:OnBtnHeadCancelClick() end
end

function XUiGuildDormSetGuildHead:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ScrollView)
    self.DynamicTable:SetProxy(XUiGuildHeadPortraitItem)
    self.DynamicTable:SetDelegate(self)
    self.GameObject:SetActiveEx(false)
    
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XGuildConfig.GoodsCoinId }, self.PanelAsset, self)
end

function XUiGuildDormSetGuildHead:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:OnRefresh(self.ListDatas[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurSeleGridItem then
            self.CurSeleGridItem:SetStatus(false)
        end

        local data = self.ListDatas[index]
        grid:SetStatus(true)
        self.CurSeleGridItem = grid
        self:UpdateInfo(data.Id)
        XDataCenter.GuildManager.MarkHeadPortrait(data.Id)
        grid:RefreshRedPoint()
    end
end

function XUiGuildDormSetGuildHead:IsSeleId(id)
    return self.CurHeadPortraitId == id
end

function XUiGuildDormSetGuildHead:UpdateInfo(id)
    if self.CurHeadPortraitId == id then
        return
    end
    self.CurHeadPortraitId = id
    local config = XGuildConfig.GetGuildHeadPortraitById(id)
    local conditionId = config.ConditionId
    local unlock, desc = true, ""
    if XTool.IsNumberValid(conditionId) then
        unlock, desc = XConditionManager.CheckCondition(conditionId)
    end
    self.BtnHeadSure.gameObject:SetActiveEx(unlock)
    local iconId = XDataCenter.GuildManager.GetGuildHeadPortrait()
    local sameIcon = iconId == self.CurHeadPortraitId and true or false
    self.BtnHeadSure:SetDisable(sameIcon, not sameIcon)
    --未解锁，需要购买
    local lockNeedCoin = config.Cost > 0 and not unlock
    --未解锁，无需购买
    local lockNoMoreNeedCoin = config.Cost <= 0 and not unlock
    self.BtnHeadNulock.gameObject:SetActiveEx(lockNeedCoin)
    self.TxtNumber.gameObject:SetActiveEx(lockNeedCoin)
    self.RImgCoin.gameObject:SetActiveEx(lockNeedCoin)
    self.ConditionPanel.gameObject:SetActiveEx(lockNoMoreNeedCoin)
    if lockNeedCoin then
        local showCoin = XDataCenter.GuildManager.GetShopCoin()
        local disable = showCoin < config.Cost
        self.TxtNumber.text = config.Cost
        self.TxtNumber.color = disable and CS.UnityEngine.Color.red or CS.UnityEngine.Color.black
        self.RImgCoin:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GoodsCoinId))
        self.BtnHeadNulock:SetDisable(disable, not disable)
    end
    if lockNoMoreNeedCoin then
        self.TxtCondition.text = desc
    end
    
    self.RImgPlayerIcon:SetRawImage(config.Icon)
    self.TxtHeadName.text = config.Name
    self.TxtDecs.text = config.Describe
end

function XUiGuildDormSetGuildHead:SetListDatas()
    self.ListDatas = XGuildConfig.GetGuildHeadPortraitDatas()
    self.DynamicTable:SetDataSource(self.ListDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiGuildDormSetGuildHead:OnBtnHeadSureClick()
    local curHeadPortrait = XDataCenter.GuildManager.GetGuildHeadPortrait()
    if self.CurHeadPortraitId ~= curHeadPortrait then
        XDataCenter.GuildManager.GuildChangeIconRequest(self.CurHeadPortraitId, function()
                local config = XGuildConfig.GetGuildHeadPortraitById(self.CurHeadPortraitId)
                if self.CallBack then
                    self.CallBack()
                end
                self:OnBtnHeadCancelClick()
            end)
    end
end

function XUiGuildDormSetGuildHead:OnBtnHeadUnlockClick()
    if XDataCenter.GuildManager.HasPortrait(self.CurHeadPortraitId) then
        return
    end
    local config = XGuildConfig.GetGuildHeadPortraitById(self.CurHeadPortraitId)
    local showCoin = XDataCenter.GuildManager.GetShopCoin()
    if config.Cost > showCoin then
        return
    end
    local gridItem = self.CurSeleGridItem
    XDataCenter.GuildManager.GuildBuyIcon(self.CurHeadPortraitId, function()
        if not gridItem then
            return
        end
        self.CurHeadPortraitId = -1
        gridItem:OnRefresh(gridItem.ItemData)
        self:UpdateInfo(gridItem.GuildId)
    end)
end

function XUiGuildDormSetGuildHead:RecordFirstSeleItem(item)
    self.CurSeleGridItem = item
end

function XUiGuildDormSetGuildHead:OnBtnHeadCancelClick()
    self:Close()
end