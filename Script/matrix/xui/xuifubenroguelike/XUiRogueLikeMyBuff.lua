local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiRogueLikeMyBuff = XLuaUiManager.Register(XLuaUi, "UiRogueLikeMyBuff")
local XUiGridBuffDetailItem = require("XUi/XUiFubenRogueLike/XUiGridBuffDetailItem")

function XUiRogueLikeMyBuff:OnAwake()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangCloseClick() end

    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList.gameObject)
    self.DynamicTable:SetProxy(XUiGridBuffDetailItem)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiRogueLikeMyBuff:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.MyBuffs[index]
        if not data then
            return
        end
        grid.RootUi = self
        grid:SetBuffInfo(data)
    end
end

function XUiRogueLikeMyBuff:OnStart()
    self:RefreshMyBuffs()
end

function XUiRogueLikeMyBuff:RefreshMyBuffs()
    self.MyBuffs = XDataCenter.FubenRogueLikeManager.GetMyBuffs()

    table.sort(self.MyBuffs, function(buffA, buffB)
        if buffA.SortWeight == buffB.SortWeight then
            if buffA.Priority == buffB.Priority then
                return buffA.BuffId < buffB.BuffId
            end
            return buffA.Priority > buffB.Priority
        end
        return buffA.SortWeight > buffB.SortWeight
    end)

    self.TxtOwnBuff.text = #self.MyBuffs
    self.ImgEmpty.gameObject:SetActiveEx(#self.MyBuffs <= 0)
    self.DynamicTable:SetDataSource(self.MyBuffs)
    self.DynamicTable:ReloadDataASync()
end

function XUiRogueLikeMyBuff:OnEnable()
end

function XUiRogueLikeMyBuff:OnDisable()
    XDataCenter.FubenRogueLikeManager.ResetNewBuffs()
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_BUFFIDS_CHANGES)
end

function XUiRogueLikeMyBuff:OnDestroy()

end

function XUiRogueLikeMyBuff:OnBtnCloseClick()
    self:Close()
end

function XUiRogueLikeMyBuff:OnBtnTanchuangCloseClick()
    self:Close()
end
