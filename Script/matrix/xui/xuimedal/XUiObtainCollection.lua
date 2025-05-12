local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiObtainCollection = XLuaUiManager.Register(XLuaUi, "UiObtainCollection")
local VIEW_MAX = 5
function XUiObtainCollection:OnStart(rewardGoodsList)
    self.Items = {}
    self.GridCommon.gameObject:SetActive(false)
    self:Refresh(rewardGoodsList)
    self:AutoAddListener()
    self:PlayAnimation("AniObtain")
end

function XUiObtainCollection:OnEnable()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Common_UiObtain)
end

function XUiObtainCollection:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
end

function XUiObtainCollection:AutoAddListener()
    self.BtnCancel.CallBack = function()
        self:OnBtnCancelClick()
    end
end

function XUiObtainCollection:OnBtnCancelClick()
    self:Close()
end

function XUiObtainCollection:Refresh(rewardGoodsList)
    rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    XUiHelper.CreateTemplates(self, self.Items, rewardGoodsList, XUiGridCommon.New, self.GridCommon, self.PanelContent, function(grid, data)
            local quality = XDataCenter.MedalManager.GetQuality(data.TemplateId)
            local levelIcon = XDataCenter.MedalManager.GetLevelIcon(data.TemplateId,quality)
            grid:SetSyncQuality(quality)
            grid:SetSyncLevelIcon(levelIcon)
            grid:Refresh(data, nil, nil, false)
        end)
    if #self.Items < VIEW_MAX then
        self.ScrView.enabled = false
    else
        self.ScrView.enabled = true
    end
end