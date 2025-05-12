local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBlackGrid = require("XUi/XUiSocial/Black/XUiBlackGrid")

local XUiPanelBlackView = XClass(nil, "XUiPanelBlackView")

local ANIMATION_TIME = CS.XGame.ClientConfig:GetFloat("SocialBlackAnimationContentShowTime")

--黑名单界面
function XUiPanelBlackView:Ctor(ui, rootUi, insertPanelTipsDescCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.InsertPanelTipsDescCb = insertPanelTipsDescCb

    self.BlackPlayerIdList = {}

    self.ScrollRect = self.PanelBlacklist:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
    
    self.DynamicListManager = XDynamicTableNormal.New(self.PanelBlacklist)
    self.DynamicListManager:SetProxy(XUiBlackGrid)
    self.DynamicListManager:SetDelegate(self)
    self.GridContact.gameObject:SetActiveEx(false)
end

function XUiPanelBlackView:Show()
    if not self.GameObject:Exist() then
        return
    end

    self.GameObject:SetActiveEx(true)
    self.RootUi:PlayAnimation("AddContactViewQieHuan")
    self.ScrollRect.enabled = true
    self:Refresh()
end

function XUiPanelBlackView:OnClose()
    self:Hide()
end

function XUiPanelBlackView:Hide()
    if not self.GameObject:Exist() then
        return
    end

    self.GameObject:SetActive(false)
end

function XUiPanelBlackView:Refresh()
    self:RefreshDynamicList()
end

function XUiPanelBlackView:RefreshDynamicList()
    self:RefreshBlackCount()

    XDataCenter.SocialManager.GetBlacksInfo(function()
        self.BlackPlayerIdList = XDataCenter.SocialManager.GetBlackPlayerIdList()
        self.DynamicListManager:SetDataSource(self.BlackPlayerIdList)
        self.DynamicListManager:ReloadDataSync()

        self.Tips.gameObject:SetActiveEx(#self.BlackPlayerIdList <= 0)
        self:RefreshBlackCount()
    end)
end

function XUiPanelBlackView:RefreshBlackCount()
    local blackCount = #self.BlackPlayerIdList
    local maxCount = CS.XGame.Config:GetInt("FriendMaxBlacklistCount")
    self.TxtFriendCount.text = CS.XTextManager.GetText("SocialBlackMaxCountDesc", blackCount, maxCount)
end

--移除黑名单播放动画后刷新
function XUiPanelBlackView:RemoveBlackRefresh(index)
    self.ScrollRect.enabled = false

    local movePositionYMap = {}
    local preGrid
    local currGrid
    for i = index + 1, #self.BlackPlayerIdList do
        preGrid = self.DynamicListManager:GetGridByIndex(i - 1)
        currGrid = self.DynamicListManager:GetGridByIndex(i)
        if currGrid and preGrid then
            movePositionYMap[i] = {
                originPositionY = currGrid:GetPositionY(),
                movePositionY = preGrid:GetPositionY() - currGrid:GetPositionY()
            }
        end
    end

    local removeGrid = self.DynamicListManager:GetGridByIndex(index)
    if removeGrid then
        removeGrid:PlayDisableAnimation()
    end

    XUiHelper.Tween(ANIMATION_TIME, function(f)
        for index, data in pairs(movePositionYMap) do
            currGrid = self.DynamicListManager:GetGridByIndex(index)
            if currGrid then
                currGrid:SetPositionY(data.originPositionY + data.movePositionY * f)
            end
        end
    end, function ()
        if (XTool.UObjIsNil(self.GameObject)) or not self.GameObject.activeSelf then
            return
        end
        self.ScrollRect.enabled = true
        self:Refresh()
    end)
end

function XUiPanelBlackView:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(handler(self, self.RemoveBlackRefresh), self.InsertPanelTipsDescCb, handler(self, self.IsLockRequestRemoveBlacklist))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.BlackPlayerIdList[index], index)
    end
end

function XUiPanelBlackView:IsLockRequestRemoveBlacklist()
    if XTool.UObjIsNil(self.ScrollRect) then
        return false
    end
    return not self.ScrollRect.enabled
end

return XUiPanelBlackView