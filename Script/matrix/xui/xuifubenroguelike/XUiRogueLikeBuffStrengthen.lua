local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiRogueLikeBuffStrengthen = XLuaUiManager.Register(XLuaUi, "UiRogueLikeBuffStrengthen")
local XUiGridBuffDetailItem = require("XUi/XUiFubenRogueLike/XUiGridBuffDetailItem")

function XUiRogueLikeBuffStrengthen:OnAwake()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangCloseClick() end
    self.BtnCancel.CallBack = function() self:OnBtnCancelClick() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    
    self.RogueLikeActivityAsset = XUiPanelAsset.New(self, self.PanelActivityAsset, XFubenRogueLikeConfig.ChallengeCoin, XFubenRogueLikeConfig.PumpkinCoin, XFubenRogueLikeConfig.KeepsakeCoin)

    self.BtnLvUpClose.CallBack = function() self:OnBtnLvUpCloseClick() end
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList.gameObject)
    self.DynamicTable:SetProxy(XUiGridBuffDetailItem)
    self.DynamicTable:SetDelegate(self)

    self.TxtBuy.gameObject:SetActiveEx(false)
end

--动态列表事件
function XUiRogueLikeBuffStrengthen:OnDynamicTableEvent(event, index, grid)

    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Buffs[index]
        if not data then
            return
        end
        grid.RootUi = self
        grid:SetBuffInfo(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        for i = 1, #self.Buffs do
            self.Buffs[i].IsSelect = index == i
            local lastGrid = self.DynamicTable:GetGridByIndex(i)
            if lastGrid then
                lastGrid:SetSelected(index == i)
            end
        end
        self.CurrentIndex = index
        self:UpdateConstSupportPoint()
    end

end

function XUiRogueLikeBuffStrengthen:UpdateConstSupportPoint()
    if not self.CurrentIndex then 
        self.TxtBuy.gameObject:SetActiveEx(false)
        return 
    end
    local data = self.Buffs[self.CurrentIndex]
    local constId = XFubenRogueLikeConfig.GetBuffConstItemIdById(data.BuffId)
    local itemCount = XDataCenter.ItemManager.GetCount(constId)
    local constCount = XFubenRogueLikeConfig.GetBuffConstItemCountById(data.BuffId)
    if not constId or constId == 0 or not constCount or constCount == 0 then
        self.TxtBuy.gameObject:SetActiveEx(false)
    else
        self.TxtBuy.gameObject:SetActiveEx(true)
        if itemCount < constCount then
            self.TxtBuy.text = string.format("<color=#FF3300FF>%s</color>",constCount)
        else
            self.TxtBuy.text = constCount
        end
        
        self.RImgMoney:SetRawImage(XItemConfigs.GetItemIconById(constId))
    end
end

function XUiRogueLikeBuffStrengthen:OnStart(node)
    self.Node = node
    local myBuffs = XDataCenter.FubenRogueLikeManager.GetMyBuffs()
    self.Buffs = {}
    for _, v in pairs(myBuffs) do
        if not XFubenRogueLikeConfig.IsBuffMaxLevel(v.BuffId) then
            table.insert(self.Buffs, v)
        end
    end

    self.DynamicTable:SetDataSource(self.Buffs)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(#self.Buffs <= 0)

    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_BUFFIDS_CHANGES, self.UpdateBuffList, self)
end


function XUiRogueLikeBuffStrengthen:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_BUFFIDS_CHANGES, self.UpdateBuffList, self)
end

function XUiRogueLikeBuffStrengthen:UpdateBuffList()
    local myBuffs = XDataCenter.FubenRogueLikeManager.GetMyBuffs()
    self.Buffs = {}
    for _, v in pairs(myBuffs) do
        if not XFubenRogueLikeConfig.IsBuffMaxLevel(v.BuffId) then
            table.insert(self.Buffs, v)
        end
    end
    
    self.DynamicTable:SetDataSource(self.Buffs)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(#self.Buffs <= 0)

    self.CurrentIndex = nil
    self:UpdateConstSupportPoint()
end

function XUiRogueLikeBuffStrengthen:OnBtnCloseClick()
    self:Close()
end

function XUiRogueLikeBuffStrengthen:OnBtnTanchuangCloseClick()
    self:Close()
end

function XUiRogueLikeBuffStrengthen:OnBtnCancelClick()
    self:Close()
end

function XUiRogueLikeBuffStrengthen:OnBtnConfirmClick()
    if not self.CurrentIndex then
        XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeSelectABuff"))
        return
    end
    if self.Node and self.CurrentIndex then
        local data = self.Buffs[self.CurrentIndex]
        XDataCenter.FubenRogueLikeManager.IntensifyBuff(self.Node.Id, data.BuffId, function()
            -- 刷新，弹窗
            self:ShowBuffLevelUp(data.BuffId)
        end)
    end
end

function XUiRogueLikeBuffStrengthen:ShowBuffLevelUp(buffId)
    local buffTemplate = XFubenRogueLikeConfig.GetBuffTemplateById(buffId)
    local intensifyTemplate = XFubenRogueLikeConfig.GetBuffTemplateById(buffTemplate.IntensifyId)
    local buffConfig = XFubenRogueLikeConfig.GetBuffConfigById(buffId)
    local intensifyConfig = XFubenRogueLikeConfig.GetBuffConfigById(buffTemplate.IntensifyId)
    
    if not intensifyTemplate then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetBuffConfigById",
        "RogueLikeBuffDetails", "Client/Fuben/RogueLike/RogueLikeBuffDetails.tab", "Id", tostring(buffId))
        self:OnBtnLvUpCloseClick()
        return
    end

    self:PlayAnimation("PanelBuffLvUpEnable", function()
        XLuaUiManager.SetMask(false)
    end,
    function()
        XLuaUiManager.SetMask(true)
    end)

    self.RImgLeftBuffIcon:SetRawImage(buffConfig.Icon)
    self.TxtLeftBuffDetails.text = buffConfig.Description
    self.RImgRightBuffIcon:SetRawImage(intensifyConfig.Icon)
    self.TxtRightBuffDetails.text = intensifyConfig.Description
    self.PanelBuffLvUp.gameObject:SetActiveEx(true)


end

function XUiRogueLikeBuffStrengthen:OnBtnLvUpCloseClick()
    self.PanelBuffLvUp.gameObject:SetActiveEx(false)
    --self:Close()
end