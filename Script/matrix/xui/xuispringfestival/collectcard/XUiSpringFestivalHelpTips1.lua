local XUiSpringFestivalHelpTips1 = XLuaUiManager.Register(XLuaUi, "UiSpringFestivalHelpTips1")
local XUiGridSpringFestivalRequestItem = require("XUi/XUiSpringFestival/CollectCard/XUiGridSpringFestivalRequestItem")
function XUiSpringFestivalHelpTips1:OnStart()
    self.RequestItemsDic = {}
    self:InitItemList()
    self:RegisterButtonEvent()
    self.LastSelectId = 0
end

function XUiSpringFestivalHelpTips1:OnEnable()

end

function XUiSpringFestivalHelpTips1:OnDisable()

end

function XUiSpringFestivalHelpTips1:OnDestroy()

end

function XUiSpringFestivalHelpTips1:InitItemList()
    local wordTemplates = XSpringFestivalActivityConfigs.GetCollectWordsTemplateOrderFunc(function(a, b)
        local countA = XDataCenter.ItemManager.GetCount(a.Id)
        local countB = XDataCenter.ItemManager.GetCount(b.Id)
        return countA < countB
    end)
    for i = 1 ,#wordTemplates do
        if not self.RequestItemsDic[wordTemplates[i].Id] and wordTemplates[i].Type ~= XSpringFestivalActivityConfigs.CollectCardType.Universal then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridRewardItem, self.PanelReward)
            obj.gameObject:SetActive(true)
            local item = XUiGridSpringFestivalRequestItem.New(obj, function(newWordId)
                self:OnSelectRequestItem(newWordId)
            end)
            item:Refresh(wordTemplates[i].Id)
            self.RequestItemsDic[wordTemplates[i].Id] = item
        end
    end
end

function XUiSpringFestivalHelpTips1:OnSelectRequestItem(newWordId)
    local item = self.RequestItemsDic[newWordId]
    if item then
        item:ShowSelectBg(true)
    end

    local lastSelectItem = self.RequestItemsDic[self.LastSelectId]
    if lastSelectItem then
        lastSelectItem:ShowSelectBg(false)
    end
    if newWordId == self.LastSelectId then
        self.LastSelectId = 0
    else
        self.LastSelectId = newWordId
    end
end

function XUiSpringFestivalHelpTips1:RegisterButtonEvent()
    self.BtnTanchuangClose.CallBack = function()
        self:OnClickCloseBtn()
    end
    self.BtnYes.CallBack = function()
        self:OnClickYesBtn()
    end
    self.BtnNo.CallBack = function()
        self:OnClickCloseBtn()
    end
end

function XUiSpringFestivalHelpTips1:OnClickCloseBtn()
    XLuaUiManager.Close("UiSpringFestivalHelpTips1")
end

function XUiSpringFestivalHelpTips1:OnClickYesBtn()
    if self.LastSelectId == 0 then
        return
    end
    XDataCenter.SpringFestivalActivityManager.CollectWordsRequestWordRequest(self.LastSelectId, function()
        XLuaUiManager.Close("UiSpringFestivalHelpTips1")
        XLuaUiManager.Open("UiSpringFestivalHelpTips2")
    end)
end

return XUiSpringFestivalHelpTips1